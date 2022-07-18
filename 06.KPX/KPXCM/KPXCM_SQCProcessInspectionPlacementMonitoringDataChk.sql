IF OBJECT_ID('KPXCM_SQCProcessInspectionPlacementMonitoringDataChk') IS NOT NULL 
    DROP PROC KPXCM_SQCProcessInspectionPlacementMonitoringDataChk
GO 

-- v2016.05.03 

CREATE PROC KPXCM_SQCProcessInspectionPlacementMonitoringDataChk
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    CREATE TABLE #KPX_TQCProcessInspection(WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCProcessInspection'
    
    
    INSERT INTO KPXCM_TQCTestResultMonitoring 
    (
        CompanySeq, QCSeq, UserSeq, LastUserSeq, LastDateTime, PgmSeq
    )
    SELECT DISTINCT @CompanySeq, A.QCSeq, @UserSeq, @UserSeq, GETDATE(), @PgmSeq 
      FROM #KPX_TQCProcessInspection AS A
     WHERE A.Status = 0  
       AND NOT EXISTS (SELECT 1 FROM KPXCM_TQCTestResultMonitoring WHERE CompanySeq = @CompanySeq AND QCSeq = A.QCSeq AND UserSeq = @UserSeq) 
    
    SELECT * FROM #KPX_TQCProcessInspection
    
    RETURN 
GO



