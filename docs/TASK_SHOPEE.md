# 📋 TASK_SHOPEE.md – Phân công nhiệm vụ SSIS ETL Pipeline

**Dự án:** Data Warehouse – Shopee Thailand (Customer Journey & Operations)  
**Số thành viên:** 3  
**Công cụ:** SQL Server + SSIS  
**Thời gian:** 4 tuần  
**Database:** `ShopeeThailandDW`  
**CSV Location:** `/home/danhtran/hehe/Shopee/shopee_*_thailand.csv`

---

## Nguyên tắc phân công

- Mỗi thành viên tham gia đầy đủ: **Extract → Transform (Dimensions) → Load (Facts)**
- Phân chia theo **domain dữ liệu** (Customers, Products, Sellers)
- Công việc cân bằng: **32 tasks/person, 8 tasks/tuần**
- Merge tất cả packages vào **Master_ETL.dtsx** cuối cùng

---

## Tổng quan phân công

| Thành viên | Domain | Dimensions | Fact Tables |
|---|---|---|---|
| **TV1** | Khách hàng & Thời gian & Devices | dim_date, dim_location, dim_customer (Type 2), dim_device, dim_page | fact_session |
| **TV2** | Sản phẩm & Đơn hàng | dim_product, dim_product_category | fact_order (🔴 chính) |
| **TV3** | Người bán & Vận chuyển & Campaigns | dim_seller (Type 2), dim_campaign, dim_shipment | fact_order_lifecycle, fact_monthly_category_sales |

---

## Chi tiết nhiệm vụ

---

### 👤 **Thành viên 1 – Domain: Khách hàng, Thời gian & Devices**

#### **TUẦN 1: Chuẩn bị + Extract**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 1.1 | **[Chung TV1-TV2-TV3]** Tạo Database + Schemas | `CREATE DATABASE ShopeeThailandDW;` + `staging`, `gold` schemas | DB + 2 schemas |
| 1.2 | **[Chung TV1-TV2-TV3]** Tạo Project Connection | SSIS Project + `ShopeeThailandDW_OLEDB` project connection | SSIS ready |
| 1.3 | Tạo 3 staging tables | `stg_customers`, `stg_session_activities`, `stg_reviews` | 3 bảng staging |
| 1.4 | Create SSIS Package: Extract | Package `Extract_Customers_Sessions.dtsx` | Package template |
| 1.5 | Flat File Source: Customers CSV | Load `shopee_customers_thailand.csv` (10 cột) | FF connection |
| 1.6 | Data Flow 1: Customers → Staging | Map & load customers | ~100K rows stg_customers |
| 1.7 | Flat File Source: Session CSV | Load `shopee_session_activities_thailand.csv` | FF connection |
| 1.8 | Data Flow 2: Sessions → Staging | Map & load sessions | ~50K rows stg_sessions |

#### **TUẦN 2: Extract + Dimensions**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 2.1 | Flat File Source: Reviews CSV | Load `shopee_reviews_thailand.csv` | FF connection |
| 2.2 | Data Flow 3: Reviews → Staging | Map & load reviews, handle NULLs | ~80K rows stg_reviews |
| 2.3 | Test Extract Package | Chạy `Extract_Customers_Sessions.dtsx` F5 | ✅ All green |
| 2.4 | Create Dim Tables DDL | `dim_date`, `dim_location`, `dim_customer` | 3 bảng dim |
| 2.5 | Create Dim_Device & Dim_Page | Device types (Mobile/Desktop/Tablet), Page types (Cart/Checkout/etc) | 2 lookup tables |
| 2.6 | Create SSIS Package: Load Dimensions | Package `Load_Dim_Customers.dtsx` | Package template |
| 2.7 | EST - Populate dim_date | Script SQL: Generate calendar 2020-2025 (WITH CTE) | ~2,100 rows |
| 2.8 | EST - Populate dim_device & dim_page | Execute SQL tasks: INSERT 3 devices + 5 page types | 3+5 rows |

