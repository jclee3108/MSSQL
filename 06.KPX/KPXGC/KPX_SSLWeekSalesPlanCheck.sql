
IF OBJECT_ID('KPX_SSLWeekSalesPlanCheck') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanCheck
GO 

-- v2014.11.17 

-- 주간판매계획입력(체크) by 이재천 
CREATE PROC KPX_SSLWeekSalesPlanCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #KPX_TSLWeekSalesPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TSLWeekSalesPlan'

    -- 체크1, 중복여부 체크 :   
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
      FROM #KPX_TSLWeekSalesPlan AS A     
      JOIN (SELECT S.BizUnit, S.WeekSeq, S.PlanRev, S.CustSeq, S.ItemSeq, S.PlanDate
              FROM (SELECT A1.BizUnit, A1.WeekSeq, A1.PlanRev, A1.CustSeq, A1.ItemSeq, A1.TITLE_IDX0_SEQ AS PlanDate
                      FROM #KPX_TSLWeekSalesPlan AS A1    
                     WHERE A1.WorkingTag IN ('A', 'U')    
                       AND A1.Status = 0    
                                                
                    UNION ALL    
                                               
                    SELECT A1.BizUnit, A1.WeekSeq, A1.PlanRev, A1.CustSeq, A1.ItemSeq, A1.PlanDate
                      FROM KPX_TSLWeekSalesPlan AS A1    
                     WHERE A1.CompanySeq = @CompanySeq     
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TSLWeekSalesPlan     
                                               WHERE WorkingTag IN ('U','D')     
                                                 AND Status = 0     
                                                 AND BizUnit = A1.BizUnit    
                                                 AND WeekSeq = A1.WeekSeq   
                                                 AND PlanRev = A1.PlanRev   
                                                 AND CustSeqOld = A1.CustSeq   
                                                 AND ItemSeqOld = A1.ItemSeq  
                                                 AND TITLE_IDX0_SEQ = A1.PlanDate
                                      )    
                   ) AS S    
             GROUP BY S.BizUnit, S.WeekSeq, S.PlanRev, S.CustSeq, S.ItemSeq, S.PlanDate
            HAVING COUNT(1) > 1    
           ) AS B ON ( A.BizUnit = B.BizUnit AND A.WeekSeq = B.WeekSeq AND B.PlanRev = A.PlanRev AND B.CustSeq = A.CustSeq AND B.itemSeq = A.itemSeq AND A.TITLE_IDX0_SEQ = B.PlanDate)   
     WHERE A.WorkingTag IN ('A', 'U')    
       AND A.Status = 0    
    -- 체크1, END 
    
    -- 체크2, 차수등록 다시하시기 바랍니다. 
    IF NOT EXISTS (SELECT 1 
                     FROM KPX_TSLWeekSalesPlanRev AS A 
                     JOIN ( SELECT DISTINCT WeekSeq, PlanRev, BizUnit 
                              FROM #KPX_TSLWeekSalesPlan 
                          ) AS B ON ( B.WeekSeq = A.WeekSeq AND B.PlanRev = A.PlanRev AND B.BizUnit = A.BizUnit ) 
                    WHERE CompanySeq = @CompanySeq 
                  )
    BEGIN
        UPDATE A 
           SET Result = '차수등록을 다시하시기 바랍니다. ', 
               Status = 1234, 
               MessageType = 1234
          FROM #KPX_TSLWeekSalesPlan AS A 
    END 
    -- 체크2, END 
    
    SELECT * FROM #KPX_TSLWeekSalesPlan 
    
    RETURN    
GO 