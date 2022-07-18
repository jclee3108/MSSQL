  
IF OBJECT_ID('KPX_SPDItemWCStdSave') IS NOT NULL   
    DROP PROC KPX_SPDItemWCStdSave  
GO  
  
-- v2014.09.25  
  
-- 제품별설비기준등록-저장 by 이재천   
CREATE PROC KPX_SPDItemWCStdSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPDItemWCStd (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDItemWCStd'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDItemWCStd')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDItemWCStd'    , -- 테이블명        
                  '#KPX_TPDItemWCStd'    , -- 임시 테이블명        
                  'ItemSeq,WorkCenterSeq,ProcSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'ItemSeqSub,WorkCenterSeqOld,ProcSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDItemWCStd WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TPDItemWCStd AS A   
          JOIN KPX_TPDItemWCStd AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeqSub AND B.WorkCenterSeq = A.WorkCenterSeqOld AND B.ProcSeq = A.ProcSeqOld )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDItemWCStd WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WorkCenterSeq = A.WorkCenterSeq,  
               B.ProcSeq = A.ProcSeq,  
               B.WCCapacity = A.WCCapacity,  
               B.Gravity = A.Gravity,  
               B.IsUse = A.IsUse,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
          FROM #KPX_TPDItemWCStd AS A   
          JOIN KPX_TPDItemWCStd AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeqSub AND B.WorkCenterSeq = A.WorkCenterSeqOld AND B.ProcSeq = A.ProcSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDItemWCStd WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPDItemWCStd  
        (   
            CompanySeq,ItemSeq,WorkCenterSeq,ProcSeq,StdProdTime,  
            WCCapacity,Gravity,IsUse,LastUserSeq,LastDateTime  
               
        )   
        SELECT @CompanySeq,A.ItemSeqSub,A.WorkCenterSeq,A.ProcSeq,A.StdProdTime,  
               A.WCCapacity,A.Gravity,A.IsUse,@UserSeq,GETDATE()  
                  
          FROM #KPX_TPDItemWCStd AS A   
           WHERE A.WorkingTag =  'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET WorkCenterSeqOld = WorkCenterSeq, 
           ProcSeqOld = ProcSeq 
      FROM #KPX_TPDItemWCStd AS A 
    
    SELECT * FROM #KPX_TPDItemWCStd   
      
    RETURN  