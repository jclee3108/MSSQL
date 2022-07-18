
IF OBJECT_ID('yw_SACSalesReceiptPlanExpDomCurr') IS NOT NULL 
    DROP PROC yw_SACSalesReceiptPlanExpDomCurr
GO 

-- v2014.03.06 

-- 채권수금계획(수출)_yw(원화계산) by이재천
CREATE PROC dbo.yw_SACSalesReceiptPlanExpDomCurr                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       
AS        
    
    DECLARE @docHandle      INT,
            @PlanYM         NCHAR(6) ,
            @CurrSeq        INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @PlanYM  = ISNULL(PlanYM,''), 
           @CurrSeq = ISNULL(CurrSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
      WITH (PlanYM  NCHAR(6), 
            CurrSeq INT )
    
    SELECT ISNULL(ExRate,1) AS ExRate 
      FROM _TPNSimpleExRate 
     WHERE CompanySeq = @CompanySeq 
       AND PlanYM = @PlanYM 
       AND CurrSeq = @CurrSeq 
    UNION ALL 
    SELECT 1
     WHERE NOT EXISTS (SELECT 1 FROM _TPNSimpleExRate WHERE CompanySeq = @CompanySeq AND PlanYM = @PlanYM AND CurrSeq = @CurrSeq)
    
    RETURN
GO
exec yw_SACSalesReceiptPlanExpDomCurr @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CurrSeq>0</CurrSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PlanYM>201403</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019921,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016812