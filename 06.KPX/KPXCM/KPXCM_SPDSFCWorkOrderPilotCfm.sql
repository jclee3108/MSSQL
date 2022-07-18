
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotCfm') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotCfm  
GO  
  
-- v2016.03.02
  
-- 긴급작업지시입력-확정 저장 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotCfm  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCWorkOrderPilot (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDSFCWorkOrderPilot'   
    IF @@ERROR <> 0 RETURN    
     
    --IF @WorkingTag = 'Cfm' 
    --BEGIN 
    --    UPDATE #KPXCM_TPDSFCWorkOrderPilot
    --       SET WorkingTag = 'A'    
    --END 
    --ELSE
    --BEGIN 
    --    UPDATE #KPXCM_TPDSFCWorkOrderPilot
    --       SET WorkingTag = 'D'
    --END 
    
    
    --------------------------------------------------------------------------------------------------
    -- 생산계획     
    --------------------------------------------------------------------------------------------------
    DECLARE @XmlData NVARCHAR(MAX)
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                SELECT A.WorkingTag AS WorkingTag, 
                                                       A.IDX_NO AS IDX_NO, 
                                                       1 AS DataSeq, 
                                                       0 AS Status, 
                                                       3 AS FactUnit, 
                                                       B.WorkCenterSeq, 
                                                       '00' AS BOMRev, 
                                                       0 AS DeptSeq, 
                                                       B.ItemSeq, 
                                                       '00' AS ProcRev, 
                                                       0 AS ProdDeptSeq, 
                                                       B.SrtDate AS ProdPlanDate, 
                                                       '' AS ProdPlanNo, 
                                                       B.ProdQty AS ProdPlanQty, 
                                                       B.ProdPlanSeq, 
                                                       B.Remark, 
                                                       '' AS StockInDate, 
                                                       C.UnitSeq, 
                                                       REPLACE(B.SrtHour,':','') AS WorkCond1, 
                                                       REPLACE(B.EndHour,':','') AS WorkCond2, 
                                                       0 AS WorkCond3, 
                                                       0 AS WorkCond4, 
                                                       B.PatternSeq AS WorkCond6, 
                                                       0 AS WorkCond7, 
                                                       B.SrtDate, 
                                                       B.EndDate, 
                                                       0 AS NodeID
                                                       
                                                  FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
                                                  JOIN KPXCM_TPDSFCWorkOrderPilot   AS B ON ( B.CompanySeq = @CompanySeq AND B.PilotSeq = A.PilotSeq ) 
                                                  LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
                                                  FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS    
                                                  
                                             )  
                             )  
    
    

    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 1030617, 'DataBlock1', '#Temp'           
    
    -- 생산계획 체크 
    INSERT INTO #Temp 
    EXEC KPXCM_SPDMPSProdPlanPilotCheck  @xmlDocument = @XmlData,  
                                         @xmlFlags = 2,  
                                         @ServiceSeq = 1030617,   
                                         @WorkingTag = N'',  
                                         @CompanySeq = @CompanySeq,   
                                         @LanguageSeq = 1,   
                                         @UserSeq = @UserSeq,   
                                         @PgmSeq = @PgmSeq   
    
    --select * from #Temp 
    --return 
    UPDATE A 
       SET Result = B.Result, 
           Status = B.Status, 
           MessageType = B.MessageType 
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN #Temp                        AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    
    IF EXISTS ( SELECT 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE Status <> 0 ) 
    BEGIN 
        SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
        RETURN 
    END 
    
    
    
    
    SELECT @XmlData = ''

    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                SELECT A.WorkingTag, 
                                                       A.IDX_NO, 
                                                       A.DataSeq, 
                                                       A.Status, 
                                                       A.FactUnit, 
                                                       A.WorkCenterSeq, 
                                                       A.BOMRev, 
                                                       A.DeptSeq, 
                                                       A.ItemSeq, 
                                                       A.ProcRev, 
                                                       A.ProdDeptSeq, 
                                                       A.ProdPlanDate, 
                                                       A.ProdPlanNo, 
                                                       A.ProdPlanQty, 
                                                       A.ProdPlanSeq, 
                                                       A.Remark, 
                                                       A.StockInDate, 
                                                       A.UnitSeq, 
                                                       A.WorkCond1, 
                                                       A.WorkCond2, 
                                                       A.WorkCond3, 
                                                       A.WorkCond4, 
                                                       A.WorkCond6, 
                                                       A.WorkCond7, 
                                                       A.SrtDate, 
                                                       A.EndDate
                                                  FROM #Temp AS A
                                                  FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS    
                                                  
                                             )  
                             )  
    
    

    CREATE TABLE #Temp2 (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 1030617, 'DataBlock1', '#Temp2'           
    
    ALTER TABLE #Temp2 ADD StdProdQty DECIMAL(19,5)
    ALTER TABLE #Temp2 ADD StdUnitSeq INT
    ALTER TABLE #Temp2 ADD OldQty DECIMAL(19,5)
    
    -- 생산계획 저장 
    INSERT INTO #Temp2 
    EXEC KPXCM_SPDMPSProdPlanPilotSave  @xmlDocument = @XmlData,  
                                        @xmlFlags = 2,  
                                        @ServiceSeq = 1030617,   
                                        @WorkingTag = N'',  
                                        @CompanySeq = @CompanySeq,   
                                        @LanguageSeq = 1,   
                                        @UserSeq = @UserSeq,   
                                        @PgmSeq = @PgmSeq   
    
    UPDATE A 
       SET Result = B.Result, 
           Status = B.Status, 
           MessageType = B.MessageType, 
           ProdPlanSeq = B.ProdPlanSeq 
           
      FROM #KPXCM_TPDSFCWorkOrderPilot  AS A 
      JOIN #Temp2                       AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    
    IF EXISTS ( SELECT 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE Status <> 0 ) 
    BEGIN 
        SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
        RETURN 
    END 
    
    --------------------------------------------------------------------------------------------------
    -- 생산계획, END 
    --------------------------------------------------------------------------------------------------
    
    
    IF EXISTS (SELECT 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE WorkingTag = 'A')
    BEGIN 
        --------------------------------------------------------------------------------------------------
        -- 작업지시 
        --------------------------------------------------------------------------------------------------
        CREATE TABLE #TPDSFCWorkOrder  (WorkingTag NCHAR(1) NULL)        
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 1030923, 'DataBlock1', '#TPDSFCWorkOrder'           
        
        ALTER TABLE #TPDSFCWorkOrder ADD ProdPlanSeq INT NULL 
        ALTER TABLE #TPDSFCWorkOrder ADD AfterWorkSeq INT NULL 
        
        INSERT INTO #TPDSFCWorkOrder ( WorkingTag, IDX_NO, DataSeq, Status, ProdPlanSeq, AfterWorkSeq ) 
        SELECT A.WorkingTag, 
               A.IDX_NO, 
               A.DataSeq, 
               A.Status, 
               A.ProdPlanSeq, 
               B.AfterWorkSeq
          FROM #Temp AS A 
          JOIN #KPXCM_TPDSFCWorkOrderPilot AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
    
        -- 작업지시 체크 
        EXEC KPXCM_SPDWorkOrderCfmPilotCheck    @xmlDocument = '',  
                                                @xmlFlags = 2,  
                                                @ServiceSeq = 1030923,   
                                                @WorkingTag = N'',  
                                                @CompanySeq = @CompanySeq,   
                                                @LanguageSeq = 1,   
                                                @UserSeq = @UserSeq,   
                                                @PgmSeq = @PgmSeq   
        
        

        
        UPDATE A 
           SET Result = B.Result, 
               Status = B.Status, 
               MessageType = B.MessageType
               
          FROM #KPXCM_TPDSFCWorkOrderPilot    AS A 
          JOIN #TPDSFCWorkOrder               AS B ON ( B.IDX_NO = A.IDX_NO ) 
        
        
        
        IF EXISTS ( SELECT 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE Status <> 0 ) 
        BEGIN 
            SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
            RETURN 
        END 

    --select * From #TPDSFCWorkOrder 
    --return 
        
        -- 작업지시 저장 
        EXEC KPXCM_SPDWorkOrderCfmPilotSave @xmlDocument = '',  
                                            @xmlFlags = 2,  
                                            @ServiceSeq = 1030923,   
                                            @WorkingTag = N'',  
                                            @CompanySeq = @CompanySeq,   
                                            @LanguageSeq = 1,   
                                            @UserSeq = @UserSeq,   
                                            @PgmSeq = @PgmSeq   
    
        UPDATE A 
           SET Result = B.Result, 
               Status = B.Status, 
               MessageType = B.MessageType, 
               WorkOrderSeq = C.WorkOrderSeq 
          FROM #KPXCM_TPDSFCWorkOrderPilot    AS A 
          JOIN #TPDSFCWorkOrder               AS B ON ( B.IDX_NO = A.IDX_NO ) 
          LEFT OUTER JOIN _TPDSFCWorkOrder    AS C ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq ) 
    

        IF EXISTS ( SELECT 1 FROM #KPXCM_TPDSFCWorkOrderPilot WHERE Status <> 0 ) 
        BEGIN 
            SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
            RETURN 
        END 
        --------------------------------------------------------------------------------------------------
        -- 작업지시, END 
        --------------------------------------------------------------------------------------------------
    END 
    

    
    
    -- 처리결과반영을 위한 Update
    UPDATE A 
       SET WorkOrderSeq = CASE WHEN A.WorkingTag = 'A' THEN A.WorkOrderSeq ELSE 0 END, 
           ProdPlanSeq = CASE WHEN A.WorkingTag = 'A' THEN A.ProdPlanSeq ELSE 0 END, 
           WorkOrderNo = CASE WHEN A.WorkingTag = 'A' THEN C.WorkOrderNo ELSE '' END, 
           ProdPlanNo = CASE WHEN A.WorkingTag = 'A' THEN D.ProdPlanNo ELSE '' END, 
           IsCfm = CASE WHEN A.WorkingTag = 'A' THEN '1' ELSE '0' END
      FROM #KPXCM_TPDSFCWorkOrderPilot      AS A 
      LEFT OUTER JOIN _TPDSFCWorkOrder      AS C ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan  AS D ON ( D.CompanySeq = @CompanySeq AND D.ProdPlanSeq = A.ProdPlanSeq ) 
     WHERE A.Status = 0 
    
    -- 실제 테이블 UPdate 
    UPDATE A 
       SET WorkOrderSeq = B.WorkOrderSeq, 
           ProdPlanSeq = B.ProdPlanSeq, 
           IsCfm = B.IsCfm 
      FROM KPXCM_TPDSFCWorkOrderPilot       AS A 
      JOIN #KPXCM_TPDSFCWorkOrderPilot      AS B ON ( B.PilotSeq = A.PilotSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.Status = 0 
    
    SELECT * FROM #KPXCM_TPDSFCWorkOrderPilot 
    
    
    RETURN  
    go
begin tran
exec KPXCM_SPDSFCWorkOrderPilotCfm @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <AfterWorkSeq>0</AfterWorkSeq>
    <IsCfm>1</IsCfm>
    <PilotSeq>1</PilotSeq>
    <ProdPlanNo>201612010007</ProdPlanNo>
    <ProdPlanSeq>15943</ProdPlanSeq>
    <WorkOrderNo>201612010001</WorkOrderNo>
    <WorkOrderSeq>142224</WorkOrderSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'CfmCan',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029271
--select * from KPXCM_TPDSFCWorkOrderPilot  
--select * From _TPDMPSDailyProdPlan where companyseq = 2 and ProdPlanSeq = 15943 
--select * from _TPDMPSDailyProdPlan_Confirm where CompanySeq = 2 and CfmSeq = 15943
--select * From _TPDSFCWorkOrder where companyseq = 2 and WorkOrderSeq = 142224 
rollback 
