  
IF OBJECT_ID('mnpt_SPJTEERentToolContractCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractCheck  
GO  
    
-- v2017.11.21
  
-- 외부장비임차계약입력-SS1체크 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractCheck      
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
    


    ------------------------------------------------------------------------
    -- 체크1, 산출 된 계약은 수정,삭제 할 수 없습니다.
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '산출 된 계약은 수정,삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTEERentToolCalc 
                    WHERE CompanySeq = @CompanySeq 
                      AND ContractSeq = A.ContractSeq 
                  ) 
    ------------------------------------------------------------------------
    -- 체크1, End 
    ------------------------------------------------------------------------



    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT, 
            @Cnt    INT 
    
    SELECT @Cnt = 1 
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
        
        CREATE TABLE #CreateNo 
        (
            IDX_NO          INT IDENTITY, 
            Main_IDX_NO     INT, 
            ContractDate    NCHAR(8), 
            MaxNo           NVARCHAR(200)
        )
        INSERT INTO #CreateNo ( ContractDate, Main_IDX_NO, MaxNo )
        SELECT ContractDate, IDX_NO, ''
          FROM #BIZ_OUT_DataBlock1 
         WHERE Status = 0 
           AND WorkingTag = 'A' 
        
        
        WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #CreateNo),0) ) 
        BEGIN 
            SELECT @BaseDate = ISNULL( MAX(ContractDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
              FROM #CreateNo   
             WHERE IDX_NO = @Cnt 
          
            EXEC dbo._SCOMCreateNo 'SITE', 'mnpt_TPJTEERentToolContract', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
            -- Temp Talbe 에 생성된 키값 UPDATE  
            UPDATE #CreateNo  
               SET MaxNo = @MaxNo      
             WHERE IDX_NO = @Cnt 
        
            SELECT @Cnt = @Cnt + 1 
        END 
        
        UPDATE A
           SET ContractNo = B.MaxNo
          FROM #BIZ_OUT_DataBlock1  AS A 
          JOIN #CreateNo            AS B ON ( B.Main_IDX_NO = A.IDX_NO )  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   




    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEERentToolContract', 'ContractSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET ContractSeq = @Seq + DataSeq
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
       AND ( ContractSeq = 0 OR ContractSeq IS NULL )  
    
    RETURN  
    


go


