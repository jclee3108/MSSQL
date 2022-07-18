IF OBJECT_ID('KPXCM_SPDMPSProdPlanPilotSave') IS NOT NULL 
    DROP PROC KPXCM_SPDMPSProdPlanPilotSave 
GO 

-- v2016.03.02 

-- 생산계획Gantt_kpx-저장 by 이지은 , 실적 생성된 데이터는 U,D 제외로직 추가 by이재천 
-- 긴급작업지시때문에 별도 SP생성 
CREATE PROC KPXCM_SPDMPSProdPlanPilotSave
            @xmlDocument    NVARCHAR(MAX),    
            @xmlFlags       INT     = 0,    
            @ServiceSeq     INT     = 0,    
            @WorkingTag     NVARCHAR(10)= '',    
            @CompanySeq     INT     = 1,    
            @LanguageSeq    INT     = 1,    
            @UserSeq        INT     = 0,    
            @PgmSeq         INT     = 0     
  
AS     
   
    CREATE TABLE #TPDMPSDailyProdPlan (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'       
    IF @@ERROR <> 0 RETURN    
    
    -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정) 
    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMPSDailyProdPlan' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
        ALTER TABLE _TPDMPSDailyProdPlan ADD PgmSeq INT NULL
    END 

    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMPSDailyProdPlanLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
        ALTER TABLE _TPDMPSDailyProdPlanLog ADD PgmSeq INT NULL
    END  
    
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog   @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TPDMPSDailyProdPlan', -- 원테이블명  
                    '#TPDMPSDailyProdPlan', -- 템프테이블명  
                    'ProdPlanSeq    ' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    'CompanySeq ,ProdPlanSeq ,FactUnit  ,ProdPlanNo  ,SrtDate ,EndDate  ,DeptSeq  ,WorkcenterSeq ,ItemSeq  ,BOMRev   
                    ,ProcRev  ,UnitSeq  ,BaseStkQty  ,PreSalesQty ,SOQty  ,StkQty  ,PreInQty  ,ProdQty  ,StdProdQty  ,SMSource   
                    ,SourceSeq ,SourceSerl  ,Remark   ,IsCfm   ,CfmEmpSeq ,CfmDate  ,LastUserSeq ,LastDateTime, StdUnitSeq, StockInDate
                    ,WorkCond1,WorkCond2,WorkCond3,WorkCond4,WorkCond5,WorkCond6,WorkCond7,PgmSeq'
                    ,'',@PgmSeq  
  
    ALTER TABLE #TPDMPSDailyProdPlan ADD StdProdQty DECIMAL(19,5)
    ALTER TABLE #TPDMPSDailyProdPlan ADD StdUnitSeq INT
    ALTER TABLE #TPDMPSDailyProdPlan ADD OldQty DECIMAL(19,5)

    UPDATE #TPDMPSDailyProdPlan
       SET StdUnitSeq = B.UnitSeq
      FROM #TPDMPSDailyProdPlan AS A JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq AND B.CompanySeq = @CompanySeq

    UPDATE #TPDMPSDailyProdPlan
       SET StdProdQty = A.ProdPlanQty * E.ConvNum / E.ConvDen
      FROM #TPDMPSDailyProdPlan AS A JOIN _TDAItemUnit AS E ON A.ItemSeq = E.ItemSeq AND A.StdUnitSeq = E.UnitSeq AND E.CompanySeq = @CompanySeq 

    UPDATE #TPDMPSDailyProdPlan
       SET OldQty = B.ProdQty
      FROM #TPDMPSDailyProdPlan AS A JOIN _TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND B.CompanySeq = @CompanySeq
    
    
    
    SELECT *
      INTO #TPDMPSDailyProdPlanSub
      FROM #TPDMPSDailyProdPlan 
    
    DELETE A 
      FROM #TPDMPSDailyProdPlan AS A 
      JOIN _TPDSFCWorkOrder     AS B ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq ) 
      JOIN _TPDSFCWorkReport    AS C ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = B.WorkOrderSeq AND C.WorkOrderSerl = B.WorkOrderSerl ) 
     WHERE A.WorkingTag = 'D' 

/*****************************************************************************************************************************/
-- 배합품목 배치Seq 담기
    DECLARE @TempBatchItem TABLE
    (
        FactUnit    INT,
        ProdPlanSeq INT,
        ItemSeq     INT,
        BatchSeq    INT
    )

    INSERT INTO @TempBatchItem
    SELECT A.FactUnit, A.ProdPlanSeq, A.ItemSeq, B.BatchSeq
      FROM #TPDMPSDailyProdPlan AS A 
      JOIN _TPDBOMBatch AS B With(NOLOCK) ON A.FactUnit = B.FactUnit AND A.ItemSeq = B.ItemSeq AND B.CompanySeq = @CompanySeq
                                         AND A.ProdPlanEndDate >= B.DateFr AND A.ProdPlanEndDate <= B.DateTo
