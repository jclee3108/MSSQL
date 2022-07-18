
IF OBJECT_ID('jongie_SCOMEnvItemSave') IS NOT NULL
    DROP PROC jongie_SCOMEnvItemSave
GO
    
-- v2013.08.07   
  
-- (종이나라) 추가개발 Mapping정보 설정_jongie-저장 by 김철웅 (copy 이재천)      
CREATE PROC jongie_SCOMEnvItemSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    CREATE TABLE #jongie_TCOMEnvItem (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#jongie_TCOMEnvItem'     
    IF @@ERROR <> 0 RETURN      
        
    -- 로그 남기기      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('jongie_TCOMEnvItem')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'jongie_TCOMEnvItem'    , -- 테이블명          
                  '#jongie_TCOMEnvItem'    , -- 임시 테이블명          
                  'ItemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , 'ItemSeqOld', @PgmSeq  -- 테이블 모든 필드명     
      
    -- 작업순서 : UPDATE -> INSERT    
      
    -- UPDATE        
    IF EXISTS ( SELECT TOP 1 1 FROM #jongie_TCOMEnvItem WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
          
        UPDATE B     
           SET B.ItemSeq      = A.ItemSeq,    
               B.LastUserSeq  = @UserSeq,    
               B.LastDateTime = GETDATE(),    
               B.PgmSeq       = @PgmSeq      
          FROM #jongie_TCOMEnvItem AS A     
          JOIN jongie_TCOMEnvItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ItemSeqOld = B.ItemSeq )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
           AND ISNULL(A.ItemSeq,0) <> 0   
          
        IF @@ERROR <> 0  RETURN    
          
        DELETE B   
          FROM #jongie_TCOMEnvItem AS A     
          JOIN jongie_TCOMEnvItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ItemSeqOld = B.ItemSeq )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
           AND ISNULL(A.ItemSeq,0) = 0   
          
        IF @@ERROR <> 0  RETURN    
          
    END      
        
    -- INSERT    
    IF EXISTS ( SELECT TOP 1 1 FROM #jongie_TCOMEnvItem WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
          
        INSERT INTO jongie_TCOMEnvItem    
        (     
            CompanySeq, ItemSeq, LastUserSeq, LastDateTime, PgmSeq     
        )     
        SELECT @CompanySeq, A.ItemSeq, @UserSeq, GETDATE(), @PgmSeq     
          FROM #jongie_TCOMEnvItem AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
           AND ISNULL(A.ItemSeq,0) <> 0   
          
        IF @@ERROR <> 0 RETURN    
          
    END       
      
    -- Old값 따기   
    UPDATE A     
       SET A.ItemSeqOld = A.ItemSeq,    
           A.ItemName = (CASE WHEN ISNULL(A.ItemSeq,0) = 0 THEN NULL ELSE A.ItemName END),  
           A.ItemNo = (CASE WHEN ISNULL(A.ItemSeq,0) = 0 THEN NULL ELSE A.ItemNo END),  
           A.Spec = (CASE WHEN ISNULL(A.ItemSeq,0) = 0 THEN NULL ELSE A.Spec END)  
             
      FROM #jongie_TCOMEnvItem AS A     
     WHERE A.Status = 0        
      
    SELECT * FROM #jongie_TCOMEnvItem     
      
    RETURN    