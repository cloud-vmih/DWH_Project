# 📘 GUIDE_TV3_DETAILED.md – Hướng dẫn chi tiết Thành viên 3 (Bán hàng & Vận chuyển & Chiến dịch)

**Phụ trách chính:**
- **Staging:** `stg_sellers`, `stg_shipments`, `stg_campaigns`
- **Dimensions:** `dim_seller` (SCD Type 2), `dim_campaign`, `dim_shipment`
- **Facts:** `fact_order_lifecycle`, `fact_monthly_category_sales`
- **SSIS Packages:** 3 packages + Master_ETL.dtsx
- **Công việc:** 32 tasks (8/tuần × 4 tuần)

---

# TUẦN 1: CHUẨN BỊ & EXTRACT (8 TASKS)

---

## Task 3.1: Kiểm tra Database & Connection Manager

**Mục tiêu:** Xác nhận ShopeeThailandDW, schemas staging/gold có sẵn từ TV1

**Step 1:** Mở SQL Server Management Studio (SSMS)

**Step 2:** Connect tới SQL Server (localhost or your server name)

**Step 3:** Chạy query kiểm tra database:
```sql
USE master;
GO

-- Kiểm tra database tồn tại
SELECT name FROM sys.databases WHERE name = 'ShopeeThailandDW';

-- Nếu không có, tạo
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ShopeeThailandDW')
BEGIN
    CREATE DATABASE ShopeeThailandDW;
END
GO

-- Kiểm tra schemas
USE ShopeeThailandDW;
GO
SELECT name FROM sys.schemas WHERE name IN ('staging', 'gold');
```

**Expected Result:** Output hiển thị 2 rows (staging, gold)

**Step 4:** Nếu schema chưa có, tạo:
```sql
USE ShopeeThailandDW;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA staging';
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA gold';
END
GO
```

**Deliverable:** ✅ ShopeeThailandDW with staging & gold schemas ready

---

## Task 3.2: Tạo Connection Manager cho TV3 SSIS Project

**Mục tiêu:** Thiết lập OLE DB Connection tới ShopeeThailandDW trong Visual Studio

**Step 1:** Mở Visual Studio

**Step 2:** Tạo Integration Services Project mới: File → New → Project → "Integration Services Project"

**Step 3:** Đặt tên project: `ShopeeTV3_ETL`

**Step 4:** Mở Connection Managers panel (View → Other Windows → Connection Managers)

**Step 5:** Right-click → "New OLE DB Connection Manager"

**Dialog Configuration:**

```
Provider:        SQL Server Native Client 11.0
Server name:     localhost (or your SQL Server)
Authentication:  Windows Authentication
                 (or SQL Authentication nếu có username/password)
Database:        ShopeeThailandDW
```

**Step 6:** Click "New..." button để mở Connection dialog

- Server name: `localhost`
- Use Windows Authentication: ✅ Checked
- Database: `ShopeeThailandDW`

**Step 7:** Click "Test Connection" → kết quả phải "Test connection succeeded"

**Step 8:** Đặt tên Connection Manager: `OleDbConnMgr_ShopeeTV3`

**Deliverable:** ✅ OLE DB Connection Manager tạo thành công, test connection passed

---

## Task 3.3: Tạo 3 Staging Tables

**Mục tiêu:** Tạo stg_sellers, stg_shipments, stg_campaigns để chứa dữ liệu raw từ CSV

**Step 1:** Mở SSMS, kết nối ShopeeThailandDW

**Step 2:** Chạy full SQL script:

```sql
USE ShopeeThailandDW;
GO

-- ============================================
-- STAGING TABLE 1: stg_sellers
-- ============================================
IF OBJECT_ID('staging.stg_sellers', 'U') IS NOT NULL
    DROP TABLE staging.stg_sellers;
GO

CREATE TABLE staging.stg_sellers (
    seller_id           VARCHAR(50)    NOT NULL PRIMARY KEY,
    seller_name         NVARCHAR(100)  NULL,
    province            NVARCHAR(100)  NULL,
    city                NVARCHAR(100)  NULL,
    seller_rating       DECIMAL(5,3)   NULL,
    total_orders        INT            NULL,
    verified_date       DATE           NULL,
    load_timestamp      DATETIME       DEFAULT GETDATE()
);
GO

-- ============================================
-- STAGING TABLE 2: stg_shipments
-- ============================================
IF OBJECT_ID('staging.stg_shipments', 'U') IS NOT NULL
    DROP TABLE staging.stg_shipments;
GO

CREATE TABLE staging.stg_shipments (
    shipment_id         VARCHAR(50)    NOT NULL PRIMARY KEY,
    order_id            VARCHAR(50)    NOT NULL,
    seller_id           VARCHAR(50)    NULL,
    shipment_date       DATE           NULL,
    expected_date       DATE           NULL,
    actual_date         DATE           NULL,
    shipment_method     VARCHAR(50)    NULL,
    tracking_number     VARCHAR(100)   NULL,
    is_on_time          BIT            NULL,
    load_timestamp      DATETIME       DEFAULT GETDATE()
);
GO

-- ============================================
-- STAGING TABLE 3: stg_campaigns
-- ============================================
IF OBJECT_ID('staging.stg_campaigns', 'U') IS NOT NULL
    DROP TABLE staging.stg_campaigns;
GO

CREATE TABLE staging.stg_campaigns (
    campaign_id         VARCHAR(50)    NOT NULL PRIMARY KEY,
    campaign_name       NVARCHAR(100)  NULL,
    campaign_type       VARCHAR(50)    NULL,
    start_date          DATE           NULL,
    end_date            DATE           NULL,
    budget              DECIMAL(15,2)  NULL,
    status              VARCHAR(20)    NULL,
    load_timestamp      DATETIME       DEFAULT GETDATE()
);
GO

-- Verify
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_SCHEMA = 'staging' AND TABLE_NAME IN ('stg_sellers', 'stg_shipments', 'stg_campaigns')
ORDER BY TABLE_NAME;
GO
```

**Expected Result:** 3 rows showing stg_sellers (7 cols), stg_shipments (9 cols), stg_campaigns (7 cols)

**Deliverable:** ✅ 3 staging tables created with proper schema

---

## Task 3.4: Tạo SSIS Package 1 - Extract_Sellers_Campaigns.dtsx

**Mục tiêu:** Xây dựng cấu trúc package để load 3 CSV files vào staging tables

**Step 1:** Visual Studio → Project: ShopeeTV3_ETL

**Step 2:** Right-click "SSIS Packages" → New SSIS Package

**Step 3:** Đặt tên: `Extract_Sellers_Campaigns.dtsx`

**Step 4:** Control Flow tab → Từ SSIS Toolbox, kéo 1 Execute SQL Task vào

**Step 5:** Đặt tên task: `EST - Truncate Staging`

**Step 6:** Double-click để mở, configure:

```
Connection:       OleDbConnMgr_ShopeeTV3
SQLStatement:     
    TRUNCATE TABLE staging.stg_sellers;
    TRUNCATE TABLE staging.stg_shipments;
    TRUNCATE TABLE staging.stg_campaigns;
```

**Step 7:** OK → quay lại Control Flow