/****************************************************************************************************************************/
  
 -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDMPSWorkOrder  
     FROM _TPDMPSWorkOrder A   
       JOIN #TPDMPSDailyProdPlan B ON ( A.ProdPlanSeq    = B.ProdPlanSeq )   
    WHERE A.CompanySeq  = @CompanySeq  
      AND B.WorkingTag = 'D'   
      AND B.Status = 0 
    IF @@ERROR <> 0  RETURN  
 END    

 IF EXISTS (SELECT TOP 1 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDMPSDailyProdPlan  
     FROM _TPDMPSDailyProdPlan A   
       JOIN #TPDMPSDailyProdPlan B ON ( A.ProdPlanSeq    = B.ProdPlanSeq )   
    WHERE A.CompanySeq  = @CompanySeq  
      AND B.WorkingTag = 'D'   
      AND B.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
 IF EXISTS (SELECT TOP 1 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDDailyProdPlanSemiPlan  
     FROM _TPDDailyProdPlanSemiPlan A   
       JOIN #TPDMPSDailyProdPlan B ON ( A.SemiProdPlanSeq    = B.ProdPlanSeq )   
    WHERE A.CompanySeq  = @CompanySeq  
      AND B.WorkingTag = 'D'   
      AND B.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    


 --POP 연동 정보 삭제처리
 IF EXISTS (SELECT TOP 1 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   INSERT INTO KPX_TPDSFCWorkOrder_POP(CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, WorkOrderNo, 
	                                    WorkOrderDate, FactUnit, WorkCenterSeq, GoodItemSeq, ProcSeq, 
	                                    ProdUnitSeq, BOMRev, OrderQty,
	                                    WorkSrtDate, WorkStartTime, WorkEndDate, WorkEndTime, 
	                                    LotNo, WorkType, Remark, WorkTimeGroup, EmpSeq, 
	                                    RegDateTime, ProcYn, WorkingTag)
        SELECT A.CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, A.IsPacking, A.WorkOrderNo, 
               A.WorkOrderDate, A.FactUnit, A.WorkCenterSeq, A.GoodItemSeq, A.ProcSeq, 
               A.ProdUnitSeq, A.BOMRev, A.OrderQty,
               A.WorkSrtDate, A.WorkStartTime, A.WorkEndDate, A.WorkEndTime, 
               A.LotNo, A.WorkType, A.Remark, A.WorkTimeGroup, A.EmpSeq, 
               A.RegDateTime, '0', 'D'
          FROM KPX_TPDSFCWorkOrder_POP AS A
               JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = @CompanySeq
                                         AND B.WorkOrderSeq = A.WorkOrderSeq
                                         AND B.WorkOrderSerl = A.WorkOrderSerl
               JOIN #TPDMPSDailyProdPlan C ON C.ProdPlanSeq = B.ProdPlanSeq
         WHERE A.IsPacking = '0'
           AND C.WorkingTag = 'D'
           AND C.Status = 0
    
    IF @@ERROR <> 0 RETURN

 END  
 --작업지시 삭제처리
 IF EXISTS (SELECT TOP 1 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
    DELETE _TPDSFCWorkOrder
      FROM _TPDSFCWorkOrder AS A
           JOIN #TPDMPSDailyProdPlan B ON B.ProdPlanSeq = A.ProdPlanSeq
     WHERE B.WorkingTag = 'D'
       AND B.Status = 0
       AND A.CompanySeq = @CompanySeq
    
    IF @@ERROR <> 0 RETURN
 END

 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
    
    --작업지시 정보 수정(수량, 시간)
    UPDATE A
       SET OrderQty     = B.ProdPlanQty,
           WorkDate     = B.SrtDate,
           WorkCond1    = B.SrtDate,
           WorkCond2    = B.EndDate,
           WorkCond3    = B.WorkCond3,
           WorkStartTime = B.WorkCond1,
           WorkEndTime  = B.WorkCond2,
           WorkCenterSeq = B.WorkCenterSeq,
           WorkCond6        = B.WorkCond6,
           Remark        = B.Remark
      FROM _TPDSFCWorkOrder AS A
           JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq
     WHERE A.CompanySeq = @CompanySeq
       AND B.WorkingTag = 'U'
       AND B.Status = 0
    
    --POP연동
	INSERT INTO KPX_TPDSFCWorkOrder_POP(CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, WorkOrderNo, 
	                                    WorkOrderDate, FactUnit, WorkCenterSeq, GoodItemSeq, ProcSeq, 
	                                    ProdUnitSeq, BOMRev, OrderQty,
	                                    WorkSrtDate, WorkStartTime, WorkEndDate, WorkEndTime, 
	                                    LotNo, WorkType, Remark, WorkTimeGroup, EmpSeq, 
	                                    RegDateTime, ProcYn, WorkingTag, PatternRev)
		 SELECT A.CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, '0', A.WorkOrderNo, 
		        A.WorkOrderDate, A.FactUnit, A.WorkCenterSeq, A.GoodItemSeq, A.ProcSeq, 
				A.ProdUnitSeq, A.ItemBOMRev, A.OrderQty, 
				A.WorkCond1, A.WorkStartTime,A.WorkCond2, A.WorkEndTime, 
				A.WorkCond3, A.WorkType, ISNULL(A.Remark,''), ISNULL(A.WorkTimeGroup,0), A.EmpSeq, 
				GETDATE(), 
				CASE WHEN A.IsCancel = '1' THEN '9'
					 ELSE '0' END,
				'A', A.WorkCond6
	  FROM _TPDSFCWorkOrder AS A
		   JOIN _TPDSFCWorkOrder_Confirm AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq
														  AND C.CfmSeq = A.WorkOrderSeq
														  AND C.CfmSerl = A.WorkOrderSerl
														  AND C.CfmCode = '1'
		   JOIN #TPDMPSDailyProdPlan AS Z ON A.ProdPlanSeq = Z.ProdPlanSeq
           JOIN (SELECT WorkOrderSeq, WorkOrderSerl, MAX(Serl) AS Serl
                   FROM KPX_TPDSFCWorkOrder_POP
                  WHERE CompanySeq = @CompanySeq
                    AND IsPacking = '0'
                  GROUP BY WorkOrderSeq, WorkOrderSerl) AS X ON X.WorkOrderSeq = A.WorkOrderSeq
                                                            AND X.WorkOrderSerl = A.WorkOrderSerl
		   JOIN KPX_TPDSFCWorkOrder_POP AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
														AND B.WorkOrderSeq = A.WorkOrderSeq
														AND B.WorkOrderSerl = A.WorkOrderSerl
														AND B.IsPacking = '0'
                                                        AND B.Serl = X.Serl
	 WHERE A.CompanySeq = @CompanySeq
	   AND B.ProcYN IN ('0', '1')
	   AND A.WorkCenterSeq IN (SELECT WorkCenterSeq FROM _TPDBaseWorkCenter WHERE CompanySeq = @CompanySeq AND SMWorkCenterType = 6011001)
	   AND A.FactUnit = 1 -- 기존사업부만 POP연동 추가 by이재천 
       AND (  ISNULL(B.WorkOrderNo   ,'')   <> ISNULL(A.WorkOrderNo   ,'')
	       OR ISNULL(B.WorkOrderDate ,'')   <> ISNULL(A.WorkOrderDate ,'')
           OR ISNULL(B.FactUnit      ,0)    <> ISNULL(A.FactUnit      ,0)
	       OR ISNULL(B.WorkCenterSeq ,0)    <> ISNULL(A.workCenterSeq ,0)
	       OR ISNULL(B.GoodItemSeq   ,0)    <> ISNULL(A.GoodItemSeq   ,0)
	       OR ISNULL(B.ProcSeq       ,0)    <> ISNULL(A.ProcSeq       ,0)
	       OR ISNULL(B.ProdUnitSeq   ,0)    <> ISNULL(A.ProdUnitSeq   ,0)
	       OR ISNULL(B.BOMRev        ,'')   <> ISNULL(A.ItemBomRev    ,'')
	       OR ISNULL(B.OrderQty      ,0)    <> ISNULL(A.OrderQty      ,0)
	       OR ISNULL(B.WorkSrtDate   ,'')   <> ISNULL(A.WorkCond1     ,'')
	       OR ISNULL(B.WorkStartTime ,'')   <> ISNULL(A.WorkStartTime ,'')
	       OR ISNULL(B.WorkEndDate   ,'')   <> ISNULL(A.WorkCond2     ,'')
	       OR ISNULL(B.WorkEndTime   ,'')   <> ISNULL(A.WorkEndTime   ,'')
	       OR ISNULL(B.LotNo         ,'')   <> ISNULL(A.WorkCond3     ,'')
	       OR ISNULL(B.Remark        ,'')   <> ISNULL(A.Remark        ,'')   
           OR ISNULL(B.PatternRev    ,0 )   <> ISNULL(A.WorkCond6     , 0))
    --UPDATE Z
    --   SET OrderQty = B.ProdPlanQty,
    --       WorkSrtDate  = B.SrtDate,
    --       WorkStartTime    = B.WorkCond1, 
    --       WorkEndDate  = B.EndDate,
    --       WorkEndTime  = B.WorkCond2,
    --       LotNo        = B.WorkCond3,
    --       WorkCenterSeq = B.WorkCenterSeq
    --  FROM KPX_TPDSFCWorkOrder_POP AS Z 
    --       JOIN _TPDSFCWorkOrder AS A ON A.CompanySeq = Z.CompanySeq
    --                                 AND A.WorkOrderSeq = Z.WorkOrderSeq
    --                                 AND A.WorkOrderSerl = Z.WorkOrderSerl
    --       JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq
    -- WHERE Z.CompanySeq = @CompanySeq
    --   AND B.WorkingTag = 'U'
    --   AND B.Status = 0
    --   AND Z.IsPacking = '0'
       
    ----검사의뢰
    UPDATE A
       SET LotNo = C.WorkCond3,
           ReqQty = C.ProdPlanQty,
           LastUserSeq = @UserSeq,
           LastDateTime = GETDATE()
      FROM KPX_TQCTestRequestItem AS A
           JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq AND B.WorkOrderSeq = A.SourceSeq AND B.WorkOrderSerl = A.SourceSerl 
           JOIN #TPDMPSDailyProdPlan AS C ON C.ProdPlanSeq = B.ProdPlanSeq
     WHERE A.CompanySeq = @CompanySeq
       AND C.WorkingTag = 'U'
       AND C.Status = 0
       AND A.SMSourceType = 1000522004

    UPDATE A  
       SET  FactUnit        = B.FactUnit            ,  
            ItemSeq         = B.ItemSeq             ,  
            BOMRev          = B.BOMRev              ,  
            ProcRev         = B.ProcRev             ,  
        --    ProdQty         = B.ProdPlanQty         ,  
            Remark          = B.Remark    ,  
            DeptSeq         = B.ProdDeptSeq ,
            BatchSeq        = C.BatchSeq,
            LastUserSeq     = @UserSeq    ,  
            LastDateTime    = GETDATE()  ,
        --    StdProdQty      = B.StdProdQty,
            StdUnitSeq      = B.StdUnitSeq,
            UnitSeq         = B.UnitSeq,            -- 단위칼럼도 업데이트 되도록 수정      12.04.30 BY 김세호
            ProdPlanNo      = B.ProdPlanNo,
            WorkCond1       = B.WorkCond1,
            WorkCond2       = B.WorkCond2,
            WorkCond3       = B.WorkCond3,
            WorkCond4       = B.WorkCond4,
            WorkCond5       = B.WorkCond5,
       --     WorkCond6       = B.WorkCond6,
            WorkCond7       = B.WorkCond7,
            ProdPlanDate    = B.ProdPlanDate,
            WorkCenterSeq   = B.WorkCenterSeq,
            SrtDate         = B.SrtDate,
            EndDate         = B.EndDate,
			PgmSeq          = @PgmSeq
     FROM _TPDMPSDailyProdPlan AS A   
          JOIN #TPDMPSDailyProdPlan AS B ON (A.ProdPlanSeq    = B.ProdPlanSeq )   
          LEFT OUTER JOIN @TempBatchItem       AS C ON (A.ProdPlanSeq    = C.ProdPlanSeq)
    WHERE A.CompanySeq = @CompanySeq  
      AND B.WorkingTag = 'U'   
      AND B.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO _TPDMPSDailyProdPlan
          ( CompanySeq 
           ,ProdPlanSeq 
           ,FactUnit  
           ,ProdPlanNo  
           ,SrtDate       --> ?
           ,EndDate  
           ,DeptSeq  
           ,WorkcenterSeq --> ?
           ,ItemSeq  
           ,BOMRev  
           ,ProcRev  
           ,UnitSeq  
           ,BaseStkQty,   PreSalesQty,    SOQty,    StkQty,  PreInQty  
           ,ProdQty  
           ,StdProdQty  
           ,SMSource  
           ,SourceSeq
           ,SourceSerl  
           ,Remark   
           ,IsCfm  ,CfmEmpSeq   ,CfmDate  
           ,LastUserSeq 
           ,LastDateTime 
           ,BatchSeq
           ,StdUnitSeq
           ,WorkCond1
           ,WorkCond2
           ,WorkCond3
           ,WorkCond4
           ,WorkCond5
           ,WorkCond6
           ,WorkCond7
           ,ProdPlanDate
		   ,PgmSeq)  

     SELECT @CompanySeq   
           ,A.ProdPlanSeq 
           ,A.FactUnit  
           ,A.ProdPlanNo  
           ,A.SrtDate
           ,A.EndDate
           ,ISNULL(A.ProdDeptSeq    ,0)
           ,A.WorkCenterSeq    
           ,A.ItemSeq   
           ,A.BOMRev   
           ,A.ProcRev   
           ,A.UnitSeq  
           ,0    ,0     ,0     ,0     ,0    
           ,A.ProdPlanQty  ,A.StdProdQty     
           ,6054001   
           ,0     ,0    
           ,CASE WHEN @PgmSeq = 10325 THEN '생산계획Forecast생성 : ' + CONVERT(NVARCHAR(8),GETDATE(),112) ELSE A.Remark END --PgmSeq : 10325(생산계획Forecast확정처리)
           ,'0'    ,  0,    ''   
           ,@UserSeq  ,GETDATE()
           ,C.BatchSeq 
           ,A.StdUnitSeq 
           ,A.WorkCond1
           ,A.WorkCond2
           ,A.WorkCond3
           ,A.WorkCond4
           ,A.WorkCond5
           ,A.WorkCond6
           ,A.WorkCond7
           ,A.ProdPlanDate
		   ,@PgmSeq
     FROM #TPDMPSDailyProdPlan           AS A 
          LEFT OUTER JOIN @TempBatchItem AS C ON A.ProdPlanSeq    = C.ProdPlanSeq
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
 -- 속도 문제로 표준 로직을 제외 처리 하고 확정 테이블에만 인서트 처리 함 20151119 이배식

   Insert into _TPDMPSDailyProdPlan_Confirm(CompanySeq,CfmSeq,CfmSerl,CfmSubSerl,CfmSecuSeq,IsAuto,CfmCode,CfmDate,CfmEmpSeq,UMCfmReason,CfmReason,LastDateTime)
   select @CompanySeq,ProdPlanSeq,0,0,6337,0,0,'',0,0,'',GetDate()
    from #TPDMPSDailyProdPlan AS A
  where A.WorkingTag in ( 'A' ,'U')  
    AND A.Status = 0    
	and Not Exists(select 1 from _TPDMPSDailyProdPlan_Confirm AS B where B.CompanySeq = @CompanySeq And B.CfmSeq = A.ProdPlanSeq)
    
    
    DELETE A 
      FROM _TPDMPSDailyProdPlan_Confirm  AS A 
      JOIN #TPDMPSDailyProdPlan         AS B ON ( B.ProdPlanSeq = A.CfmSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag = 'D' 
       AND B.Status = 0 
    
    SELECT * FROM #TPDMPSDailyProdPlan 
    
RETURN    

--GO
--begin tran 

--exec KPXCM_SPDMPSProdPlanGanttSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <IDX_NO>1</IDX_NO>
--    <WorkingTag>D</WorkingTag>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <FactUnit>3</FactUnit>
--    <WorkCenterSeq>2</WorkCenterSeq>
--    <BOMRev>00</BOMRev>
--    <DeptSeq>0</DeptSeq>
--    <ItemSeq>322</ItemSeq>
--    <ProcRev>00</ProcRev>
--    <ProdDeptSeq>0</ProdDeptSeq>
--    <ProdPlanDate>20170102</ProdPlanDate>
--    <ProdPlanNo>201701020002</ProdPlanNo>
--    <ProdPlanQty>28030.00000</ProdPlanQty>
--    <ProdPlanSeq>14188</ProdPlanSeq>
--    <Remark />
--    <UnitSeq>9</UnitSeq>
--    <WorkCond1>2200</WorkCond1>
--    <WorkCond2>1500</WorkCond2>
--    <WorkCond3 />
--    <WorkCond4>0.00000</WorkCond4>
--    <WorkCond6>2.00000</WorkCond6>
--    <WorkCond7>0.00000</WorkCond7>
--    <SrtDate>20170102</SrtDate>
--    <EndDate>20170103</EndDate>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030617,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025514
--rollback 
GO


