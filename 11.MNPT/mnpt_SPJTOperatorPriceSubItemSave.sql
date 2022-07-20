  
IF OBJECT_ID('mnpt_SPJTOperatorPriceSubItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceSubItemSave  
GO  
    
-- v2017.09.19
  
-- 운전원노임단가입력-SS3저장 by 이재천
CREATE PROC mnpt_SPJTOperatorPriceSubItemSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceSubItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTOperatorPriceSubItem'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock3'    , -- 임시 테이블명        
                  'StdSeq,StdSerl,StdSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock3          AS A   
          JOIN mnpt_TPJTOperatorPriceSubItem   AS B ON ( B.CompanySeq = @CompanySeq 
                                                     AND A.StdSeq = B.StdSeq 
                                                     AND A.StdSerl = B.StdSerl 
                                                     AND A.StdSubSerl = B.StdSubSerl 
                                                       )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PJTTypeSeq      = A.PJTTypeSeq      ,  
               B.UnDayPrice      = A.UnDayPrice      ,  
               B.UnHalfPrice     = A.UnHalfPrice     ,  
               B.UnMonthPrice    = A.UnMonthPrice    ,  
               B.DailyDayPrice   = A.DailyDayPrice   ,  
               B.DailyHalfPrice  = A.DailyHalfPrice  ,  
               B.DailyMonthPrice = A.DailyMonthPrice ,  
               B.OSDayPrice      = A.OSDayPrice      ,  
               B.OSHalfPrice     = A.OSHalfPrice     ,  
               B.OSMonthPrice    = A.OSMonthPrice    ,  
               B.EtcDayPrice     = A.EtcDayPrice     ,  
               B.EtcHalfPrice    = A.EtcHalfPrice    ,  
               B.EtcMonthPrice   = A.EtcMonthPrice   , 
               B.LastUserSeq     = @UserSeq    ,  
               B.LastDateTime    = GETDATE()   ,
               B.PgmSeq          = @PgmSeq   
          FROM #BIZ_OUT_DataBlock3             AS A   
          JOIN mnpt_TPJTOperatorPriceSubItem   AS B ON ( B.CompanySeq = @CompanySeq 
                                                     AND A.StdSeq = B.StdSeq 
                                                     AND A.StdSerl = B.StdSerl 
                                                     AND A.StdSubSerl = B.StdSubSerl 
                                                       )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTOperatorPriceSubItem  
        (   
            Companyseq, StdSeq, StdSerl, StdSubSerl, PJTTypeSeq, 
            UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, 
            DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice, 
            EtcHalfPrice, EtcMonthPrice, FirstUserSeq, FirstDateTime, LastUserSeq, 
            LastDateTime, PgmSeq
        )   
        SELECT @Companyseq, StdSeq, StdSerl, StdSubSerl, PJTTypeSeq, 
               UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, 
               DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice, 
               EtcHalfPrice, EtcMonthPrice, @UserSeq, GETDATE(), @UserSeq, 
               GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock3 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
 
