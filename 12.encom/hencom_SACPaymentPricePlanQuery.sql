 
IF OBJECT_ID('hencom_SACPaymentPricePlanQuery') IS NOT NULL   
    DROP PROC hencom_SACPaymentPricePlanQuery  
GO  
  
-- v2017.06.02
  
-- 정기분대금지급계획-조회 by 이재천
CREATE PROC hencom_SACPaymentPricePlanQuery  
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
            @StdDate    NCHAR(8), 
            @SlipUnit   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate   = ISNULL( StdDate, '' ), 
           @SlipUnit  = ISNULL( SlipUnit, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate     NCHAR(8),
            SlipUnit    INT 
           )    
    
    -- 기준 된 사업소 
    CREATE TABLE #SlipUnit  
    (
        SlipUnit    INT, 
        MinorSort   INT 
    )

    INSERT INTO #SlipUnit ( SlipUnit, MinorSort ) 
    SELECT B.ValueSeq, A.MinorSort
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015263 
       AND C.ValueText = '1' 
       AND A.IsUse = '1' 
    
    
    -- 기준일의 데이터 
    SELECT * 
      INTO #hencom_TACPaymentPricePlan 
      FROM hencom_TACPaymentPricePlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate = @StdDate 
    
    
    -- 최종 조회 
    SELECT A.SlipUnit, 
           C.SlipUnitName, 
           ISNULL(B.MatAmt1,0) AS MatAmt1, 
           ISNULL(B.MatAmt2,0) AS MatAmt2, 
           ISNULL(B.MatAmt3,0) AS MatAmt3, 
           ISNULL(B.MatAmt4,0) AS MatAmt4, 
           ISNULL(B.MatAmt1,0) + ISNULL(B.MatAmt2,0) + ISNULL(B.MatAmt3,0) + ISNULL(B.MatAmt4,0) AS SumMatAmt, 

           ISNULL(B.GoodsAmt1,0) AS GoodsAmt1, 
           ISNULL(B.GoodsAmt3,0) AS GoodsAmt3, 
           ISNULL(B.GoodsAmt4,0) AS GoodsAmt4, 
           ISNULL(B.GoodsAmt1,0) + ISNULL(B.GoodsAmt3,0) + ISNULL(B.GoodsAmt4,0) AS SumGoodsAmt, 

           ISNULL(B.ReAmt1,0) AS ReAmt1, 
           ISNULL(B.ReAmt2,0) AS ReAmt2, 
           ISNULL(B.ReAmt1,0) + ISNULL(B.ReAmt2,0) AS SumReAmt, 

           ISNULL(B.EtcAmt1,0) AS EtcAmt1, 
           ISNULL(B.EtcAmt1,0) AS SumEtcAmt, 

           ISNULL(B.MatAmt1,0) + ISNULL(B.MatAmt2,0) + ISNULL(B.MatAmt3,0) + ISNULL(B.MatAmt4,0) + 
           ISNULL(B.GoodsAmt1,0) + ISNULL(B.GoodsAmt3,0) + ISNULL(B.GoodsAmt4,0) + 
           ISNULL(B.ReAmt1,0) + ISNULL(B.ReAmt2,0) + 
           ISNULL(B.EtcAmt1,0) AS SumAmt,  

           B.Remark, 
           A.MinorSort, 
           CASE WHEN B.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsSave
      INTO #Result 
      FROM #SlipUnit                                AS A 
      LEFT OUTER JOIN #hencom_TACPaymentPricePlan   AS B ON ( B.SlipUnit = A.SlipUnit ) 
      LEFT OUTER JOIN _TACSlipUnit                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
      WHERE (@SlipUnit = 0 OR A.SlipUnit = @SlipUnit) 
    

    IF EXISTS (SELECT 1 FROM #Result) 
    BEGIN 
        INSERT INTO #Result 
        SELECT 99999 AS SlipUnit, 
               'TOTAL' AS SlipUnitName, 
               SUM(A.MatAmt1) AS MatAmt1, 
               SUM(A.MatAmt2) AS MatAmt2, 
               SUM(A.MatAmt3) AS MatAmt3, 
               SUM(A.MatAmt4) AS MatAmt4, 
               SUM(A.SumMatAmt) AS SumMatAmt, 

               SUM(A.GoodsAmt1) AS GoodsAmt1, 
               SUM(A.GoodsAmt3) AS GoodsAmt3, 
               SUM(A.GoodsAmt4) AS GoodsAmt4, 
               SUM(A.SumGoodsAmt) AS SumGoodsAmt, 

               SUM(A.ReAmt1) AS ReAmt1, 
               SUM(A.ReAmt2) AS ReAmt2, 
               SUM(A.SumReAmt) AS SumReAmt, 

               SUM(A.EtcAmt1) AS EtcAmt1, 
               SUM(A.SumEtcAmt) AS SumEtcAmt, 

               SUM(A.SumAmt) AS SumAmt, 

               '' AS Remark, 
               0 AS MinorSort, 
               '' AS IsSave 
          FROM #Result AS A 
    END 
    
    SELECT * FROM #Result ORDER BY MinorSort 

    
    RETURN  
GO
exec hencom_SACPaymentPricePlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate>20170706</StdDate>
    <SlipUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512352,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033717