  
IF OBJECT_ID('KPX_SEQCheckReportCheck') IS NOT NULL   
    DROP PROC KPX_SEQCheckReportCheck  
GO  
  
-- v2014.10.31  
  
-- 점검내역등록-체크 by 이재천   
CREATE PROC KPX_SEQCheckReportCheck  
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
      
    CREATE TABLE #KPX_TEQCheckReport( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQCheckReport'   
    IF @@ERROR <> 0 RETURN     
    
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #KPX_TEQCheckReport  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TEQCheckReport AS A   
      JOIN (SELECT S.ToolSeq, S.CheckDate, S.UMCheckTerm   
              FROM (SELECT A1.ToolSeq, A1.CheckDate, A1.UMCheckTerm 
                      FROM #KPX_TEQCheckReport AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ToolSeq, A1.CheckDate, A1.UMCheckTerm 
                      FROM KPX_TEQCheckReport AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TEQCheckReport   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ToolSeq = A1.ToolSeq  
                                                 AND CheckDateOld = A1.CheckDate 
                                                 AND UMCheckTerm = A1.UMCheckTerm
                                      )  
                   ) AS S  
             GROUP BY S.ToolSeq, S.CheckDate, S.UMCheckTerm   
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ToolSeq = B.ToolSeq AND A.CheckDate = B.CheckDate AND A.UMCheckTerm = B.UMCheckTerm )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TEQCheckReport   
      
    RETURN  