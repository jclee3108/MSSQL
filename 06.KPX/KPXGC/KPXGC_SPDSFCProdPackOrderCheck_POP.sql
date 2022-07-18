
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrderCheck_POP') IS NOT NULL 
    DROP PROC KPXGC_SPDSFCProdPackOrderCheck_POP 
GO 

-- v2015.08.21 

-- 포장작업지시 연동체크 by이재천 
CREATE PROC KPXGC_SPDSFCProdPackOrderCheck_POP  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDSFCWorkOrder_POP( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCWorkOrder_POP'   
    IF @@ERROR <> 0 RETURN  
    
    IF (SELECT TOP 1 IsCfm FROM #KPX_TPDSFCWorkOrder_POP) = '0' 
    BEGIN
        
        UPDATE A 
           SET Result = 'POP에서 작업이 진행되어 확정을 취소 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TPDSFCWorkOrder_POP AS A 
          JOIN [POP_GC].AIRMES.KPXGC.V_SCHTT_WORKORDER_STATUS AS B ON ( B.SITECODE = @CompanySeq AND B.WORKID = A.PackOrderSeq AND B.Status = 2013070200018 ) 
    
    END 
    
    SELECT * FROM #KPX_TPDSFCWorkOrder_POP 
    
    RETURN  
  