#### **TUẦN 3: Dimensions**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 3.1 | DFT - Load dim_location (SCD Type 1) | OLE DB Source → Lookup → Conditional Split → OLE DB Dest/Command | ~77 locations |
| 3.2 | DFT - Load dim_customer (SCD Type 2) | **Multicast logic**: Lookup → Expired old + Insert new version | ~100K customers |
| 3.3 | Test Load Dim Package | Chạy `Load_Dim_Customers.dtsx` | ✅ All dims loaded |
| 3.4 | Validate SCD Type 2 | Check effective_from/to, is_current = 1 cho tất cả | ✅ Correct |
| 3.5 | Create Fact_Session table DDL | PK: session_id, FKs: customer_key, date_key, device_key | DDL created |
| 3.6 | Create SSIS Package: Load Fact | Package `Load_Fact_Session.dtsx` | Package template |
| 3.7 | Data Flow: Load fact_session | JOIN stg_sessions + dims → OLE DB Dest | ~50K sessions |
| 3.8 | Test Fact Package | Chạy `Load_Fact_Session.dtsx` | ✅ fact_session loaded |

#### **TUẦN 4: Analytics + Integration**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 4.1 | Query 1: Top provinces by customers | SELECT province, COUNT(customer_key) ... GROUP BY ... ORDER BY | Insight |
| 4.2 | Query 2: Device type distribution | SELECT device_type, COUNT(session_id), AVG(session_duration) | Insight |
| 4.3 | Query 3: Session activity trends | SELECT date, SUM(activity_count), AVG(page_views) GROUP BY month | Insight |
| 4.4 | Verify FK Integrity | Kiểm tra: fact_session → dim_customer, dim_date, dim_device | ✅ No orphans |
| 4.5 | Document: SCD Type 2 Logic | Viết mapping: Customer changes (city, phone) → new version | Doc created |
| 4.6 | Prepare for Master Package | Output tất cả 3 packages ready | 3 packages ready |
| 4.7 | Code review: Guides + Queries | Verify guides đầy đủ & queries chạy | ✅ Ready |
| 4.8 | **[Chung]** Master Package Integration | Xem bước 4.8 của TV3 | Master ready |

**Deliverables TV1:**
- 3 staging tables + 5 dimension tables + 1 fact table
- 3 SSIS packages (Extract, Load Dims, Load Facts)
- 3 SQL queries (insights khách hàng)
- Tài liệu: SCD Type 2 mapping

---

### 👤 **Thành viên 2 – Domain: Sản phẩm & Đơn hàng (🔴 FACT CHÍNH)**

#### **TUẦN 1: Chuẩn bị + Extract**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 2.1 | **[Chung]** Tạo Database + Schemas | (TV1 làm, TV2 verify) | ✅ Ready |
| 2.2 | **[Chung]** Tạo Project Connection | (TV1 làm, TV2 use) | ✅ Ready |
| 2.3 | Tạo 3 staging tables | `stg_products`, `stg_order_items`, `stg_orders` | 3 bảng staging |
| 2.4 | Create SSIS Package: Extract | Package `Extract_Products_Orders.dtsx` | Package template |
| 2.5 | Flat File Source: Products CSV | Load `shopee_products_thailand.csv` (8 cột) | FF connection |
| 2.6 | Data Flow 1: Products → Staging | Map seller_id, category, weight, etc | ~33K rows |
| 2.7 | Flat File Source: Order Items CSV | Load `shopee_order_items_thailand.csv` (10 cột) | FF connection |
| 2.8 | Data Flow 2: Order Items → Staging | Map order_id, product_id, price, discount, commission | ~113K rows |

