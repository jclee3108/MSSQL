IF OBJECT_ID('KPXCM_SPDMPSProdPlanPilotCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDMPSProdPlanPilotCheck 
GO 

-- v2016.03.02 
    
-- 생산계획Gantt_kpx-체크 by 이지은, 실적체크 제외 by이재천 ( 수정,삭제시 아예 제외시킴 ) 
-- 긴급작업지시때문에 별도 SP생성 
CREATE PROC KPXCM_SPDMPSProdPlanPilotCheck
 @xmlDocument    NVARCHAR(MAX),        
 @xmlFlags       INT     = 0,        
 @ServiceSeq     INT     = 0,        
 @WorkingTag     NVARCHAR(10)= '',        
 @CompanySeq     INT     = 1,        
 @LanguageSeq    INT     = 1,        
 @UserSeq        INT     = 0,        
 @PgmSeq         INT     = 0        
      
AS         
    
    DECLARE @SiteInitialName NVARCHAR(100), @SPName NVARCHAR(100)        
        
    SELECT @SiteInitialName = ISNULL(EnvValue,'') FROM _TCOMEnv WHERE EnvSeq = 2 AND CompanySeq = @CompanySeq        
        
    --IF EXISTS (select * from sysobjects where name like @SiteInitialName +'_SPDMPSProdPlanCheck')        
    --BEGIN        
    --    SELECT @SPName = @SiteInitialName +'_SPDMPSProdPlanCheck'        
                
    --    EXEC @SPName @xmlDocument,@xmlFlags,@ServiceSeq,@WorkingTag,@CompanySeq,@LanguageSeq,@UserSeq,@PgmSeq        
    --    RETURN              
        
    --END        
        
      
    DECLARE @Count       INT,      
            @Seq         INT,      
            @MessageType INT,      
            @Status      INT,      
            @Results     NVARCHAR(250),  
            @DeleteValue INT       
      
    
    
    -- 서비스 마스타 등록 생성        

    CREATE TABLE #TPDMPSDailyProdPlan (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'           
    IF @@ERROR <> 0 RETURN    
   
--select * from #TPDMPSDailyProdPlan
    --CREATE TABLE #Link( WorkingTag NCHAR(1) NULL )      
    --EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#Link'     
    --IF @@ERROR <> 0 RETURN

    EXEC dbo._SCOMEnv @CompanySeq,6266,@UserSeq,@@PROCID,@DeleteValue OUTPUT  
     
/*****************************************************************************************************************/    
-- 제품별공정별 소요자재 등록여부    
/*****************************************************************************************************************/    
    
    delete from #TPDMPSDailyProdPlan
    where Itemseq = 0

	declare @Maxrow  INT

	-- 이동배치 처리 작업계획도 삭제 필요해서 추가함

	--if   EXISTS(select 1 from #TPDMPSDailyProdPlan where WorkingTag = 'D')
	--begin

	--  select @Maxrow = Max(DataSeq)
	--   from #TPDMPSDailyProdPlan

	--  insert into #TPDMPSDailyProdPlan
	--   (WorkingTag,IDX_NO,DataSeq,Selected,MessageType,Status,Result,ROW_IDX,IsChangedMst,FactUnitName,FactUnit,ProdPlanDateFr
	--   ,ProdPlanDateTo,WorkCenterName,WorkCenterSeq,Capacity,BOMRev,BOMRevName,DeptSeq,FromSeq,FromSerl,FromSTDQty
	--   ,FromSubSerl,FromTableSeq,ItemName,ItemNo,ItemSeq,ProcRev,ProcRevName,ProdDeptName,ProdDeptSeq,ProdPlanDate
	--   ,ProdPlanEndDate,ProdPlanNo,ProdPlanQty,ProdPlanSeq,Remark,Spec,StockInDate,ToPgmSeq,ToTableSeq,UnitName
	--   ,UnitSeq,WorkCond1,WorkCond2,WorkCond3,WorkCond4,WorkCond5,WorkCond6,WorkCond7,TableName,SrtDate,EndDate
	--   ,NodeID,Sort,ProdFlagName,ProdFlag)
	--  select A.WorkingTag,@Maxrow + Row_Number() over(Order by A.ProdPlanSeq) ,@Maxrow + Row_Number() over(Order by A.ProdPlanSeq)
	--        ,A.Selected
	--		,A.MessageType
	--		,A.Status
	--		,A.Result
	--		,A.ROW_IDX,A.IsChangedMst
	--        ,A.FactUnitName,A.FactUnit,A.ProdPlanDateFr,A.ProdPlanDateTo,A.WorkCenterName,A.WorkCenterSeq,A.Capacity
	--		,A.BOMRev,A.BOMRevName,A.DeptSeq,A.FromSeq,A.FromSerl
	--         ,A.FromSTDQty,A.FromSubSerl,A.FromTableSeq,A.ItemName,A.ItemNo,A.ItemSeq,A.ProcRev,A.ProcRevName,A.ProdDeptName
	--		 ,A.ProdDeptSeq,A.ProdPlanDate,A.ProdPlanEndDate,A.ProdPlanNo,A.ProdPlanQty,B.SuccessorProdPalnSeq,A.Remark,A.Spec
	--		 ,A.StockInDate,A.ToPgmSeq,A.ToTableSeq,A.UnitName,A.UnitSeq,A.WorkCond1,A.WorkCond2,A.WorkCond3,A.WorkCond4
	--		 ,A.WorkCond5,A.WorkCond6,A.WorkCond7,A.TableName,A.SrtDate,A.EndDate,A.NodeID,A.Sort,A.ProdFlagName,A.ProdFlag
	--		 --,A.CompanySeq,A.PredecessorProdPlanSeq,A.SuccessorProdPalnSeq --,A.LastUserSeq,A.LastDateTime
 --      from #TPDMPSDailyProdPlan as a
	--	      Join  KPX_TPDMPSProdPlanRelation  as b with(Nolock) ON B.CompanySeq = @CompanySeq And B.PredecessorProdPlanSeq  = A.ProdPlanSeq 
	--   where WorkingTag = 'D' 

	--end


    IF (SELECT Count(*) 
	      FROM #TPDMPSDailyProdPlan AS A 
		       LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND B.ItemSeq IS NULL) > 0    
    BEGIN     
        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '제품별공정별소요자재가 등록되지 않은 품목입니다.',                          
               MessageType   = 17009,        
               Status        = 1      
          FROM #TPDMPSDailyProdPlan AS A LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
        WHERE A.WorkingTag <> 'D'    
          AND A.Status = 0    
          AND B.ItemSeq IS NULL    
            
    END    
    


/****************************************************************************************************************/    
-- 제품별공정별 워크센터 등록여부    
/*****************************************************************************************************************/    
   --  select * from #TPDMPSDailyProdPlan
  --     select * from _TPDROUItemProcWC
	 --  where CompanySeq = 2
	 --   and ItemSeq = 356
		--and WorkCenterseq =33

     
    IF (SELECT COUNT(*) FROM #TPDMPSDailyProdPlan                         AS A    
                             LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq --AND A.ProcRev = B.ProcRev    
                             LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq    
                             LEFT OUTER JOIN _TPDROUItemProcWC            AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ProcRev = D.ProcRev and A.ItemSeq = D.ItemSeq and A.WorkCenterSeq = D.WorkCenterSeq                               
                       WHERE A.WorkingTag <> 'D'    
                         AND A.Status = 0    
                         AND D.ItemSeq IS NULL ) > 0    
    BEGIN     

	 --   select 1
		--from #TPDMPSDailyProdPlan as a
		--   join _TPDROUItemProcWC as b
		--where WorkCenterseq = 1
		--  and ITemSEq = 356


        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '['+Isnull(A2.WorkCenterName,'') +'/'+Isnull(A1.ItemName,'')+ ']'+ '제품별 공정별 워크센터가 등록되지 않은 품목입니다.',                          
               MessageType   = 17009,        
               Status        = 1      
            FROM #TPDMPSDailyProdPlan              AS A    
	           LEFT OUTER JOIN _TDAItem                     AS A1 ON A1.CompanySeq = @CompanySeq And A1.ItemSeq = A.ItemSeq
			   LEFT OUTER JOIN _TPDBaseWorkCenter           AS A2 ON A2.CompanySeq = @CompanySeq And A2.WorkCenterSeq = A.WorkCenterSeq
               LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  --AND A.ProcRev = B.ProcRev    
               LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq    
               LEFT OUTER JOIN _TPDROUItemProcWC            AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev 
			                                                    and A.WorkCenterSeq = D.WorkCenterSeq     
         WHERE A.WorkingTag <> 'D'    
           AND A.Status = 0    
           AND D.ItemSeq IS NULL     
       
    END    
    
/****************************************************************************************************************/    
-- 생산사업장별 생산품목 공정흐름 차수 등록여부    
/*****************************************************************************************************************/    
    
    IF (SELECT Count(*) FROM #TPDMPSDailyProdPlan AS A JOIN _TPDROUItemProcRevFactUnit AS B ON A.ItemSeq = B.ItemSeq AND A.FactUnit = B.FactUnit and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND B.ItemSeq IS NULL) = 0    
    BEGIN     
        UPDATE #TPDMPSDailyProdPlan        
           SET Result        = '생산사업장별 생산품목에 등록되지 않은 품목입니다.',                          
               MessageType   = 17009,        
               Status        = 1      
          FROM #TPDMPSDailyProdPlan AS A     
         LEFT OUTER JOIN _TPDROUItemProcRevFactUnit AS B ON A.ItemSeq = B.ItemSeq     
                                                        AND A.FactUnit = B.FactUnit     
                                                        and A.ProcRev = B.ProcRev     
                                                        and A.BOMRev = B.BOMRev     
                                                        AND B.CompanySeq = @CompanySeq    
        WHERE A.WorkingTag <> 'D'    
          AND A.Status = 0    
          AND B.ItemSeq IS NULL    
            
    END    
    --SELECT 124,* FROM #TPDMPSDailyProdPlan 

/****************************************************************************************************************/    
-- BOM/생산 단위의 환산정보 유무 체크       --      11.11.28 BY 김세호    
/*****************************************************************************************************************/    
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            1293                  , -- @1의 @2을(를) 확인하세요.     
                            @LanguageSeq       ,       
                            7,'',                   -- 품목    
                            907, ''                 -- 단위환산정보    
    
    
    UPDATE A    
       SET Result        = REPLACE(@Results, '의', '(' + ISNULL(I.ItemNo,'') + ')'),                          
           MessageType   = @MessageType,        
           Status        = @Status      
      FROM #TPDMPSDailyProdPlan AS A    
      LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                AND I.ItemSeq = A.ItemSeq
      LEFT OUTER JOIN _TDAItemDefUnit      AS B ON @CompanySeq = B.CompanySeq    
                                               AND A.ItemSeq = B.ItemSeq    
                                               AND B.UMModuleSeq = 1003003  
  LEFT OUTER JOIN _TDAItemUnit         AS C ON B.CompanySeq = C.CompanySeq    
                                               AND B.ItemSeq = C.ItemSeq    
                                               AND B.STDUnitSeq = C.UnitSeq  
      LEFT OUTER JOIN _TDAItemDefUnit      AS D ON @CompanySeq = D.CompanySeq    
                                               AND A.ItemSeq = D.ItemSeq    
                                               AND D.UMModuleSeq = 1003004  
      LEFT OUTER JOIN _TDAItemUnit         AS E ON D.CompanySeq = E.CompanySeq    
                                               AND D.ItemSeq = E.ItemSeq    
                                                 AND D.STDUnitSeq = E.UnitSeq  
     WHERE A.WorkingTag IN ('A', 'U')    
       AND A.Status = 0    
       AND (B.ItemSeq IS NULL OR C.ItemSeq IS NULL OR D.ItemSeq IS NULL OR E.ItemSeq IS NULL)       

--select @Results
/****************************************************************************************************************/    
-- 제품별공정별소요자재에 공정품 누락되어 있는 경우 체크        --  11.12.21 BY 김세호    
/*****************************************************************************************************************/    
    
    --SELECT 165,* FROM #TPDMPSDailyProdPlan 
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan AS A     
                   JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND ISNULL(B.AssyItemSeq, 0) = 0)     
    BEGIN     
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            1293                  , -- @1의 @2을(를) 확인하세요.    
                            @LanguageSeq       ,       
                            11356,'',                   -- 제품별공정별소요자재    
                            3970, ''                 -- 공정품    
    
        UPDATE A        
           SET Result        = @Results,                 
               MessageType   = @MessageType,        
               Status        = @Status      
          FROM #TPDMPSDailyProdPlan AS A     
                   JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq    
            WHERE A.WorkingTag <> 'D'    
              AND A.Status = 0    
              AND ISNULL(B.AssyItemSeq, 0) = 0    
            
    END    
    --SELECT 192,* FROM #TPDMPSDailyProdPlan 
    IF @DeleteValue IS NULL  
        SELECT @DeleteValue = '0'  
    
    -----------------------------------------         
    -- 소요자재 생성 여부   --          
    -----------------------------------------            
    IF @DeleteValue = '1' --<생산계획>  MRP(소요자재) 생성된 데이터가 있을 경우 원천 생산계획/작업지시 건 삭제 불가 여부  
    BEGIN  
        IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'D'  AND Status = 0   )        
        BEGIN        
            IF EXISTS (SELECT 1 FROM _TPDMRPDailyItem AS A   
                                     JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq  = @CompanySeq    
                                                                   AND A.ProdPlanSeq = B.ProdPlanSeq       
                               WHERE B.WorkingTag = 'D'    
                                 AND B.Status = 0  )        
            BEGIN   
                EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                      @Status      OUTPUT,        
                                      @Results     OUTPUT,        
                                      1310               , -- @1의 @2이(가) 생성되어 있어 @3 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1310)        
                                      @LanguageSeq       , 
                                      2509,                -- 생산계획 (SELECT * FROM _TCADictionary WHERE WordSeq = 2509)  
                                      '',  
                                      34477,               -- 소요자재 (SELECT * FROM _TCADictionary WHERE WordSeq = 34477)  
                                      '',  
                                      308,                 -- 삭제 (SELECT * FROM _TCADictionary WHERE WordSeq = 308)  
                                      ''  
                       
                 UPDATE #TPDMPSDailyProdPlan          
                    SET Result        = ProdPlanNo + ':' + @Results,                            
                        MessageType   = @MessageType,          
                        Status        = @Status                   
            END        
        END     
    END  
      
    -------------------------------------------        
      -- 사용여부체크         
    -------------------------------------------       
    -------------------------------------------        
    -- 마감여부체크        
    -------------------------------------------        
    -- 공통 SP Call 예정        
        
    -------------------------------------------        
    -- 진행여부체크        
    -------------------------------------------        
    -- 공통 SP Call 예정        
        
    -------------------------------------------        
    -- 확정여부체크        
    -------------------------------------------        
    -- 공통 SP Call 예정        
    
    --POP 연동 처리 확인
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          8                  , -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                          @LanguageSeq       ,       
                          0, ''   -- SELECT * FROM _TCADictionary WHERE Word like '%자원%' 
    UPDATE A
       SET Result        = @Results,
           MessageType   = @MessageType,
           Status        = @Status
      FROM #TPDMPSDailyProdPlan AS A
           JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                  AND B.ProdPlanSeq = A.ProdPlanSeq
           JOIN KPX_TPDSFCWorkOrder_POP AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                         AND C.WorkOrderSeq = B.WorkOrderSeq
                                                         AND C.WorkOrderSerl = B.WorkOrderSerl
                                                         AND C.IsPacking = '0'
     WHERE C.ProcYN = '3'
       AND A.WorkingTag IN ('U', 'D')
    
    
    
    /* 제외 by이재천 ( 간트 저장시 실적있는 건은 저장Sp에서 아예 제외 시킴 )
    -----------------------------------------       
    -- 진행여부체크   --        
    -----------------------------------------          
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                            @Status      OUTPUT,      
                            @Results     OUTPUT,      
                            8                  , -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                            @LanguageSeq       ,       
                            0,    
                            '생산실적'   -- SELECT * FROM _TCADictionary WHERE Word like '%자원%'      
        
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('U','D')  AND Status = 0   )      
    BEGIN      
        --IF EXISTS (SELECT 1 FROM _TPDSFCWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq = @CompanySeq  AND A.ProdPlanSeq = B.ProdPlanSeq     
        --                                                                             WHERE B.WorkingTag  IN ('U','D')  AND B.Status = 0  )      
        --BEGIN      
             UPDATE A        
                SET Result        = replace(replace(@Results,'(@3)가(이)','이'),'@2',''),                          
                    MessageType   = @MessageType,        
                    Status        = @Status
               FROM #TPDMPSDailyProdPlan AS A   
                    JOIN _TPDSFCWorkOrder AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq AND O.ProdPlanSeq = A.ProdPlanSeq
                    JOIN _TPDSFCWorkReport AS B ON B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = O.WorkOrderSeq AND B.WorkOrderSerl = O.WorkOrderSerl
              WHERE A.WorkingTag = 'D'

            UPDATE A        
                SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                          
                    MessageType   = @MessageType,        
                    Status        = @Status
                    --select *
               FROM #TPDMPSDailyProdPlan AS A   
                    JOIN _TPDMPSDailyProdPlan AS B ON B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq
                
              WHERE A.WorkingTag = 'U'
                AND A.FactUnit <> B.FactUnit
                AND A.WorkCenterSeq <> B.WorkCenterSeq
                AND A.ItemSeq <> B.ItemSeq
                AND A.ProdPlanQty <> B.ProdQty
                AND A.WorkCond1 <> B.Workcond1
                AND A.WorkCond2 <> B.Workcond2
                AND A.WorkCond3 <> B.Workcond3
                AND A.SrtDate <> B.SrtDate
                AND A.EndDate <> B.EndDate
        --END      
    END      
    
    
    */
    -------------------------------------------       
    ---- 검사데이터 확인   --        
    ------------------------------------------- 
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,      
    --                        @Status      OUTPUT,      
    --                        @Results     OUTPUT,      
    --                        8                  , -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
    --                        @LanguageSeq       ,       
    --                        0,    
    --                        '검사실적'   -- SELECT * FROM _TCADictionary WHERE Word like '%자원%'  
    ----검사의뢰
    --UPDATE C       
    --   SET Result        = replace(replace(@Results,'(@3)가(이)','이'),'@2',''),                          
    --       MessageType   = @MessageType,        
    --       Status        = @Status
    --  FROM KPX_TQCTestRequestItem AS A
    --       JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq AND B.WorkOrderSeq = A.SourceSeq AND B.WorkOrderSerl = A.SourceSerl 
    --       JOIN #TPDMPSDailyProdPlan AS C ON B.ProdPlanSeq = B.ProdPlanSeq
    --       JOIN KPX_TQCTestResult AS D ON D.CompanySeq = A.CompanySeq AND D.ReqSeq = A.ReqSeq
    -- WHERE A.CompanySeq = @CompanySeq
    --   AND C.WorkingTag = 'U'
    --   AND C.Status = 0
    --   AND A.SMSouceType = 1000522004
    --   AND A.LotNo <> C.WorkCond3

    --SELECT 292,* FROM #TPDMPSDailyProdPlan 
    -------------------------------------------  
    -- 생산계획번호 규칙  
    -------------------------------------------      
    
        DECLARE @IDX_NO INT,    
                @ProdDate NCHAR(8),    
                @ProdPlanNo     NVARCHAR(100),    
                @CurrDate NCHAR(8),    
                @CurrDateYn NCHAR(1),    
                @FactUnit   INT    
           
    -- 생산사업장별 생산계획번호 설정(자동/수동) 추가로 로직 추가 2010. 12. 3. hkim    
    -- 생산사업장별로 셋팅한 경우          
    IF EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl AS A JOIN #TPDMPSDailyProdPlan AS B ON A.FirstUnit = B.FactUnit WHERE A.TableName = '_TPDMPSDailyProdPlan' AND A.CompanySeq = @CompanySeq AND A.IsAutoCreate = '1' )    
    BEGIN    
         IF ISNULL((SELECT BaseDateColumnName FROM _TCOMCreateNoDefine where CompanySeq = @CompanySeq and TableName = '_TPDMPSDailyProdPlan'),'') = ''     
        BEGIN    
            SELECT @CurrDateYn = '1'    
            SELECT @CurrDate = CONVERT(NCHAR(8), GetDATE(),112)    
        END    
    
       DECLARE Cursor1 CURSOR FOR        
           SELECT IDX_NO, ProdPlanEndDate, FactUnit  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0        
        OPEN Cursor1        
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate, @FactUnit    
        WHILE @@Fetch_Status = 0        
        BEGIN     
                IF @CurrDateYn = '1' SELECT @ProdDate = @CurrDate    
    
                EXEC dbo._SCOMCreateNo  'PD',       
                                        '_TPDMPSDailyProdPlan',       
                                        @CompanySeq,       
                                        @FactUnit,       
                                        @ProdDate,       
                                        @ProdPlanNo OUTPUT  
                                           
                UPDATE  #TPDMPSDailyProdPlan      
                   SET  ProdPlanNo  = ISNULL(@ProdPlanNo, '')    
              WHERE  IDX_NO = @IDX_NO        
    
            
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate,@FactUnit    
        END        
          CLOSE Cursor1        
        DEALLOCATE Cursor1      
        
    END    
    -- 법인별로 자동/수동 셋팅한 경우     
    ELSE IF (SELECT IsAutoCreate FROM _TCOMCreateNoDefine WHERE TableName = '_TPDMPSDailyProdPlan' and CompanySeq = @CompanySeq) = '1' AND NOT EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl WHERE CompanySeq = @CompanySeq AND TableName = '_TPDMPSDailyProdPlan' )      
    BEGIN    
        DECLARE @ProdDeptSeq    INT,        -- 생산관리부서 ( 생산계획입력화면에서 입력받음)  
                @DeptSeq        INT,         -- 로그인유저의 부서   
                @SecondInitialUnit INT     -- 부서 이니셜 사용시, @ProdDeptSeq OR @DeptSeq 값 사용  
  
        SELECT TOP 1 @DeptSeq = DeptSeq FROM #TPDMPSDailyProdPlan  
  
        IF ISNULL((SELECT BaseDateColumnName FROM _TCOMCreateNoDefine where CompanySeq = @CompanySeq and TableName = '_TPDMPSDailyProdPlan'),'') = ''     
        BEGIN    
            SELECT @CurrDateYn = '1'    
            SELECT @CurrDate = CONVERT(NCHAR(8), GetDATE(),112)    
        END    
    
          
        DECLARE Cursor1 CURSOR FOR        
           SELECT IDX_NO, SrtDate, FactUnit, ProdDeptSeq  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0  AND  ProdPlanNo = ''    
        OPEN Cursor1        
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate, @FactUnit, @ProdDeptSeq   
   
        WHILE @@Fetch_Status = 0        
        BEGIN        
    
                IF @CurrDateYn = '1' SELECT @ProdDate = @CurrDate    
                                  
                -- 두번째 이니셜코드 세팅  
                SELECT @SecondInitialUnit = CASE WHEN @ProdDeptSeq <> 0 THEN @ProdDeptSeq ELSE @DeptSeq END  
   
                EXEC dbo._SCOMCreateNo  'PD',       
                                        '_TPDMPSDailyProdPlan',       
                                        @CompanySeq,       
                                        @FactUnit,       
                                        @ProdDate,       
                                        @ProdPlanNo OUTPUT,  
                                        @SecondInitialUnit     
                                          
                UPDATE  #TPDMPSDailyProdPlan      
                   SET  ProdPlanNo  = ISNULL(@ProdPlanNo, '')    
                 WHERE  IDX_NO = @IDX_NO        
    
            
        FETCH NEXT FROM Cursor1 INTO @IDX_NO, @ProdDate,@FactUnit, @ProdDeptSeq    
        END        
        CLOSE Cursor1        
        DEALLOCATE Cursor1      
    
    END    
    
    --SELECT 389,* FROM #TPDMPSDailyProdPlan 
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1107                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1107)      
          @LanguageSeq       ,   -- SELECT * FROM _TCAMessageLanguage WHERE Message like '%등록된%'    
                        0,    
                        '생산계획번호'   -- SELECT * FROM _TCADictionary WHERE Word like '%등록된%'      
    
    
     
    -- 생산계획번호 자동생성이 아니면 중복체크   :: 자동채번인 경우에도 수동 입력시는 중복체크가 필요함으로.. 주석처리 2012.07.11 BY 허승남  
    --IF (SELECT IsAutoCreate FROM _TCOMCreateNoDefine WHERE TableName = '_TPDMPSDailyProdPlan' and CompanySeq = @CompanySeq) <> '1'     
    --    AND NOT EXISTS (SELECT 1 FROM _TCOMCreateNoDefineDtl AS A JOIN #TPDMPSDailyProdPlan AS B ON A.FirstUnit = B.FactUnit WHERE A.TableName = '_TPDMPSDailyProdPlan' AND A.CompanySeq = @CompanySeq)    
    --BEGIN     
        IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('A')  AND Status = 0 AND ISNULL(FromTableSeq, 0) <> 7 )      
        BEGIN    
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                          
                   MessageType   = @MessageType,        
                   Status        = @Status                    
              FROM #TPDMPSDailyProdPlan As A JOIN _TPDMPSDailyProdPlan  AS B ON A.ProdPlanNo = B.ProdPlanNo AND B.CompanySeq = @CompanySeq       
               WHERE A.WorkingTag = 'A'    
      AND A.Status = 0  
        END    
  
                                      
                                  
                                      
    -- 생산계획 번호가 자동 채번 및 입력 된 값이 없는지 체크    2010. 12. 3. hkim    
    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag IN ('A', 'U') AND Status = 0 AND ProdPlanNo = '')    
    BEGIN    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1039                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)      
                        @LanguageSeq       ,   -- SELECT * FROM _TCAMessageLanguage WHERE Message like '%등록된%'    
                        0,    
                        '생산계획번호'   -- SELECT * FROM _TCADictionary WHERE Word like '%등록된%'      
        
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = @Results, --replace(replace(@Results,'(@3)',''),'@2',''),                          
                   MessageType   = @MessageType,        
                   Status        = @Status      
              FROM #TPDMPSDailyProdPlan AS A     
             WHERE A.WorkingTag IN ('A', 'U')    
               AND Status = 0    
               AND ProdPlanNo = ''    
    END    
       
