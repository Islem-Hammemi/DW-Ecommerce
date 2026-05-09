-- ============================================================
-- ETL v3 : BULK INSERT avec fichiers PIPE-DELIMITED (|)
-- Ces fichiers n'ont pas de guillemets → BULK INSERT fonctionne
-- sur toutes versions SQL Server (2012+)
-- !! MODIFIEZ LES CHEMINS selon votre bureau !!
-- ============================================================

USE DW_Ecommerce;
GO

IF OBJECT_ID('stg_Superstore', 'U') IS NOT NULL DROP TABLE stg_Superstore;
IF OBJECT_ID('stg_CustomerBehavior', 'U') IS NOT NULL DROP TABLE stg_CustomerBehavior;
GO

CREATE TABLE stg_Superstore (
    order_id      NVARCHAR(50),
    order_date    NVARCHAR(20),
    ship_date     NVARCHAR(20),
    ship_mode     NVARCHAR(50),
    customer_id   NVARCHAR(50),
    customer_name NVARCHAR(100),
    segment       NVARCHAR(50),
    country       NVARCHAR(100),
    city          NVARCHAR(100),
    state         NVARCHAR(100),
    postal_code   NVARCHAR(20),
    region        NVARCHAR(50),
    product_id    NVARCHAR(50),
    category      NVARCHAR(100),
    sub_category  NVARCHAR(100),
    product_name  NVARCHAR(500),
    sales         NVARCHAR(20),
    quantity      NVARCHAR(10),
    discount      NVARCHAR(10),
    profit        NVARCHAR(20),
    unit_price    NVARCHAR(20)
);
GO

CREATE TABLE stg_CustomerBehavior (
    customer_id              NVARCHAR(20),
    gender                   NVARCHAR(10),
    age                      NVARCHAR(5),
    city                     NVARCHAR(100),
    membership_type          NVARCHAR(50),
    total_spend              NVARCHAR(20),
    items_purchased          NVARCHAR(10),
    average_rating           NVARCHAR(10),
    discount_applied         NVARCHAR(10),
    days_since_last_purchase NVARCHAR(10),
    satisfaction_level       NVARCHAR(50)
);
GO

-- ============================================================
-- !! MODIFIEZ LES DEUX CHEMINS CI-DESSOUS !!
-- Remplacez "user" par votre nom Windows (ex: C:\Users\Ahmed\Desktop\...)
-- ============================================================

BULK INSERT stg_Superstore
FROM 'C:\Users\user\Desktop\Superstore_pipe.csv'
WITH (
    FIELDTERMINATOR = '|',
    ROWTERMINATOR   = '\n',
    FIRSTROW        = 2,
    CODEPAGE        = '1252',
    TABLOCK
);
GO

SELECT COUNT(*) AS [Superstore - lignes chargées] FROM stg_Superstore;
-- Attendu : 9986
GO

BULK INSERT stg_CustomerBehavior
FROM 'C:\Users\user\Desktop\CustomerBehavior_pipe.csv'
WITH (
    FIELDTERMINATOR = '|',
    ROWTERMINATOR   = '\n',
    FIRSTROW        = 2,
    CODEPAGE        = '1252',
    TABLOCK
);
GO

SELECT COUNT(*) AS [CustomerBehavior - lignes chargées] FROM stg_CustomerBehavior;
-- Attendu : 350
GO

PRINT '✅ Staging chargé - Passez au script 02';
