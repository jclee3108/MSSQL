  
IF OBJECT_ID('KPX_SPUMonthlyDelvGapListQuery') IS NOT NULL   
    DROP PROC KPX_SPUMonthlyDelvGapListQuery  
GO  
  
-- v2014.12.16  
  
-- 전년동월대비 구매실적-조회 by 이재천   
CREATE PROC KPX_SPUMonthlyDelvGapListQuery  
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
            @StdYM      NCHAR(6), 
            @BizUnit    INT, 
            @SMABC      INT, 
            @StdYM2     NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL(StdYM, '' ),  
           @BizUnit = ISNULL(BizUnit, 0 ), 
           @SMABC   = ISNULL(SMABC, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYM      NCHAR(6), 
            BizUnit    INT, 
            SMABC      INT     
           )
    
    SELECT @StdYM2 = (SELECT CONVERT(NCHAR(6),DATEADD(YEAR, -1, @StdYM + '01'),112)) 
    
    CREATE TABLE #BaseData 
    (
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        StdYM       NCHAR(6) 
    ) 
    
    INSERT INTO #BaseData ( ItemSeq, Qty, Amt, StdYM ) 
    SELECT B.ItemSeq, SUM(B.Qty), SUM(B.CurAmt), LEFT(A.DelvInDate,6)
      FROM _TPUDelvIn AS A 
      LEFT OUTER JOIN _TPUDelvInItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
                 JOIN _TDAItem       AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.SMABC = @SMABC AND C.AssetSeq = 4 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( LEFT(A.DelvInDate,6) IN ( @StdYM, @StdYM2 ) ) 
     GROUP BY B.ItemSeq, LEFT(A.DelvInDate,6)
     
    SELECT A.ItemSeq, 
           C.ItemName, 
           C.ItemNo, 
           ISNULL(A.Qty,0) AS Qty1, 
           ISNULL(A.Amt,0) AS Amt1, 
           ISNULL(B.Qty,0) AS Qty2, 
           ISNULL(B.Amt,0) AS Amt2, 
           
           CASE WHEN ISNULL(B.Amt,0) = 0 THEN 0 ELSE (ISNULL(A.Amt,0) / ISNULL(B.Amt,0)) * 100 END AS AmtRate
           
      FROM #BaseData AS A 
      OUTER APPLY ( SELECT Qty, Amt
                      FROM #BaseData AS Z 
                     WHERE Z.ItemSEq = A.ItemSeq 
                       AND Z.StdYM = @StdYM2
                  ) AS B 
      LEFT OUTER JOIN _TDAItem AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.StdYM = @StdYM 
    
    RETURN  
GO 
exec KPX_SPUMonthlyDelvGapListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201410</StdYM>
    <BizUnit />
    <SMABC>2002001</SMABC>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026839,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020596