IF OBJECT_ID('KPXLS_SPDSFCGoodInSave') IS NOT NULL 
    DROP PROC KPXLS_SPDSFCGoodInSave
GO 

-- v2016.01.12 

-- 생산입고저장 LotMaster 입고일자 update 로직 추가 by 이재천 
/************************************************************
설  명 - 생산입고저장
작성일 - 2008년 10월 25일 
작성자 - 정동혁
UPDATE :: 검사는 진행을 사용하지 않으므로, 진행은 실적-> 입고로 만 연결되도록 주석처리  :: 12.05.21 BY 김세호
       :: 자동입고로 넘어왔을경우 OldQty 로 삭제진행데이터 생성해주도록                 :: 12.05.21 BY 김세호
          (실적->입고 삭제진행데이터 생성전에 실적TR의 수량이 수정/삭제 되므로)    
************************************************************/
CREATE PROC KPXLS_SPDSFCGoodInSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  

AS    

    -- 진행              
    CREATE TABLE #SComSourceDailyBatch    
    (  
        ToTableName   NVARCHAR(100),  
        ToSeq         INT,  
        ToSerl        INT,  
        ToSubSerl     INT,  
        FromTableName NVARCHAR(100),  
        FromSeq       INT,  
        FromSerl      INT,  
        FromSubSerl   INT,  
        ToQty         DECIMAL(19,5),  
        ToStdQty      DECIMAL(19,5),  
        ToAmt         DECIMAL(19,5),  
        ToVAT         DECIMAL(19,5),  
        FromQty       DECIMAL(19,5),  
        FromSTDQty    DECIMAL(19,5),  
        FromAmt       DECIMAL(19,5),  
        FromVAT       DECIMAL(19,5)  
    )  

    DECLARE @EmpSeq     INT

    SELECT @EmpSeq = dbo._FCOMGetEmpSeqByCompany(@CompanySeq, @UserSeq)

    IF ISNULL(@EmpSeq,0) = 0 SELECT @EmpSeq = 0 -- 송기연 추가 20091228 


    IF @WorkingTag <> 'AutoGoodIn'
    BEGIN
        -- 서비스 마스타 등록 생성
        CREATE TABLE #TPDSFCGoodIn (WorkingTag NCHAR(1) NULL)  
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCGoodIn'     
        IF @@ERROR <> 0 RETURN    
    END


    EXEC _SCOMLog  @CompanySeq,
                   @UserSeq, 
                   '_TPDSFCGoodIn',
                   '#TPDSFCGoodIn',
                   'GoodInSeq',
                   'CompanySeq,GoodInSeq,FactUnit,InDate,WHSeq,GoodItemSeq,UnitSeq,ProdQty,StdProdQty,UnitPrice,Amt,FlowDate,InDeptSeq,
                    EmpSeq,WorkOrderSeq,WorkReportSeq,WorkSerl,QCSeq,RealLotNo,SerialNoFrom,Remark,PJTSeq,WBSSeq,LastUserSeq,LastDateTime'


    -- 진행은 데이터 서비스를 호출 하다보니 잦은 오류가 발생한다.
    -- 진행데이터에서 발생하는 오류는 치명적이므로 데이터서비스대신 SP호출로 변경한다. 2009.09.26 정동혁
    -- 진행연결삭제(최종검사 => 생산입고)  


    -- 검사는 진행을 사용하지 않으므로, 진행은 실적-> 입고로 만 연결되도록 주석처리 -- 12.05.21 BY 김세호
--    INSERT INTO #SComSourceDailyBatch  
--    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
--           '_TPDQCTestReport', B.QCSeq, 0, 0,  
--           A.ProdQty, A.StdProdQty, 0,   0,  
--           B.ReqInQty, 0, 0,   0
--      FROM #TPDSFCGoodIn            AS A  
--           JOIN _TPDQCTestReport    AS B ON A.WorkReportSeq = B.SourceSeq
--                                        AND B.SourceType = '3'
--                                        AND B.CompanySeq = @CompanySeq
--     WHERE A.WorkingTag IN ('U','D')  
--       AND A.Status = 0  
--
--    IF @@ERROR <> 0      
--    BEGIN      
--        RETURN      
--    END    


