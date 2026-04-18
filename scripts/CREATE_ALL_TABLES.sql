/*
================================================================================
CONSOLIDATED SCRIPT: CREATE ALL TABLES (Staging, Dimensions, Facts)
Shopee Thailand Data Warehouse
Database: ShopeeThailandDW
Created: 2026-04-18
================================================================================
This script creates all staging tables, dimension tables, and fact tables
for the Shopee Thailand DW project.

SCHEMA STRUCTURE:
- staging: Raw data from sources
- dwh: Cleaned dimensions and facts

TABLES:
- 3 Staging tables (TV1: customers, sessions, reviews)
- 3 Staging tables (TV2: products, order_items, orders)
- 5+ Dimension tables
- 2+ Fact tables
================================================================================
*/

-- ============================================================================
-- STEP 0: USE DATABASE & CREATE SCHEMAS
-- ============================================================================
USE master
DROP DATABASE IF EXISTS ShopeeThailandDW;
CREATE DATABASE ShopeeThailandDW;
GO

USE ShopeeThailandDW;
GO

-- Create schemas if not exists
CREATE SCHEMA staging;
GO

CREATE SCHEMA dwh;
GO

PRINT '✓ Database and schemas ready';
GO

-- ============================================================================
-- PART 1: STAGING TABLES - TV1 (Customers, Sessions, Reviews)
-- ============================================================================

PRINT '--- Creating TV1 Staging Tables ---';
GO

CREATE TABLE staging.stg_customers (
    customer_id         VARCHAR(50)   NOT NULL,
    first_name          NVARCHAR(100) NULL,
    last_name           NVARCHAR(100) NULL,
    gender              VARCHAR(10)   NULL,
    dob                 DATE          NULL,
    registration_date   DATE          NULL,
    phone               VARCHAR(20)   NULL,
    email               VARCHAR(100)  NULL,
    province            NVARCHAR(100) NULL,
    city                NVARCHAR(100) NULL,
);
GO

CREATE TABLE staging.stg_sessions (
    session_id          INT           NOT NULL,
    customer_id         VARCHAR(50)   NULL,
    session_date        DATE          NULL,
    session_start_time  DATETIME      NULL,
    session_end_time    DATETIME      NULL,
    utm_source          VARCHAR(50)   NULL,
    campaign_id         VARCHAR(50)   NULL,
    device_type         VARCHAR(20)   NULL,
    order_id            INT           NULL,
);
GO

CREATE TABLE staging.stg_session_activities (
    activity_id         INT           NOT NULL,
    session_id          INT           NULL,
    page_url            VARCHAR(50)   NULL,
    session_start_time  DATETIME      NULL,
    session_end_time    DATETIME      NULL,
);
GO

-- TABLE: stg_reviews
IF OBJECT_ID('staging.stg_reviews', 'U') IS NOT NULL
    DROP TABLE staging.stg_reviews;
GO

CREATE TABLE staging.stg_reviews (
    review_id           INT           NOT NULL,
    review_date         DATE          NULL,
    review_text         TEXT		  NULL,
    order_item_id       INT           NULL,
);
GO

PRINT '✓ TV1 Staging tables created (stg_customers, stg_session_activities, stg_reviews)';
GO

-- ============================================================================
-- PART 2: STAGING TABLES - TV2 (Products, Orders, Order Items)
-- ============================================================================

PRINT '--- Creating TV2 Staging Tables ---';
GO

-- TABLE: stg_products
IF OBJECT_ID('staging.stg_products', 'U') IS NOT NULL
    DROP TABLE staging.stg_products;
GO

CREATE TABLE staging.stg_products (
    product_id        VARCHAR(50)    NOT NULL,
    seller_id         VARCHAR(50)    NULL,
    category          NVARCHAR(100)  NULL,
    product_name      NVARCHAR(100)  NULL,
    maintenance_rate  DECIMAL(5,2)   NULL,
    commission_rate   DECIMAL(5,2)   NULL,
    weight            DECIMAL(10,3)  NULL,
    created_at        DATE           NULL,
);
GO

-- TABLE: stg_order_items
IF OBJECT_ID('staging.stg_order_items', 'U') IS NOT NULL
    DROP TABLE staging.stg_order_items;
