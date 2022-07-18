  
IF OBJECT_ID('KPXLS_SQCProInspRequestItemQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCProInspRequestItemQuery 
GO  
  
-- v2015.12.08  
  
-- (검사품)수입검사의뢰-디테일조회 by 이재천   
CREATE PROC KPXLS_SQCProInspRequestItemQuery  
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
            @DelvSeq    INT, 
            @ItemSeq    INT, 
            @ExpKind    INT, -- 1 내수 , 2 수입 
            @IsPass     NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvSeq   = ISNULL( DelvSeq, 0 ), 
           @ItemSeq   = ISNULL( ItemSeq, 0 ), 
           @ExpKind   = ISNULL( ExpKind, 0 ), 
           @IsPass    = ISNULL( IsPass, '0' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DelvSeq     INT, 
            ItemSeq     INT, 
            ExpKind     INT, 
            IsPass      NCHAR(1) 
           )    
    
    CREATE TABLE #Result 
    (
        IsQCRequest     NCHAR(1), 
        IsPass          NCHAR(1), 
        LotNo           NVARCHAR(100), 
        MakerLotNo      NVARCHAR(100), 
        CreateDate      NCHAr(8), 
        ValiDate        NCHAR(8), 
        DelvQty         DECIMAL(19,5), 
        DelvSeq         INT, 
        DelvSerl        INT, 
        SMTestResult    INT, 
        SMTestResultName NVARCHAR(100), 
        ReqSeq          INT, 
        ReqSerl         INT, 
        UMQcTypeName    NVARCHAR(100), 
        UMQcType        INT 
    )
    
    
    
    IF @ExpKind = 1 
    BEGIN  
        -- 최종조회   
        INSERT INTO #Result 
        (
            IsQCRequest, IsPass, LotNo, MakerLotNo, CreateDate, 
            ValiDate, DelvQty, DelvSeq, DelvSerl, SMTestResult, 
            SMTestResultName, ReqSeq, ReqSerl, UMQcTypeName, UMQcType 
        )
        SELECT CASE WHEN E.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsQCRequest, 
               C.IsPass, 
               --G.MinorName AS UMQcTypeName, 
               B.LotNo, 
               C.MakerLotNo, 
               C.CreateDate, 
               C.ValiDate, 
               B.Qty AS DelvQty, 
               B.DelvSeq, 
               B.DelvSerl, 
               I.SMTestResult, 
               J.MinorName AS SMTestResultName, 
               --B.QCQty AS OkQty, 
               --B.BadQty, 
               D.ReqSeq, 
               E.ReqSerl, 
               CONVERT(NVARCHAR(100),'') AS UMQcTypeName, 
               CONVERT(INT,0) AS UMQcType
          FROM _TPUDelv                         AS A 
                     JOIN _TPUDelvItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
          LEFT OUTER JOIN KPXLS_TPUDelvItemAdd  AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.DelvSeq AND C.DelvSerl = B.DelvSerl ) 
          LEFT OUTER JOIN KPXLS_TQCRequest      AS D ON ( D.CompanySeq = @CompanySeq AND D.SourceSeq = A.DelvSeq AND SMSourceType = 1000522008 AND D.PgmSeq = CASE WHEN C.IsPass = '1' THEN 1027881 ELSE 1027845 END ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItem  AS E ON ( E.CompanySeq = @CompanySeq AND E.ReqSeq = D.ReqSeq AND E.SourceSeq = B.DelvSeq AND E.SourceSerl = B.DelvSerl ) 
          LEFT OUTER JOIN KPX_TQCTestResult     AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = E.ReqSeq AND F.ReqSerl = E.ReqSerl ) 
          LEFT OUTER JOIN _TLGLotMaster         AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = B.ItemSeq AND H.LotNo = B.LotNo ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR AS I ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = E.ReqSeq AND I.ReqSerl = E.ReqSerl ) 
          LEFT OUTER JOIN _TDAUMinor            AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = I.SMTestResult ) 
        
         WHERE A.CompanySeq = @CompanySeq  
           AND A.DelvSeq = @DelvSeq 
           AND B.ItemSeq = @ItemSeq 
           AND C.IsPass = @IsPass 
           AND (E.PgmSeq IS NULL OR E.PgmSeq = @PgmSeq)
    END 
    ELSE
    BEGIN
        
        -- 최종조회   
        INSERT INTO #Result 
        (
            IsQCRequest, IsPass, LotNo, MakerLotNo, CreateDate, 
            ValiDate, DelvQty, DelvSeq, DelvSerl, SMTestResult, 
            SMTestResultName, ReqSeq, ReqSerl, UMQcTypeName, UMQcType 
        )
        SELECT CASE WHEN E.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsQCRequest, 
               B.Memo3 AS IsPass, 
               --G.MinorName AS UMQcTypeName, 
               B.LotNo, 
               B.Memo1 AS MakerLotNo, 
               B.ProdDate AS CreateDate, 
               B.Memo2 AS ValiDate, 
               B.Qty AS DelvQty, 
               B.DelvSeq, 
               B.DelvSerl, 
               I.SMTestResult, 
               J.MinorName AS SMTestResultName, 
               --B.QCQty AS OkQty, 
               --B.BadQty, 
               D.ReqSeq, 
               E.ReqSerl, 
               CONVERT(NVARCHAR(100),'') AS UMQcTypeName, 
               CONVERT(INT,0) AS UMQcType
          FROM _TUIImpDelv                      AS A 
                     JOIN _TUIImpDelvItem       AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequest      AS D ON ( D.CompanySeq = @CompanySeq AND D.SourceSeq = A.DelvSeq AND SMSourceType = 1000522007 AND D.PgmSeq = CASE WHEN B.Memo3 = '1' THEN 1027881 ELSE 1027845 END ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItem  AS E ON ( E.CompanySeq = @CompanySeq AND E.ReqSeq = D.ReqSeq AND E.SourceSeq = B.DelvSeq AND E.SourceSerl = B.DelvSerl ) 
          LEFT OUTER JOIN KPX_TQCTestResult     AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = E.ReqSeq AND F.ReqSerl = E.ReqSerl ) 
          LEFT OUTER JOIN _TLGLotMaster         AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = B.ItemSeq AND H.LotNo = B.LotNo ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR AS I ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = E.ReqSeq AND I.ReqSerl = E.ReqSerl ) 
          LEFT OUTER JOIN _TDAUMinor            AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = I.SMTestResult ) 
        
         WHERE A.CompanySeq = @CompanySeq  
           AND A.DelvSeq = @DelvSeq 
           AND B.ItemSeq = @ItemSeq 
           AND B.Memo3 = @IsPass 
           AND (E.PgmSeq IS NULL OR E.PgmSeq = @PgmSeq)
    END 
    
    
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
    
    SELECT *
      FROM #Result 
    
    RETURN  
    go
exec KPXLS_SQCProInspRequestItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DelvSeq>1000182</DelvSeq>
    <ItemSeq>27375</ItemSeq>
    <ExpKind>2</ExpKind>
    <IsPass>0</IsPass>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033628,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027845