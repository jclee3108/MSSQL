  
IF OBJECT_ID('KPX_SSLMonthSalesPlanCheck') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanCheck  
GO  
  
-- v2014.11.14  
  
-- 월간판매계획입력-체크 by 이재천   
CREATE PROC KPX_SSLMonthSalesPlanCheck  
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
      
    CREATE TABLE #KPX_TSLMonthSalesPlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLMonthSalesPlan'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE A  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TSLMonthSalesPlan AS A   
      JOIN (SELECT S.BizUnit, S.PlanYM, S.PlanRev, S.CustSeq, S.ItemSeq
              FROM (SELECT A1.BizUnit, A1.PlanYM, A1.PlanRev, A1.CustSeq, A1.ItemSeq
                      FROM #KPX_TSLMonthSalesPlan AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.BizUnit, A1.PlanYM, A1.PlanRev, A1.CustSeq, A1.ItemSeq
                      FROM KPX_TSLMonthSalesPlan AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TSLMonthSalesPlan   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND BizUnit = A1.BizUnit  
                                                 AND PlanYM = A1.PlanYM 
                                                 AND PlanRev = A1.PlanRev 
                                                 AND CustSeqOld = A1.CustSeq 
                                                 AND ItemSeqOld = A1.ItemSeq
                                      )  
                   ) AS S  
             GROUP BY S.BizUnit, S.PlanYM, S.PlanRev, S.CustSeq, S.ItemSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.BizUnit = B.BizUnit AND A.PlanYM = B.PlanYM AND B.PlanRev = A.PlanRev AND B.CustSeq = A.CustSeq AND B.itemSeq = A.itemSeq ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- 체크2, 차수등록 다시하시기 바랍니다. 
    IF NOT EXISTS (SELECT 1 
                     FROM KPX_TSLMonthSalesPlanRev AS A 
                     JOIN ( SELECT DISTINCT PlanYM, PlanRev, BizUnit 
                              FROM #KPX_TSLMonthSalesPlan 
                          ) AS B ON ( B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev AND B.BizUnit = A.BizUnit ) 
                    WHERE CompanySeq = @CompanySeq 
                  )
    BEGIN
        UPDATE A 
           SET Result = '차수등록을 다시하시기 바랍니다. ', 
               Status = 1234, 
               MessageType = 1234
          FROM #KPX_TSLMonthSalesPlan AS A 
    END 
    -- 체크2, END 
    
    SELECT * FROM #KPX_TSLMonthSalesPlan   
      
    RETURN  