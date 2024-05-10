/*

A Project for the Seattle Department of Transportation: Preparation for data visualisation 

*/

-- Identifying the total number of collisions
SELECT count(*)
FROM PortfolioProject.dbo.SeattleCollision

-- Updating date columns into a DATE format
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD DATE_UPD Date;

UPDATE PortfolioProject.dbo.SeattleCollision
SET DATE_UPD = CONVERT(Date, DATE);

-- Converting the values from the 'time' column into readible time formats
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD N_TIME TIME;

UPDATE PortfolioProject.dbo.SeattleCollision
SET N_TIME = CAST(DATEADD(MINUTE, TIME * 60, '00:00') AS TIME);

ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD TIME_UPD NVARCHAR(255);

UPDATE PortfolioProject.dbo.SeattleCollision
SET TIME_UPD = CONVERT(NVARCHAR(255), N_TIME, 108);

-- Creating a filter for good vs poor driving conditions
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD POORDRIVINGCOND bit;
UPDATE PortfolioProject.dbo.SeattleCollision
SET POORDRIVINGCOND = CASE 
		WHEN WEATHER = 'Clear' AND ROADCOND = 'Dry' THEN 0
		ELSE 1
	END;

-- Creating a function for determining Daylight vs Nightime
CREATE FUNCTION FINDTIMEOFDAY(
    @CollisionDate DATE,
    @CollisionTime TIME)
RETURNS VARCHAR(8)
AS
BEGIN
    DECLARE @MONTHN INT;
    DECLARE @SUNRISE TIME;
    DECLARE @SUNSET TIME;
    SELECT @MONTHN = MONTH(@CollisionDate);
    SELECT @SUNRISE = SUNRISE, @SUNSET = SUNSET
    FROM PortfolioProject.dbo.SeattleSunriseSunset
    WHERE MONTHN = @MONTHN;
    RETURN CASE 
        WHEN @CollisionTime >= @SUNRISE AND @CollisionTime < @SUNSET THEN 'Daylight'
        ELSE 'Night'
    END;
END;

-- Adding a new column 'TimeOfDay' to the  original dataframe
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD TIMEOFDAY AS dbo.FINDTIMEOFDAY(DATE_UPD, N_TIME);

-- Crating a filter for Nightime 
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD NIGHTTIME bit;
UPDATE PortfolioProject.dbo.SeattleCollision
SET NIGHTTIME = CASE 
		WHEN TIMEOFDAY = 'Daylight' THEN 0
		ELSE 1
	END;

-- Adding more descriptive labels to the Severity column
ALTER TABLE PortfolioProject.dbo.SeattleCollision
ADD SEVERITY nvarchar(255);
UPDATE PortfolioProject.dbo.SeattleCollision
SET SEVERITY = CASE 
		WHEN SEVERITYCODE = 3 THEN '3—fatality'
		WHEN SEVERITYCODE = 2 THEN '2—injury'
		WHEN SEVERITYCODE = 1 THEN '1—property damage'
		ELSE '0—unknown'
	END;

-- Ordering the columns and omitting the columns that are less relevant
SELECT DATE_UPD, TIME_UPD, TIMEOFDAY, SEVERITY, COLLISIONTYPE, JUNCTIONTYPE, INATTENTIONIND, UNDERINFL, SPEEDING, HITPARKEDCAR, POORDRIVINGCOND, NIGHTTIME, intersection_related
FROM PortfolioProject.dbo.SeattleCollision
ORDER BY DATE_UPD ASC

-- Calculating the number of collisions per year and n of people affected
SELECT
    YEAR(DATE_UPD) AS COLLISION_YEAR,
    COUNT(*) AS COLLISIONS_PER_YEAR,
    SUM(PERSONCOUNT) AS TOTAL_AFFECTED
FROM PortfolioProject.dbo.SeattleCollision
GROUP BY YEAR(DATE_UPD)
ORDER BY COLLISIONS_PER_YEAR DESC;

-- Calculating the number of collisions per month and n of people affected
SELECT 
    MONTH(DATE_UPD) AS COLLISION_MONTH,
    COUNT(*) AS COLLISIONS_PER_MONTH,
    SUM(PERSONCOUNT) AS TOTAL_AFFECTED
