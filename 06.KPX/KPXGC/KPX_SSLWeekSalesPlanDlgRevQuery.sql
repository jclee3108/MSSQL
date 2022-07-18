
IF OBJECT_ID('KPX_SSLWeekSalesPlanDlgRevQuery') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanDlgRevQuery
GO 

-- v2014.11.17 
    
-- 주간판매계획입력Dlg-차수조회 by 이재천   
CREATE PROC KPX_SSLWeekSalesPlanDlgRevQuery    
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
            @WeekSeq        INT
        
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
      
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),   
           @WeekSeq     = ISNULL( WeekSeq, '' )   
      
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
            BizUnit        INT,    
            WeekSeq        INT 
           )  
      
    IF EXISTS (SELECT 1   
                 FROM KPX_TSLWeekSalesPlanRev             
                WHERE CompanySeq = @CompanySeq   
                  AND BizUnit = @BizUnit   
                  AND WeekSeq = @WeekSeq
              )   
    BEGIN   
        SELECT RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,MAX(PlanRev)) + 1),2) AS PlanRev,   
               CONVERT(INT,MAX(PlanRev)) + 1 AS PlanRevSeq   
         FROM KPX_TSLWeekSalesPlanRev             
        WHERE CompanySeq = @CompanySeq   
          AND BizUnit = @BizUnit   
          AND WeekSeq = @WeekSeq   
      
    END   
    ELSE   
    BEGIN  
        SELECT '01' AS PlanRev, 1 AS PlanRevSeq   
    END   
      
    RETURN   