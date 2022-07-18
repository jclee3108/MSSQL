  
IF OBJECT_ID('KPX_SACDailyExpPlanItemQuery') IS NOT NULL   
    DROP PROC KPX_SACDailyExpPlanItemQuery  
GO  
  
-- v2014.12.09  
  
-- 일일외화매각계획서-매각 조회 by 이재천   
CREATE PROC KPX_SACDailyExpPlanItemQuery  
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
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (BaseDate   NCHAR(8))    
    
    -- 최종조회   
    SELECT A.BaseDate, 
           A.Serl, 
           A.UMExpPlanSeq, 
           B.MinorName AS UMExpPlanName, 
           A.UMBankSeq, 
           C.MinorName AS UMBankName, 
           A.Amt, 
           A.ExRate, 
           A.Remark
           
      FROM KPX_TACDailyExpPlanItem  AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMExpPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMBankSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND @BaseDate = A.BaseDate  
    
    RETURN  