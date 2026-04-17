# 📘 GUIDE_TV1_SHOPEE.md – Thành viên 1: Khách hàng, Thời gian & Devices

**Domain:** Customers, Datetime, Devices  
**Staging Tables:** 3 (stg_customers, stg_session_activities, stg_reviews)  
**Dimensions:** 5 (dim_date, dim_location, dim_customer, dim_device, dim_page)  
**Facts:** 1 (fact_session)  
**SSIS Packages:** 3 (Extract, Load_Dims, Load_Facts)  
**Công việc chung:** Khởi tạo Database + Schemas

---

# TUẦN 1: CHUẨN BỊ + EXTRACT

---

## TASK 1.1: Tạo Database + Schemas (Chung TV1-TV2-TV3)

**Mục tiêu:** Tạo môi trường cơ sở dữ liệu cho toàn team

**Chi tiết Step-by-Step:**

### Step 1: Mở SQL Server Management Studio (SSMS)
1. Tìm **SQL Server Management Studio** trên máy
2. Click để mở
3. **Connect** dialog sẽ hiện:
   - **Server name:** Nhập `localhost` hoặc `.\SQLEXPRESS` (tùy setup của bạn)
   - **Authentication:** Chọn `Windows Authentication`
   - Click **Connect**

### Step 2: Tạo Database mới
1. Trong SSMS, click **New Query** (toolbar trên cùng)
2. Paste script:
   ```sql
   CREATE DATABASE ShopeeThailandDW;
   GO
   ```
3. Highlight script → Click **Execute** (hay Ctrl+Shift+E)
4. **Output** phải hiện: `Commands completed successfully`

### Step 3: Verify Database được tạo
1. Ở panel trái **Object Explorer**, tìm **Databases** folder
2. Click chuột phải → **Refresh**
3. Nên thấy `ShopeeThailandDW` trong danh sách

### Step 4: Tạo 2 Schemas trong Database
1. Click **New Query** lại
2. Paste:
   ```sql
   USE ShopeeThailandDW;
   GO
   
   CREATE SCHEMA staging;
   GO
   
   CREATE SCHEMA gold;
   GO
   ```
3. Execute
4. Verify: Trong Object Explorer → ShopeeThailandDW → Security → Schemas, phải thấy `staging` + `gold`

**Output:** 
- ✅ Database `ShopeeThailandDW` created
- ✅ Schema `staging` created
- ✅ Schema `gold` created

**Thời gian:** ~5 phút

**Thông báo TV2 & TV3:** Server name + Database name

---

## TASK 1.2: Tạo SSIS Project + Connection Manager (Chung)

**Mục tiêu:** Setup SSIS infrastructure cho ETL

### Step 1: Mở Visual Studio
1. Tìm **Visual Studio** (hoặc SQL Server Data Tools - SSDT)
2. Click để mở