#### **TUẦN 2: Extract + Dimensions**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 2.9 | Flat File Source: Orders CSV | Load `shopee_orders_thailand.csv` (11 cột) | FF connection |
| 2.10 | Data Flow 3: Orders → Staging | Map order_date, customer_id, total_amount, campaign_id | ~100K rows |
| 2.11 | Test Extract Package | Chạy `Extract_Products_Orders.dtsx` | ✅ All green |
| 2.12 | Create Dim Tables DDL | `dim_product_category`, `dim_product` | 2 bảng dim |
| 2.13 | Create SSIS Package: Load Dimensions | Package `Load_Dim_Product.dtsx` | Package template |
| 2.14 | EST - Populate dim_product_category | Execute SQL: INSERT categories từ staging | ~71 categories |
| 2.15 | DFT - Load dim_product_category (SCD Type 1) | Lookup + Conditional Split → OLE DB Dest/Command | ~71 rows |
| 2.16 | DFT - Load dim_product (SCD Type 1) | JOIN stg_products + dim_category, Lookup, detect changes | ~33K products |

#### **TUẦN 3: Fact Table (CHÍNH)**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 3.1 | Create fact_order table DDL | **PK:** (order_id, order_item_id), **FKs:** customer, product, date, campaign | DDL created |
| 3.2 | Create SSIS Package: Load Fact | Package `Load_Fact_Order.dtsx` | Package template |
| 3.3 | **OLE DB Source Query** | JOIN stg_order_items + stg_orders + all dims (customer, product, date, campaign) | Query tested |
| 3.4 | **Incremental Load Logic** | WHERE NOT EXISTS (order_id, order_item_id) in fact_order | Logic built |
| 3.5 | **Data Flow: fact_order** | Lookups (customer, product, date, campaign) → OLE DB Dest (INSERT ONLY) | ~113K rows |
| 3.6 | Test Fact Package - Run 1 | Chạy `Load_Fact_Order.dtsx` lần 1 | ✅ 113K rows |
| 3.7 | Test Fact Package - Run 2 | Chạy lần 2 (Incremental - không insert lại) | ✅ 0 new rows |
| 3.8 | Validate Incremental Logic | Verify: chỉ INSERT new orders, không duplicate | ✅ Correct |

#### **TUẦN 4: Analytics + Integration**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 4.1 | Query 1: Top 10 sản phẩm bán chạy | SELECT product_name, COUNT(*), SUM(total_amount) ... ORDER BY revenue DESC | Insight |
| 4.2 | Query 2: Doanh thu theo tháng & danh mục | SELECT month, category, SUM(revenue) GROUP BY month, category | Insight |
| 4.3 | Query 3: Phân tích order value | SELECT AVG(total_amount), MIN, MAX, STDEV by customer/product | Insight |
| 4.4 | Verify FK Integrity | Check: fact_order → dim_customer, dim_product, dim_date, dim_campaign | ✅ No orphans |
| 4.5 | Document: Incremental Load Strategy | Viết mapping: CDC logic, NOT EXISTS query | Doc created |
| 4.6 | Prepare for Master Package | Output: Extract + Load_Dim + Load_Fact packages | 3 packages ready |
| 4.7 | Review: Guides đủ chi tiết? | Verify guides có step-by-step SSIS configuration | ✅ Ready |
| 4.8 | **[Chung]** Master Package Integration | Xem TV3 task 4.8 | Master ready |

**Deliverables TV2:**
- 3 staging tables + 2 dimension tables + 1 fact table (🔴 CENTRAL)
- 3 SSIS packages (Extract, Load Dims, Load Facts - Incremental)
- 3 SQL queries (insights doanh thu)
- Tài liệu: Incremental Load mapping

---

### 👤 **Thành viên 3 – Domain: Người bán, Vận chuyển & Campaigns**

