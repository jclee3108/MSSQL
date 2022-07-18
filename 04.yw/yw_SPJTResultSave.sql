  
IF OBJECT_ID('yw_SPJTResultSave') IS NOT NULL   
    DROP PROC yw_SPJTResultSave  
GO  
  
 --v2014.07.02  
  
-- 프로젝트실적입력_YW(저장) by 이재천   
CREATE PROC yw_SPJTResultSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #yw_TPJTWBSResult (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTWBSResult'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('yw_TPJTWBSResult')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'yw_TPJTWBSResult'    , -- 테이블명        
                  '#yw_TPJTWBSResult'    , -- 임시 테이블명        
                  'PJTSeq,UMWBSSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTWBSResult WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #yw_TPJTWBSResult AS A   
          JOIN yw_TPJTWBSResult AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWBSSeq = A.UMWBSSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
    
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTWBSResult WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        UPDATE B   
           SET B.TargetDate = A.TargetDate,  
               B.BegDate = A.BegDate,  
               B.EndDate = A.EndDate,  
               B.ChgDate = A.ChgDate,  
               B.Results = A.Results,  
               B.FileSeq = A.FileSeq,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
          FROM #yw_TPJTWBSResult AS A   
          JOIN yw_TPJTWBSResult AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.UMWBSSeq = A.UMWBSSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TPJTWBSResult WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO yw_TPJTWBSResult  
        (   
            CompanySeq, PJTSeq, UMWBSSeq, TargetDate, BegDate,  
            EndDate, ChgDate, Results, FileSeq, LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.PJTSeq,A.UMWBSSeq,A.TargetDate,A.BegDate,  
               A.EndDate,A.ChgDate,A.Results,A.FileSeq,@UserSeq,  
               GETDATE()   
          FROM #yw_TPJTWBSResult AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
      END     
    
    SELECT * FROM #yw_TPJTWBSResult   
      
    RETURN  
    
    
    