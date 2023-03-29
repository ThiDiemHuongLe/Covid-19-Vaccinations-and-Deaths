/*1. Import Excel into SQL
I used Wizard 2019, somehow Wizard 2022 did not work*/

/*2. Here are the two datasets*/
Select *
From CovidDeaths$

Select *
From CovidVaccinations$

Select Location, Date, Total_cases, New_cases, total_deaths, population
From CovidDeaths$
Order by 1,2

/*3. What is the percentage of people who died among those who 
were infected*/
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from CovidDeaths$
where location = 'Canada'
order by 1,2
/*As of 30th April 2021, Canada had 24k deaths among over 1.2 mil cases
, so deathrate is about 1.97%
The likelihood of you dying if you contract the virus by ea country*/

/*4. What is the percentage of population contracting the virus?*/
Select Location, date, total_cases, population, (total_cases/population)*100 as CovidRate
from CovidDeaths$
where location = 'Canada'
order by 1,2
/*As of 30th April 2021, there was 3.25% population contracting Covid*/

/*5. Which country has the highest infection rate compared to population?*/
Select location,population, max(total_cases) as HighestInfectionCountry , max((total_cases/population))*100 as InfectionRate
from CovidDeaths$
group by Location, population
order by InfectionRate desc

/*6. Which country has the highest death count per population?*/
Select location,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null /*to filter out errors of location
Word Europe - when continent is Null then location is that continent
 - error*/
group by Location
order by TotalDeathCount desc
/*So the US is the country who recorded highest number of deaths*/

/*7. Which continent has the highest death count per population*/
/* Better code
Select location,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is null 
group by location
order by TotalDeathCount desc*/

Select continent,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null 
group by continent
order by TotalDeathCount desc

/*8. total number of cases + death across the globe per day*/
Select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths
/*to convert data type as nvarchar into int for code to work*/
from CovidDeaths$
where continent is not null
group by date
order by date

/*9. Total number of cases and deaths from beginning till april 21*/
Select  sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths
/*to convert data type as nvarchar into int for code to work*/
from CovidDeaths$
where continent is not null

/*10. Joining the two tables based on Location and date as
these two are specific*/
Select *
from CovidDeaths$ as Dea
join CovidVaccinations$ as Vac
on Dea.location = Vac.location
and Dea.date = Vac.date


/*11. What is the percentage of vaccination across population*/
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population)*100
from CovidDeaths$ as Dea
join CovidVaccinations$ as Vac
on Dea.location = Vac.location
and Dea.date = Vac.date
where dea.continent is not null
order by 2,3

/*Code explanation:
- Why Partition by Location? We want to get the sum by each location
or country; then we want it to roll over from this day to next day showing
total; then we want it to stop by each country and start new with new country
*/


/*CTE*/
With PopvsVac (Continent, Location, Date, Population,new_vaccinations,RollingPeopleVaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths$ as Dea
join CovidVaccinations$ as Vac
on Dea.location = Vac.location
and Dea.date = Vac.date
where dea.continent is not null
--order by 2,3
)

Select *,(RollingPeopleVaccinated/population)*100
from PopvsVac

/*Temp table*/
Create table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths$ as Dea
join CovidVaccinations$ as Vac
on Dea.location = Vac.location
and Dea.date = Vac.date
where dea.continent is not null

Select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

/*Create view to store data for later visuals*/

Create View PercentPopulationVaccined as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
from CovidDeaths$ as Dea
join CovidVaccinations$ as Vac
on Dea.location = Vac.location
and Dea.date = Vac.date
where dea.continent is not null