#### **TUẦN 1: Chuẩn bị + Extract**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 3.1 | **[Chung]** Tạo Database + Schemas | (TV1 làm, TV3 verify) | ✅ Ready |
| 3.2 | **[Chung]** Tạo Project Connection | (TV1 làm, TV3 use) | ✅ Ready |
| 3.3 | Tạo 3 staging tables | `stg_sellers`, `stg_shipments`, `stg_campaigns` | 3 bảng staging |
| 3.4 | Create SSIS Package: Extract | Package `Extract_Sellers_Campaigns.dtsx` | Package template |
| 3.5 | Flat File Source: Sellers CSV | Load `shopee_sellers_thailand.csv` (7 cột) | FF connection |
| 3.6 | Data Flow 1: Sellers → Staging | Map seller_id, name, province, city, rating | ~3K rows |
| 3.7 | Flat File Source: Shipments CSV | Load `shopee_shipments_thailand.csv` (9 cột) | FF connection |
| 3.8 | Data Flow 2: Shipments → Staging | Map order_id, shipment_date, actual_date, method, is_on_time | ~100K rows |

#### **TUẦN 2: Extract + Dimensions**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 3.9 | Flat File Source: Campaigns CSV | Load `shopee_campaigns_thailand.csv` (7 cột) | FF connection |
| 3.10 | Data Flow 3: Campaigns → Staging | Map campaign_id, name, type, start_date, end_date, budget | ~20 campaigns |
| 3.11 | Test Extract Package | Chạy `Extract_Sellers_Campaigns.dtsx` | ✅ All green |
| 3.12 | Create Dim Tables DDL | `dim_seller` (SCD Type 2), `dim_campaign`, `dim_shipment` | 3 bảng dim |
| 3.13 | Create SSIS Package: Load Dimensions | Package `Load_Dim_Sellers_Campaign.dtsx` | Package template |
| 3.14 | EST - Populate dim_shipment | Execute SQL: INSERT shipment methods (5-6 methods) | ~6 rows |
| 3.15 | EST - Populate dim_campaign | Execute SQL: INSERT campaigns từ staging | ~20 campaigns |
| 3.16 | DFT - Load dim_seller (SCD Type 2) | Lookup location → Lookup seller → Multicast (Expire + Insert) | ~3K sellers |

#### **TUẦN 3: Fact Tables (2 bảng)**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 3.17 | Create fact_order_lifecycle DDL | **PK:** order_id, **Measures:** days_to_deliver, is_on_time, is_cancelled | DDL created |
| 3.18 | Create fact_monthly_sales DDL | **PK:** (date_key, category_key), **Measures:** total_orders, revenue, cancelled_rate | DDL created |
| 3.19 | Create SSIS Package: Load Facts | Package `Load_Fact_Lifecycle_Sales.dtsx` | Package template |
| 3.20 | Data Flow 1: fact_order_lifecycle (UPSERT) | JOIN stg_orders + stg_shipments → Lookup fact_lifecycle → Upsert (NEW + UPDATE) | ~100K rows |
| 3.21 | Test fact_lifecycle Package - Run 1 | Chạy lần 1 (INSERT all) | ✅ 100K inserted |
| 3.22 | Test fact_lifecycle Package - Run 2 | Chạy lần 2 (UPDATE thay đổi, không insert) | ✅ Updates processed |
| 3.23 | Data Flow 2: fact_monthly_sales (REBUILD) | TRUNCATE + GROUP BY month + category + SUM/COUNT/AVG | ~600 rows |
| 3.24 | Test Monthly Sales Package | Chạy rebuild monthly facts | ✅ Loaded |

#### **TUẦN 4: Master Package + Analytics**

