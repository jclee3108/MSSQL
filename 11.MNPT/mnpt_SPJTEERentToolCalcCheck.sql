  
IF OBJECT_ID('mnpt_SPJTEERentToolCalcCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolCalcCheck  
GO  
    
-- v2017.11.28
  
-- 외부장비임차정산-체크 by 이재천
CREATE PROC mnpt_SPJTEERentToolCalcCheck  
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
    


    UPDATE A
        SET WorkingTag = LEFT(@WorkingTag,1)
        FROM #BIZ_OUT_DataBlock1 AS A 
    
    
    --------------------------------------------------------------------------
    -- 체크0, 계약이 존재 하지 않아 처리 할 수 없습니다.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '계약이 존재 하지 않아 처리 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE Status = 0        
       AND BizUnit = 0 
    --------------------------------------------------------------------------
    -- 체크0, End 
    --------------------------------------------------------------------------
    --------------------------------------------------------------------------
    -- 체크1, 이미 산출 되어 있습니다.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '이미 산출 되어 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND EXISTS (
                   SELECT 1 
                     FROM mnpt_TPJTEERentToolCalc 
                    WHERE CompanySeq = @CompanySeq 
                      AND BizUnit = A.BizUnit 
                      AND RentCustSeq = A.RentCustSeq 
                      AND UMRentType = A.UMRentType 
                      AND UMRentKind = A.UMRentKind 
                      AND RentToolSeq = A.RentToolSeq 
                      AND WorkDate = A.WorkDateSub
                      AND ContractSeq = A.ContractSeq 
                      AND ContractSerl = A.ContractSerl 
                  ) 
    --------------------------------------------------------------------------
    -- 체크1, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- 체크2, 산출 되지 않은 건입니다.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '산출 되지 않은 건입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN mnpt_TPJTEERentToolCalc AS B ON ( B.CompanySeq = @CompanySeq AND B.CalcSeq = A.CalcSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
       AND NOT EXISTS (
                       SELECT 1 
                         FROM mnpt_TPJTEERentToolCalc 
                        WHERE CompanySeq = @CompanySeq 
                          AND ContractSeq = A.ContractSeq 
                          AND ContractSerl = A.ContractSerl
                          AND StdYM = B.StdYM
                    ) 
    --------------------------------------------------------------------------
    -- 체크2, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- 체크3, 산출 후 처리 할 수 있습니다.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '산출 후 처리 할 수 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'U' 
       AND (A.CalcSeq = 0 OR A.CalcSeq IS NULL)
    --------------------------------------------------------------------------
    -- 체크3, End 
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- 체크4, 전표가 발행되어 처리 할 수 없습니다.
    --------------------------------------------------------------------------
    UPDATE A
       SET Result = '전표가 발행되어 처리 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN mnpt_TPJTEERentToolCalc AS B ON ( B.CompanySeq = @CompanySeq AND B.CalcSeq = A.CalcSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U' , 'D' ) 
       AND B.SlipSeq <> 0 
    --------------------------------------------------------------------------
    -- 체크4, End 
    --------------------------------------------------------------------------
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TPJTEERentToolCalc', 'CalcSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET CalcSeq = @Seq + DataSeq
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
       AND ( CalcSeq = 0 OR CalcSeq IS NULL )  
    
    RETURN  
    go
