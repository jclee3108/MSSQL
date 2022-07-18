
IF OBJECT_ID('KPX_SSLWeekSalesPlanDlgCheck') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanDlgCheck
GO 

-- v2014.11.17 
    
-- 주간판매계획입력Dlg-체크 by 이재천     
CREATE PROC KPX_SSLWeekSalesPlanDlgCheck    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    DECLARE @MessageType    INT,    
            @Status         INT,    
            @Results        NVARCHAR(250)     
      
    CREATE TABLE #KPX_TSLWeekSalesPlanRev( WorkingTag NCHAR(1) NULL )      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLWeekSalesPlanRev'     
    IF @@ERROR <> 0 RETURN       
      
    -- 체크 1, 전 차수의 데이터가 존재하지 않습니다.  
    IF NOT EXISTS ( SELECT 1  
                     FROM #KPX_TSLWeekSalesPlanRev AS A   
                     JOIN KPX_TSLWeekSalesPlan     AS B ON ( B.CompanySeq = @CompanySeq   
                                                          AND B.BizUnit = A.BizUnit   
                                                          AND B.WeekSeq = A.WeekSeq
                                                          AND B.PlanRev = RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,A.PlanRev)-1),2) )   
                  )  
       AND (SELECT PlanRev FROM #KPX_TSLWeekSalesPlanRev) <> '01'  
    BEGIN  
        UPDATE A  
           SET Result = '전 차수의 데이터가 존재하지 않습니다.',   
               Status = 1234,   
               MessageType = 1234  
          FROM #KPX_TSLWeekSalesPlanRev AS A   
    END                     
    -- 체크 1, END   
  
      
    SELECT * FROM #KPX_TSLWeekSalesPlanRev     
        
    RETURN    