**Step 8:** Kéo 3 Data Flow Tasks từ Toolbox, đặt tên:
- `DFT - Load Sellers`
- `DFT - Load Shipments`
- `DFT - Load Campaigns`

**Step 9:** Kết nối: EST → DFT1 → DFT2 → DFT3 (sequential)

**Step 10:** Save package (Ctrl+S)

**Deliverable:** ✅ Package skeleton with 1 EST + 3 DFT, proper sequence

---

## Task 3.5: DFT - Load Sellers (Flat File → stg_sellers)

**Mục tiêu:** Extract CSV sellers data → stg_sellers

**Step 1:** Double-click `DFT - Load Sellers` để mở Data Flow tab

**Step 2:** Từ Toolbox → Flat File Source → kéo vào

**Step 3:** Double-click Flat File Source → mở dialog

**Dialog - General Tab:**
```
File name: C:\Users\YourUsername\Downloads\shopee_sellers_thailand.csv
(Hoặc đường dẫn đúng tới file CSV)

Format:        Delimited
Text qualifier: " (double quote)
Column delimiter: , (comma)
```

**Dialog - Preview Tab:**
- Click Preview → xem 100 dòng đầu
- Verify columns: seller_id, seller_name, province, city, seller_rating, total_orders, verified_date

**Step 4:** OK → quay lại Data Flow

**Step 5:** Kéo OLE DB Destination vào

**Step 6:** Nối Flat File Source → OLE DB Destination

**Step 7:** Double-click OLE DB Destination → mở dialog

**Dialog Configuration:**

```
Connection manager:    OleDbConnMgr_ShopeeTV3
Table or view:         staging.stg_sellers
```

**Step 8:** Click "Mappings" tab → Verify column mapping:

| Source Column | Destination Column |
|---|---|
| seller_id | seller_id |
| seller_name | seller_name |
| province | province |
| city | city |
| seller_rating | seller_rating |
| total_orders | total_orders |
| verified_date | verified_date |

**Step 9:** OK → Save package

**Test Run:**

**Step 10:** Right-click `DFT - Load Sellers` → Execute Task

**Expected Result:** Green checkmark ✓, status "DFT completed successfully"

**Verify in SSMS:**
```sql
SELECT COUNT(*) AS seller_count FROM staging.stg_sellers;
```

**Deliverable:** ✅ stg_sellers populated with seller data

---

## Task 3.6: DFT - Load Shipments (CSV → stg_shipments)

**Mục tiêu:** Extract shipments CSV → stg_shipments, tính is_on_time

**Step 1:** Double-click `DFT - Load Shipments` → Data Flow tab

**Step 2:** Kéo Flat File Source vào, double-click

**Dialog Configuration:**
```
File name: C:\...\shopee_shipments_thailand.csv
Format:    Delimited
Delimiter: , (comma)
```

**Step 3:** Preview → kiểm tra columns: shipment_id, order_id, seller_id, shipment_date, expected_date, actual_date, shipment_method, tracking_number

**Step 4:** OK

**Step 5:** Kéo Derived Column transformation vào

**Step 6:** Nối: Flat File Source → Derived Column

**Step 7:** Double-click Derived Column → mở dialog

**New Derived Column:**
```
Output Alias:       is_on_time
Expression:         (actual_date <= expected_date) ? 1 : 0
Data Type:          Signed Byte (DT_I1)
```

**Step 8:** OK

**Step 9:** Kéo OLE DB Destination vào

**Step 10:** Nối: Derived Column → OLE DB Destination

**Step 11:** Double-click OLE DB Destination

**Dialog:**
```
Connection:  OleDbConnMgr_ShopeeTV3
Table:       staging.stg_shipments
```

**Step 12:** Mappings tab → verify:

| Source | Destination |
|---|---|
| shipment_id | shipment_id |
| order_id | order_id |
| seller_id | seller_id |
| shipment_date | shipment_date |
| expected_date | expected_date |
| actual_date | actual_date |
| shipment_method | shipment_method |
| tracking_number | tracking_number |
| is_on_time | is_on_time |

**Step 13:** OK → Save

**Test Run:**
```sql
SELECT COUNT(*) FROM staging.stg_shipments;
SELECT TOP 5 shipment_id, is_on_time FROM staging.stg_shipments;
```

**Deliverable:** ✅ stg_shipments loaded with is_on_time calculated

---

## Task 3.7: DFT - Load Campaigns (CSV → stg_campaigns)

**Mục tiêu:** Extract campaigns CSV → stg_campaigns

**Step 1:** Double-click `DFT - Load Campaigns` → Data Flow tab

**Step 2:** Kéo Flat File Source vào, configure

**Dialog:**
```
File name: C:\...\shopee_campaigns_thailand.csv
Format:    Delimited
Delimiter: , (comma)
```

**Step 3:** Preview kiểm tra: campaign_id, campaign_name, campaign_type, start_date, end_date, budget, status

**Step 4:** OK

**Step 5:** Kéo OLE DB Destination vào

**Step 6:** Nối: Source → Destination

**Step 7:** Configure Destination

**Dialog:**
```
Connection:  OleDbConnMgr_ShopeeTV3
Table:       staging.stg_campaigns
```

**Step 8:** Mappings tab → map tất cả 7 columns

**Step 9:** OK → Save

**Test Run:**
```sql
SELECT COUNT(*) FROM staging.stg_campaigns;
```

**Deliverable:** ✅ stg_campaigns populated

---

## Task 3.8: Execute Extract Package & Verify

**Mục tiêu:** Chạy Extract_Sellers_Campaigns.dtsx toàn bộ, verify dữ liệu

**Step 1:** Visual Studio → Package Explorer → Extract_Sellers_Campaigns.dtsx

**Step 2:** Right-click → Execute Package

**Step 3:** Watch Execution Results:
- EST - Truncate: ✓ Green
- DFT - Load Sellers: ✓ Green
- DFT - Load Shipments: ✓ Green
- DFT - Load Campaigns: ✓ Green

**Expected Output:**
```
Execution completed successfully
```

**Step 4:** SSMS verification queries:

```sql
USE ShopeeThailandDW;
GO

-- Row counts
SELECT 
    'stg_sellers' AS TableName,
    COUNT(*) AS RowCount
FROM staging.stg_sellers
UNION ALL
SELECT 'stg_shipments', COUNT(*) FROM staging.stg_shipments
UNION ALL
SELECT 'stg_campaigns', COUNT(*) FROM staging.stg_campaigns;

-- Sample data
SELECT TOP 3 * FROM staging.stg_sellers;
SELECT TOP 3 * FROM staging.stg_shipments WHERE is_on_time IS NOT NULL;
SELECT TOP 3 * FROM staging.stg_campaigns;
```

**Expected Results:**
- stg_sellers: ~500-1000 rows
- stg_shipments: ~5000-10000 rows
- stg_campaigns: ~50-100 rows

**Deliverable:** ✅ Extract package executed successfully, all 3 staging tables populated

---

# TUẦN 2: TẠO DIMENSIONS (8 TASKS)

---

## Task 3.9: Tạo 3 Dimension Tables

**Mục tiêu:** Tạo dim_seller, dim_campaign, dim_shipment

**Step 1:** SSMS → ShopeeThailandDW

**Step 2:** Chạy DDL script:

