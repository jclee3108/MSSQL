  
IF OBJECT_ID('mnpt_SPJTEEExcelUploadMappingCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEEExcelUploadMappingCheck  
GO  
    

-- v2017.11.20
  
-- 제주연안엑셀업로드맵핑_mnpt-체크 by 이재천   
CREATE PROC mnpt_SPJTEEExcelUploadMappingCheck   
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results + ' (프로젝트, 청구항목)',
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.PJTSeq, S.ItemSeq   
              FROM (SELECT A1.PJTSeq, A1.ItemSeq  
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTSeq, A1.ItemSeq  
                      FROM mnpt_TPJTEEExcelUploadMapping AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND MappingSeq = A1.MappingSeq  
                                      )  
                   ) AS S  
             GROUP BY S.PJTSeq, S.ItemSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTSeq = B.PJTSeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- 중복여부 체크 :   
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results + ' (항목(Text), 구분(Text))',
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.TextPJTType, S.TextItemKind   
              FROM (SELECT A1.TextPJTType, A1.TextItemKind  
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.TextPJTType, A1.TextItemKind
                      FROM mnpt_TPJTEEExcelUploadMapping AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND MappingSeq = A1.MappingSeq  
                                      )  
                   ) AS S  
             GROUP BY S.TextPJTType, S.TextItemKind 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.TextPJTType = B.TextPJTType AND A.TextItemKind = B.TextItemKind )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
      


    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEEExcelUploadMapping', 'MappingSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET MappingSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( MappingSeq = 0 OR MappingSeq IS NULL )  
      
      
    RETURN  
