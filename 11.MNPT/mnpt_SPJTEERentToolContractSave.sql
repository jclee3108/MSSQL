  
IF OBJECT_ID('mnpt_SPJTEERentToolContractSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEERentToolContractSave  
GO  
    
-- v2017.11.21
  
-- 외부장비임차계약입력-SS1저장 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContract')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEERentToolContract'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'ContractSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTEERentToolContract      AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.ContractSeq, 
               B.ContractSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTEERentToolContractItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEERentToolContractItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTEERentToolContractItem'    , -- 테이블명        
                      '#ItemLog'    , -- 임시 테이블명        
                      'ContractSeq,ContractSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, End
        --------------------------------------------------------------
        
        DELETE B 
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTEERentToolContractItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.BizUnit        = A.BizUnit ,  
               B.ContractDate   = A.ContractDate ,  
               B.ContractNo     = A.ContractNo ,  
               B.RentCustSeq    = A.RentCustSeq ,  
               B.RentSrtDate    = A.RentSrtDate ,  
               B.RentEndDate    = A.RentEndDate ,  
               B.EmpSeq         = A.EmpSeq ,  
               B.DeptSeq        = A.DeptSeq ,  
               B.Remark         = A.Remark ,  
               B.LastUserSeq    = @UserSeq  ,  
               B.LastDateTime   = GETDATE() ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEERentToolContract  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTEERentToolContract  
        (   
            CompanySeq, ContractSeq, BizUnit, ContractDate, ContractNo, 
            RentCustSeq, RentSrtDate, RentEndDate, EmpSeq, DeptSeq, 
            Remark, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, 
            PgmSeq
        )   
        SELECT @CompanySeq, ContractSeq, BizUnit, ContractDate, ContractNo, 
               RentCustSeq, RentSrtDate, RentEndDate, EmpSeq, DeptSeq, 
               Remark, @UserSeq, GETDATE(), @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    RETURN  
 
