# ĐỒ ÁN KHO DỮ LIỆU (DATA WAREHOUSE)
**Đề tài:** Xây dựng hệ thống phân tích hành trình khách hàng và vận hành Shopee Thái Lan
**Công nghệ sử dụng:** SQL Server, SSIS (Integration Services)
**Dataset:** Shopee TH Customer Journey and Operations (Kaggle)

---

## 1. MÔ HÌNH KIẾN TRÚC DỮ LIỆU
Hệ thống được thiết kế theo mô hình **Star Schema** (Sơ đồ hình sao) nhằm tối ưu hóa hiệu suất truy vấn phân tích và đảm bảo tính mạch lạc trong cấu trúc báo cáo.

### Quy trình ETL (Extract - Transform - Load):
1. **Source Layer:** Các file CSV gốc từ Kaggle.
2. **Staging Layer:** Dữ liệu thô được nạp vào SQL Server (không biến đổi) để giảm thiểu độ trễ truy cập nguồn.
3. **DWH Layer:** Dữ liệu được làm sạch, chuẩn hóa và nạp vào các bảng Dimension/Fact thông qua SSIS.

---

## 2. THIẾT KẾ BẢNG DIMENSION (DIMENSION TABLES)

Để đáp ứng tiêu chí **SCD (Slowly Changing Dimension)** của Rubric, nhóm áp dụng Type 2 cho các bảng cần theo dõi lịch sử.

| Tên bảng | Loại SCD | Phân cấp (Hierarchy) / Thuộc tính | Ý nghĩa nghiệp vụ |
| :--- | :--- | :--- | :--- |
| **Dim_Date** | Static | Year > Quarter > Month > Day | Chứa thông tin lễ tết Thái Lan, cuối tuần. |
| **Dim_Location** | Static | Region > Province | Phân vùng địa lý 6 vùng chính của Thái Lan. |
| **Dim_Customer** | **Type 2** | SK, Customer_ID, FullName, Province_Key | Theo dõi thay đổi địa chỉ khách hàng. |
| **Dim_Seller** | **Type 2** | SK, Seller_ID, Shop_Name, Rating, Province_Key | Theo dõi lịch sử Rating và loại Seller. |
| **Dim_Product** | Type 1 | Product_Key, Name, Brand, Category_L3 | Thông tin sản phẩm và phân loại. |
| **Dim_Campaign** | Type 1 | Campaign_Key, Name, Type, Budget | Thông tin các chương trình Marketing. |
| **Dim_Shipment** | Static | Method_Name, Estimated_Days | Các phương thức vận chuyển (Shopee Express, Kerry...). |
| **Dim_Device** | Static | Device_Type (Mobile, Desktop, Tablet) | Thiết bị truy cập. |
| **Dim_Page** | Static | Page_URL, Page_Type (Cart, Checkout...) | Các điểm chạm trong hành trình khách hàng. |

---

## 3. THIẾT KẾ BẢNG FACT (FACT TABLES)

Nhóm triển khai đầy đủ 3 loại Fact để chứng minh kỹ năng thiết kế Kho dữ liệu mức độ cao.

### 3.1. Fact_Order (Transaction Fact)
* **Grain:** Một dòng tương ứng với một chi tiết sản phẩm trong đơn hàng.
* **Measures:** `Quantity`, `Unit_Price`, `Line_Total`, `Shipping_Fee`, `Discount_Amount`, `Commission_Amount`, `Net_Amount`.
* **FK:** `Order_ID`, `User_SK`, `Seller_SK`, `Product_Key`, `Date_Key`, `Campaign_Key`.

### 3.2. Fact_Order_Lifecycle (Accumulating Snapshot Fact)
* **Grain:** Một dòng tương ứng với toàn bộ vòng đời của một đơn hàng.
* **Mục tiêu:** Theo dõi hiệu quả vận hành (Operations).
* **Measures:** `Order_Date`, `Payment_Date`, `Ship_Date`, `Delivery_Date`, `Total_Days_To_Deliver`, `Is_Delayed`, `Is_Cancelled`.

### 3.3. Fact_Monthly_Category_Sales (Periodic Snapshot Fact)
* **Grain:** Thống kê tổng hợp theo từng Tháng và từng Danh mục sản phẩm.
* **Measures:** `Total_Revenue`, `Total_Orders`, `Total_Items_Sold`, `Total_Cancelled_Rate`.

### 3.4. Fact_Session (Transaction Fact)
* **Grain:** Một dòng tương ứng với một phiên truy cập người dùng.
* **Measures:** `Session_Duration`, `Activity_Count`, `Page_View_Count`.

---

## 4. CHIẾN LƯỢC TRIỂN KHAI ETL (SSIS)

Để đạt điểm A (9-10), pipeline ETL được thiết kế với các kỹ thuật sau:

* **Surrogate Key (SK):** Sử dụng khóa thay thế tự tăng (Identity) thay vì khóa tự nhiên để độc lập dữ liệu DWH với hệ thống nguồn.
* **Incremental Load (CDC):** Sử dụng cơ chế biến `LastETLRun` để chỉ nạp những dữ liệu mới phát sinh hoặc có thay đổi từ Stage vào DWH.
* **Lookup Transformation:** Sử dụng bộ nhớ đệm (Cache) để ánh xạ Business Key sang Surrogate Key một cách tối ưu nhất.
* **SCD Type 2 Logic:** Kết hợp `Lookup` và `Derived Column` trong SSIS để phát hiện thay đổi thuộc tính, đóng bản ghi cũ (`Valid_To`) và chèn bản ghi mới.

---

## 5. CÂU HỎI PHÂN TÍCH KINH DOANH (INSIGHTS)

1. **Vận hành:** Tỉnh thành nào có tỷ lệ đơn hàng bị giao trễ (`Is_Delayed`) cao nhất theo từng đơn vị vận chuyển?
2. **Marketing:** Chiến dịch (`Campaign`) nào mang lại doanh thu thuần (`Net_Amount`) lớn nhất trên mỗi thiết bị di động?
3. **Hành trình khách hàng:** Trang (`Page_Type`) nào có tỷ lệ thoát cao nhất khiến khách hàng không hoàn tất thanh toán?
4. **Tăng trưởng:** Xu hướng doanh thu của ngành hàng Electronics so với Fashion qua các tháng trong năm 2024.
