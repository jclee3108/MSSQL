
  
IF OBJECT_ID('KPX_SSLMonthSalesPlanDlgRevQuery') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanDlgRevQuery  
GO  
  
-- v2014.11.14 
  
-- 월간판매계획입력Dlg-차수조회 by 이재천 
CREATE PROC KPX_SSLMonthSalesPlanDlgRevQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @BizUnit        INT,  
            @PlanYM         NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ), 
           @PlanYM      = ISNULL( PlanYM, '' ) 
    
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit        INT,  
            PlanYM         NCHAR(6)    
           )
    
    IF EXISTS (SELECT 1 
                 FROM KPX_TSLMonthSalesPlanRev           
                WHERE CompanySeq = @CompanySeq 
                  AND BizUnit = @BizUnit 
                  AND PlanYM = @PlanYM 
              ) 
    BEGIN 
        SELECT RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,MAX(PlanRev)) + 1),2) AS PlanRev, 
               CONVERT(INT,MAX(PlanRev)) + 1 AS PlanRevSeq 
         FROM KPX_TSLMonthSalesPlanRev           
        WHERE CompanySeq = @CompanySeq 
          AND BizUnit = @BizUnit 
          AND PlanYM = @PlanYM 
    
    END 
    ELSE 
    BEGIN
        SELECT '01' AS PlanRev, 1 AS PlanRevSeq 
    END 
    
    RETURN 
GO 
exec KPX_SSLMonthSalesPlanDlgRevQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201411</PlanYM>
    <BizUnit>2</BizUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025833,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021712