-- 생산계획번호를 수정했을 경우 중복체크 해준다     --  2011.03.29 김세호 추가    
    
    IF EXISTS(SELECT 1 FROM #TPDMPSDailyProdPlan AS A    
                       JOIN _TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq     
                                                     AND B.CompanySeq  = @CompanySeq    
                        WHERE A.WorkingTag = 'U'     
                          AND A.ProdPlanNo <> B.ProdPlanNo  
                          AND ISNULL(A.FromTableSeq, 0) <> 7)    
     BEGIN    
    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                        @Status      OUTPUT,      
                        @Results     OUTPUT,      
                        1107                  ,      
                        @LanguageSeq       ,       
                        1524,    
                        '생산계획번호',    
                        1524,    
                        '생산계획번호'    
    
            UPDATE #TPDMPSDailyProdPlan        
               SET Result        = @Results,                
                   MessageType   = @MessageType,        
                   Status        = @Status      
              FROM #TPDMPSDailyProdPlan AS A      
     
             WHERE A.WorkingTag IN ('U')    
    AND A.Status = 0    
               AND A.ProdPlanNo <> ''     
               AND A.ProdPlanNo IN (SELECT ProdPlanNo FROM  _TPDMPSDailyProdPlan WHERE CompanySeq = @CompanySeq)      
     END    

    

    -------------------------------------------        
    -- INSERT 번호부여(맨 마지막 처리)        
    -------------------------------------------       
        
    SELECT @Count = COUNT(1) FROM #TPDMPSDailyProdPlan WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)    
    IF @Count > 0        
    BEGIN           
    
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDMPSDailyProdPlan', 'ProdPlanSeq', @Count        
               
        UPDATE #TPDMPSDailyProdPlan        
           SET ProdPlanSeq = @Seq + DataSeq    
         WHERE WorkingTag = 'A'       
           AND Status = 0                   
    END
