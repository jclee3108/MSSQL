
IF OBJECT_ID('KPXCM_SPDSFCWorkReportPOPIFERPSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkReportPOPIFERPSave  
GO  
  
-- v2015.11.18 
  
-- 생산실적반영(POP)-ERP실적반영 by 이재천 
CREATE PROC KPXCM_SPDSFCWorkReportPOPIFERPSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0
AS    
      
    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'   
    IF @@ERROR <> 0 RETURN    
    
    ALTER TABLE #Temp ADD Cnt INT NULL 
    
    --SELECT A.Seq, A.IDX_NO, A.DataSeq, A.Cnt, B.Cnt 
    UPDATE A 
       SET A.Cnt = B.Cnt 
      FROM #Temp AS A 
      JOIN (
            SELECT IDX_NO, ROW_NUMBER() OVER(Order by A.Seq) AS Cnt 
              FROM #Temp AS A 
           ) AS B ON ( A.IDX_NO = B.IDX_NO ) 
    
    ------------------------------------------------------------------------
    -- 체크1, 이미 처리된 데이터가 존재합니다.
    ------------------------------------------------------------------------
    UPDATE A 
       SET Result = '이미 처리된 데이터가 존재합니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #Temp AS A 
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
     WHERE A.Status = 0 
       AND B.ProcYn = '1' 
    ------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------

    ------------------------------------------------------------------------
    -- 체크2, 이전 데이터(같은 실적)가 처리되지 않았습니다.
    ------------------------------------------------------------------------
    UPDATE A
       SET Result = '이전 데이터(같은 실적)가 처리되지 않았습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #Temp AS A 
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.IFWorkReportSeq = A.IFWorkReportSeq AND B.Seq < A.Seq AND B.ProcYn <> '1' AND B.IsPacking = '0' ) 
     WHERE B.Seq NOT IN (SELECT Seq FROM #Temp) 
       AND A.Status = 0 
    ------------------------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------------------------
    
    
    IF EXISTS (SELECT 1 FROM #Temp WHERE Status <> 0) 
    BEGIN
        SELECT * FROM #Temp 
        RETURN 
    END 
    
    DECLARE @Cnt        INT, 
            @MaxCnt     INT, 
            @Seq        INT,
            @Status     INT, 
            @Result     NVARCHAR(500),
            @MessageType INT 
            
            
    SELECT @Cnt = 1 
    SELECT @MaxCnt = ( SELECT MAX(Cnt) FROM #Temp )
    
    
    IF ISNULL(@MaxCnt,0) = 0 
    BEGIN
        SELECT * FROM #Temp
        RETURN 
    END 
    
    
    WHILE( 1 = 1 ) 
    BEGIN
    
        SELECT @Seq = Seq 
          FROM #Temp AS A 
         WHERE A.Cnt = @Cnt 
        
    
        EXEC KPXCM_SPDSFCWorkReportSub_POP 2, @Seq, @Status OUTPUT, @Result OUTPUT, @MessageType OUTPUT 

        
        IF ISNULL(@Status,0) = 0 
        BEGIN 
        
            exec KPXCM_SPDSFCWorkReportExceptSub_POP 2, @Seq
            
        END 

        
        UPDATE A 
           SET Status = @Status, 
               Result = @Result, 
               MessageType = @MessageType
          FROM #Temp AS A 
         WHERE Cnt = @Cnt 
        
        
        
        
        
        IF @Cnt >= ISNULL(@MaxCnt,0)
        BEGIN
            BREAK 
        END 
        ELSE 
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
        
        
    END 
    
    SELECT B.ErrorMessage, B.ProcYn , B.WorkReportSeq, A.* 
      FROM #Temp AS A 
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
    
    
    RETURN  
    GO
    begin tran 
exec KPXCM_SPDSFCWorkReportPOPIFERPSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IFWorkReportSeq>2015110200026</IFWorkReportSeq>
    <Seq>1000029382</Seq>
    <WorkOrderSeq>100656</WorkOrderSeq>
    <WorkOrderSerl>100656</WorkOrderSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IFWorkReportSeq>2015110200026</IFWorkReportSeq>
    <Seq>1000030026</Seq>
    <WorkOrderSeq>100656</WorkOrderSeq>
    <WorkOrderSerl>100656</WorkOrderSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IFWorkReportSeq>2015110200026</IFWorkReportSeq>
    <Seq>1000030028</Seq>
    <WorkOrderSeq>100656</WorkOrderSeq>
    <WorkOrderSerl>100656</WorkOrderSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033251,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027544
rollback 




--select * from KPX_TPDSFCWorkReport_POP where IFWorkReportSeq = 2015111700109
--select * from KPX_TPDSFCworkReportExcept_POP where ReportSeq = 1000035515