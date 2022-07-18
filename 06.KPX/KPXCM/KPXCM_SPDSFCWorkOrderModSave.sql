IF OBJECT_ID('KPXCM_SPDSFCWorkOrderModSave') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkOrderModSave
GO
  
-- v2016.03.30
-- 수정 by이재천   
  
/************************************************************  
 설  명 - 데이터-작업지시조정_KPX : 저장  
 작성일 - 20150123  
 작성자 - 박상준  
 수정자 -   
************************************************************/  
CREATE PROC KPXCM_SPDSFCWorkOrderModSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT     = 0,    
    @ServiceSeq     INT     = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT     = 1,    
    @LanguageSeq    INT     = 1,    
    @UserSeq        INT     = 0,    
    @PgmSeq         INT     = 0  
AS     
      
    CREATE TABLE #TPDSFCWorkOrder (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkOrder'       
    IF @@ERROR <> 0 RETURN    
      
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 EXEC _SCOMLog  @CompanySeq,  
                   @UserSeq,  
                   '_TPDSFCWorkOrder',  
                   '#TPDSFCWorkOrder',  
                   'WorkOrderSeq,WorkOrderSerl',  
                   'CompanySeq,WorkOrderSeq,WorkOrderSerl,FactUnit,WorkOrderNo,WorkOrderDate,ProdPlanSeq,WorkPlanSerl,DailyWorkPlanSerl,  
                    WorkCenterSeq,GoodItemSeq,ProcSeq,AssyItemSeq,ProdUnitSeq,OrderQty,StdUnitQty,WorkDate,WorkStartTime,  
                    WorkEndTime,ChainGoodsSeq,WorkType,DeptSeq,ItemUnitSeq,ProcRev,Remark,IsProcQC,IsLastProc,IsPjt,PJTSeq,  
                    WBSSeq,ItemBomRev,ProcNo,ToProcNo,SMToProcMovType,ProdOrderSeq,IsCancel,LastUserSeq,LastDateTime,BatchSeq,IsJobOrderEnd,JobOrderEndDate,Priority,  
                    WorkCond1,WorkCond2,WorkCond3,WorkCond4,WorkCond5,WorkCond6,WorkCond7,WorkTimeGroup, EmpSeq',  
     '',@PgmSeq  
  
  
---- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
---- DELETE      
IF EXISTS (SELECT TOP 1 1 FROM #TPDSFCWorkOrder WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN    
  
   delete from _TPDMPSWorkOrder  
    where CompanySeq  = @CompanySeq  
      and ProdPlanSeq in (select A.ProdPlanSeq   
                            from _TPDSFCWorkOrder AS A with(Nolock)  
               Join #TPDSFCWorkOrder AS B With(nolock) On A.CompanySeq = @CompanySeq And A.WorkOrderSeq = B.WorkOrderSeq And A.WorkOrderSerl = B.WorkOrderSerl  
                            where CompanySeq = @CompanySeq  
           )  
  
             IF @@ERROR <> 0  RETURN  
  
            update _TPDMPSDailyProdPlan_Confirm  
      set CfmCode = 0  
    where CompanySeq = @CompanySeq  
      and CfmSeq in (select A.ProdPlanSeq   
                            from _TPDSFCWorkOrder AS A with(Nolock)  
               Join #TPDSFCWorkOrder AS B With(nolock) On A.CompanySeq = @CompanySeq And A.WorkOrderSeq = B.WorkOrderSeq And A.WorkOrderSerl = B.WorkOrderSerl  
                            where CompanySeq = @CompanySeq  
           )  
  
            IF @@ERROR <> 0  RETURN  
  
            DELETE _TPDSFCWorkOrder  
              FROM #TPDSFCWorkOrder      AS A   
                   JOIN _TPDSFCWorkOrder AS B ON ( A.WorkOrderSerl      = B.WorkOrderSerl )   
                         AND ( A.WorkOrderSeq       = B.WorkOrderSeq )   
             WHERE B.CompanySeq  = @CompanySeq  
               AND A.WorkingTag  = 'D'   
               AND A.Status      = 0      
           
             IF @@ERROR <> 0  RETURN  
     
  
    END    
  
  
-- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkOrder WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
            UPDATE _TPDSFCWorkOrder  
              SET  WorkCond7 = A.Workcond7,  
       Remark  = A.Remark,  
                   LastUserSeq  = @UserSeq,  
                   LastDateTime = GetDate()  
              FROM #TPDSFCWorkOrder      AS A   
                   JOIN _TPDSFCWorkOrder AS B ON ( A.WorkOrderSerl      = B.WorkOrderSerl )   
                         AND ( A.WorkOrderSeq       = B.WorkOrderSeq )   
                           
             WHERE B.CompanySeq = @CompanySeq  
               AND A.WorkingTag = 'U'   
               AND A.Status     = 0      
     
              IF  @@ERROR <> 0  RETURN  
    END    
    -- 인터페이스 속도 문제 때문에 후작업 수정하면 최초 인터페이스 내용 인터페이스 테이블에 인서트 처리함  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkOrder WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
  INSERT INTO KPX_TPDSFCWorkOrder_POP(CompanySeq, WorkOrderSeq, WorkOrderSerl, IsPacking, WorkOrderNo,         
            WorkOrderDate, FactUnit, WorkCenterSeq, GoodItemSeq, ProcSeq,         
            ProdUnitSeq, BOMRev, OrderQty,        
            WorkSrtDate, WorkStartTime, WorkEndDate, WorkEndTime,         
            LotNo, WorkType, Remark, WorkTimeGroup, EmpSeq,         
            RegDateTime, ProcYn, WorkingTag,TankName,PatternRev,PatternItemSeq,PostProc,SubItemName,IsPilot)        
     SELECT A.CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, '0', A.WorkOrderNo,         
      A.WorkOrderDate, A.FactUnit, A.WorkCenterSeq, A.GoodItemSeq, A.ProcSeq,         
      A.ProdUnitSeq, A.ItemBOMRev, A.OrderQty,         
      A.WorkCond1, A.WorkStartTime,A.WorkCond2, A.WorkEndTime,         
      A.WorkCond3, A.WorkType, ISNULL(A.Remark,''), ISNULL(A.WorkTimeGroup,0), A.EmpSeq,         
      GETDATE(),         
      CASE WHEN A.IsCancel = '1' THEN '9'        
        ELSE '0' END,        
      'A' , ISNULL(A.Remark,''),right('00'+ convert(nvarchar(2),convert(INT,A.WorkCond6)),2) ,A.AssyItemSeq  
    ,convert(int,A.WorkCond7), D.ItemEngSName, CASE WHEN @PgmSeq = 1029271 THEN '1' ELSE '0' END 
    FROM _TPDSFCWorkOrder AS A        
     Join #TPDSFCWorkOrder AS A1 ON A1.WorkingTag = 'U' AND A1.Status = 0 And A1.WorkOrderSeq = A.WorkOrderSeq And A1.WorkOrderSerl = A.WorkOrderSerl  
     JOIN _TPDSFCWorkOrder_Confirm AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq        
        AND C.CfmSeq = A.WorkOrderSeq        
        AND C.CfmSerl = A.WorkOrderSerl        
        AND C.CfmCode = '1'        
    LEFT OUTER JOIN KPX_TPDSFCWorkOrder_POP AS B ON B.CompanySeq = A.CompanySeq        
       AND B.WorkOrderSeq = A.WorkOrderSeq        
       AND B.WorkOrderSerl = A.WorkOrderSerl        
       AND B.IsPacking = '0' 
       AND B.ProcYn <> '5' 
    LEFT OUTER JOIN _TDAItem    AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = CONVERT(INT,A.WorkCond5) )   
   WHERE A.CompanySeq = @CompanySeq        
     AND ISNULL(B.CompanySeq, 0) = 0        
     AND A.WorkCenterSeq IN (SELECT WorkCenterSeq FROM _TPDBaseWorkCenter WHERE CompanySeq = @CompanySeq AND SMWorkCenterType = 6011001)        
     AND A.FactUnit = 3  
     AND isnull(A.WorkCond7,0) <> 0   -- 후작업이 입력된 값만 인터페이스 한다  
     
            IF @@ERROR <> 0  RETURN  
    END    
-- select * from Kpx_TpdsfcWorkOrder_pop where WorkOrderSeq = 28414  
  
---- INSERT  
--IF EXISTS (SELECT 1 FROM #TPDSFCWorkOrder WHERE WorkingTag = 'A' AND Status = 0)    
--    BEGIN    
--            INSERT INTO _TPDSFCWorkOrder   
--                   (CompanySeq, WorkCond7       ,Remark          ,QCType          ,QCTypeName      ,FactUnitName    ,  
--                         WorkOrderSeq    ,StdToDate       ,GoodItemSeq     ,WorkCond7Name   ,WorkOrderSerl   ,  
--                         WorkCenterSeq   ,WorkCenterName  ,FactUnit        ,StdFrDate       ,ProdPlanNo      ,  
--                         GoodItemName      
--                   LastUserSeq, LastDateTime )   
--            SELECT @CompanySeq, WorkCond7       ,Remark          ,QCType          ,QCTypeName      ,FactUnitName    ,  
--                   WorkOrderSeq    ,StdToDate       ,GoodItemSeq     ,WorkCond7Name   ,WorkOrderSerl   ,  
--                   WorkCenterSeq   ,WorkCenterName  ,FactUnit        ,StdFrDate       ,ProdPlanNo      ,  
--                   GoodItemName     
--                   @UserSeq ,GetDate()   
--              FROM #TPDSFCWorkOrder AS A     
--             WHERE A.WorkingTag = 'A'   
--               AND A.Status = 0      
  
--            IF @@ERROR <> 0 RETURN  
--    END     
  
    SELECT * FROM #TPDSFCWorkOrder   
RETURN      
  
  