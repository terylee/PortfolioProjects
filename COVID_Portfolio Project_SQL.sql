CREATe DATABASE Covid

/*
Queries used for Tableau Project
*/

-- 1. 

SELECT SUM(new_cases) total_cases
    , SUM(CAST(new_deaths as int)) total_deaths
    , SUM(cast(new_deaths as int))/SUM(New_Cases)*100 death_percentage
FROM CovidDeaths
WHERE continent is not null 
GROUP BY date
ORDER BY 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


SELECT SUM(new_cases) total_cases
    , SUM(cast(new_deaths as int)) total_deaths
    , SUM(cast(new_deaths as int))/SUM(New_Cases)*100 death_percentage
FROM CovidDeaths
WHERE location = 'World'
ORDER BY 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(cast(new_deaths as int)) total_death_count
FROM CovidDeaths
WHERE continent is null 
    AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


-- 3.

SELECT location, population
    , MAX(total_cases) highest_infection_count
    , MAX((total_cases/population))*100 percent_population_infected
FROM CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- 4.


SELECT location, population, date
    , MAX(total_cases) highest_infection_count
    , MAX((total_cases/population))*100 percent_population_infected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY percent_population_infected DESC


-- Here only in case you want to check them out


-- 1.

SELECT dea.continent, dea.location, dea.date, dea.population
    , MAX(vac.total_vaccinations) rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1,2,3


-- 2.
SELECT SUM(new_cases) total_cases
    , SUM(cast(new_deaths as int)) total_deaths
    , SUM(cast(new_deaths as int))/SUM(new_Cases)*100 as death_percentage
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Double check based off the data provided
-- Numbers are extremely close so we will keep them - The Second includes "International"  Location


-- 3.

-- I take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(cast(new_deaths as int)) total_death_count
FROM CovidDeaths
WHERE continent is null 
    AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC



-- 4.

SELECT location, population
    , MAX(total_cases) highest_infection_count
    , MAX((total_cases/population))*100 as percent_population_infected
FROM CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC



-- 5.
-- took the above query and added population
SELECT location, date, population, total_cases, total_deaths
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- 6. 

WITH pop_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percent_people_vaccinated
FROM pop_vac


-- 7. 

SELECT location, population, date
    , MAX(total_cases) highest_infection_count
    , MAX((total_cases/population))*100 percent_population_infected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY percent_population_infected DESC
