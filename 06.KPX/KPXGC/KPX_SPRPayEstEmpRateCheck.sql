  
IF OBJECT_ID('KPX_SPRPayEstEmpRateCheck') IS NOT NULL   
    DROP PROC KPX_SPRPayEstEmpRateCheck  
GO  
  
-- v2014.12.15  
  
-- 급여추정 개인별인상율-체크 by 이재천   
CREATE PROC KPX_SPRPayEstEmpRateCheck  
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
    
    CREATE TABLE #KPX_TPRPayEstEmpRate( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayEstEmpRate'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE #KPX_TPRPayEstEmpRate  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TPRPayEstEmpRate AS A   
      JOIN (SELECT S.YY, S.EmpSeq  
              FROM (SELECT A1.YY, A1.EmpSeq   
                      FROM #KPX_TPRPayEstEmpRate AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.YY, A1.EmpSeq   
                      FROM KPX_TPRPayEstEmpRate AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TPRPayEstEmpRate   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND YY = A1.YY 
                                                 AND EmpSeqOld = A1.EmpSeq 
                                      )  
                   ) AS S  
             GROUP BY S.YY, S.EmpSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.YY = B.YY AND A.EmpSeq = B.EmpSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TPRPayEstEmpRate   
      
    RETURN  