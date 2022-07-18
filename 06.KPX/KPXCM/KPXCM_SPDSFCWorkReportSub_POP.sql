IF OBJECT_ID('KPXCM_SPDSFCWorkReportSub_POP') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportSub_POP
GO 

/************************************************************    
 설  명 - 작업실적스케줄    
 작성일 - 2014-12-07    
 작성자 - 전경만    
************************************************************/    
CREATE PROCEDURE KPXCM_SPDSFCWorkReportSub_POP
    @CompanySeq     INT = 2,             -- 법인        
    @MainSeq        INT, 
    @Status         INT = null OUTPUT, 
    @Result         NVARCHAR(500) = NULL OUTPUT, 
    @MessageType    INT = NULL OUTPUT 
AS      
    DECLARE  @CurrDATETIME          DATETIME            -- 현재일      
            ,@XmlData               NVARCHAR(MAX)      
            ,@Seq                   INT      
            ,@MaxNo                 NVARCHAR(50)      
            ,@FactUnit              INT      
            ,@Date                  NVARCHAR(8)      
            ,@DataSeq               INT      
            ,@Count                 INT,    
            @UserSeq                INT 

    
    UPDATE A
       SET ProcYn = '0', 
           ErrorMessage = ''
      FROM KPX_TPDSFCWorkReport_POP AS A 
     WHERE A.Seq = @MainSeq 
    
    SELECT @CurrDATETIME    = GETDATE()      
    
    --실적 정보 중 작업지시가 없는 것은 무시한다.    
    UPDATE A    
       SET ProcYN = '7',    
           ErrorMessage = '작업지시 정보가 없습니다.'    
      FROM KPX_TPDSFCWorkReport_POP AS A    
           LEFT OUTER JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq and B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkORderSerl    
     WHERE A.Seq = @MainSeq 
       AND A.CompanySeq = @CompanySeq 
       AND ISNULL(B.CompanySeq,0) = 0 
    
    
    --select * from _TPDSFCWorkOrder where WorkOrderSeq = 130701
	 --UPDATE A    
  --     SET ProcYN = '7',    
  --         ErrorMessage = 'pop연동 정보 임시 취소'    
  --    FROM KPX_TPDSFCWorkReport_POP AS A    
  --    WHERE A.ProcYN = '0'    
  --     AND A.IsPacking = '0'    
  --     AND A.CompanySeq = @CompanySeq    
	--   and A.EmpSeq <> 1064
    
    --실적 최초 데이터가 수정,삭제인 정보는 무시한다.    
    UPDATE Z
       SET ProcYN = '8',    
           ErrorMessage = '실적 최초 데이터가 삭제인 정보는 무시한다.'    
      FROM KPX_TPDSFCWorkReport_POP AS Z
     WHERE Z.CompanySeq = @CompanySeq 
       AND Z.WorkingTag IN ( 'U', 'D' ) 
       AND Z.Seq = @MainSeq 
       AND NOT EXISTS (
                        SELECT 1
                          FROM KPX_TPDSFCWorkReport_POP AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.IFWorkReportSeq = Z.IFWorkReportSeq
                           AND A.WorkingTag = 'A' 
                           AND A.Seq < Z.Seq  
                      ) 
    
    
    -- I/F 대상 실적건 담기 (KPX_TPDSFCWorkReport_POP)      
    SELECT TOP 1     
            ROW_NUMBER() OVER(ORDER BY A.Seq) AS RowCnt    
            ,A.CompanySeq        
            ,A.Seq        
            ,A.IFWorkReportSeq        
            ,0      AS WorkReportSeq      
            ,ISNULL(A.WorkOrderSeq, 0)      AS WorkOrderSeq        
            ,ISNULL(A.WorkOrderSerl, 0)     AS WorkOrderSerl    
            ,IsPacking    
            ,A.WorkTimeGroup      
            ,A.WorkStartDate    
            ,A.WorkEndDate    
            ,A.WorkCenterSeq      
            ,A.GoodItemSeq      
            ,A.ProcSeq      
            ,W.AssyItemSeq      
            ,A.ProdUnitSeq      
            ,A.ProdQty      
            ,A.OkQty      
            ,A.BadQty      
            ,A.WorkStartTime      
            ,A.WorkEndTime      
            ,A.WorkMin                     -- 생산시간(분)    
            ,ISNULL(A.RealLotNo,'')   AS RealLotNo      
            ,A.WorkType      
            ,ISNULL(A.OutKind,0)   AS OutKind      
            ,CASE WHEN ISNULL(A.RegEmpSeq, 0) = 0 THEN 1 ELSE A.RegEmpSeq END                 AS EmpSeq      
            ,A.Remark      
            ,A.ProcDateTime      
            ,A.ProcYn      
            ,A.ErrorMessage                ,(CASE WHEN ISNULL(A.FactUnit, 0) = 0 THEN B.FactUnit ELSE A.FactUnit END)  AS FactUnit      
            ,(CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN B.DeptSeq ELSE A.DeptSeq END)     AS DeptSeq      
            ,0                                                                          AS BizUnit      
            ,0                                                                          AS Status      
            ,CONVERT(NVARCHAR(100), '')                                                 AS Result      
            ,CONVERT(DECIMAL(19,5), 0)                                                  AS StdUnitProdQty      
            ,CONVERT(DECIMAL(19,5), 0)                                                  AS StdUnitBadQty      
            ,A.WorkingTag    
            --,A.HambaQty    
            --,ISNULL(A.RealWorkHour, 0)             AS WorkCond4  -- 실가동시간(= 보유시간 - 비가동시간)      
      INTO #Temp_Source        
      FROM KPX_TPDSFCWorkReport_POP     AS A        
           JOIN _TPDBaseWorkCenter      AS B ON A.CompanySeq = B.CompanySeq        
                                            AND A.WorkCenterSeq = B.WorkCenterSeq        
           LEFT OUTER JOIN _fnadmEmpOrd(@CompanySeq, '') AS E ON E.EmpSeq = A.RegEmpSeq    
           LEFT OUTER JOIN _TDAItemUnit AS U ON A.CompanySeq = U.CompanySeq
                                            And A.GoodItemSeq = U.ItemSeq        
                                            AND A.ProdUnitSeq = U.UnitSeq         
           JOIN _TPDSFCWorkOrder AS W ON W.CompanySeq = @CompanySeq AND W.WorkOrderSeq = A.WorkOrderSeq AND W.WorkOrderSerl = A.WorkOrderSerl    
    WHERE A.CompanySeq = @CompanySeq
       And ISNULL(A.ProcYN ,'0') = '0'    
       AND A.Seq = @MainSeq 
    
    UPDATE A    
       SET ProcYN = '5' --처리시작    
      FROM KPX_TPDSFCWorkReport_POP AS A    
     WHERE A.CompanySeq = @CompanySeq
       And ISNULL(A.ProcYN ,'0') = '0'    
       AND Seq = @MainSeq 
    

       
    IF NOT EXISTS (SELECT 1 FROM #Temp_Source)    
    BEGIN    
        RETURN    
    END    
    
    
    --select * from #Temp_Source 
    
    --select * from _TCAUser where EmpSeq = 1388
    --return 
    
    SELECT @UserSeq = U.UserSeq 
      FROM #Temp_Source AS A    
           LEFT OUTER JOIN _TCAUSer AS U ON U.CompanySeq = @CompanySeq AND U.EmpSeq = A.EmpSeq    
    
    SELECT @UserSeq = ISNULL(@UserSeq,0)
    
    
    UPDATE A       
       SET DeptSeq = (SELECT DeptSeq FROM _FnadmEmpOrd(@CompanySeq, '') WHERE EmpSeq = A.EmpSeq)      
      FROM #Temp_Source AS A      
     WHERE ISNULL(DeptSeq, 0) = 0      
      
    -- 사업부문 UPDATE 및 기준단위 환산 (생산/양품/불량 수량은 실적Save SP 내에서 환산해주지만, 그전에 생산/불량 기준단위수량은 사용되어서 환산 미리해줌)        
    UPDATE A        
       SET BizUnit = B.BizUnit        
            ,StdUnitProdQty = (CASE WHEN ISNULL(U.ConvDen, 0) = 0 THEN A.ProdQty         
                               ELSE A.ProdQty * (CONVERT(DECIMAL(19, 10), U.ConvNum / U.ConvDen)) END)         
            ,StdUnitBadQty =  (CASE WHEN ISNULL(U.ConvDen, 0) = 0 THEN A.BadQty         
                               ELSE A.BadQty * (CONVERT(DECIMAL(19, 10), U.ConvNum / U.ConvDen)) END)               
      FROM #Temp_Source    AS A        
           JOIN _TDAFactUnit        AS B ON A.CompanySeq = B.CompanySeq        
                           AND A.FactUnit = B.FactUnit        
           LEFT OUTER JOIN _TDAItemUnit     AS U ON A.CompanySeq = U.CompanySeq  
                                                AnD A.GoodItemSeq = U.ItemSeq        
                                                AND A.ProdUnitSeq = U.UnitSeq            
                                                
    ALTER TABLE #Temp_Source ADD WorkDate NCHAR(8)    
    
    
    --=================================================================================        
    -- 트랜젝션 시작 부분        
    --=================================================================================        
    --SET LOCK_TIMEOUT -1        
    --BEGIN TRANSACTION        
    --BEGIN TRY       
            
    --WHILE (1=1)    
    --BEGIN    
    --    IF ISNULL(@MaxCnt,0) < @Cnt    
    --        BREAK    
    
    
    
    --Row별 처리를 위해 위에서(#Temp_Source)에서 받은 내용을 하나씩 #TMP_TPDSFCWorkReport로 생성한다.    
    IF OBJECT_ID('tempdb..#TMP_TPDSFCWorkReport') IS NOT NULL      
    BEGIN      
       DROP TABLE #TMP_TPDSFCWorkReport      
    END     
    
    SELECT *     
      INTO #TMP_TPDSFCWorkReport    
      FROM #Temp_Source    
    
    UPDATE A    
       SET WorkReportSeq = ISNULL((SELECT MAX(P.WorkReportSeq)     
                                     FROM KPX_TPDSFCWorkReport_POP AS P    
                                          JOIN _TPDSFCWorkReport AS R ON R.CompanySeq = P.CompanySeq     
                                                                     AND R.WorkOrderSeq = P.WorkOrderSeq    
                                                                     AND R.WorkOrderSerl = P.WorkOrderSerl    
                                                                     AND R.WorkReportSeq = P.WorkReportSeq    
                                    WHERE P.CompanySeq = A.CompanySeq     
                                      AND P.WorkOrderseq = A.WorkOrderSeq     
                                      AND P.WorkOrderSerl = A.WorkOrderSerl     
                                      AND P.IFWorkReportSeq = A.IFWorkReportSeq),0)    
      FROM #TMP_TPDSFCWorkReport AS A    
     WHERE A.WorkingTag in ( 'D','U')
	     

	/*------------------------------------------------------------------------------------------------------------------------------        
		수불 마감 체크         
	  ------------------------------------------------------------------------------------------------------------------------------*/        
    UPDATE A    
       SET WorkDate = WorkEndDate    
      FROM #TMP_TPDSFCWorkReport AS A    
    IF OBJECT_ID('tempdb..#TMP_CloseItemCheck') IS NOT NULL      
    BEGIN      
       DROP TABLE #TMP_CloseItemCheck      
    END     
    SELECT  DISTINCT          
            A.WorkingTag        AS WorkingTag,            
            IDENTITY(INT,1,1)   AS DataSeq,            
            0                   AS Status,            
            0                   AS Selected,            
           'DataBlock2'         AS TABLE_NAME,         
            A.GoodItemSeq       AS ItemSeq,        
            A.BizUnit           AS BizUnit,        
            A.BizUnit           AS BizUnitOld,           
            2894                AS ServiceSeq,        
            2                   AS MethodSeq,        
            A.DeptSeq           AS DeptSeq,          
            A.WorkDate          AS Date,        
            A.WorkDate          AS DateOld,        
            A.Seq               AS Seq        
      INTO #TMP_CloseItemCheck        
      FROM #TMP_TPDSFCWorkReport    AS A        
     --WHERE A.RowCnt = @Cnt    
        
    ------------------------------            
    -- Temp테이블 데이터 XMl로 생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(SELECT  DataSeq  AS IDX_NO, *             
                                                  FROM #TMP_CloseItemCheck            
   FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS))           
        
        
 IF OBJECT_ID('tempdb..#TCOMCloseItemCheck') IS NOT NULL      
 BEGIN      
  DROP TABLE #TCOMCloseItemCheck      
 END     
    CREATE TABLE #TCOMCloseItemCheck (WorkingTag NCHAR(1) NULL)                
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2639, 'DataBlock2', '#TCOMCloseItemCheck'         
    
    --select @XmlData 
    --return 
    /*
    INSERT INTO #TCOMCloseItemCheck        
    EXEC _SCOMCloseItemCheck            
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2639,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015         

    
    --select * From #TCOMCloseItemCheck 
    --return 

    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SCOMCloseItemCheck''', 15, 1)        
    END        
    
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
      IF EXISTS (SELECT 1 FROM  #TCOMCloseItemCheck WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TCOMCloseItemCheck
            
            RETURN  
     END         
  
    */
    
    
/*------------------------------------------------------------------------------------------------------------------------------        
    생산실적 체크         
------------------------------------------------------------------------------------------------------------------------------*/        
 IF OBJECT_ID('tempdb..#TMP_TPDSFCWorkReport_Xml') IS NOT NULL      
 BEGIN      
  DROP TABLE #TMP_TPDSFCWorkReport_Xml      
 END     
    SELECT  A.WorkingTag                AS WorkingTag      
            ,IDENTITY(INT, 1, 1)        AS DataSeq      
            ,0                          AS Status      
            ,0                          AS Selected      
            ,'DataBlock1'               AS TABLE_NAME      
            ,'00'                       AS ItemBomRevName      
            ,A.ProdQty      
            ,A.OKQty      
            ,A.BadQty      
            ,A.BadQty                   AS ReOrderQty      
            ,0                          AS LossCostQty      
            ,0                          AS DisuseQty      
            ,A.WorkStartTime      
            ,A.WorkEndTime      
            ,(A.WorkMin/60.0)           AS WorkHour     
            ,0                          AS WorkerQty      
            ,0                          AS ProcHour    
            ,A.RealLotNo      
            ,''                         AS SerialNoFrom      
            ,''                         AS SerialNoTo      
            ,A.WorkstartDate            AS WorkCondition1      
            ,A.WorkEndDate              AS WorkCondition2      
            ,''                         AS WorkCondition3      
            ,A.WorkMin                  AS WorkCondition4      
            ,0                          AS WorkCondition5      
            ,0                          AS WorkCondition6      
            ,A.StdUnitBadQty            AS StdUnitReOrderQty      
            ,0                          AS StdUnitLossCostQty      
            ,0                          AS StdUnitDisuseQty      
            ,N'연동생성 실적건'         AS Remark      
            ,'00'                       AS ProcRev      
            ,A.WorkReportSeq            AS WorkReportSeq      
            ,A.WorkOrderSeq      
            ,A.WorkCenterSeq      
            ,A.AssyItemSeq      
            ,A.ProcSeq      
            ,A.ProdUnitSeq      
        ,0                          AS ChainGoodsSeq      
            ,EmpSeq                     AS EmpSeq      
            ,A.WorkOrderSerl      
            ,'0'                        AS IsProcQC      
            ,C.IsLastProc                        AS IsLastProc      
            ,'0'                        AS IsPjt      
            ,0                          AS PJTSeq      
            ,0                          AS WBSSeq      
            ,0                          AS SubEtcInSeq      
            ,A.WorkTimeGroup      
            ,0                          AS QCSeq      
            ,''                         AS QCNo      
            ,0                          AS PreProdWRSeq      
            ,0                          AS PreAssySeq      
            ,0                          AS PreAssyQty      
            ,''                         AS PreLotNo      
            ,0                          AS PreUnitSeq      
            ,0                          AS CustSeq      
            ,ISNULL(A.WorkType, 6041001) AS WorkType      
            ,A.GoodItemSeq      
            ,A.WorkDate             AS WorkDate      
            ,ISNULL(A.DeptSeq  ,8)      AS DeptSeq    
            ,A.FactUnit      
            ,A.Seq      
        INTO #TMP_TPDSFCWorkReport_Xml      
        FROM #TMP_TPDSFCWorkReport   AS A      
             LEFT OUTER JOIN _TPDROUItemProcWC  AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq       
                                                          AND A.GoodItemSeq = B.ItemSeq       
                                                          AND A.WorkCenterSeq = B.WorkCenterSeq    
                                                          AND A.ProcSeq = B.ProcSeq    
             LEFT OUTER JOIN _TPDROUItemProc AS C with(Nolock) ON C.CompanySeq = @CompanySeq
                                                              And C.ProcSeq = A.ProcSeq     
                                                              AND C.ItemSeq = A.GoodItemSeq    
                     
    WHERE A.Status = 0      

    ------------------------------            
    -- Temp테이블 데이터 XMl로 생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                SELECT DataSeq AS IDX_NO, *             
                                                  FROM #TMP_TPDSFCWorkReport_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
            
 IF OBJECT_ID('tempdb..#TPDSFCWorkReport') IS NOT NULL      
 BEGIN      
  DROP TABLE #TPDSFCWorkReport      
 END     
    CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)                
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock1', '#TPDSFCWorkReport'                
            
    
    INSERT INTO #TPDSFCWorkReport            
    EXEC KPXCM_SPDSFCWorkReportCheckPOP    
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2909,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015            
    
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SPDSFCWorkReportCheck''', 15, 1)        
          
    END        
	 --오류시 오류처리        
	 UPDATE A      
		SET ProcYN = '2',      
		 ErrorMessage = D.Result 
	   FROM KPX_TPDSFCWorkReport_POP AS A      
		 JOIN #TMP_TPDSFCWorkReport AS B ON B.Seq = A.Seq      
		 JOIN #TMP_TPDSFCWorkReport_Xml AS C ON C.Seq = B.Seq      
		 JOIN #TPDSFCWorkReport AS D ON D.DataSeq = C.DataSeq      
	  WHERE D.Status <> 0  
	    and A.CompanySeq = @CompanySeq     
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM  #TPDSFCWorkReport WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TPDSFCWorkReport
            
            RETURN  
     END   
     
    UPDATE A      
      SET WorkReportSeq = CASE WHEN C.Status <> 0 THEN 0 ELSE C.WorkReportSeq END          
     FROM #TMP_TPDSFCWorkReport         AS A          
     JOIN #TMP_TPDSFCWorkReport_Xml     AS B ON A.Seq = B.Seq          
     JOIN #TPDSFCWorkReport             AS C ON B.DataSeq = C.DataSeq          
    --WHERE A.RowCnt = @Cnt      
          
   UPDATE C      
      SET WorkReportSeq = CASE WHEN C.Status <> 0 THEN 0 ELSE C.WorkReportSeq END          
     FROM #TMP_TPDSFCWorkReport         AS A          
     JOIN #TMP_TPDSFCWorkReport_Xml     AS B ON A.Seq = B.Seq          
     JOIN #TPDSFCWorkReport             AS C ON B.DataSeq = C.DataSeq          
    --WHERE A.RowCnt = @Cnt      
    
    
/*------------------------------------------------------------------------------------------------------------------------------        
    LotMaster 체크         
----------------------------------------------------------------------------------------------------------------------------*/        
 IF OBJECT_ID('tempdb..#TMP_TLGLotMaster_Xml') IS NOT NULL      
 BEGIN      
  DROP TABLE #TMP_TLGLotMaster_Xml      
 END     
    SELECT A.WorkingTag,      
           A.IDX_NO,      
           A.DataSeq,      
           A.Status,      
           A.Selected,      
           'DataBlock1'                 AS TABLE_NAME,      
           ISNULL(B.WorkOrderNo, '')    AS InNo,      
           ''                           AS LotNoOld,      
           0                            AS ItemSeqOld,      
           A.WorkDate                   AS RegDate,         --입고일    
           A.WorkDate                   AS CreateDate2,     --제조일자    
           DATEADD(DAY, CASE WHEN I.SMLimitTermKind = 8004001 THEN I.LimitTerm*30    
                             ELSE I.LimitTerm END, A.WorkDate) AS Validate,        --유효일자    
           A.GoodItemSeq                AS ItemSeq,      
           A.ProdUnitSeq                AS UnitSeq,      
           A.OKQty                      AS Qty,      
           B.WorkCond3                  AS LotNo,      
           N'생산실적 연동'             AS Remark,      
           '0'                          AS IsDelete,      
           '1'                          AS IsProductItem,      
           ''                           AS IsExceptEmptyLotNo      
      INTO #TMP_TLGLotMaster_Xml      
      FROM #TPDSFCWorkReport       AS A      
           LEFT OUTER JOIN _TPDSFCWorkOrder AS B ON B.COmpanySeq = @CompanySeq      
                                                AND A.WorkOrderSeq = B.WorkOrderSeq      
                                                AND A.WorkOrderSerl = B.WorkOrderSerl      
           LEFT OUTER JOIN _TDAItemStock AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq    
                                                          AND I.ItemSeq = A.GoodItemSeq    
     WHERE A.Status = 0         
                   
    ------------------------------            
    -- Temp테이블 데이터 XMl로 생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *         
                                                  FROM #TMP_TLGLotMaster_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))          
 IF OBJECT_ID('tempdb..#TLGLotMaster') IS NOT NULL      
 BEGIN      
  DROP TABLE #TLGLotMaster      
 END     
    CREATE TABLE #TLGLotMaster (WorkingTag NVARCHAR(4) NULL)              
      EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 4422, 'DataBlock1', '#TLGLotMaster'            
    
    ------------------------------            
    -- Lot마스터 Check SP            
    ------------------------------            
    INSERT INTO #TLGLotMaster            
    EXEC _SLGLotNoMasterCheck             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 4422,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015          
print 408    
        
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SLGLotNoMasterCheck''', 15, 1)        
    END        
        
        
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM  #TLGLotMaster WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TLGLotMaster
            
            RETURN  
     END 
     
        
