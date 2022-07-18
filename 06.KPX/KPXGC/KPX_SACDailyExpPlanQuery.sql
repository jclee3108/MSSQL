  
IF OBJECT_ID('KPX_SACDailyExpPlanQuery') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanQuery  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-조회 by 이재천   
CREATE PROC KPX_SACDailyExpPlanQuery  
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
            @BaseDate   NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BaseDate = ISNULL( BaseDate, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (BaseDate   NCHAR(8))    
    
    -- 최종조회   
    SELECT A.BaseDate, 
           A.DeptSeq, 
           B.DeptName, 
           A.BegExRate, 
           A.ExRateSpread 
      FROM KPX_TACDailyExpPlan  AS A 
      LEFT OUTER JOIN _TDADept  AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND @BaseDate = A.BaseDate  
    
    RETURN  