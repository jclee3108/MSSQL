 
IF OBJECT_ID('hencom_SACFundPlanCloseQuery') IS NOT NULL   
    DROP PROC hencom_SACFundPlanCloseQuery  
GO  

-- v2017.07.10
  
-- 자금계획마감-조회 by 이재천
CREATE PROC hencom_SACFundPlanCloseQuery  
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
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DateFr = ISNULL( DateFr, '' ),  
           @DateTo = ISNULL( DateTo, '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DateFr     NCHAR(8),
            DateTo     NCHAR(8)
           )    
    
    CREATE TABLE #Result 
    (
        StdDate     NCHAR(8), 
        Check1      NCHAR(1), 
        Check2      NCHAR(1), 
        Check3      NCHAR(1), 
        Check4      NCHAR(1), 
        IsExists1   NCHAR(1), 
        IsExists2   NCHAR(1), 
        IsExists3   NCHAR(1),
        IsExists4   NCHAR(1), 
        CloseTime   NVARCHAR(200)
    )
    
    -- 정기분대금지급 
    INSERT INTO #Result ( StdDate, IsExists1, IsExists2, IsExists3, IsExists4 ) 
    SELECT DISTINCT A.StdDate, '1', '0', '0', '0'
      FROM hencom_TACPaymentPricePlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate BETWEEN @DateFr AND @DateTo 

    -- 자금이체 
    INSERT INTO #Result ( StdDate, IsExists1, IsExists2, IsExists3, IsExists4 ) 
    SELECT DISTINCT A.StdDate, '0', '1', '0', '0'
      FROM hencom_TACFundSendPlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate BETWEEN @DateFr AND @DateTo 
    
    -- 도급비내역 
    INSERT INTO #Result ( StdDate, IsExists1, IsExists2, IsExists3, IsExists4 ) 
    SELECT DISTINCT A.StdDate, '0', '0', '1', '0'
      FROM hencom_TACSubContrAmtList  AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate BETWEEN @DateFr AND @DateTo 
    
    -- 전도금 
    INSERT INTO #Result ( StdDate, IsExists1, IsExists2, IsExists3, IsExists4 ) 
    SELECT DISTINCT A.StdDate, '0', '0', '0', '1'
      FROM hencom_TACSendAmtList  AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate BETWEEN @DateFr AND @DateTo 
    

    UPDATE A
       SET Check1 = ISNULL(B.Check1,'0'), 
           Check2 = ISNULL(B.Check2,'0'), 
           Check3 = ISNULL(B.Check3,'0'), 
           Check4 = ISNULL(B.Check4,'0'), 
           CloseTime = CONVERT(NVARCHAR(200),B.LastDateTime,120)
      FROM #Result                              AS A 
      LEFT OUTER JOIN hencom_TACFundPlanClose   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 

    
    SELECT StdDate, 
           MAX(Check1) AS Check1, 
           MAX(Check2) AS Check2, 
           MAX(Check3) AS Check3, 
           MAX(Check4) AS Check4, 
           MAX(IsExists1) AS IsExists1, 
           MAX(IsExists2) AS IsExists2, 
           MAX(IsExists3) AS IsExists3, 
           MAX(IsExists4) AS IsExists4, 
           MAX(CloseTime) AS CloseTime 
      FROM #Result 
     GROUP BY StdDate 
     ORDER BY StdDate 
    
    RETURN  
    GO 
exec hencom_SACFundPlanCloseQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DateFr>20170601</DateFr>
    <DateTo>20170710</DateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033922