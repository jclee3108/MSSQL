IF OBJECT_ID('KPXCM_SPDSFCWorkOrderLotNoReplace') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkOrderLotNoReplace
GO 

-- 2016.04.27 

-- 작업지시, I/F 테이블, POP테이블 LotNo 동기화 by이재천 
CREATE PROC KPXCM_SPDSFCWorkOrderLotNoReplace
    @CompanySeq INT 
AS 

    -- 작지 최종건에만 반영 
    SELECT WorkOrderSeq, MAX(Serl) AS Serl 
      INTO #Temp 
      FROM KPX_TPDSFCWorkorder_POP 
     WHERE CompanySeq = @CompanySeq  
       AND IsPacking = '0' 
     GROUP BY WorkOrderSeq 
    

    select A.WorkOrderSeq, A.WorkorderSerl, A.WorkCond3 AS LotNo
      INTO #TPDSFCWorkOrder
      from _TPDSFCWorkOrder AS A 
      JOIN KPX_TPDSFCWorkorder_POP AS B ON ( B.CompanySeq = A.CompanySeq 
                                         AND B.IsPacking = '0' 
                                         AND B.WorkOrderSeq = A.WorkOrderSeq 
                                         AND B.WorkOrderSerl = A.WorkOrderSerl 
                                         AND B.ProcYn IN ( '1', '0' ) 
                                           ) 
      JOIN #Temp            AS C ON ( C.WorkorderSeq = B.WorkOrderSeq AND C.Serl = B.Serl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkOrderDate >= CONVERT(NCHAR(8),DATEADD(MONTH, -1, GETDATE()),112) 
       AND A.WorkCond3 <> B.LotNo 
    
    -- 일반작업지시 확정이 아닌 것만 Update 
    SELECT A.WorkOrderSeq, A.WorkOrderSerl, A.WorkCond3 AS LotNo
      INTO #SCHTT_WorkOrder
      FROM _TPDSFCWorkOrder AS A 
      JOIN POP_CM_test.airmes.kpxcm.SCHTT_WorkOrder  AS B ON ( B.SITECODE = A.CompanySeq 
                                                           AND B.WORKID = A.WorkOrderSeq 
                                                           AND B.WORKORDERSERL = A.WorkOrderSerl 
                                                           AND B.ISPACKING = '0' 
                                                           AND B.USEYN = 'Y' 
                                                           AND ISNULL(B.PROCFLAG,'N') = 'N' 
                                                             ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkOrderDate >= CONVERT(NCHAR(8),DATEADD(MONTH, -1, GETDATE()),112)
       AND A.WorkCond3 <> B.LotNo 
       
    -- 포장작업지시 작업시작이 아닌 것만 Update 
    SELECT C.PackOrderSeq AS WorkOrderSeq, C.PackOrderSerl AS WorkOrderSerl, A.WorkCond3 AS LotNo
      INTO #SCHTT_WorkOrder_Pack
      FROM _TPDSFCWorkOrder AS A 
      JOIN KPX_TPDSFCProdPackOrderItem AS C ON ( C.CompanySeq = @CompanySeq AND C.SourceSeq = A.WorkOrderSeq AND C.SourceSerl = A.WorkOrderSerl ) 
      JOIN POP_CM_test.airmes.kpxcm.SCHTT_WorkOrder  AS B ON ( B.SITECODE = C.CompanySeq 
                                                           AND B.WORKID = C.PackOrderSeq 
                                                           AND B.WORKORDERSERL = C.PackOrderSerl  
                                                           AND B.ISPACKING = '1' 
                                                           AND B.RST_WORKSTRTIME IS NULL
                                                             ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkOrderDate >= CONVERT(NCHAR(8),DATEADD(MONTH, -1, GETDATE()),112)
       AND A.WorkCond3 <> B.LotNo 
    
    
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkOrder)
    BEGIN 
    
    
        UPDATE A
           SET LotNo = B.LotNo 
        --select A.LotNo, B.LotNo 
          FROM KPX_TPDSFCWorkorder_POP AS A 
          JOIN #TPDSFCWorkOrder         AS B ON ( B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
    
    
        UPDATE A
           SET LotNo = B.LotNo 
        --select A.LotNo, B.LotNo 
          FROM KPX_TPDSFCProdPackOrderItem AS A 
          JOIN #TPDSFCWorkOrder         AS B ON ( B.WorkOrderSeq = A.SourceSeq AND B.WorkOrderSerl = A.SourceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
    
    END 
    
    IF EXISTS (SELECT 1 FROM #SCHTT_WorkOrder)
    BEGIN 
    
    
        UPDATE A
           SET LotNo = B.LotNo 
        --select A.LotNo, B.LotNo 
          FROM POP_CM_test.airmes.kpxcm.SCHTT_WorkOrder AS A 
          JOIN #SCHTT_WorkOrder                         AS B ON ( B.WorkOrderSeq = A.WORKID AND B.WorkOrderSerl = A.WORKORDERSERL ) 
         WHERE A.SITECODE = @CompanySeq 
           AND A.ISPACKING = '0'  
         
        UPDATE A
           SET LotNo = B.LotNo 
        --select A.LotNo, B.LotNo 
          FROM POP_CM_test.airmes.kpxcm.SCHTT_WorkOrder AS A 
          JOIN #SCHTT_WorkOrder_Pack                    AS B ON ( B.WorkOrderSeq = A.WORKID AND B.WorkOrderSerl = A.WORKORDERSERL ) 
         WHERE A.SITECODE = @CompanySeq 
           AND A.ISPACKING = '1'  
    
    END 
    
   return 
   go
   --begin tran 
   exec KPXCM_SPDSFCWorkOrderLotNoReplace 2 
   
   --rollback 