--select * from #TPDMPSDailyProdPlan
    -------------------------------------------  
    --LotNo부여
    -------------------------------------------  
    CREATE TABLE #ProdPlan(IDX INT IDENTITY(1,1), ProdPlanSeq INT, LotNo NVARCHAR(100), ItemName NVARCHAR(100), ItemSeq INT,
                           BaseMM NCHAR(6), IsFlake NCHAR(1), IsMon NCHAR(1), SrtDate NCHAR(8), WCNo NCHAR(2), SrtTime NCHAR(4))
    
    SELECT ROW_NUMBER() OVER(ORDER BY A.ItemSeq) AS IDX,
           A.ItemSeq,
           CASE WHEN D.MngValSeq = 1010361002 THEN '1'
                ELSE '0' END AS IsFlake,
           (SELECT '1' FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 27
                                          AND EnvValue = A.ItemSeq AND D.MngValSeq = 1010361002) AS IsMon,
           MIN(A.SrtDate) AS SrtDate
      INTO #ProdItem
      FROM #TPDMPSDailyProdPlan AS A
           LEFT OUTER JOIN _TDAItemUserDefine AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                               AND D.ItemSeq = A.ItemSeq
                                                               AND D.MngSerl = 1000001
     WHERE A.WorkingTag = 'A'
     GROUP BY A.ItemSeq, D.MngValSeq
   /*
--select * FROM #TPDMPSDailyProdPlan 
--select * from #ProdItem
    DECLARE @IDX        INT,
            @MaxIDX     INT,
            @PlanIDX    INT,
            @PlanMaxIDX INT,
            @MaxLotNo   NVARCHAR(100),
            @BaseMM     NCHAR(6)
    
    SELECT @IDX = 1,
           @MaxIDX = MAX(IDX) FROM #ProdItem
--select * from #ProdItem
    WHILE(1=1)
    BEGIN
        --DELETE #ProdPlan
        
        INSERT INTO #ProdPlan
             SELECT DISTINCT B.ProdPlanSeq, '', I.ItemName, A.ItemSeq, LEFT(B.SrtDate,6),
                    A.IsFlake, A.IsMon, B.SrtDate, ISNULL(R.WCNo,''), B.WorkCond1
               FROM #ProdItem AS A
                    JOIN #TPDMPSDailyProdPlan AS B ON B.ItemSeq = A.ItemSeq AND B.WorkingTag = 'A'
                    JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq
                    LEFT OUTER JOIN KPX_TPDWorkCenterRate AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                                           AND R.WorkCenterSeq = B.WorkCenterSeq
              WHERE IDX = @IDX
              ORDER BY B.SrtDate, B.WorkCond1

        SELECT @PlanIDX = 1,
               @PlanMaxIDX = MAX(IDX) FROM #ProdPlan
        SELECT @BaseMM = BaseMM FROM #ProdPlan

        IF EXISTS (SELECT 1 FROM #ProdPlan WHERE IsFlake = '0')
        BEGIN
            SELECT @MaxLotNo = MAX(RIGHT(WorkCond3,4)) 
              FROM _TPDMPSDailyProdPlan 
             WHERE CompanySeq = @CompanySeq
               AND LEFT(SrtDate,6) = @BaseMM
               AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')

--SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0'
--select MAX(RIGHT(WorkCond3,4))
--FROM _TPDMPSDailyProdPlan 
--WHERE CompanySeq = @CompanySeq
--AND LEFT(SrtDate,6) = @BaseMM
--AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
--select * from #ProdPlan

            IF ISNULL(@MaxLotNo,'') = ''
                SELECT @MaxLotNo = '0000'
            
            WHILE(1=1)
            BEGIN
--select * 
--FROM #ProdPlan AS A
--                       JOIN (SELECT ROW_NUMBER() OVER(ORDER BY SrtDate, SrtTime) AS IDX, 
--                                    ProdPlanSeq
--                               FROM #ProdPlan
--                              WHERE ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')) AS B ON B.ProdPlanSeq = A.ProdPlanSeq
--                 WHERE A.IsFlake = '0'
--                   AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
                   
                UPDATE A 
                   SET LotNo = RIGHT(BaseMM,4)+
                               --'-'+ 
                               RIGHT(CONVERT(NVARCHAR(10), '0000'+CONVERT(NVARCHAR(10),(CONVERT(INT, @MaxLotNo)+
                                    B.IDX))),4)
                  FROM #ProdPlan AS A
                       JOIN (SELECT ROW_NUMBER() OVER(ORDER BY SrtDate, SrtTime) AS IDX, 
                                    ProdPlanSeq
                               FROM #ProdPlan
                              WHERE ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')) AS B ON B.ProdPlanSeq = A.ProdPlanSeq
                 WHERE A.IsFlake = '0'
                   AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '0')
                 

                SELECT @PlanIDX = @PlanIDX +1
                IF @PlanIDX > ISNULL(@PlanMaxIDX, 0) 
                    BREAK
            END
        END

        --Flake -  특정제품 LotNo 7자리   = 월별발생 년(2)+월(2)+일(3)     
        IF EXISTS (SELECT 1 FROm #ProdPlan WHERE IsFlake = '1' AND ISNULL(IsMon,'0') = '1')
        BEGIN
            SELECT @MaxLotNo = MAX(WorkCond3) 
              FROM _TPDMPSDailyProdPlan 
             WHERE CompanySeq = @CompanySeq
               AND LEFT(SrtDate,6) = @BaseMM
               AND ItemSeq = (SELECT ItemSeq FROM #ProdItem WHERE IDX = @IDX AND IsFlake = '1' AND IsMon = '1')
            
            IF ISNULL(@MaxLotNo, '') = ''
                SELECT @MaxLotNo = SUBSTRING(SrtDate,3,4)+'0'+RIGHT(SrtDate, 2)
                  FROM #ProdItem 
                 WHERE IDX = @IDX AND IsFlake = '1' AND IsMon = '1'
            
            UPDATE A
               SET LotNo = @MaxLotNo
              FROM #ProdPlan AS A
             WHERE A.IsFlake = '1' AND IsMon = '1'
        END
        
        --Flake -  일반제품 LotNo 8자리 = 일별 년(2)+월(2)+일(2)+반응기(2)
        IF EXISTS (SELECT 1 FROm #ProdPlan WHERE IsFlake = '1' AND ISNULL(IsMon,'0') = '0')
        BEGIN

            SELECT @MaxLotNo = ''

            UPDATE A
               SET LotNo = CASE WHEN @MaxLotNo ='' THEN SUBSTRING(SrtDate,3,4)+RIGHT(SrtDate, 2) 
                                ELSE @MaxLotNo END
                           +RIGHT('00'+A.WCNo, 2)
              FROM #ProdPlan AS A
             WHERE A.IsFlake = '1' AND ISNULL(IsMon,'0') = '0'
        END
                
        SELECT @IDX = @IDX +1
        IF @IDX > ISNULL(@MaxIDX, 0) 
            BREAK
    END
--select * from #ProdPlan
    UPDATE A
       SET WorkCond3 = B.LotNo
      FROM #TPDMPSDailyProdPlan AS A
           JOIN #ProdPlan AS B ON B.ProdPlanSeq = A.ProdPlanSeq
     WHERE A.WorkingTag = 'A'
       AND A.NodeId NOT IN (SELECT PredecessorNodeID FROM #Link)
       AND A.NodeId NOT IN (SELECT SuccessorNodeID FROM #Link)
    */       
    --SELECT * from #ProdPlan
      
    SELECT * FROM #TPDMPSDailyProdPlan       
    --SELECT * FROM #Link
     --where PredecessorNodeID <> 0
       --Or SuccessorNodeID <> 0
RETURN          
/******************************************************************************************************************************************************/
GO


