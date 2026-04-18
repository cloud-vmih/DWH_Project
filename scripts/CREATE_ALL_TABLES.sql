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
- gold: Cleaned dimensions and facts

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
USE ShopeeThailandDW;
GO

-- Create schemas if not exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    CREATE SCHEMA staging;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    CREATE SCHEMA gold;
GO

PRINT '✓ Database and schemas ready';
GO

-- ============================================================================
-- PART 1: STAGING TABLES - TV1 (Customers, Sessions, Reviews)
-- ============================================================================

PRINT '--- Creating TV1 Staging Tables ---';
GO

-- TABLE: stg_customers
IF OBJECT_ID('staging.stg_customers', 'U') IS NOT NULL
    DROP TABLE staging.stg_customers;
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
    city                NVARCHAR(100) NULL
);
GO

-- TABLE: stg_session_activities
IF OBJECT_ID('staging.stg_session_activities', 'U') IS NOT NULL
    DROP TABLE staging.stg_session_activities;
GO

CREATE TABLE staging.stg_session_activities (
    session_id          VARCHAR(50)   NOT NULL,
    customer_id         VARCHAR(50)   NULL,
    session_date        DATE          NULL,
    session_duration    INT           NULL,
    device_type         VARCHAR(20)   NULL,
    activity_count      INT           NULL,
    page_view_count     INT           NULL
);
GO

-- TABLE: stg_reviews
IF OBJECT_ID('staging.stg_reviews', 'U') IS NOT NULL
    DROP TABLE staging.stg_reviews;
GO

CREATE TABLE staging.stg_reviews (
    review_id           VARCHAR(50)   NOT NULL,
    order_id            VARCHAR(50)   NULL,
    customer_id         VARCHAR(50)   NULL,
    review_score        INT           NULL,
    review_comment      NVARCHAR(MAX) NULL,
    review_date         DATE          NULL
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
    created_at        DATE           NULL
);
GO

-- TABLE: stg_order_items
IF OBJECT_ID('staging.stg_order_items', 'U') IS NOT NULL
    DROP TABLE staging.stg_order_items;
GO

CREATE TABLE staging.stg_order_items (
    order_id          VARCHAR(50)    NOT NULL,
    order_item_id     INT            NOT NULL,
    product_id        VARCHAR(50)    NOT NULL,
    seller_id         VARCHAR(50)    NOT NULL,
    unit_price        DECIMAL(12,2)  NOT NULL,
    quantity          INT            NULL,
    discount_amount   DECIMAL(12,2)  NULL,
    commission_amount DECIMAL(12,2)  NULL,
    maintenance_amount DECIMAL(12,2) NULL,
    shipping_fee      DECIMAL(12,2)  NULL
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
    order_day           INT           NULL,
    year_month          VARCHAR(10)   NULL,
    subtotal_amount     DECIMAL(12,2) NULL,
    shipping_fee_total  DECIMAL(12,2) NULL,
    commission_total    DECIMAL(12,2) NULL,
    maintenance_total   DECIMAL(12,2) NULL,
    total_amount        DECIMAL(12,2) NULL,
    campaign_id         VARCHAR(50)   NULL
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
    seller_name        NVARCHAR(100)  NULL,
    registration_date  DATE           NULL,
    province           NVARCHAR(100)  NULL,
    city               NVARCHAR(100)  NULL,
    phone              VARCHAR(20)    NULL
);
GO

-- TABLE: stg_shipments
IF OBJECT_ID('staging.stg_shipments', 'U') IS NOT NULL
    DROP TABLE staging.stg_shipments;
GO

