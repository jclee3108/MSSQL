
IF OBJECT_ID('KPXCM_SSEAccidentCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentCheckCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천 
-- v2015.01.28 
/************************************************************  
    설  명 - 데이터-사고관리 : 체크  
    작성일 - 20110324  
    작성자 - 천경민  
************************************************************/  
CREATE PROC KPXCM_SSEAccidentCheckCHE  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS  
    
    DECLARE @Count       INT,  
            @Seq         INT,  
            @Date        NCHAR(8),  
            @MaxNo       NVARCHAR(20),  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250)  
     
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #_TSEAccidentCHE (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEAccidentCHE'  
    IF @@ERROR <> 0 RETURN   
    
    -------------------------------  
    -- 사고조사등록 화면 CHECK  
    -------------------------------  
    IF @PgmSeq = 1025154    
    BEGIN  
        -------------------------------------------------  
        -- 사고조사등록시 발생보고 데이터 존재 여부 확인  
        -------------------------------------------------  
        UPDATE A  
           SET Result        = '발생보고 자료가 없으면 사고조사등록을 할 수 없습니다.',  
               MessageType   = 99999,  
               Status        = 99999  
          FROM #_TSEAccidentCHE AS A  
                 LEFT OUTER JOIN _TSEAccidentCHE AS B ON B.CompanySeq   = @CompanySeq  
                                                     AND A.AccidentSeq  = B.AccidentSeq  
                                                     AND B.AccidentSerl = '1'  
         WHERE A.WorkingTag = 'A'  
           AND A.Status = 0  
           AND A.AccidentSerl = '2'  
           AND ISNULL(B.AccidentSeq,0) = 0 
        END  
        
        -------------------------------  
        -- 사고발생보고등록 화면 CHECK  
        -------------------------------  
    ELSE IF @PgmSeq = 1025138 -- 사고발생보고등록 
    BEGIN  
        -------------------------------------------  
        -- 사고조사 등록 되었으면 삭제 안되게  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              8                  , -- 진행된 건이 있어 수정/삭제 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%삭제%')    
                              @LanguageSeq       ,     
                              0, ''  
         UPDATE A  
           SET Result        = @Results,  
               MessageType   = @MessageType,    
               Status        = @Status  
          FROM #_TSEAccidentCHE AS A  
               JOIN _TSEAccidentCHE AS B ON B.CompanySeq   = @CompanySeq  
                                          AND A.AccidentSeq  = B.AccidentSeq  
                                          AND B.AccidentSerl = '2'  
         WHERE A.WorkingTag = 'D'  
           AND A.Status = 0  
     
        -------------------------------------------  
        -- INSERT 번호부여(맨 마지막 처리)    
        -------------------------------------------    
        SELECT @Count = COUNT(1) FROM #_TSEAccidentCHE WHERE WorkingTag = 'A'  
          
        IF @Count > 0  
        BEGIN  
            SELECT @Date = ISNULL(MAX(AccidentDate), CONVERT(NCHAR(8), GETDATE(), 112))    
              FROM #_TSEAccidentCHE  
             WHERE WorkingTag = 'A'   
               AND Status = 0  
             -- 키값생성코드부분 시작      
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TSEAccidentCHE', 'AccidentSeq', @Count  
              
            -- Temp Table에 생성된 키값 UPDATE  
            UPDATE #_TSEAccidentCHE  
                   SET AccidentSeq = @Seq + DataSeq  
                 WHERE WorkingTag = 'A'    
                   AND Status = 0  
         
            -- 번호생성코드부분 시작      
       
            EXEC dbo._SCOMCreateNo 'SITE', '_TSEAccidentCHE', @CompanySeq, '', @Date, @MaxNo OUTPUT  
            -- Temp Talbe 에 생성된 키값 UPDATE    
            UPDATE #_TSEAccidentCHE    
               SET AccidentNo = @MaxNo  
             WHERE WorkingTag = 'A'  
               AND Status = 0  
        END  
    END  
    
    SELECT * FROM #_TSEAccidentCHE  
    
    RETURN  