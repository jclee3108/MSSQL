  
IF OBJECT_ID('KPX_SQCCOAPrintSave') IS NOT NULL   
    DROP PROC KPX_SQCCOAPrintSave  
GO  
  
-- v2014.12.18  
  
-- 시험성적서발행(COA)-저장 by 이재천   
CREATE PROC KPX_SQCCOAPrintSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCCOAPrint (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCCOAPrint'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCCOAPrint')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQCCOAPrint'    , -- 테이블명        
                  '#KPX_TQCCOAPrint'    , -- 임시 테이블명        
                  'COASeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    /* 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCCOAPrint WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TQCCOAPrint AS A   
          JOIN KPX_TQCCOAPrint AS B ON ( B.CompanySeq = @CompanySeq AND B.COASeq = A.COASeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    */
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCCOAPrint WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.CustSeq = A.CustSeq,  
               B.ItemSeq = A.ItemSeq,  
               B.LotNo = A.LotNo,  
               B.QCType = A.QCType,  
               B.ShipDate = A.ShipDate,  
               B.COACount = A.COACount,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_TQCCOAPrint AS A   
          JOIN KPX_TQCCOAPrint AS B ON ( B.CompanySeq = @CompanySeq AND B.COASeq = A.COASeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCCOAPrint WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TQCCOAPrint  
        (   
            CompanySeq,COASeq,CustSeq,ItemSeq,LotNo,  
            QCType,ShipDate,COADate,COANo,COACount,  
            IsPrint,QCSeq, KindSeq, LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.COASeq,A.CustSeq,A.ItemSeq,A.LotNo,  
               A.QCType,A.ShipDate,CONVERT(NCHAR(8), GETDATE(), 112) , A.COANo, A.COACount,  
               '0',A.QCSeq, KindSeq, @UserSeq,GETDATE()
          FROM #KPX_TQCCOAPrint AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
        
        UPDATE A 
           SET COADate = CONVERT(NCHAR(8), GETDATE(), 112)
          FROM #KPX_TQCCOAPrint AS A 
    END     
    
    
    
    SELECT * FROM #KPX_TQCCOAPrint   
      
    RETURN  