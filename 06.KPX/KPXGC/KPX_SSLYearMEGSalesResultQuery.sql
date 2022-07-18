
IF OBJECT_ID('KPX_SSLYearMEGSalesResultQuery') IS NOT NULL   
    DROP PROC KPX_SSLYearMEGSalesResultQuery  
GO  

-- v2014.12.24  

-- 월(년) MEG위탁판매 실적-조회 by 이재천   
CREATE PROC KPX_SSLYearMEGSalesResultQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYear    NCHAR(4) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear   = ISNULL( StdYear, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYear   NCHAR(4))    
    
    CREATE TABLE #BaseData_Sub
    (
        SMExpKind   INT, 
        SalesYM     NCHAR(6), 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        Price       DECIMAL(19,5) 
    ) 
    CREATE TABLE #BaseData 
    (
        SMExpKind   INT, 
        SalesYM     NCHAR(6), 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        Price       DECIMAL(19,5) 
    ) 
    INSERT INTO #BaseData_Sub ( SMExpKind, SalesYM, Qty, Amt, Price ) 
    SELECT CASE WHEN A.SMExpKind = 8009001 THEN 1 
                WHEN A.SMExpKind IN (8009002, 8009003) THEN 2
                ELSE 3 
                END, 
           LEFT(A.SalesDate,6), 
           FLOOR(SUM(B.Qty) / 1000) , 
           FLOOR(SUM(B.DomAmt) / 1000), 
           FLOOR(AVG(B.Price) / 1000) 
      FROM _TSLSales                    AS A 
      JOIN _TSLSalesItem                AS B ON ( B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS C ON ( C.ItemSeq = B.ItemSeq ) 
                 JOIN _TDAUMinorValue        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ItemClassLSeq AND D.Serl = 1000002 AND D.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(C.ItemClassLSeq,4) = 2003 
       AND LEFT(A.SalesDate,4) = @StdYear 
     GROUP BY LEFT(A.SalesDate,6),
              CASE WHEN A.SMExpKind = 8009001 THEN 1 
                WHEN A.SMExpKind IN (8009002, 8009003) THEN 2
                ELSE 3 
                END
    
    -- 내수, Local, 수출 
    INSERT INTO #BaseData 
    SELECT * FROM #BaseData_Sub
    
    -- 합계 
    INSERT INTO #BaseData 
    SELECT 4, SalesYM, SUM(Qty), SUM(Amt), AVG(Price) 
      FROM #BaseData_Sub 
     GROUP BY SalesYM 
    
    CREATE TABLE #Result_Sub 
    (
        KindSeq         INT, 
        KindName        NVARCHAR(100), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5), 
        Price           DECIMAL(19,5), 
        LQty            DECIMAL(19,5), 
        LAmt            DECIMAL(19,5), 
        LPrice          DECIMAL(19,5), 
        ExpQty          DECIMAL(19,5), 
        ExpAmt          DECIMAL(19,5), 
        ExpPrice        DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5), 
        SumPrice        DECIMAL(19,5)
    )
    CREATE TABLE #Result 
    (
        KindSeq         INT, 
        KindName        NVARCHAR(100), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5), 
        Price           DECIMAL(19,5), 
        LQty            DECIMAL(19,5), 
        LAmt            DECIMAL(19,5), 
        LPrice          DECIMAL(19,5), 
        ExpQty          DECIMAL(19,5), 
        ExpAmt          DECIMAL(19,5), 
        ExpPrice        DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5), 
        SumPrice        DECIMAL(19,5)
    )
    
    INSERT INTO #Result_Sub 
    ( 
        KindSeq, KindName, Qty, Amt, Price, 
        LQty, LAmt, LPrice, ExpQty, ExpAmt, 
        ExpPrice, SumQty, SumAmt, SumPrice 
    ) 
    SELECT A.SalesYM AS KindSeq , 
           CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(A.SalesYM,2))) + '월' AS KindName, 
           B.Qty, 
           B.Amt, 
           B.Price, 
           C.LQty, 
           C.LAmt, 
           C.LPrice, 
           D.ExpQty, 
           D.ExpAmt, 
           D.ExpPrice, 
           E.SumQty,
           E.SumAmt, 
           E.SumPrice 
      FROM (SELECT DISTINCT SalesYM FROM #BaseData)AS A 
      OUTER APPLY (SELECT Z.SalesYM, Z.Qty AS Qty, Z.Amt AS Amt, Z.Price AS Price
                     FROM #BaseData AS Z 
                    WHERE Z.SMExpKind = 1 
                      AND Z.SalesYM = A.SalesYM 
                  ) AS B 
      OUTER APPLY (SELECT Z.SalesYM, Z.Qty AS LQty, Z.Amt AS LAmt, Z.Price AS LPrice
                     FROM #BaseData AS Z 
                    WHERE Z.SMExpKind = 2 
                      AND Z.SalesYM = A.SalesYM 
                  ) AS C 
      OUTER APPLY (SELECT Z.SalesYM, Z.Qty AS ExpQty, Z.Amt AS ExpAmt, Z.Price AS ExpPrice
                     FROM #BaseData AS Z 
                    WHERE Z.SMExpKind = 3 
                      AND Z.SalesYM = A.SalesYM 
                  ) AS D 
      OUTER APPLY (SELECT Z.SalesYM, Z.Qty AS SumQty, Z.Amt AS SumAmt, Z.Price AS SumPrice
                     FROM #BaseData AS Z 
                    WHERE Z.SMExpKind = 4 
                      AND Z.SalesYM = A.SalesYM 
                  ) AS E 
    
    INSERT INTO #Result 
    SELECT * FROM #Result_Sub 
    
    
    INSERT INTO #Result 
    SELECT 999998, '합계', SUM(Qty), SUM(Amt), AVG(Price), 
           SUM(LQty), SUM(LAmt), AVG(LPrice), SUM(ExpQty), SUM(ExpAmt), 
           AVG(ExpPrice), SUM(SumQty), SUM(SumAmt), AVG(SumPrice) 
      FROM #Result_Sub 
    
    INSERT INTO #Result 
    SELECT 999999, '평균', AVG(Qty), AVG(Amt), AVG(Price), 
           AVG(LQty), AVG(LAmt), AVG(LPrice), AVG(ExpQty), AVG(ExpAmt), 
           AVG(ExpPrice), AVG(SumQty), AVG(SumAmt), AVG(SumPrice) 
      FROM #Result_Sub 
    
    SELECT * FROM #Result ORDER BY KindSeq 
    
    
    RETURN  
GO 
exec KPX_SSLYearMEGSalesResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYear>2013</StdYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027085,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021256