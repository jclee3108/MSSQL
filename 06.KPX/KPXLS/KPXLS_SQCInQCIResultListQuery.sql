  
IF OBJECT_ID('KPXLS_SQCInQCIResultListQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultListQuery  
GO  
  
-- v2015.12.17  
  
-- (검사품)수입검사조회-조회 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultListQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemName   NVARCHAR(100), 
            @TestDateFr NCHAR(8), 
            @TestDateTo NCHAR(8), 
            @BizUnit    INT, 
            @ItemNo     NVARCHAR(100), 
            @LotNo      NVARCHAR(100)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemName   = ISNULL( ItemName   , 0 ), 
           @TestDateFr = ISNULL( TestDateFr , 0 ), 
           @TestDateTo = ISNULL( TestDateTo , 0 ), 
           @BizUnit    = ISNULL( BizUnit    , 0 ), 
           @ItemNo     = ISNULL( ItemNo     , 0 ), 
           @LotNo      = ISNULL( LotNo      , 0 )
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemName   NVARCHAR(100),
            TestDateFr NCHAR(8),       
            TestDateTo NCHAR(8),       
            BizUnit    INT,       
            ItemNo     NVARCHAR(100),       
            LotNo      NVARCHAR(100)     
           )    
    
    IF @TestDateTo = '' SELECT @TestDateTo = '99991231'
    
    CREATE TABLE #Result 
    (
        BizUnitName         NVARCHAR(200), 
        BizUnit             INT, 
        TestDate            NCHAR(8), 
        ItemName            NVARCHAR(200), 
        ItemNo              NVARCHAR(200), 
        ItemSeq             INT, 
        LotNo               NVARCHAR(200), 
        SMTestResult        INT, 
        SMTestResultName    NVARCHAR(200), 
        IsCfm               NCHAR(1), 
        CustName            NVARCHAR(200), 
        CustSeq             INT, 
        QCNo                NVARCHAR(200), 
        ReqDate             NCHAR(8), 
        ReqNo               NVARCHAR(200), 
        QCType              INT, 
        QCTypeName          NVARCHAR(200), 
        ExpKindName         NVARCHAR(200), 
        QCSeq               INT 
    )
    
    
    -- 국내 
    INSERT INTO #Result 
    (
        BizUnitName, BizUnit, TestDate, ItemName, ItemNo, 
        ItemSeq, LotNo, SMTestResult, SMTestResultName, IsCfm, 
        CustName, CustSeq, QCNo, ReqDate, ReqNo, 
        QCType, QCTypeName, ExpKindName, QCSeq
    )
    SELECT G.BizUnitName, 
           F.BizUnit, 
           H.TestDate, 
           I.ItemName, 
           I.ItemNo, 
           E.ItemSeq, 
           E.LotNo, 
           A.SMTestResult, 
           J.MinorName AS SMTestResultName, 
           H.IsCfm, 
           K.CustName, 
           F.CustSeq, 
           A.QCNo, 
           C.ReqDate, 
           C.ReqNo, 
           A.QCType, 
           L.QCTypeName, 
           '국내' AS ExpKindName, 
           A.QCSeq
           
      FROM KPX_TQCTestResult                        AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
      LEFT OUTER JOIN KPXLS_TQCRequest              AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq ) 
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = B.ReqSeq AND D.ReqSerl = B.ReqSerl ) 
      LEFT OUTER JOIN _TPUDelvItem                  AS E ON ( E.CompanySeq = @CompanySeq AND E.DelvSeq = B.SourceSeq AND E.DelvSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TPUDelv                      AS F ON ( F.CompanySeq = @CompanySeq AND F.DelvSeq = E.DelvSeq ) 
      LEFT OUTER JOIN _TDABizUnit                   AS G ON ( G.CompanySeq = @CompanySeq AND G.BizUnit = F.BizUnit ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS H ON ( H.CompanySeq = @CompanySeq AND H.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN _TDAItem                      AS I ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = E.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.SMTestResult ) 
      LEFT OUTER JOIN _TDACust                      AS K ON ( K.CompanySeq = @CompanySeq AND K.CustSeq = F.CustSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType        AS L ON ( L.CompanySeq = @CompanySeq AND L.QCType = A.QCType ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND C.SMSourceType = 1000522008 
       AND ( @ItemName = '' OR I.ItemName LIKE @ItemName + '%' ) 
       AND ( H.TestDate BETWEEN @TestDateFr AND @TestDateTo ) 
       AND ( @BizUnit = 0 OR G.BizUnit = @BizUnit ) 
       AND ( @ItemNo = '' OR I.ItemNo LIKE @ItemNo + '%' ) 
       AND ( @LotNo = '' OR E.LotNo LIKE @LotNo + '%' ) 
       
    -- 수입  
    INSERT INTO #Result 
    (
        BizUnitName, BizUnit, TestDate, ItemName, ItemNo, 
        ItemSeq, LotNo, SMTestResult, SMTestResultName, IsCfm, 
        CustName, CustSeq, QCNo, ReqDate, ReqNo, 
        QCType, QCTypeName, ExpKindName, QCSeq
    )
    SELECT G.BizUnitName, 
           F.BizUnit, 
           H.TestDate, 
           I.ItemName, 
           I.ItemNo, 
           E.ItemSeq, 
           E.LotNo, 
           A.SMTestResult, 
           J.MinorName AS SMTestResultName, 
           H.IsCfm, 
           K.CustName, 
           F.CustSeq, 
           A.QCNo, 
           C.ReqDate, 
           C.ReqNo, 
           A.QCType, 
           L.QCTypeName, 
           '수입' AS ExpKindName, 
           A.QCSeq
           
      FROM KPX_TQCTestResult                        AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
      LEFT OUTER JOIN KPXLS_TQCRequest              AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq ) 
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = B.ReqSeq AND D.ReqSerl = B.ReqSerl ) 
      LEFT OUTER JOIN _TUIImpDelvItem               AS E ON ( E.CompanySeq = @CompanySeq AND E.DelvSeq = B.SourceSeq AND E.DelvSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TUIImpDelv                   AS F ON ( F.CompanySeq = @CompanySeq AND F.DelvSeq = E.DelvSeq ) 
      LEFT OUTER JOIN _TDABizUnit                   AS G ON ( G.CompanySeq = @CompanySeq AND G.BizUnit = F.BizUnit ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS H ON ( H.CompanySeq = @CompanySeq AND H.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN _TDAItem                      AS I ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = E.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.SMTestResult ) 
      LEFT OUTER JOIN _TDACust                      AS K ON ( K.CompanySeq = @CompanySeq AND K.CustSeq = F.CustSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType        AS L ON ( L.CompanySeq = @CompanySeq AND L.QCType = A.QCType ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND C.SMSourceType = 1000522007 
       AND ( @ItemName = '' OR I.ItemName LIKE @ItemName + '%' ) 
       AND ( H.TestDate BETWEEN @TestDateFr AND @TestDateTo ) 
       AND ( @BizUnit = 0 OR G.BizUnit = @BizUnit ) 
       AND ( @ItemNo = '' OR I.ItemNo LIKE @ItemNo + '%' ) 
       AND ( @LotNo = '' OR E.LotNo LIKE @LotNo + '%' ) 
    
    SELECT * FROM #Result 
    
    RETURN  
    go
exec KPXLS_SQCInQCIResultListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemName />
    <ItemNo />
    <LotNo />
    <TestDateFr>20151201</TestDateFr>
    <TestDateTo>20151218</TestDateTo>
    <BizUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033877,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028056

--select * from KPXLS_TQCRequestItem where reqseq = 35 

--select *From _TPUDelv where delvseq = 1002125 
--select *From _TPUDelvItem where delvseq = 1002125 and delvserl  = 4 