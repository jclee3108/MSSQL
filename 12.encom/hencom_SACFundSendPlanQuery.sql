 
IF OBJECT_ID('hencom_SACFundSendPlanQuery') IS NOT NULL   
    DROP PROC hencom_SACFundSendPlanQuery  
GO  
  
-- v2017.06.02
  
-- 정기분대금지급계획-조회 by 이재천
CREATE PROC hencom_SACFundSendPlanQuery  
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
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000003 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015263 
       AND C.ValueText = '1' 
       AND A.IsUse = '1' 
    
    
    -- 기준일의 데이터 
    SELECT * 
      INTO #hencom_TACFundSendPlan 
      FROM hencom_TACFundSendPlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate = @StdDate 
    
    
    -- 최종 조회 
    SELECT A.SlipUnit, 
           C.SlipUnitName, 
           ISNULL(B.InSendAmt,0) AS InSendAmt, 

           ISNULL(B.SendAmt1,0) AS SendAmt1, 
           ISNULL(B.SendAmt2,0) AS SendAmt2, 
           ISNULL(B.SendAmt3,0) AS SendAmt3, 
           ISNULL(B.SendAmt4,0) AS SendAmt4, 
           ISNULL(B.SendAmt5,0) AS SendAmt5, 
           ISNULL(B.SendAmt6,0) AS SendAmt6, 
           ISNULL(B.SendAmt7,0) AS SendAmt7, 
           ISNULL(B.SendAmt8,0) AS SendAmt8, 

           ISNULL(B.InSendAmt,0) + ISNULL(B.SendAmt1,0) + ISNULL(B.SendAmt2,0) + ISNULL(B.SendAmt3,0) + ISNULL(B.SendAmt4,0) + 
           ISNULL(B.SendAmt5,0) + ISNULL(B.SendAmt6,0) + ISNULL(B.SendAmt7,0) + ISNULL(B.SendAmt8,0) AS TotSendAmt, 

           ISNULL(B.AccSendAmt,0) AS AccSendAmt, 

           ISNULL(B.InSendAmt,0) + 
           ISNULL(B.SendAmt1,0) + ISNULL(B.SendAmt2,0) + ISNULL(B.SendAmt3,0) + ISNULL(B.SendAmt4,0) + 
           ISNULL(B.SendAmt5,0) + ISNULL(B.SendAmt6,0) + ISNULL(B.SendAmt7,0) + ISNULL(B.SendAmt8,0) + 
           ISNULL(B.AccSendAmt,0) AS SumAmt, 

           B.Remark, 
           A.MinorSort, 
           CASE WHEN B.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsSave
      INTO #Result 
      FROM #SlipUnit                                AS A 
      LEFT OUTER JOIN #hencom_TACFundSendPlan   AS B ON ( B.SlipUnit = A.SlipUnit ) 
      LEFT OUTER JOIN _TACSlipUnit                  AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipUnit = A.SlipUnit ) 
      WHERE (@SlipUnit = 0 OR A.SlipUnit = @SlipUnit) 
    

    IF EXISTS (SELECT 1 FROM #Result) 
    BEGIN 
        INSERT INTO #Result 
        SELECT 99999 AS SlipUnit, 
               'TOTAL' AS SlipUnitName, 
               SUM(A.InSendAmt) AS InSendAmt, 

               SUM(A.SendAmt1) AS SendAmt1, 
               SUM(A.SendAmt2) AS SendAmt2, 
               SUM(A.SendAmt3) AS SendAmt3, 
               SUM(A.SendAmt4) AS SendAmt4, 
               SUM(A.SendAmt5) AS SendAmt5, 
               SUM(A.SendAmt6) AS SendAmt6, 
               SUM(A.SendAmt7) AS SendAmt7, 
               SUM(A.SendAmt8) AS SendAmt8, 

               SUM(A.TotSendAmt) AS TotSendAmt, 
               SUM(A.AccSendAmt) AS AccSendAmt, 
               SUM(A.SumAmt) AS SumAmt, 

               '' AS Remark, 
               0 AS MinorSort, 
               '' AS IsSave 
          FROM #Result AS A 
    END 
    
    SELECT * FROM #Result ORDER BY MinorSort 
    
    RETURN  
GO
--exec hencom_SACFundSendPlanQuery @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>0</IsChangedMst>
--    <StdDate>20170706</StdDate>
--    <SlipUnit />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1512352,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033717