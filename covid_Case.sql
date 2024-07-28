SELECT * 
FROM covid_death
WHERE continent is not null
ORDER BY 3, 4;

-- Selecting columns that will be used
SELECT location_, date_, total_cases, new_cases, total_deaths, population 
FROM covid_death
ORDER BY location_, date_;

-- Looking at the percentage of death compared to total cases in Indonesia
SELECT location_, date_, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM covid_death
WHERE location_ = 'Indonesia'
ORDER BY location_, date_ DESC;

-- Looking at percentage of pupulation contracted by covid in Indonesia
SELECT location_, date_, population, total_cases, (total_cases/population)*100 as infected_rate
FROM covid_death
WHERE location_ = 'Indonesia'
ORDER BY location_, date_ DESC;

-- Looking at country with the highest infected rate
SELECT location_, population, MAX(total_cases) AS max_cases_count, MAX((total_cases/population)*100) AS infected_rate
FROM covid_death
WHERE continent is not null
GROUP BY location_, population
ORDER BY infected_rate DESC;

-- Looking at country with the highest death rate per population
SELECT location_, population, MAX(total_deaths) AS max_death_count, MAX((total_deaths/population)*100) AS death_rate
FROM covid_death
WHERE continent is not null
GROUP BY location_, population
ORDER BY death_rate DESC;


-- Ranking total death across continet
SELECT continent, MAX(total_deaths) AS max_death_count
FROM covid_death
WHERE continent is not null
GROUP BY continent
ORDER BY max_death_count DESC;

-- Looking at global daily death percentage 
SELECT date_, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/ SUM(new_cases)*100 as death_rate
FROM covid_death
WHERE continent is not null and new_cases != 0 and new_deaths != 0
GROUP BY date_
ORDER BY 1, 2;

-- Looking at daily number of population that has been vaccinated
SELECT cd.continent, cd.location_, cd.date_, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location_ ORDER BY cd.location_, cd.date_) as RollingPeopleVaccinated
FROM covid_death as cd
JOIN covid_vaccination as cv
	ON cd.location_ = cv.location_
	AND cd.date_ = cv.date_
WHERE cd.continent is not null
ORDER BY cd.location_, cd.date_;

-- Looking at the percentage of population that has beem vaccinated
----CTE
WITH pop_vac(continent, location_, date_, population, new_vaccination, RollingPeopleVaccinated)
AS 
(
	SELECT cd.continent, cd.location_, cd.date_, cd.population, cv.new_vaccinations,
		SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location_ ORDER BY cd.location_, cd.date_) as RollingPeopleVaccinated
	FROM covid_death as cd
	JOIN covid_vaccination as cv
	ON cd.location_ = cv.location_
	AND cd.date_ = cv.date_
	WHERE cd.continent is not null
)

SELECT *, (RollingPeopleVaccinated/population)*100 as rolling_percent
FROM pop_vac

-- OR
CREATE TABLE PercentPopulationVaccinated
(
    continent VARCHAR(255),
    location_ VARCHAR(255),
    date_ TIMESTAMP,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT cd.continent, cd.location_, cd.date_, cd.population, cv.new_vaccinations,
		SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location_ ORDER BY cd.location_, cd.date_) as RollingPeopleVaccinated
	FROM covid_death as cd
	JOIN covid_vaccination as cv
	ON cd.location_ = cv.location_
	AND cd.date_ = cv.date_
	WHERE cd.continent is not null;

SELECT *, (RollingPeopleVaccinated/population)*100 as rolling_percent
FROM PercentPopulationVaccinated;

-- Creating view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated as 
SELECT cd.continent, cd.location_, cd.date_, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location_ ORDER BY cd.location_, cd.date_) as RollingPeopleVaccinated
FROM covid_death as cd
JOIN covid_vaccination as cv
	ON cd.location_ = cv.location_
	AND cd.date_ = cv.date_
WHERE cd.continent is not null


