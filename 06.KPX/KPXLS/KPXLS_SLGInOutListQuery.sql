  
IF OBJECT_ID('KPXLS_SLGInOutListQuery') IS NOT NULL   
    DROP PROC KPXLS_SLGInOutListQuery  
GO  
  
-- v2016.01.11  
  
-- 입출고대장조회-조회 by 이재천   
CREATE PROC KPXLS_SLGInOutListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @BizUnit        INT,  
            @DateFr         NCHAR(8), 
            @DateTo         NCHAR(8), 
            @SubInOutSeq    INT, 
            @AssetSeq       INT, 
            @WHSeq          INT, 
            @ItemNo         NVARCHAR(100), 
            @ItemName       NVARCHAR(100), 
            @LotNo          NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit        = ISNULL( BizUnit        , 0 ),  
           @DateFr         = ISNULL( DateFr         , '' ),  
           @DateTo         = ISNULL( DateTo         , '' ),  
           @SubInOutSeq    = ISNULL( SubInOutSeq    , 0 ),  
           @AssetSeq       = ISNULL( AssetSeq       , 0 ),  
           @WHSeq          = ISNULL( WHSeq          , 0 ),  
           @ItemNo         = ISNULL( ItemNo         , '' ),  
           @ItemName       = ISNULL( ItemName       , '' ),  
           @LotNo          = ISNULL( LotNo          , '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit        INT,  
            DateFr         NCHAR(8),       
            DateTo         NCHAR(8),       
            SubInOutSeq    INT,       
            AssetSeq       INT,       
            WHSeq          INT,       
            ItemNo         NVARCHAR(100),      
            ItemName       NVARCHAR(100),      
            LotNo          NVARCHAR(100)       
           )    
    
    CREATE TABLE #GetInOutLot
    (  
        LotNo   NVARCHAR(30),
        ItemSeq    INT  
    )  
    
    CREATE TABLE #GetInOutDetailLotStock  
    (
        IDX_NO          INT IDENTITY,  
        WHSeq           INT,  
        FunctionWHSeq   INT,  
        LotNo           NVARCHAR(30),
        ItemSeq         INT,  
        UnitSeq         INT,  
        InOutDate       NCHAR(8),  
        InOutType       INT,  
        InOutSeq        INT,  
        InOutSerl       INT,  
        InOutNo         NVARCHAR(20),  
        InOutKind       INT,  
        InOutDetailKind INT,  
        InQty           DECIMAL(19,5),  
        OutQty          DECIMAL(19,5),  
        STDInQty        DECIMAL(19,5),  
        STDOutQty       DECIMAL(19,5)  
    )  
    
    CREATE TABLE #GetInOutLotStock    
    (    
        WHSeq           INT,    
        FunctionWHSeq   INT,    
        LotNo           NVARCHAR(30),
        ItemSeq         INT,    
        UnitSeq         INT,    
        PrevQty         DECIMAL(19,5),    
        InQty           DECIMAL(19,5),    
        OutQty          DECIMAL(19,5),    
        StockQty        DECIMAL(19,5),    
        STDPrevQty      DECIMAL(19,5),    
        STDInQty        DECIMAL(19,5),    
        STDOutQty       DECIMAL(19,5),    
        STDStockQty     DECIMAL(19,5)    
    )    
    
    CREATE TABLE #WHDetailStock  
    (  
        IDX                 INT IDENTITY,  
        InOutDate           NCHAR(8),  
        SubInOutName        NVARCHAR(10),  
        InOutKindName       NVARCHAR(100),  
        InOutDetailKindName NVARCHAR(100),  
        WHKindName          NVARCHAR(100),  
        FunctionWHName      NVARCHAR(100),  
        UnitName            NVARCHAR(30),  
        InOutKind           INT,  
        InOutDetailKind     INT,  
        FunctionWHSeq       INT,  
        UnitSeq             INT,  
        SMWHKind            INT,  
        InQty               DECIMAL(19,5),  
        OutQty              DECIMAL(19,5),  
        StockQty            DECIMAL(19,5),  
        InOutType           INT,  
        InOutSeq            INT,  
        InOutSerl           INT,  
        InOutNo             NVARCHAR(30),
        Cnt                 NCHAR(1),
        JumpOutPgmId        NVARCHAR(100), 
        ColumnName          NVARCHAR(50),
        Remark              NVARCHAR(1000), 
        ItemSeq             INT, 
        ItemName            NVARCHAR(100), 
        ItemNo              NVARCHAR(100), 
        LotNo               NVARCHAR(100), 
        AssetSeq            INT, 
        AssetName           NVARCHAR(100), 
        WHSeq               INT, 
        WHName              NVARCHAR(100), 
        BizUnit             INT, 
        BizUnitName         NVARCHAR(100) 
    )  
    
    INSERT INTO #GetInOutLot ( ItemSeq, LotNo ) 
    SELECT A.ItemSeq, B.LotNo 
      FROM _TDAItem         AS A 
      JOIN _TLGLotMaster    AS B ON ( B.CompanySeq = A.CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @AssetSeq = 0 OR A.AssetSeq = @AssetSeq ) 
       AND ( @ItemName = '' OR A.ItemName LIKE @ItemName + '%' ) 
       AND ( @ItemNo = '' OR A.ItemNo LIKE @ItemNo + '%' ) 
       AND ( @LotNo = '' OR B.LotNo LIKE @LotNo + '%' ) 
    
      -- 창고재고 가져오기  (이월)
     EXEC _SLGGetInOutLotStock   @CompanySeq   = @CompanySeq,   -- 법인코드      
                                 @BizUnit      = @BizUnit,      -- 사업부문      
                                 @FactUnit     = 0,     -- 생산사업장      
                                 @DateFr       = @DateFr,       -- 조회기간Fr      
                                 @DateTo       = @DateTo,       -- 조회기간To      
                                 @WHSeq        = @WHSeq,        -- 창고지정      
                                 @SMWHKind     = 0,     -- 창고구분별 조회      
                                 @CustSeq      = 0,      -- 수탁거래처      
                                 @IsTrustCust  = '',  -- 수탁여부      
                                 @IsSubDisplay = '0', -- 기능창고 조회      
                                 @IsUnitQry    = '0',    -- 단위별 조회      
                                 @QryType      = 'S' -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고      
   
     -- 창고재고 가져오기  
     EXEC _SLGGetInOutDetailLotStock     @CompanySeq   = @CompanySeq,   -- 법인코드  
                                         @BizUnit      = @BizUnit,      -- 사업부문  
                                         @FactUnit     = 0,     -- 생산사업장  
                                         @DateFr       = @DateFr,       -- 조회기간Fr  
                                         @DateTo       = @DateTo,       -- 조회기간To  
                                         @WHSeq        = @WHSeq,        -- 창고지정  
                                         @SMWHKind     = 0,     -- 창고구분별 조회  
                                         @CustSeq      = 0,      -- 수탁거래처  
                                         @IsTrustCust  = '',  -- 수탁여부  
                                         @IsSubInclude = '0', -- 기능창고 포함  
                                         @IsSubDisplay = '0', -- 기능창고 조회  
                                         @IsUnitQry    = '0',    -- 단위별 조회  
                                         @QryType      = 'S' -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고 
    
    
    -- _TLGInOutJumpPgmId에 InOutType별 PgmId가 존재합니다. -> ( sp_help _TLGInOutJumpPgmId / SELECT * FROM _TLGInOutJumpPgmId )
    -- 일단 #JumpPgmId에 각 구분값(Local구분, 반품구분, 프로젝트구분)에 대한 디폴드 값을 INSERT 한 후,
    -- SP로 넘어온 DataBlock의 데이터를 검토하여 조건 별로 UPDATE 해 줍니다.
    -- 이렇게 UPDATE 된 #JumpPgmId를 통해, _TLGInOutJumpPgmId과 JOIN하여 PgmId를 조회합니다.
    CREATE TABLE #JumpPgmId 
    (
        IDX_NO      INT,
        SMInOutType INT,
        InOutType   INT,
        InOutSeq    INT,
        InOutSerl   INT,
        SMLocalKind INT,
        IsReturn    NCHAR(1),
        IsPMS       NCHAR(1),
        ColumnName  NVARCHAR(100)
    )
    INSERT INTO #JumpPgmId ( IDX_NO, SMInOutType, InOutType, InOutSeq, InOutSerl, SMLocalKind, IsReturn, IsPMS, ColumnName )
    SELECT A.IDX_NO, B.MinorSeq, A.InOutType, A.InOutSeq, A.InOutSerl, 8918001, '0', '0',
           CASE A.InOutType WHEN 10  THEN 'InvoiceSeq'    -- 거래명세표
                            WHEN 11  THEN 'InvoiceSeq'    -- 반품명세표
                            WHEN 20  THEN 'BillSeq'       -- 매출
                            WHEN 120 THEN 'SetInOutSeq'   -- 세트입고처리
                            WHEN 130 THEN 'WorkReportSeq' -- 생산실적
                            WHEN 140 THEN 'GoodInSeq'     -- 생산입고
                            WHEN 150 THEN 'OSPDelvInSeq'  -- 외주입고
                            WHEN 160 THEN 'DelvSeq'       -- 구매납품
                            WHEN 170 THEN 'DelvInSeq'     -- 구매입고
                            WHEN 180 THEN 'MatOutSeq'     -- 자재불출
                            WHEN 190 THEN 'OSPDelvSeq'    -- 외주납품
                            WHEN 240 THEN 'DelvSeq'       -- 수입입고
                            WHEN 241 THEN 'DelvSeq'       -- 수입반품
                            WHEN 250 THEN 'MoveSeq'       -- 공정품이동
                            WHEN 260 THEN 'QCSeq'         -- 구매후검사
                            WHEN 171 THEN 'DelvInSeq'     -- 구매반품
                            WHEN 280 THEN 'BadReworkSeq'  -- 입고후불량재작업
                            WHEN 300 THEN 'DelvInSeq'     -- 구매입고반품
                            WHEN 350 THEN 'OSPDelvInSeq'  -- 외주입고반품
                            WHEN 330 THEN 'AdjustSeq'     -- 공정품 수량조정   -- 2014.03.28 김용현 추가 JumpOut이 안되서
                            WHEN 370 THEN 'DelvInSeq'     -- 구매반품
                            WHEN 310 THEN 'InOutSeq'      -- LOT대체
                                     ELSE 'InOutSeq'      END AS ColumnName
      FROM #GetInOutDetailLotStock  AS A
      JOIN _TDASMinor               AS B WITH(NOLOCK) ON A.InOutType  = B.MinorValue
                                                     AND B.MajorSeq   = 8042
                                                     AND B.CompanySeq = @CompanySeq
    
    /***** 프로젝트 구분 UPDATE *****/
    UPDATE #JumpPgmId
       SET IsPMS = '1'
      FROM #JumpPgmId                   AS A
      JOIN #GetInOutDetailLotStock      AS B ON A.InOutSeq = B.InOutSeq
                                            AND A.InOutSerl = B.InOutSerl
                                            AND A.InOutType = B.InOutType
      JOIN _TSLInvoice                  AS C ON C.CompanySeq = @CompanySeq
                                            AND B.InOutType IN (10, 11)
                                            AND B.InOutSeq = C.InvoiceSeq
     WHERE ISNULL(C.IsPJT, '') = '1'
         
 -- PJT여부 추가 20130830  
   
 -- FrmPJTMMOutProc             프로젝트자재출고입력  
 -- FrmPUDelv_PMSPur            프로젝트구매납품입력  
 -- FrmPUDelvIn_PMSPur          프로젝트구매입고입력  
 -- FrmPUDelvInReturn_PMSPur    프로젝트구매반품입력  
 -- FrmSLBill2_PMSSales         프로젝트세금계산서입력(매출)  
   
    /***** 프로젝트 구분 UPDATE *****/      -- PMS 구분 매출 추가  
    UPDATE #JumpPgmId    
       SET IsPMS = '1'     
      FROM #JumpPgmId                       AS A    
      JOIN #GetInOutDetailLotStock          AS B ON A.InOutSeq   = B.InOutSeq    
                                                AND A.InOutSerl  = B.InOutSerl    
                                                AND A.InOutType  = B.InOutType    
      LEFT OUTER JOIN _TSLSales             AS C ON C.CompanySeq = @CompanySeq     
                                                AND A.InOutSeq   = C.SalesSeq    
                                                AND A.InOutType  = 20    
      LEFT OUTER JOIN _TSLSalesitem         AS D ON C.CompanySeq = D.CompanySeq     
                                                AND C.SalesSeq   = D.SalesSeq  
   
     WHERE ISNULL(D.PjtSeq, 0) <> 0    
   
   
   
    /***** 프로젝트 구분 UPDATE *****/      -- PMS 구분 구매납품 추가  
    UPDATE #JumpPgmId    
       SET IsPMS = '1'     
      FROM #JumpPgmId                   AS A    
      JOIN #GetInOutDetailLotStock      AS B ON A.InOutSeq   = B.InOutSeq    
                                            AND A.InOutSerl  = B.InOutSerl    
                                            AND A.InOutType  = B.InOutType    
      LEFT OUTER JOIN _TpuDelv          AS C ON C.CompanySeq = @CompanySeq     
                                            AND A.InOutSeq    = C.DelvSeq    
                                            AND A.InOutType  = 160    
           
     WHERE ISNULL(C.IsPJT, '') = '1'    
               
   
    /***** 프로젝트 구분 UPDATE *****/      -- PMS 구분 구매입고 추가  
    UPDATE #JumpPgmId    
       SET IsPMS = '1'     
      FROM #JumpPgmId                       AS A    
      JOIN #GetInOutDetailLotStock          AS B ON A.InOutSeq = B.InOutSeq    
                                                  AND A.InOutSerl = B.InOutSerl    
                                                  AND A.InOutType = B.InOutType    
      LEFT OUTER JOIN _TpuDelvIn            AS C ON C.CompanySeq = @CompanySeq     
                                                AND A.InOutSeq = C.DelvInSeq    
                                                AND A.InOutType = 170    
     WHERE ISNULL(C.IsPJT, '') = '1'    
        
     
     
    /***** 프로젝트 구분 UPDATE *****/      -- PMS 구분 자재출고 추가  
    UPDATE #JumpPgmId    
       SET IsPMS = '1'     
      FROM #JumpPgmId                       AS A    
      JOIN #GetInOutDetailLotStock          AS B ON A.InOutSeq = B.InOutSeq    
                                                AND A.InOutSerl = B.InOutSerl    
                                                AND A.InOutType = B.InOutType    
      LEFT OUTER JOIN _TPDMMOutM            AS C ON C.CompanySeq = @CompanySeq     
                                                AND A.InOutSeq = C.MatOutSeq    
                                                AND A.InOutType = 180    
      LEFT OUTER JOIN _TPDMMOutItem         AS D ON C.CompanySeq = D.CompanySeq     
                                                AND C.MatOutSeq = D.MatOutSeq  
     WHERE ISNULL(D.PjtSeq, 0) <> 0
      
    /***** 프로젝트 구분 UPDATE *****/      -- PMS 구분 수입입고 
    UPDATE #JumpPgmId    
       SET IsPMS = '1'     
      FROM #JumpPgmId                       AS A    
      JOIN #GetInOutDetailLotStock          AS B ON A.InOutSeq = B.InOutSeq    
                                                AND A.InOutSerl = B.InOutSerl    
                                                AND A.InOutType = B.InOutType    
      LEFT OUTER JOIN _TUIImpDelv           AS C ON C.CompanySeq = @CompanySeq     
                                                AND A.InOutSeq   = C.DelvSeq    
                                                AND A.InOutType  = 240    
      LEFT OUTER JOIN _TUIImpDelvItem       AS D ON C.CompanySeq = D.CompanySeq     
                                                AND C.DelvSeq  = D.DelvSeq  
     WHERE ISNULL(C.ISPJT, 0) <> 0
    
    /***** 내수수출구분 UPDATE *****/
    -- 거래명세표(10) & 반품명세표(11)
    UPDATE #JumpPgmId
       SET SMLocalKind = 8918002
      FROM #JumpPgmId                   AS A
      JOIN #GetInOutDetailLotStock      AS B ON A.InOutSeq = B.InOutSeq
                                            AND A.InOutSerl = B.InOutSerl
                                            AND A.InOutType = B.InOutType
      LEFT OUTER JOIN _TSLExpInvoice    AS C ON C.CompanySeq = @CompanySeq
                                            AND A.InOutType IN (10, 11)
                                            AND A.InOutSeq = C.InvoiceSeq
     WHERE ISNULL(C.InvoiceSeq, 0) <> 0
    
    -- 판매매출(20)
    UPDATE #JumpPgmId
       SET SMLocalKind = 8918002
      FROM #JumpPgmId                       AS A
      JOIN #GetInOutDetailLotStock          AS B ON A.InOutSeq = B.InOutSeq
                                                AND A.InOutSerl = B.InOutSerl
                                                AND A.InOutType = B.InOutType
      LEFT OUTER JOIN _TSLSales             AS C ON C.CompanySeq = @CompanySeq 
                                                AND A.InOutSeq = C.SalesSeq
                                                AND A.InOutType  = 20
      LEFT OUTER JOIN _TDASMinorValue       AS D ON C.CompanySeq = D.CompanySeq
                                                AND C.SMExpKind  = D.MinorSeq
                                                AND D.Serl       = 1001
     WHERE D.ValueText <> '1'
  
    /*****  반품구분 UPDATE *****/
    UPDATE #JumpPgmId
       SET IsReturn = '1'
      FROM #JumpPgmId                   AS A
      JOIN #GetInOutDetailLotStock      AS B ON A.InOutSeq  = B.InOutSeq
                                            AND A.InOutSerl = B.InOutSerl
                                            AND A.InOutType = B.InOutType
     WHERE B.InOutType  = 180
       AND B.InOutKind <> 8023020
  
    -- 수입반품(수입claim)
    UPDATE #JumpPgmId  
       SET IsReturn = '1'  
      FROM #JumpPgmId                   AS A  
      JOIN #GetInOutDetailLotStock      AS B ON A.InOutSeq  = B.InOutSeq  
                                            AND A.InOutSerl = B.InOutSerl  
                                            AND A.InOutType = B.InOutType  
     WHERE B.InOutType  = 241
    
    /****************************************************************************/
    
    
    INSERT INTO #WHDetailStock
    (
        InOutDate, SubInOutName, InOutKindName, InOutDetailKindName, WHKindName,  
        FunctionWHName, UnitName, InOutKind, InOutDetailKind, FunctionWHSeq,  
        UnitSeq, SMWHKind, InQty, OutQty, StockQty,  
        InOutType, InOutSeq, InOutSerl, InOutNo,JumpOutPgmId,ColumnName, Remark, 
        ItemSeq, ItemName, ItemNo, LotNo, AssetSeq, AssetName, 
        WHSeq, WHName, BizUnit, BizUnitName, Cnt 
    )
    SELECT  ISNULL(A.InOutDate,'') AS InOutDate,                               
             CASE WHEN A.InQty <> 0 THEN '입고'  
                  WHEN A.OutQty <> 0 THEN '출고'  
                  ELSE '' END AS SubInOutName,  
             ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.InOutKind), '') AS InOutKindName,  
             ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.InOutDetailKind), '') AS InOutDetailKindName,  
             ISNULL((SELECT MinorName   
                       FROM _TDASMinor WITH (NOLOCK)  
                      WHERE CompanySeq = @CompanySeq   
                        AND MinorSeq = (CASE WHEN ISNULL(A.FunctionWHSeq,0) = 0 THEN ISNULL(B.SMWHKind,0) ELSE ISNULL(C.SMWHKind,0) END)),'') AS WHKindName,  
             ISNULL((SELECT WHName FROM _TDAWHSub WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = A.FunctionWHSeq), '') AS FunctionWHName,  
             ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = D.UnitSeq), '') AS UnitName,  
             ISNULL(A.InOutKind, 0)   AS InOutKind,  
             ISNULL(A.InOutDetailKind, 0) AS InOutDetailKind,  
             ISNULL(A.FunctionWHSeq, 0)  AS FunctionWHSeq,  
             ISNULL(D.UnitSeq, 0) AS UnitSeq,  
             CASE WHEN ISNULL(A.FunctionWHSeq,0) = 0 THEN ISNULL(B.SMWHKind,0) ELSE ISNULL(C.SMWHKind,0) END AS SMWHKind,  
             ISNULL(A.STDInQty, 0) AS InQty,  
             ISNULL(A.STDOutQty, 0) AS OutQty,  
             ISNULL(A.STDInQty, 0) - ISNULL(A.STDOutQty, 0) AS StockQty,  
             ISNULL(A.InOutType,0)   AS InOutType,  
             ISNULL(A.InOutSeq, 0)   AS InOutSeq,  
             ISNULL(A.InOutSerl, 0)   AS InOutSerl,  
             ISNULL(A.InOutNo, '')   AS InOutNo, 
             ISNULL(Pgm2.PgmId, P.PgmId)  AS JumpOutPgmId, -- 20130621 박성호 추가
             O.ColumnName,
             -- 자재투입에 한하여 생산실적입력의 하단 자재투입에 대한 비고로 보여줌 :: 20151104 김소록 추가
             CASE WHEN A.InOutKind = 8023015 THEN ISNULL(I.InOutRemark, '') 
                                             ELSE ISNULL(Pgm1.InOutRemark, '') END AS Remark  , 
             A.ItemSeq, 
             D.ItemName, 
             D.ItemNo, 
             A.LotNo, 
             E.AssetSeq, 
             E.AssetName, 
             A.WHSeq, 
             B.WHName, 
             @BizUnit, 
             (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit) AS BizUnitName, 
             '4' AS Cnt 
             
      FROM  #GetInOutDetailLotStock      AS A
      LEFT OUTER JOIN _TDAWH              AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A.WHSeq = B.WHSeq  
      LEFT OUTER JOIN _TDAWHSub           AS C ON C.CompanySeq = @CompanySeq  
                                                            AND A.FunctionWHSeq = C.WHSeq  
      LEFT OUTER JOIN _TDAItem            AS D ON D.CompanySeq = @CompanySeq  
                                                            AND A.ItemSeq = D.ItemSeq
                 JOIN #JumpPgmId          AS O              ON A.InOutType = O.InOutType 
                                                           AND A.InOutSeq = O.InOutSeq 
                                                           AND A.InOutSerl = O.InOutSerl 
                                                           AND A.IDX_NO = O.IDX_NO
      LEFT OUTER JOIN _TLGInOutJumpPgmId  AS P ON P.CompanySeq = @CompanySeq
                                                           AND P.SMInOutType = O.SMInOutType
                                                           AND P.SMLocalKind = O.SMLocalKind
                                                           AND P.IsReturn = O.IsReturn
                                                           AND P.IsPMS = O.IsPMS
      LEFT OUTER JOIN _TLGInOutDailyItem  AS Pgm1 ON Pgm1.CompanySeq = @CompanySeq
                                                              AND Pgm1.InOutType = A.InOutType
                                                              AND Pgm1.InOutSeq = A.InOutSeq
                                                              AND Pgm1.InOutSerl = A.InOutSerl
                                                              AND Pgm1.LotNo = A.LotNo
      LEFT OUTER JOIN _TLGInOutDailyItemSub AS I ON I.CompanySeq = @CompanySeq 
                                                             AND I.InOutType = A.InOutType 
                                                             AND I.InOutSeq = A.InOutSeq 
                                                             AND I.LotNo = A.LotNo
                                                             AND I.ItemSeq = A.ItemSeq
      LEFT OUTER JOIN _TCAPgm               AS Pgm2 ON Pgm2.PgmSeq = Pgm1.PgmSeq
      LEFT OUTER JOIN _TDAItemAsset         AS E ON ( E.CompanySeq = @CompanySeq AND E.AssetSeq = D.AssetSeq ) 
     WHERE ( @SubInOutSeq = 0 OR 
             CASE WHEN A.InQty <> 0 THEN '입고'  
                  WHEN A.OutQty <> 0 THEN '출고'  
                  ELSE '' END = CASE WHEN @SubInOutSeq = 1 THEN '입고' WHEN @SubInOutSeq = 2 THEN '출고' END ) 
     ORDER BY A.InOutDate, A.InOutSeq, A.InOutSerl, A.InOutType, A.InOutKind  
    
    
    UPDATE #WHDetailStock  
       SET StockQty = Y.StockQty  
      FROM #WHDetailStock AS X   
      JOIN (
            SELECT A.IDX, SUM(B.StockQty) AS StockQty  
              FROM #WHDetailStock AS A   
              JOIN #WHDetailStock AS B ON A.IDX >= B.IDX  
             WHERE B.CNT NOT IN (2,3)   
             GROUP BY A.IDX
           ) AS Y ON X.IDX = Y.IDX  
    
    -- 구매입고 -> 구매납품 
    CREATE TABLE #DelvIn
    (
        IDX_NO      INT IDENTITY, 
        DelvInSeq   INT, 
        DelvInSerl  INT 
    )    
    INSERT INTO #DelvIn ( DelvInSeq , DelvInSerl ) 
    SELECT InOutSeq, InOutSerl 
      FROM #WHDetailStock 
     WHERE InOutType = 170 
    
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TPUDelvItem'   -- 찾을 데이터의 테이블

    CREATE TABLE #TCOMSourceTracking 
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
          
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TPUDelvInItem',  -- 기준 테이블
                             @TempTableName = '#DelvIn',  -- 기준템프테이블
                             @TempSeqColumnName = 'DelvInSeq',  -- 템프테이블 Seq
                             @TempSerlColumnName = 'DelvInSerl',  -- 템프테이블 Serl
                             @TempSubSerlColumnName = '' 

    TRUNCATE TABLE #GetInOutLotStock 
    TRUNCATE TABLE #GetInOutDetailLotStock 
    
    SELECT @DateFr = LEFT(@DateFr,4) + '0101'
    
    
     -- 창고재고 가져오기  
     EXEC _SLGGetInOutDetailLotStock     @CompanySeq   = @CompanySeq,   -- 법인코드  
                                         @BizUnit      = @BizUnit,      -- 사업부문  
                                         @FactUnit     = 0,     -- 생산사업장  
                                         @DateFr       = @DateFr,       -- 조회기간Fr  
                                         @DateTo       = @DateTo,       -- 조회기간To  
                                         @WHSeq        = @WHSeq,        -- 창고지정  
                                         @SMWHKind     = 0,     -- 창고구분별 조회  
                                         @CustSeq      = 0,      -- 수탁거래처  
                                         @IsTrustCust  = '',  -- 수탁여부  
                                         @IsSubInclude = '0', -- 기능창고 포함  
                                         @IsSubDisplay = '0', -- 기능창고 조회  
                                         @IsUnitQry    = '0',    -- 단위별 조회  
                                         @QryType      = 'S' -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고 
    
    
    -- 입출고 -> 입출고요청 
    CREATE TABLE #InOut
    (
        IDX_NO      INT IDENTITY, 
        InOutSeq    INT, 
        InOutSerl   INT
    )    
    INSERT INTO #InOut ( InOutSeq , InOutSerl ) 
    SELECT InOutSeq, InOutSerl
      FROM #WHDetailStock 
     WHERE InOutKind IN ( 8023020, 8023008 ) 
    
    TRUNCATE TABLE #TMP_SourceTable   
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TLGInOutReqItem'   -- 찾을 데이터의 테이블

    TRUNCATE TABLE #TCOMSourceTracking 
          
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TLGInOutDailyItem',  -- 기준 테이블
                             @TempTableName = '#InOut',  -- 기준템프테이블
                             @TempSeqColumnName = 'InOutSeq',  -- 템프테이블 Seq
                             @TempSerlColumnName = 'InOutSerl',  -- 템프테이블 Serl
                             @TempSubSerlColumnName = '' 
    
    
    SELECT A.*, C.CustName, 
           CASE WHEN A.InOutType = 170 THEN F.MakerLotNo 
                WHEN A.InOutType = 240 THEN I.Memo1 
                ELSE '' END AS MakerLotNo, 
           CASE WHEN A.InOutType = 170 THEN H.CustName 
                WHEN A.InOutType = 240 THEN J.CustName 
                ELSE '' END AS CustName, 
           K.SumInQty, 
           K.SumOutQty, 
           ISNULL(K.SumInQty,0) - ISNULL(K.SumOutQty,0) AS SumStockQty, 
           CASE WHEN A.InOutKind IN ( 8023001, 8023021 ) THEN M.CustName 
                WHEN A.InOutKind IN ( 8023020, 8023008 ) THEN S.DeptName 
                WHEN A.InOutKind IN ( 8023003, 8023015 ) THEN N.DeptName 
                END AS OutCustName, 
           T.ReqNo AS QCReqNo, 
           CASE WHEN A.InOutKind = 8023020 THEN U.LotNo ELSE '' END BatchNo
    
      FROM #WHDetailStock AS A
      LEFT OUTER JOIN _TLGInOutDaily            AS B ON B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = A.InOutType
      LEFT OUTER JOIN _TDACust                  AS C ON C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq 
      LEFT OUTER JOIN #DelvIn                   AS D ON ( D.DelvInSeq = A.InOutSeq AND D.DelvInSerl = A.InOutSerl ) 
      LEFT OUTER JOIN #TCOMSourceTracking       AS E ON ( E.IDX_NO = D.IDX_NO ) 
      LEFT OUTER JOIN KPXLS_TPUDelvItemAdd      AS F ON ( F.CompanySeq = @CompanySeq AND F.DelvSeq = E.Seq AND F.DelvSerl = E.Serl ) 
      LEFT OUTER JOIN _TPUDelvItem              AS G ON ( G.CompanySeq = @CompanySeq AND G.DelvSeq = E.Seq AND G.DelvSerl = E.Serl )      
      LEFT OUTER JOIN _TDACust                  AS H ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = G.MakerSeq ) 
      LEFT OUTER JOIN _TUIImpDelvItem           AS I ON ( I.CompanySeq = @CompanySeq AND I.DelvSeq = A.InOutSeq AND I.DelvSerl = A.InOutSerl ) 
      LEFT OUTER JOIN _TDACust                  AS J ON ( J.CompanySeq = @CompanySeq AND J.CustSeq = I.MakerSeq ) 
      LEFT OUTER JOIN (
                        SELECT ItemSeq, LotNo, WHSeq, SUM(STDInQty) AS SumInQty, SUM(STDOutQty) AS SumOutQty -- 누계재고 
                          FROM #GetInOutDetailLotStock 
                         GROUP BY ItemSeq, LotNo, WHSeq 
                      ) AS K ON ( K.ItemSeq = A.ItemSeq AND K.LotNo = A.LotNo AND K.WHSeq = A.WHSeq ) 
      LEFT OUTER JOIN _TLGInOutDaily            AS L ON ( L.CompanySeq = @CompanySeq AND L.InOutSeq = A.InOutSeq AND L.InOutType = A.InOutType ) 
      LEFT OUTER JOIN _TDACust                  AS M ON ( M.CompanySeq = @CompanySeq AND M.CustSeq = L.CustSeq ) 
      LEFT OUTER JOIN _TDADept                  AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = L.DeptSeq ) 
      LEFT OUTER JOIN #InOut                    AS O ON ( O.InOutSeq = A.InOutSeq AND O.InOutSerl = A.InOutSerl ) 
      LEFT OUTER JOIN #TCOMSourceTracking       AS P ON ( P.IDX_NO = O.IDX_NO ) 
      LEFT OUTER JOIN _TLGInOutReqItem          AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.ReqSeq = P.Seq AND Q.ReqSerl = P.Serl ) 
      LEFT OUTER JOIN _TLGInOutReq              AS R ON ( R.CompanySeq = @CompanySeq AND R.ReqSeq = Q.ReqSeq ) 
      LEFT OUTER JOIN _TDADept                  AS S ON ( S.CompanySeq = @CompanySeq AND S.DeptSeq = R.DeptSeq ) 
      LEFT OUTER JOIN _TLGInOutDailyItem        AS U ON ( U.CompanySeq = @CompanySeq AND U.InOutSeq = A.InOutSeq AND U.InOutSerl = A.InOutSerl AND U.InOutType = A.InOutType ) 
      LEFT OUTER JOIN ( 
                        SELECT ReqNo, -- 시험검사의뢰번호 
                               CASE WHEN Z.SMSourceType = 1000522008 THEN R.ItemSeq 
                                    WHEN Z.SMSourceType = 1000522007 THEN S.ItemSeq 
                                    END AS ItemSeq, 
                               CASE WHEN Z.SMSourceType = 1000522008 THEN R.LotNo 
                                    WHEN Z.SMSourceType = 1000522007 THEN S.LotNo 
                                    END AS LotNo
                          FROM KPXLS_TQCRequest                 AS Z 
                          LEFT OUTER JOIN KPXLS_TQCRequestItem  AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ReqSeq = Z.ReqSeq ) 
                          LEFT OUTER JOIN _TPUDelvItem          AS R ON ( R.CompanySeq = @CompanySeq AND R.DelvSeq = Y.SourceSeq AND R.DelvSerl = Y.SourceSerl )
                          LEFT OUTER JOIN _TUIImpDelvItem       AS S ON ( S.CompanySeq = @CompanySeq AND S.DelvSeq = Y.SourceSeq AND S.DelvSerl = Y.SourceSerl ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.SMSourceType IN ( 1000522008, 1000522007 ) 
                      ) AS T ON ( T.ItemSeq = A.ItemSeq AND T.LotNo = A.LotNo ) 

     ORDER BY IDX
    
    RETURN  
    go
    begin tran 
exec KPXLS_SLGInOutListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <DateFr>20150102</DateFr>
    <DateTo>20160112</DateTo>
    <WHSeq />
    <SubInOutSeq />
    <AssetSeq />
    <ItemName />
    <ItemNo />
    <LotNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028385

rollback 
