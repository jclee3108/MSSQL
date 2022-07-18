IF OBJECT_ID('KPXLS_SQCInQCIResultpRrint') IS NOT NULL 
    DROP PROC KPXLS_SQCInQCIResultpRrint
GO 

-- v2015.12.15      
      
-- (검사품)수입검사등록-조회 by 이재천       
CREATE PROC KPXLS_SQCInQCIResultpRrint      
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
            @QCSeq      INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
          
    SELECT @QCSeq   = ISNULL( QCSeq, 0 ) 
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )           
      WITH (QCSeq     INT)        
    
    CREATE TABLE #Result 
    (
        ItemName        NVARCHAR(200), 
        QCNo            NVARCHAR(200), 
        QCSeq           INT, 
        DelvDate        NCHAR(8), 
        SCDate          NCHAR(8), 
        SCAmount        NVARCHAR(200), 
        SCEmpName       NVARCHAR(200), 
        SCPackage       NVARCHAR(200), 
        SCRocate        NVARCHAR(200), 
        UseItemName     NVARCHAR(200), 
        ReqNo           NVARCHAR(200), 
        LotNo           NVARCHAR(200), 
        DelvTotQty      DECIMAL(19,5), 
        CreateCustName  NVARCHAR(200), 
        InTestItemName  NVARCHAR(200), 
        TestBase        NVARCHAR(200), 
        TestResult      NVARCHAR(200), 
        QCDate          NCHAR(8), 
        EmpName         NVARCHAR(200), 
        SMTestResultName    NVARCHAR(200)
    )
    
    
    
    -- 내수 
    INSERT INTO #Result 
    (
        ItemName, QCNo, QCSeq, DelvDate, SCDate, 
        SCAmount, SCEmpName, SCPackage, SCRocate, UseItemName, 
        ReqNo, LotNo, DelvTotQty, CreateCustName, InTestItemName, 
        TestBase, TestResult, QCDate, EmpName, SMTestResultName    
    )
    SELECT 
           M.ItemName, 
           A.QCNo, 
           A.QCSeq, 
           J.DelvDate,   
           B.SCDate,   
           B.SCAmount,   
           B.SCEmpName,   
           B.SCPackage,   
           B.SCRocate,   
           B.UseItemName,  
           G.ReqNo,   
           I.LotNo,   
           I.Qty AS DelvTotQty,   
           R.CreateCustName, 
           
           P.InTestItemName, -- 시험항목 
           CASE WHEN S.SMInputType = 1018002 THEN S.UpperLimit
                WHEN S.SMInputType = 1018001 AND ISNULL(S.UpperLimit,'') = '' THEN S.LowerLimit + ' ' + E.QCUnitName + ' Min'
                WHEN S.SMInputType = 1018001 AND ISNULL(S.LowerLimit,'') = '' THEN S.UpperLimit + ' ' + E.QCUnitName + ' Max'
                WHEN S.SMInputType = 1018001 AND ISNULL(S.LowerLimit,'') <> '' AND ISNULL(S.UpperLimit,'') <> '' THEN S.LowerLimit + ' ~ ' + S.UpperLimit + ' ' + E.QCUnitName 
                END AS TestBase, 
                
           CASE WHEN S.SMInputType = 1018002 THEN O.TestValue
                ELSE O.TestValue + ' ' + E.QCUnitName 
                END AS TestResult, 
           B.TestDate AS QCDate, 
           Q.EmpName, 
           CASE WHEN O.IsSpecial = '1' THEN '특'
                WHEN O.SMTestResult =  6035003 THEN '합' 
                WHEN O.SMTestResult = 6035004 THEN '불' 
                END AS SMTestResultName
           
           
      FROM KPX_TQCTestResult                        AS A   
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq )     
      LEFT OUTER JOIN KPXLS_TQCRequestItem          AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = A.ReqSeq AND F.ReqSerl = A.ReqSerl )   
      LEFT OUTER JOIN KPXLS_TQCRequest              AS G ON ( G.CompanySeq = @CompanySeq AND G.ReqSeq = F.ReqSeq )   
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS H ON ( H.CompanySeq = @CompanySeq AND H.ReqSeq = F.ReqSeq AND H.ReqSerl = F.ReqSerl )   
      LEFT OUTER JOIN _TPUDelvItem                  AS I ON ( I.CompanySeq = @CompanySeq AND I.DelvSeq = F.SourceSeq AND I.DelvSerl = F.SourceSerl )   
      LEFT OUTER JOIN _TPUDelv                      AS J ON ( J.CompanySeq = @CompanySeq AND J.DelvSeq = I.DelvSeq )   
      LEFT OUTER JOIN KPXLS_TPUDelvItemAdd          AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = I.DelvSeq AND L.DelvSerl = I.DelvSerl )   
      LEFT OUTER JOIN _TDAItem                      AS M ON ( M.CompanySeq = @CompanySeq AND M.ItemSeq = I.ItemSeq )   
      LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR       AS R ON ( R.CompanySeq = @CompanySeq AND R.ReqSeq = G.ReqSeq )   
      LEFT OUTER JOIN KPX_TQCTestResultItem         AS O ON ( O.CompanySeq = @CompanySeq AND O.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPX_TQCQATestItems            AS P ON ( P.CompanySeq = @CompanySeq AND P.TestItemSeq = O.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQASpec                 AS S ON ( S.CompanySeq   = @CompanySeq    
                                                          AND A.ItemSeq = S.ItemSeq    
                                                          AND O.TestItemSeq = S.TestItemSeq    
                                                          AND O.QAAnalysisType = S.QAAnalysisType    
                                                          AND O.QCUnit = S.QCUnit    
                                                          AND CONVERT(NCHAR(8),O.RegDate,112) BETWEEN S.SDate AND S.EDate  
                                                          AND S.QCType = CASE WHEN ISNULL(A.QCType, 0) = 0 THEN O.QCType ELSE A.QCType END  
                                                            )
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit        AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = O.QCUnit ) 
      LEFT OUTER JOIN _TDAEmp                       AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.EmpSeq = O.RegEmpSeq ) 
      LEFT OUTER JOIN _TDASMinor                    AS T ON ( T.CompanySeq = @CompanySeq AND T.MinorSeq = O.SMTestResult ) 
        
     WHERE A.CompanySeq = @CompanySeq    
       AND A.QCSeq = @QCSeq   
       AND G.SMSourceType = 1000522008  
    
    -- 수입 
    INSERT INTO #Result 
    (
        ItemName, QCNo, QCSeq, DelvDate, SCDate, 
        SCAmount, SCEmpName, SCPackage, SCRocate, UseItemName, 
        ReqNo, LotNo, DelvTotQty, CreateCustName, InTestItemName, 
        TestBase, TestResult, QCDate, EmpName, SMTestResultName    
    )
    SELECT 
           M.ItemName, 
           A.QCNo, 
           A.QCSeq, 
           J.DelvDate,   
           B.SCDate,   
           B.SCAmount,   
           B.SCEmpName,   
           B.SCPackage,   
           B.SCRocate,   
           B.UseItemName,  
           G.ReqNo,   
           I.LotNo,   
           I.Qty AS DelvTotQty,   
           R.CreateCustName, 
           
           P.InTestItemName, -- 시험항목 
           CASE WHEN S.SMInputType = 1018002 THEN S.UpperLimit
                WHEN S.SMInputType = 1018001 AND ISNULL(S.UpperLimit,'') = '' THEN S.LowerLimit + ' ' + E.QCUnitName + ' Min'
                WHEN S.SMInputType = 1018001 AND ISNULL(S.LowerLimit,'') = '' THEN S.UpperLimit + ' ' + E.QCUnitName + ' Max'
                WHEN S.SMInputType = 1018001 AND ISNULL(S.LowerLimit,'') <> '' AND ISNULL(S.UpperLimit,'') <> '' THEN S.LowerLimit + ' ~ ' + S.UpperLimit + ' ' + E.QCUnitName 
                END AS TestBase, 
                
           CASE WHEN S.SMInputType = 1018002 THEN O.TestValue
                ELSE O.TestValue + ' ' + E.QCUnitName 
                END AS TestResult, 
           B.TestDate AS QCDate, 
           Q.EmpName, 
           CASE WHEN O.IsSpecial = '1' THEN '특'
                WHEN O.SMTestResult =  6035003 THEN '합' 
                WHEN O.SMTestResult = 6035004 THEN '불' 
                END AS SMTestResultName
           
           
      FROM KPX_TQCTestResult                        AS A   
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq )     
      LEFT OUTER JOIN KPXLS_TQCRequestItem          AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = A.ReqSeq AND F.ReqSerl = A.ReqSerl )   
      LEFT OUTER JOIN KPXLS_TQCRequest              AS G ON ( G.CompanySeq = @CompanySeq AND G.ReqSeq = F.ReqSeq )   
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS H ON ( H.CompanySeq = @CompanySeq AND H.ReqSeq = F.ReqSeq AND H.ReqSerl = F.ReqSerl )   
      LEFT OUTER JOIN _TUIImpDelvItem               AS I ON ( I.CompanySeq = @CompanySeq AND I.DelvSeq = F.SourceSeq AND I.DelvSerl = F.SourceSerl )   
      LEFT OUTER JOIN _TUIImpDelv                   AS J ON ( J.CompanySeq = @CompanySeq AND J.DelvSeq = I.DelvSeq )   
      LEFT OUTER JOIN KPXLS_TPUDelvItemAdd          AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = I.DelvSeq AND L.DelvSerl = I.DelvSerl )   
      LEFT OUTER JOIN _TDAItem                      AS M ON ( M.CompanySeq = @CompanySeq AND M.ItemSeq = I.ItemSeq )   
      LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR       AS R ON ( R.CompanySeq = @CompanySeq AND R.ReqSeq = G.ReqSeq )   
      LEFT OUTER JOIN KPX_TQCTestResultItem         AS O ON ( O.CompanySeq = @CompanySeq AND O.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPX_TQCQATestItems            AS P ON ( P.CompanySeq = @CompanySeq AND P.TestItemSeq = O.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQASpec                 AS S ON ( S.CompanySeq   = @CompanySeq    
                                                          AND A.ItemSeq = S.ItemSeq    
                                                          AND O.TestItemSeq = S.TestItemSeq    
                                                          AND O.QAAnalysisType = S.QAAnalysisType    
                                                          AND O.QCUnit = S.QCUnit    
                                                          AND CONVERT(NCHAR(8),O.RegDate,112) BETWEEN S.SDate AND S.EDate  
                                                          AND S.QCType = CASE WHEN ISNULL(A.QCType, 0) = 0 THEN O.QCType ELSE A.QCType END  
                                                            )
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit        AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = O.QCUnit ) 
      LEFT OUTER JOIN _TDAEmp                       AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.EmpSeq = O.RegEmpSeq ) 
      LEFT OUTER JOIN _TDASMinor                    AS T ON ( T.CompanySeq = @CompanySeq AND T.MinorSeq = O.SMTestResult ) 
        
     WHERE A.CompanySeq = @CompanySeq    
       AND A.QCSeq = @QCSeq   
       AND G.SMSourceType = 1000522007 
    
    
    SELECT * FROM #Result 
    
    
    
      RETURN     
      go
begin tran 
exec KPXLS_SQCInQCIResultpRrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QCSeq>23</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027993
rollback 



--select * from sysobjects where name like '[_]T%Delv%'