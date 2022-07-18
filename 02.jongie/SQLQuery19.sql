  
IF OBJECT_ID('yw_SLGTransSave')IS NOT NULL
    DROP PROC yw_SLGTransSave
GO

-- 2013.09.03 

-- 이동입고저장_BCD_yw by공민하, 이재천
CREATE PROC yw_SLGTransSave
    @CompanySeq     INT  = 1,
    @Seq			INT = 0,
    @Serl			INT = 0,
    @InWHSeq		INT  = 0,
    @OutWHSeq		INT = 0,
    @ItemSeq		INT = 0,
    @Qty			DECIMAL(19, 5) = 0,
    @ReqDate		NVARCHAR(8) = '', 
    @UserId         NVARCHAR(50)
AS
    
    CREATE TABLE #TEMP_TABLE 
    (
        IDX_NO          INT IDENTITY(0, 1), 
        Status          INT,
        Result          NVARCHAR(100),
        CompanySeq      INT, 
        Seq             INT, 
        Serl            INT, 
        InWHSeq         INT, 
        OutWHSeq        INT, 
        ItemSeq         INT, 
        Qty             DECIMAL(19,5), 
        ReqDate         NVARCHAR(8), 
        UserId          NVARCHAR(50), 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(100)
    )
    INSERT INTO #TEMP_TABLE (Status, Result, CompanySeq, Seq, Serl, InWHSeq, OutWHSeq, ItemSeq, Qty, ReqDate, UserId)
    SELECT 0, '', @CompanySeq, @Seq, @Serl, @InWHSeq, @OutWHSeq, @ItemSeq, @Qty, @ReqDate, @UserId
    
    CREATE TABLE #TLGInOutDaily  
    (  
        IDX_NO          INT NOT NULL,  
        DataSeq         INT NOT NULL,  
        WorkingTag      NCHAR(1) NOT NULL,  
        Status          INT NOT NULL,  
        Result          NVARCHAR(255) NULL,  
        MessageType     INT NULL,  
          
        CompanySeq      INT NOT NULL,   
        InOutType       INT NOT NULL,   
        InOutSeq        INT NOT NULL,   
        BizUnit         INT NOT NULL,   
        InOutNo         NVARCHAR(30) NULL,   
        FactUnit        INT NOT NULL,   
        ReqBizUnit      INT NOT NULL,   
        DeptSeq         INT NOT NULL,   
        EmpSeq          INT NOT NULL,   
        InOutDate       NCHAR(8) NOT NULL,   
        WCSeq           INT NOT NULL,   
        ProcSeq         INT NOT NULL,   
        CustSeq         INT NOT NULL,   
        OutWHSeq        INT NOT NULL,   
        InWHSeq         INT NOT NULL,   
        DVPlaceSeq      INT NOT NULL,   
        IsTrans         NCHAR(1) NOT NULL,   
        IsCompleted     NCHAR(1) NOT NULL,   
        CompleteDeptSeq INT NOT NULL,   
        CompleteEmpSeq  INT NOT NULL,   
        CompleteDate    NCHAR(8) NOT NULL,   
        InOutDetailType INT NOT NULL,   
        Remark          NVARCHAR(1000) NULL,   
        Memo            NVARCHAR(1000) NULL,   
        IsBatch         NCHAR(1) NULL,   
        LastUserSeq     INT NULL,   
        LastDateTime    DATETIME NULL,   
        UseDeptSeq      INT NULL,   
        PgmSeq          INT NULL,  
          
        -- 마감체크를 위한 필드   
        DeptSeqOld      INT NOT NULL,  
        BizUnitOld      INT NOT NULL,  
        InOutDateOld    NVARCHAR(8) NOT NULL   
    )   
      
    CREATE TABLE #TLGInOutDailyItem   
    (  
        IDX_NO          INT NOT NULL,  
        Up_IDX_NO       INT NOT NULL,  
        DataSeq         INT NOT NULL,  
        WorkingTag      NCHAR(1) NOT NULL,  
        Status          INT NOT NULL,  
        Result          NVARCHAR(255) NULL,  
        MessageType     INT NULL,  
          
        CompanySeq      INT NOT NULL,   
        InOutType       INT NOT NULL,   
        InOutSeq        INT NOT NULL,   
        InOutSerl       INT NOT NULL,   
        ItemSeq         INT NOT NULL,   
        InOutRemark     NVARCHAR(200) NULL,   
        CCtrSeq         INT NULL,   
        DVPlaceSeq      INT NULL,   
        InWHSeq         INT NULL,   
        OutWHSeq        INT NULL,   
        UnitSeq         INT NULL,   
        Qty             DECIMAL(19,5) NULL,   
        STDQty          DECIMAL(19,5) NULL,   
        Amt             DECIMAL(19,5) NULL,   
        EtcOutAmt       DECIMAL(19,5) NULL,   
        EtcOutVAT       DECIMAL(19,5) NULL,   
        InOutKind       INT NULL,   
        InOutDetailKind INT NULL,   
        LotNo           NVARCHAR(30) NULL,   
        SerialNo        NVARCHAR(30) NULL,   
          IsStockSales    NCHAR(1) NULL,   
        OriUnitSeq      INT NULL,   
        OriItemSeq      INT NULL,   
        OriQty          DECIMAL(19,5) NULL,   
        OriSTDQty       DECIMAL(19,5) NULL,   
        LastUserSeq     INT NULL,   
        LastDateTime    DATETIME NULL,   
        PJTSeq          INT NULL,   
        OriLotNo        NVARCHAR(30) NULL,   
        ProgFromSeq     INT NULL,   
        ProgFromSerl    INT NULL,   
        ProgFromSubSerl INT NULL,   
        ProgFromTableSeq INT NULL,   
        PgmSeq          INT NULL,   
          
        -- _SLGCreateDataForInOutLotStock 에서 필요하는 필드   
        DataKind        INT NOT NULL,  
        InOutDataSerl   INT NOT NULL,  
        IsLot           NCHAR(1) NOT NULL,   
        CustSeq         INT NULL,   
        InOutDate       NVARCHAR(8) NULL,  
        SalesCustSeq    INT NULL,   
        IsTrans         NCHAR(1) NULL   
    )  
    
    -- 처리1, 이동처리   
    DECLARE @EnvValue6 INT,  @EnvValue20 INT, @GETDATE NVARCHAR(8), @UserSeq INT
    SELECT @EnvValue20 = EnvValue FROM yw_TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 20 AND EnvSerl = 1   
    SELECT @EnvValue6 = ISNULL(EnvValue,0) FROM yw_TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 6 AND EnvSerl = 1   
    --SELECT @EnvValue6 = ISNULL(@EnvValue6,0)  
    SELECT @GETDATE = CONVERT(NVARCHAR(8),GETDATE(),112)
    SELECT @UserSeq = (SELECT B.UserSeq FROM #TEMP_TABLE AS A JOIN _TCAUser AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.UserId = RTRIM(A.UserId) ))
    
    INSERT INTO #TLGInOutDaily -- _TLGInOutDaily 
    (  
        IDX_NO      , DataSeq        , WorkingTag  , Status          , Result          ,   
        DeptSeqOld  , BizUnitOld     , InOutDateOld,  
          
        CompanySeq  , InOutType      , InOutSeq    , BizUnit         , InOutNo         ,  
        FactUnit    , ReqBizUnit     , DeptSeq     , EmpSeq          , InOutDate       ,   
        WCSeq       , ProcSeq        , CustSeq     , OutWHSeq        , InWHSeq         ,  
        DVPlaceSeq  , IsTrans        , IsCompleted , CompleteDeptSeq , CompleteEmpSeq  ,  
        CompleteDate, InOutDetailType, Remark      , Memo            , IsBatch         ,  
        LastUserSeq , LastDateTime   , UseDeptSeq  , PgmSeq  
    )  
    SELECT A.IDX_NO      , 1                , 'A'           , A.Status          , A.Result          ,   
           J.DeptSeq     , @EnvValue20      , A.ReqDate  ,  
             
           @CompanySeq   , 80               , 0, @EnvValue20   , ''         ,  
           0             , @EnvValue20       , J.DeptSeq     , I.EmpSeq          , @GETDATE     ,  
           0             , 0                , 0             , A.OutWHSeq        , A.InWHSeq         ,  
           0             , '0'              , '1'           , J.DeptSeq         , I.EmpSeq          ,  
           @GETDATE  , 0                , 'PDA 이동요청건'     , NULL              , NULL              ,  
           G.UserSeq      , GETDATE()        , NULL          , 1371  
             
      FROM #TEMP_TABLE AS A   
      JOIN _TDAWH              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.OutWHSeq = C.WHSeq )  
      JOIN _TDAWH              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND A.InWHSeq = D.WHSeq )  
      LEFT OUTER JOIN _TCAUser AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.UserId = RTRIM(A.UserId) ) 
      LEFT OUTER JOIN _TDAEmp  AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = G.EmpSeq ) 
      LEFT OUTER JOIN _TDADept AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = I.DeptSeq ) 
      LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'') AS B ON ( G.EmpSeq = B.EmpSeq )     
     WHERE A.Status = 0   
    
    INSERT INTO #TLGInOutDailyItem -- _TLGInOutDailyItem  
    (     
        IDX_NO      , Up_IDX_NO      , DataSeq          , WorkingTag, Status     ,  
        Result      , DataKind       , InOutDataSerl    , IsLot     , CustSeq    ,  
        InOutDate   , SalesCustSeq   , IsTrans          ,  
          
        CompanySeq  , InOutType      , InOutSeq         , InOutSerl , ItemSeq    ,   
        InOutRemark , CCtrSeq        , DVPlaceSeq       , InWHSeq   , OutWHSeq   ,  
        UnitSeq     , Qty            , STDQty           , Amt       , EtcOutAmt  ,  
          EtcOutVAT   , InOutKind      , InOutDetailKind  , LotNo     , SerialNo   ,  
        IsStockSales, OriUnitSeq     , OriItemSeq       , OriQty    , OriSTDQty  ,  
        LastUserSeq , LastDateTime   , PJTSeq           , OriLotNo  , ProgFromSeq,  
        ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq , PgmSeq  
    )   
    SELECT B.IDX_NO      , B.IDX_NO         , 1          , 'A'         , B.Status     ,  
           B.Result      , 0                , 0          , C.IsLotMng  , 0            ,  
           @GETDATE      , 0                , '0'        ,  
             
           @CompanySeq   , 80               ,0                   , 0           , B.ItemSeq    ,  
           'PDA 이동요청건' , NULL             , NULL            , B.InWHSeq   , B.OutWHSeq   ,  
           D.UnitSeq     , B.Qty            , B.Qty              , 0           , 0            ,  
           0             , 8023008          , @EnvValue6         , H.LotNo     , ''           ,  
           NULL          , NULL             , NULL               , 0           , 0            ,  
           G.UserSeq     , GETDATE()       , NULL              , NULL       , NULL         ,  
           NULL          , NULL             , NULL               , 1371   
             
      FROM #TEMP_TABLE AS B 
      JOIN _TDAItemStock               AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND B.ItemSeq = C.ItemSeq )  
      JOIN _TDAItem                    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND B.ItemSeq = D.ItemSeq )  
      LEFT OUTER JOIN _TCAUser         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.UserId = RTRIM(B.UserId) ) 
      LEFT OUTER JOIN _TLGInOutReqItem AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ReqSeq = B.Seq AND H.ReqSerl = B.Serl ) 

     WHERE B.Status = 0   
    
    BEGIN TRAN
    EXEC _SLGInOutDailyBatchByScript @CompanySeq, 1, @UserSeq, 1371 
    
    UPDATE A   
       SET A.Result = B.Result,  
           A.Status = CASE WHEN B.Result = '' THEN 0 ELSE 1 END,  --B.Status,  
           A.InOutSeq = B.InOutSeq,   
           A.InOutNo = B.InOutNo   
             
      FROM #TEMP_TABLE AS A   
      JOIN #TLGInOutDaily AS B ON ( A.IDX_NO = B.IDX_NO ) --AND B.Status <> 0 )  
     WHERE A.Status = 0   
    
    UPDATE A   
       SET A.Result = B.Result,  
           A.Status = CASE WHEN B.Result = '' THEN 0 ELSE 1 END 
    
      FROM #TEMP_TABLE AS A   
      JOIN #TLGInOutDailyItem AS B ON ( A.IDX_NO = B.IDX_NO AND B.Status <> 0 )  
     WHERE A.Status = 0 
    
    -- 처리1, END   
    
    select * from #TLGInOutDailyItem
    select * from #TEMP_TABLE
    --return
	-- 진행                    
    CREATE TABLE #SComSourceDailyBatch (                    
        ToTableName     NVARCHAR(100),                    
        ToSeq           INT,                    
        ToSerl			INT,                    
        ToSubSerl       INT,                    
        FromTableName   NVARCHAR(100),                    
        FromSeq         INT,                     
        FromSerl        INT,                    
        FromSubSerl     INT,                    
        ToQty           DECIMAL(19, 5),                    
        ToStdQty        DECIMAL(19, 5),                    
        ToAmt           DECIMAL(19, 5),                    
        ToVAT           DECIMAL(19, 5),                    
        FromQty         DECIMAL(19, 5),                    
        FromSTDQty      DECIMAL(19, 5),                    
        FromAmt         DECIMAL(19, 5),                    
        FromVAT         DECIMAL(19, 5)                    
    )                    
                    
    -- 진행연결(이동요청 => 이동)            --_Tcomprogtable        
    INSERT INTO #SComSourceDailyBatch                    
		SELECT '_TLGInOutDailyItem', A.InOutSeq, A.InOutSerl, 0,                    
			   '_TLGInOutReqItem', B.Seq, B.Serl, 0,                    
			   A.Qty, A.STDQty, 0, 0,                    
			   B.Qty, B.Qty, 0, 0                    
		  FROM #TLGInOutDailyItem AS A                    
			   INNER JOIN #TEMP_TABLE AS B WITH(NOLOCK) ON ( B.IDX_NO = A.IDX_NO ) 
    
    -- 진행연결 
    EXEC _SComSourceDailyBatch 'A', @CompanySeq, 0
    
    
    
    
    -- 이동 요청에서 이동으로 진행
    CREATE TABLE #TMP_ProgressTable 
                 (
                  IDOrder INT, 
                  TableName NVARCHAR(100)
                 ) 
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
         SELECT 1, '_TLGInOutDailyItem'   -- 데이터 찾을 테이블

    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TLGInOutReqItem',    -- 기준이 되는 테이블
            @TempTableName = '#TEMP_TABLE',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'Seq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'Serl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
    SELECT A.IDX_NO, SUM(B.Qty) AS SaveQty 
      INTO #TLGInOutDailyItem_J
      FROM #TCOMProgressTracking AS A 
      JOIN _TLGInOutDailyItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.Seq AND B.InOutSerl = A.Serl ) 
     GROUP BY A.IDX_NO
    
    UPDATE B
       SET Result = N'이동요청 수량이 이미 진행완료 되었습니다.',
           Status = 1
      FROM #TLGInOutDailyItem_J AS A
      JOIN #TEMP_TABLE AS B ON ( A.IDX_NO = B.IDX_NO ) 
     WHERE A.SaveQty >= B.Qty
    
    -- 오류메시지를 위한 출력
    
	SELECT Status AS Status,		-- 0(정상처리시), 1(에러시)
		   Result AS Message		-- 에러시 메세지
      FROM #TEMP_TABLE
    
    -- 오류일 때는 ROLLBACK, 오류가 아닐때는 COMMIT
    IF (SELECT Status FROM #TEMP_TABLE) = 0 
        COMMIT TRAN
    
    ELSE
        ROLLBACK TRAN
GO


BEGIN TRAN
EXEC yw_SLGTransSave 1, 7, 1, 12, 27, 45266, 15.00, '20130910', 'master'
--select * from _TLGInOutDailyItem where CompanySeq =1 and InOutType = 80 
--select * from _TLGInOutReqItem where CompanySeq = 1 
--select * from _TCOMSourceDaily where FromTableSeq = 15

--select * from _TCOMProgTable where ProgTableName = '_TLGInOutReqItem'
ROLLBACK



--select * from _TCAUser where companyseq = 1 and userid = 'jclee1'