| # | Nhiệm vụ | Chi tiết | Output |
|---|---|---|---|
| 4.1 | Query 1: Top sellers by revenue & on-time rate | SELECT seller_name, SUM(revenue), AVG(is_on_time) ... ORDER BY revenue DESC | Insight |
| 4.2 | Query 2: Campaign ROI analysis | SELECT campaign_name, orders, revenue, ROI (revenue/budget) | Insight |
| 4.3 | Query 3: Shipment performance by method | SELECT method, COUNT, on_time_rate, avg_days | Insight |
| 4.4 | Verify FK Integrity (Upsert) | Check: fact_lifecycle → dim_seller, dim_campaign, dim_shipment, dim_date | ✅ No orphans |
| 4.5 | Document: Upsert + SCD Type 2 Logic | Viết mapping: Multicast, Expire, Insert new version | Doc created |
| 4.6 | Create Master_ETL.dtsx | Orchestration package với 4 steps: Extract → Dims → fact_order → Aggregates | Master template |
| 4.7 | **STEP 1 in Master:** Extract (Song parallel) | 3 Execute Package Tasks (TV1, TV2, TV3 Extract packages) | Control Flow |
| 4.8 | **STEP 2 in Master:** Dimensions (Sequential) | 3 Execute Package Tasks (TV1, TV2, TV3 Load Dims) + Precedence constraints | Control Flow |
| 4.9 | **STEP 3 in Master:** Fact Order (Critical) | 1 Execute Package Task (TV2 Load_Fact_Order) - phụ thuộc STEP 2 | Control Flow |
| 4.10 | **STEP 4 in Master:** Aggregates (Parallel) | 2 Execute Package Tasks (TV1 Load_Fact_Session, TV3 Load_Lifecycle_Sales) | Control Flow |
| 4.11 | Test Master Package | Chạy toàn bộ Master_ETL.dtsx từ đầu đến cuối | ✅ All steps green |
| 4.12 | Final Validation | Verify: Tất cả tables populated, SCD/Incremental/Upsert logic đúng | ✅ Complete |

**Deliverables TV3:**
- 3 staging tables + 3 dimension tables + 2 fact tables
- 3 SSIS packages (Extract, Load Dims, Load Facts)
- 1 Master Package (orchestration)
- 3 SQL queries (insights vận hành)
- Tài liệu: Upsert + SCD Type 2 mapping

---

## Công việc chung (3 người cùng làm)

| # | Nhiệm vụ | Chính | Hỗ trợ |
|---|---|---|---|
| C1 | Tạo Database + Schemas | TV1 | TV2, TV3 verify |
| C2 | Tạo Project Connection SSIS | TV1 | TV2, TV3 use |
| C3 | Design Staging Tables (9 bảng) | Cả 3 | Mỗi người design 3 của mình |
| C4 | Design Dimension Tables (9 bảng) | Cả 3 | Cùng review, TV1 (date) first |
| C5 | Design Fact Tables (4 bảng) | Cả 3 | Cùng review schema |
| C6 | CSV Mapping + Data Profile | Cả 3 | Mỗi người 3 CSV của mình |
| C7 | Testing: Integration end-to-end | Cả 3 | Run Master Package, verify all |
| C8 | Documentation: Architecture | TV2 | TV1, TV3 contribute |
| C9 | Code Review: Packages | Cả 3 | Peer review trước Master |
| C10 | Final Sign-off | Cả 3 | Verify: ✅ All complete |

---

## Thứ tự thực thi trong Master Package

```
┌─────────────────────────────────────────┐
│ STEP 1: EXTRACT (Song parallel)         │
├──────────────┬──────────────┬───────────┤
│ TV1:         │ TV2:         │ TV3:      │
│ Extract_    │ Extract_    │ Extract_   │
│ Customers.. │ Products... │ Sellers..  │
└──────┬───────┴──────┬──────┴──┬────────┘
       │      All Success ──────┘
       │
┌──────▼────────────────────────────┐
│ STEP 2: LOAD DIMENSIONS           │
│ (Sequential → Precedence)         │
├────────────┬────────────┬─────────┤
│ TV1:       │ TV2:       │ TV3:    │
│ Load_Dim   │ Load_Dim   │ Load_Dim│
│ Cust (date │ Product    │ Seller  │
│ first)     │ (type 1)   │ (type 2)│
└────┬───────┴────┬──────┴───┬──────┘
     │ seq        │ seq      │ seq (depends TV1 location)
     ▼ Success    ▼ Success  ▼ Success
┌──────────────────────────────────┐
│ STEP 3: LOAD FACT_ORDER          │
│ (🔴 CRITICAL - Main fact)        │
│ TV2: Load_Fact_Order             │
│ Phụ thuộc: STEP 2 all complete   │
└──────┬───────────────────────────┘
       │
┌──────▼──────────────────────────────┐
│ STEP 4: LOAD AGGREGATES (Parallel) │
├──────────────┬──────────────────────┤
│ TV1:         │ TV3:                 │
│ Load_Fact_   │ Load_Fact_           │
│ Session      │ Lifecycle_Sales      │
└──────────────┴──────────────────────┘
       │
       ▼
   ✅ DONE!
```

