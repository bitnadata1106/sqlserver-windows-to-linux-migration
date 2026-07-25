USE AdventureWorks2014;
GO

IF OBJECT_ID('mart.vw_monthly_sales', 'V') IS NULL
    THROW 51000, 'FAIL: mart.vw_monthly_sales does not exist.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM mart.vw_monthly_sales
    WHERE sales_month IS NULL
       OR order_count <= 0
       OR total_sales_amount IS NULL
)
    THROW 51001, 'FAIL: Invalid monthly sales data detected.', 1;
GO

IF (
    SELECT CAST(SUM(total_sales_amount) AS DECIMAL(19, 4))
    FROM mart.vw_monthly_sales
) <> (
    SELECT CAST(SUM(TotalDue) AS DECIMAL(19, 4))
    FROM Sales.SalesOrderHeader
)
    THROW 51002, 'FAIL: Mart total does not match source total.', 1;
GO

PRINT 'PASS: Monthly sales mart validation completed.';
GO