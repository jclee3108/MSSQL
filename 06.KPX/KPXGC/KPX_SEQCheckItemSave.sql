  
IF OBJECT_ID('KPX_SEQCheckItemSave') IS NOT NULL   
    DROP PROC KPX_SEQCheckItemSave  
GO  
  
-- v2014.10.30  
  
-- 점검설비등록-저장 by 이재천   
CREATE PROC KPX_SEQCheckItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TEQCheckItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQCheckItem'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQCheckItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEQCheckItem'    , -- 테이블명        
                  '#KPX_TEQCheckItem'    , -- 임시 테이블명        
                  'ToolSeq,UMCheckTerm'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'ToolSeq,UMCheckTermOld', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TEQCheckItem AS A   
          JOIN KPX_TEQCheckItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq AND B.UMCheckTerm = A.UMCheckTermOld )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.CheckKind = A.CheckKind,
               B.UMCheckTerm = A.UMCheckTerm,   
               B.CheckItem = A.CheckItem,  
               B.SMInputType = A.SMInputType,  
               B.CodeHelpConst = A.CodeHelpConst, 
               B.CodeHelpParams = A.CodeHelpParams, 
               B.Mask = A.Mask, 
               B.Remark = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
                 
          FROM #KPX_TEQCheckItem AS A   
          JOIN KPX_TEQCheckItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq AND B.UMCheckTerm = A.UMCheckTermOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEQCheckItem  
        (   
            CompanySeq,ToolSeq,UMCheckTerm,CheckKind,CheckItem,  
            SMInputType,CodeHelpConst,CodeHelpParams,Remark,LastUserSeq,
            LastDateTime, Mask
        )   
        SELECT @CompanySeq,A.ToolSeq,A.UMCheckTerm,A.CheckKind,A.CheckItem,  
               A.SMInputType,A.CodeHelpConst,A.CodeHelpParams,A.Remark,@UserSeq,
               GETDATE(), A.Mask 
          FROM #KPX_TEQCheckItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A
       SET UMCheckTermOld = UMCheckTerm
      FROM #KPX_TEQCheckItem AS A 
      
    SELECT * FROM #KPX_TEQCheckItem   
    
    RETURN  
      