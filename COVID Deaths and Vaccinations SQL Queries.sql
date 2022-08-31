SELECT *
FROM [Portfolio Project].dbo.CovidDeaths
ORDER BY 3,4

SELECT *
FROM [Portfolio Project].dbo.CovidVaccinations
ORDER BY 3,4

-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project].dbo.CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project].dbo.CovidDeaths
WHERE Location like '%states%' AND total_cases IS NOT NULL
ORDER BY 1,2


-- Looking at Total cases vs Population

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS CasesPercentage
FROM [Portfolio Project].dbo.CovidDeaths
WHERE Location like '%states%' AND total_cases IS NOT NULL
ORDER BY 1,2

--Looking at Countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS HighestCasesPercentage
FROM [Portfolio Project].dbo.CovidDeaths
--WHERE Location like '%states%' AND total_cases IS NOT NULL
GROUP BY Location, population
ORDER BY HighestCasesPercentage DESC

--Looking at Countries with highest death rate per population
SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Looking at things by Continent 
--SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
--FROM [Portfolio Project].dbo.CovidDeaths
--WHERE continent IS NULL AND location NOT LIKE '%income%'
--GROUP BY location
--ORDER BY TotalDeathCount DESC

--Highest death count by continent
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
   SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project].dbo.CovidDeaths
--WHERE Location like '%states%' AND total_cases IS NOT NULL 
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--JOIN TWO TABLES

SELECT *
FROM [Portfolio Project].dbo.CovidDeaths dea 
   JOIN [Portfolio Project].dbo.CovidVaccinations vac
   ON dea.location = vac.location 
   AND dea.date = vac.date

--Looking at total population vs vaccinations

SELECT dea.continent AS Continent, dea.location AS Location, dea.date AS Date, dea.population AS Population, 
   vac.new_vaccinations AS NewVaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
   ORDER BY dea.location, dea.date) AS RollingPopVaxed,

FROM [Portfolio Project].dbo.CovidDeaths dea 
   JOIN [Portfolio Project].dbo.CovidVaccinations vac
   ON dea.location = vac.location 
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingPopVaxed)
AS
(
SELECT dea.continent AS Continent, dea.location AS Location, dea.date AS Date, dea.population AS Population, 
   vac.new_vaccinations AS NewVaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
   ORDER BY dea.location, dea.date) AS RollingPopVaxed
FROM [Portfolio Project].dbo.CovidDeaths dea 
   JOIN [Portfolio Project].dbo.CovidVaccinations vac
   ON dea.location = vac.location 
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPopVaxed/Population)*100 AS PercentVaxed 
FROM PopvsVac





--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaxed
CREATE TABLE #PercentPopulationVaxed
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingPopVaxed numeric
)

INSERT INTO #PercentPopulationVaxed
SELECT dea.continent AS Continent, dea.location AS Location, dea.date AS Date, dea.population AS Population, 
   vac.new_vaccinations AS NewVaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
   ORDER BY dea.location, dea.date) AS RollingPopVaxed
FROM [Portfolio Project].dbo.CovidDeaths dea 
   JOIN [Portfolio Project].dbo.CovidVaccinations vac
   ON dea.location = vac.location 
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPopVaxed/Population)*100 AS PercentVaxed 
FROM #PercentPopulationVaxed


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaxed AS
SELECT dea.continent AS Continent, dea.location AS Location, dea.date AS Date, dea.population AS Population, 
   vac.new_vaccinations AS NewVaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
   ORDER BY dea.location, dea.date) AS RollingPopVaxed
FROM [Portfolio Project].dbo.CovidDeaths dea 
   JOIN [Portfolio Project].dbo.CovidVaccinations vac
   ON dea.location = vac.location 
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3