```sql
USE ShopeeThailandDW;
GO

-- =====================================================
-- DIMENSION 1: dim_shipment (Static)
-- =====================================================
IF OBJECT_ID('gold.dim_shipment', 'U') IS NOT NULL
    DROP TABLE gold.dim_shipment;
GO

CREATE TABLE gold.dim_shipment (
    shipment_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    shipment_method   VARCHAR(50)       NOT NULL UNIQUE,
    provider_name     VARCHAR(100)      NULL,
    avg_delivery_days INT               NULL
);
GO

-- =====================================================
-- DIMENSION 2: dim_campaign (Slowly Changing Type 1)
-- =====================================================
IF OBJECT_ID('gold.dim_campaign', 'U') IS NOT NULL
    DROP TABLE gold.dim_campaign;
GO

CREATE TABLE gold.dim_campaign (
    campaign_key      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    campaign_id       VARCHAR(50)       NOT NULL UNIQUE,
    campaign_name     NVARCHAR(100)     NULL,
    campaign_type     VARCHAR(50)       NULL,
    start_date_key    INT               NULL,
    end_date_key      INT               NULL,
    budget            DECIMAL(15,2)     NULL,
    CONSTRAINT FK_campaign_start_date FOREIGN KEY (start_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_campaign_end_date FOREIGN KEY (end_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO

-- =====================================================
-- DIMENSION 3: dim_seller (Slowly Changing Type 2)
-- =====================================================
IF OBJECT_ID('gold.dim_seller', 'U') IS NOT NULL
    DROP TABLE gold.dim_seller;
GO

CREATE TABLE gold.dim_seller (
    seller_key        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seller_id         VARCHAR(50)       NOT NULL,
    seller_name       NVARCHAR(100)     NULL,
    province          NVARCHAR(100)     NULL,
    city              NVARCHAR(100)     NULL,
    seller_rating     DECIMAL(5,3)      NULL,
    location_key      INT               NULL,
    -- SCD Type 2 columns
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_seller_location FOREIGN KEY (location_key)
        REFERENCES gold.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_seller_current ON gold.dim_seller(seller_id, is_current);
GO

-- Verify
SELECT 
    'dim_shipment' AS TableName,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dim_shipment') AS ColumnCount
UNION ALL
SELECT 'dim_campaign', (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dim_campaign')
UNION ALL
SELECT 'dim_seller', (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'dim_seller');
GO
```

**Expected Result:** 3 dimension tables created

**Deliverable:** ✅ dim_shipment, dim_campaign, dim_seller created with SCD Type 2 for seller

---

## Task 3.10: Load dim_shipment (Static lookup)

**Mục tiêu:** Populate dim_shipment từ stg_shipments distinct shipment_method

**Step 1:** SSMS → chạy query:

```sql
USE ShopeeThailandDW;
GO

-- Distinct shipment methods từ staging
INSERT INTO gold.dim_shipment (shipment_method, provider_name, avg_delivery_days)
SELECT DISTINCT
    shipment_method,
    NULL AS provider_name,
    NULL AS avg_delivery_days
FROM staging.stg_shipments
WHERE shipment_method IS NOT NULL;

-- Verify
SELECT * FROM gold.dim_shipment;
GO
```

**Expected Result:** 3-5 rows (e.g., Standard, Express, Overnight)

**Deliverable:** ✅ dim_shipment populated

---

## Task 3.11: Tạo SSIS Package 2 - Load_Dim_Sellers_Campaign.dtsx

**Mục tiêu:** Xây dựng package load dimensions với SCD Type 2 cho seller

**Step 1:** Visual Studio → New SSIS Package: `Load_Dim_Sellers_Campaign.dtsx`

**Step 2:** Control Flow tab

**Step 3:** Kéo 3 Data Flow Tasks:
- `DFT - Load dim_campaign`
- `DFT - Load dim_seller (SCD2)`

**Step 4:** Sequential: DFT_campaign → DFT_seller

**Step 5:** Save package

**Deliverable:** ✅ Package skeleton created

---

## Task 3.12: DFT - Load dim_campaign (Type 1)

**Mục tiêu:** Load campaigns → dim_campaign, map start/end dates tới dim_date keys

**Step 1:** Double-click `DFT - Load dim_campaign`

**Step 2:** Kéo OLE DB Source → configure

**Dialog:**
```
Connection:      OleDbConnMgr_ShopeeTV3
Data access mode: SQL Command
SQL Command:     SELECT 
                    campaign_id,
                    campaign_name,
                    campaign_type,
                    start_date,
                    end_date,
                    budget
                 FROM staging.stg_campaigns
                 WHERE campaign_id IS NOT NULL;
```

**Step 3:** OK → Columns tab preview

**Step 4:** Kéo Lookup transformation (2 times):
- Lookup 1: For start_date
- Lookup 2: For end_date

**Step 5:** Nối: Source → Lookup_start → Lookup_end

**Step 6:** Double-click Lookup_start → configure

**Dialog - Connection Tab:**
```
Connection: OleDbConnMgr_ShopeeTV3
Use cache: Partial cache
Select a table or view: gold.dim_date
```

**Step 7:** Columns tab → Join on:

```
Left input (source):     start_date
Right input (dim_date):  full_date
Output Alias:            start_date_key (map to dim_date.date_key)
```

**Step 8:** OK

**Step 9:** Configure Lookup_end similarly for end_date

**Step 10:** Kéo OLE DB Destination

**Step 11:** Nối: Lookup_end → Destination

**Step 12:** Configure Destination

**Dialog:**
```
Connection:  OleDbConnMgr_ShopeeTV3
Table:       gold.dim_campaign
```

**Step 13:** Mappings:

| Source | Destination |
|---|---|
| campaign_id | campaign_id |
| campaign_name | campaign_name |
| campaign_type | campaign_type |
| start_date_key | start_date_key |
| end_date_key | end_date_key |
| budget | budget |

**Step 14:** OK → Save

**Test Run:** Execute package, verify:
```sql
SELECT COUNT(*) FROM gold.dim_campaign;
SELECT TOP 5 * FROM gold.dim_campaign;
```

**Deliverable:** ✅ dim_campaign loaded with date keys

---

## Task 3.13: DFT - Load dim_seller (SCD Type 2) - Part 1: Lookup & Detection

**Mục tiêu:** Detect seller changes (rating/location), expire old records

**Step 1:** Double-click `DFT - Load dim_seller (SCD2)`

**Step 2:** Kéo OLE DB Source → configure

**Dialog:**
```
SQL Command: SELECT 
                s.seller_id,
                s.seller_name,
                s.province,
                s.city,
                s.seller_rating
             FROM staging.stg_sellers s
             WHERE s.seller_id IS NOT NULL;
```

**Step 3:** OK

**Step 4:** Kéo Lookup transformation → double-click

**Dialog - Connection:**
```
Connection: OleDbConnMgr_ShopeeTV3
Table:      gold.dim_seller
```

**Step 5:** Columns tab → Join on:

```
Left (source):           seller_id
Right (dim_seller):      seller_id (WHERE is_current = 1)
```

**Step 6:** Available Input Columns → Select:
- seller_name (from dim_seller)
- province (from dim_seller)
- city (from dim_seller)
- seller_rating (from dim_seller)
- seller_key (from dim_seller)

