     
IF OBJECT_ID('mnpt_SPJTWorkPlanReportListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTWorkPlanReportListQuery      
GO      
      
-- v2018.01.22
      
-- 작업조회-조회 by 이재천  
CREATE PROC mnpt_SPJTWorkPlanReportListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @IsShipWork         NCHAR(1), 
            @IsUMBisWorkType    NCHAR(1), 
            @IsSumQty           NCHAR(1), 
            @IsUMExtraSeq       NCHAR(1), 
            @IsUMWorkType       NCHAR(1), 
            @IsUMWorkTeam       NCHAR(1), 
            @IsWorkDate         NCHAR(1), 
            @IsInvoiceList      NCHAR(1), 
            @SerlYear           NCHAR(4), 
            @IFShipCode         NVARCHAR(100), 
            @SerlNo             NVARCHAR(100), 
            @ToWorkDate         NCHAR(8), 
            @FrWorkDate         NCHAR(8), 
            @PJTNo              NVARCHAR(100),   
            @TextPJTName        NVARCHAR(100),   
            @WorkPlanReportSeq  INT, 
            @CfmSeq             INT, 
            @ShipCfmSeq         INT, 
            @UMWorkDivision     INT, 
            @UMExtraSeq         INT, 
            @UMWorkType         INT, 
            @UMWorkTeam         INT, 
            @ShipSeq            INT, 
            @PJTTypeSeq         INT, 
            @PJTTypeClassSSeq   INT, 
            @PJTTypeClassMSeq   INT, 
            @BizUnit            INT, 
            @CustSeq            INT, 
            @ShipSerlNo         NVARCHAR(100), 
            @FrOutDate          NCHAR(8),
            @ToOutDate          NCHAR(8), 
            @PJTSeq             INT
      
    SELECT @IsShipWork         = ISNULL( IsShipWork         , '0' ), 
           @IsUMBisWorkType    = ISNULL( IsUMBisWorkType    , '0' ), 
           @IsSumQty           = ISNULL( IsSumQty           , '0' ), 
           @IsUMExtraSeq       = ISNULL( IsUMExtraSeq       , '0' ), 
           @IsUMWorkType       = ISNULL( IsUMWorkType       , '0' ), 
           @IsUMWorkTeam       = ISNULL( IsUMWorkTeam       , '0' ), 
           @IsWorkDate         = ISNULL( IsWorkDate         , '0' ), 
           @IsInvoiceList      = ISNULL( IsInvoiceList      , '0' ), 
           @SerlYear           = ISNULL( SerlYear           , '' ), 
           @IFShipCode         = ISNULL( IFShipCode         , '' ), 
           @SerlNo             = ISNULL( SerlNo             , '' ), 
           @ToWorkDate         = ISNULL( ToWorkDate         , '' ), 
           @FrWorkDate         = ISNULL( FrWorkDate         , '' ), 
           @PJTNo              = ISNULL( PJTNo              , '' ), 
           @TextPJTName        = ISNULL( TextPJTName        , '' ), 
           @WorkPlanReportSeq  = ISNULL( WorkPlanReportSeq  , 0 ), 
           @CfmSeq             = ISNULL( CfmSeq             , 0 ), 
           @ShipCfmSeq         = ISNULL( ShipCfmSeq         , 0 ), 
           @UMWorkDivision     = ISNULL( UMWorkDivision     , 0 ), 
           @UMExtraSeq         = ISNULL( UMExtraSeq         , 0 ), 
           @UMWorkType         = ISNULL( UMWorkType         , 0 ), 
           @UMWorkTeam         = ISNULL( UMWorkTeam         , 0 ), 
           @ShipSeq            = ISNULL( ShipSeq            , 0 ), 
           @PJTTypeSeq         = ISNULL( PJTTypeSeq         , 0 ), 
           @PJTTypeClassSSeq   = ISNULL( PJTTypeClassSSeq   , 0 ), 
           @PJTTypeClassMSeq   = ISNULL( PJTTypeClassMSeq   , 0 ), 
           @BizUnit            = ISNULL( BizUnit            , 0 ), 
           @CustSeq            = ISNULL( CustSeq            , 0 ), 
           @ShipSerlNo         = ISNULL( IFShipCode, '' ) + ISNULL( SerlYear, '' ) + ISNULL( SerlNo, '' ), 
           @FrOutDate          = ISNULL( FrOutDate, ''), 
           @ToOutDate          = ISNULL( ToOutDate, ''), 
           @PJTSeq             = ISNULL( PJTSeq, 0)
      FROM #BIZ_IN_DataBlock1    
    
    SELECT @ShipSerlNo = LTRIM(RTRIM(@ShipSerlNo))
    
    IF @ToWorkDate = '' SELECT @ToWorkDate = '99991231'
    --IF @ToOutDate = '' SELECT @ToOutDate = '99991231'

    -- 계획, 실적 조회조건에 따라 담아두기 
    CREATE TABLE #BaseData 
    (
        Seq             INT, 
        WorkDate        NCHAR(8), 
        UMWeather       INT, 
        MRemark         NVARCHAR(2000), 
        IsCfm           NCHAR(1), 
        PJTSeq          INT, 
        ShipSeq         INT, 
        ShipSerl        INT, 
        UMWorkType      INT, 
        UMWorkTeam      INT, 
        TodayQty        DECIMAL(19,5), 
        TodayMTWeight   DECIMAL(19,5), 
        TodayCBMWeight  DECIMAL(19,5), 
        ExtraGroupSeq   NVARCHAR(500), 
        WorkSrtTime     NVARCHAR(10), 
        WorkEndTime     NVARCHAR(10), 
        RealWorkTime    DECIMAL(19,5), 
        EmpSeq          INT, 
        DRemark         NVARCHAR(2000), 
        UMLoadType      INT
    )



    CREATE TABLE #SumQty 
    (
        Seq             INT, 
        GoodsQty        DECIMAL(19,5), 
        GoodsMTWeight   DECIMAL(19,5), 
        GoodsCBMWeight  DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumMTWeight     DECIMAL(19,5), 
        SumCBMWeight    DECIMAL(19,5), 
        EtcQty          DECIMAL(19,5), 
        EtcMTWeight     DECIMAL(19,5), 
        EtcCBMWeight    DECIMAL(19,5)
    )
    
    
    IF @WorkPlanReportSeq = 1 
    BEGIN -- 작업계획 
        INSERT INTO #BaseData 
        (
            Seq            , WorkDate       , UMWeather      , MRemark        , IsCfm          , 
            PJTSeq         , ShipSeq        , ShipSerl       , UMWorkType     , UMWorkTeam     , 
            TodayQty       , TodayMTWeight  , TodayCBMWeight , ExtraGroupSeq  , WorkSrtTime    , 
            WorkEndTime    , RealWorkTime   , EmpSeq         , DRemark        , UMLoadType
        )
        SELECT A.WorkPlanSeq    , A.WorkDate       , A.UMWeather      , A.MRemark        , A.IsCfm          , 
               A.PJTSeq         , A.ShipSeq        , A.ShipSerl       , A.UMWorkType     , A.UMWorkTeam     , 
               A.TodayQty       , A.TodayMTWeight  , A.TodayCBMWeight , A.ExtraGroupSeq  , A.WorkSrtTime    , 
               A.WorkEndTime    , A.RealWorkTime   , A.EmpSeq         , A.DRemark        , A.UMLoadType   
          FROM mnpt_TPJTWorkPlan AS A 
          LEFT OUTER JOIN _TPJTProject                  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
          LEFT OUTER JOIN _TDABizUnit                   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
          LEFT OUTER JOIN _TPJTType                     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
          LEFT OUTER JOIN _TDACust                      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
          LEFT OUTER JOIN mnpt_TPJTShipDetail           AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
          LEFT OUTER JOIN mnpt_TPJTShipMaster           AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
          LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
          LEFT OUTER JOIN _VDAItemClass                 AS V ON ( V.CompanySeq = @CompanySeq AND V.ItemClassSSeq = C.ItemClassSeq ) 
          LEFT OUTER JOIN _TDAUMinorValue               AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.UMWorkType AND L.Serl = 1000001 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND ( A.WorkDate BETWEEN @FrWorkDate AND @ToWorkDate ) 
           AND ( @PJTTypeClassMSeq = 0 OR V.ItemClassMSeq = @PJTTypeClassMSeq ) 
           AND ( @UMWorkTeam = 0 OR A.UMWorkTeam = @UMWorkTeam ) 
           AND ( @BizUnit = 0 OR P.BizUnit = @BizUnit ) 
           AND ( @PJTTypeClassSSeq = 0 OR V.ItemClassSSeq = @PJTTypeClassSSeq ) 
           AND ( @UMWorkType = 0 OR A.UMWorkType = @UMWorkType ) 
           AND ( @CfmSeq = 0 OR A.IsCfm = CASE WHEN @CfmSeq = 2 THEN '1' ELSE '0' END ) 
           AND ( @PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%' ) 
           AND ( @PJTTypeSeq = 0 OR P.PJTTypeSeq = @PJTTypeSeq ) 
           AND ( @UMExtraSeq = 0 OR A.ExtraGroupSeq LIKE '%' + CONVERT(NVARCHAR(100),@UMExtraSeq) + '%' ) 
           AND ( @ShipCfmSeq = 0 OR S.IsCfm = CASE WHEN @ShipCfmSeq = 2 THEN '1' ELSE '0' END ) 
           AND ( @TextPJTName = '' OR P.PJTName LIKE @TextPJTName + '%' ) 
           AND ( @ShipSerlNo = '' OR G.IFShipCode + G.ShipSerlNo LIKE @ShipSerlNo + '%' ) 
           AND ( @UMWorkDivision = 0 OR ISNULL(L.ValueText,'0') = CASE WHEN @UMWorkDivision = 1015815001 THEN '1' ELSE '0' END ) 
           AND ( @CustSeq = 0 OR P.CustSeq = @CustSeq ) 
           AND ( @ShipSeq = 0 OR A.ShipSeq = @ShipSeq ) 
           AND ( (@FrOutDate = '' AND @ToOutDate = '') OR (LEFT(G.OutDateTime,8) BETWEEN @FrOutDate AND CASE WHEN @ToOutDate = '' THEN '99991231' ELSE @ToOutDate END) ) 
           AND ( @PJTSeq = 0 OR A.PJTSeq = @PJTSeq ) 
        
        IF @IsSumQty = '1'  -- 누계,잔량 표시
        BEGIN 
            INSERT INTO #SumQty 
            ( 
                 Seq            , GoodsQty       , GoodsMTWeight  , GoodsCBMWeight , SumQty         ,
                 SumMTWeight    , SumCBMWeight   , EtcQty         , EtcMTWeight    , EtcCBMWeight   
            )
            SELECT A.WorkPlanSeq,
           
                   S.PlanQty AS GoodsQty, 
                   S.PlanMTWeight AS GoodsMTWeight, 
                   S.PlanCBMWeight AS GoodsCBMWeight, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumQty END AS SumQty, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumMTWeight END AS SumMTWeight, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumCBMWeight END AS SumCBMWeight, 

                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight
              FROM mnpt_TPJTWorkPlan            AS A 
              LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
              OUTER APPLY ( -- 전일 누계
                            SELECT PJTSeq, 
                                   ShipSeq, 
                                   ShipSerl, 
                                   UMWorkType, 
                                   SUM(TodayQty) AS SumQty, 
                                   SUM(TodayMTWeight) AS SumMTWeight, 
                                   SUM(TodayCBMWeight) AS SumCBMWeight
                              FROM mnpt_TPJTWorkPlan AS Z 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.WorkDate < A.WorkDate 
                               AND Z.PJTSeq = A.PJTSeq 
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND Z.UMWorkType = A.UMWorkType 
                             GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.UMWorkType 
                          ) AS K 
              OUTER APPLY ( -- 전일 누계
                            SELECT Z.PJTSeq, 
                                   Z.ShipSeq, 
                                   Z.ShipSerl, 
                                   CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                                   SUM(Z.TodayQty) AS SumQty, 
                                   SUM(Z.TodayMTWeight) AS SumMTWeight, 
                                   SUM(Z.TodayCBMWeight) AS SumCBMWeight
                              FROM mnpt_TPJTWorkPlan AS Z 
                              LEFT OUTER JOIN _TDAUMinorValue   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.WorkDate < A.WorkDate 
                               AND Z.PJTSeq = A.PJTSeq
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                             GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                            ) AS KK 
              OUTER APPLY ( -- 금일 작업
                            SELECT Z.PJTSeq, 
                                   Z.ShipSeq, 
                                   Z.ShipSerl, 
                                   CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                                   SUM(Z.TodayQty) AS TodayQty, 
                                   SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                                   SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                                FROM mnpt_TPJTWorkPlan AS Z 
                                LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                               WHERE Z.CompanySeq = @CompanySeq
                                 AND Z.WorkDate = A.WorkDate
                               AND Z.PJTSeq = A.PJTSeq
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                               GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                          ) AS W 
              LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND EXISTS (SELECT 1 FROM #BaseData WHERE Seq = A.WorkPlanSeq) 
        END 
    END 
    ELSE 
    BEGIN -- 작업실적 
        INSERT INTO #BaseData 
        (
            Seq            , WorkDate       , UMWeather      , MRemark        , IsCfm          , 
            PJTSeq         , ShipSeq        , ShipSerl       , UMWorkType     , UMWorkTeam     , 
            TodayQty       , TodayMTWeight  , TodayCBMWeight , ExtraGroupSeq  , WorkSrtTime    , 
            WorkEndTime    , RealWorkTime   , EmpSeq         , DRemark        , UMLoadType
        )
        SELECT A.WorkReportSeq  , A.WorkDate       , A.UMWeather      , A.MRemark        , A.IsCfm          , 
               A.PJTSeq         , A.ShipSeq        , A.ShipSerl       , A.UMWorkType     , A.UMWorkTeam     , 
               A.TodayQty       , A.TodayMTWeight  , A.TodayCBMWeight , A.ExtraGroupSeq  , A.WorkSrtTime    , 
               A.WorkEndTime    , A.RealWorkTime   , A.EmpSeq         , A.DRemark        , A.UMLoadType
          FROM mnpt_TPJTWorkReport                      AS A 
          LEFT OUTER JOIN _TPJTProject                  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
          LEFT OUTER JOIN _TDABizUnit                   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
          LEFT OUTER JOIN _TPJTType                     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
          LEFT OUTER JOIN _TDACust                      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
          LEFT OUTER JOIN mnpt_TPJTShipDetail           AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
          LEFT OUTER JOIN mnpt_TPJTShipMaster           AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
          LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
          LEFT OUTER JOIN _VDAItemClass                 AS V ON ( V.CompanySeq = @CompanySeq AND V.ItemClassSSeq = C.ItemClassSeq ) 
          LEFT OUTER JOIN _TDAUMinorValue               AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.UMWorkType AND L.Serl = 1000001 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND ( A.WorkDate BETWEEN @FrWorkDate AND @ToWorkDate ) 
           AND ( @PJTTypeClassMSeq = 0 OR V.ItemClassMSeq = @PJTTypeClassMSeq ) 
           AND ( @UMWorkTeam = 0 OR A.UMWorkTeam = @UMWorkTeam ) 
           AND ( @BizUnit = 0 OR P.BizUnit = @BizUnit ) 
           AND ( @PJTTypeClassSSeq = 0 OR V.ItemClassSSeq = @PJTTypeClassSSeq ) 
           AND ( @UMWorkType = 0 OR A.UMWorkType = @UMWorkType ) 
           AND ( @CfmSeq = 0 OR A.IsCfm = CASE WHEN @CfmSeq = 2 THEN '1' ELSE '0' END ) 
           AND ( @PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%' ) 
           AND ( @PJTTypeSeq = 0 OR P.PJTTypeSeq = @PJTTypeSeq ) 
           AND ( @UMExtraSeq = 0 OR A.ExtraGroupSeq LIKE '%' + CONVERT(NVARCHAR(100),@UMExtraSeq) + '%' ) 
           AND ( @ShipCfmSeq = 0 OR S.IsCfm = CASE WHEN @ShipCfmSeq = 2 THEN '1' ELSE '0' END ) 
           AND ( @TextPJTName = '' OR P.PJTName LIKE @TextPJTName + '%' ) 
           AND ( @ShipSerlNo = '' OR G.IFShipCode + G.ShipSerlNo LIKE @ShipSerlNo + '%' ) 
           AND ( @UMWorkDivision = 0 OR ISNULL(L.ValueText,'0') = CASE WHEN @UMWorkDivision = 1015815001 THEN '1' ELSE '0' END ) 
           AND ( @CustSeq = 0 OR P.CustSeq = @CustSeq ) 
           AND ( @ShipSeq = 0 OR A.ShipSeq = @ShipSeq ) 
           AND ( (@FrOutDate = '' AND @ToOutDate = '') OR (LEFT(G.OutDateTime,8) BETWEEN @FrOutDate AND CASE WHEN @ToOutDate = '' THEN '99991231' ELSE @ToOutDate END) ) 
           AND ( @PJTSeq = 0 OR A.PJTSeq = @PJTSeq ) 
        
        IF @IsSumQty = '1' -- 누계,잔량 표시
        BEGIN 
            INSERT INTO #SumQty 
            ( 
                 Seq            , GoodsQty       , GoodsMTWeight  , GoodsCBMWeight , SumQty         ,
                 SumMTWeight    , SumCBMWeight   , EtcQty         , EtcMTWeight    , EtcCBMWeight   
            )
            SELECT A.WorkReportSeq,
           
                   S.PlanQty AS GoodsQty, 
                   S.PlanMTWeight AS GoodsMTWeight, 
                   S.PlanCBMWeight AS GoodsCBMWeight, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumQty END AS SumQty, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumMTWeight END AS SumMTWeight, 
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumCBMWeight END AS SumCBMWeight, 

                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
                   CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight
              FROM mnpt_TPJTWorkReport            AS A 
              LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
              OUTER APPLY ( -- 전일 누계
                            SELECT PJTSeq, 
                                   ShipSeq, 
                                   ShipSerl, 
                                   UMWorkType, 
                                   SUM(TodayQty) AS SumQty, 
                                   SUM(TodayMTWeight) AS SumMTWeight, 
                                   SUM(TodayCBMWeight) AS SumCBMWeight
                              FROM mnpt_TPJTWorkReport AS Z 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.WorkDate < A.WorkDate 
                               AND Z.PJTSeq = A.PJTSeq 
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND Z.UMWorkType = A.UMWorkType 
                             GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.UMWorkType 
                          ) AS K 
              OUTER APPLY ( -- 전일 누계
                            SELECT Z.PJTSeq, 
                                   Z.ShipSeq, 
                                   Z.ShipSerl, 
                                   CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                                   SUM(Z.TodayQty) AS SumQty, 
                                   SUM(Z.TodayMTWeight) AS SumMTWeight, 
                                   SUM(Z.TodayCBMWeight) AS SumCBMWeight
                              FROM mnpt_TPJTWorkReport AS Z 
                              LEFT OUTER JOIN _TDAUMinorValue   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.WorkDate < A.WorkDate 
                               AND Z.PJTSeq = A.PJTSeq
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                             GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                            ) AS KK 
              OUTER APPLY ( -- 금일 작업
                            SELECT Z.PJTSeq, 
                                   Z.ShipSeq, 
                                   Z.ShipSerl, 
                                   CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                                   SUM(Z.TodayQty) AS TodayQty, 
                                   SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                                   SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                                FROM mnpt_TPJTWorkReport AS Z 
                                LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                               WHERE Z.CompanySeq = @CompanySeq
                                 AND Z.WorkDate = A.WorkDate
                               AND Z.PJTSeq = A.PJTSeq
                               AND Z.ShipSeq = A.ShipSeq 
                               AND Z.ShipSerl = A.ShipSerl 
                               AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                               GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                          ) AS W 
              LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND EXISTS (SELECT 1 FROM #BaseData WHERE Seq = A.WorkPlanSeq) 
        END 

    END 
    
    
    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, Srt
    --------------------------------------------------
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( Seq, ExtraGroupSeq ) 
    SELECT Seq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM #BaseData 
     
    
    CREATE TABLE #CheckExtraSeq 
    (
        Seq             INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        Seq             INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @Seq            INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @Seq = Seq
          FROM #ExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( Seq, UMExtraType, UMExtraTypeName ) 
        SELECT @Seq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( Seq, MultiExtraName ) 
        SELECT @Seq, STUFF(@ExtraGroupName,1,1,'')


        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, End  
    --------------------------------------------------

    SELECT A.Seq, 
           CASE WHEN ISNULL(A.ShipSeq,0) = 0 OR ISNULL(A.ShipSerl,0) = 0 THEN ISNULL(C.IsCreateInvoice,'0') ELSE ISNULL(B.IsCreateInvoice,'0') END AS IsCreateInvoice, 
           ISNULL(D.IsUnionAmt,'0') AS IsUnionAmt, 
           ISNULL(E.IsDailyAmt,'0') AS IsDailyAmt
      INTO #IsInvoice
      FROM #BaseData AS A 
      LEFT OUTER JOIN (
                        SELECT Z.PJTSeq, Z.ShipSeq, Z.ShipSerl , '1' AS IsCreateInvoice -- 모선이 있는 청구생성여부
                          FROM mnpt_TPJTLinkInvoiceItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND EXISTS (SELECT 1 FROM #BaseData WHERE PJTSeq = Z.PJTSeq AND ShipSeq = Z.ShipSeq AND ShipSerl = Z.ShipSerl) 
                         GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl 
                      ) AS B ON ( B.PJTSeq = A.PJTSeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN (
                        SELECT Z.PJTSeq, Z.ChargeDate, '1' AS IsCreateInvoice -- 모선이 없는 청구생성여부
                          FROM mnpt_TPJTLinkInvoiceItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND EXISTS (SELECT 1 FROM #BaseData WHERE PJTSeq = Z.PJTSeq AND LEFT(WorkDate,6) = Z.ChargeDate)
                         GROUP BY Z.PJTSeq, Z.ChargeDate
                      ) AS C ON ( C.PJTSeq = A.PJTSeq AND C.ChargeDate = LEFT(A.WorkDate,6) )
      LEFT OUTER JOIN (
                        SELECT Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.WorkDate, Z.UMWorkTeam, '1' AS IsUnionAmt 
                          FROM mnpt_TPJTUnionPayDaily AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND EXISTS (
                                       SELECT 1 
                                         FROM #BaseData 
                                        WHERE PJTSeq = Z.PJTSeq 
                                          AND ShipSeq = Z.ShipSeq 
                                          AND ShipSerl = Z.ShipSerl 
                                          AND WorkDate = Z.WorkDate 
                                          And UMWorkTeam = Z.UMWorkTeam
                                      )
                         GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.WorkDate, Z.UMWorkTeam
                      ) AS D ON ( D.PJTSeq = A.PJTSeq AND D.ShipSeq = A.ShipSeq AND D.ShipSerl = A.ShipSerl AND D.WorkDate = A.WorkDate AND D.UMWorkTeam = A.UMWorkTeam ) 
      LEFT OUTER JOIN (
                        SELECT Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.WorkDate, Z.UMWorkTeam, '1' AS IsDailyAmt
                          FROM mnpt_TPJTUnionPayDaily2 AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND EXISTS (
                                       SELECT 1 
                                         FROM #BaseData 
                                        WHERE PJTSeq = Z.PJTSeq 
                                          AND ShipSeq = Z.ShipSeq 
                                          AND ShipSerl = Z.ShipSerl 
                                          AND WorkDate = Z.WorkDate 
                                          And UMWorkTeam = Z.UMWorkTeam
                                      )
                         GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.WorkDate, Z.UMWorkTeam
                      ) AS E ON ( E.PJTSeq = A.PJTSeq AND E.ShipSeq = A.ShipSeq AND E.ShipSerl = A.ShipSerl AND E.WorkDate = A.WorkDate AND E.UMWorkTeam = A.UMWorkTeam ) 

                       
    CREATE TABLE #Result 
    (
        PJTName             NVARCHAR(200), 
        PJTNo               NVARCHAR(200), 
        PJTTypeName         NVARCHAR(200), 
        CustName            NVARCHAR(200), 
        ShipSerlNo          NVARCHAR(100), 
        EnShipName          NVARCHAR(200), 
        InDateTime          NVARCHAR(100), 
        OutDateTime         NVARCHAR(100), 
        DiffApproachTime    DECIMAL(19,5), 
        GoodsQty            DECIMAL(19,5), 
        GoodsMTWeight       DECIMAL(19,5), 
        GoodsCBMWeight      DECIMAL(19,5), 
        IsShipCfm           NCHAR(1), 
        WorkPlanReport      NVARCHAR(100), 
        WorkDate            NCHAR(8), 
        WorkDay             NVARCHAR(10), 
        UMHoliDayTypeName   NVARCHAR(200), 
        UMWeatherName       NVARCHAR(200), 
        UMWorkTeamName      NVARCHAR(200), 
        UMWorkTypeName      NVARCHAR(200), 
        IsInvoice           NCHAR(1), 
        IsShip              NCHAR(1), 
        MultiExtraName      NVARCHAR(200), 
        SumQty              DECIMAL(19,5), 
        SumMTWeight         DECIMAL(19,5), 
        SumCBMWeight        DECIMAL(19,5), 
        TodayQty            DECIMAL(19,5), 
        TodayMTWeight       DECIMAL(19,5), 
        TodayCBMWeight      DECIMAL(19,5), 
        EtcQty              DECIMAL(19,5), 
        EtcMTWeight         DECIMAL(19,5), 
        EtcCBMWeight        DECIMAL(19,5), 
        WorkSrtTime         NVARCHAR(10), 
        WorkEndTime         NVARCHAR(10), 
        RealWorkTime        DECIMAL(19,5), 
        EmpName             NVARCHAR(200), 
        DRemark             NVARCHAR(2000), 
        IsCfm               NCHAR(1), 
        IsCreateInvoice     NCHAR(1), 
        IsUnionAmt          NCHAR(1), 
        IsDailyAmt          NCHAR(1), 
        WorkPlanSeq         INT, 
        WorkReportSeq       INT, 
        UMBisWorkTypeName   NVARCHAR(200), 
        SelfToolName        NVARCHAR(200), 
        RentToolName        NVARCHAR(200), 
        ToolWorkTime        DECIMAL(19,5), 
        DriverEmpName1      NVARCHAR(200), 
        DriverEmpName2      NVARCHAR(200), 
        DriverEmpName3      NVARCHAR(200), 
        NDEmpName           NVARCHAR(200), 
        NDUnionUnloadGang   DECIMAL(19,5),
        NDUnionUnloadMan    DECIMAL(19,5),
        DUnionDay           DECIMAL(19,5),
        DUnionHalf          DECIMAL(19,5),
        DUnionMonth         DECIMAL(19,5),
        NDUnionDailyDay     DECIMAL(19,5),
        NDUnionDailyHalf    DECIMAL(19,5),
        NDUnionDailyMonth   DECIMAL(19,5),
        NDUnionSignalDay    DECIMAL(19,5),
        NDUnionSignalHalf   DECIMAL(19,5),
        NDUnionSignalMonth  DECIMAL(19,5),
        NDUnionEtcDay       DECIMAL(19,5),
        NDUnionEtcHalf      DECIMAL(19,5),
        NDUnionEtcMonth     DECIMAL(19,5),
        DDailyDay           DECIMAL(19,5),
        DDailyHalf          DECIMAL(19,5),
        DDailyMonth         DECIMAL(19,5),
        NDDailyDay          DECIMAL(19,5),
        NDDailyHalf         DECIMAL(19,5),
        NDDailyMonth        DECIMAL(19,5),
        DOSDay              DECIMAL(19,5),
        DOSHalf             DECIMAL(19,5),
        DOSMonth            DECIMAL(19,5),
        NDOSDay             DECIMAL(19,5),
        NDOSHalf            DECIMAL(19,5),
        NDOSMonth           DECIMAL(19,5),
        DEtcDay             DECIMAL(19,5),
        DEtcHalf            DECIMAL(19,5),
        DEtcMonth           DECIMAL(19,5),
        NDEtcDay            DECIMAL(19,5),
        NDEtcHalf           DECIMAL(19,5),
        NDEtcMonth          DECIMAL(19,5),
        DRemark2            NVARCHAR(2000), 
        WorkPlanSerl        INT, 
        WorkReportSerl      INT, 
        Partition_IDX       INT, 
        UMLoadTypeName      NVARCHAR(200), 
        DDailyEmpName       NVARCHAR(200), 
        NDDailyEmpName      NVARCHAR(200) 
    
    )
    
    SELECT P.PJTName,           -- 프로젝트명 
           P.PJTNo,             -- 프로젝트번호 
           C.PJTTypeName,       -- 화태
           D.CustName,          -- 거래처 
           G.IFShipCode + '-' + LEFT(G.ShipSerlNo,4) + '-' + RIGHT(G.ShipSerlNo,3) AS ShipSerlNo, -- 모선항차 
           H.EnShipName,        -- 모선명 
           STUFF(STUFF(LEFT(G.InDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(G.InDateTime,4),3,0,':') AS InDateTime, -- 입항일시 
           STUFF(STUFF(LEFT(G.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(G.OutDateTime,4),3,0,':') AS OutDateTime, -- 출항일시 
           -- 접안시간(시간단위로 올림) : (입항일시[DATETIME 타입(분으로 계산)] - 접안일시[DATETIME 타입(분으로 계산)]) / 60. 
          G.DiffApproachTime, -- 접안시간
          S.PlanQty AS GoodsQty, 
          S.PlanMTWeight AS GoodsMTWeight, 
          S.PlanCBMWeight AS GoodsCBMWeight, 
          S.IsCfm AS IsShipCfm, 
          CASE WHEN @WorkPlanReportSeq = 1 THEN '작업계획' ELSE '작업실적' END AS WorkPlanReport, 
          A.WorkDate, 
          DATENAME (WeekDay, A.WorkDate) AS WorkDay,   -- 요일 
          E.DayTypeName AS UMHoliDayTypeName,          -- 공휴구분 
          F.MinorName AS UMWeatherName,                -- 날씨 
          I.MinorName AS UMWorkTeamName,               -- 주야 
          J.MinorName AS UMWorkTypeName,               -- 작업항목 
          CASE WHEN K.UMWorkType IS NULL THEN '0' ELSE '1' END AS IsInvoice, -- 청구대상 
          CASE WHEN L.ValueText = '1' THEN '1' ELSE '0' END AS IsShip, -- 본선작업
          M.MultiExtraName,                            -- 할증구분
          A.WorkSrtTime,                               -- 작업시작시간
          A.WorkEndTime,                               -- 작업종료시간
          A.RealWorkTime, 
          N.EmpName,                                   -- 총괄포맨
          A.DRemark,                                   -- 특이사항
          A.IsCfm,                                     -- 승인여부 
          Q.IsCreateInvoice, -- 청구생성
          Q.IsUnionAmt, -- 노조노임산출
          Q.IsDailyAmt, -- 일용임금산출 
          CASE WHEN @WorkPlanReportSeq = 1 THEN A.Seq ELSE 0 END AS WorkPlanSeq, 
          CASE WHEN @WorkPlanReportSeq = 2 THEN A.Seq ELSE 0 END AS WorkReportSeq, 
          A.TodayQty, 
          A.TodayMTWeight, 
          A.TodayCBMWeight, 
          O.SumQty, 
          O.SumMTWeight, 
          O.SumCBMWeight, 
          O.EtcQty, 
          O.EtcMTWeight, 
          O.EtcCBMWeight, 
          R.MinorName AS UMLoadTypeName

      INTO #PlanReportMaster
      FROM #BaseData                                AS A 
      LEFT OUTER JOIN _TPJTProject                  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit                   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType                     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust                      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail           AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster           AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.Solar,
                               MAX(X.DayTypeName) AS DayTypeName
                          FROM _TCOMCalendarHolidayPRWkUnit AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue   AS Y ON ( Y.CompanySeq  = @CompanySeq
                                                                  AND Y.ValueSeq    = Z.DayTypeSeq
                                                                  AND Y.MajorSeq    = 1015916
                                                                  AND Y.Serl        = 1000001 
                                                                    )
                          LEFT OUTER JOIN _TPRWkDayType     AS X ON ( X.CompanySeq = @CompanySeq AND X.DayTypeSeq = Y.ValueSeq ) 
	                     WHERE Z.CompanySeq = @CompanySeq
	                     GROUP BY Z.Solar 
                       ) AS E ON ( E.Solar = A.WorkDate ) 
      LEFT OUTER JOIN _TDAUMinor                    AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN _TDAUMinor                    AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkTeam ) 
      LEFT OUTER JOIN _TDAUMinor                    AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMWorkType ) 
      OUTER APPLY (
                    SELECT DISTINCT Z.UMWorkType
                      FROM mnpt_TPJTProjectMapping AS Z
                     WHERE Z.CompanySeq = @CompanySeq
                       AND Z.IsAmt = '1' 
                       AND Z.PJTSeq = A.PJTSeq 
                       AND Z.UMWorkType = A.UMWorkType 
                  ) AS K 
      LEFT OUTER JOIN _TDAUMinorValue               AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = J.MinorSeq AND L.Serl = 1000001 ) 
      LEFT OUTER JOIN #GroupExtraName               AS M ON ( M.Seq = A.Seq ) 
      LEFT OUTER JOIN _TDAEmp                       AS N ON ( N.CompanySeq = @CompanySeq AND N.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN #SumQty                       AS O ON ( O.Seq = A.Seq ) 
      LEFT OUTER JOIN #IsInvoice                    AS Q ON ( Q.Seq = A.Seq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMLoadType ) 
     WHERE (@IsShipWork = '0' OR L.ValueText = @IsShipWork) -- 본선작업항목만보기
       AND (CASE WHEN K.UMWorkType IS NULL THEN '0' ELSE '1' END 
          = CASE WHEN @IsInvoiceList = '1' 
                 THEN '1' 
                 ELSE (CASE WHEN K.UMWorkType IS NULL THEN '0' ELSE '1' END) 
                 END -- 청구대상만 보기
           )

       
    
    
    -- Detail 
    IF @WorkPlanReportSeq = 1 
    BEGIN -- 작업계획 
        INSERT INTO #Result 
        (
            PJTName            , PJTNo              , PJTTypeName        , CustName           , ShipSerlNo         , 
            EnShipName         , InDateTime         , OutDateTime        , DiffApproachTime   , GoodsQty           , 
            GoodsMTWeight      , GoodsCBMWeight     , IsShipCfm          , WorkPlanReport     , WorkDate           , 
            WorkDay            , UMHoliDayTypeName  , UMWeatherName      , UMWorkTeamName     , UMWorkTypeName     , 
            IsInvoice          , IsShip             , MultiExtraName     , WorkSrtTime        , WorkEndTime        , 
            RealWorkTime       , EmpName            , DRemark            , IsCfm              , IsCreateInvoice    , 
            IsUnionAmt         , IsDailyAmt         , WorkPlanSeq        , WorkReportSeq      , UMBisWorkTypeName  , 
            SelfToolName       , RentToolName       , ToolWorkTime       , DriverEmpName1     , DriverEmpName2     , 
            DriverEmpName3     , NDEmpName          , NDUnionUnloadGang  , NDUnionUnloadMan   , DUnionDay          , 
            DUnionHalf         , DUnionMonth        , NDUnionDailyDay    , NDUnionDailyHalf   , NDUnionDailyMonth  , 
            NDUnionSignalDay   , NDUnionSignalHalf  , NDUnionSignalMonth , NDUnionEtcDay      , NDUnionEtcHalf     , 
            NDUnionEtcMonth    , DDailyDay          , DDailyHalf         , DDailyMonth        , NDDailyDay         , 
            NDDailyHalf        , NDDailyMonth       , DOSDay             , DOSHalf            , DOSMonth           , 
            NDOSDay            , NDOSHalf           , NDOSMonth          , DEtcDay            , DEtcHalf           , 
            DEtcMonth          , NDEtcDay           , NDEtcHalf          , NDEtcMonth         , DRemark2           , 
            WorkPlanSerl       , WorkReportSerl     , TodayQty           , TodayMTWeight      , TodayCBMWeight     , 
            SumQty             , SumMTWeight        , SumCBMWeight       , EtcQty             , EtcMTWeight        , 
            EtcCBMWeight       , Partition_IDX      , UMLoadTypeName     , DDailyEmpName      , NDDailyEmpName
        ) 
        SELECT A.PJTName            , A.PJTNo              , A.PJTTypeName        , A.CustName           , A.ShipSerlNo         ,
               A.EnShipName         , A.InDateTime         , A.OutDateTime        , A.DiffApproachTime   , A.GoodsQty           ,
               A.GoodsMTWeight      , A.GoodsCBMWeight     , A.IsShipCfm          , A.WorkPlanReport     , A.WorkDate           ,
               A.WorkDay            , A.UMHoliDayTypeName  , A.UMWeatherName      , A.UMWorkTeamName     , A.UMWorkTypeName     ,
               A.IsInvoice          , A.IsShip             , A.MultiExtraName     , A.WorkSrtTime        , A.WorkEndTime        ,
               A.RealWorkTime       , A.EmpName            , A.DRemark            , A.IsCfm              , A.IsCreateInvoice    ,
               A.IsUnionAmt         , A.IsDailyAmt         , A.WorkPlanSeq        , A.WorkReportSeq      , 

               CC.MinorName AS UMBisWorkTypeName,               -- 업무구분 
               DD.EquipmentSName AS SelfToolName,    -- 자가장비 
               EE.EquipmentSName AS RentToolName,    -- 임차장비 
               BB.ToolWorkTime,                      -- 운행시간 
               FF.EmpName AS DriverEmpName1,         -- 운전원당사1
               II.EmpName AS DriverEmpName2,         -- 운전원당사2
               GG.EmpName AS DriverEmpName3,         -- 운전원당사3
               HH.EmpName AS NDEmpName,              -- 운전원외당사
               BB.NDUnionUnloadGang  ,
               BB.NDUnionUnloadMan   ,
               BB.DUnionDay          ,
               BB.DUnionHalf         ,
               BB.DUnionMonth        ,
               BB.NDUnionDailyDay    ,
               BB.NDUnionDailyHalf   ,
               BB.NDUnionDailyMonth  ,
               BB.NDUnionSignalDay   ,
               BB.NDUnionSignalHalf  ,
               BB.NDUnionSignalMonth ,
               BB.NDUnionEtcDay      ,
               BB.NDUnionEtcHalf     ,
               BB.NDUnionEtcMonth    ,
               BB.DDailyDay          ,
               BB.DDailyHalf         ,
               BB.DDailyMonth        ,
               BB.NDDailyDay         ,
               BB.NDDailyHalf        ,
               BB.NDDailyMonth       ,
               BB.DOSDay             ,
               BB.DOSHalf            ,
               BB.DOSMonth           ,
               BB.NDOSDay            ,
               BB.NDOSHalf           ,
               BB.NDOSMonth          ,
               BB.DEtcDay            ,
               BB.DEtcHalf           ,
               BB.DEtcMonth          ,
               BB.NDEtcDay           ,
               BB.NDEtcHalf          ,
               BB.NDEtcMonth         ,
               BB.DRemark AS DRemark2, 
               BB.WorkPlanSerl, 
               0 AS WorkReportSeq, 
               A.TodayQty           , 
               A.TodayMTWeight      , 
               A.TodayCBMWeight     , 
               A.SumQty             , 
               A.SumMTWeight        , 
               A.SumCBMWeight       , 
               A.EtcQty             , 
               A.EtcMTWeight        , 
               A.EtcCBMWeight       , 
               ROW_NUMBER() OVER ( PARTITION BY A.WorkPlanSeq ORDER BY A.WorkPlanSeq ) AS Partition_IDX, 
               A.UMLoadTypeName, 
               '', 
               '' 
          FROM #PlanReportMaster AS A 
          LEFT OUTER JOIN mnpt_TPJTWorkPlanItem         AS BB ON ( BB.CompanySeq = @CompanySeq AND BB.WorkPlanSeq = A.WorkPlanSeq ) 
          LEFT OUTER JOIN _TDAUMinor                    AS CC ON ( CC.CompanySeq = @CompanySeq AND CC.MinorSeq = BB.UMBisWorkType ) 
          LEFT OUTER JOIN mnpt_TPDEquipment             AS DD ON ( DD.CompanySeq = @CompanySeq AND DD.EquipmentSeq = BB.SelfToolSeq ) 
          LEFT OUTER JOIN mnpt_TPDEquipment             AS EE ON ( EE.CompanySeq = @CompanySeq AND EE.EquipmentSeq = BB.RentToolSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS FF ON ( FF.CompanySeq = @CompanySeq AND FF.EmpSeq = BB.DriverEmpSeq1 ) 
          LEFT OUTER JOIN _TDAEmp                       AS II ON ( II.CompanySeq = @CompanySeq AND II.EmpSeq = BB.DriverEmpSeq2 ) 
          LEFT OUTER JOIN _TDAEmp                       AS GG ON ( GG.CompanySeq = @CompanySeq AND GG.EmpSeq = BB.DriverEmpSeq3 ) 
          LEFT OUTER JOIN _TDAEmp                       AS HH ON ( HH.CompanySeq = @CompanySeq AND HH.EmpSeq = BB.NDEmpSeq ) 
    END 
    ELSE 
    BEGIN -- 작업실적 
        INSERT INTO #Result 
        (
            PJTName            , PJTNo              , PJTTypeName        , CustName           , ShipSerlNo         , 
            EnShipName         , InDateTime         , OutDateTime        , DiffApproachTime   , GoodsQty           , 
            GoodsMTWeight      , GoodsCBMWeight     , IsShipCfm          , WorkPlanReport     , WorkDate           , 
            WorkDay            , UMHoliDayTypeName  , UMWeatherName      , UMWorkTeamName     , UMWorkTypeName     , 
            IsInvoice          , IsShip             , MultiExtraName     , WorkSrtTime        , WorkEndTime        , 
            RealWorkTime       , EmpName            , DRemark            , IsCfm              , IsCreateInvoice    , 
            IsUnionAmt         , IsDailyAmt         , WorkPlanSeq        , WorkReportSeq      , UMBisWorkTypeName  , 
            SelfToolName       , RentToolName       , ToolWorkTime       , DriverEmpName1     , DriverEmpName2     , 
            DriverEmpName3     , NDEmpName          , NDUnionUnloadGang  , NDUnionUnloadMan   , DUnionDay          , 
            DUnionHalf         , DUnionMonth        , NDUnionDailyDay    , NDUnionDailyHalf   , NDUnionDailyMonth  , 
            NDUnionSignalDay   , NDUnionSignalHalf  , NDUnionSignalMonth , NDUnionEtcDay      , NDUnionEtcHalf     , 
            NDUnionEtcMonth    , DDailyDay          , DDailyHalf         , DDailyMonth        , NDDailyDay         , 
            NDDailyHalf        , NDDailyMonth       , DOSDay             , DOSHalf            , DOSMonth           , 
            NDOSDay            , NDOSHalf           , NDOSMonth          , DEtcDay            , DEtcHalf           , 
            DEtcMonth          , NDEtcDay           , NDEtcHalf          , NDEtcMonth         , DRemark2           , 
            WorkPlanSerl       , WorkReportSerl     , TodayQty           , TodayMTWeight      , TodayCBMWeight     , 
            SumQty             , SumMTWeight        , SumCBMWeight       , EtcQty             , EtcMTWeight        , 
            EtcCBMWeight       , Partition_IDX      , UMLoadTypeName     , DDailyEmpName      , NDDailyEmpName
        ) 
        SELECT A.PJTName            , A.PJTNo              , A.PJTTypeName        , A.CustName           , A.ShipSerlNo         ,
               A.EnShipName         , A.InDateTime         , A.OutDateTime        , A.DiffApproachTime   , A.GoodsQty           ,
               A.GoodsMTWeight      , A.GoodsCBMWeight     , A.IsShipCfm          , A.WorkPlanReport     , A.WorkDate           ,
               A.WorkDay            , A.UMHoliDayTypeName  , A.UMWeatherName      , A.UMWorkTeamName     , A.UMWorkTypeName     ,
               A.IsInvoice          , A.IsShip             , A.MultiExtraName     , A.WorkSrtTime        , A.WorkEndTime        ,
               A.RealWorkTime       , A.EmpName            , A.DRemark            , A.IsCfm              , A.IsCreateInvoice    ,
               A.IsUnionAmt         , A.IsDailyAmt         , A.WorkPlanSeq        , A.WorkReportSeq      , 

               CC.MinorName AS UMBisWorkType,        -- 업무구분 
               DD.EquipmentSName AS SelfToolName,    -- 자가장비 
               EE.EquipmentSName AS RentToolName,    -- 임차장비 
               BB.ToolWorkTime,                      -- 운행시간 
               FF.EmpName AS DriverEmpName1,         -- 운전원당사1
               II.EmpName AS DriverEmpName2,         -- 운전원당사2
               GG.EmpName AS DriverEmpName3,         -- 운전원당사3
               HH.EmpName AS NDEmpName,              -- 운전원외당사
               BB.NDUnionUnloadGang  ,
               BB.NDUnionUnloadMan   ,
               BB.DUnionDay          ,
               BB.DUnionHalf         ,
               BB.DUnionMonth        ,
               BB.NDUnionDailyDay    ,
               BB.NDUnionDailyHalf   ,
               BB.NDUnionDailyMonth  ,
               BB.NDUnionSignalDay   ,
               BB.NDUnionSignalHalf  ,
               BB.NDUnionSignalMonth ,
               BB.NDUnionEtcDay      ,
               BB.NDUnionEtcHalf     ,
               BB.NDUnionEtcMonth    ,
               BB.DDailyDay          ,
               BB.DDailyHalf         ,
               BB.DDailyMonth        ,
               BB.NDDailyDay         ,
               BB.NDDailyHalf        ,
               BB.NDDailyMonth       ,
               BB.DOSDay             ,
               BB.DOSHalf            ,
               BB.DOSMonth           ,
               BB.NDOSDay            ,
               BB.NDOSHalf           ,
               BB.NDOSMonth          ,
               BB.DEtcDay            ,
               BB.DEtcHalf           ,
               BB.DEtcMonth          ,
               BB.NDEtcDay           ,
               BB.NDEtcHalf          ,
               BB.NDEtcMonth         ,
               BB.DRemark AS DRemark2, 
               0 AS WorkPlanSerl, 
               BB.WorkReportSerl AS WorkReportSerl, 
               A.TodayQty           , 
               A.TodayMTWeight      , 
               A.TodayCBMWeight     , 
               A.SumQty             , 
               A.SumMTWeight        , 
               A.SumCBMWeight       , 
               A.EtcQty             , 
               A.EtcMTWeight        , 
               A.EtcCBMWeight       , 
               ROW_NUMBER() OVER ( PARTITION BY A.WorkReportSeq ORDER BY A.WorkReportSeq ) AS Partition_IDX, 
               A.UMLoadTypeName, 
               KK.EmpName AS DDailyEmpName, 
               PP.EmpName AS NDDailyEmpName 
          FROM #PlanReportMaster AS A 
          LEFT OUTER JOIN mnpt_TPJTWorkReportItem       AS BB ON ( BB.CompanySeq = @CompanySeq AND BB.WorkReportSeq = A.WorkReportSeq ) 
          LEFT OUTER JOIN _TDAUMinor                    AS CC ON ( CC.CompanySeq = @CompanySeq AND CC.MinorSeq = BB.UMBisWorkType ) 
          LEFT OUTER JOIN mnpt_TPDEquipment             AS DD ON ( DD.CompanySeq = @CompanySeq AND DD.EquipmentSeq = BB.SelfToolSeq ) 
          LEFT OUTER JOIN mnpt_TPDEquipment             AS EE ON ( EE.CompanySeq = @CompanySeq AND EE.EquipmentSeq = BB.RentToolSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS FF ON ( FF.CompanySeq = @CompanySeq AND FF.EmpSeq = BB.DriverEmpSeq1 ) 
          LEFT OUTER JOIN _TDAEmp                       AS II ON ( II.CompanySeq = @CompanySeq AND II.EmpSeq = BB.DriverEmpSeq2 ) 
          LEFT OUTER JOIN _TDAEmp                       AS GG ON ( GG.CompanySeq = @CompanySeq AND GG.EmpSeq = BB.DriverEmpSeq3 ) 
          LEFT OUTER JOIN _TDAEmp                       AS HH ON ( HH.CompanySeq = @CompanySeq AND HH.EmpSeq = BB.NDEmpSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS KK ON ( KK.CompanySeq = @CompanySeq AND KK.EmpSeq = BB.DDailyEmpSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS PP ON ( PP.CompanySeq = @CompanySeq AND PP.EmpSeq = BB.NDDailyEmpSeq ) 
    END 
    
    -- 수량, 시간 등 중복으로 집계되지 않도록 0으로 update
    UPDATE A
       SET TodayQty = 0, 
           TodayMTWeight = 0, 
           TodayCBMWeight = 0, 
           RealWorkTime = 0 
      FROM #Result AS A 
     WHERE Partition_IDX <> 1 
    
    IF @IsUMBisWorkType = '0'
    BEGIN -- 업무구분/장비표시 X
        SELECT A.PJTName, 
               A.PJTNo, 
               A.PJTTypeName, 
               A.CustName, 
               A.ShipSerlNo,
               A.EnShipName, 
               MAX(A.InDateTime) AS InDateTime, 
               MAX(A.OutDateTime) AS OutDateTime, 
               LEFT(NULLIF(MAX(A.DiffApproachTime),0),charindex('.',MAX(A.DiffApproachTime))-1) AS DiffApproachTime, 
               LEFT(NULLIF(MAX(A.GoodsQty),0),charindex('.',MAX(A.GoodsQty))-1) AS GoodsQty,
               LEFT(NULLIF(MAX(A.GoodsMTWeight),0),charindex('.',MAX(A.GoodsMTWeight))+3) AS GoodsMTWeight, 
               LEFT(NULLIF(MAX(A.GoodsCBMWeight),0),charindex('.',MAX(A.GoodsCBMWeight))+3) AS GoodsCBMWeight, 
               MIN(A.IsShipCfm) AS IsShipCfm, 
               MAX(A.WorkPlanReport) AS WorkPlanReport, 
               CASE WHEN @IsWorkDate = '1' THEN A.WorkDate ELSE '' END AS WorkDate, 
               CASE WHEN @IsWorkDate = '1' THEN A.WorkDay ELSE '' END AS WorkDay, 
               CASE WHEN ISNULL(MAX(A.UMHoliDayTypeName),'') = '' THEN '　' ELSE MAX(A.UMHoliDayTypeName) END AS UMHoliDayTypeName, 

               CASE WHEN ISNULL(MAX(A.UMWeatherName),'') = '' THEN '　' ELSE MAX(A.UMWeatherName) END AS UMWeatherName, 
               CASE WHEN @IsUMWorkTeam = '1' THEN A.UMWorkTeamName ELSE '' END AS UMWorkTeamName, 
               CASE WHEN @IsUMWorkType = '1' THEN A.UMWorkTypeName ELSE '' END AS UMWorkTypeName, 
               CASE WHEN @IsUMWorkType = '1' THEN A.UMLoadTypeName ELSE '' END AS UMLoadTypeName, 
               
               CASE WHEN @IsUMWorkType = '1' THEN MAX(A.IsInvoice) ELSE '0' END AS IsInvoice, 
               CASE WHEN @IsUMWorkType = '1' THEN MAX(A.IsShip) ELSE '0' END AS IsShip, 
               CASE WHEN @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.MultiExtraName,'') = '' THEN '　' ELSE A.MultiExtraName END) ELSE '　' END AS MultiExtraName, 

               LEFT(NULLIF(SUM(A.TodayQty),0),charindex('.',SUM(A.TodayQty))-1) AS TodayQty, 
               LEFT(NULLIF(SUM(A.TodayMTWeight),0),charindex('.',SUM(A.TodayMTWeight))+3) AS TodayMTWeight, 
               LEFT(NULLIF(SUM(A.TodayCBMWeight),0),charindex('.',SUM(A.TodayCBMWeight))+3) AS TodayCBMWeight, 

               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.WorkSrtTime,'') = '' THEN '　' ELSE A.WorkSrtTime END) ELSE '　' END AS WorkSrtTime, 
               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.WorkEndTime,'') = '' THEN '　' ELSE A.WorkEndTime END) ELSE '　' END AS WorkEndTime, 

               LEFT(NULLIF(ROUND(SUM(A.RealWorkTime),1),0),charindex('.',SUM(A.RealWorkTime))+1) AS RealWorkTime, 
               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.EmpName,'') = '' THEN '　' ELSE A.EmpName END) ELSE '　' END AS EmpName, 
               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.DRemark,'') = '' THEN '　' ELSE A.DRemark END) ELSE '　' END AS DRemark, 


               MIN(A.IsCfm) AS IsCfm, 
               MIN(A.IsCreateInvoice) AS IsCreateInvoice,
               MIN(A.IsUnionAmt) AS IsUnionAmt, 
               MIN(A.IsDailyAmt) AS IsDailyAmt, 
               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN A.WorkPlanSeq ELSE '' END AS WorkPlanSeq, 
               CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN A.WorkReportSeq ELSE '' END AS WorkReportSeq, 
               LEFT(NULLIF(SUM(A.NDUnionUnloadGang  ),0),charindex('.',SUM(A.NDUnionUnloadGang )) + 1) AS NDUnionUnloadGang  ,
               LEFT(NULLIF(SUM(A.NDUnionUnloadMan   ),0),charindex('.',SUM(A.NDUnionUnloadMan  )) - 1) AS NDUnionUnloadMan   ,
               LEFT(NULLIF(SUM(A.DUnionDay          ),0),charindex('.',SUM(A.DUnionDay         )) + 2) AS DUnionDay          ,
               LEFT(NULLIF(SUM(A.DUnionHalf         ),0),charindex('.',SUM(A.DUnionHalf        )) + 2) AS DUnionHalf         ,
               LEFT(NULLIF(SUM(A.DUnionMonth        ),0),charindex('.',SUM(A.DUnionMonth       )) + 2) AS DUnionMonth        ,
               LEFT(NULLIF(SUM(A.NDUnionDailyDay    ),0),charindex('.',SUM(A.NDUnionDailyDay   )) + 2) AS NDUnionDailyDay    ,
               LEFT(NULLIF(SUM(A.NDUnionDailyHalf   ),0),charindex('.',SUM(A.NDUnionDailyHalf  )) + 2) AS NDUnionDailyHalf   ,
               LEFT(NULLIF(SUM(A.NDUnionDailyMonth  ),0),charindex('.',SUM(A.NDUnionDailyMonth )) + 2) AS NDUnionDailyMonth  ,
               LEFT(NULLIF(SUM(A.NDUnionSignalDay   ),0),charindex('.',SUM(A.NDUnionSignalDay  )) + 2) AS NDUnionSignalDay   ,
               LEFT(NULLIF(SUM(A.NDUnionSignalHalf  ),0),charindex('.',SUM(A.NDUnionSignalHalf )) + 2) AS NDUnionSignalHalf  ,
               LEFT(NULLIF(SUM(A.NDUnionSignalMonth ),0),charindex('.',SUM(A.NDUnionSignalMonth)) + 2) AS NDUnionSignalMonth ,
               LEFT(NULLIF(SUM(A.NDUnionEtcDay      ),0),charindex('.',SUM(A.NDUnionEtcDay     )) + 2) AS NDUnionEtcDay      ,
               LEFT(NULLIF(SUM(A.NDUnionEtcHalf     ),0),charindex('.',SUM(A.NDUnionEtcHalf    )) + 2) AS NDUnionEtcHalf     ,
               LEFT(NULLIF(SUM(A.NDUnionEtcMonth    ),0),charindex('.',SUM(A.NDUnionEtcMonth   )) + 2) AS NDUnionEtcMonth    ,
               LEFT(NULLIF(SUM(A.DDailyDay          ),0),charindex('.',SUM(A.DDailyDay         )) + 2) AS DDailyDay          ,
               LEFT(NULLIF(SUM(A.DDailyHalf         ),0),charindex('.',SUM(A.DDailyHalf        )) + 2) AS DDailyHalf         ,
               LEFT(NULLIF(SUM(A.DDailyMonth        ),0),charindex('.',SUM(A.DDailyMonth       )) + 2) AS DDailyMonth        ,
               LEFT(NULLIF(SUM(A.NDDailyDay         ),0),charindex('.',SUM(A.NDDailyDay        )) + 2) AS NDDailyDay         ,
               LEFT(NULLIF(SUM(A.NDDailyHalf        ),0),charindex('.',SUM(A.NDDailyHalf       )) + 2) AS NDDailyHalf        ,
               LEFT(NULLIF(SUM(A.NDDailyMonth       ),0),charindex('.',SUM(A.NDDailyMonth      )) + 2) AS NDDailyMonth       ,
               LEFT(NULLIF(SUM(A.DOSDay             ),0),charindex('.',SUM(A.DOSDay            )) + 2) AS DOSDay             ,
               LEFT(NULLIF(SUM(A.DOSHalf            ),0),charindex('.',SUM(A.DOSHalf           )) + 2) AS DOSHalf            ,
               LEFT(NULLIF(SUM(A.DOSMonth           ),0),charindex('.',SUM(A.DOSMonth          )) + 2) AS DOSMonth           ,
               LEFT(NULLIF(SUM(A.NDOSDay            ),0),charindex('.',SUM(A.NDOSDay           )) + 2) AS NDOSDay            ,
               LEFT(NULLIF(SUM(A.NDOSHalf           ),0),charindex('.',SUM(A.NDOSHalf          )) + 2) AS NDOSHalf           ,
               LEFT(NULLIF(SUM(A.NDOSMonth          ),0),charindex('.',SUM(A.NDOSMonth         )) + 2) AS NDOSMonth          ,
               LEFT(NULLIF(SUM(A.DEtcDay            ),0),charindex('.',SUM(A.DEtcDay           )) + 2) AS DEtcDay            ,
               LEFT(NULLIF(SUM(A.DEtcHalf           ),0),charindex('.',SUM(A.DEtcHalf          )) + 2) AS DEtcHalf           ,
               LEFT(NULLIF(SUM(A.DEtcMonth          ),0),charindex('.',SUM(A.DEtcMonth         )) + 2) AS DEtcMonth          ,
               LEFT(NULLIF(SUM(A.NDEtcDay           ),0),charindex('.',SUM(A.NDEtcDay          )) + 2) AS NDEtcDay           ,
               LEFT(NULLIF(SUM(A.NDEtcHalf          ),0),charindex('.',SUM(A.NDEtcHalf         )) + 2) AS NDEtcHalf          ,
               LEFT(NULLIF(SUM(A.NDEtcMonth         ),0),charindex('.',SUM(A.NDEtcMonth        )) + 2) AS NDEtcMonth         , 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumQty) ELSE NULL END,0)
                    ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumQty) ELSE NULL END) - 1 
                   ) AS SumQty, 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumMTWeight) ELSE NULL END,0) 
                   ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumMTWeight) ELSE NULL END) + 3
                   ) AS SumMTWeight, 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumCBMWeight) ELSE NULL END,0) 
                   ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.SumCBMWeight) ELSE NULL END) + 3
                   ) AS SumCBMWeight, 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcQty) ELSE NULL END,0) 
                   ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcQty) ELSE NULL END) - 1 
                   ) AS EtcQty, 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcMTWeight) ELSE NULL END,0) 
                   ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcMTWeight) ELSE NULL END) + 3
                   ) AS EtcMTWeight, 
               LEFT(NULLIF(CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcCBMWeight) ELSE NULL END,0) 
                   ,charindex('.',CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN MAX(A.EtcCBMWeight) ELSE NULL END) + 3
                   ) AS EtcCBMWeight 
          FROM #Result AS A 
         GROUP BY A.PJTName, 
                  A.PJTNo, 
                  A.PJTTypeName, 
                  A.CustName, 
                  A.ShipSerlNo,
                  A.EnShipName, 
                  CASE WHEN @IsWorkDate = '1' THEN A.WorkDate ELSE '' END, 
                  CASE WHEN @IsWorkDate = '1' THEN A.WorkDay ELSE '' END, 
                  CASE WHEN @IsUMWorkTeam = '1' THEN A.UMWorkTeamName ELSE '' END, 
                  CASE WHEN @IsUMWorkType = '1' THEN A.UMWorkTypeName ELSE '' END, 
                  CASE WHEN @IsUMWorkType = '1' THEN A.UMLoadTypeName ELSE '' END, 
                  CASE WHEN @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.MultiExtraName,'') = '' THEN '　' ELSE A.MultiExtraName END) ELSE '　' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.WorkSrtTime,'') = '' THEN '　' ELSE A.WorkSrtTime END) ELSE '　' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.WorkEndTime,'') = '' THEN '　' ELSE A.WorkEndTime END) ELSE '　' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.EmpName,'') = '' THEN '　' ELSE A.EmpName END) ELSE '　' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN (CASE WHEN ISNULL(A.DRemark,'') = '' THEN '　' ELSE A.DRemark END) ELSE '　' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN A.WorkPlanSeq ELSE '' END, 
                  CASE WHEN @IsWorkDate = '1' AND @IsUMWorkType = '1' AND @IsUMWorkTeam = '1' AND @IsUMExtraSeq = '1' THEN A.WorkReportSeq ELSE '' END
         ORDER BY PJTName, ShipSerlNo, WorkDate, WorkSrtTime, UMWorkTypeName
    
    END 
    ELSE 
    BEGIN -- 업무구분/장비표시
        SELECT A.PJTName            , A.PJTNo              , A.PJTTypeName        , A.CustName           , A.ShipSerlNo         , 

               A.EnShipName         , A.InDateTime         , A.OutDateTime        , 
               LEFT(NULLIF(A.DiffApproachTime,0),charindex('.',A.DiffApproachTime)-1) AS DiffApproachTime,
               LEFT(NULLIF(A.GoodsQty,0),charindex('.',A.GoodsQty) -1) AS GoodsQty, 

               LEFT(NULLIF(A.GoodsMTWeight,0),charindex('.',A.GoodsMTWeight)-1) AS GoodsMTWeight, 
               LEFT(NULLIF(A.GoodsCBMWeight,0),charindex('.',A.GoodsCBMWeight)-1) AS GoodsCBMWeight, 
               A.IsShipCfm          , A.WorkPlanReport     , A.WorkDate           , 

               A.WorkDay            , 
               CASE WHEN ISNULL(A.UMHoliDayTypeName,'') = '' THEN '　' ELSE A.UMHoliDayTypeName END AS UMHoliDayTypeName, 
               CASE WHEN ISNULL(A.UMWeatherName,'') = '' THEN '　' ELSE A.UMWeatherName END AS UMWeatherName, 
               A.UMWorkTeamName     , A.UMWorkTypeName     , 

               A.IsInvoice          , A.IsShip             , 
               CASE WHEN ISNULL(A.MultiExtraName,'') = '' THEN '　' ELSE A.MultiExtraName END AS MultiExtraName, 
               CASE WHEN ISNULL(A.WorkSrtTime,'') = '' THEN '　' ELSE A.WorkSrtTime END AS WorkSrtTime, 
               CASE WHEN ISNULL(A.WorkEndTime,'') = '' THEN '　' ELSE A.WorkEndTime END AS WorkEndTime, 

               LEFT(NULLIF(ROUND(A.RealWorkTime,1),0),charindex('.',A.RealWorkTime)+1)  AS RealWorkTime, 
               CASE WHEN ISNULL(A.EmpName,'') = '' THEN '　' ELSE A.EmpName END AS EmpName, 
               CASE WHEN ISNULL(A.DRemark,'') = '' THEN '　' ELSE A.DRemark END AS DRemark, 
               A.IsCfm              , A.IsCreateInvoice    , 

               A.IsUnionAmt         , A.IsDailyAmt         , A.WorkPlanSeq        , A.WorkReportSeq      , A.UMBisWorkTypeName  , 
               A.SelfToolName       , A.RentToolName       , A.ToolWorkTime       , A.DriverEmpName1     , A.DriverEmpName2     , 
               
               A.DriverEmpName3     , A.NDEmpName          , 
               LEFT(NULLIF(A.NDUnionUnloadGang  ,0),charindex('.',A.NDUnionUnloadGang) + 1) AS NDUnionUnloadGang, 
               LEFT(NULLIF(A.NDUnionUnloadMan   ,0),charindex('.',A.NDUnionUnloadMan) - 1 ) AS NDUnionUnloadMan , 
               LEFT(NULLIF(A.DUnionDay          ,0),charindex('.',A.DUnionDay) + 2) AS DUnionDay        , 

               LEFT(NULLIF(A.DUnionHalf       ,0),charindex('.',A.DUnionHalf) + 2) AS DUnionHalf         , 
               LEFT(NULLIF(A.DUnionMonth      ,0),charindex('.',A.DUnionMonth) + 2) AS DUnionMonth       , 
               LEFT(NULLIF(A.NDUnionDailyDay  ,0),charindex('.',A.NDUnionDailyDay) + 2) AS NDUnionDailyDay   , 
               LEFT(NULLIF(A.NDUnionDailyHalf ,0),charindex('.',A.NDUnionDailyHalf) + 2) AS NDUnionDailyHalf  , 
               LEFT(NULLIF(A.NDUnionDailyMonth,0),charindex('.',A.NDUnionDailyMonth) + 2) AS NDUnionDailyMonth , 

               LEFT(NULLIF(A.NDUnionSignalDay  ,0),charindex('.',A.NDUnionSignalDay) + 2) AS NDUnionSignalDay   , 
               LEFT(NULLIF(A.NDUnionSignalHalf ,0),charindex('.',A.NDUnionSignalHalf) + 2) AS NDUnionSignalHalf  , 
               LEFT(NULLIF(A.NDUnionSignalMonth,0),charindex('.',A.NDUnionSignalMonth) + 2) AS NDUnionSignalMonth , 
               LEFT(NULLIF(A.NDUnionEtcDay     ,0),charindex('.',A.NDUnionEtcDay) + 2) AS NDUnionEtcDay      , 
               LEFT(NULLIF(A.NDUnionEtcHalf    ,0),charindex('.',A.NDUnionEtcHalf) + 2) AS NDUnionEtcHalf     , 

               LEFT(NULLIF(A.NDUnionEtcMonth  ,0),charindex('.',A.NDUnionEtcMonth) + 2) AS NDUnionEtcMonth    ,
               LEFT(NULLIF(A.DDailyDay        ,0),charindex('.',A.DDailyDay) + 2) AS DDailyDay         , 
               LEFT(NULLIF(A.DDailyHalf       ,0),charindex('.',A.DDailyHalf) + 2) AS DDailyHalf    , 
               LEFT(NULLIF(A.DDailyMonth      ,0),charindex('.',A.DDailyMonth) + 2) AS DDailyMonth   , 
               LEFT(NULLIF(A.NDDailyDay       ,0),charindex('.',A.NDDailyDay) + 2) AS NDDailyDay    , 

               LEFT(NULLIF(A.NDDailyHalf      ,0),charindex('.',A.NDDailyHalf) + 2) AS NDDailyHalf        , 
               LEFT(NULLIF(A.NDDailyMonth     ,0),charindex('.',A.NDDailyMonth) + 2) AS NDDailyMonth      , 
               LEFT(NULLIF(A.DOSDay           ,0),charindex('.',A.DOSDay) + 2) AS DOSDay    , 
               LEFT(NULLIF(A.DOSHalf          ,0),charindex('.',A.DOSHalf) + 2) AS DOSHalf   , 
               LEFT(NULLIF(A.DOSMonth         ,0),charindex('.',A.DOSMonth) + 2) AS DOSMonth  , 

               LEFT(NULLIF(A.NDOSDay          ,0),charindex('.',A.NDOSDay) + 2) AS NDOSDay            , 
               LEFT(NULLIF(A.NDOSHalf         ,0),charindex('.',A.NDOSHalf) + 2) AS NDOSHalf          , 
               LEFT(NULLIF(A.NDOSMonth        ,0),charindex('.',A.NDOSMonth) + 2) AS NDOSMonth, 
               LEFT(NULLIF(A.DEtcDay          ,0),charindex('.',A.DEtcDay) + 2) AS DEtcDay  , 
               LEFT(NULLIF(A.DEtcHalf         ,0),charindex('.',A.DEtcHalf) + 2) AS DEtcHalf , 

               LEFT(NULLIF(A.DEtcMonth        ,0),charindex('.',A.DEtcMonth) + 2) AS DEtcMonth          , 
               LEFT(NULLIF(A.NDEtcDay         ,0),charindex('.',A.NDEtcDay) + 2) AS NDEtcDay          , 
               LEFT(NULLIF(A.NDEtcHalf        ,0),charindex('.',A.NDEtcHalf) + 2) AS NDEtcHalf    , 
               LEFT(NULLIF(A.NDEtcMonth       ,0),charindex('.',A.NDEtcMonth) + 2) AS NDEtcMonth   , 
               A.DRemark2                                   , 

               A.WorkPlanSerl       , 
               A.WorkReportSerl     , 
               LEFT(NULLIF(A.TodayQty        ,0),charindex('.',A.TodayQty) -1 ) AS TodayQty        , 
               LEFT(NULLIF(A.TodayMTWeight   ,0),charindex('.',A.TodayMTWeight) + 3) AS TodayMTWeight   , 
               LEFT(NULLIF(A.TodayCBMWeight  ,0),charindex('.',A.TodayCBMWeight) + 3) AS TodayCBMWeight  ,

               LEFT(NULLIF(A.SumQty          ,0),charindex('.',A.SumQty) -1 ) AS SumQty         , 
               LEFT(NULLIF(A.SumMTWeight     ,0),charindex('.',A.SumMTWeight) + 3) AS SumMTWeight    , 
               LEFT(NULLIF(A.SumCBMWeight    ,0),charindex('.',A.SumCBMWeight) + 3) AS SumCBMWeight   , 
               LEFT(NULLIF(A.EtcQty          ,0),charindex('.',A.EtcQty) - 1) AS EtcQty         , 
               LEFT(NULLIF(A.EtcMTWeight     ,0),charindex('.',A.EtcMTWeight) + 3) AS EtcMTWeight    , 

               LEFT(NULLIF(A.EtcCBMWeight,0),charindex('.',A.EtcCBMWeight) + 3) AS EtcCBMWeight       , 
               A.UMLoadTypeName     , 
               A.DDailyEmpName      , 
               A.NDDailyEmpName

          FROM #Result AS A 
         ORDER BY PJTName, ShipSerlNo, WorkDate, WorkSrtTime, UMWorkTypeName, UMBisWorkTypeName



    END 

    RETURN     
GO