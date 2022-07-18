  
IF OBJECT_ID('KPX_SPDQCRequestInsPurchaseSave') IS NOT NULL   
    DROP PROC KPX_SPDQCRequestInsPurchaseSave  
GO  
  
-- v2015.01.15  
  
-- 수입검사의뢰-저장 by 이재천 
CREATE PROC KPX_SPDQCRequestInsPurchaseSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TQCTestRequest( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestRequest'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPX_TQCTestRequestItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestRequestItem'   
    IF @@ERROR <> 0 RETURN      
    
    --ALTER TABLE #KPX_TQCTestRequest ADD SourceSeq INT NULL 
    UPDATE A
       SET SMSourceType = 1000522008 
      FROM #KPX_TQCTestRequestItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    
    UPDATE A 
       SET ReqSeq = B.ReqSeq 
      FROM #KPX_TQCTestRequest AS A 
      OUTER APPLY (SELECT TOP 1 ReqSeq 
                     FROM KPX_TQCTestRequestItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.SourceSeq = A.DelvSeq 
                      AND Z.SMSourceType = 1000522008 
                  ) AS B 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequest WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestRequest') 
            
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TQCTestRequest'    , -- 테이블명        
              '#KPX_TQCTestRequest'    , -- 임시 테이블명        
              'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        DELETE B   
          FROM #KPX_TQCTestRequest AS A   
          JOIN KPX_TQCTestRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequestItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestRequestItem')    
        
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TQCTestRequestItem'    , -- 테이블명        
              '#KPX_TQCTestRequestItem'    , -- 임시 테이블명        
              'SourceSeq,SourceSerl,SMSourceType'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , 'DelvSeq,DelvSerl,SMSourceType', @PgmSeq  -- 테이블 모든 필드명 
        
        DELETE B   
          FROM #KPX_TQCTestRequestItem AS A   
          JOIN KPX_TQCTestRequestItem AS B ON ( B.CompanySeq = @CompanySeq AND A.DelvSeq = B.SourceSeq AND A.DelvSerl = B.SourceSerl AND B.SMSourceType = A.SMSourceType ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- UPDATE 
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequest WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN    
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestRequest')    
        
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TQCTestRequest'    , -- 테이블명        
              '#KPX_TQCTestRequest'    , -- 임시 테이블명        
              'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B 
           SET B.BizUnit = A.BizUnit, 
               B.DeptSeq = A.DeptSeq, 
               B.EmpSeq = A.EmpSeq, 
               B.CustSeq = A.CustSeq,
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE() 
          FROM #KPX_TQCTestRequest AS A   
          JOIN KPX_TQCTestRequest AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END 
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequestItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN    
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestRequestItem') 
        
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_TQCTestRequestItem'    , -- 테이블명        
              '#KPX_TQCTestRequestItem'    , -- 임시 테이블명        
              'SourceSeq,SourceSerl,SMSourceType'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , 'DelvSeq,DelvSerl,SMSourceType', @PgmSeq  -- 테이블 모든 필드명 
                
        UPDATE B 
           SET B.ItemSeq = A.ItemSeq, 
               B.LotNo = A.LotNo, 
               B.WHSeq = A.WHSeq, 
               B.UnitSeq = A.UnitSeq, 
               B.ReqQty = A.Qty, 
               B.Remark = A.Remark, 
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE() 
          FROM #KPX_TQCTestRequestItem AS A   
          JOIN KPX_TQCTestRequestItem AS B ON ( B.CompanySeq = @CompanySeq AND A.DelvSeq = B.SourceSeq AND A.DelvSerl = B.SourceSerl AND B.SMSourceType = A.SMSourceType ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
    END   
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequest WHERE WorkingTag = 'A' AND Status = 0 )    
       AND EXISTS ( SELECT 1 
                      FROM #KPX_TQCTestRequestItem AS A   
                      JOIN KPX_TQCQAProcessQCType AS B ON ( B.CompanySeq = @CompanySeq AND B.InQC = 1000498001 ) 
                      JOIN KPX_TQCQASpec          AS C ON ( C.CompanySeq = @CompanySeq AND C.QCType = B.QCType AND C.ItemSeq = A.ItemSeq ) 
                      JOIN KPX_TQcInReceiptItem   AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSEq = A.ItemSeq AND D.IsInQC = '1' ) 
                     WHERE A.WorkingTag = 'A'   
                       AND A.Status = 0      
                  )
    
    BEGIN    
          
        INSERT INTO KPX_TQCTestRequest  
        (   
            CompanySeq,     ReqSeq,     BizUnit,        ReqDate,        ReqNo, 
            DeptSeq,        EmpSeq,     CustSeq,        LastUserSeq,    LastDateTime 
        ) 
        SELECT @CompanySeq,     A.ReqSeq,       A.BizUnit,      CONVERT(NCHAR(8),GETDATE(),112),    A.ReqNo,             
               A.DeptSeq,       A.EmpSeq,       A.CustSeq,      @UserSeq,                           GETDATE()
          FROM #KPX_TQCTestRequest AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END    
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCTestRequestItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        DECLARE @MaxSerl INT 
        
        SELECT @MaxSerl = (SELECT MAX(ReqSerl) FROM KPX_TQCTestRequestItem WHERE CompanySeq = @CompanySeq AND ReqSeq = (SELECT TOP 1 ReqSeq FROM #KPX_TQCTestRequestItem WHERE WorkingTag = 'A'))
        
        INSERT INTO KPX_TQCTestRequestItem  
        (   
            CompanySeq,     ReqSeq,     ReqSerl,        QCType,         ItemSeq, 
            LotNo,          WHSeq,      UnitSeq,        ReqQty,         Remark, 
            SMSourceType,   SourceSeq,  SourceSerl,     LastUserSeq,    LastDateTime
        )   
        SELECT @CompanySeq,     A.ReqSeq,       ROW_NUMBER()OVER(ORDER BY B.QCType) + ISNULL(@MaxSerl,0),     B.QCType,        A.ItemSeq,             
               A.LotNo,         A.WHSeq,        A.UnitSeq,     A.Qty,           A.Remark, 
               A.SMSourceType,  A.DelvSeq,      A.DelvSerl,  @UserSeq,        GETDATE()
          FROM #KPX_TQCTestRequestItem AS A   
          JOIN KPX_TQCQAProcessQCType AS B ON ( B.CompanySeq = @CompanySeq AND B.InQC = 1000498001 ) 
          CROSS APPLY (SELECT TOP 1 QCType 
                         FROM KPX_TQCQASpec AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN Z.SDate AND Z.EDate  
                          AND Z.QCType = B.QCType 
                          AND Z.ItemSeq = A.ItemSeq 
                      ) AS C 
          JOIN KPX_TQcInReceiptItem   AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSEq = A.ItemSeq AND D.IsInQC = '1' ) 
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TQCTestRequest
    SELECT * FROM #KPX_TQCTestRequestItem   
      
    RETURN  
GO 