  
IF OBJECT_ID('mnpt_SPJTEERentToolContractItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractItemCheck  
GO  
    
-- v2018.01.05
  
-- 외부장비임차계약입력-SS2체크 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractItemCheck      
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
            @Results        NVARCHAR(250), 
            @MaxSerl        INT 
    /*
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2' 
    UPDATE #BIZ_OUT_DataBlock2  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock2 AS A   
      JOIN (SELECT S.PJTTypeSeq, S.UMLoadWaySeq, S.ContractSeq
              FROM (SELECT A1.PJTTypeSeq, A1.UMLoadWaySeq, A1.ContractSeq
                      FROM #BIZ_OUT_DataBlock2 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTTypeSeq, A1.UMLoadWaySeq, A1.ContractSeq
                      FROM mnpt_TPJTEERentToolContractItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock2   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ContractSeq = A1.ContractSeq  
                                                 AND StdSerl = A1.StdSerl
                                      )  
                   ) AS S  
             GROUP BY S.PJTTypeSeq, S.UMLoadWaySeq, S.ContractSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTTypeSeq = B.PJTTypeSeq AND A.UMLoadWaySeq = B.UMLoadWaySeq AND A.ContractSeq = B.ContractSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  


    UPDATE A  
       SET Result       = B.Result, 
           MessageType  = B.MessageType,  
           Status       = B.Status  
      FROM #BIZ_OUT_DataBlock3  AS A 
      JOIN #BIZ_OUT_DataBlock2        AS B ON ( B.ROW_IDX = A.ROW_IDX ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    */
    
    ------------------------------------------------------------------------
    -- 체크1, 장비(임차구분)인 경우에는 장비가 필수입니다. 
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '장비(임차구분)인 경우에는 장비가 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.UMRentKind = 1016351001 
       AND (A.RentToolSeq = 0 OR A.RentToolSeq IS NULL)
    ------------------------------------------------------------------------
    -- 체크1, End 
    ------------------------------------------------------------------------

    ------------------------------------------------------------------------
    -- 체크2, 운전원(임차구분), SPC장비(임차구분)인 경우에는 장비를 입력 할 수 없습니다.
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '운전원(임차구분), SPC장비(임차구분)인 경우에는 장비를 입력 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.UMRentKind <> 1016351001 
       AND (A.RentToolSeq <> 0 AND A.RentToolSeq IS NOT NULL)
    ------------------------------------------------------------------------
    -- 체크2, End 
    ------------------------------------------------------------------------

    ------------------------------------------------------------------------
    -- 체크3, 산출 된 계약은 수정,삭제 할 수 없습니다.
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '산출 된 계약은 수정,삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTEERentToolCalc 
                    WHERE CompanySeq = @CompanySeq 
                      AND ContractSeq = A.ContractSeq 
                      AND ContractSerl = A.ContractSerl
                  ) 
    ------------------------------------------------------------------------
    -- 체크3, End 
    ------------------------------------------------------------------------





    -- Serl 채번 
    SELECT @MaxSerl = MAX(A.ContractSerl) 
      FROM mnpt_TPJTEERentToolContractItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock2 WHERE ContractSeq = A.ContractSeq) 
    
    UPDATE A 
       SET ContractSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock2   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock2  
     WHERE Status = 0  
       AND ( ContractSeq = 0 OR ContractSeq IS NULL ) 
        
    
    RETURN  
  
  go

