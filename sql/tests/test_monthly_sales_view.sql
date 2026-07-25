USE ADVENTUREWORKS2014;
GO

IF OBJECT_ID('mart.vw_monthly_sales', 'V') IS NULL
    THROW 51000, 'FAIL: mart.vw_monthly_sales does not exist.', 1;
GO

IF
    EXISTS (
        SELECT 1
        FROM MART.VW_MONTHLY_SALES
        WHERE
            SALES_MONTH IS NULL
            OR ORDER_COUNT <= 0
            OR TOTAL_SALES_AMOUNT IS NULL
    )
    THROW 51001, 'FAIL: Invalid monthly sales data detected.', 1;
GO

IF (
    SELECT CAST(SUM(TOTAL_SALES_AMOUNT) AS DECIMAL(19, 4))
    FROM MART.VW_MONTHLY_SALES
) <> (
    SELECT CAST(SUM(TOTALDUE) AS DECIMAL(19, 4))
    FROM SALES.SALESORDERHEADER
)
    THROW 51002, 'FAIL: Mart total does not match source total.', 1;
GO

PRINT 'PASS: Monthly sales mart validation completed.';
GO
