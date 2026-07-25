USE AdventureWorks2014;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'mart'
)
BEGIN
    EXEC('CREATE SCHEMA mart');
END;
GO

CREATE OR ALTER VIEW mart.vw_monthly_sales
AS
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS sales_month,
    COUNT(*) AS order_count,
    CAST(SUM(SubTotal) AS DECIMAL(19, 4)) AS subtotal_amount,
    CAST(SUM(TaxAmt) AS DECIMAL(19, 4)) AS tax_amount,
    CAST(SUM(Freight) AS DECIMAL(19, 4)) AS freight_amount,
    CAST(SUM(TotalDue) AS DECIMAL(19, 4)) AS total_sales_amount
FROM Sales.SalesOrderHeader
GROUP BY
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1);
GO
