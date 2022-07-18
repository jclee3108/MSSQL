  
IF OBJECT_ID('KPX_SACFundDailyPlanIsExists') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanIsExists  
GO  
  
-- v2014.12.23  
  
-- 일자금계획입력(자금일보)- 데이터 존재여부 by 이재천   
CREATE PROC KPX_SACFundDailyPlanIsExists  
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
            @FundDate   NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FundDate  = ISNULL( FundDate, '' )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FundDate   NCHAR(8)
           )    
    
    
    IF EXISTS (SELECT 1 FROM KPX_TACFundDailyPlanIn WHERE CompanySeq = @CompanySeq AND FundDate = @FundDate) 
    OR EXISTS (SELECT 1 FROM KPX_TACFundDailyPlanOut WHERE CompanySeq = @CompanySeq AND FundDate = @FundDate)
    BEGIN
        SELECT '1' AS IsExists 
    END  
    ELSE 
    BEGIN
        SELECT '0' AS IsExists 
    END 
    
    RETURN  
GO 
