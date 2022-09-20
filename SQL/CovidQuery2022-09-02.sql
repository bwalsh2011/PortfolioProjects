
Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data we're going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the US
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what perceentage of the population got Covid
Select Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

Select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as HighestInfectionPopPercent
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
Group by location, population
order by HighestInfectionPopPercent desc

-- Showing countries with Highest Death Count per Population

Select Location, max(cast(Total_Deaths as bigint)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
Group by location
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count
Select continent, max(cast(Total_Deaths as bigint)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as TotalGlobalCases, SUM(cast(new_deaths as int)) as TotalGlobalDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
-- Where location like '%states%'
-- Group by date
order by 1,2

-- Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.location like '%Albania%'
-- where dea.continent is not null
order by 2,3

-- Use CTE

With PopvsVac (Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac


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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3

Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3


Select *
From PercentPopulationVaccinated