GO

CREATE TABLE staging.stg_order_items (
    order_id          INT    NOT NULL,
    order_item_id     INT            NOT NULL,
    product_id        VARCHAR(50)    NOT NULL,
    unit_price        DECIMAL(12,2)  NOT NULL,
    quantity          INT            NULL,
    unit_price_after_discount DECIMAL(12,2)  NULL,
    line_total        DECIMAL(12,2)  NULL,
    discount_percent   DECIMAL(12,2)  NULL,
    commission_amount DECIMAL(12,2)  NULL,
    maintenance_amount DECIMAL(12,2) NULL,
    shipping_fee_item      DECIMAL(12,2)  NULL,
    estimated_delivery_start DATE          NULL,
    estimated_delivery_end   DATE          NULL,
    item_status        VARCHAR(50)    NULL,
    is_campaign         BIT             NULL,
    product_campaign_id VARCHAR(50)    NULL,
);
GO

-- TABLE: stg_orders
IF OBJECT_ID('staging.stg_orders', 'U') IS NOT NULL
    DROP TABLE staging.stg_orders;
GO

CREATE TABLE staging.stg_orders (
    order_id            VARCHAR(50)   NOT NULL,
    order_date          DATE          NOT NULL,
    customer_id         VARCHAR(50)   NULL,
    order_day           DATE           NULL,
    year_month          VARCHAR(10)   NULL,
    subtotal_amount     DECIMAL(12,2) NULL,
    shipping_fee_total  DECIMAL(12,2) NULL,
    commission_total    DECIMAL(12,2) NULL,
    maintenance_total   DECIMAL(12,2) NULL,
    total_amount        DECIMAL(12,2) NULL,
    campaign_id         VARCHAR(50)   NULL,
);
GO

PRINT '✓ TV2 Staging tables created (stg_products, stg_order_items, stg_orders)';
GO

-- ============================================================================
-- PART 3: STAGING TABLES - TV3 (Sellers, Shipments, Campaigns, etc.)
-- ============================================================================

PRINT '--- Creating TV3 Staging Tables ---';
GO

-- TABLE: stg_sellers
IF OBJECT_ID('staging.stg_sellers', 'U') IS NOT NULL
    DROP TABLE staging.stg_sellers;
GO

CREATE TABLE staging.stg_sellers (
    seller_id          VARCHAR(50)    NOT NULL,
    shop_name          NVARCHAR(100)  NULL,
    seller_type        VARCHAR(50)    NULL,
    email			   VARCHAR(100)   NULL,
    contact_phone      VARCHAR(20)    NULL,
    province           NVARCHAR(100)  NULL,
    city               NVARCHAR(100)  NULL,
    join_date          DATE           NULL,
    status			   VARCHAR(20)    NULL,
    fbs_standard 	   VARCHAR(20)    NULL,
    use_logistics	   BIT		      NULL,
    warehouse          BIT            NULL,
);
GO

-- TABLE: stg_shipments
IF OBJECT_ID('staging.stg_shipments', 'U') IS NOT NULL
    DROP TABLE staging.stg_shipments;
GO

CREATE TABLE staging.stg_shipments (
    order_item_id       VARCHAR(50)   NOT NULL,
    courier_name        VARCHAR(50)   NULL,
    shipped_date        DATE          NULL,
    delivery_date       DATE          NULL,
    delivery_status     VARCHAR(50)   NULL,
    actual_delivery_day       INT     NULL,
);
GO

-- TABLE: stg_campaigns
IF OBJECT_ID('staging.stg_campaigns', 'U') IS NOT NULL
    DROP TABLE staging.stg_campaigns;
GO

CREATE TABLE staging.stg_campaigns (
    campaign_id       VARCHAR(50)   NOT NULL,
    campaign_name     NVARCHAR(100) NULL,
    start_date        DATE          NULL,
    end_date          DATE          NULL,
    campaign_type     VARCHAR(50)   NULL
);
GO

PRINT '✓ TV3 Staging tables created (stg_sellers, stg_shipments, stg_campaigns)';
GO

