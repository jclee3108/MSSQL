  
IF OBJECT_ID('KPXLS_SQCNProlnspRequestListQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCNProlnspRequestListQuery  
GO  
  
-- v2016.01.05  
  
-- (무검사품)수입검사의뢰/결과조회-조회 by 이재천   
CREATE PROC KPXLS_SQCNProlnspRequestListQuery  
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
            @QCReqDateFr    NCHAR(8), 
            @QCReqDateTo    NCHAR(8), 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100), 
            @LotNo          NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @BizUnit       = ISNULL( BizUnit      , 0 ),  
           @QCReqDateFr   = ISNULL( QCReqDateFr  , '' ),  
           @QCReqDateTo   = ISNULL( QCReqDateTo  , '' ),  
           @ItemName      = ISNULL( ItemName, '' ), 
           @ItemNo        = ISNULL( ItemNo, ''), 
           @LotNo         = ISNULL( LotNo        , '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit        INT,  
            QCReqDateFr    NCHAR(8), 
            QCReqDateTo    NCHAR(8), 
            ItemName       NVARCHAR(100),
            ItemNo         NVARCHAR(100),
            LotNo          NVARCHAR(100) 
           )    
    
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
        IsPass          NCHAR(1) 
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
        DelvSeq             , ExpKind             , IsPass 
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
           M.IsPass
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
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR ISNULL(H.BizUnit,0) = @BizUnit ) 
       AND ( A.ReqDate BETWEEN @QCReqDateFr AND @QCReqDateTo ) 
       AND ( @ItemName = '' OR G.ItemName LIKE @ItemName + '%' ) 
       AND ( @ItemNo = '' OR G.ItemNo LIKE @ItemNo + '%' ) 
       AND ( @LotNo = '' OR ISNULL(K.LotNo,'') LIKE @LotNo + '%' ) 
       AND ( A.SMSourceType = 1000522008 AND M.IsPass = '1' ) 
    
    
    -- 수입 
    INSERT INTO #Result
    (
        ReqSeq              , ReqSerl             , ReqNo               , BizUnit             , BizUnitName         , 
        SMSourceType        , UMImpTypeName       , CustSeq             , CustName            , EmpSeq              , 
        EmpName             , DeptSeq             , DeptName            , DelvDate            , DelvNo              , 
        Remark              , ReqQty              , LotNo               , ReqDate             , ItemSeq             , 
        ItemName            , ItemNo              , Spec                , SOurceSeq           , SourceSerl          , 
        UMQcTypeName        , UMQcType            , CreateDate          , ValiDate            , MakerLotNo          , 
        DelvSeq             , ExpKind             , IsPass
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
           K.Memo3 
           
      FROM KPXLS_TQCRequest                     AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TUIImpDelv               AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq ) 
      LEFT OUTER JOIN _TUIImpDelvItem           AS K ON ( K.CompanySeq = @CompanySeq AND K.DelvSeq = B.SourceSeq AND K.DelvSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TDABizUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = H.BizUnit ) 
      LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = H.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = H.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS F ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = H.DeptSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = K.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR ISNULL(H.BizUnit,0) = @BizUnit ) 
       AND ( A.ReqDate BETWEEN @QCReqDateFr AND @QCReqDateTo ) 
       AND ( @ItemName = '' OR G.ItemName LIKE @ItemName + '%' ) 
       AND ( @ItemNo = '' OR G.ItemNo LIKE @ItemNo + '%' ) 
       AND ( @LotNo = '' OR ISNULL(K.LotNo,'') LIKE @LotNo + '%' ) 
       AND ( A.SMSourceType = 1000522007 AND K.Memo3 = '1' ) 
    
    SELECT * FROM #Result 
    
    RETURN  
    go
    exec KPXLS_SQCNProlnspRequestListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit />
    <QCReqDateFr />
    <QCReqDateTo />
    <ItemName />
    <LotNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034222,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028310
