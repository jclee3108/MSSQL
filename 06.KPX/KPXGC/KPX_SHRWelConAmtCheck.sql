  
IF OBJECT_ID('KPX_SHRWelConAmtCheck') IS NOT NULL   
    DROP PROC KPX_SHRWelConAmtCheck  
GO  
  
-- v2014.11.27  
  
-- 경조사지급기준등록-체크 by 이재천   
CREATE PROC KPX_SHRWelConAmtCheck  
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
    
    CREATE TABLE #KPX_THRWelConAmt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelConAmt'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0

    UPDATE #KPX_THRWelConAmt  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_THRWelConAmt AS A   
      JOIN (SELECT S.SMConMutual, S.ConSeq, S.WkItemSeq  
              FROM (SELECT A1.SMConMutual, A1.ConSeq, A1.WkItemSeq    
                      FROM #KPX_THRWelConAmt AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.SMConMutual, A1.ConSeq, A1.WkItemSeq   
                      FROM KPX_THRWelConAmt AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_THRWelConAmt   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND SMConMutual = A1.SMConMutual   
                                                 AND ConSeq = A1.ConSeq 
                                                 AND WkItemSeqOld = A1.WkItemSeq 
                                      )  
                   ) AS S  
             GROUP BY S.SMConMutual, S.ConSeq, S.WkItemSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.SMConMutual = B.SMConMutual AND A.ConSeq = B.ConSeq AND A.WkItemSeq = B.WkItemSeq)  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_THRWelConAmt   
    
    RETURN  
    
    