-- ============================================================================
-- PART 4: DIMENSION TABLES - Core Dimensions (TV1 & TV2 & TV3)
-- ============================================================================

PRINT '--- Creating Core Dimension Tables ---';
GO

CREATE TABLE dwh.dim_date (
    date_key          INT          NOT NULL PRIMARY KEY,
    full_date         DATE         NOT NULL UNIQUE,
    year              INT          NOT NULL,
    quarter           INT          NOT NULL,
    month             INT          NOT NULL,
    month_name        VARCHAR(20)  NOT NULL,
    day_of_month      INT          NOT NULL,
    day_of_week       INT          NOT NULL,
    day_name          VARCHAR(20)  NOT NULL,
    is_weekend        BIT          NOT NULL DEFAULT 0,
);
GO


CREATE TABLE dwh.dim_location (
    location_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,     
    province          NVARCHAR(100)     NOT NULL,
    city              NVARCHAR(100)     NOT NULL,
    region            VARCHAR(50)       NULL
);
GO

CREATE UNIQUE INDEX UX_dim_location ON dwh.dim_location(province, city);
GO

PRINT '✓ Core dimensions created (dim_date, dim_location)';
GO

-- ============================================================================
-- PART 5: DIMENSION TABLES - TV1 (Customers, Devices, Pages)
-- ============================================================================

PRINT '--- Creating TV1 Dimension Tables ---';
GO

