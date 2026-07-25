/*****************************
validate_adventureworks
******************************/
-- [1] DB 확인
SELECT name
FROM sys.databases;
GO

SELECT
    name AS database_name,
    state_desc,
    recovery_model_desc,
    compatibility_level
FROM sys.databases
WHERE name = 'AdventureWorks2014';
GO

-- [2] 스키마, 테이블, 뷰 개수
USE adventureworks2014;
GO

SELECT
    (
        SELECT COUNT(*) FROM sys.schemas
        WHERE schema_id < 16384
    ) AS schema_count,
    (SELECT COUNT(*) FROM sys.tables) AS table_count,
    (SELECT COUNT(*) FROM sys.views) AS view_count,
    (SELECT COUNT(*) FROM sys.procedures) AS procedure_count;

-- [3] 주요 테이블별 행 개수

SELECT
    'Sales.SalesOrderHeader' AS table_name,
    COUNT(*) AS row_count
FROM sales.salesorderheader

UNION ALL

SELECT
    'Sales.SalesOrderDetail',
    COUNT(*)
FROM sales.salesorderdetail

UNION ALL

SELECT
    'Production.Product',
    COUNT(*)
FROM production.product

UNION ALL

SELECT
    'Sales.SalesTerritory',
    COUNT(*)
FROM sales.salesterritory

UNION ALL

SELECT
    'Production.ProductCategory',
    COUNT(*)
FROM production.productcategory

UNION ALL

SELECT
    'Production.ProductSubcategory',
    COUNT(*)
FROM production.productsubcategory;
GO

-- [4]핵심판매 집계값 : 행 개수가 같더라도 금액 데이터가 달라질 수 있기 때문에, 핵심 비즈니스 수치도 비교
SELECT
    CAST(SUM(linetotal) AS DECIMAL(19, 2)) AS total_line_amount,
    CAST(AVG(linetotal) AS DECIMAL(19, 2)) AS avg_line_amount,
    COUNT(DISTINCT salesorderid) AS order_count,
    COUNT(*) AS order_detail_count,
    SUM(orderqty) AS total_order_quantity
FROM sales.salesorderdetail;

--주문헤더
SELECT
    CAST(SUM(subtotal) AS DECIMAL(19, 2)) AS total_subtotal,
    CAST(SUM(taxamt) AS DECIMAL(19, 2)) AS total_tax,
    CAST(SUM(freight) AS DECIMAL(19, 2)) AS total_freight,
    CAST(SUM(totaldue) AS DECIMAL(19, 2)) AS total_due,
    COUNT(*) AS order_count
FROM sales.salesorderheader;

-- [5] 날짜범위: 특정 시기의 데이터가 통째로 누락되거나 잘렸는지 빠르게 파악
SELECT
    MIN(orderdate) AS min_order_date,
    MAX(orderdate) AS max_order_date,
    MIN(duedate) AS min_due_date,
    MAX(duedate) AS max_due_date,
    MIN(shipdate) AS min_ship_date,
    MAX(shipdate) AS max_ship_date
FROM sales.salesorderheader;

-- [6] 필수 컬럼 NULL 검사: 업무상 반드시 값이 있어야 하는 컬럼만

SELECT
    SUM(CASE WHEN salesorderid IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN orderdate IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN customerid IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN territoryid IS NULL THEN 1 ELSE 0 END) AS null_territory_id
FROM sales.salesorderheader;

-- [7] 기본키 중복 검사 : 정상 결과는 0행
-- 주문 헤더
SELECT
    salesorderid,
    COUNT(*) AS duplicate_count
FROM sales.salesorderheader
GROUP BY salesorderid
HAVING COUNT(*) > 1;

-- 주문 상세 복합키
SELECT
    salesorderid,
    salesorderdetailid,
    COUNT(*) AS duplicate_count
FROM sales.salesorderdetail
GROUP BY
    salesorderid,
    salesorderdetailid
HAVING COUNT(*) > 1;

-- [8] 관계 무결성, 고아 데이터 검사 : 정상 결과는 0행
-- 주문 상세에는 존재하지만 주문 헤더에는 없는 데이터:
SELECT COUNT(*) AS orphan_order_detail_count
FROM sales.salesorderdetail AS d
LEFT JOIN sales.salesorderheader AS h
    ON d.salesorderid = h.salesorderid
WHERE h.salesorderid IS NULL;

--주문 상세에는 있지만 제품 테이블에는 없는 제품
SELECT COUNT(*) AS orphan_product_count
FROM sales.salesorderdetail AS d
LEFT JOIN production.product AS p
    ON d.productid = p.productid
WHERE p.productid IS NULL;
