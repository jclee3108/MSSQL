  
IF OBJECT_ID('KPXCM_SPDProdProcSave') IS NOT NULL   
    DROP PROC KPXCM_SPDProdProcSave 
GO  
  
-- v2016.03.07 
  
-- 제품별생산소요등록-저장 by 이재천  
CREATE PROC KPXCM_SPDProdProcSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPDProdProc (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDProdProc'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDProdProc')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDProdProc'    , -- 테이블명        
                  '#KPX_TPDProdProc'    , -- 임시 테이블명        
                  'ItemSeq,PatternRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDProdProc WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PatternName    = A.PatternName,  
               B.UseYn          = A.UseYn,  
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE()
        
          FROM #KPX_TPDProdProc AS A   
          JOIN KPX_TPDProdProc  AS B ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND A.PatternRev = B.PatternRev )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    SELECT * FROM #KPX_TPDProdProc   
      
    RETURN  