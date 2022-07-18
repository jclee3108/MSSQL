  
IF OBJECT_ID('KPX_SPRPayRetEstSave') IS NOT NULL   
    DROP PROC KPX_SPRPayRetEstSave  
GO  
  
-- v2014.12.15  
  
-- 급여추정 퇴직금추계액등록-저장 by 이재천   
CREATE PROC KPX_SPRPayRetEstSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPRPayRetEst (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRPayRetEst'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRPayRetEst')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRPayRetEst'    , -- 테이블명        
                  '#KPX_TPRPayRetEst'    , -- 임시 테이블명        
                  'YY,EmpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'YY,EmpSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayRetEst WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPRPayRetEst AS A   
          JOIN KPX_TPRPayRetEst AS B ON ( B.CompanySeq = @CompanySeq AND A.YY = B.YY AND A.EmpSeqOld = B.EmpSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
    
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayRetEst WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.EmpSeq = A.EmpSeq, 
               B.RetEstAmt = A.RetEstAmt, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TPRPayRetEst AS A   
          JOIN KPX_TPRPayRetEst AS B ON ( B.CompanySeq = @CompanySeq AND A.YY = B.YY AND A.EmpSeqOld = B.EmpSeq ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRPayRetEst WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPRPayRetEst  
        (   
            CompanySeq, YY, EmpSeq, RetEstAmt, Remark, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.YY, A.EmpSeq, A.RetEstAmt, A.Remark, 
               @UserSeq, GETDATE()
          FROM #KPX_TPRPayRetEst AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    UPDATE A 
       SET EmpSeqOld = EmpSeq 
      FROM #KPX_TPRPayRetEst AS A 
    
    SELECT * FROM #KPX_TPRPayRetEst   
    
    RETURN  