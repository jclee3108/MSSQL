
IF OBJECT_ID('KPX_SSLReceiptPlanExpDomCurr') IS NOT NULL 
    DROP PROC KPX_SSLReceiptPlanExpDomCurr
GO 

-- v2014.03.06   
  
-- 채권수금계획(수출) (원화계산) by이재천  
CREATE PROC KPX_SSLReceiptPlanExpDomCurr                  
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