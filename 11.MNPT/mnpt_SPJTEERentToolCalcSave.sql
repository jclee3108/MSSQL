  
IF OBJECT_ID('mnpt_SPJTEERentToolCalcSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolCalcSave  
GO  
    
-- v2017.11.28
  
-- 외부장비임차정산-저장 by 이재천
CREATE PROC mnpt_SPJTEERentToolCalcSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
       
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolCalc')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEERentToolCalc'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'CalcSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    --select 1, * from #BIZ_OUT_DataBlock1 
    --return 

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTEERentToolCalc AS B ON ( B.CompanySeq = @CompanySeq AND A.CalcSeq = B.CalcSeq ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        UPDATE A
           SET Qty          = 0,
               Price        = 0,
               Amt          = 0,
               AddListName  = '',
               AddQty       = 0,
               AddPrice     = 0,
               AddAmt       = 0,
               RentAmt      = 0,
               RentVAT      = 0,
               TotalAmt     = 0,
               Remark       = '',
               IsCalc       = '0',
               CalcSeq      = 0
          FROM #BIZ_OUT_DataBlock1 AS A 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.Qty          = A.Qty          , 
               B.Price        = A.Price        , 
               B.Amt          = A.Amt          , 
               B.AddListName  = A.AddListName  , 
               B.AddQty       = A.AddQty       , 
               B.AddPrice     = A.AddPrice     , 
               B.AddAmt       = A.AddAmt       , 
               B.RentAmt      = A.RentAmt      , 
               B.RentVAT      = A.RentVAT      , 
               B.Remark       = A.Remark       , 
               B.LastUserSeq  = @UserSeq       , 
               B.LastDateTime = GETDATE()      , 
               B.PgmSeq       = @PgmSeq     
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEERentToolCalc  AS B ON ( B.CompanySeq = @CompanySeq AND A.CalcSeq = B.CalcSeq ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        --select * From #BIZ_OUT_DataBlock1 
        --return 
        ------------------------------------------------------------------------
        -- 외부장비임차계약
        ------------------------------------------------------------------------
        SELECT A.ContractSeq, B.ContractSerl, A.BizUnit, A.RentCustSeq , A.RentSrtDate, 
               A.RentEndDate, B.UMRentKind, B.RentToolSeq, B.UMRentType, B.Qty, 
               B.Price, B.Amt
          INTO #Contract
          FROM mnpt_TPJTEERentToolContract      AS A 
          JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND EXISTS (SELECT 1 
                         FROM #BIZ_OUT_DataBlock1 AS Z  
                        WHERE Z.ContractSeq = A.ContractSeq
                          AND Z.ContractSerl = B.ContractSerl 
                      )
        
        UPDATE A
           SET Qty = B.Qty, 
               Price = B.Price, 
               Amt = B.Qty * B.Price, 
               RentAmt = B.Qty * B.Price, 
               RentVAT = (B.Qty * B.Price) * 0.1, 
               TotalAmt = (B.Qty * B.Price) + ((B.Qty * B.Price) * 0.1)
          FROM #BIZ_OUT_DataBlock1  AS A 
          JOIN #Contract            AS B ON ( B.ContractSeq = A.ContractSeq 
                                          AND B.ContractSerl = A.ContractSerl 
                                            ) 


        INSERT INTO mnpt_TPJTEERentToolCalc  
        (   
            CompanySeq, CalcSeq, BizUnit, RentCustSeq, UMRentType, 
            UMRentKind, RentToolSeq, WorkDate, Qty, Price, 
            Amt, AddListName, AddQty, AddPrice, AddAmt, 
            RentAmt, RentVAT, Remark, ContractSeq, ContractSerl, 
            SlipSeq, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, 
            PgmSeq, StdYM
        )   
        SELECT @CompanySeq, CalcSeq, BizUnit, RentCustSeq, UMRentType, 
               UMRentKind, RentToolSeq, WorkDateSub, Qty, Price, 
               Amt, AddListName, AddQty, AddPrice, AddAmt, 
               RentAmt, RentVAT, Remark, ContractSeq, ContractSerl, 
               0, @UserSeq, GETDATE(), @UserSeq, GETDATE(), 
               @PgmSeq, StdYM
          FROM #BIZ_OUT_DataBlock1 AS A   
          
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    

    RETURN  

