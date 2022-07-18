  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockCodeSet') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockCodeSet  
GO  
  
-- v2016.06.15  
  
-- 월생산계획-코드셋팅 by 이재천 
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockCodeSet  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PlanYM     NCHAR(8), 
            @FactUnit   INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYM      = ISNULL( PlanYM, '' ), 
           @FactUnit    = ISNULL( FactUnit, 0 )
    
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PlanYM     NCHAR(8), 
            FactUnit   INT       
           )    
    
    SELECT TOP 1 A.PlanSeq  
      FROM KPXCM_TPDSFCMonthProdPlanStock AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanYM = A.PlanYMSub
       AND A.PlanYM = @PlanYM 
       AND A.FactUnit = @FactUnit 
       
    
    RETURN  
    GO
    exec KPXCM_SPDSFCMonthProdPlanStockCodeSet @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>3</FactUnit>
    <PlanYM>201607</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069