/*------------------------------------------------------------------------------------------------------------------------------        
    LotMaster 저장         
------------------------------------------------------------------------------------------------------------------------------*/        
      
    ------------------------------            
    -- Lot마스터 Check SP XML 생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TLGLotMaster           
                                                 WHERE Status = 0         
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
    DELETE FROM #TLGLotMaster            
        
    ------------------------------            
    -- Lot마스터 SAVE SP            
    ------------------------------            
    INSERT INTO #TLGLotMaster            
    EXEC _SLGLotNoMasterSave             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 4422,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015           
        
        
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SLGLotNoMasterSave''', 15, 1)        
    END        
        
/*------------------------------------------------------------------------------------------------------------------------------        
    생산실적 저장         
------------------------------------------------------------------------------------------------------------------------------*/        
        
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TPDSFCWorkReport            
                                                 WHERE Status = 0        
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            




    DELETE FROM #TPDSFCWorkReport             
    ------------------------------            
    -- 생산실적입력 SAVE SP            
    ------------------------------            
    INSERT INTO #TPDSFCWorkReport            
    EXEC _SPDSFCWorkReportSave             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2909,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq = @UserSeq,    
         @PgmSeq       = 1015          
  
        
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SPDSFCWorkReportSave''', 15, 1)        
              
              
    END        
    
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM  #TPDSFCWorkReport WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TPDSFCWorkReport
            
            RETURN  
     END 
    
  /*------------------------------------------------------------------------------------------------------------------------------        
    진행 Save        
   ------------------------------------------------------------------------------------------------------------------------------*/        
 IF OBJECT_ID('tempdb..#TMP_SourceDaily_Xml') IS NOT NULL      
 BEGIN      
  DROP TABLE #TMP_SourceDaily_Xml      
 END     
    SELECT A.WorkingTag,            
           A.IDX_NO,            
           A.DataSeq,            
           A.Status,            
           A.Selected,            
           'DataBlock1'    AS TABLE_NAME,            
           5               AS FromTableSeq,            
           A.WorkOrderSeq  AS FromSeq,            
           A.WorkOrderSerl AS FromSerl,            
           0               AS FromSubSerl,            
           6               AS ToTableSeq,            
           B.OrderQty      AS FromQty,            
           B.StdUnitQty    AS FromSTDQty,            
           0               AS FromAmt,            
           0               AS FromVAT,            
           0               AS PrevFromTableSeq,            
           A.WorkReportSeq AS ToSeq,          
           A.StdUnitOKQty  AS ToSTDQty,          
           A.ProdQty       AS ToQty            
      INTO #TMP_SourceDaily_Xml            
      FROM #TPDSFCWorkReport            AS A            
          JOIN _TPDSFCWorkOrder             AS B ON B.CompanySeq = @CompanySeq
                                                And A.WorkOrderSeq  = B.WorkOrderSeq            
                                                AND A.WorkOrderSerl = B.WorkOrderSerl            
     WHERE B.CompanySeq = @CompanySeq            
       AND NOT EXISTS (SELECT 1 FROM #TMP_TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq AND Status <> 0)         
      
    ------------------------------            
    -- 진행 SAVE Xml생성            
      ------------------------------             
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TMP_SourceDaily_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
 IF OBJECT_ID('tempdb..#TCOMSourceDaily') IS NOT NULL      
 BEGIN      
  DROP TABLE #TCOMSourceDaily      
 END     
     CREATE TABLE #TCOMSourceDaily  (WorkingTag NCHAR(1) NULL)                      
     ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 3181, 'DataBlock1', '#TCOMSourceDaily'          
        
     Alter Table #TCOMSourceDaily Add OldToQty DECIMAL(19, 5)                   
     Alter Table #TCOMSourceDaily Add OldToSTDQty DECIMAL(19, 5)                   
     Alter Table #TCOMSourceDaily Add OldToAmt DECIMAL(19, 5)                   
     Alter Table #TCOMSourceDaily Add OldToVAT DECIMAL(19, 5)          
        
    ------------------------------            
    -- 진행 SAVE SP            
    ------------------------------            
    INSERT INTO #TCOMSourceDaily        
    EXEC _SCOMSourceDailySave             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 3181,                     
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,            
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015            
        
        
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SCOMSourceDailySave''', 15, 1)        
    END        
        
        
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM  #TCOMSourceDaily WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TCOMSourceDaily
            
            RETURN  
     END 
     

/*------------------------------------------------------------------------------------------------------------------------------        
    수불 Batch Save        
------------------------------------------------------------------------------------------------------------------------------*/          
 IF OBJECT_ID('tempdb..#TMP_InOutDailyBatch_Xml') IS NOT NULL      
 BEGIN      
  DROP TABLE #TMP_InOutDailyBatch_Xml      
 END     
    ------------------------------            
    -- 입출고 SAVE TempData생성            
    ------------------------------            
    SELECT A.WorkingTag,            
           A.IDX_NO,            
           A.DataSeq,            
           A.Status,            
           A.Selected,            
           'DataBlock1'    AS TABLE_NAME,            
           A.WorkReportSeq AS InOutSeq,            
   130             AS InOutType            
      INTO #TMP_InOutDailyBatch_Xml        
      FROM #TPDSFCWorkReport AS A            
    WHERE  NOT EXISTS (SELECT 1 FROM #TMP_TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq AND Status <> 0)         
        
    ------------------------------            
    -- 입출고 SAVE Xml생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TMP_InOutDailyBatch_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
 IF OBJECT_ID('tempdb..#TLGInOutDailyBatch') IS NOT NULL      
 BEGIN      
  DROP TABLE #TLGInOutDailyBatch      
 END    
     CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)              
     EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDailyBatch'       

    ------------------------------            
    -- 입출고 SAVE SP            
    ------------------------------            
    INSERT INTO #TLGInOutDailyBatch        
    EXEC _SLGInOutDailyBatch             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2619,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,             
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015            
  
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC _SLGInOutDailyBatch''', 15, 1)        
    END        
    
    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM  #TLGInOutDailyBatch WHERE Status <> 0)        
     BEGIN        
        
            SELECT @Status = Status , 
                   @Result = Result, 
                   @MessageType = MessageType 
              FROM #TLGInOutDailyBatch
            
            RETURN  
     END 
    
    --select * from #TMP_TPDSFCWorkReport 
    --return 
