-- Populate_DimDate.sql — Exécuter une seule fois
USE DW_Ecommerce;
GO
DELETE FROM Dim_Date;
GO
DECLARE @d DATE = '2015-01-01', @end DATE = '2026-12-31';
WHILE @d <= @end
BEGIN
    INSERT INTO Dim_Date (date_id, full_date, day, month, month_name, quarter, year, semester, is_weekend)
    VALUES (
        CONVERT(INT, REPLACE(CONVERT(VARCHAR,@d,112),'-','')),
        @d, DAY(@d), MONTH(@d), DATENAME(MONTH,@d),
        DATEPART(QUARTER,@d), YEAR(@d),
        CASE WHEN MONTH(@d)<=6 THEN 1 ELSE 2 END,
        CASE WHEN DATEPART(WEEKDAY,@d) IN (1,7) THEN 1 ELSE 0 END
    );
    SET @d = DATEADD(DAY,1,@d);
END
GO
SELECT COUNT(*) AS total_dates FROM Dim_Date;
PRINT '✅ Dim_Date peuplée';