### Step 2: Tạo Integration Services Project
1. **File** → **New** → **Project**
2. Dialog **New Project**:
   - Tìm template: **Integration Services Project**
   - **Name:** `ShopeeThailandDW_ETL`
   - **Location:** Chọn folder (ví dụ: `D:\Projects\`)
3. Click **Create**
4. Visual Studio tạo project với 1 package mặc định `Package.dtsx`

### Step 3: Rename package mặc định
1. Ở **Solution Explorer** (bên phải), chuột phải `Package.dtsx`
2. **Rename** → gõ `Extract_Customers_Sessions.dtsx`
3. Enter

### Step 4: Tạo 2 packages bổ sung
1. Chuột phải thư mục **SSIS Packages** → **New SSIS Package**
2. System tạo `Package1.dtsx`
3. Rename → `Load_Dim_Customers.dtsx`
4. Lặp lại → `Load_Fact_Session.dtsx`

### Step 5: Tạo OLE DB Connection Manager (dùng chung cho team)
1. Double-click `Extract_Customers_Sessions.dtsx` → mở package
2. Ở panel dưới cùng tìm **Connection Managers** (trống lúc đầu)
3. Chuột phải vùng trống → **New OLE DB Connection**
4. Dialog **Configure OLE DB Connection Manager**:
   - Click **New...**
5. Dialog **Connection Manager**:
   ```
   Server name:        localhost  (hoặc .\SQLEXPRESS)
   Authentication:     ✓ Windows Authentication
   Database:           ShopeeThailandDW  (dropdown)
   ```
6. Click **Test Connection** → "Test connection succeeded" ✓
7. Click **OK** → **OK**
8. Connection xuất hiện ở panel dưới → chuột phải → **Rename** → `ShopeeThailandDW_OLEDB`
9. **🔴 QUAN TRỌNG:** Chuột phải connection → **Convert to Project Connection**
   - Lúc này connection có thể dùng chung cho TẤT CẢ packages trong project

**Output:**
- ✅ SSIS Project created
- ✅ 3 packages created (Extract, Load_Dim, Load_Fact)
- ✅ Project Connection `ShopeeThailandDW_OLEDB` ready

**Thời gian:** ~10 phút

---

## TASK 1.3: Tạo 3 Staging Tables DDL

**Mục tiêu:** Chuẩn bị schema staging layer

### Step 1: Tạo stg_customers
Trong SSMS, New Query, paste:
```sql
USE ShopeeThailandDW;
GO

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
```
Execute

### Step 2: Tạo stg_session_activities
Paste:
```sql
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
```
Execute

### Step 3: Tạo stg_reviews
Paste:
```sql
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
```
Execute

### Step 4: Verify
Paste verify script:
```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'staging'
ORDER BY TABLE_NAME;
```
Execute → phải thấy 3 bảng

**Output:**
- ✅ stg_customers created (10 columns)
- ✅ stg_session_activities created (7 columns)
- ✅ stg_reviews created (6 columns)

**Thời gian:** ~5 phút

---

## TASK 1.4: Create SSIS Package: Extract_Customers_Sessions.dtsx

**Mục tiêu:** Setup package structure

### Step 1: Mở package trong Visual Studio
1. Double-click `Extract_Customers_Sessions.dtsx` trong Solution Explorer
2. Mở tab **Control Flow** (ở dưới canvas)
3. Canvas trống - ready để thêm components

### Step 2: Thêm Execute SQL Task - Truncate
1. **SSIS Toolbox** (bên trái):
   - Tìm **Execute SQL Task** (trong "Control Flow Tasks")
   - Kéo vào Control Flow canvas
2. Double-click task → **Execute SQL Task Editor**:
   - **Name:** `EST - Truncate Staging`
   - **Connection:** `ShopeeThailandDW_OLEDB`
   - **SQLSourceType:** `Direct input`
   - **SQLStatement:** Click `...` button, paste:
     ```sql
     TRUNCATE TABLE staging.stg_customers;
     TRUNCATE TABLE staging.stg_session_activities;
     TRUNCATE TABLE staging.stg_reviews;
     ```
3. Click **OK**

### Step 3: Thêm 3 Data Flow Tasks
1. Từ Toolbox, tìm **Data Flow Task**
2. Kéo vào canvas 3 lần
3. Rename:
   - `DFT - Load Customers`
   - `DFT - Load Sessions`
   - `DFT - Load Reviews`

### Step 4: Nối Precedence Constraints (Success)
1. Click `EST - Truncate Staging` task
2. Kéo **mũi tên xanh** (Output → Success) xuống `DFT - Load Customers`
3. Lặp lại cho `DFT - Load Sessions` và `DFT - Load Reviews`
4. Canvas sẽ hiện:
   ```
   [EST - Truncate]
      ↓ ↓ ↓ (3 mũi tên success)
   [DFT-Cust] [DFT-Sess] [DFT-Rev]
   ```

**Output:**
- ✅ Control Flow structure created
- ✅ 3 DFTs ready for data flow configuration

**Thời gian:** ~5 phút

---

## TASK 1.5-1.8: Xây dựng Data Flows (Chi tiết trong PHẦN 2)

Xem **PHẦN 2 TUẦN 1 – DATA FLOW CONFIGURATION** bên dưới

---

# PHẦN 2: DATA FLOW CONFIGURATION (Chi tiết từng component)

---

## TASK 1.5: Data Flow 1 - Load Customers (Step-by-Step)

**Mục tiêu:** Extract từ CSV → Load staging.stg_customers

### Step 1: Vào Data Flow Tab
1. Double-click `DFT - Load Customers` trong Control Flow
2. Visual Studio chuyển sang tab **Data Flow**
3. Canvas trống - ready

### Step 2: Thêm Flat File Source
1. **SSIS Toolbox** → tìm **Flat File Source** (trong "Data Flow Sources")
2. Kéo vào canvas

### Step 3: Tạo Flat File Connection Manager
1. Double-click **Flat File Source** → **Flat File Source Editor**
2. **Connection manager name:** Chưa có → Click **New...**
3. Dialog **Flat File Connection Manager Editor**:

**Tab General:**
   - **Connection manager name:** `FF_Customers`
   - **File name:** Click **Browse** → Chọn:
     ```
     /home/danhtran/hehe/Shopee/shopee_customers_thailand.csv
     ```
   - **Format:** `Delimited`
   - **Text qualifier:** `"`
   - **Column delimiter:** `Comma {,}`
   - ✅ **Column names in the first data row:** CHECK
   - **Code page:** `65001 (UTF-8)`

4. Click **OK** (quay lại Flat File Source Editor)

### Step 4: Verify Columns
1. Ở Flat File Source Editor, click **Tab Columns**
2. Sẽ hiện 10 cột từ CSV:
   - customer_id, first_name, last_name, gender, dob, registration_date, phone, email, province, city
3. Verify: 10 cột đầy đủ ✓

### Step 5: Set DataTypes (Tab Advanced)
1. Click **Tab Advanced**
2. Cho mỗi cột, click tên → panel phải set:
   - **customer_id** → `string [DT_STR]` | Width: 50
   - **first_name** → `Unicode string [DT_WSTR]` | Width: 100
   - **last_name** → `Unicode string [DT_WSTR]` | Width: 100
   - **gender** → `string [DT_STR]` | Width: 10
   - **dob** → `string [DT_STR]` | Width: 20 (convert sau nếu cần)
   - **registration_date** → `string [DT_STR]` | Width: 20
   - **phone** → `string [DT_STR]` | Width: 20
   - **email** → `string [DT_STR]` | Width: 100
   - **province** → `Unicode string [DT_WSTR]` | Width: 100
   - **city** → `Unicode string [DT_WSTR]` | Width: 100

3. Click **OK**

### Step 6: Thêm OLE DB Destination
1. Từ Toolbox, kéo **OLE DB Destination** vào canvas
2. Nối từ Flat File Source:
   - Click Flat File Source → kéo **mũi tên xanh** xuống OLE DB Destination
   - Sẽ hiện đường xanh nối 2 component

### Step 7: Cấu hình OLE DB Destination
1. Double-click **OLE DB Destination**
2. **Tab Connection Manager:**
   - **OLE DB connection manager:** `ShopeeThailandDW_OLEDB`
   - **Data access mode:** `Table or view - fast load`
   - **Name of table or view:** `[staging].[stg_customers]`
   - ✅ **Table lock:** CHECK
   - ✅ **Check constraints:** CHECK

3. **Tab Mappings:**
   - Verify: 10 input columns → 10 destination columns (auto-map)
   - Mapping phải đúng:
     ```
     customer_id → customer_id
     first_name → first_name
     ... (tất cả 10)
     ```

4. Click **OK**

### Step 8: Test Data Flow
1. Quay lại **Control Flow** tab
2. Click chuột phải `DFT - Load Customers` → **Execute**
   - Hoặc nhấn **F5** (execute whole package)
3. Visual Studio chạy, component sẽ:
   - **Vàng** = running
   - **Xanh** = success
4. Verify: Cả Flat File Source + OLE DB Destination = xanh ✓
5. Click **Stop Debugging** khi xong

### Step 9: Verify dữ liệu trong SSMS
1. Trong SSMS, New Query:
   ```sql
   SELECT COUNT(*) AS row_count FROM staging.stg_customers;
   ```
2. Execute → phải thấy ~100,000 rows

**Output:**
- ✅ FF_Customers connection created
- ✅ Data Flow configured (FF Source → OLE DB Dest)
- ✅ ~100K rows loaded to stg_customers

**Thời gian:** ~15 phút

---

## TASK 1.6-1.8: Load Sessions + Reviews (Tương tự 1.5)

Lặp lại các bước 1.5 cho:

**1.6 - Sessions:**
- CSV: `shopee_session_activities_thailand.csv`
- Staging: `[staging].[stg_session_activities]`
- Columns: 7 (session_id, customer_id, session_date, session_duration, device_type, activity_count, page_view_count)
- Expected rows: ~50K

**1.7 - Reviews:**
- CSV: `shopee_reviews_thailand.csv`
- Staging: `[staging].[stg_reviews]`
- Columns: 6 (review_id, order_id, customer_id, review_score, review_comment, review_date)
- Expected rows: ~80K

**TASK 1.8: Test Extract Package**
1. Chuột phải package `Extract_Customers_Sessions.dtsx` → **Execute Package**
2. Tất cả 3 DFTs phải chạy xanh (song parallel)
3. Verify trong SSMS:
   ```sql
   SELECT 'stg_customers' AS tbl, COUNT(*) AS rows FROM staging.stg_customers
   UNION ALL
   SELECT 'stg_sessions', COUNT(*) FROM staging.stg_session_activities
   UNION ALL
   SELECT 'stg_reviews', COUNT(*) FROM staging.stg_reviews;
   ```
   Expected:
   - stg_customers: ~100K
   - stg_sessions: ~50K
   - stg_reviews: ~80K

---

# TUẦN 2: EXTRACT (TIẾP) + DIMENSIONS

---

## TASK 2.1-2.3: Tạo Dimensions DDL

**Mục tiêu:** Tạo schema cho dimension layer

### TASK 2.1: Tạo dim_date (Static)
Trong SSMS, New Query:
```sql
USE ShopeeThailandDW;
GO

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
```

### TASK 2.2: Tạo dim_location (SCD Type 1)
```sql
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
```

### TASK 2.3: Tạo dim_customer (SCD Type 2)
```sql
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
    -- SCD Type 2
    effective_from    DATE              NOT NULL DEFAULT '1900-01-01',
    effective_to      DATE              NOT NULL DEFAULT '9999-12-31',
    is_current        BIT               NOT NULL DEFAULT 1,
    CONSTRAINT FK_dim_customer_location FOREIGN KEY (location_key)
        REFERENCES gold.dim_location(location_key)
);
GO

CREATE INDEX IX_dim_customer ON gold.dim_customer(customer_id, is_current);
GO
```

### TASK 2.4-2.5: Tạo dim_device + dim_page (Static Lookups)
```sql
-- dim_device
IF OBJECT_ID('gold.dim_device', 'U') IS NOT NULL
    DROP TABLE gold.dim_device;
GO

CREATE TABLE gold.dim_device (
    device_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    device_type  VARCHAR(20)       NOT NULL UNIQUE
);
GO

-- dim_page
IF OBJECT_ID('gold.dim_page', 'U') IS NOT NULL
    DROP TABLE gold.dim_page;
GO

CREATE TABLE gold.dim_page (
    page_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    page_type    VARCHAR(50)       NOT NULL UNIQUE
);
GO
```

**Output:**
- ✅ 5 dimension tables DDL created

---

## TASK 2.6: Create SSIS Package: Load_Dim_Customers.dtsx

**Chi tiết từng bước:**

### Step 1: Mở package
1. Double-click `Load_Dim_Customers.dtsx` trong Solution Explorer
2. Tab **Control Flow**
3. Canvas trống

### Step 2: Thêm Execute SQL Tasks
1. Kéo **Execute SQL Task** → Rename `EST - Populate dim_date`
2. Double-click:
   - **Connection:** `ShopeeThailandDW_OLEDB`
   - **SQLStatement:** (xem bước 2.7 bên dưới)
3. Click **OK**

Lặp lại cho `EST - Populate dim_device` + `EST - Populate dim_page`

### Step 3: Nối Precedence Constraints
```
[EST - Populate dim_date]
    ↓ Success
[EST - Populate dim_device]
    ↓ Success
[EST - Populate dim_page]
    ↓ Success (ready cho DFTs tiếp)
```

### Step 4: Thêm 3 Data Flow Tasks
1. Kéo **Data Flow Task** × 3
2. Rename:
   - `DFT - Load dim_location (SCD Type 1)`
   - `DFT - Load dim_customer (SCD Type 2)`
   - (3rd for future)
3. Nối:
   ```
   [EST - Populate dim_page]
        ↓
   [DFT - Load dim_location]
        ↓
   [DFT - Load dim_customer]
   ```

**Output:**
- ✅ Load_Dim package structure ready

**Thời gian:** ~10 phút

---

## TASK 2.7: EST - Populate dim_date (Execute SQL)

### Step 1: Double-click `EST - Populate dim_date` → Edit SQL

**SQLStatement:**
```sql
IF NOT EXISTS (SELECT 1 FROM gold.dim_date)
BEGIN
    DECLARE @start DATE = '2020-01-01';
    DECLARE @end   DATE = '2025-12-31';

    ;WITH DateCTE AS (
        SELECT @start AS dt
        UNION ALL
        SELECT DATEADD(DAY, 1, dt) FROM DateCTE WHERE dt < @end
    )
    INSERT INTO gold.dim_date (
        date_key, full_date, year, quarter, month, month_name,
        day_of_month, day_of_week, day_name, is_weekend, is_holiday
    )
    SELECT
        CONVERT(INT, FORMAT(dt, 'yyyyMMdd')),
        dt,
        YEAR(dt),
        DATEPART(QUARTER, dt),
        MONTH(dt),
        DATENAME(MONTH, dt),
        DAY(dt),
        DATEPART(WEEKDAY, dt),
        DATENAME(WEEKDAY, dt),
        CASE WHEN DATEPART(WEEKDAY, dt) IN (1, 7) THEN 1 ELSE 0 END,
        0
    FROM DateCTE
    OPTION (MAXRECURSION 2500);
END
```

### Step 2: Test chạy
1. Chuột phải task → **Execute**
2. Phải xanh ✓
3. Verify:
   ```sql
   SELECT COUNT(*) FROM gold.dim_date;
   -- Expected: 2191 rows (2020-01-01 to 2025-12-31)
   ```

**Output:**
- ✅ dim_date populated (2191 rows)

---

## TASK 2.8: EST - Populate dim_device + dim_page

### dim_device:
```sql
IF NOT EXISTS (SELECT 1 FROM gold.dim_device)
BEGIN
    INSERT INTO gold.dim_device (device_type) VALUES
        ('Mobile'),
        ('Desktop'),
        ('Tablet');
END
```

### dim_page:
```sql
IF NOT EXISTS (SELECT 1 FROM gold.dim_page)
BEGIN
    INSERT INTO gold.dim_page (page_type) VALUES
        ('Homepage'),
        ('Product Page'),
        ('Cart'),
        ('Checkout'),
        ('Account');
END
```

Test chạy → Verify:
```sql
SELECT COUNT(*) FROM gold.dim_device;   -- 3
SELECT COUNT(*) FROM gold.dim_page;     -- 5
```

**Output:**
- ✅ dim_device populated (3 rows)
- ✅ dim_page populated (5 rows)

---

# TUẦN 3: DIMENSIONS (Data Flow Tasks)

---

## TASK 3.1-3.2: DFT - Load dim_location + dim_customer (SCD Type 2)

**Chi tiết**: Xem **PHẦN 3 – SCD TYPE 2 IMPLEMENTATION** bên dưới (quá dài, tách riêng)

---

# TUẦN 4: FACTS + ANALYTICS

---

## TASK 4.1-4.3: SQL Queries (3 insights)

### Query 1: Top tỉnh/thành phố có khách hàng nhiều nhất

```sql
SELECT TOP 10
    dl.province,
    dl.region,
    COUNT(DISTINCT dc.customer_key) AS unique_customers,
    COUNT(DISTINCT dc.customer_key) * 100.0 
        / (SELECT COUNT(DISTINCT customer_key) FROM gold.dim_customer WHERE is_current=1) AS pct
FROM gold.dim_customer dc
INNER JOIN gold.dim_location dl ON dc.location_key = dl.location_key
WHERE dc.is_current = 1
GROUP BY dl.province, dl.region
ORDER BY unique_customers DESC;
```

**Chạy:** New Query trong SSMS → Execute → Verify có kết quả

### Query 2: Phân bố khách hàng theo thiết bị

```sql
SELECT
    fs.device_type,
    COUNT(DISTINCT fs.session_id) AS total_sessions,
    SUM(fs.activity_count) AS total_activities,
    AVG(fs.session_duration) AS avg_duration_seconds
FROM gold.fact_session fs
GROUP BY fs.device_type
ORDER BY total_sessions DESC;
```

### Query 3: Hoạt động session theo tháng

```sql
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(DISTINCT fs.session_id) AS sessions,
    AVG(fs.activity_count) AS avg_activities,
    AVG(fs.page_view_count) AS avg_pages
FROM gold.fact_session fs
INNER JOIN gold.dim_date dd ON fs.session_date_key = dd.date_key
GROUP BY dd.year, dd.month, dd.month_name
ORDER BY dd.year DESC, dd.month DESC;
```

**Output:**
- ✅ Query 1: Top 10 provinces
- ✅ Query 2: Device distribution
- ✅ Query 3: Monthly trends

---

## TASK 4.4-4.8: Validation + Integration

### TASK 4.4: Verify FK Integrity
```sql
-- Check no orphan customers
SELECT COUNT(*) AS orphan_count
FROM gold.fact_session fs
LEFT JOIN gold.dim_customer dc ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;
-- Expected: 0

-- Check no orphan dates
SELECT COUNT(*) AS orphan_count
FROM gold.fact_session fs
LEFT JOIN gold.dim_date dd ON fs.session_date_key = dd.date_key
WHERE dd.date_key IS NULL;
-- Expected: 0
```

### TASK 4.5: Document SCD Type 2 Logic
File: `SCD_Type_2_Mapping_TV1.md` hoặc ghi chú:
- Input: stg_customers (update profile)
- Lookup: dim_customer (match customer_id WHERE is_current=1)
- Logic: If phone/city changes → Expire old (is_current=0, effective_to=today) + Insert new
- Multicast: Nhân đôi stream → OLE DB Command UPDATE + OLE DB Dest INSERT

### TASK 4.6-4.7: Prepare for Master Package
- ✅ Extract_Customers_Sessions.dtsx ready
- ✅ Load_Dim_Customers.dtsx ready
- ✅ Load_Fact_Session.dtsx ready
- Gửi 3 packages cho TV3 để integrate vào Master

### TASK 4.8: Verify all packages execute successfully
1. Run `Extract_Customers_Sessions.dtsx` → All green
2. Run `Load_Dim_Customers.dtsx` → All green
3. Run `Load_Fact_Session.dtsx` → All green

**Output:**
- ✅ 3 packages verified
- ✅ All data loaded correctly
- ✅ FK integrity checked
- ✅ Ready for Master Package integration

---

# ✅ FINAL CHECKLIST – TV1 COMPLETION

**Database & Setup:**
- [ ] Database ShopeeThailandDW created
- [ ] Schemas (staging, gold) created
- [ ] SSIS Project created with 3 packages
- [ ] Project Connection ShopeeThailandDW_OLEDB configured

**Staging Layer:**
- [ ] stg_customers: ~100K rows
- [ ] stg_session_activities: ~50K rows
- [ ] stg_reviews: ~80K rows

**Dimension Layer:**
- [ ] dim_date: 2191 rows (2020-2025)
- [ ] dim_location: ~77 rows
- [ ] dim_customer: ~100K rows (SCD Type 2)
- [ ] dim_device: 3 rows
- [ ] dim_page: 5 rows

**Fact Layer:**
- [ ] fact_session: ~50K rows

**ETL Packages:**
- [ ] Extract_Customers_Sessions.dtsx ✅ working
- [ ] Load_Dim_Customers.dtsx ✅ working (SCD Type 2)
- [ ] Load_Fact_Session.dtsx ✅ working

**Queries & Analytics:**
- [ ] Query 1: Top provinces ✓
- [ ] Query 2: Device distribution ✓
- [ ] Query 3: Monthly trends ✓

**Documentation:**
- [ ] SCD Type 2 mapping documented
- [ ] All step-by-step tasks completed

---

**READY FOR TV3 MASTER PACKAGE INTEGRATION!** 🎉

