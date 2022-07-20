  
IF OBJECT_ID('mnpt_SPRWkEmpRepWkConfirmSave') IS NOT NULL   
    DROP PROC mnpt_SPRWkEmpRepWkConfirmSave  
GO  
    
-- v2018.01.23
  
-- 휴일근무신청확정-저장 by 이재천
CREATE PROC mnpt_SPRWkEmpRepWkConfirmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #mnpt_TPREEWkEmpRepWk (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TPREEWkEmpRepWk'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPREEWkEmpRepWk')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPREEWkEmpRepWk'    , -- 테이블명        
                  '#mnpt_TPREEWkEmpRepWk'    , -- 임시 테이블명        
                  'EmpSeq, RepWkSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TPREEWkEmpRepWk WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WkMoney        = A.WkMoney,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #mnpt_TPREEWkEmpRepWk AS A   
          JOIN mnpt_TPREEWkEmpRepWk AS B ON ( B.CompanySeq = @CompanySeq AND A.EmpSeq = B.EmpSeq AND A.RepWkSeq = B.RepWkSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    SELECT * FROM #mnpt_TPREEWkEmpRepWk   
      
    RETURN  