---------------------------------------------------------------------------------------------------------------------------  
    -- 진행연결삭제(생산실적 => 생산입고)      
    -- (자동입고 인 경우는 _SPDSFCWorkReportSave에서 넘어온 Old값으로 수량 넣어준다 : 실적TR의 수량은 이미 수정/삭제 되었으므로)      -- 12.05.21 BY 김세호
---------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #SComSourceDailyBatch      
    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0, '_TPDSFCWorkReport', A.WorkReportSeq,           
           0, 0, C.ProdQty, C.StdProdQty, 0,   0,    
           ISNULL(B.OKQty, 0), ISNULL(B.StdUnitOKQty, 0),
--           CASE WHEN @WorkingTag = 'AutoGoodIn' THEN A.OldOKQty        ELSE B.OKQty END,      -- 사이트용 실적 서비스및 SP때문에 이란 주석처리 -- 12.06.29 BY 김세호 
--           CASE WHEN @WorkingTag = 'AutoGoodIn' THEN A.OldStdUnitOKQty ELSE B.StdUnitOKQty END, -- 사이트용 실적 서비스및 SP때문에 이란 주석처리  -- 12.06.29 BY 김세호 
           0,   0    
      FROM #TPDSFCGoodIn                         AS A      
           JOIN _TPDSFCGoodIn                    AS C ON A.GoodInSeq = C.GoodInSeq
                                                     AND @CompanySeq =  C.CompanySeq
            LEFT OUTER JOIN _TPDSFCWorkReport    AS B ON A.WorkReportSeq = B.WorkReportSeq    
                                                     AND B.CompanySeq = @CompanySeq    
     WHERE A.WorkingTag IN ('U','D')           
       AND A.Status = 0    
       AND NOT EXISTS (SELECT 1 FROM #SComSourceDailyBatch WHERE ToSeq = A.GoodInSeq)  
    

    IF @@ERROR <> 0      
    BEGIN      
        RETURN      
    END    
  
    -- 진행연결  
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq  
    IF @@ERROR <> 0 RETURN  

---------------------------------------------------------------------------------------------------------------------------  


  




    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT

    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE _TPDSFCGoodIn
          FROM _TPDSFCGoodIn   AS A 
            JOIN #TPDSFCGoodIn AS B ON A.GoodInSeq = B.GoodInSeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
           AND A.CompanySeq  = @CompanySeq
        IF @@ERROR <> 0  RETURN


		-- 외주 용역비 삭제 2010. 9. 6 hkim
		DECLARE @OutsourcingType NVARCHAR(100)
		
		EXEC dbo._SCOMEnv @CompanySeq,6513,@UserSeq,@@PROCID,@OutsourcingType OUTPUT

		IF @OutsourcingType = '1' -- '1' 생산입고기준, '0' 생산실적기준
		BEGIN 
			IF EXISTS (SELECT 1 FROM _TPDSFCOutsourcingCostItem AS A 
									 JOIN #TPDSFCGoodIn			AS B ON A.WorkReportSeq = B.GoodInSeq 
							   WHERE A.CompanySeq = @CompanySeq 
								 AND B.Status	  = 0
								 AND B.WorkingTag = 'D')
			BEGIN
				DELETE _TPDSFCOutsourcingCostItem  
				  FROM _TPDSFCOutsourcingCostItem	AS A 
					   JOIN #TPDSFCGoodIn			AS B ON A.WorkReportSeq = B.GoodInSeq 
				 WHERE A.CompanySeq = @CompanySeq 
				   AND B.Status		= 0
				   AND B.WorkingTag = 'D'			
			END		
		END							     								
    END  


    -- 입고담당자   (자동입고등에서 담당자가 안들어오는경우 로그인 사원으로 넣어준다. )
    UPDATE #TPDSFCGoodIn
       SET EmpSeq = @EmpSeq
     WHERE WorkingTag IN ('A','U')  
       AND Status = 0  
       AND EmpSeq = 0 

    
    UPDATE A
       SET InDeptSeq = B.DeptSeq
      FROM #TPDSFCGoodIn                        AS A 
        JOIN dbo._FDAGetDept(@CompanySeq,0,'')  AS B ON A.EmpSeq = B.EmpSeq
     WHERE A.WorkingTag IN ('A','U')  
       AND A.Status = 0  
       AND A.InDeptSeq = 0 


    -- 기준단위수량 적용
    -- 2012. 1. 9 hkim 기준단위 수량 소수점 관련해서 처리되도록 추가
    DECLARE @ItemEnvSeq     INT

    EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@ItemEnvSeq OUTPUT  
    
    UPDATE T
       SET StdProdQty = CASE WHEN N.SMDecPointSeq = 1003002 THEN ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END ), @ItemEnvSeq, @ItemEnvSeq + 1)  
                                   WHEN N.SMDecPointSeq = 1003003 THEN ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@ItemEnvSeq + 1)), @ItemEnvSeq)     
                                   ELSE ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END ), @ItemEnvSeq) END     --T.ProdQty * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END )
      FROM #TPDSFCGoodIn                   AS T
           LEFT OUTER JOIN _TDAItemUnit    AS U ON T.GoodItemSeq = U.ItemSeq
                                               AND T.UnitSeq = U.UnitSeq
                                               AND @CompanySeq = U.CompanySeq
           LEFT OUTER JOIN _TDAUnit        AS N ON N.CompanySeq  = @CompanySeq                                                            
                                               AND T.UnitSeq = N.UnitSeq
     
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN

        UPDATE _TPDSFCGoodIn
           SET  FactUnit            = B.FactUnit            ,
                InDate              = B.InDate              ,
                WHSeq               = B.WHSeq               ,
                GoodItemSeq         = B.GoodItemSeq         ,
                UnitSeq             = B.UnitSeq             ,
                ProdQty             = B.ProdQty             ,
                StdProdQty          = B.StdProdQty          ,
                FlowDate            = B.FlowDate            ,
                InDeptSeq           = B.InDeptSeq           ,
                EmpSeq              = CASE WHEN ISNULL(B.EmpSeq,0) > 0 THEN B.EmpSeq ELSE @EmpSeq END               ,
                WorkOrderSeq        = B.WorkOrderSeq        ,
                WorkReportSeq       = B.WorkReportSeq       ,
                WorkSerl            = B.WorkSerl            ,
                QCSeq               = B.QCSeq               ,
                RealLotNo           = B.RealLotNo           ,
                SerialNoFrom        = B.SerialNoFrom        ,
                Remark              = ISNULL(B.Remark, '')  ,
                LastUserSeq         = @UserSeq              ,
                LastDateTime        = GETDATE()             ,
                IsWorkOrderEnd      = B.IsWorkOrderEnd      -- 2010.11.19 정동혁 추가. 작업지수량만큼 생산입고하지 못했더라도 해당작지를 완료로 보게한다.
          FROM _TPDSFCGoodIn   AS A 
            JOIN #TPDSFCGoodIn AS B ON A.GoodInSeq = B.GoodInSeq
         WHERE B.WorkingTag = 'U' 
           AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN
    END   


    -- INSERT
    IF EXISTS (SELECT 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO _TPDSFCGoodIn 
                   (CompanySeq          ,GoodInSeq              ,FactUnit               ,InDate                 ,WHSeq              ,
                    GoodItemSeq         ,UnitSeq                ,ProdQty                ,StdProdQty             ,UnitPrice          ,
                    Amt                 ,FlowDate               ,InDeptSeq              ,EmpSeq                 ,WorkOrderSeq       ,
                    WorkReportSeq       ,WorkSerl               ,QCSeq                  ,RealLotNo              ,SerialNoFrom       ,
                    Remark              ,PJTSeq                 ,WBSSeq                 ,LastUserSeq            ,LastDateTime       ,
                    IsWorkOrderEnd)
            SELECT  @CompanySeq         ,A.GoodInSeq            ,A.FactUnit             ,A.InDate               ,A.WHSeq             ,
                    A.GoodItemSeq       ,A.UnitSeq              ,A.ProdQty              ,A.StdProdQty           ,ISNULL(A.UnitPrice,0),
                    ISNULL(A.Amt,0)     ,ISNULL(A.FlowDate,'')  ,A.InDeptSeq            ,CASE WHEN ISNULL(A.EmpSeq,0) > 0 THEN A.EmpSeq ELSE @EmpSeq END ,A.WorkOrderSeq      , 
                    A.WorkReportSeq     ,ISNULL(A.WorkSerl,0)   ,ISNULL(A.QCSeq,0)      ,A.RealLotNo            ,A.SerialNoFrom      , 
                    ISNULL(A.Remark,'') ,W.PJTSeq               ,W.WBSSeq               , @UserSeq              ,GETDATE()           ,
                    ISNULL(A.IsWorkOrderEnd, '0')
              FROM #TPDSFCGoodIn        AS A   
                JOIN _TPDSFCWorkReport  AS W WITH(NOLOCK) ON A.WorkReportSeq = W.WorkReportSeq
                                                         AND W.CompanySeq = @CompanySeq
             WHERE A.WorkingTag = 'A' AND A.Status = 0    
        IF @@ERROR <> 0 RETURN
    END   


    TRUNCATE TABLE #SComSourceDailyBatch  
    
    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가 
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET RegDate = B.InDate
      FROM _TLGLotMaster AS A 
      JOIN #TPDSFCGoodIn AS B ON ( B.GoodItemSeq = A.ItemSeq AND B.RealLotNo = A.LotNo ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag IN ( 'A', 'U' ) 
    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가,END 
    ------------------------------------------------------------------------------------------
    
    

    -- 검사는 진행을 사용하지 않으므로, 진행은 실적-> 입고로 만 연결되도록 주석처리 -- 12.05.21 BY 김세호
--    INSERT INTO #SComSourceDailyBatch  
--    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
--           '_TPDQCTestReport', B.QCSeq, 0, 0,  
--           A.ProdQty, A.StdProdQty, 0,   0,  
--           B.ReqInQty, 0, 0,   0
--      FROM #TPDSFCGoodIn            AS A  
--           JOIN _TPDQCTestReport    AS B ON A.WorkReportSeq = B.SourceSeq
--                                        AND B.SourceType = '3'
--                                        AND B.CompanySeq = @CompanySeq
--     WHERE A.WorkingTag IN ('A','U')
--       AND A.Status = 0  


    -- 진행연결(생산실적 => 생산입고)  
    INSERT INTO #SComSourceDailyBatch  
    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
           '_TPDSFCWorkReport', B.WorkReportSeq, 0, 0,  
           A.ProdQty, A.StdProdQty, 0,   0,  
           B.OKQty, B.StdUnitOKQty, 0,   0
      FROM #TPDSFCGoodIn            AS A  
           JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq
                                        AND B.CompanySeq = @CompanySeq
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0  
       AND NOT EXISTS (SELECT 1 FROM #SComSourceDailyBatch WHERE ToSeq = A.GoodInSeq)


    -- 진행연결  
    EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
    IF @@ERROR <> 0 RETURN    

    IF @WorkingTag <> 'AutoGoodIn'
    BEGIN
        SELECT * FROM #TPDSFCGoodIn   
    END

    RETURN    
/*******************************************************************************************************************/
GO


