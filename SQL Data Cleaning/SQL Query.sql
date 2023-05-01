/* 

Data Cleaning in SQL Queries

*/

---------------------------------------------------------------------------------------------------------------------------------

-- Populate - Address (Physical Location)

UPDATE sqlprojects..museums
SET [Address (Physical Location)] = ISNULL([Address (Physical Location)], [Address (Administrative Location)])

UPDATE sqlprojects..museums
SET [Zip Code (Physical Location)] = ISNULL([Zip Code (Physical Location)], [Zip Code (Administrative Location)])

---------------------------------------------------------------------------------------------------------------------------------

-- Breaking Administrative address into individual columns

ALTER TABLE sqlprojects..museums
ADD [Street (Administrative Location)] varchar(255)

UPDATE sqlprojects..museums
SET [Street (Administrative Location)] = SUBSTRING([Address (Administrative Location)], 1, CHARINDEX(',', [Address (Administrative Location)])-1)

ALTER TABLE sqlprojects..museums
ADD [City (Administrative Location)] varchar(255)

UPDATE sqlprojects..museums
SET [City (Administrative Location)] = SUBSTRING([Address (Administrative Location)], 
												 CHARINDEX(',', [Address (Administrative Location)]) + 2, 
												 CHARINDEX(',', [Address (Administrative Location)], CHARINDEX(',', [Address (Administrative Location)])+1) - CHARINDEX(',', [Address (Administrative Location)])-1)

ALTER TABLE sqlprojects..museums
ADD [State (Administrative Location)] varchar(255)

UPDATE sqlprojects..museums
SET [State (Administrative Location)] = SUBSTRING([Address (Administrative Location)], 
												  CHARINDEX(',', [Address (Administrative Location)], CHARINDEX(',', [Address (Administrative Location)])+1) + 2, 100)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking Physical address into individual columns

ALTER TABLE sqlprojects..museums
ADD [Street (Physical Location)] varchar(255)

UPDATE sqlprojects..museums
SET [Street (Physical Location)] = PARSENAME(REPLACE([Address (Physical Location)], ',', '.'),3)

ALTER TABLE sqlprojects..museums
ADD [City (Physical Location)] varchar(255)

UPDATE sqlprojects..museums
SET [City (Physical Location)] = PARSENAME(REPLACE([Address (Physical Location)], ',', '.'),2)

ALTER TABLE sqlprojects..museums
ADD [State (Physical Location)] varchar(255)

UPDATE sqlprojects..museums
SET [State (Physical Location)] = PARSENAME(REPLACE([Address (Physical Location)], ',', '.'),1)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (
	   PARTITION BY [Museum Name],
					[Museum Type],
					[Address (Administrative Location)], 
					[Tax Period]
					ORDER BY
						[Museum ID]
					) row_num
FROM sqlprojects..museums
)

DELETE
FROM RowNumCTE
WHERE row_num > 1

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populating Phone Number based on Zip Code, Longitude And Latitude

UPDATE M1
SET [Phone Number] = ISNULL(M1.[Phone Number], M2.[Phone Number])
FROM sqlprojects..museums M1 LEFT JOIN sqlprojects..museums M2 ON M1.[Museum Name] = M2.[Museum Name] AND 
																  M1.[Museum Type] = M2.[Museum Type] AND 
																  M1.[Address (Administrative Location)] = M2.[Address (Administrative Location)] AND 
																  M1.[Phone Number] IS NULL AND 
																  M2.[Phone Number] IS NOT NULL 

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Replace Null With Zeroes

UPDATE sqlprojects..museums
SET Income = ISNULL(Income, 0),
	Revenue = ISNULL(Revenue, 0)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Drop Unwanted Columns

ALTER TABLE sqlprojects..museums
DROP COLUMN IF EXISTS [Locale Code (NCES)], 
     COLUMN IF EXISTS [County Code (FIPS)], 
	 COLUMN IF EXISTS [State Code (FIPS)], 
	 COLUMN IF EXISTS [Region Code (AAM)]

SELECT * FROM sqlprojects..museums

-------------------------------------------------------------------------------------END----------------------------------------------------------------------------------------------------------------