CREATE TABLE staging.stg_shipments (
    shipment_id       VARCHAR(50)   NOT NULL,
    order_id          VARCHAR(50)   NULL,
    shipment_date     DATE          NULL,
    shipment_method   VARCHAR(50)   NULL,
    expected_date     DATE          NULL,
    actual_date       DATE          NULL,
    is_on_time        BIT           NULL,
    tracking_number   VARCHAR(100)  NULL
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

-- TABLE: dim_date (Static - No changes)
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO

CREATE TABLE gold.dim_date (
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
    is_holiday        BIT          NOT NULL DEFAULT 0
);
GO

-- TABLE: dim_location (SCD Type 1 - No history)
IF OBJECT_ID('gold.dim_location', 'U') IS NOT NULL
    DROP TABLE gold.dim_location;
GO

CREATE TABLE gold.dim_location (
    location_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    province          NVARCHAR(100)     NOT NULL,
    city              NVARCHAR(100)     NOT NULL,
    region            VARCHAR(50)       NULL
);
GO

CREATE UNIQUE INDEX UX_dim_location ON gold.dim_location(province, city);
GO

PRINT '✓ Core dimensions created (dim_date, dim_location)';
GO

-- ============================================================================
-- PART 5: DIMENSION TABLES - TV1 (Customers, Devices, Pages)
-- ============================================================================

PRINT '--- Creating TV1 Dimension Tables ---';
GO

-- TABLE: dim_customer (SCD Type 2 - Track changes)
IF OBJECT_ID('gold.dim_customer', 'U') IS NOT NULL
    DROP TABLE gold.dim_customer;
GO

CREATE TABLE gold.dim_customer (
    customer_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_id       VARCHAR(50)       NOT NULL,
    first_name        NVARCHAR(100)     NULL,
    last_name         NVARCHAR(100)     NULL,
    gender            VARCHAR(10)       NULL,
    age_group         VARCHAR(20)       NULL,
    location_key      INT               NULL,
    registration_date DATE              NULL,
    -- SCD Type 2 Tracking
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_dim_customer_location FOREIGN KEY (location_key)
        REFERENCES gold.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_customer ON gold.dim_customer(customer_id, is_current);
GO

-- TABLE: dim_device (Static - Small list)
IF OBJECT_ID('gold.dim_device', 'U') IS NOT NULL
    DROP TABLE gold.dim_device;
GO

CREATE TABLE gold.dim_device (
    device_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    device_type  VARCHAR(20)       NOT NULL UNIQUE
);
GO

-- TABLE: dim_page (Static - Reference)
IF OBJECT_ID('gold.dim_page', 'U') IS NOT NULL
    DROP TABLE gold.dim_page;
GO

CREATE TABLE gold.dim_page (
    page_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    page_type    VARCHAR(50)       NOT NULL UNIQUE
);
GO

PRINT '✓ TV1 dimensions created (dim_customer, dim_device, dim_page)';
GO

-- ============================================================================
-- PART 6: DIMENSION TABLES - TV2 (Products, Categories)
-- ============================================================================

PRINT '--- Creating TV2 Dimension Tables ---';
GO

-- TABLE: dim_product_category (SCD Type 1)
IF OBJECT_ID('gold.dim_product_category', 'U') IS NOT NULL
    DROP TABLE gold.dim_product_category;
GO

CREATE TABLE gold.dim_product_category (
    category_key  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_name NVARCHAR(100)     NOT NULL UNIQUE
);
GO

-- TABLE: dim_product (SCD Type 1)
IF OBJECT_ID('gold.dim_product', 'U') IS NOT NULL
    DROP TABLE gold.dim_product;
GO

CREATE TABLE gold.dim_product (
    product_key    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    product_id     VARCHAR(50)       NOT NULL UNIQUE,
    product_name   NVARCHAR(100)     NULL,
    category_key   INT               NULL,
    weight         DECIMAL(10,3)     NULL,
    maintenance_rate DECIMAL(5,2)    NULL,
    commission_rate DECIMAL(5,2)     NULL,
    CONSTRAINT FK_product_category FOREIGN KEY (category_key)
        REFERENCES gold.dim_product_category(category_key)
);
GO

PRINT '✓ TV2 dimensions created (dim_product_category, dim_product)';
GO

-- ============================================================================
-- PART 7: DIMENSION TABLES - TV3 (Sellers, Shipments, Campaigns)
-- ============================================================================

PRINT '--- Creating TV3 Dimension Tables ---';
GO

-- TABLE: dim_seller (SCD Type 2 - Track seller info changes)
IF OBJECT_ID('gold.dim_seller', 'U') IS NOT NULL
    DROP TABLE gold.dim_seller;
GO

CREATE TABLE gold.dim_seller (
    seller_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seller_id         VARCHAR(50)       NOT NULL,
    seller_name       NVARCHAR(100)     NULL,
    location_key      INT               NULL,
    registration_date DATE              NULL,
    -- SCD Type 2 Tracking
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_dim_seller_location FOREIGN KEY (location_key)
        REFERENCES gold.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_seller ON gold.dim_seller(seller_id, is_current);
GO

-- TABLE: dim_shipment (SCD Type 1)
IF OBJECT_ID('gold.dim_shipment', 'U') IS NOT NULL
    DROP TABLE gold.dim_shipment;
GO

CREATE TABLE gold.dim_shipment (
    shipment_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    shipment_method   VARCHAR(50)       NOT NULL UNIQUE
);
GO

-- TABLE: dim_campaign (Static - Reference)
IF OBJECT_ID('gold.dim_campaign', 'U') IS NOT NULL
    DROP TABLE gold.dim_campaign;
GO

CREATE TABLE gold.dim_campaign (
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

-- TABLE: fact_session (TV1 - Session activity tracking)
IF OBJECT_ID('gold.fact_session', 'U') IS NOT NULL
    DROP TABLE gold.fact_session;
GO

CREATE TABLE gold.fact_session (
    session_id         VARCHAR(50)   NOT NULL PRIMARY KEY,
    customer_key       INT           NOT NULL,
    device_key         INT           NOT NULL,
    session_date_key   INT           NOT NULL,
    session_duration   INT           NULL,
    activity_count     INT           NOT NULL,
    page_view_count    INT           NOT NULL,
    CONSTRAINT FK_fact_session_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_session_device FOREIGN KEY (device_key)
        REFERENCES gold.dim_device(device_key),
    CONSTRAINT FK_fact_session_date FOREIGN KEY (session_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO

CREATE INDEX IX_fact_session_date ON gold.fact_session(session_date_key);
CREATE INDEX IX_fact_session_customer ON gold.fact_session(customer_key);
GO

-- TABLE: fact_shipment (TV1 - Shipment tracking - INCREMENTAL)
IF OBJECT_ID('gold.fact_shipment', 'U') IS NOT NULL
    DROP TABLE gold.fact_shipment;
GO

CREATE TABLE gold.fact_shipment (
    shipment_id              VARCHAR(50)    NOT NULL PRIMARY KEY,
    order_id                 VARCHAR(50)    NOT NULL,
    seller_key               INT            NOT NULL,
    shipment_method_key      INT            NULL,
    order_date_key           INT            NOT NULL,
    shipment_date_key        INT            NOT NULL,
    expected_delivery_key    INT            NOT NULL,
    actual_delivery_key      INT            NULL,
    days_to_deliver          INT            NULL,
    is_on_time               BIT            DEFAULT 0,
    tracking_number          VARCHAR(100)   NULL,
    CONSTRAINT PK_fact_shipment PRIMARY KEY (shipment_id),
    CONSTRAINT FK_fact_shipment_seller FOREIGN KEY (seller_key)
        REFERENCES gold.dim_seller(seller_key),
    CONSTRAINT FK_fact_shipment_method FOREIGN KEY (shipment_method_key)
        REFERENCES gold.dim_shipment(shipment_key),
    CONSTRAINT FK_fact_shipment_order_date FOREIGN KEY (order_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_ship_date FOREIGN KEY (shipment_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_expected_date FOREIGN KEY (expected_delivery_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_shipment_actual_date FOREIGN KEY (actual_delivery_key)
        REFERENCES gold.dim_date(date_key)
);
GO

CREATE INDEX IX_fact_shipment_seller ON gold.fact_shipment(seller_key);
CREATE INDEX IX_fact_shipment_dates ON gold.fact_shipment(order_date_key, actual_delivery_key);
GO

PRINT '✓ TV1 fact tables created (fact_session, fact_shipment)';
GO

-- ============================================================================
-- PART 9: FACT TABLES - TV2 (fact_order, fact_seller_sales)
-- ============================================================================

PRINT '--- Creating TV2 Fact Tables ---';
GO

-- TABLE: fact_order (TV2 - Central fact table - INCREMENTAL)
IF OBJECT_ID('gold.fact_order', 'U') IS NOT NULL
    DROP TABLE gold.fact_order;
GO

CREATE TABLE gold.fact_order (
    order_id                 VARCHAR(50)    NOT NULL PRIMARY KEY,
    customer_key             INT            NOT NULL,
    seller_key               INT            NOT NULL,
    product_key              INT            NOT NULL,
    order_date_key           INT            NOT NULL,
    campaign_key             INT            NULL,
    order_item_id            INT            NOT NULL,
    unit_price               DECIMAL(12,2)  NOT NULL,
    quantity                 INT            NOT NULL,
    discount_amount          DECIMAL(12,2)  NULL,
    commission_amount        DECIMAL(12,2)  NULL,
    maintenance_amount       DECIMAL(12,2)  NULL,
    shipping_fee             DECIMAL(12,2)  NULL,
    total_amount             DECIMAL(12,2)  NOT NULL,
    CONSTRAINT FK_order_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_order_seller FOREIGN KEY (seller_key)
        REFERENCES gold.dim_seller(seller_key),
    CONSTRAINT FK_order_product FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_order_date FOREIGN KEY (order_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_order_campaign FOREIGN KEY (campaign_key)
        REFERENCES gold.dim_campaign(campaign_key)
);
GO

CREATE INDEX IX_fact_order_date ON gold.fact_order(order_date_key);
CREATE INDEX IX_fact_order_seller ON gold.fact_order(seller_key);
CREATE INDEX IX_fact_order_customer ON gold.fact_order(customer_key);
GO

-- TABLE: fact_seller_sales (TV2 - Aggregated seller sales - INCREMENTAL)
IF OBJECT_ID('gold.fact_seller_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_seller_sales;
GO

CREATE TABLE gold.fact_seller_sales (
    seller_sales_id          VARCHAR(100)   NOT NULL PRIMARY KEY,
    seller_key               INT            NOT NULL,
    product_key              INT            NOT NULL,
    order_date_key           INT            NOT NULL,
    total_orders             INT            NOT NULL,
    total_quantity_sold      INT            NOT NULL,
    total_revenue            DECIMAL(15,2)  NOT NULL,
    total_discount_amount    DECIMAL(15,2)  NULL,
    total_commission_amount  DECIMAL(15,2)  NULL,
    total_maintenance_amount DECIMAL(15,2)  NULL,
    net_revenue              DECIMAL(15,2)  NULL,
    avg_order_value          DECIMAL(12,2)  NULL,
    avg_review_score         DECIMAL(3,2)   NULL,
    CONSTRAINT FK_seller_sales_seller FOREIGN KEY (seller_key)
        REFERENCES gold.dim_seller(seller_key),
    CONSTRAINT FK_seller_sales_product FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_seller_sales_date FOREIGN KEY (order_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO

CREATE INDEX IX_fact_seller_sales_date ON gold.fact_seller_sales(order_date_key);
CREATE INDEX IX_fact_seller_sales_seller ON gold.fact_seller_sales(seller_key);
GO

PRINT '✓ TV2 fact tables created (fact_order, fact_seller_sales)';
GO

-- ============================================================================
-- PART 10: FACT TABLES - TV3 (fact_lifecycle_sales)
-- ============================================================================

PRINT '--- Creating TV3 Fact Tables ---';
GO

-- TABLE: fact_lifecycle_sales (TV3 - Master aggregated fact)
IF OBJECT_ID('gold.fact_lifecycle_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_lifecycle_sales;
GO

CREATE TABLE gold.fact_lifecycle_sales (
    lifecycle_sales_id       VARCHAR(100)   NOT NULL PRIMARY KEY,
    seller_key               INT            NOT NULL,
    product_key              INT            NOT NULL,
    order_date_key           INT            NOT NULL,
    customer_key             INT            NOT NULL,
    total_orders             INT            NOT NULL,
    total_quantity_sold      INT            NOT NULL,
    total_revenue            DECIMAL(15,2)  NOT NULL,
    total_discount_amount    DECIMAL(15,2)  NULL,
    total_commission_amount  DECIMAL(15,2)  NULL,
    total_maintenance_amount DECIMAL(15,2)  NULL,
    net_revenue              DECIMAL(15,2)  NULL,
    avg_order_value          DECIMAL(12,2)  NULL,
    avg_review_score         DECIMAL(3,2)   NULL,
    CONSTRAINT FK_lifecycle_seller FOREIGN KEY (seller_key)
        REFERENCES gold.dim_seller(seller_key),
    CONSTRAINT FK_lifecycle_product FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_lifecycle_date FOREIGN KEY (order_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_lifecycle_customer FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customer(customer_key)
);
GO

CREATE INDEX IX_fact_lifecycle_date ON gold.fact_lifecycle_sales(order_date_key);
CREATE INDEX IX_fact_lifecycle_seller ON gold.fact_lifecycle_sales(seller_key);
CREATE INDEX IX_fact_lifecycle_customer ON gold.fact_lifecycle_sales(customer_key);
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
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME LIKE 'dim_%';

PRINT '';
PRINT '📐 DIMENSION TABLES: ' + CAST(@dimCount AS VARCHAR) + ' created';
SELECT '  - ' + TABLE_NAME AS [Dimension Tables]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME LIKE 'dim_%'
ORDER BY TABLE_NAME;

-- Count fact tables
DECLARE @factCount INT;
SELECT @factCount = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME LIKE 'fact_%';

PRINT '';
PRINT '📈 FACT TABLES: ' + CAST(@factCount AS VARCHAR) + ' created';
SELECT '  - ' + TABLE_NAME AS [Fact Tables]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME LIKE 'fact_%'
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
