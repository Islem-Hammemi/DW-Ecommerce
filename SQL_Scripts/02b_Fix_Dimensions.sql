-- ============================================================
-- SCRIPT CORRECTIF — Relancer les dimensions qui ont échoué
-- Exécuter dans SSMS si Dim_Product et Dim_Customer = 0 lignes
-- ============================================================

USE DW_Ecommerce;
GO

-- Vérifier l'état actuel
SELECT 'Dim_Ship'     AS [Table], COUNT(*) AS [Lignes] FROM Dim_Ship      UNION ALL
SELECT 'Dim_Geography',            COUNT(*)              FROM Dim_Geography UNION ALL
SELECT 'Dim_Product',              COUNT(*)              FROM Dim_Product   UNION ALL
SELECT 'Dim_Customer',             COUNT(*)              FROM Dim_Customer;
GO

-- ============================================================
-- Vider Dim_Product et Dim_Customer (Fact_Sales vide = pas de FK)
-- ============================================================
DELETE FROM Fact_Sales;  -- D'abord Fact_Sales (dépend des dimensions)
DELETE FROM Dim_Customer;
DELETE FROM Dim_Product;
GO
PRINT 'Tables vidées OK';

-- ============================================================
-- Dim_Product — correction : GROUP BY au lieu de DISTINCT
-- Résout le problème de même product_id avec noms différents
-- ============================================================
INSERT INTO Dim_Product (product_id, product_name, category, sub_category)
SELECT
    LTRIM(RTRIM(product_id)),
    MIN(LTRIM(RTRIM(product_name))),   -- prendre le premier nom
    MIN(LTRIM(RTRIM(category))),
    MIN(LTRIM(RTRIM(sub_category)))
FROM stg_Superstore
WHERE product_id IS NOT NULL AND LTRIM(RTRIM(product_id)) != ''
GROUP BY LTRIM(RTRIM(product_id));
GO

SELECT COUNT(*) AS [Dim_Product - lignes] FROM Dim_Product;
-- Attendu : ~1850 lignes
PRINT 'Dim_Product OK';
GO

-- ============================================================
-- Dim_Customer — correction : GROUP BY au lieu de DISTINCT
-- ============================================================
;WITH SS AS (
    SELECT
        LTRIM(RTRIM(customer_id))   AS customer_id,
        MIN(LTRIM(RTRIM(customer_name))) AS customer_name,
        MIN(LTRIM(RTRIM(segment)))   AS segment,
        ROW_NUMBER() OVER (ORDER BY MIN(LTRIM(RTRIM(customer_id)))) AS rn
    FROM stg_Superstore
    WHERE customer_id IS NOT NULL AND LTRIM(RTRIM(customer_id)) != ''
    GROUP BY LTRIM(RTRIM(customer_id))
),
CB AS (
    SELECT
        gender, TRY_CAST(age AS INT) AS age,
        membership_type, satisfaction_level,
        TRY_CAST(average_rating AS DECIMAL(3,2)) AS avg_r,
        ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
    FROM stg_CustomerBehavior
)
INSERT INTO Dim_Customer (customer_id, customer_name, segment, gender, age, membership_type, satisfaction, avg_rating)
SELECT ss.customer_id, ss.customer_name, ss.segment,
    cb.gender, cb.age, cb.membership_type, cb.satisfaction_level, cb.avg_r
FROM SS
LEFT JOIN CB ON (ss.rn % 350) + 1 = cb.rn;
GO

SELECT COUNT(*) AS [Dim_Customer - lignes] FROM Dim_Customer;
-- Attendu : ~793 lignes
PRINT 'Dim_Customer OK';
GO

-- ============================================================
-- Vérification de toutes les dimensions
-- ============================================================
SELECT 'Dim_Date'      AS [Table], COUNT(*) AS [Lignes] FROM Dim_Date      UNION ALL
SELECT 'Dim_Ship',                  COUNT(*)              FROM Dim_Ship      UNION ALL
SELECT 'Dim_Geography',             COUNT(*)              FROM Dim_Geography UNION ALL
SELECT 'Dim_Product',               COUNT(*)              FROM Dim_Product   UNION ALL
SELECT 'Dim_Customer',              COUNT(*)              FROM Dim_Customer;
GO

PRINT '✅ Dimensions OK — Exécutez maintenant 03_Load_FactSales.sql';