**Output Alias:** existing_* for each column

**Step 7:** OK

**Step 8:** Kéo Conditional Split → double-click

**Dialog:**

```
Condition 1 (CHANGED):
(seller_name != existing_seller_name) ||
(seller_rating != existing_seller_rating) ||
(province != existing_province) ||
(city != existing_city)

Output: "Changed"

Condition 2 (UNCHANGED):
Default output

Output: "Unchanged"
```

**Step 9:** OK

**Step 10:** From Conditional Split:
- "Changed" output → Multicast
- "Unchanged" output → Discard (Trash component)

**Step 11:** Kéo Multicast → output 2 streams:
- Stream 1: UPDATE old record (expire)
- Stream 2: INSERT new record

**Step 12:** Save (we'll continue with UPDATE/INSERT in next task)

**Deliverable:** ✅ Lookup + Conditional Split logic configured

---

## Task 3.14: DFT - Load dim_seller (SCD Type 2) - Part 2: Multicast & OLE DB Command

**Mục tiêu:** Expire old seller records, insert new versions

**Step 1:** From Multicast output 1 (Expire old)

**Step 2:** Kéo OLE DB Command → double-click

**Dialog:**

```
Connection:      OleDbConnMgr_ShopeeTV3
Timeout:         30
SqlCommand:      UPDATE gold.dim_seller
                 SET is_current = 0,
                     effective_to = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
                 WHERE seller_key = ?

Variable Mappings:
  Parameter 0: existing_seller_key
```

**Step 3:** OK

**Step 4:** From Multicast output 2 (Insert new)

**Step 5:** Kéo Derived Column → add:

```
New Column: effective_from
Expression: CAST(GETDATE() AS DATE)

New Column: effective_to
Expression: CAST('9999-12-31' AS DATE)

New Column: is_current
Expression: 1
```

**Step 6:** OK

**Step 7:** Kéo OLE DB Destination → configure

**Dialog:**
```
Connection: OleDbConnMgr_ShopeeTV3
Table:      gold.dim_seller
```

**Step 8:** Mappings tab:

| Source | Destination |
|---|---|
| seller_id | seller_id |
| seller_name | seller_name |
| province | province |
| city | city |
| seller_rating | seller_rating |
| location_key | location_key |
| effective_from | effective_from |
| effective_to | effective_to |
| is_current | is_current |

**Step 9:** OK → Save

**Test Run:**
```sql
SELECT COUNT(*) FROM gold.dim_seller WHERE is_current = 1;
SELECT * FROM gold.dim_seller ORDER BY seller_id, effective_from;
```

**Deliverable:** ✅ SCD Type 2 logic implemented (expire + insert)

---

## Task 3.15: Verify Dimensions Package Execution

**Mục tiêu:** Chạy toàn bộ Load_Dim_Sellers_Campaign.dtsx, xác nhận tất cả dimension loaded

**Step 1:** Visual Studio → Package Explorer → Load_Dim_Sellers_Campaign.dtsx

**Step 2:** Right-click → Execute Package

**Expected Results:**
- DFT - Load dim_campaign: ✓ Green
- DFT - Load dim_seller (SCD2): ✓ Green

**Step 3:** SSMS verification:

```sql
USE ShopeeThailandDW;
GO

-- Campaign count
SELECT COUNT(*) AS campaign_count FROM gold.dim_campaign;

-- Seller current records
SELECT COUNT(*) AS seller_current_count FROM gold.dim_seller WHERE is_current = 1;

-- Seller history (including expired)
SELECT COUNT(*) AS seller_total_count FROM gold.dim_seller;

-- Sample seller history (if there are changes)
SELECT seller_id, seller_key, seller_rating, effective_from, effective_to, is_current
FROM gold.dim_seller
ORDER BY seller_id, effective_from;
```

**Deliverable:** ✅ All dimension tables loaded successfully

---

## Task 3.16: Create fact_order_lifecycle Table

**Mục tiêu:** Tạo fact table với Accumulating Snapshot pattern cho order lifecycle

**Step 1:** SSMS → chạy DDL:

```sql
USE ShopeeThailandDW;
GO

-- ======================================================
-- FACT TABLE 1: fact_order_lifecycle (Accumulating Snapshot)
-- ======================================================
IF OBJECT_ID('gold.fact_order_lifecycle', 'U') IS NOT NULL
    DROP TABLE gold.fact_order_lifecycle;
GO

CREATE TABLE gold.fact_order_lifecycle (
    order_id                 VARCHAR(50)  NOT NULL PRIMARY KEY,
    seller_key               INT          NOT NULL,
    campaign_key             INT          NULL,
    shipment_key             INT          NULL,
    order_date_key           INT          NOT NULL,
    shipment_date_key        INT          NULL,
    delivery_date_key        INT          NULL,
    expected_delivery_key    INT          NULL,
    days_to_deliver          INT          NULL,
    is_on_time               BIT          NULL,
    is_cancelled             BIT          DEFAULT 0,
    CONSTRAINT FK_lifecycle_seller FOREIGN KEY (seller_key)
        REFERENCES gold.dim_seller(seller_key),
    CONSTRAINT FK_lifecycle_campaign FOREIGN KEY (campaign_key)
        REFERENCES gold.dim_campaign(campaign_key),
    CONSTRAINT FK_lifecycle_shipment FOREIGN KEY (shipment_key)
        REFERENCES gold.dim_shipment(shipment_key),
    CONSTRAINT FK_lifecycle_order_date FOREIGN KEY (order_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_lifecycle_shipment_date FOREIGN KEY (shipment_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_lifecycle_delivery_date FOREIGN KEY (delivery_date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_lifecycle_expected_date FOREIGN KEY (expected_delivery_key)
        REFERENCES gold.dim_date(date_key)
);
GO

CREATE INDEX IX_fact_lifecycle_seller ON gold.fact_order_lifecycle(seller_key);
CREATE INDEX IX_fact_lifecycle_campaign ON gold.fact_order_lifecycle(campaign_key);
CREATE INDEX IX_fact_lifecycle_dates ON gold.fact_order_lifecycle(order_date_key, delivery_date_key);
GO

-- Verify
SELECT 
    COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_order_lifecycle' AND TABLE_SCHEMA = 'gold';
GO
```

**Expected Result:** fact_order_lifecycle created with 11 columns + FKs

**Deliverable:** ✅ fact_order_lifecycle table structure ready

---

# TUẦN 3: TẠO FACT TABLES & LOAD (8 TASKS)

---

## Task 3.17: Create fact_monthly_category_sales Table

**Mục tiêu:** Tạo periodic snapshot cho doanh số hàng tháng theo category

**Step 1:** SSMS → chạy DDL:

```sql
USE ShopeeThailandDW;
GO

-- ======================================================
-- FACT TABLE 2: fact_monthly_category_sales (Periodic Snapshot)
-- ======================================================
IF OBJECT_ID('gold.fact_monthly_category_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_monthly_category_sales;
GO

CREATE TABLE gold.fact_monthly_category_sales (
    date_key              INT            NOT NULL,
    category_key          INT            NOT NULL,
    total_orders          INT            NOT NULL DEFAULT 0,
    total_items_sold      INT            NOT NULL DEFAULT 0,
    total_revenue         DECIMAL(15,2)  NOT NULL DEFAULT 0,
    total_cancelled       INT            NOT NULL DEFAULT 0,
    cancelled_rate        DECIMAL(5,2)   NULL,
    avg_review_score      DECIMAL(3,2)   NULL,
    CONSTRAINT PK_fact_monthly_sales PRIMARY KEY (date_key, category_key),
    CONSTRAINT FK_sales_date FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_sales_category FOREIGN KEY (category_key)
        REFERENCES gold.dim_product_category(category_key)
);
GO

CREATE INDEX IX_fact_monthly_sales_date ON gold.fact_monthly_category_sales(date_key);
GO

-- Verify
SELECT 
    COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_monthly_category_sales' AND TABLE_SCHEMA = 'gold';
GO
```

**Expected Result:** fact_monthly_category_sales created with 8 columns + PK + FKs

**Deliverable:** ✅ fact_monthly_category_sales table structure ready

---

## Task 3.18: Tạo SSIS Package 3 - Load_Fact_Lifecycle_Sales.dtsx

**Mục tiêu:** Xây dựng package load fact tables với UPSERT + REBUILD logic

**Step 1:** Visual Studio → New SSIS Package: `Load_Fact_Lifecycle_Sales.dtsx`

**Step 2:** Control Flow tab

**Step 3:** Kéo tasks:
- Execute SQL Task (EST): `EST - Truncate fact_monthly_sales`
- Data Flow Task (DFT): `DFT - Load fact_order_lifecycle (UPSERT)`
- Data Flow Task (DFT): `DFT - Load fact_monthly_sales (REBUILD)`

**Step 4:** Sequence: DFT_lifecycle → EST_truncate → DFT_monthly

**Step 5:** Save package

**Deliverable:** ✅ Package skeleton with proper sequence

---

## Task 3.19: DFT - Load fact_order_lifecycle (UPSERT Part 1: Lookup & Detection)

**Mục tiêu:** Load orders with shipment info, lookup dim keys, detect new vs existing

**Step 1:** Double-click `DFT - Load fact_order_lifecycle (UPSERT)`

**Step 2:** Kéo OLE DB Source → double-click

**Dialog:**
```
SQL Command: SELECT 
                o.order_id,
                o.seller_id,
                o.campaign_id,
                o.order_date,
                s.shipment_id,
                s.shipment_date,
                s.actual_date,
                s.expected_date,
                s.shipment_method,
                s.is_on_time
             FROM staging.stg_orders o
             LEFT JOIN staging.stg_shipments s ON o.order_id = s.order_id
             WHERE o.order_id IS NOT NULL;
```

**Note:** If stg_orders doesn't exist yet, TV2 should create it. For now, join available tables.

**Step 3:** OK

**Step 4:** Kéo Multiple Lookup transformations:

**Lookup 1 - dim_seller:**
- Connection: OleDbConnMgr_ShopeeTV3
- Table: gold.dim_seller
- Join: seller_id = seller_id (WHERE is_current = 1)
- Output: seller_key

**Lookup 2 - dim_campaign:**
- Join: campaign_id = campaign_id
- Output: campaign_key

**Lookup 3 - dim_shipment:**
- Join: shipment_method = shipment_method
- Output: shipment_key

**Lookup 4 - dim_date (order_date):**
- Join: order_date → full_date
- Output: order_date_key

**Lookup 5 - dim_date (shipment_date):**
- Join: shipment_date → full_date
- Output: shipment_date_key

**Lookup 6 - dim_date (actual_date/delivery_date):**
- Join: actual_date → full_date
- Output: delivery_date_key

**Lookup 7 - dim_date (expected_date):**
- Join: expected_date → full_date
- Output: expected_delivery_key

**Chain:** Source → Lookup1 → Lookup2 → Lookup3 → Lookup4 → Lookup5 → Lookup6 → Lookup7

**Step 5:** After last Lookup, kéo Conditional Split

**Dialog:**

```
Condition: NEW_OR_UPDATE (default, no specific condition)
All rows → Multicast
```

**Step 6:** OK

**Deliverable:** ✅ Lookup chain + Conditional Split configured

---

## Task 3.20: DFT - Load fact_order_lifecycle (UPSERT Part 2: Multicast + Commands)

**Mục tiêu:** INSERT new orders, UPDATE existing shipment info

**Step 1:** From Conditional Split → Multicast

**Step 2:** From Multicast Output 1 (Existing records → UPDATE):

**Step 3:** Kéo OLE DB Command

**Dialog:**
```
Connection: OleDbConnMgr_ShopeeTV3
SqlCommand: UPDATE gold.fact_order_lifecycle
            SET shipment_date_key = ?,
                delivery_date_key = ?,
                expected_delivery_key = ?,
                shipment_key = ?,
                days_to_deliver = DATEDIFF(DAY, ?, ?),
                is_on_time = ?
            WHERE order_id = ?

Parameter Mappings:
  0: shipment_date_key
  1: delivery_date_key
  2: expected_delivery_key
  3: shipment_key
  4: order_date (start)
  5: delivery_date (end)
  6: is_on_time
  7: order_id
```

**Step 4:** OK

**Step 5:** From Multicast Output 2 (New records → INSERT):

**Step 6:** Kéo Derived Column:

```
New Column: days_to_deliver
Expression: DATEDIFF(DAY, order_date, actual_date)
```

**Step 7:** OK

**Step 8:** Kéo OLE DB Destination

**Dialog:**
```
Connection: OleDbConnMgr_ShopeeTV3
Table: gold.fact_order_lifecycle
```

**Mappings:**

| Source | Destination |
|---|---|
| order_id | order_id |
| seller_key | seller_key |
| campaign_key | campaign_key |
| shipment_key | shipment_key |
| order_date_key | order_date_key |
| shipment_date_key | shipment_date_key |
| delivery_date_key | delivery_date_key |
| expected_delivery_key | expected_delivery_key |
| days_to_deliver | days_to_deliver |
| is_on_time | is_on_time |
| is_cancelled | is_cancelled (default 0) |

**Step 9:** OK → Save

**Test Run:**
```sql
SELECT COUNT(*) FROM gold.fact_order_lifecycle;
SELECT TOP 5 * FROM gold.fact_order_lifecycle;
```

**Deliverable:** ✅ UPSERT logic implemented for fact_order_lifecycle

---

## Task 3.21: EST - Truncate fact_monthly_sales

**Mục tiêu:** Setup Execute SQL Task để truncate trước rebuild

**Step 1:** Double-click `EST - Truncate fact_monthly_sales` (Control Flow)

**Dialog:**
```
Connection: OleDbConnMgr_ShopeeTV3
SQLStatement: TRUNCATE TABLE gold.fact_monthly_category_sales;
```

**Step 2:** OK → Save

**Deliverable:** ✅ EST task configured for truncate

---

## Task 3.22: DFT - Load fact_monthly_category_sales (REBUILD)

**Mục tiêu:** Aggregate monthly sales by category from fact_order table

**Step 1:** Double-click `DFT - Load fact_monthly_sales (REBUILD)`

**Step 2:** Kéo OLE DB Source → double-click

**Dialog:**
```
SQL Command: SELECT
                CONVERT(INT, FORMAT(dd.full_date, 'yyyyMM') + '01') AS date_key,
                dpc.category_key,
                COUNT(DISTINCT fo.order_id) AS total_orders,
                SUM(fo.quantity) AS total_items_sold,
                SUM(fo.total_amount) AS total_revenue,
                SUM(CAST(fo.is_cancelled AS INT)) AS total_cancelled,
                CAST(SUM(CAST(fo.is_cancelled AS INT)) * 100.0 / NULLIF(COUNT(DISTINCT fo.order_id), 0) AS DECIMAL(5,2)) AS cancelled_rate,
                AVG(CAST(fo.review_score AS DECIMAL(3,2))) AS avg_review_score
             FROM gold.fact_order fo
             INNER JOIN gold.dim_date dd ON fo.order_date_key = dd.date_key
             INNER JOIN gold.dim_product dp ON fo.product_key = dp.product_key
             INNER JOIN gold.dim_product_category dpc ON dp.category_key = dpc.category_key
             GROUP BY CONVERT(INT, FORMAT(dd.full_date, 'yyyyMM') + '01'), dpc.category_key;
```

**Step 3:** OK

**Step 4:** Kéo OLE DB Destination

**Dialog:**
```
Connection: OleDbConnMgr_ShopeeTV3
Table: gold.fact_monthly_category_sales
```

**Mappings:**

| Source | Destination |
|---|---|
| date_key | date_key |
| category_key | category_key |
| total_orders | total_orders |
| total_items_sold | total_items_sold |
| total_revenue | total_revenue |
| total_cancelled | total_cancelled |
| cancelled_rate | cancelled_rate |
| avg_review_score | avg_review_score |

**Step 5:** OK → Save

**Test Run:**
```sql
SELECT COUNT(*) FROM gold.fact_monthly_category_sales;
SELECT TOP 5 * FROM gold.fact_monthly_category_sales;
```

**Deliverable:** ✅ Monthly sales rebuild logic implemented

---

## Task 3.23: Execute Load_Fact_Lifecycle_Sales Package

**Mục tiêu:** Chạy toàn bộ package, verify both fact tables populated

**Step 1:** Visual Studio → Package Explorer → Load_Fact_Lifecycle_Sales.dtsx

**Step 2:** Right-click → Execute Package

**Expected Results:**
- EST - Truncate: ✓ Green
- DFT - Load lifecycle: ✓ Green
- DFT - Load monthly sales: ✓ Green

**Step 3:** SSMS verification:

```sql
USE ShopeeThailandDW;
GO

-- Lifecycle fact row count
SELECT COUNT(*) AS lifecycle_count FROM gold.fact_order_lifecycle;

-- Monthly sales row count
SELECT COUNT(*) AS monthly_sales_count FROM gold.fact_monthly_category_sales;

-- Sample lifecycle data
SELECT TOP 3 * FROM gold.fact_order_lifecycle;

-- Sample monthly sales data
SELECT TOP 3 * FROM gold.fact_monthly_category_sales;
```

**Deliverable:** ✅ Both fact tables loaded successfully

---

## Task 3.24: Write 3 SQL Queries for Analysis

**Mục tiêu:** Tạo 3 queries phân tích doanh số, vận chuyển, chiến dịch

**Query 1: Top 10 Sellers by Revenue**

```sql
USE ShopeeThailandDW;
GO

SELECT TOP 10
    ds.seller_name,
    ds.province,
    ds.city,
    COUNT(DISTINCT fol.order_id) AS total_orders,
    SUM(fo.total_amount) AS total_revenue,
    CAST(SUM(CAST(fol.is_on_time AS INT)) * 100.0 / COUNT(DISTINCT fol.order_id) AS DECIMAL(5,2)) AS on_time_rate
FROM gold.fact_order_lifecycle fol
INNER JOIN gold.dim_seller ds ON fol.seller_key = ds.seller_key
LEFT JOIN gold.fact_order fo ON fol.order_id = fo.order_id
WHERE ds.is_current = 1 AND fo.order_id IS NOT NULL
GROUP BY ds.seller_name, ds.province, ds.city, ds.seller_rating
ORDER BY total_revenue DESC;
GO
```

**Query 2: Campaign Performance & ROI**

```sql
USE ShopeeThailandDW;
GO

SELECT
    dc.campaign_name,
    dc.campaign_type,
    dd_start.full_date AS campaign_start,
    dd_end.full_date AS campaign_end,
    COUNT(DISTINCT fol.order_id) AS orders_in_campaign,
    SUM(fo.total_amount) AS campaign_revenue,
    dc.budget,
    CAST(SUM(fo.total_amount) * 1.0 / NULLIF(dc.budget, 0) AS DECIMAL(10,2)) AS roi
FROM gold.fact_order_lifecycle fol
LEFT JOIN gold.dim_campaign dc ON fol.campaign_key = dc.campaign_key
LEFT JOIN gold.fact_order fo ON fol.order_id = fo.order_id
LEFT JOIN gold.dim_date dd_start ON dc.start_date_key = dd_start.date_key
LEFT JOIN gold.dim_date dd_end ON dc.end_date_key = dd_end.date_key
WHERE dc.campaign_key IS NOT NULL AND fo.order_id IS NOT NULL
GROUP BY dc.campaign_name, dc.campaign_type, dd_start.full_date, dd_end.full_date, dc.budget
ORDER BY roi DESC;
GO
```

**Query 3: Shipment Method Performance**

```sql
USE ShopeeThailandDW;
GO

SELECT
    dsh.shipment_method,
    dsh.provider_name,
    COUNT(*) AS total_shipments,
    SUM(CAST(fol.is_on_time AS INT)) AS on_time_count,
    CAST(SUM(CAST(fol.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_rate,
    AVG(fol.days_to_deliver) AS avg_delivery_days
FROM gold.fact_order_lifecycle fol
INNER JOIN gold.dim_shipment dsh ON fol.shipment_key = dsh.shipment_key
WHERE fol.shipment_key IS NOT NULL
GROUP BY dsh.shipment_method, dsh.provider_name
ORDER BY on_time_rate DESC;
GO
```

**Step 1:** SSMS → Create new Query Tab

**Step 2:** Copy Query 1, execute, save results

**Expected Output:** Top sellers with revenue & on-time rate

**Step 3:** Repeat for Query 2 and Query 3

**Deliverable:** ✅ 3 queries written and tested

---

# TUẦN 4: MASTER PACKAGE & VALIDATION (8 TASKS)

---

## Task 3.25: Tạo Master_ETL.dtsx Package

**Mục tiêu:** Integrate TV1, TV2, TV3 packages vào Master with 4-step orchestration

**Step 1:** Visual Studio → New SSIS Package: `Master_ETL.dtsx`

**Step 2:** Control Flow tab

**Step 3:** Kéo 4 Sequence Containers (to organize steps):
- Container 1: `STEP 1 - EXTRACT (Parallel)`
- Container 2: `STEP 2 - LOAD DIMENSIONS (Sequential)`
- Container 3: `STEP 3 - LOAD CENTRAL FACT (Critical)`
- Container 4: `STEP 4 - LOAD AGGREGATES (Parallel)`

**Step 4:** Connect sequentially: Container1 → Container2 → Container3 → Container4

**Step 5:** Inside each container, we'll add Execute Package Tasks (next tasks)

**Step 6:** Save package

**Deliverable:** ✅ Master package skeleton with 4 containers

---

## Task 3.26: Configure STEP 1 - Extract (Parallel)

**Mục tiêu:** Execute TV1, TV2, TV3 extract packages in parallel

**Step 1:** Double-click `STEP 1 - EXTRACT (Parallel)` container

**Step 2:** Kéo 3 Execute Package Tasks:
- `TV1 - Execute Extract_Customers_Sessions.dtsx`
- `TV2 - Execute Extract_Products_Orders.dtsx`
- `TV3 - Execute Extract_Sellers_Campaigns.dtsx`

**Step 3:** Configure each Execute Package Task:

**For TV1 Extract:**
- Double-click task → Dialog
- Location: File System
- File: C:\...\ShopeeTV1_ETL\Extract_Customers_Sessions.dtsx
- Execute outside transaction: ✓ Checked

**For TV2 Extract:**
- Similar config, point to TV2 project
- File: C:\...\ShopeeTV2_ETL\Extract_Products_Orders.dtsx

**For TV3 Extract:**
- File: C:\...\ShopeeTV3_ETL\Extract_Sellers_Campaigns.dtsx

**Step 4:** Do NOT connect these 3 tasks (leave them parallel)

**Step 5:** OK → Save

**Step 6:** Test Run this container alone:

```
All 3 should execute in parallel, all turning green ✓
```

**Deliverable:** ✅ STEP 1 - Extract executing all 3 packages in parallel

---

## Task 3.27: Configure STEP 2 - Dimensions (Sequential)

**Mục tiêu:** Execute TV1, TV2, TV3 dimension packages sequentially with proper ordering

**Step 1:** Double-click `STEP 2 - LOAD DIMENSIONS (Sequential)` container

**Step 2:** Kéo 3 Execute Package Tasks:
- `TV1 - Execute Load_Dim_Customers.dtsx`
- `TV2 - Execute Load_Dim_Product.dtsx`
- `TV3 - Execute Load_Dim_Sellers_Campaign.dtsx`

**Step 3:** Configure and connect sequentially:

**Task 1 (TV1):**
- Execute Package → Load_Dim_Customers.dtsx
- TV1 creates dim_date + dim_location (required by TV3)

**Task 2 (TV2):**
- Execute Package → Load_Dim_Product.dtsx
- Depends on TV1 (dim_date for FK)
- Connect: TV1 → TV2

**Task 3 (TV3):**
- Execute Package → Load_Dim_Sellers_Campaign.dtsx
- Depends on TV1 (dim_location FK) + TV2 (dim_date FK)
- Connect: TV2 → TV3

**Step 4:** OK → Save

**Step 5:** Test Run:

```
Execution order: TV1 → TV2 → TV3 (sequential)
All should be green ✓
```

**Deliverable:** ✅ STEP 2 - Dimensions executing sequentially with proper dependencies

---

## Task 3.28: Configure STEP 3 - Load Central Fact

**Mục tiêu:** Execute TV2's fact_order package (CRITICAL PATH - must complete before aggregates)

**Step 1:** Double-click `STEP 3 - LOAD CENTRAL FACT (Critical)` container

**Step 2:** Kéo 1 Execute Package Task:
- `TV2 - Execute Load_Fact_Order.dtsx`

**Step 3:** Configure:

```
Location: File System
File: C:\...\ShopeeTV2_ETL\Load_Fact_Order.dtsx
Execute outside transaction: ✓ Checked
```

**Step 4:** OK → Save

**Note:** This is the critical path. fact_order table is the central fact that aggregates depend on.

**Step 5:** Test Run:

```
Should execute fact_order load successfully ✓
```

**Deliverable:** ✅ STEP 3 - Central fact_order loaded (critical path)

---

## Task 3.29: Configure STEP 4 - Aggregates (Parallel)

**Mục tiêu:** Execute TV3's fact_lifecycle + monthly sales packages in parallel

**Step 1:** Double-click `STEP 4 - LOAD AGGREGATES (Parallel)` container

**Step 2:** Kéo 2 Execute Package Tasks:
- `TV3 - Execute Load_Fact_Lifecycle_Sales.dtsx`
- `TV1 - Execute Load_Session_Facts.dtsx` (if exists, else just TV3)

**Step 3:** Configure TV3 task:

```
Location: File System
File: C:\...\ShopeeTV3_ETL\Load_Fact_Lifecycle_Sales.dtsx
```

**Step 4:** Do NOT connect these tasks (keep parallel)

**Step 5:** OK → Save

**Step 6:** Test Run:

```
Both should execute in parallel, both green ✓
```

**Deliverable:** ✅ STEP 4 - Aggregates executing in parallel

---

## Task 3.30: Execute Full Master_ETL Package

**Mục tiêu:** Run Master_ETL.dtsx end-to-end, verify all 4 steps complete successfully

**Step 1:** Visual Studio → Package Explorer → Master_ETL.dtsx

**Step 2:** Right-click → Execute Package

**Step 3:** Watch Execution Flow:

```
STEP 1 - EXTRACT (Parallel)
  ├─ TV1 - Extract: ✓ Green
  ├─ TV2 - Extract: ✓ Green
  └─ TV3 - Extract: ✓ Green
         │
         ▼
STEP 2 - LOAD DIMENSIONS (Sequential)
  ├─ TV1 - Load Dim: ✓ Green
  ├─ TV2 - Load Dim: ✓ Green
  └─ TV3 - Load Dim: ✓ Green
         │
         ▼
STEP 3 - LOAD CENTRAL FACT
  └─ TV2 - Fact Order: ✓ Green
         │
         ▼
STEP 4 - LOAD AGGREGATES (Parallel)
  ├─ TV3 - Lifecycle + Sales: ✓ Green
  └─ TV1 - Session Facts: ✓ Green (if exists)
```

**Expected Output:** "Package execution completed successfully"

**Step 4:** Total runtime should be ~5-10 minutes (depending on data volume)

**Deliverable:** ✅ Master_ETL executed end-to-end successfully

---

## Task 3.31: Comprehensive Data Validation

**Mục tiêu:** Verify all tables populated, FK integrity, data quality

**Step 1:** SSMS → run comprehensive validation script:

```sql
USE ShopeeThailandDW;
GO

-- ===========================================
-- VALIDATION 1: Table Row Counts
-- ===========================================
SELECT
    'staging.stg_sellers' AS TableName,
    COUNT(*) AS RowCount
FROM staging.stg_sellers
UNION ALL
SELECT 'staging.stg_shipments', COUNT(*) FROM staging.stg_shipments
UNION ALL
SELECT 'staging.stg_campaigns', COUNT(*) FROM staging.stg_campaigns
UNION ALL
SELECT 'gold.dim_seller', COUNT(*) FROM gold.dim_seller
UNION ALL
SELECT 'gold.dim_campaign', COUNT(*) FROM gold.dim_campaign
UNION ALL
SELECT 'gold.dim_shipment', COUNT(*) FROM gold.dim_shipment
UNION ALL
SELECT 'gold.fact_order_lifecycle', COUNT(*) FROM gold.fact_order_lifecycle
UNION ALL
SELECT 'gold.fact_monthly_category_sales', COUNT(*) FROM gold.fact_monthly_category_sales;

-- ===========================================
-- VALIDATION 2: SCD Type 2 Check (dim_seller)
-- ===========================================
SELECT
    COUNT(DISTINCT seller_id) AS unique_sellers,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_records,
    SUM(CASE WHEN is_current = 0 THEN 1 ELSE 0 END) AS expired_records,
    COUNT(*) AS total_records
FROM gold.dim_seller;

-- ===========================================
-- VALIDATION 3: Foreign Key Integrity
-- ===========================================
-- Check fact_order_lifecycle FKs
SELECT COUNT(*) AS lifecycle_with_invalid_seller
FROM gold.fact_order_lifecycle fol
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_seller ds WHERE fol.seller_key = ds.seller_key);

SELECT COUNT(*) AS lifecycle_with_invalid_campaign
FROM gold.fact_order_lifecycle fol
WHERE fol.campaign_key IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM gold.dim_campaign dc WHERE fol.campaign_key = dc.campaign_key);

SELECT COUNT(*) AS lifecycle_with_invalid_shipment
FROM gold.fact_order_lifecycle fol
WHERE fol.shipment_key IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM gold.dim_shipment ds WHERE fol.shipment_key = ds.shipment_key);

-- ===========================================
-- VALIDATION 4: Data Quality Checks
-- ===========================================
-- Check for NULLs in critical columns
SELECT
    'fact_order_lifecycle' AS TableName,
    'seller_key' AS Column,
    COUNT(*) AS null_count
FROM gold.fact_order_lifecycle
WHERE seller_key IS NULL
UNION ALL
SELECT 'fact_order_lifecycle', 'order_date_key', COUNT(*)
FROM gold.fact_order_lifecycle
WHERE order_date_key IS NULL;

-- ===========================================
-- VALIDATION 5: Sample Data Review
-- ===========================================
SELECT TOP 5 'dim_seller' AS Table, seller_id, seller_name, seller_rating, is_current FROM gold.dim_seller
UNION ALL
SELECT TOP 5 'dim_campaign', campaign_id, campaign_name, campaign_type, 0 FROM gold.dim_campaign
UNION ALL
SELECT TOP 5 'dim_shipment', shipment_method, provider_name, 0, 0 FROM gold.dim_shipment;

SELECT TOP 5 * FROM gold.fact_order_lifecycle;
SELECT TOP 5 * FROM gold.fact_monthly_category_sales;

GO
```

**Expected Results:**
- All tables have row counts > 0
- dim_seller: SCD Type 2 properly tracked with is_current flag
- No FK violations
- No NULLs in critical columns
- Sample data looks reasonable

**Step 2:** If any validation fails, troubleshoot:
- Check source CSV files have data
- Verify lookups in SSIS packages
- Check FK column mappings

**Deliverable:** ✅ All data validation checks passed

---

## Task 3.32: Documentation & Checklist

**Mục tiêu:** Document all packages, create final checklist

**Step 1:** Create summary document:

```
==============================================
TV3 DELIVERABLES SUMMARY
==============================================

STAGING TABLES (3):
  [✓] staging.stg_sellers
  [✓] staging.stg_shipments
  [✓] staging.stg_campaigns

DIMENSION TABLES (3):
  [✓] gold.dim_seller (SCD Type 2 with effective_from/to)
  [✓] gold.dim_campaign (Type 1)
  [✓] gold.dim_shipment (Static)

FACT TABLES (2):
  [✓] gold.fact_order_lifecycle (Accumulating Snapshot)
  [✓] gold.fact_monthly_category_sales (Periodic Snapshot)

SSIS PACKAGES (3):
  [✓] Extract_Sellers_Campaigns.dtsx
      - EST: Truncate staging
      - DFT: Load sellers
      - DFT: Load shipments (with is_on_time calc)
      - DFT: Load campaigns
  
  [✓] Load_Dim_Sellers_Campaign.dtsx
      - DFT: Load dim_campaign (with date lookups)
      - DFT: Load dim_seller (SCD Type 2 with Multicast)
  
  [✓] Load_Fact_Lifecycle_Sales.dtsx
      - DFT: Load fact_order_lifecycle (UPSERT with Multicast)
      - EST: Truncate fact_monthly_sales
      - DFT: Load fact_monthly_sales (REBUILD aggregate)

MASTER PACKAGE:
  [✓] Master_ETL.dtsx (4-step orchestration)
      STEP 1: Extract (TV1 || TV2 || TV3 parallel)
      STEP 2: Dimensions (TV1 → TV2 → TV3 sequential)
      STEP 3: Central Fact (TV2 fact_order)
      STEP 4: Aggregates (TV3 + TV1 parallel)

SQL QUERIES (3):
  [✓] Top 10 sellers by revenue with on-time rate
  [✓] Campaign performance & ROI analysis
  [✓] Shipment method performance & on-time rate

DATA VALIDATION:
  [✓] All tables populated
  [✓] SCD Type 2 history tracked
  [✓] No FK violations
  [✓] No critical NULLs
  [✓] End-to-end package execution successful

==============================================
```

**Step 2:** Save as TV3_DELIVERABLES.md

**Deliverable:** ✅ Complete documentation created

---

# ✅ FINAL CHECKLIST - TV3

**Before marking as complete:**

- [ ] ✅ Database & Schemas verified (ShopeeThailandDW with staging & gold)
- [ ] ✅ Connection Manager created & tested
- [ ] ✅ 3 Staging tables created (stg_sellers, stg_shipments, stg_campaigns)
- [ ] ✅ Extract_Sellers_Campaigns.dtsx package created & executed (all DFTs green)
- [ ] ✅ 3 Dimension tables created (dim_seller SCD2, dim_campaign, dim_shipment)
- [ ] ✅ Load_Dim_Sellers_Campaign.dtsx package created & executed (dimensions loaded)
- [ ] ✅ SCD Type 2 logic verified (expire old + insert new with effective dates)
- [ ] ✅ 2 Fact tables created (fact_order_lifecycle, fact_monthly_category_sales)
- [ ] ✅ Load_Fact_Lifecycle_Sales.dtsx package created & executed (facts loaded)
- [ ] ✅ UPSERT logic verified for fact_order_lifecycle (Lookup + Conditional Split + Multicast)
- [ ] ✅ REBUILD logic verified for fact_monthly_sales (Truncate + Insert aggregates)
- [ ] ✅ Master_ETL.dtsx created with 4-step orchestration
- [ ] ✅ Master package executed end-to-end (all 4 steps green, ~5-10 minutes runtime)
- [ ] ✅ 3 SQL queries written & tested (seller revenue, campaign ROI, shipment performance)
- [ ] ✅ Comprehensive data validation passed (row counts, FK integrity, data quality)
- [ ] ✅ No FK violations detected
- [ ] ✅ Documentation completed & archived

**Status: ✅ TV3 COMPLETE - Ready for production deployment**

---

**Next Steps for Team:**
1. TV2 completes fact_order table (critical path for TV3 aggregates)
2. All teams test Master_ETL.dtsx end-to-end
3. Schedule full end-to-end ETL execution
4. Monitor performance & implement tuning if needed
