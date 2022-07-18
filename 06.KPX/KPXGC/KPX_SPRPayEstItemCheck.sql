  
IF OBJECT_ID('KPX_SPRPayEstItemCheck') IS NOT NULL   
    DROP PROC KPX_SPRPayEstItemCheck  
GO  
  
-- v2014.12.15  
  
-- 급여추정항목설정-체크 by 이재천   
CREATE PROC KPX_SPRPayEstItemCheck  
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
      
    CREATE TABLE #KPX_TPRPayEstItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayEstItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE #KPX_TPRPayEstItem  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TPRPayEstItem AS A   
      JOIN (SELECT S.ItemSeq  
              FROM (SELECT A1.ItemSeq  
                      FROM #KPX_TPRPayEstItem AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ItemSeq  
                      FROM KPX_TPRPayEstItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TPRPayEstItem   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ItemSeqOld = A1.ItemSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ItemSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    
    SELECT * FROM #KPX_TPRPayEstItem   
      
    RETURN  