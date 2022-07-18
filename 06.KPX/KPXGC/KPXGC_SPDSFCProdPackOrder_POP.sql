
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrder_POP') IS NOT NULL 
    DROP PROC KPXGC_SPDSFCProdPackOrder_POP 
GO 

-- v2015.08.21 

-- 포장작업지시 연동 by이재천 
CREATE PROC KPXGC_SPDSFCProdPackOrder_POP  
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
            @Results        NVARCHAR(250), 
            @IsCfm          NCHAR(1) 
      
    CREATE TABLE #KPX_TPDSFCWorkOrder_POP( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCWorkOrder_POP'   
    IF @@ERROR <> 0 RETURN  
    
    SELECT @IsCfm = (SELECT TOP 1 IsCfm FROM #KPX_TPDSFCWorkOrder_POP) 
    
    IF @IsCfm = '0' 
    BEGIN 
        --삭제건은 WorkingTag 'D'로 Insert한다.  
        --포장 작업지시  
        INSERT INTO KPX_TPDSFCWorkOrder_POP
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, WorkOrderNo,  
            WorkOrderDate, FactUnit, WorkCenterSeq, GoodItemSeq, ProcSeq, 
            ProdUnitSeq, BOMRev, OrderQty, WorkSrtDate, WorkStartTime, 
            WorkEndDate, WorkEndTime, LotNo, WorkType, Remark, 
            WorkTimeGroup, EmpSeq, UMProgType, RegDateTime, ProcYn, 
            OutLotNo, WorkingTag, PackingLocation, TankName
        )   
        SELECT A.CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, A.IsPacking, A.WorkOrderNo,  
               A.WorkOrderDate, A.FactUnit, A.WorkCenterSeq, A.GoodItemSeq, A.ProcSeq, 
               A.ProdUnitSeq, A.BOMRev, A.OrderQty, A.WorkSrtDate, A.WorkStartTime, 
               A.WorkEndDate, A.WorkEndTime, A.LotNo, A.WorkType, A.Remark, 
               A.WorkTimeGroup, A.EmpSeq, A.UMProgType, GETDATE(), A.ProcYn, 
               A.OutLotNo, 'D', A.PackingLocation, A.TankName  
          FROM #KPX_TPDSFCWorkOrder_POP AS M 
          JOIN KPX_TPDSFCWorkOrder_POP  AS A ON ( A.CompanySeq = @CompanySeq AND A.WorkOrderSeq = M.PackOrderSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.IsPacking = '1' 
           AND A.ProcYn <> '9' 
        
        UPDATE A
           SET ProcYn = '9'
          FROM #KPX_TPDSFCWorkOrder_POP AS M 
          JOIN KPX_TPDSFCWorkOrder_POP  AS A ON ( A.CompanySeq = @CompanySeq AND A.WorkOrderSeq = M.PackOrderSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.IsPacking = '1' 
    
        
        --용기정보 삭제 
        DELETE A 
          FROM #KPX_TPDSFCWorkOrder_POP         AS M 
          JOIN KPX_TPDSFCWorkOrderPackItem_POP  AS A ON ( A.CompanySeq = @CompanySeq AND A.WorkOrderSeq = M.PackOrderSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
        
        --삭제 처리 완료  
    END 
    
    ----중단처리  
    --UPDATE B  
    --   SET ProcYN = '9'  
    --  FROM KPX_TPDSFCProdPackOrderItem AS A  
    --  JOIN KPX_TPDSFCWorkOrder_POP AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq  
    --                                                AND B.WorkOrderSeq = A.PackOrderSeq  
    --                                                AND B.WorkOrderSerl = A.PackOrderSerl  
    -- WHERE A.CompanySeq = @CompanySeq  
    --   AND B.IsPacking = '1'  
    --   AND A.IsStop = '1'  
    --   AND Exists (select 1 from KPX_TPDSFCWorkOrder_POP AS C with(Nolock) where B.CompanySeq = C.CompanySeq  
    --   AND B.WorkOrderSeq = C.WorkOrderSeq  
    --   AND B.WorkOrderSerl = C.WorkOrderSerl  
    --   and C.ProcYn <> '9')  
    ----중단 처리 완료  
    
    IF @IsCfm = '1' 
    BEGIN 
        --포장작업지시  
        INSERT INTO KPX_TPDSFCWorkOrder_POP
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, WorkOrderNo,   
            WorkOrderDate, FactUnit, GoodItemSeq, ProdUnitSeq, OrderQty,  
            WorkSrtDate, WorkStartTime, WorkEndDate, WorkEndTime, LotNo,   
            UMProgType,  RegDateTime, ProcYn,   OutLotNo, WorkingTag, 
            PackingLocation, TankName
        )  
        SELECT A.CompanySeq, C.PackOrderSeq, C.PackOrderSerl, '1', A.OrderNo,   
               A.PackDate, A.FactUnit, C.ItemSeq, C.UnitSeq, C.OrderQty,   
               A.PackDate, '', C.PackingDate, '',  C.OutLotNo,   
               
               A.UMProgType, GETDATE(),   
               CASE WHEN C.IsStop = '1' THEN '9'  
                    ELSE '0' END,  
               C.OutLotNo,  
               'A',  
                
               C.PackingLocation, T.TankName  
          FROM #KPX_TPDSFCWorkOrder_POP AS M 
                     JOIN KPX_TPDSFCProdPackOrder       AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.PackOrderSeq = M.PackOrderSeq ) 
                     JOIN KPX_TPDSFCProdPackOrderItem   AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.PackOrderSeq = A.PackOrderSeq  
          LEFT OUTER JOIN KPX_TPDTank                   AS T WITH(NOLOCK) ON T.CompanySeq = C.CompanySeq AND T.TankSeq = C.TankSeq  
         WHERE A.CompanySeq = @CompanySeq  
        
        --용기정보  
        INSERT INTO KPX_TPDSFCWorkOrderPackItem_POP
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, SubItemSeq, 
            OutWHSeq, Qty, PackingQty, NonMarking, RegDateTime, 
            ProcYn
        )  
        SELECT A.CompanySeq, C.PackOrderSeq, C.PackOrderSerl, '1', C.SubItemSeq, 
               A.SubOutWHSeq, C.SubQty, C.PackingQty, C.NonMarking, GETDATE(),   
               CASE WHEN C.IsStop = '1' THEN '9'  
                    ELSE '0' END  
          FROM #KPX_TPDSFCWorkOrder_POP     AS M 
          JOIN KPX_TPDSFCProdPackOrder      AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.PackOrderSeq = M.PackOrderSeq ) 
          JOIN KPX_TPDSFCProdPackOrderItem  AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.PackOrderSeq = A.PackOrderSeq  
         WHERE A.CompanySeq = @CompanySeq  
    END 
    
    SELECT * FROM #KPX_TPDSFCWorkOrder_POP 
    
    RETURN  
  