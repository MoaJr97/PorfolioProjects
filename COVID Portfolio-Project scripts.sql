--Importing table 1
select * from CovidVaccinations;

select count(iso_code)from CovidVaccinations;

select new_vaccinations from CovidVaccinations
where new_vaccinations is not null;

select * from CovidDeaths;

select location,date,total_cases,new_cases,total_deaths,population from CovidDeaths
order by 1,2;
--The data proves to be correct after import!


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
select location,date,total_cases,total_deaths,(cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage from CovidDeaths
where location like '%State%'
order by 1,2;


-- Looking at Total Cases vs Population
-- Showing what percentage of population got Covid
select location,date,total_cases,total_deaths,(cast(total_cases as float)/population)*100 as DeathPercentage1 from CovidDeaths
-- where location like '%State%'
order by 1,2;


-- Looking at Country With Highest Infection Rate Compared to Population
select location, population, max(cast(total_cases as float)) as HighestInfectionCount, max((cast(total_cases as float)/population))*100 as PercentagePopulationInfected 
from CovidDeaths
group by location, population
order by PercentagePopulationInfected desc;


-- Showing Contries with Highest Death Count per Population
select location, population, MAX(CAST(total_deaths as float)) as TotalDeathCount from CovidDeaths
group by location, population
order by TotalDeathCount desc;


-- Let's break things down by continent (# when i put 'where continent is null' gives an error!)
select continent, max(cast(total_deaths as float)) as TotalDeathCount from CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


-- Showing continents with the highest death count per population
select Continent, MAX(CAST(total_deaths as float)/population) as TotalDeathCount 
from coviddeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


-- Global Numbers with date (#due to an error, the 'COALESCE' function was used)
select date, sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths,
CASE
	WHEN SUM(CAST(new_deaths as float)) = 0 THEN 0
	ELSE sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100
END as DeathPercentage
From CovidDeaths
-- where location like '%states%'
where continent is not null
group by date
order by 1,2;


-- Global Numbers
select sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths, sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage3 from CovidDeaths
-- where location like '%states%'
where continent is not null
-- group by date
order by 1,2;


-- Inserting a new tabel
-- Looking the table of vaccinates
select * from CovidVaccinations;


-- Counting lines
select count(location) from CovidVaccinations; --(409.990 lines)


-- Analysing columns
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'CovidVaccinations' AND TABLE_SCHEMA = 'dbo';


-- Join the tables
select * from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date;


-- Looking at Total Population vs Vaccinations
select
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location) as total_vaccinations
from CovidDeaths dea
	join 
	CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where
	dea.continent is not null;


-- Looking at Total Population vs Vaccinations
select
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths dea
	join 
	CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where
	dea.continent is not null
order by 1,2,3;


-- Looking at Total Population vs Vaccinations
select
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated -- (RollingPeopleVaccinated/population)*100,
from CovidDeaths dea
	join 
	CovidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where
	dea.continent is not null
order by 2,3;


--Use CTE
with PopvsVac as (
select dea.continent, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations))
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
SELECT continent, date, population, new_vaccinations, RollingPeopleVaccinated,
       (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM PopvsVac
ORDER BY date, population; 
--select *, (RollingPeopleVaccinated/Population)*100
--from PopvsVac;


-- Use CTE
with PopvsVac as (
select dea.continent, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations))
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as Percentage_Vac_per_Pop
from PopvsVac;


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations))
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as Percentage_Vac_per_Pop
from #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations))
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3;


-- Visualization
Select * 
from PercentPopulationVaccinated