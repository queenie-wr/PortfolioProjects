--SELECT * 
--FROM CovidDeaths
--ORDER BY 3,4

--SELECT * 
--FROM CovidVaccinations
--ORDER BY 3,4

-- Data cleaning: Change data type

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths bigint;

ALTER TABLE CovidDeaths
ALTER COLUMN population bigint;

-- Data cleaning: change blanks to nulls
UPDATE CovidDeaths 
SET col1 = NULLIF(col1, '')

SELECT * 
FROM CovidDeaths
ORDER BY 3,4


--Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths:
-- Shows likelihood of dying from COVID
SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal(18,0)) / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE total_cases <> 0 AND total_deaths <> 1 AND Location like '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT Location, date, total_cases, population, (CAST(total_cases AS decimal(18,0)) / population) * 100 AS CovidPercentage
FROM CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- Countries with highest infection rate compared to population
SELECT Location, population,  MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS decimal(18,0)) / population) * 100) AS PercentPopulationInfected
FROM CovidDeaths
WHERE population <> 0 AND total_cases <> 1 
GROUP BY Location, population
ORDER BY PercentPopulationInfected desc

-- Showing countries with highest death count 
SELECT continent, Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE Location NOT IN ('World', 'Europe', 'North America', 'European Union', 'South America', 'Asia')
GROUP BY continent, location
ORDER BY TotalDeathCount desc

-- Showing continents with highest death count 
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount desc


-- Showing countries with highest death count by population
SELECT Location, population, MAX(total_deaths) AS HighestDeathCount, MAX(CAST(total_deaths AS decimal(18,0)) / population) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE population <> 0 AND total_deaths <> 1
GROUP BY Location, population
ORDER BY DeathPercentage desc

-- Global numbers
SELECT date, SUM(CAST(new_cases as int)) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(cast(new_cases as decimal(18,0)))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null AND new_cases <> 0 AND new_deaths <> 1
GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Looking at new vaccinations per day (Rolling count)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE
-- number of columns in CTE need to match actual table
WITH PopVsVac (Continent, Location, Date, population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/cast(population as decimal(18,0)))*100
FROM PopVsVac
WHERE population <> 0 AND RollingPeopleVaccinated <>1


-- OR use Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated bigint
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/cast(population as decimal(18,0)))*100
FROM #PercentPopulationVaccinated
WHERE population <> 0 AND RollingPeopleVaccinated <>1


-- Creating view to store data for later visualisations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- Then go to the Object Explorer on the left, PortfolioProject -> Views -> you will see the view. open it up (right click, select Top 1000 rows)