IF OBJECT_ID('KPXCM_SPDMPSProdPlanCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDMPSProdPlanCheck
GO 

-- v2015.09.22 

-- 천안공장 LotNo 필수 체크 by이재천 

/************************************************************    
  설  명 - 데이터-생산계획입력 : 체크    
  작성일 - 20090826    
  작성자 - 이성덕    
  UPDATE ::  생산계획 번호 수정시 중복 체크 추가     :: 2011.03.29 BY 김세호  
         ::  제목의 BOM/생산단위 환산정보 없을 경우 체크 :: 2011.11.28 BY 김세호   
         ::  제품별공정별소요자재등록에 공정품누락되어 있을경우 체크 :: 2011.12.21 BY 김세호 
         ::  계획번호 채번시 이니셜단위 부서도 적용되도록 수정   :: 2012.01.05  BY 김세호
         ::  생산계획 수량 0 이하일 경우 체크                    ::  12.05.16 BY 김세호
         ::  프로젝트에서 넘어온건일경우 (FromtableSeq = 7) 생산계획 중복 허용       :: 12.07.04 BY 김세호
         ::  자동채번을 사용하는 경우라도 생산번호를 수동으로 입력한 경우 수동입력된게 적용되도록 수정  :: 12.07.11 BY 허승남 
 ************************************************************/    
 CREATE PROC dbo.KPXCM_SPDMPSProdPlanCheck   
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
       
     IF EXISTS (select * from sysobjects where name like @SiteInitialName +'_SPDMPSProdPlanCheck')      
     BEGIN      
         SELECT @SPName = @SiteInitialName +'_SPDMPSProdPlanCheck'      
               
         EXEC @SPName @xmlDocument,@xmlFlags,@ServiceSeq,@WorkingTag,@CompanySeq,@LanguageSeq,@UserSeq,@PgmSeq      
         RETURN            
       
     END      
       
     
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
    
     EXEC dbo._SCOMEnv @CompanySeq,6266,@UserSeq,@@PROCID,@DeleteValue OUTPUT
    
    UPDATE A 
       SET Result = '[LotNo] 필수항목이 누락되었습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPDMPSDailyProdPlan AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND A.FactUnit = 6 -- 천안공장 
       AND ISNULL(A.WorkCond3,'') = '' 
    
 /*****************************************************************************************************************/  
 -- 제품별공정별 소요자재 등록여부  
 /*****************************************************************************************************************/  
   
   
     IF (SELECT Count(*) FROM #TPDMPSDailyProdPlan AS A LEFT OUTER JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq AND A.BOMRev = B.BOMRev and A.ProcRev = B.ProcRev AND B.CompanySeq = @CompanySeq  
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
   
     IF (SELECT COUNT(*) FROM #TPDMPSDailyProdPlan              AS A  
                              LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev  
                              LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq  
                              LEFT OUTER JOIN _TPDROUItemProcWC AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev AND C.ProcSeq = D.ProcSeq                  
                        WHERE A.WorkingTag <> 'D'  
                          AND A.Status = 0  
                          AND D.ItemSeq IS NULL ) > 0  
     BEGIN   
         UPDATE #TPDMPSDailyProdPlan      
            SET Result        = '제품별 공정별 워크센터가 등록되지 않은 품목입니다.',                        
                MessageType   = 17009,      
                Status        = 1    
           FROM #TPDMPSDailyProdPlan              AS A  
                LEFT OUTER JOIN _TPDROUItemProcRev           AS B ON B.companySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev  
                LEFT OUTER JOIN _TPDProcTypeItem             AS C ON C.companySeq = @CompanySeq AND B.ProcTypeSeq = C.ProcTypeSeq  
                LEFT OUTER JOIN _TPDROUItemProcWC AS D ON D.companySeq = @CompanySeq AND A.FactUnit = D.FactUnit AND A.ItemSeq = D.ItemSeq AND A.ProcRev = D.ProcRev AND C.ProcSeq = D.ProcSeq                  
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
        SET Result        = REPLACE(@Results, '의', '(' + A.ItemNo + ')'),                        
            MessageType   = @MessageType,      
            Status        = @Status    
       FROM #TPDMPSDailyProdPlan AS A  
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
         
   
 /****************************************************************************************************************/  
 -- 제품별공정별소요자재에 공정품 누락되어 있는 경우 체크        --  11.12.21 BY 김세호  
 /*****************************************************************************************************************/  
   
   
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
     
 -- 작업지시조정에서 생산시적 진행되었을경우 잔량에 대한 조정이 안되고있으므로 일단 주석처리
 -- 작업지시조정에서 잔량에 대해서도 조정 가능하도록 수정되면 해당 주석은 해지 할 예정       -- 12.07.12 BY 김세호
 --/****************************************************************************************************************/  
 ---- 생산계획 수량 0 이하일 경우 체크        --  12.05.16 BY 김세호
 --/*****************************************************************************************************************/  
 --
 --    IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag IN ('A', 'U') AND Status = 0 AND ProdPlanQty <= 0) 
 --     BEGIN
 --
 --
 --        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
 --                            @Status      OUTPUT,    
 --                            @Results     OUTPUT,    
 --                            1196                  , -- @을(를) 확인하세요
 --                            @LanguageSeq       ,     
 --                            6423,''                   -- 생산계획수량  
 --
 --        UPDATE #TPDMPSDailyProdPlan 
 --           SET Result        = @Results,               
 --               MessageType   = @MessageType,      
 --               Status        = @Status  
 --          FROM #TPDMPSDailyProdPlan 
 --         WHERE WorkingTag IN ('A', 'U') 
 --           AND Status = 0 
 --           AND ProdPlanQty <= 0
 --
 --
 --     END
    
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
        
   
       -----------------------------------------     
     -- 진행여부체크   --      
     -----------------------------------------        
       EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                             @Status      OUTPUT,    
                             @Results     OUTPUT,    
                             8                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)    
                             @LanguageSeq       ,     
                             0,  
                             '작업지시'   -- SELECT * FROM _TCADictionary WHERE Word like '%자원%'    
      
       
       
     IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan WHERE WorkingTag  IN ('U','D')  AND Status = 0   )    
     BEGIN    
         IF EXISTS (SELECT 1 FROM _TPDSFCWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.CompanySeq = @CompanySeq  AND A.ProdPlanSeq = B.ProdPlanSeq   
                                                                                      WHERE B.WorkingTag  IN ('U','D')  AND B.Status = 0  )    
         BEGIN    
              UPDATE #TPDMPSDailyProdPlan      
                 SET Result        = replace(replace(@Results,'(@3)',''),'@2',''),                        
                     MessageType   = @MessageType,      
                     Status        = @Status               
         END    
     END    
          
   
   
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
            SELECT IDX_NO, ProdPlanEndDate, FactUnit, ProdDeptSeq  FROM #TPDMPSDailyProdPlan  WHERE WorkingTag = 'A' AND Status = 0  AND  ProdPlanNo = ''  
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
   
 --#####################################################################
 --중복된 생산계획번호 체크         
 --#####################################################################
       --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       --                      @Status      OUTPUT,  
       --                      @Results     OUTPUT,  
       --                      6                  , -- 중복된 데이터가 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
       --                      @LanguageSeq       ,   
       --                      1524,''   -- SELECT * FROM _TCADictionary WHERE Word like '%생산계획번호%'  
  
       --UPDATE #TPDMPSDailyProdPlan  
       --   SET Result        = REPLACE(@Results,'@2',A.ProdPlanNo),  
       --       MessageType   = @MessageType,  
       --       Status        = @Status  
       --  FROM #TPDMPSDailyProdPlan AS A JOIN ( SELECT S.ProdPlanNo  
       --                                 FROM (  
       --                                       SELECT A1.ProdPlanNo  
       --                                         FROM #TPDMPSDailyProdPlan AS A1  
       --                                        WHERE A1.WorkingTag IN ('A','U')  
       --                                          AND A1.Status = 0  
       --                                       UNION ALL  
       --                                       SELECT A1.ProdPlanNo  
       --                                         FROM _TPDMPSDailyProdPlan AS A1  
       --                                        WHERE A1.Companyseq = @CompanySeq
       --                                          AND A1.ProdPlanSeq NOT IN (SELECT ProdPlanSeq   
       --                                                                       FROM #TPDMPSDailyProdPlan   
       --                                                                      WHERE WorkingTag IN ('U','D')   
       --                                                                        AND Status = 0)  
       --                                      ) AS S  
       --                                GROUP BY S.ProdPlanNo  
       --                                HAVING COUNT(1) > 1  
       --                              ) AS B ON (A.ProdPlanNo = B.ProdPlanNo)  
  
                                      
                                     
                                     
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
     
     SELECT * FROM #TPDMPSDailyProdPlan     
       
 RETURN        
 go
 begin tran 
 exec KPXCM_SPDMPSProdPlanCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>아산공장</FactUnitName>
    <ProdPlanNo />
    <ProdPlanDate>20150922</ProdPlanDate>
    <ItemName>2- 반제품(제품)</ItemName>
    <ItemNo>2- 반제품(제품)</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <BOMRevName>00</BOMRevName>
    <ProcRevName>최종공정</ProcRevName>
    <ProdPlanQty>1</ProdPlanQty>
    <ProdPlanEndDate>20150922</ProdPlanEndDate>
    <ProdDeptName />
    <Remark />
    <FromTableSeq>0</FromTableSeq>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <ToTableSeq>0</ToTableSeq>
    <FromQty>0</FromQty>
    <FromSTDQty>0</FromSTDQty>
    <ProdDeptSeq />
    <FactUnit>1</FactUnit>
    <ProcRev>00</ProcRev>
    <ItemSeq>24635</ItemSeq>
    <ProdPlanSeq />
    <BOMRev>00</BOMRev>
    <UnitSeq>2</UnitSeq>
    <WorkCond1 />
    <WorkCond2 />
    <WorkCond3 />
    <WorkCond4>0</WorkCond4>
    <WorkCond5>0</WorkCond5>
    <WorkCond6>0</WorkCond6>
    <WorkCond7>0</WorkCond7>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <DeptSeq>1300</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=5295,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5987
rollback 