FROM PortfolioProject.dbo.SeattleCollision
GROUP BY MONTH(DATE_UPD)
ORDER BY COLLISIONS_PER_MONTH DESC;

-- Including a rolling count of collisions 
SELECT DATE_UPD,
	      SUM(COLLCOUNT) OVER (ORDER BY DATE_UPD ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ROLLCOUNT
FROM (SELECT DATE_UPD,
      COUNT(*) AS COLLCOUNT
      FROM PortfolioProject.dbo.SeattleCollision
      GROUP BY DATE_UPD) AS subquery
ORDER BY ROLLCOUNT DESC;

-- Examining the number of collisions that ended in injuries vs fatalities
SELECT 
    COUNT(*) AS TOTAL_COLLISIONS,
    SUM(CASE WHEN FATALITIES > 0 THEN 1 ELSE 0 END) AS TOTAL_FATAL_COLLISIONS,
    (SUM(CASE WHEN FATALITIES > 0 THEN 1.0 ELSE 0 END) / COUNT(*)) * 100.0 AS PERCENTAGE_FATAL_COLLISIONS,
    SUM(CASE WHEN INJURIES > 0 THEN 1 ELSE 0 END) AS TOTAL_INJURIES,
    (SUM(CASE WHEN INJURIES > 0 THEN 1.0 ELSE 0 END) / COUNT(*)) * 100.0 AS PERCENTAGE_INJURIES
FROM 
    PortfolioProject.dbo.SeattleCollision;

-- Determining what factors were more prevalent across all collisions
SELECT 
    COUNT(*) AS TOTAL_COLLISIONS,
    (SUM(CASE WHEN INATTENTIONIND = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_INATTENTIONIND,
    (SUM(CASE WHEN UNDERINFL = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_UNDERINFL,
    (SUM(CASE WHEN SPEEDING = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_SPEEDING,
    (SUM(CASE WHEN HITPARKEDCAR = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_HITPARKEDCAR,
    (SUM(CASE WHEN POORDRIVINGCOND = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_POORDRIVINGCOND,
    (SUM(CASE WHEN NIGHTTIME = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_NIGHTTIME,
    (SUM(CASE WHEN intersection_related = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS PERC_INTERSECT_RELATED
FROM PortfolioProject.dbo.SeattleCollision;

-- Determining what factors were more prevalent during collisions that resulted in injuries
SELECT 
    SUM(INJURIES) AS TOTAL_INJURIES,
    SUM(CASE WHEN INATTENTIONIND = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_INATTENTIONIND,
    SUM(CASE WHEN UNDERINFL = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_UNDERINFL,
    SUM(CASE WHEN SPEEDING = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_SPEEDING,
    SUM(CASE WHEN HITPARKEDCAR = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_HITPARKEDCAR,
    SUM(CASE WHEN POORDRIVINGCOND = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_POORDRIVINGCOND,
    SUM(CASE WHEN NIGHTTIME = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_NIGHTTIME,
    SUM(CASE WHEN intersection_related = 1 THEN 1 ELSE 0 END) / SUM(INJURIES) * 100.0 AS PERC_INTERSECT_RELATED
FROM PortfolioProject.dbo.SeattleCollision
WHERE INJURIES > 0;

-- Determining what factors were more prevalent during collisions that resulted in fatalities
SELECT 
    SUM(FATALITIES) AS TOTAL_FATALITIES,
    SUM(CASE WHEN INATTENTIONIND = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_INATTENTIONIND,
    SUM(CASE WHEN UNDERINFL = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_UNDERINFL,
    SUM(CASE WHEN SPEEDING = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_SPEEDING,
    SUM(CASE WHEN HITPARKEDCAR = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_HITPARKEDCAR,
    SUM(CASE WHEN POORDRIVINGCOND = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_POORDRIVINGCOND,
    SUM(CASE WHEN NIGHTTIME = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_NIGHTTIME,
    SUM(CASE WHEN intersection_related = 1 THEN 1 ELSE 0 END) / SUM(FATALITIES) * 100.0 AS PERC_INTERSECT_RELATED
FROM PortfolioProject.dbo.SeattleCollision
WHERE FATALITIES > 0;

-- Removing the redundant columns
ALTER TABLE PortfolioProject.dbo.SeattleCollision
DROP COLUMN SPDCASENO, SEVERITYCODE, LIGHTCOND, DATE, TIME