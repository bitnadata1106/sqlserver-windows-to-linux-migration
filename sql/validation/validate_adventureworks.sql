/*****************************
validate_adventureworks
******************************/
-- [1] DB 확인
SELECT name
FROM sys.databases;
go

SELECT
    name AS database_name,
    state_desc,
    recovery_model_desc,
    compatibility_level
FROM sys.databases
WHERE name = 'AdventureWorks2014';
GO

-- [2] 스키마, 테이블, 뷰 개수
USE AdventureWorks2014;
GO

SELECT
    (SELECT COUNT(*) FROM sys.schemas WHERE schema_id < 16384) AS schema_count,
    (SELECT COUNT(*) FROM sys.tables) AS table_count,
    (SELECT COUNT(*) FROM sys.views) AS view_count,
    (SELECT COUNT(*) FROM sys.procedures) AS procedure_count;

-- [3] 주요 테이블별 행 개수

SELECT 'Sales.SalesOrderHeader' AS table_name, COUNT(*) AS row_count
FROM Sales.SalesOrderHeader

UNION ALL

SELECT 'Sales.SalesOrderDetail', COUNT(*)
FROM Sales.SalesOrderDetail

UNION ALL

SELECT 'Production.Product', COUNT(*)
FROM Production.Product

UNION ALL

SELECT 'Sales.SalesTerritory', COUNT(*)
FROM Sales.SalesTerritory

UNION ALL

SELECT 'Production.ProductCategory', COUNT(*)
FROM Production.ProductCategory

UNION ALL

SELECT 'Production.ProductSubcategory', COUNT(*)
FROM Production.ProductSubcategory;
go

-- [4]핵심판매 집계값 : 행 개수가 같더라도 금액 데이터가 달라질 수 있기 때문에, 핵심 비즈니스 수치도 비교
SELECT
    COUNT(DISTINCT SalesOrderID) AS order_count,
    COUNT(*) AS order_detail_count,
    SUM(OrderQty) AS total_order_quantity,
    CAST(SUM(LineTotal) AS DECIMAL(19, 2)) AS total_line_amount,
    CAST(AVG(LineTotal) AS DECIMAL(19, 2)) AS avg_line_amount
FROM Sales.SalesOrderDetail;

--주문헤더
SELECT
    COUNT(*) AS order_count,
    CAST(SUM(SubTotal) AS DECIMAL(19, 2)) AS total_subtotal,
    CAST(SUM(TaxAmt) AS DECIMAL(19, 2)) AS total_tax,
    CAST(SUM(Freight) AS DECIMAL(19, 2)) AS total_freight,
    CAST(SUM(TotalDue) AS DECIMAL(19, 2)) AS total_due
FROM Sales.SalesOrderHeader;

-- [5] 날짜범위: 특정 시기의 데이터가 통째로 누락되거나 잘렸는지 빠르게 파악
SELECT
    MIN(OrderDate) AS min_order_date,
    MAX(OrderDate) AS max_order_date,
    MIN(DueDate) AS min_due_date,
    MAX(DueDate) AS max_due_date,
    MIN(ShipDate) AS min_ship_date,
    MAX(ShipDate) AS max_ship_date
FROM Sales.SalesOrderHeader;

-- [6] 필수 컬럼 NULL 검사: 업무상 반드시 값이 있어야 하는 컬럼만

SELECT
    SUM(CASE WHEN SalesOrderID IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS null_territory_id
FROM Sales.SalesOrderHeader;

-- [7] 기본키 중복 검사 : 정상 결과는 0행
-- 주문 헤더
SELECT
    SalesOrderID,
    COUNT(*) AS duplicate_count
FROM Sales.SalesOrderHeader
GROUP BY SalesOrderID
HAVING COUNT(*) > 1;

-- 주문 상세 복합키
SELECT
    SalesOrderID,
    SalesOrderDetailID,
    COUNT(*) AS duplicate_count
FROM Sales.SalesOrderDetail
GROUP BY
    SalesOrderID,
    SalesOrderDetailID
HAVING COUNT(*) > 1;

-- [8] 관계 무결성, 고아 데이터 검사 : 정상 결과는 0행
-- 주문 상세에는 존재하지만 주문 헤더에는 없는 데이터:
SELECT COUNT(*) AS orphan_order_detail_count
FROM Sales.SalesOrderDetail AS d
LEFT JOIN Sales.SalesOrderHeader AS h
    ON d.SalesOrderID = h.SalesOrderID
WHERE h.SalesOrderID IS NULL;

--주문 상세에는 있지만 제품 테이블에는 없는 제품
SELECT COUNT(*) AS orphan_product_count
FROM Sales.SalesOrderDetail AS d
LEFT JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
WHERE p.ProductID IS NULL;