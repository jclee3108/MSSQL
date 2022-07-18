  
IF OBJECT_ID('KPX_SQCShipmentInspectionRequestSave') IS NOT NULL   
    DROP PROC KPX_SQCShipmentInspectionRequestSave  
GO  
  
-- v2014.12.11  
  
-- 출하검사의뢰(탱크로리)-저장 by 이재천   
CREATE PROC KPX_SQCShipmentInspectionRequestSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCShipmentInspectionRequest (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCShipmentInspectionRequest'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCShipmentInspectionRequest')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TQCShipmentInspectionRequest'    , -- 테이블명        
                  '#KPX_TQCShipmentInspectionRequest'    , -- 임시 테이블명        
                  'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCShipmentInspectionRequest WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TQCShipmentInspectionRequest AS A   
          JOIN KPX_TQCShipmentInspectionRequest AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCShipmentInspectionRequest WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ReqDate = A.ReqDate,  
               B.ReqNo = A.ReqNo,  
               B.QCType = A.QCType,  
               B.ItemSeq = A.ItemSeq,  
               B.LotNo = A.LotNo,  
               B.Qty = A.Qty,  
               B.UnitSeq = A.UnitSeq,  
               B.CustSeq = A.CustSeq,  
               B.EmpSeq = A.EmpSeq,  
               B.DeptSeq = A.DeptSeq,  
               B.Remark = A.Remark,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
                 
          FROM #KPX_TQCShipmentInspectionRequest AS A   
          JOIN KPX_TQCShipmentInspectionRequest AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCShipmentInspectionRequest WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TQCShipmentInspectionRequest  
        (   
            CompanySeq,ReqSeq,ReqDate,ReqNo,QCType,  
            ItemSeq,LotNo,Qty,UnitSeq,CustSeq,  
            EmpSeq,DeptSeq,Remark,IsStop,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.ReqSeq,A.ReqDate,A.ReqNo,A.QCType,  
               A.ItemSeq,A.LotNo,A.Qty,A.UnitSeq,A.CustSeq,  
               A.EmpSeq,A.DeptSeq,A.Remark,'0',@UserSeq,  
               GETDATE()   
          FROM #KPX_TQCShipmentInspectionRequest AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TQCShipmentInspectionRequest   
      
    RETURN  