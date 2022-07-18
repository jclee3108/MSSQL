IF OBJECT_ID('KPXLS_SPDQCRequestInsPurchaseQuery') IS NOT NULL 
    DROP PROC KPXLS_SPDQCRequestInsPurchaseQuery
GO 

-- v2015.12.09 
    
 -- 수입검사의뢰조회-조회 by 이재천   
 CREATE PROC KPXLS_SPDQCRequestInsPurchaseQuery
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
            @UMImpType      INT, 
            @DelvDateFr     NCHAR(8), 
            @DelvDateTo     NCHAR(8), 
            @QCReqDateFr    NCHAR(8), 
            @QCReqDateTo    NCHAR(8), 
            @CustSeq        INT, 
            @ItemSeq        INT, 
            @LotNo          NVARCHAR(100), 
            @DelvNo         NVARCHAR(100), 
            @QCReqEmpSeq    INT, 
            @QCReqDeptSeq   INT, 
            @SMTestResult   INT, 
            @ReqNo          NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @BizUnit       = ISNULL( BizUnit      , 0 ),  
           @UMImpType     = ISNULL( UMImpType    , 0 ),  
           @DelvDateFr    = ISNULL( DelvDateFr   , '' ),  
           @DelvDateTo    = ISNULL( DelvDateTo   , '' ),  
           @QCReqDateFr   = ISNULL( QCReqDateFr  , '' ),  
           @QCReqDateTo   = ISNULL( QCReqDateTo  , '' ),  
           @CustSeq       = ISNULL( CustSeq      , 0 ),  
           @ItemSeq       = ISNULL( ItemSeq      , 0 ),  
           @LotNo         = ISNULL( LotNo        , '' ),  
           @DelvNo        = ISNULL( DelvNo       , '' ),  
           @QCReqEmpSeq   = ISNULL( QCReqEmpSeq  , 0 ),  
           @QCReqDeptSeq  = ISNULL( QCReqDeptSeq , 0 ), 
           @SMTestResult  = ISNULL( SMTestResult , 0 ), 
           @ReqNo         = ISNULL( ReqNo, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit        INT,  
            UMImpType      INT, 
            DelvDateFr     NCHAR(8), 
            DelvDateTo     NCHAR(8), 
            QCReqDateFr    NCHAR(8), 
            QCReqDateTo    NCHAR(8), 
            CustSeq        INT, 
            ItemSeq        INT, 
            LotNo          NVARCHAR(100),
            DelvNo         NVARCHAR(100),
            QCReqEmpSeq    INT, 
            QCReqDeptSeq   INT, 
            SMTestResult   INT, 
            ReqNo          NVARCHAR(100) 
           )    
    
    IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231'
    IF @QCReqDateTo = '' SELECT @QCReqDateTo = '99991231'
     
    
    CREATE TABLE #Result 
    (
        ReqSeq          INT, 
        ReqSerl         INT, 
        ReqNo           NVARCHAR(100), 
        BizUnit         INT, 
        BizUnitName     NVARCHAR(100), 
        SMSourceType    INT, 
        UMImpTypeName   NVARCHAR(100), 
        CustSeq         INT, 
        CustName        NVARCHAR(100), 
        EmpSeq          INT, 
        EmpName         NVARCHAR(100), 
        DeptSeq         INT, 
        DeptName        NVARCHAR(100), 
        DelvDate        NCHAR(8), 
        DelvNo          NVARCHAR(100), 
        Remark          NVARCHAR(500), 
        ReqQty          DECIMAL(19,5), 
        LotNo           NVARCHAR(100), 
        ReqDate         NCHAR(8), 
        ItemSeq         INT, 
        ItemName        NVARCHAR(100), 
        ItemNo          NVARCHAR(100), 
        Spec            NVARCHAR(100), 
        SOurceSeq       INT, 
        SourceSerl      INT, 
        UMQcTypeName    NVARCHAR(100), 
        UMQcType        INT, 
        CreateDate      NCHAR(8), 
        ValiDate        NCHAr(8), 
        MakerLotNo      NVARCHAR(100), 
        DelvSeq         INT, 
        ExpKind         INT, 
        OKQty           DECIMAL(19,5), 
        BadQty          DECIMAL(19,5) 
    ) 
    
    
    -- 국내 
    INSERT INTO #Result
    (
        ReqSeq              , ReqSerl             , ReqNo               , BizUnit             , BizUnitName         , 
        SMSourceType        , UMImpTypeName       , CustSeq             , CustName            , EmpSeq              , 
        EmpName             , DeptSeq             , DeptName            , DelvDate            , DelvNo              , 
        Remark              , ReqQty              , LotNo               , ReqDate             , ItemSeq             , 
        ItemName            , ItemNo              , Spec                , SOurceSeq           , SourceSerl          , 
        UMQcTypeName        , UMQcType            , CreateDate          , ValiDate            , MakerLotNo          , 
        DelvSeq             , ExpKind             , OKQty               , BadQty
    )
    SELECT A.ReqSeq, 
           B.ReqSerl, 
           A.ReqNo, 
           ISNULL(H.BizUnit,0) AS BizUnit, 
           ISNULL(C.BizUnitName,'') AS BizUnitName, 
           A.SMSourceType, 
           '국내' AS UMImpTypeName, 
           ISNULL(H.CustSeq,0) AS CustSeq, 
           ISNULL(D.CustName,'') AS CustName, 
           ISNULL(H.EmpSeq,0) AS EmpSeq, 
           ISNULL(E.EmpName,'') AS EmpName,            
           ISNULL(H.DeptSeq,0) AS DeptSeq, 
           ISNULL(F.DeptName,'') AS DeptName,            
           ISNULL(H.DelvDate,'') AS DelvDate, 
            ISNULL(H.DelvNo,'') AS DelvNo, 
           B.Remark, 
           ISNULL(K.Qty,0) AS ReqQty, 
           ISNULL(K.LotNo,'') AS LotNo, 
           A.ReqDate AS ReqDate, 
           ISNULL(K.ItemSeq,0) AS ItemSeq, 
           ISNULL(G.ItemName,'') AS ItemName, 
           ISNULL(G.ItemNo,'') AS ItemNo, 
           ISNULL(G.Spec,'') AS Spec,
           B.SourceSeq, 
           B.SourceSerl, 
           CONVERT(NVARCHAR(100),'') AS UMQcTypeName, 
           CONVERT(INT,0) AS UMQcType, 
           M.CreateDate, 
           M.ValiDate,  
           M.MakerLotNo, 
           ISNULL(H.DelvSeq,0) AS DelvSeq, 
           1 AS ExpKind, 
           Q.OKQty, 
           Q.BadQty 
      FROM KPXLS_TQCRequest                     AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TPUDelv                  AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq ) 
      LEFT OUTER JOIN _TPUDelvItem              AS K ON ( K.CompanySeq = @CompanySeq AND K.DelvSeq = B.SourceSeq AND K.DelvSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TDABizUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = H.BizUnit ) 
      LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = H.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = H.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS F ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = H.DeptSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = K.ItemSeq ) 
      LEFT OUTER JOIN KPXLS_TPUDelvItemAdd      AS M ON ( M.CompanySeq = @CompanySeq AND M.DelvSeq = K.DelvSeq AND M.DelvSerl = K.DelvSerl ) 
      LEFT OUTER JOIN KPX_TQCTestResult         AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.ReqSeq = B.ReqSeq AND Q.ReqSErl = B.ReqSerl ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR ISNULL(H.BizUnit,0) = @BizUnit ) 
       AND ( @CustSeq = 0 OR ISNULL(H.CustSeq,0) = @CustSeq ) 
       AND ( @UMImpType = 0 OR  1010619001 = @UMImpType ) 
       AND ( ISNULL(H.DelvDate,'') BETWEEN @DelvDateFr AND @DelvDateTo ) 
       AND ( A.ReqDate BETWEEN @QCReqDateFr AND @QCReqDateTo ) 
       AND ( @ItemSeq = 0 OR ISNULL(K.ItemSeq,0) = @ItemSeq ) 
       AND ( @LotNo = '' OR ISNULL(K.LotNo,'') LIKE @LotNo + '%' ) 
       AND ( @QCReqEmpSeq = 0 OR ISNULL(H.EmpSeq,0) = @QCReqEmpSeq ) 
       AND ( @QCReqDeptSeq = 0 OR ISNULL(H.DeptSeq,0) = @QCReqDeptSeq ) 
       AND ( @DelvNo = '' OR ISNULL(H.DelvNo,'') LIKE @DelvNo + '%' ) 
       AND ( @ReqNo = '' OR A.ReqNo LIKE @ReqNo + '%' ) 
       AND ( A.SMSourceType = 1000522008 AND M.IsPass = '0' ) 
    
    
    -- 수입 
    INSERT INTO #Result
    (
        ReqSeq              , ReqSerl             , ReqNo               , BizUnit             , BizUnitName         , 
        SMSourceType        , UMImpTypeName       , CustSeq             , CustName            , EmpSeq              , 
        EmpName             , DeptSeq             , DeptName            , DelvDate            , DelvNo              , 
        Remark              , ReqQty              , LotNo               , ReqDate             , ItemSeq             , 
        ItemName            , ItemNo              , Spec                , SOurceSeq           , SourceSerl          , 
        UMQcTypeName        , UMQcType            , CreateDate          , ValiDate            , MakerLotNo          , 
        DelvSeq             , ExpKind             , OKQty               , BadQty
    )
    SELECT A.ReqSeq, 
           B.ReqSerl, 
           A.ReqNo, 
           ISNULL(H.BizUnit,0) AS BizUnit, 
           ISNULL(C.BizUnitName,'') AS BizUnitName, 
           A.SMSourceType, 
           '국내' AS UMImpTypeName, 
           ISNULL(H.CustSeq,0) AS CustSeq, 
           ISNULL(D.CustName,'') AS CustName, 
           ISNULL(H.EmpSeq,0) AS EmpSeq, 
           ISNULL(E.EmpName,'') AS EmpName,            
           ISNULL(H.DeptSeq,0) AS DeptSeq, 
           ISNULL(F.DeptName,'') AS DeptName,            
           ISNULL(H.DelvDate,'') AS DelvDate, 
            ISNULL(H.DelvNo,'') AS DelvNo, 
           B.Remark, 
           ISNULL(K.Qty,0) AS ReqQty, 
           ISNULL(K.LotNo,'') AS LotNo, 
           A.ReqDate AS ReqDate, 
           ISNULL(K.ItemSeq,0) AS ItemSeq, 
           ISNULL(G.ItemName,'') AS ItemName, 
           ISNULL(G.ItemNo,'') AS ItemNo, 
           ISNULL(G.Spec,'') AS Spec,
           B.SourceSeq, 
           B.SourceSerl, 
           CONVERT(NVARCHAR(100),'') AS UMQcTypeName, 
           CONVERT(INT,0) AS UMQcType, 
           K.ProdDate AS CreateDate, 
           K.Memo2 AS ValiDate,  
           K.Memo1 AS MakerLotNo, 
           ISNULL(H.DelvSeq,0) AS DelvSeq, 
           2 AS ExpKind, 
           Q.OKQty, 
           Q.BadQty 
           
      FROM KPXLS_TQCRequest                     AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TUIImpDelv               AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq ) 
      LEFT OUTER JOIN _TUIImpDelvItem           AS K ON ( K.CompanySeq = @CompanySeq AND K.DelvSeq = B.SourceSeq AND K.DelvSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TDABizUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = H.BizUnit ) 
      LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = H.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = H.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS F ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = H.DeptSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = K.ItemSeq ) 
      LEFT OUTER JOIN KPX_TQCTestResult         AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.ReqSeq = B.ReqSeq AND Q.ReqSErl = B.ReqSerl ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR ISNULL(H.BizUnit,0) = @BizUnit ) 
       AND ( @CustSeq = 0 OR ISNULL(H.CustSeq,0) = @CustSeq ) 
       AND ( @UMImpType = 0 OR  1010619002 = @UMImpType ) 
       AND ( ISNULL(H.DelvDate,'') BETWEEN @DelvDateFr AND @DelvDateTo ) 
       AND ( A.ReqDate BETWEEN @QCReqDateFr AND @QCReqDateTo ) 
       AND ( @ItemSeq = 0 OR ISNULL(K.ItemSeq,0) = @ItemSeq ) 
       AND ( @LotNo = '' OR ISNULL(K.LotNo,'') LIKE @LotNo + '%' ) 
       AND ( @QCReqEmpSeq = 0 OR ISNULL(H.EmpSeq,0) = @QCReqEmpSeq ) 
       AND ( @QCReqDeptSeq = 0 OR ISNULL(H.DeptSeq,0) = @QCReqDeptSeq ) 
       AND ( @DelvNo = '' OR ISNULL(H.DelvNo,'') LIKE @DelvNo + '%' ) 
       AND ( @ReqNo = '' OR A.ReqNo LIKE @ReqNo + '%' ) 
       AND ( A.SMSourceType = 1000522007 AND K.Memo3 = '0' ) 
    
    UPDATE A  
       SET A.UMQcType    = 1010418004   --미검사  
      FROM #Result AS A   
                                            LEFT OUTER JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                               AND C.ReqSeq      = A.ReqSeq  
                                                                                               AND C.ReqSerl        = A.ReqSerl  
                                            LEFT OUTER JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                               AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(B.CompanySeq,0) = 0    -- 결과 없음       
       
    UPDATE A  
       SET A.UMQcType    = 1010418002  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.UMQcType,0) = 0  
      AND ISNULL(B.SMTestResult ,0) = 6035004   --불합격  
      AND ISNULL(B.IsSpecial, '') <> '1'  
  
    UPDATE A  
       SET A.UMQcType    = 1010418003   --특채  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.UMQcType,0) = 0  
      AND ISNULL(B.IsSpecial, '') = '1'  
  
  
    UPDATE A  
       SET A.UMQcType    = CASE B.SMTestResult WHEN 6035001 /*무검사*/ THEN 1010418005 --무검사  
                                               WHEN 6035003            THEN 1010418001 END  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.UMQcType,0) = 0  
    
    UPDATE A  
       SET A.UMQcTypeName   = B.MinorName  
      FROM #Result AS A JOIN _TDAUMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.UMQcType = B.MinorSeq  
    
    
    DELETE A 
      FROM #Result AS A 
     WHERE @SMTestResult <> 0 
       AND @SMTestResult <> A.UMQcType
            
     
    SELECT *
      FROM #Result 
      
      
    
 RETURN  

go
exec KPXLS_SPDQCRequestInsPurchaseQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReqNo />
    <BizUnit />
    <UMImpType />
    <QCReqDateFr />
    <QCReqDateTo />
    <CustSeq />
    <ItemSeq />
    <LotNo />
    <DelvNo />
    <QCReqEmpSeq />
    <QCReqDeptSeq />
    <SMTestResult>0</SMTestResult>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033670,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027885