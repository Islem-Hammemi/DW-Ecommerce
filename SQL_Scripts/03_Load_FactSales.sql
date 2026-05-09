-- ============================================================
-- ETL v3 : Dim_Date + Fact_Sales
-- Exécuter APRÈS 02_Load_Dimensions.sql
-- ============================================================

USE DW_Ecommerce;
GO

-- Vérifier Dim_Date (doit avoir ~4383 lignes)
SELECT COUNT(*) AS [Dim_Date - lignes] FROM Dim_Date;
-- Si 0 : exécutez d'abord le script Populate_DimDate.sql
GO

-- Charger Fact_Sales
INSERT INTO Fact_Sales (date_id, customer_id, product_id, geo_id, ship_id,
    order_id, quantity, unit_price, discount, total_sales, profit)
SELECT
    d.date_id,
    LTRIM(RTRIM(ss.customer_id)),
    LTRIM(RTRIM(ss.product_id)),
    g.geo_id, sh.ship_id,
    LTRIM(RTRIM(ss.order_id)),
    TRY_CAST(ss.quantity   AS INT),
    TRY_CAST(ss.unit_price AS DECIMAL(10,2)),
    TRY_CAST(ss.discount   AS DECIMAL(5,4)),
    TRY_CAST(ss.sales      AS DECIMAL(10,2)),
    TRY_CAST(ss.profit     AS DECIMAL(10,2))
FROM stg_Superstore ss
INNER JOIN Dim_Date d ON d.full_date = TRY_CAST(ss.order_date AS DATE)
INNER JOIN Dim_Customer c ON c.customer_id = LTRIM(RTRIM(ss.customer_id))
INNER JOIN Dim_Product p ON p.product_id = LTRIM(RTRIM(ss.product_id))
INNER JOIN Dim_Geography g
    ON g.city = LTRIM(RTRIM(ss.city)) AND g.state = LTRIM(RTRIM(ss.state))
INNER JOIN Dim_Ship sh ON sh.ship_mode = LTRIM(RTRIM(ss.ship_mode))
WHERE ss.order_id IS NOT NULL AND TRY_CAST(ss.order_date AS DATE) IS NOT NULL;
GO

-- Vérification finale
SELECT [Table], [Lignes] FROM (
    SELECT 'Dim_Date'      AS [Table], COUNT(*) AS [Lignes] FROM Dim_Date      UNION ALL
    SELECT 'Dim_Customer',              COUNT(*)              FROM Dim_Customer  UNION ALL
    SELECT 'Dim_Product',               COUNT(*)              FROM Dim_Product   UNION ALL
    SELECT 'Dim_Geography',             COUNT(*)              FROM Dim_Geography UNION ALL
    SELECT 'Dim_Ship',                  COUNT(*)              FROM Dim_Ship      UNION ALL
    SELECT 'Fact_Sales',                COUNT(*)              FROM Fact_Sales
) t;

-- Aperçu
SELECT TOP 5 f.order_id, d.full_date, c.customer_name, p.category,
    g.city, sh.ship_mode, f.quantity, f.total_sales, f.profit, f.profit_margin
FROM Fact_Sales f
JOIN Dim_Date d ON f.date_id = d.date_id
JOIN Dim_Customer c ON f.customer_id = c.customer_id
JOIN Dim_Product p ON f.product_id = p.product_id
JOIN Dim_Geography g ON f.geo_id = g.geo_id
JOIN Dim_Ship sh ON f.ship_id = sh.ship_id;
GO

PRINT ' DW_Ecommerce prêt ! Connectez Power BI maintenant.';
