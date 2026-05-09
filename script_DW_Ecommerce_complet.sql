-- ============================================================
-- Data Warehouse DW_Ecommerce
-- Script complet de création du Star Schema
-- Data Warehouse + Modélisation
-- Date : 2026-05-08
-- Datasets : Sample - Superstore.csv + E-commerce Customer Behavior.csv
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_Ecommerce')
BEGIN
    ALTER DATABASE DW_Ecommerce SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_Ecommerce;
END
GO

CREATE DATABASE DW_Ecommerce;
GO
USE DW_Ecommerce;
GO

-- ============================================================
-- DIMENSIONS
-- ============================================================

-- 1. Dimension Date
CREATE TABLE Dim_Date (
    date_id        INT PRIMARY KEY,
    full_date      DATE        NOT NULL,
    day            INT         NOT NULL,
    month          INT         NOT NULL,
    month_name     VARCHAR(20) NOT NULL,
    quarter        INT         NOT NULL,
    year           INT         NOT NULL,
    semester       INT         NOT NULL,
    is_weekend     BIT         NOT NULL
);
GO

-- 2. Dimension Client
CREATE TABLE Dim_Customer (
    customer_id       VARCHAR(50)  PRIMARY KEY,
    customer_name     VARCHAR(100) NOT NULL,
    segment           VARCHAR(50),
    gender            VARCHAR(10),
    age               INT,
    membership_type   VARCHAR(50),
    satisfaction      VARCHAR(50),
    avg_rating        DECIMAL(3,2)
);
GO

-- 3. Dimension Géographie
CREATE TABLE Dim_Geography (
    geo_id         INT IDENTITY(1,1) PRIMARY KEY,
    city           VARCHAR(100) NOT NULL,
    state          VARCHAR(100),
    country        VARCHAR(100) NOT NULL,
    region         VARCHAR(50),
    postal_code    VARCHAR(20)
);
GO

-- 4. Dimension Produit
CREATE TABLE Dim_Product (
    product_id       VARCHAR(50)  PRIMARY KEY,
    product_name     VARCHAR(255) NOT NULL,
    category         VARCHAR(100) NOT NULL,
    sub_category     VARCHAR(100) NOT NULL
);
GO

-- 5. Dimension Mode d'expédition
CREATE TABLE Dim_Ship (
    ship_id        INT IDENTITY(1,1) PRIMARY KEY,
    ship_mode      VARCHAR(50) NOT NULL
);
GO

-- ============================================================
-- TABLE DE FAITS
-- ============================================================

CREATE TABLE Fact_Sales (
    sale_id          INT IDENTITY(1,1) PRIMARY KEY,

    -- Clés étrangères vers les dimensions
    date_id          INT          NOT NULL,
    customer_id      VARCHAR(50)  NOT NULL,
    product_id       VARCHAR(50)  NOT NULL,
    geo_id           INT          NOT NULL,
    ship_id          INT          NOT NULL,

    -- Identifiant métier
    order_id         VARCHAR(50)  NOT NULL,

    -- Mesures
    quantity         INT           NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,
    discount         DECIMAL(5,4)  NOT NULL,
    total_sales      DECIMAL(10,2) NOT NULL,
    profit           DECIMAL(10,2) NOT NULL,
    profit_margin    AS (CASE WHEN total_sales = 0 THEN 0
                         ELSE ROUND(profit / total_sales * 100, 2)
                         END),

    -- Contraintes FK
    CONSTRAINT FK_Sales_Date     FOREIGN KEY (date_id)     REFERENCES Dim_Date(date_id),
    CONSTRAINT FK_Sales_Customer FOREIGN KEY (customer_id) REFERENCES Dim_Customer(customer_id),
    CONSTRAINT FK_Sales_Product  FOREIGN KEY (product_id)  REFERENCES Dim_Product(product_id),
    CONSTRAINT FK_Sales_Geo      FOREIGN KEY (geo_id)      REFERENCES Dim_Geography(geo_id),
    CONSTRAINT FK_Sales_Ship     FOREIGN KEY (ship_id)     REFERENCES Dim_Ship(ship_id)
);
GO

-- ============================================================
-- OPTIMISATION : Index sur les colonnes fréquemment filtrées
-- ============================================================

CREATE INDEX IDX_FactSales_DateId     ON Fact_Sales(date_id);
CREATE INDEX IDX_FactSales_CustomerId ON Fact_Sales(customer_id);
CREATE INDEX IDX_FactSales_ProductId  ON Fact_Sales(product_id);
CREATE INDEX IDX_FactSales_GeoId      ON Fact_Sales(geo_id);
CREATE INDEX IDX_FactSales_ShipId     ON Fact_Sales(ship_id);

CREATE INDEX IDX_DimDate_Year    ON Dim_Date(year);
CREATE INDEX IDX_DimDate_Month   ON Dim_Date(month);
CREATE INDEX IDX_DimDate_Quarter ON Dim_Date(quarter);

CREATE INDEX IDX_DimProduct_Category    ON Dim_Product(category);
CREATE INDEX IDX_DimProduct_SubCategory ON Dim_Product(sub_category);

CREATE INDEX IDX_DimGeo_Region  ON Dim_Geography(region);
CREATE INDEX IDX_DimGeo_Country ON Dim_Geography(country);
GO

-- ============================================================
-- VERIFICATION : Clés primaires et étrangères
-- ============================================================

SELECT
    tc.TABLE_NAME,
    kcu.COLUMN_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_NAME     = kcu.TABLE_NAME
WHERE tc.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;
GO
