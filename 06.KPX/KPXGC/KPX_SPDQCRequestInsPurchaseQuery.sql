  
IF OBJECT_ID('KPX_SPDQCRequestInsPurchaseQuery') IS NOT NULL   
    DROP PROC KPX_SPDQCRequestInsPurchaseQuery  
GO  
  
-- v2015.01.15 
  
-- 수입검사의뢰조회-조회 by 이재천   
CREATE PROC KPX_SPDQCRequestInsPurchaseQuery  
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
            @SMTestResult   INT 
    
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
           @SMTestResult  = ISNULL( SMTestResult , 0 ) 
    
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
            SMTestResult   INT 
           )    
    
    IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231'
    IF @QCReqDateTo = '' SELECT @QCReqDateTo = '99991231'
    
    CREATE TABLE #Temp 
    (
        PurQCReqSeq     INT, 
        PurQCReqSerl    INT, 
        PurQCReqNo      NVARCHAR(100), 
        BizUnit         INT, 
        BizUnitName     NVARCHAR(100), 
        SMSourceType    INT, 
        UMImpTypeName   NVARCHAR(100), 
        CustSeq         INT, 
        CustName        NVARCHAR(100), 
        QCReqEmpSeq     INT, 
        QCReqEmpName    NVARCHAR(100), 
        QCReqDeptSeq    INT, 
        QCReqDeptName   NVARCHAR(100), 
        DelvDate        NCHAR(8), 
        DelvNo          NVARCHAR(100), 
        Remark          NVARCHAR(2000), 
        ReqQty          DECIMAL(19,5), 
        LotNo           NVARCHAR(100), 
        QCReqDate       NCHAR(8), 
        ItemSeq         INT, 
        ItemName        NVARCHAR(100), 
        ItemNo          NVARCHAR(100), 
        Spec            NVARCHAR(100), 
        SourceSeq       INT, 
        SourceSerl      INT, 
        QCTypeName      NVARCHAR(100), 
        QCType          INT 
    )
    
    INSERT INTO #Temp 
    (
        PurQCReqSeq         ,PurQCReqSerl        ,PurQCReqNo          ,BizUnit             ,BizUnitName         ,
        SMSourceType        ,UMImpTypeName       ,CustSeq             ,CustName            ,QCReqEmpSeq         ,
        QCReqEmpName        ,QCReqDeptSeq        ,QCReqDeptName       ,DelvDate            ,DelvNo              ,
        Remark              ,ReqQty              ,LotNo               ,QCReqDate           ,ItemSeq             ,
        ItemName            ,ItemNo              ,Spec                ,SourceSeq           ,SourceSerl          , 
        QCTypeName          ,QCType 
        
    ) 
    SELECT A.ReqSeq AS PurQCReqSeq, 
           B.ReqSerl AS PurQCReqSerl, 
           A.ReqNo AS PurQCReqNo, 
           A.BizUnit, 
           C.BizUnitName, 
           B.SMSourceType, 
           CASE WHEN B.SMSourceType = 1000522007 THEN '수입' WHEN B.SMSourceType = 1000522008 THEN '국내' ELSE '' END AS UMImpTypeName, 
           A.CustSeq, 
           D.CustName, 
           A.EmpSeq AS QCReqEmpSeq, 
           E.EmpName AS QCReqEmpName, 
           A.DeptSeq AS QCReqDeptSeq, 
           F.DeptName AS QCReqDeptName, 
           CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLDate,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvDate,'') ELSE '' END AS DelvDate, 
           CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLNo,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvNo,'') ELSE '' END AS DelvNo, 
           B.Remark, 
           B.ReqQty, 
           B.LotNo, 
           A.ReqDate AS QCReqDate, 
           B.ItemSeq, 
           G.ItemName, 
           G.ItemNo, 
           G.Spec, 
           B.SourceSeq, 
           B.SourceSerl, 
           J.QCTypeName, 
           B.QCType 
    
      FROM KPX_TQCTestRequest                   AS A 
      LEFT OUTER JOIN KPX_TQCTestRequestItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TDABizUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS F ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TPUDelv                  AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq ) 
      LEFT OUTER JOIN _TUIImpBL                 AS I ON ( I.CompanySeq = @CompanySeq AND I.BLSeq = B.SourceSeq )
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS J ON ( J.CompanySeq = @CompanySeq AND J.QCType = B.QCType ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
       AND ( @UMImpType = 0 OR CASE WHEN B.SMSourceType = 1000522007 THEN 1010619002 WHEN B.SMSourceType = 1000522008 THEN 1010619002 ELSE 0 END = @UMImpType ) 
       AND ( CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLDate,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvDate,'') ELSE '' END BETWEEN @DelvDateFr AND @DelvDateTo ) 
       AND ( A.ReqDate BETWEEN @QCReqDateFr AND @QCReqDateTo ) 
       AND ( @ItemSeq = 0 OR B.ItemSeq = @ItemSeq ) 
       AND ( @LotNo = '' OR B.LotNo LIKE @LotNo + '%' ) 
       AND ( @QCReqEmpSeq = 0 OR A.EmpSeq = @QCReqEmpSeq ) 
       AND ( @QCReqDeptSeq = 0 OR A.DeptSeq = @QCReqDeptSeq ) 
       AND ( B.SMSourceType IN ( 1000522007, 1000522008 ) ) 
       AND ( @DelvNo = '' OR CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLNo,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvNo,'') ELSE '' END LIKE @DelvNo + '%' ) 
    /*
    -----------------------------------------------
    -- 구매 납품 -> 구매입고 진행구하기 
    -----------------------------------------------
    CREATE TABLE #Delv 
    (
        IDX_NO      INT IDENTITY, 
        DelvSeq     INT, 
        DelvSerl    INT 
    )
    INSERT INTO #Delv (DelvSeq, DelvSerl) 
    SELECT SourceSeq, SourceSerl 
      FROM #Temp 
     WHERE SMSourceType = 1000522008
    
    CREATE TABLE #TMP_ProgressTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    ) 
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TPUDelvInItem'   -- 데이터 찾을 테이블
    
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
            @TableName = '_TPUDelvItem',    -- 기준이 되는 테이블
            @TempTableName = '#Delv',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'DelvSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'DelvSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
    SELECT A.DelvSeq, A.DelvSerl, C.DelvInDate 
      INTO #DelvIn
      FROM #Delv AS A 
      LEFT OUTER JOIN #TCOMProgressTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      LEFT OUTER JOIN _TPUDelvIn            AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvInSeq = B.Seq ) 
    
    -----------------------------------------------
    -- 수입 BL -> 수입 입고 진행구하기 
    -----------------------------------------------
    CREATE TABLE #BL 
    (
        IDX_NO      INT IDENTITY, 
        BLSeq       INT, 
        BLSerl      INT 
    )
    INSERT INTO #BL (BLSeq, BLSerl) 
    SELECT SourceSeq, SourceSerl 
      FROM #Temp 
     WHERE SMSourceType = 1000522007
    
    TRUNCATE TABLE #TMP_ProgressTable 
    
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TUIImpDelvItem'   -- 데이터 찾을 테이블
    
    TRUNCATE TABLE #TCOMProgressTracking
    
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TUIImpBLItem',    -- 기준이 되는 테이블
            @TempTableName = '#BL',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'BLSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'BLSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
    SELECT A.BLSeq, A.BLSerl, C.DelvDate
      INTO #BLDelvIn 
      FROM #BL AS A 
      LEFT OUTER JOIN #TCOMProgressTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      LEFT OUTER JOIN _TUIImpDelv           AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.Seq ) 
    */ 
    --  최종조회 
    SELECT A.*, 
           --CASE WHEN A.SMSourceType = 1000522007 THEN ISNULL(C.DelvDate,'') WHEN A.SMSourceType = 1000522008 THEN ISNULL(B.DelvInDate,'') ELSE '' END AS DelvInDate, -- 입고일
           D.QCNo, -- 검사번호
           E.EmpSeq AS TestEmpSeq, 
           F.EmpName AS TestEmpName, -- 검사자 
           E.TestDate, -- 검사일
           D.SMTestResult AS SMTestResult, -- 검사구분 
           ISNULL(G.MinorName,'미검사') AS SMTestResultName -- 검사구분 
      FROM #Temp                        AS A 
      --LEFT OUTER JOIN #DelvIn           AS B ON ( B.DelvSeq = A.SourceSeq AND B.DelvSerl = A.SourceSerl ) 
      --LEFT OUTER JOIN #BLDelvIn         AS C ON ( C.BLSeq = A.SourceSeq AND C.BLSerl = A.SourceSerl ) 
      LEFT OUTER JOIN KPX_TQCTestResult AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = A.PurQCReqSeq AND D.ReqSerl = A.PurQCReqSerl ) 
      OUTER APPLY (SELECT TOP 1 EmpSeq, TestDate
                     FROM KPX_TQCTestResultItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.QCSeq = D.QCSeq 
                   ) E 
      LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = E.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = D.SMTestResult ) 
     WHERE (@SMTestResult = 0 OR D.SMTestResult = @SMTestResult) 
    
    RETURN  
GO 

exec KPX_SPDQCRequestInsPurchaseQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CustSeq />
    <ItemSeq />
    <LotNo />
    <DelvDateFr />
    <DelvDateTo />
    <QCReqDateFr />
    <QCReqDateTo />
    <DelvNo />
    <QCReqEmpSeq />
    <QCReqDeptSeq />
    <BizUnit />
    <UMImpType />
    <SMTestResult />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027256,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022767