--------------------------------------------------------------------------------------------------------------------------------------------------         
    -- 최종 반영내역  UPDATE        
--------------------------------------------------------------------------------------------------------------------------------------------------         
    UPDATE A        
       SET   ProcYn = CASE WHEN B.Status = 0 THEN '1' ELSE '2' END        
            ,ProcDateTime = @CurrDATETIME        
            ,ErrorMessage = B.Result        
            ,WorkReportSeq    = CASE WHEN B.Status = 0 THEN B.WorkReportSeq ELSE 0 END      
      FROM KPX_TPDSFCWorkReport_POP        AS A        
      JOIN #TMP_TPDSFCWorkReport          AS B ON A.Seq = B.Seq       
                                              AND A.WorkOrderSeq = B.WorkOrderSeq    
                                              AND A.WorkOrderSerl = B.WorkOrderSerl     
    where A.CompanySeq = @CompanySeq 
    
    --select * From KPX_TPDSFCWorkReport_POP where Seq = 1000035632

    
    --select * from _TPDSFCWorkReport where WorkOrderSeq =  130016
    --END TRY       
        
         
    --BEGIN CATCH        
    ----select 1    
    --    SELECT ERROR_NUMBER()    AS ErrorNumber,        
    --           ERROR_SEVERITY()  AS ErrorSeverity,        
    --           ERROR_STATE()     AS ErrorState,        
    --           ERROR_PROCEDURE() AS ErrorProcedure,        
    --           ERROR_LINE()      AS ErrorLine,        
    --           ERROR_MESSAGE()   AS ErrorMessage;        
        
    --    IF @@TRANCOUNT > 0        
    --        ROLLBACK TRANSACTION;        
        
    --END CATCH        
        
    --IF @@TRANCOUNT > 0        
    --    COMMIT TRANSACTION;        
                
        
        
    
RETURN      
GO


begin tran 
exec KPXCM_SPDSFCWorkReportSub_POP 2, 1000034866





rollback 