  
IF OBJECT_ID('mnpt_SPJTEECNTRReportListSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEECNTRReportListSave  
GO  
    
-- v2017.11.07
  
-- 컨테이너실적조회-저장 by 이재천   
CREATE PROC mnpt_SPJTEECNTRReportListSave  
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTEECNTRReport')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTEECNTRReport'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'CNTRReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEECNTRReport    AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTEECNTRReport_IF AS B ON ( B.CompanySeq = @CompanySeq AND A.CNTRReportSeq = B.CNTRReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    RETURN  