CREATE TABLE dwh.dim_customer (
    customer_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_id       VARCHAR(50)       NOT NULL,
    first_name        NVARCHAR(100)     NULL,
    last_name         NVARCHAR(100)     NULL,
    gender            VARCHAR(10)       NULL,
    age_group         VARCHAR(20)       NULL,
    phone             VARCHAR(20)       NULL,
    email             VARCHAR(100)      NULL,
    location_key      INT               NULL,
    registration_date DATE              NULL,
    -- SCD Type 2 Tracking
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_dim_customer_location FOREIGN KEY (location_key)
        REFERENCES dwh.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_customer ON dwh.dim_customer(customer_id, is_current);
GO

CREATE TABLE dwh.dim_device (
    device_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    device_type  VARCHAR(20)       NOT NULL UNIQUE
);
GO

CREATE TABLE dwh.dim_page (
    page_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    page_type    VARCHAR(50)       NOT NULL UNIQUE
);
GO

-- TABLE: dim_page (Static - Reference)
CREATE TABLE dwh.dim_source (
    source_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    source_type    VARCHAR(50)       NOT NULL UNIQUE
);
GO

PRINT '✓ TV1 dimensions created (dim_customer, dim_device, dim_page)';
GO

-- ============================================================================
-- PART 6: DIMENSION TABLES - TV2 (Products, Categories)
-- ============================================================================

PRINT '--- Creating TV2 Dimension Tables ---';
GO


CREATE TABLE dwh.dim_product_category (
    category_key  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_name NVARCHAR(100)     NOT NULL UNIQUE
);
GO


CREATE TABLE dwh.dim_product (
    product_key    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    product_id     VARCHAR(50)       NOT NULL UNIQUE,
    product_name   NVARCHAR(100)     NULL,
    category_key   INT               NULL,
    weight         DECIMAL(10,3)     NULL,
    maintenance_rate DECIMAL(5,2)    NULL,
    commission_rate DECIMAL(5,2)     NULL,
    effective_from    DATE           NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE           NOT NULL DEFAULT '9999-12-31',
    is_current        BIT            NOT NULL DEFAULT 1,
    CONSTRAINT FK_product_category FOREIGN KEY (category_key)
        REFERENCES dwh.dim_product_category(category_key)
);
GO

CREATE INDEX IX_dim_product ON dwh.dim_product(product_id, is_current);
GO

PRINT '✓ TV2 dimensions created (dim_product_category, dim_product)';
GO

-- ============================================================================
-- PART 7: DIMENSION TABLES - TV3 (Sellers, Shipments, Campaigns)
-- ============================================================================

PRINT '--- Creating TV3 Dimension Tables ---';
GO


CREATE TABLE dwh.dim_seller (
    seller_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seller_id         VARCHAR(50)       NOT NULL,
    seller_name       NVARCHAR(100)     NULL,
    seller_type       VARCHAR(50)       NULL,
    fbs_standard      VARCHAR(20)       NULL,
    use_logistics     BIT               NULL,
    warehouse		  BIT               NULL,
    location_key      INT               NULL,
    join_date_key     INT               NULL,
    -- SCD Type 2 Tracking
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_dim_seller_location FOREIGN KEY (location_key)
        REFERENCES dwh.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_seller ON dwh.dim_seller(seller_id, is_current);
GO

CREATE TABLE dwh.dim_shipment (
    shipment_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    shipment_method   VARCHAR(50)       NOT NULL UNIQUE
);
GO

CREATE TABLE dwh.dim_campaign (
    campaign_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    campaign_id       VARCHAR(50)       NOT NULL UNIQUE,
    campaign_name     NVARCHAR(100)     NULL,
    campaign_type     VARCHAR(50)       NULL,
    start_date        DATE              NULL,
    end_date          DATE              NULL
);
GO

PRINT '✓ TV3 dimensions created (dim_seller, dim_shipment, dim_campaign)';
GO

-- ============================================================================
-- PART 8: FACT TABLES - TV1 (fact_session)
-- ============================================================================

PRINT '--- Creating TV1 Fact Tables ---';
GO

CREATE TABLE dwh.fact_session (
    activity_id        INT           NOT NULL PRIMARY KEY,
    session_id         INT   NOT NULL ,
    page_key           INT           NOT NULL,
    customer_key       INT           NOT NULL,
    device_key         INT           NOT NULL,
    source_key         INT           NULL,
    campaign_key       INT           NULL,
    session_date_key   INT           NOT NULL,
    session_duration   INT           NULL,
    activity_count     INT           NOT NULL,
    page_view_count    INT           NOT NULL,
    CONSTRAINT FK_fact_session_customer FOREIGN KEY (customer_key)
        REFERENCES dwh.dim_customer(customer_key),
    CONSTRAINT FK_fact_session_device FOREIGN KEY (device_key)
        REFERENCES dwh.dim_device(device_key),
    CONSTRAINT FK_fact_session_date FOREIGN KEY (session_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_session_source FOREIGN KEY (source_key)
        REFERENCES dwh.dim_source(source_key),
    CONSTRAINT FK_fact_session_page FOREIGN KEY (page_key)
        REFERENCES dwh.dim_page(page_key)
);
GO

CREATE INDEX IX_fact_session_activity ON dwh.fact_session(session_id, activity_id);
CREATE INDEX IX_fact_session_date ON dwh.fact_session(session_date_key);
CREATE INDEX IX_fact_session_device ON dwh.fact_session(device_key);
CREATE INDEX IX_fact_session_source ON dwh.fact_session(source_key);

GO

CREATE TABLE dwh.fact_shipment (
    shipment_key             INT IDENTITY(1,1)   PRIMARY KEY,
    order_item_id            INT            NOT NULL,
    order_id                 INT            NOT NULL,
    seller_key               INT            NOT NULL,
    shipment_method_key      INT            NULL,
    order_date_key           INT            NOT NULL,
    shipment_date_key        INT            NOT NULL,
    start_expected_delivery_key    INT            NOT NULL,
    end_expected_delivery_key    INT            NOT NULL,
    actual_delivery_key      INT            NULL,
    days_to_deliver          INT            NULL,
    is_on_time               BIT            DEFAULT 0
    CONSTRAINT FK_fact_shipment_seller FOREIGN KEY (seller_key)
        REFERENCES dwh.dim_seller(seller_key),
    CONSTRAINT FK_fact_shipment_method FOREIGN KEY (shipment_method_key)
        REFERENCES dwh.dim_shipment(shipment_key),
    CONSTRAINT FK_fact_shipment_order_date FOREIGN KEY (order_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_ship_date FOREIGN KEY (shipment_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_start_expected_date FOREIGN KEY (start_expected_delivery_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_end_expected_date FOREIGN KEY (end_expected_delivery_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_actual_date FOREIGN KEY (actual_delivery_key)
        REFERENCES dwh.dim_date(date_key)
);
GO

CREATE INDEX IX_fact_shipment_item ON dwh.fact_shipment(order_id, order_item_id);
CREATE INDEX IX_fact_shipment_seller ON dwh.fact_shipment(seller_key, shipment_method_key);
CREATE INDEX IX_fact_shipment_dates ON dwh.fact_shipment(order_date_key, actual_delivery_key);
GO

PRINT '✓ TV1 fact tables created (fact_session, fact_shipment)';
GO

-- ============================================================================
-- PART 9: FACT TABLES - TV2 (fact_order, fact_seller_sales)
-- ============================================================================

PRINT '--- Creating TV2 Fact Tables ---';
GO

CREATE TABLE dwh.fact_order (
    order_item_key           INT IDENTITY(1,1)   PRIMARY KEY,
    order_item_id			 INT            NOT NULL,
    order_id                 INT            NOT NULL,
    customer_key             INT            NOT NULL,
    seller_key               INT            NOT NULL,
    product_key              INT            NOT NULL,
    order_date_key           INT            NOT NULL,
    campaign_key             INT            NULL,
    unit_price               DECIMAL(12,2)  NOT NULL,
    quantity                 INT            NOT NULL,
    discount_percent_per_item         DECIMAL(12,2)  NULL,
    commission_amount_per_item        DECIMAL(12,2)  NULL,
    maintenance_amount_per_item       DECIMAL(12,2)  NULL,
    shipping_fee_item             DECIMAL(12,2)  NULL,
    line_total               DECIMAL(12,2)  NOT NULL,
    item_status              VARCHAR(50)    NULL,
    total_amount             DECIMAL(12,2)  NOT NULL,
    subtotal_amount          DECIMAL(12,2)  NOT NULL,
    shipping_fee_total       DECIMAL(12,2)  NULL,
    commission_total         DECIMAL(12,2)  NULL,
    maintenance_total        DECIMAL(12,2)  NULL,
    CONSTRAINT FK_order_customer FOREIGN KEY (customer_key)
        REFERENCES dwh.dim_customer(customer_key),
    CONSTRAINT FK_order_seller FOREIGN KEY (seller_key)
        REFERENCES dwh.dim_seller(seller_key),
    CONSTRAINT FK_order_product FOREIGN KEY (product_key)
        REFERENCES dwh.dim_product(product_key),
    CONSTRAINT FK_order_date FOREIGN KEY (order_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_order_campaign FOREIGN KEY (campaign_key)
        REFERENCES dwh.dim_campaign(campaign_key)
);
GO

CREATE INDEX IX_fact_order_id ON dwh.fact_order(order_id);
CREATE INDEX IX_fact_order_date ON dwh.fact_order(order_date_key);
CREATE INDEX IX_fact_order_seller ON dwh.fact_order(seller_key);
CREATE INDEX IX_fact_order_customer ON dwh.fact_order(customer_key);
GO

-- ============================================================================
-- PART 10: FACT TABLES - TV3 (fact_lifecycle_sales)
-- ============================================================================

PRINT '--- Creating TV3 Fact Tables ---';
GO

CREATE TABLE dwh.fact_lifecycle_order (
    lifecycle_sales_id       INT IDENTITY(1,1)   NOT NULL PRIMARY KEY,
    order_id                 INT            NOT NULL,
    customer_key             INT            NOT NULL,
    location_key             INT            NULL,
    order_date_key           INT            NOT NULL,
    payment_date_key         INT            NULL,
    shipment_date_key        INT            NULL,
    delivery_date_key        INT            NULL,
    total_items              INT            NOT NULL,
    total_days_to_deliver    INT            NULL,
    order_status             VARCHAR(50)    NULL,
    items_shipped_count      INT            NULL,
    items_delivered_count    INT            NULL,  
    items_cancelled_count    INT            NULL, 
    items_returned_count     INT            NULL,
    CONSTRAINT FK_lifecycle_date FOREIGN KEY (order_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_lifecycle_shipment_date FOREIGN KEY (shipment_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_lifecycle_delivery_date FOREIGN KEY (delivery_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_lifecycle_payment_date FOREIGN KEY (payment_date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_lifecycle_customer FOREIGN KEY (customer_key)
        REFERENCES dwh.dim_customer(customer_key),
    CONSTRAINT FK_lifecycle_location FOREIGN KEY (location_key)
        REFERENCES dwh.dim_location(location_key),  
);
GO

CREATE INDEX IX_fact_lifecycle_order_date ON dwh.fact_lifecycle_order(order_date_key);
CREATE INDEX IX_fact_lifecycle_order_id ON dwh.fact_lifecycle_order(order_id);
GO

CREATE TABLE dwh.fact_monthly_category_sales (
    date_key              INT            NOT NULL,
    category_key          INT            NOT NULL,
    total_orders          INT            NOT NULL DEFAULT 0,
    total_items_sold      INT            NOT NULL DEFAULT 0,
    total_amount         DECIMAL(15,2)  NOT NULL DEFAULT 0,
    total_cancelled       INT            NOT NULL DEFAULT 0,
    total_returned        INT            NOT NULL DEFAULT 0,
    total_completed       INT            NOT NULL DEFAULT 0,
    commission_amount       DECIMAL(15,2)  NULL,
    maintenance_amount      DECIMAL(15,2)  NULL,
    CONSTRAINT PK_fact_monthly_sales PRIMARY KEY (date_key, category_key),
    CONSTRAINT FK_sales_date FOREIGN KEY (date_key)
        REFERENCES dwh.dim_date(date_key),
    CONSTRAINT FK_sales_category FOREIGN KEY (category_key)
        REFERENCES dwh.dim_product_category(category_key)
);
GO

CREATE INDEX IX_fact_monthly_sales_date ON dwh.fact_monthly_category_sales(date_key);
CREATE INDEX IX_fact_monthly_sales_category ON dwh.fact_monthly_category_sales(category_key);
GO


PRINT '✓ TV3 fact tables created (fact_lifecycle_sales)';
GO

-- ============================================================================
-- PART 11: VERIFICATION & SUMMARY
-- ============================================================================

PRINT '
================================================================================
                            VERIFICATION SUMMARY
================================================================================
';

-- Count staging tables
DECLARE @stagingCount INT;
SELECT @stagingCount = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'staging';

PRINT '📊 STAGING TABLES: ' + CAST(@stagingCount AS VARCHAR) + ' created';
SELECT '  - ' + TABLE_NAME AS [Staging Tables]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'staging'
ORDER BY TABLE_NAME;

-- Count dimension tables
DECLARE @dimCount INT;
SELECT @dimCount = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dwh' AND TABLE_NAME LIKE 'dim_%';

PRINT '';
PRINT '📐 DIMENSION TABLES: ' + CAST(@dimCount AS VARCHAR) + ' created';
SELECT '  - ' + TABLE_NAME AS [Dimension Tables]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dwh' AND TABLE_NAME LIKE 'dim_%'
ORDER BY TABLE_NAME;

-- Count fact tables
DECLARE @factCount INT;
SELECT @factCount = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dwh' AND TABLE_NAME LIKE 'fact_%';

PRINT '';
PRINT '📈 FACT TABLES: ' + CAST(@factCount AS VARCHAR) + ' created';
SELECT '  - ' + TABLE_NAME AS [Fact Tables]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dwh' AND TABLE_NAME LIKE 'fact_%'
ORDER BY TABLE_NAME;

PRINT '';
PRINT '================================================================================';
PRINT '✅ TOTAL TABLES CREATED: ' + CAST((@stagingCount + @dimCount + @factCount) AS VARCHAR);
PRINT '================================================================================';

PRINT '
📝 NEXT STEPS:
1. Run SSIS Extract packages to populate staging tables
2. Run SSIS Load packages to populate dimensions
3. Run SSIS Load packages to populate facts
4. Verify FK integrity
5. Generate analytics queries

⚠️  NOTE:
- Staging tables are empty - awaiting ETL load
- Dimension tables are empty - require ETL load or manual populate
- Fact tables are empty - require ETL load
- All Foreign Key constraints are active
';

GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
PRINT 'Script execution completed at ' + CONVERT(VARCHAR, GETDATE(), 121);
GO