---

## Tổng kết khối lượng công việc

| Hạng mục | TV1 | TV2 | TV3 | Tổng |
|---|---|---|---|---|
| **Staging tables** | 3 | 3 | 3 | 9 |
| **Dimension tables** | 5 | 2 | 3 | 10 |
| **Fact tables** | 1 | 1 | 2 | 4 |
| **SSIS Packages** | 3 | 3 | 3+1 Master | 10 |
| **Rows (Kỳ vọng)** | ~250K | ~250K | ~100K | ~600K |
| **SQL Queries** | 3 | 3 | 3 | 9 |
| **SCD Handling** | Type 2 (customer) | Type 1 (product) | Type 2 (seller) | - |
| **Load Strategy** | Rebuild | Incremental | Upsert + Rebuild | - |
| **Tasks/Week** | 8 | 8 | 8 | 24 |
| **Tasks Total** | 32 | 32 | 32 | 96 |

---

## Dependencies & Critical Path

```
Week 1: Extract
- TV1 Extract (done) ─┐
- TV2 Extract (done) ├─→ PARALLEL OK
- TV3 Extract (done) ─┘

Week 2-3: Dimensions
- TV1 dim_date ──→ (must first, for all date_keys)
- TV1 dim_location → (needed by TV3 for seller location)
- TV1 dim_customer (SCD Type 2)
- TV2 dim_product
- TV3 dim_seller (depends on dim_location from TV1)

Week 3-4: Facts
- TV2 fact_order (CENTRAL - needed by everyone)
  ├─ depends: all dims from TV1, TV2, TV3
  └─ needed for: TV1 session analytics, TV3 sales aggregates

- TV1 fact_session (can run once TV1 dims done)

- TV3 fact_lifecycle & sales (can run after fact_order)

Week 4: Master Integration
- STEP 1: 3 extracts (parallel)
- STEP 2: 3 dim loads (sequential)
- STEP 3: fact_order (after step 2)
- STEP 4: 2 aggregates (after step 3)
```

---

## Cân bằng công việc - Kiểm chứng

✅ **Tasks cân bằng:** Mỗi TV 32 tasks, 8/tuần  
✅ **Dimensions cân bằng:** TV1 (5) + TV2 (2) + TV3 (3) = 10 total  
✅ **Facts cân bằng:** TV1 (1) + TV2 (1) + TV3 (2) = 4 total  
✅ **Parallel work:** Extract week, dim loading week (mostly parallel)  
✅ **Dependency:** fact_order critical path, chỉ 1 nút thắt  
✅ **SCD/Loading:** Type 1 + Type 2 + Incremental + Upsert + Rebuild mix  
✅ **Everyone participates:** Extract → Transform → Load ✅

---

## Success Criteria (tuần 4)

- [ ] Tất cả 9 staging tables: ~600K rows
- [ ] Tất cả 10 dimensions: ~120K rows (dim_date + locations + customers + products + sellers + campaign + device + page + category + shipment)
- [ ] Tất cả 4 facts: ~200K rows (session + order + lifecycle + monthly_sales)
- [ ] SCD Type 2: customer & seller có effective_from/to, is_current đúng
- [ ] Incremental: fact_order chạy 2 lần, lần 2 không insert duplicate
- [ ] Upsert: fact_lifecycle chạy 2 lần, lần 2 update changes
- [ ] Master Package: 4 steps chạy xanh, không error
- [ ] 9 queries: tất cả chạy, trả về insights hợp lý
- [ ] Documentation: Guides + Queries + Mappings đầy đủ
- [ ] Zero orphan foreign keys

