  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceSave') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceSave  
GO  
    
-- v2017.09.28
  
-- 노조노임단가입력-SS1저장 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePrice')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTUnionWagePrice'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'StdSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePrice      AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTUnionWagePriceItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePriceItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTUnionWagePriceItem'    , -- 테이블명        
                      '#ItemLog'    , -- 임시 테이블명        
                      'StdSeq,StdSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, End
        --------------------------------------------------------------
        
        DELETE B 
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePriceItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl, 
               B.TitleSeq 
          INTO #ValueLog
          FROM #BIZ_OUT_DataBlock1              AS A 
          JOIN mnpt_TPJTUnionWagePriceValue     AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePriceValue')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTUnionWagePriceValue'    , -- 테이블명        
                      '#ValueLog'    , -- 임시 테이블명        
                      'StdSeq,StdSerl,TitleSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock1          AS A   
          JOIN mnpt_TPJTUnionWagePriceValue AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.StdDate        = A.StdDate ,  
               B.Remark         = A.Remark  ,  
               B.LastUserSeq    = @UserSeq  ,  
               B.LastDateTime   = GETDATE() ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTUnionWagePrice  AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTUnionWagePrice  
        (   
            Companyseq, StdSeq, StdDate, Remark, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @Companyseq, StdSeq, StdDate, Remark, @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    RETURN  
 
