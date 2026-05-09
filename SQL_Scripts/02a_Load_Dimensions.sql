-- ============================================================
-- ETL — Chargement initial des Dimensions
-- Exécuter APRÈS : 01_Staging_BulkInsert_v3.sql
--                  00_Populate_DimDate.sql
-- Exécuter AVANT  : 02b_Fix_Dimensions.sql (si correction nécessaire)
--                   03_Load_FactSales.sql
-- Datasets : stg_Superstore + stg_CustomerBehavior
-- Date : 2026-05-09
-- ============================================================

USE DW_Ecommerce;
GO

-- ============================================================
-- VÉRIFICATION PRÉALABLE : staging chargé ?
-- ============================================================
SELECT 'stg_Superstore'        AS [Table], COUNT(*) AS [Lignes] FROM stg_Superstore        UNION ALL
SELECT 'stg_CustomerBehavior',              COUNT(*)              FROM stg_CustomerBehavior;
-- Attendu : ~9986 lignes pour stg_Superstore, ~350 pour stg_CustomerBehavior
-- Si 0 ligne → relancez 01_Staging_BulkInsert_v3.sql d'abord
GO

-- ============================================================
-- 1. Dim_Ship — Modes d'expédition distincts
-- ============================================================
DELETE FROM Dim_Ship;
GO

INSERT INTO Dim_Ship (ship_mode)
SELECT DISTINCT
    LTRIM(RTRIM(ship_mode))
FROM stg_Superstore
WHERE ship_mode IS NOT NULL
  AND LTRIM(RTRIM(ship_mode)) != '';
GO

SELECT COUNT(*) AS [Dim_Ship - lignes] FROM Dim_Ship;
-- Attendu : 4 lignes (First Class, Second Class, Standard Class, Same Day)
PRINT 'Dim_Ship OK';
GO

-- ============================================================
-- 2. Dim_Geography — Combinaisons ville/état/pays/région uniques
-- ============================================================
DELETE FROM Dim_Geography;
GO

INSERT INTO Dim_Geography (city, state, country, region, postal_code)
SELECT DISTINCT
    LTRIM(RTRIM(city)),
    LTRIM(RTRIM(state)),
    LTRIM(RTRIM(country)),
    LTRIM(RTRIM(region)),
    LTRIM(RTRIM(postal_code))
FROM stg_Superstore
WHERE city    IS NOT NULL AND LTRIM(RTRIM(city))    != ''
  AND country IS NOT NULL AND LTRIM(RTRIM(country)) != '';
GO

SELECT COUNT(*) AS [Dim_Geography - lignes] FROM Dim_Geography;
-- Attendu : ~631 lignes
PRINT 'Dim_Geography OK';
GO

-- ============================================================
-- 3. Dim_Product — Produits distincts depuis stg_Superstore
-- GROUP BY product_id pour éviter les doublons de noms
-- ============================================================
DELETE FROM Dim_Product;
GO

INSERT INTO Dim_Product (product_id, product_name, category, sub_category)
SELECT
    LTRIM(RTRIM(product_id)),
    MIN(LTRIM(RTRIM(product_name))),
    MIN(LTRIM(RTRIM(category))),
    MIN(LTRIM(RTRIM(sub_category)))
FROM stg_Superstore
WHERE product_id IS NOT NULL
  AND LTRIM(RTRIM(product_id)) != ''
GROUP BY LTRIM(RTRIM(product_id));
GO

SELECT COUNT(*) AS [Dim_Product - lignes] FROM Dim_Product;
-- Attendu : ~1850 lignes
PRINT 'Dim_Product OK';
GO

-- ============================================================
-- 4. Dim_Customer — Clients enrichis avec données comportementales
-- Jointure approximative SS ↔ CB par rang (rn % 350)
-- car les deux datasets n'ont pas de clé commune directe
-- ============================================================
DELETE FROM Dim_Customer;
GO

;WITH SS AS (
    SELECT
        LTRIM(RTRIM(customer_id))       AS customer_id,
        MIN(LTRIM(RTRIM(customer_name))) AS customer_name,
        MIN(LTRIM(RTRIM(segment)))       AS segment,
        ROW_NUMBER() OVER (ORDER BY MIN(LTRIM(RTRIM(customer_id)))) AS rn
    FROM stg_Superstore
    WHERE customer_id IS NOT NULL
      AND LTRIM(RTRIM(customer_id)) != ''
    GROUP BY LTRIM(RTRIM(customer_id))
),
CB AS (
    SELECT
        LTRIM(RTRIM(gender))                          AS gender,
        TRY_CAST(age AS INT)                          AS age,
        LTRIM(RTRIM(membership_type))                 AS membership_type,
        LTRIM(RTRIM(satisfaction_level))              AS satisfaction_level,
        TRY_CAST(average_rating AS DECIMAL(3,2))      AS avg_rating,
        ROW_NUMBER() OVER (ORDER BY customer_id)      AS rn
    FROM stg_CustomerBehavior
)
INSERT INTO Dim_Customer
    (customer_id, customer_name, segment, gender, age, membership_type, satisfaction, avg_rating)
SELECT
    ss.customer_id,
    ss.customer_name,
    ss.segment,
    cb.gender,
    cb.age,
    cb.membership_type,
    cb.satisfaction_level,
    cb.avg_rating
FROM SS
LEFT JOIN CB ON (ss.rn % 350) + 1 = cb.rn;
GO

SELECT COUNT(*) AS [Dim_Customer - lignes] FROM Dim_Customer;
-- Attendu : ~793 lignes
PRINT 'Dim_Customer OK';
GO

-- ============================================================
-- VÉRIFICATION FINALE — Toutes les dimensions
-- ============================================================
SELECT [Table], [Lignes] FROM (
    SELECT 'Dim_Date'      AS [Table], COUNT(*) AS [Lignes] FROM Dim_Date      UNION ALL
    SELECT 'Dim_Ship',                  COUNT(*)              FROM Dim_Ship      UNION ALL
    SELECT 'Dim_Geography',             COUNT(*)              FROM Dim_Geography UNION ALL
    SELECT 'Dim_Product',               COUNT(*)              FROM Dim_Product   UNION ALL
    SELECT 'Dim_Customer',              COUNT(*)              FROM Dim_Customer
) t
ORDER BY [Table];
GO

PRINT ' Toutes les dimensions chargées — Passez au script 03_Load_FactSales.sql';
PRINT ' En cas de lignes manquantes dans Dim_Product ou Dim_Customer → relancez 02b_Fix_Dimensions.sql';
GO
