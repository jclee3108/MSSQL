IF OBJECT_ID('KPXCM_SPUDelvIF_MES2') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvIF_MES2
GO 


-- v2016.10.26 
  
-- 수입입고 생성(MES 천안공장) by이재천  
CREATE PROC KPXCM_SPUDelvIF_MES2
    @CompanySeq INT 
AS      
    
    CREATE TABLE #ImpDelvAll -- 수입입고 마스터 모든 데이터 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        DelvSeq     INT, 
        DelvNo      NVARCHAR(100), 
        DelvDate    NCHAR(8), 
        CustSeq     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        Remark      NVARCHAR(500), 
        SMImpType   INT, 
        CurrSeq     INT, 
        ExRate      DECIMAL(10,5), 
        BizUnit     INT, 
        POSeq       INT 
    ) 
    
    CREATE TABLE #ImpDelv -- 수입입고 마스터 하나의 데이터 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        DelvSeq     INT, 
        DelvNo      NVARCHAR(100), 
        DelvDate    NCHAR(8), 
        CustSeq     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        Remark      NVARCHAR(500), 
        SMImpType   INT, 
        CurrSeq     INT, 
        ExRate      DECIMAL(10,5), 
        BizUnit     INT, 
        POSeq       INT 
    ) 
    
    CREATE TABLE #ImpDelvItem -- 수입입고 디테일 데이터 
    (
        IDX_NO      INT IDENTITY, 
        DelvSeq     INT, 
        DelvSerl    INT, 
        ItemSeq     INT,  
        UnitSeq     INT, 
        Price       DECIMAL(19,5), 
        Qty         DECIMAL(19,5), 
        CurAmt      DECIMAL(19,5), 
        DomAmt      DECIMAL(19,5), 
        StdUnitSeq  INT, 
        StdUnitQty  DECIMAL(19,5), 
        WHSeq       INT, 
        LOTNo       NVARCHAR(100), 
        DomPrice    DECIMAL(19,5), 
        CurVAT      DECIMAL(19,5), 
        DomVAT      DECIMAL(19,5), 
        IsVAT       NCHAR(1), 
        Remark      NVARCHAR(500), 
        ValiDate    NCHAR(8), 
        POSeq       INT, 
        POSerl      INT, 
        Seq         NVARCHAR(20), 
        PermitSeq   INT, 
        PermitSerl  INT
    ) 
    
    CREATE TABLE #LotMaster -- Lot마스터 
    (
        IDX_NO      INT IDENTITY, 
        LotNo       NVARCHAR(100), 
        ItemSeq     INT, 
        UnitSeq     INT, 
        Qty         DECIMAL(19,5), 
        RegDate     NCHAR(8), 
        CustSeq     INT, 
        Remark      NVARCHAR(500), 
        InNo        NVARCHAR(200), 
        WorkingTag  NCHAR(1), 
        ValiDate    NCHAR(8) 
    ) 
    
    CREATE TABLE #SourceDaily -- 수입필증 -> 수입입고 진행 
    (
        IDX_NO          INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        FromTableSeq    INT, 
        FromSeq         INT, 
        FromSerl        INT, 
        FromQty         DECIMAL(19,5), 
        FromSTDQty      DECIMAL(19,5), 
        FromAmt         DECIMAL(19,5), 
        FromVAT         DECIMAL(19,5), 
        ToTableSeq      INT, 
        ToSeq           INT, 
        ToSerl          INT, 
        ToQty           DECIMAL(19,5), 
        ToSTDQty        DECIMAL(19,5), 
        ToAmt           DECIMAL(19,5), 
        ToVAT           DECIMAL(19,5)
    )
    
    CREATE TABLE #InOutDaily -- 수불 입고 
    (
        IDX_NO      INT IDENTITY, 
        WorkingTag  NCHAR(1), 
        InOutSeq    INT, 
        InOutType   INT 
    ) 
    
    DECLARE @BizUnit    INT, 
            @Status     INT 
    
    SELECT @BizUnit = 26 
    
    INSERT INTO #ImpDelvAll -- 수입입고 데이터 (전체)
    (
        WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
        DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
        ExRate     , BizUnit    , POSeq      
    ) 
    SELECT A.WorkingTag, 0, 0, MAX(A.DelvDate), MAX(B.CustSeq), 
           MAX(B.DeptSeq), MAX(B.EmpSeq), 'MES연동실적건', MAX(B.SMImpType), MAX(B.CurrSeq), 
           MAX(B.ExRate), @BizUnit, A.POSeq -- 천안공장 
      FROM IF_PUInQCResult_MES AS A 
      JOIN _TPUORDPO AS B ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ImpType = 1 -- 수입 
       AND ISNULL(A.ProcYn,'0') = '0' 
       
       AND A.WorkingTag = 'A' -- 추후에 삭제 예정 
     GROUP BY A.POSeq, A.WorkingTag 
    

     --order by A.POSeq desc      
    
    
    -- 처리할 데이터 없으면 return 
    IF NOT EXISTS (SELECT 1 FROM #ImpDelvAll)
    BEGIN 
        
        SELECT * FROM #ImpDelvAll
        RETURN 
    END 
    
    
    
    
    DECLARE @MainCnt INT -- 한건씩 처리하기위한 변수 
    SELECT @MainCnt = 1 
    
    
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        
        TRUNCATE TABLE #ImpDelv 
        INSERT INTO #ImpDelv -- 수입입고 데이터 
        (
            WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
            DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
            ExRate     , BizUnit    , POSeq
        ) 
        SELECT TOP 1 
               WorkingTag , DelvSeq    , DelvNo     , DelvDate   , CustSeq    , 
               DeptSeq    , EmpSeq     , Remark     , SMImpType  , CurrSeq    , 
               ExRate     , BizUnit    , POSeq 
          FROM #ImpDelvAll 
         WHERE IDX_NO = @MainCnt 
        

    
        
        IF EXISTS (SELECT 1 FROM #ImpDelv WHERE WorkingTag = 'A') 
        BEGIN 
        
            DECLARE @Count      INT, -- 채번 변수 
                    @DelvSeq    INT, 
                    @Cnt        INT, -- WHILE 변수 
                    @BaseDate   NCHAR(8), -- 번호 채번하기위한 날짜 
                    @DelvNo     NVARCHAR(100) -- 채번 번호 
            
            SELECT @Count = COUNT(1) FROM #ImpDelv 
            
            -- DelvSeq 채번 
            EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TUIImpDelv', 'DelvSeq', 1 
            
            
            SELECT @BaseDate = DelvDate 
              FROM #ImpDelv 
             WHERE WorkingTag = 'A' 
            
            EXEC _SCOMCreateNo 'PU', '_TUIImpDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT  
            
            UPDATE A 
               SET DelvSeq = @DelvSeq + A.IDX_NO, 
                   DelvNo = @DelvNo 
              FROM #ImpDelv AS A 
             WHERE A.WorkingTag = 'A' 
        
            
        END 
        
        
        
        TRUNCATE TABLE #ImpDelvItem
        INSERT INTO #ImpDelvItem -- 수입입고 디테일 데이터 
        (
            DelvSeq       , DelvSerl      , ItemSeq       , UnitSeq       , Price         , 
            Qty           , CurAmt        , DomAmt        , StdUnitSeq    , StdUnitQty    , 
            WHSeq         , LOTNo         , DomPrice      , CurVAT        , DomVAT        , 
            IsVAT         , Remark        , ValiDate      , POSeq         , POSerl        , 
            Seq 
        ) 

        SELECT A.DelvSeq, ROW_NUMBER() OVER(ORDER BY A.DelvSeq), C.ItemSeq, C.UnitSeq, C.Price, 
               B.Qty, C.Price * B.Qty, 0, C.StdUnitSeq, B.Qty, 
               ISNULL(F.WHSeq,179), B.LotNo, 0, ISNULL((C.Price * B.Qty) / CONVERT(INT,REPLACE(E.MinorName,'%','')),0), 0, 
               '0', 'MES연동실적건', B.ValiDate, C.POSeq, C.POSerl, 
               B.Seq
          FROM #ImpDelv                 AS A 
          JOIN IF_PUInQCResult_MES      AS B ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq AND ISNULL(B.ProcYn,'0') ='0' AND B.ImpType = 1 AND A.WorkingTag = B.WorkingTag ) 
          JOIN _TPUORDPOItem            AS C ON ( C.CompanySeq = @CompanySeq AND C.POSeq = B.POSeq AND C.POSerl = B.POSerl ) 
          LEFT OUTER JOIN _TDAItemSales AS D ON ( D.CompanySeq = @COmpanySeq AND D.ItemSeq = C.ItemSeq )   
          LEFT OUTER JOIN _TDASMinor    AS E ON ( E.CompanySeq = @COmpanySeq AND E.MinorSeq = D.SMVatType )   
          LEFT OUTER JOIN (SELECT Z.ItemSeq, MAX(Z.WHSeq) AS WHSeq 
                             FROM _TDAWHItem AS Z 
                            WHERE Z.CompanySeq = @CompanySeq 
                            GROUP BY Z.ItemSeq 
                          ) AS F ON ( F.ItemSeq = C.ItemSeq ) 
         WHERE B.WorkingTag = 'A' -- 추후에 삭제예정 
        ----------------------------------------------------        
        -- 수정/삭제시 DelvSeq, DelvSerl 업데이트 
        ----------------------------------------------------
        
        -- 수입필증 -> 수입입고 찾기 
        CREATE TABLE #ProgData 
        (
            IDX_NO      INT IDENTITY, 
            POSeq       INT, 
            POSerl      INT, 
            DelvSeq     INT, 
            DelvSerl    INT, 
            PermitSeq   INT, 
            PermitSerl  INT 
        ) 
        INSERT INTO #ProgData ( POSeq, POSerl, DelvSeq, DelvSerl, PermitSeq, PermitSerl ) 
         SELECT DISTINCT A.POSeq, A.POSerl, 0, 0, 0, 0 
          FROM #ImpDelvItem AS A 
          JOIN #ImpDelv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
         --WHERE B.WorkingTag IN ( 'U', 'D' ) 
        
        
        CREATE TABLE #TMP_ProgressTable 
        (
            IDOrder   INT, 
            TableName NVARCHAR(100)
        ) 
        
        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
        SELECT 1, '_TUIImpPermitItem' -- 수입필증 
        UNION ALL 
        SELECT 2, '_TUIImpDelvItem'   -- 수입입고 
        
        
        CREATE TABLE #TCOMProgressTracking
        (
            IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)
        ) 
        EXEC _SCOMProgressTracking 
                @CompanySeq = @CompanySeq, 
                @TableName = '_TPUORDPOItem',    -- 기준이 되는 테이블
                @TempTableName = '#ProgData',  -- 기준이 되는 템프테이블
                @TempSeqColumnName = 'POSeq',  -- 템프테이블의 Seq
                @TempSerlColumnName = 'POSerl',  -- 템프테이블의 Serl
                @TempSubSerlColumnName = ''  
        
        
        UPDATE A 
           SET DelvSeq = ISNULL(B.Seq,0), 
               DelvSerl = ISNULL(B.Serl,0), 
               PermitSeq = ISNULL(C.Seq,0), 
               PermitSerl = ISNULL(C.Serl,0) 
          FROM #ProgData AS A 
          LEFT OUTER JOIN #TCOMProgressTracking  AS B ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 2 ) 
          LEFT OUTER JOIN #TCOMProgressTracking  AS C ON ( C.IDX_NO = A.IDX_NO AND C.IDOrder = 1 ) 
        
        
        UPDATE A 
           SET DelvSeq = CASE WHEN B.WorkingTag IN ( 'U', 'D' ) THEN C.DelvSeq ELSE A.DelvSeq END, 
               DelvSerl = CASE WHEN B.WorkingTag IN ( 'U', 'D' ) THEN C.DelvSerl ELSE A.DelvSerl END, 
               PermitSeq = C.PermitSeq, 
               PermitSerl = C.PermitSerl 
          FROM #ImpDelvItem AS A 
          JOIN #ImpDelv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
          JOIN #ProgData AS C ON ( C.POSeq = A.POSeq AND C.POSerl = A.POSerl ) 
        
        UPDATE A 
           SET DelvSeq = B.DelvSeq
          FROM #ImpDelv     AS A 
          JOIN #ProgData AS B ON ( B.POSeq = A.POSeq ) 
         WHERE A.WorkingTag IN ( 'U', 'D' )  
        
        DROP TABLE #TCOMProgressTracking
        DROP TABLE #TMP_ProgressTable 
        ----------------------------------------------------        
        -- 수정/삭제시 DelvSeq, DelvSerl 업데이트, END  
        ----------------------------------------------------
        
        ----------------------------------------------------
        -- 신고필증 환률로 계산하기 
        ----------------------------------------------------
        UPDATE A 
           SET DomAmt = A.CurAmt * C.ExRate, 
               DomVAT = A.CurVAT * C.ExRate, 
               DomPrice = A.Price * C.ExRate 
          FROM #ImpDelvItem             AS A 
          JOIN _TUIImpPermitItem        AS B ON ( B.CompanySeq = @CompanySeq AND B.PermitSeq = A.PermitSeq AND B.PermitSerl = A.PermitSerl ) 
          JOIN _TUIImpPermit            AS C ON ( C.CompanySeq = @CompanySeq AND C.PermitSeq = B.PermitSeq ) 
        ----------------------------------------------------
        -- 신고필증 환률로 계산하기, END 
        ----------------------------------------------------
        
        ------------------------------------------------------------------------------
        -- 수입필증이 없는 데이터는 Skip
        ------------------------------------------------------------------------------
        DELETE B 
          FROM #ImpDelvItem AS A 
          JOIN #ImpDelv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
         WHERE A.PermitSeq = 0 
         
        DELETE A
          FROM #ImpDelvItem AS A 
         WHERE A.PermitSeq = 0 
        ------------------------------------------------------------------------------
        -- 수입필증이 없는 데이터는 Skip, END 
        ------------------------------------------------------------------------------        
        
        
        TRUNCATE TABLE #LotMaster 
        INSERT INTO #LotMaster 
        (
            LotNo    , ItemSeq  , UnitSeq  , Qty        , RegDate  , 
            CustSeq  , Remark   , InNo     , WorkingTag , ValiDate 
        ) 
        SELECT A.LOTNo, A.ItemSeq, A.UnitSeq, A.Qty, B.DelvDate, 
               B.CustSeq, B.Remark, B.DelvNo, B.WorkingTag, A.ValiDate 
          FROM #ImpDelvItem AS A 
          JOIN #ImpDelv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
         WHERE NOT EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq AND LotNo = A.LOTNo) 
        
        
        --FromTableseq = 48 -- 수입신고필증 
        --ToTableSeq = 49 -- 수입입고 
        
        TRUNCATE TABLE #SourceDaily 
        INSERT INTO #SourceDaily 
        (
            WorkingTag    , FromTableSeq      , FromSeq           , FromSerl          , FromQty           , 
            FromSTDQty    , FromAmt           , FromVAT           , ToTableSeq        , ToSeq             , 
            ToSerl        , ToQty             , ToSTDQty          , ToAmt             , ToVAT                 
        )
        SELECT B.WorkingTag, 48, C.PermitSeq, C.PermitSerl, C.Qty, 
               C.STDQty, C.DomAmt, 0, 49, A.DelvSeq, 
               A.DelvSerl, A.Qty, A.Qty, A.CurAmt, A.CurVAT 
          FROM #ImpDelvItem         AS A 
          JOIN #ImpDelv             AS B ON ( B.DelvSeq = A.DelvSeq ) 
          JOIN _TUIImpPermitItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.PermitSeq = A.PermitSeq AND C.PermitSerl = A.PermitSerl ) 
        
        
                
        TRUNCATE TABLE #InOutDaily
        INSERT INTO #InOutDaily 
        (
            WorkingTag, InOutSeq, InOutType 
        )
        SELECT DISTINCT B.WorkingTag, A.DelvSeq, 240 
          FROM #ImpDelvItem     AS A 
          JOIN #ImpDelv         AS B ON ( B.DelvSeq = A.DelvSeq ) 
        

        -- 테이블에 반영 
        DECLARE @XmlData NVARCHAR(MAX) 
        
        BEGIN TRAN 
        -- ImpDelv 생성 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.DelvSeq,         
                                                          A.DelvNo, 
                                                          A.DelvDate, 
                                                          A.CustSeq, 
                                                          A.DeptSeq, 
                                                          A.EmpSeq, 
                                                          A.Remark, 
                                                          A.SMImpType, 
                                                          A.CurrSeq, 
                                                          A.ExRate, 
                                                          A.BizUnit, 
                                                          '0' AS IsPJT, 
                                                          A.SMImpType AS SMImpKind 
                                                      FROM #ImpDelv AS A         
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
            
            EXEC @Status = 
                 KPXCM_SSLImpDelvMasterSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 4493,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134    
        
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '수입입고 마스터데이터 오류' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #ImpDelvItem         AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
    
        -- ImpDelvItem 생성 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT B.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.DelvSeq,         
                                                          A.DelvSerl, 
                                                          A.Price, 
                                                          A.Qty, 
                                                          A.CurAmt, 
                                                          A.DomPrice, 
                                                          A.DomAmt, 
                                                          A.WHSeq, 
                                                          0 AS DelvCustSeq, 
                                                          0 AS SalesCustSeq, 
                                                          A.StdUnitSeq AS STDUnitSeq, 
                                                          A.StdUnitQty AS STDQty, 
                                                          A.ItemSeq, 
                                                          A.UnitSeq, 
                                                          A.LOTNo AS LotNo, 
                                                          A.Remark, 
                                                          A.CurVAT, 
                                                          A.DomVAT, 
                                                          A.IsVAT
                                                      FROM #ImpDelvItem AS A  
                                                      JOIN #ImpDelv     AS B ON ( B.DelvSeq = A.DelvSeq ) 
                                                     FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SSLImpDelvSheetSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 4493,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134    
        
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '수입입고 품목데이터 오류' 
              FROM IF_PUInQCResult_MES AS A 
              JOIN #ImpDelvItem        AS B ON ( B.Seq = A.Seq ) 
            
            RETURN 
        END 
        
        
        -- Lot마스터 생성 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.LotNo, 
                                                          A.ItemSeq, 
                                                          A.UnitSeq, 
                                                          A.Qty, 
                                                          A.RegDate, 
                                                          A.CustSeq, 
                                                          A.Remark, 
                                                          A.InNo, 
                                                          A.ValiDate 
                                                      FROM #LotMaster AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SLGLotNoMasterSave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 4422,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134   
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = 'Lot마스터 오류' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #ImpDelvItem         AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
        

        -- 수입필증 -> 수입입고 진행생성 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.ToTableSeq, 
                                                          A.FromQty, 
                                                          A.FromSTDQty, 
                                                          A.FromAmt, 
                                                          A.FromVAT, 
                                                          A.FromSeq, 
                                                          A.FromSerl, 
                                                          A.FromTableSeq, 
                                                          A.ToAmt, 
                                                          A.ToSTDQty, 
                                                          A.ToSeq, 
                                                          A.ToSerl, 
                                                          A.ToVAT, 
                                                          A.ToQty 
                                                      FROM #SourceDaily AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SCOMSourceDailySave_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 3181,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1134   
        

        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '수입필증 -> 수입입고 진행 오류' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #ImpDelvItem         AS B ON ( B.Seq = A.Seq ) 
              
            RETURN 
        END 
        
        -- 수입입고 수불처리 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq, 
                                                          A.InOutType
                                                      FROM #InOutDaily AS A  
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      )) 
        
            EXEC @Status = 
                 KPXCM_SLGInOutDailyBatch_MES         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1341   
        
        
        
        IF @@ERROR <> 0 OR @Status <> 0 
        BEGIN 
            ROLLBACK 
            
            UPDATE A 
               SET ProcYn = '2', 
                   ErrorMessage = '수입입고 재고반영 오류' 
              FROM IF_PUInQCResult_MES  AS A 
              JOIN #ImpDelvItem         AS B ON ( B.Seq = A.Seq ) 
            
            RETURN 
        END 
        ELSE 
        BEGIN 
            
            UPDATE A
               SET ProcYn = '1' 
              FROM IF_PUInQCResult_MES    AS A 
              JOIN #ImpDelvItem            AS B ON ( B.Seq = A.Seq ) 
            --select * from #DelvItem 
            
            
            COMMIT TRAN 
            RETURN 
        END 
        
        IF @MainCnt >= (SELECT MAX(IDX_NO) FROM #DelvAll) 
        BEGIN 
            BREAK 
        END 
        ELSE 
        BEGIN 
            SELECT @MainCnt = @MainCnt + 1 
        END 
    
    END -- while end 
    
    

GO


