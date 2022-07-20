  
IF OBJECT_ID('mnpt_SPJTEERentToolContractItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractItemSave  
GO  
    
-- v2017.09.28
  
-- 외부장비임차계약입력-SS2저장 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractItemSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContractItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEERentToolContractItem'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock2'    , -- 임시 테이블명        
                  'ContractSeq,ContractSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock2                AS A   
          JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq AND A.ContractSerl = B.ContractSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMRentKind     = A.UMRentKind,  
               B.RentToolSeq    = A.RentToolSeq,  
               B.UMRentType     = A.UMRentType,  
               B.Qty            = A.Qty,  
               B.Price          = A.Price,  
               B.Amt            = A.Amt,  
               B.PJTSeq         = A.PJTSeq,  
               B.Remark         = A.Remark,
               B.LastUserSeq    = @UserSeq    ,  
               B.LastDateTime   = GETDATE()   ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock2                AS A   
          JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl )
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTEERentToolContractItem  
        (   
            CompanySeq, ContractSeq, ContractSerl, UMRentKind, RentToolSeq, 
            TextRentToolName, UMRentType, Qty, Price, Amt, 
            PJTSeq, Remark, FirstUserSeq, FirstDateTime, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ContractSeq, ContractSerl, UMRentKind, RentToolSeq, 
               TextRentToolName, UMRentType, Qty, Price, Amt, 
               PJTSeq, Remark, @UserSeq, GETDATE(), @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock2 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
 
go

