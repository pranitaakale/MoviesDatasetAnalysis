
---- I] Data Cleaning =============================================================================================================================


WITH getyearrange AS (
SELECT *, 
TRIM(replace(Replace(Replace([Year],'(', ' '), ')',' '),'–','-')) as YearRange
FROM dbo.movies WITH(NOLOCK)
),
eliminatespaces as (
	SELECT *,
	CASE 
		WHEN CHARINDEX(' ',YearRange)>4 
			THEN Trim(SUBSTRING(YearRange,1,CHARINDEX(' ',YearRange)))
		WHEN CHARINDEX(' ',YearRange) between 1 and 4  
			THEN TRIM(SUBSTRING(YearRange,CHARINDEX(' ',YearRange)+2,len(YearRange)))
		ELSE Trim(YearRange)
	END AS YearRange2
	FROM getyearrange
),
CleanedYear as (
SELECT --*,
	MOVIES, 
	CASE
		WHEN len(YearRange2)<4 THEN '0'
		WHEN len(YearRange2)=5 THEN concat(YearRange2,'2024')
		WHEN len(YearRange2)>9 THEN SUBSTRING(YearRange2,1,5) --exceptional case
		ELSE YearRange2
	END AS YearRange3, GENRE, RATING,ONE_LINE, STARS,VOTES,RunTime,Gross
FROM eliminatespaces
),
separateyear as(
SELECT Movies,YearRange3,
CASE 
	WHEN CHARINDEX('-', YearRange3,1)>0 Then Replace(SUBSTRING(YearRange3,1,CHARINDEX('-', YearRange3,1)),'-','')
	ELSE YearRange3
END AS StartYear,
CASE 
	WHEN CHARINDEX('-', YearRange3,1)>0 Then Replace(SUBSTRING(YearRange3,CHARINDEX('-', YearRange3,1),len(YearRange3)),'-','')
	ELSE YearRange3
END AS EndYear,
GENRE,RATING,ONE_LINE,STARS,VOTES,RunTime,Gross
FROM CleanedYear
),
consistentcols as (
	SELECT *, replace(replace(trim(REPLACE(STARS, CHAR(10), ' ')),'Directors','Director'),'Stars','Star') as updated_stars
	FROM separateyear
),
getindexes as (
	SELECT *,
	CHARINDEX('|',updated_stars) as SplitIndex
	FROM consistentcols
),
splitcols as (
	SELECT *,
	Trim(Replace(Replace(SUBSTRING(updated_stars,1,SplitIndex),'|',''),'Director:','')) as Director,
	Trim(Replace(Replace(SUBSTRING(updated_stars,SplitIndex,len(updated_stars)),'|',''),'Star:','')) as [Cast]
	FROM getindexes
),
CleanedCols as(
SELECT MOVIES,YearRange3,ISNULL(try_cast(StartYear as int),0) StartYear,ISNULL(try_cast(EndYear as int),0) EndYear,
trim(REPLACE(GENRE, CHAR(10), ' ')) GENRE,RATING,ONE_LINE,Director,[CAST],cast(Replace(Votes,',','') as int) VOTES,cast(Rating as float) RunTime,Gross
FROM splitcols
)
SELECT *
--into #TempCleanedCols
FROM CleanedCols 



---- II] Data Analysis ==============================================================================================================================

---- Review Cleaned Data
SELECT *
FROM #TempCleanedCols


---- 1] How has the number of movies and TV shows released each year changed over time?
SELECT startyear, count(*) AS NumReleased
FROM #TempCleanedCols
group by startyear
order by 1

---- 2] What are the trends in ratings and votes over the years?
SELECT startyear,sum(Votes) TotalVotesPerYear,avg(Rating) AvgRatingsPerYear
FROM #TempCleanedCols
group by StartYear
order by 1


---- 3] Which genres are the most popular among viewers?
--SELECT distinct genre
--FROM #TempCleanedCols
--where genre not like '%,%'

--SELECT genre,SplitValues.value
--FROM #TempCleanedCols
--CROSS APPLY STRING_SPLIT(genre, ',') AS SplitValues

--SELECT genre, count(*)
--FROM #TempCleanedCols
--group by genre
--order by 2 desc

with getcombinedcount as (
	SELECT genre, count(*) as C1
	FROM #TempCleanedCols
	group by genre
),
splitgenres as(
	SELECT *
	FROM getcombinedcount
	CROSS APPLY STRING_SPLIT(genre, ',') AS SplitValues
)
SELECT value, sum(C1)
FROM splitgenres
group by value
order by 2 desc


---- 4] How does the popularity of different genres vary by year? || Are there any trends in the popularity of specific genres over time?
with getcombinedcount as (
	SELECT StartYear,genre, count(*) as C1
	FROM #TempCleanedCols
	group by StartYear,genre
),
splitgenres as (
SELECT StartYear, trim(genre) Genre, trim(SplitValues.value) as SplitGenre, C1
FROM getcombinedcount
CROSS APPLY STRING_SPLIT(genre, ',') AS SplitValues
)
SELECT StartYear,SplitGenre, sum(C1)
FROM splitgenres
where SplitGenre like '%Drama%'            
group by StartYear,SplitGenre
order by 1,2



---- 5] Which movies or TV shows have the highest ratings and votes?
SELECT MOVIES, count(Votes), avg(Rating)
FROM #TempCleanedCols
group by MOVIES





