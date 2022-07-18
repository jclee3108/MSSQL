  
IF OBJECT_ID('KPXLS_SQCInQCIResultQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultQuery  
GO  
  
-- v2015.12.15  
  
-- (검사품)수입검사등록-조회 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultQuery  
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
            @QCSeq          INT, 
            @SMSourceType   INT 
            
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QCSeq   = ISNULL( QCSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (QCSeq   INT)    
    
    
    
    SELECT @SMSourceType = C.SMSourceType 
      FROM KPX_TQCTestResult AS A 
      LEFT OUTER JOIN KPXLS_TQCRequestItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
      LEFT OUTER JOIN KPXLS_TQCRequest      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.QCSeq = @QCSeq 
    
    
    IF @SMSourceType = 1000522008 
    BEGIN 
        -- 최종조회   
        SELECT A.QCSeq, 
               A.QCNo, 
               C.TestDate AS QCDate, 
               B.SCDate, 
               B.SCAmount, 
               B.SCEmpName, 
               B.SCPackage, 
               B.IsCfm, 
               CASE WHEN B.IsCfm = '1' THEN B.CfmDateTime ELSE '' END AS CfmDate, 
               A.OKQty, 
               A.BadQty, 
               D.EmpName AS CfmEmpName, 
               B.SCRocate, 
               B.UseItemName, 
               A.SMTestResult AS UMQcType, 
               E.MinorName AS UMQcTypeName, 
               
               K.BizUnitName, 
               J.BizUnit, 
               '국내' AS ExpKindName, 
               G.ReqDate, 
               G.ReqNo, 
               A.QCType, 
               I.LotNo, 
               M.ItemName, 
               M.ItemNo, 
               I.ItemSeq, 
               I.Qty AS DelvTotQty, 
               N.UnitName, 
               O.EmpName, 
               P.DeptName, 
               Q.CustName, 
               J.DelvNo, 
               J.DelvDate, 
               L.MakerLotNo, 
               L.CreateDate, 
               L.ValiDate,
               R.Storage, 
               R.CarNo, 
               R.CreateCustName, 
               R.QCReqList, 
               F.ReqSeq, 
               F.ReqSerl,
               G.Remark
          FROM KPX_TQCTestResult                    AS A 
          LEFT OUTER JOIN KPXLS_TQCTestResultAdd    AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
          OUTER APPLY (
                        SELECT TOP 1 TestDate
                          FROM KPX_TQCTestResultItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.QCSeq = A.QCSeq 
                      ) AS C 
          LEFT OUTER JOIN _TDAEmp                       AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.CfmEmpSeq ) 
          LEFT OUTER JOIN _TDAUMinor                    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMTestResult ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItem          AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = A.ReqSeq AND F.ReqSerl = A.ReqSerl ) 
          LEFT OUTER JOIN KPXLS_TQCRequest              AS G ON ( G.CompanySeq = @CompanySeq AND G.ReqSeq = F.ReqSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS H ON ( H.CompanySeq = @CompanySeq AND H.ReqSeq = F.ReqSeq AND H.ReqSerl = F.ReqSerl ) 
          LEFT OUTER JOIN _TPUDelvItem                  AS I ON ( I.CompanySeq = @CompanySeq AND I.DelvSeq = F.SourceSeq AND I.DelvSerl = F.SourceSerl ) 
          LEFT OUTER JOIN _TPUDelv                      AS J ON ( J.CompanySeq = @CompanySeq AND J.DelvSeq = I.DelvSeq ) 
          LEFT OUTER JOIN _TDABizUnit                   AS K ON ( K.CompanySeq = @CompanySeq AND K.BizUnit = J.BizUnit ) 
          LEFT OUTER JOIN KPXLS_TPUDelvItemAdd          AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = I.DelvSeq AND L.DelvSerl = I.DelvSerl ) 
          LEFT OUTER JOIN _TDAItem                      AS M ON ( M.CompanySeq = @CompanySeq AND M.ItemSeq = I.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit                      AS N ON ( N.CompanySeq = @CompanySeq AND N.UnitSeq = I.UnitSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = G.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                      AS P ON ( P.COmpanySeq = @CompanySeq AND P.DeptSeq = G.DeptSeq ) 
          LEFT OUTER JOIN _TDACust                      AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.CustSeq = J.CustSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR       AS R ON ( R.CompanySeq = @CompanySeq AND R.ReqSeq = G.ReqSeq ) 
        
         WHERE A.CompanySeq = @CompanySeq  
           AND A.QCSeq = @QCSeq 
           AND G.SMSourceType = 1000522008
    END 
    ELSE
    BEGIN
        -- 최종조회   
        SELECT A.QCSeq, 
               A.QCNo, 
               C.TestDate AS QCDate, 
               B.SCDate, 
               B.SCAmount, 
               B.SCEmpName, 
               B.SCPackage, 
               B.IsCfm, 
               CASE WHEN B.IsCfm = '1' THEN B.CfmDateTime ELSE '' END AS CfmDate, 
               A.OKQty, 
               A.BadQty, 
               D.EmpName AS CfmEmpName, 
               B.SCRocate, 
               B.UseItemName, 
               A.SMTestResult AS UMQcType, 
               E.MinorName AS UMQcTypeName, 
               
               K.BizUnitName, 
               J.BizUnit, 
               '수입' AS ExpKindName, 
               G.ReqDate, 
               G.ReqNo, 
               A.QCType, 
               I.LotNo, 
               M.ItemName, 
               M.ItemNo, 
               I.ItemSeq, 
               I.Qty AS DelvTotQty, 
               N.UnitName, 
               O.EmpName, 
               P.DeptName, 
               Q.CustName, 
               J.DelvNo, 
               J.DelvDate, 
               I.Memo1 AS MakerLotNo, 
               '' AS CreateDate, 
               I.Memo2 AS ValiDate,
               R.Storage, 
               R.CarNo, 
               R.CreateCustName, 
               R.QCReqList, 
               F.ReqSeq, 
               F.ReqSerl,
               G.Remark
          FROM KPX_TQCTestResult                    AS A 
          LEFT OUTER JOIN KPXLS_TQCTestResultAdd    AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
          OUTER APPLY (
                        SELECT TOP 1 TestDate
                          FROM KPX_TQCTestResultItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.QCSeq = A.QCSeq 
                      ) AS C 
          LEFT OUTER JOIN _TDAEmp                       AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.CfmEmpSeq ) 
          LEFT OUTER JOIN _TDAUMinor                    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMTestResult ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItem          AS F ON ( F.CompanySeq = @CompanySeq AND F.ReqSeq = A.ReqSeq AND F.ReqSerl = A.ReqSerl ) 
          LEFT OUTER JOIN KPXLS_TQCRequest              AS G ON ( G.CompanySeq = @CompanySeq AND G.ReqSeq = F.ReqSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PUR   AS H ON ( H.CompanySeq = @CompanySeq AND H.ReqSeq = F.ReqSeq AND H.ReqSerl = F.ReqSerl ) 
          LEFT OUTER JOIN _TUIImpDelvItem               AS I ON ( I.CompanySeq = @CompanySeq AND I.DelvSeq = F.SourceSeq AND I.DelvSerl = F.SourceSerl ) 
          LEFT OUTER JOIN _TUIImpDelv                   AS J ON ( J.CompanySeq = @CompanySeq AND J.DelvSeq = I.DelvSeq ) 
          LEFT OUTER JOIN _TDABizUnit                   AS K ON ( K.CompanySeq = @CompanySeq AND K.BizUnit = J.BizUnit ) 
          --LEFT OUTER JOIN KPXLS_TPUDelvItemAdd          AS L ON ( L.CompanySeq = @CompanySeq AND L.DelvSeq = I.DelvSeq AND L.DelvSerl = I.DelvSerl ) 
          LEFT OUTER JOIN _TDAItem                      AS M ON ( M.CompanySeq = @CompanySeq AND M.ItemSeq = I.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit                      AS N ON ( N.CompanySeq = @CompanySeq AND N.UnitSeq = I.UnitSeq ) 
          LEFT OUTER JOIN _TDAEmp                       AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = G.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                      AS P ON ( P.COmpanySeq = @CompanySeq AND P.DeptSeq = G.DeptSeq ) 
          LEFT OUTER JOIN _TDACust                      AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.CustSeq = J.CustSeq ) 
          LEFT OUTER JOIN KPXLS_TQCRequestAdd_PUR       AS R ON ( R.CompanySeq = @CompanySeq AND R.ReqSeq = G.ReqSeq ) 
        
         WHERE A.CompanySeq = @CompanySeq  
           AND A.QCSeq = @QCSeq 
           AND G.SMSourceType = 1000522007
    END 
        
    RETURN  
GO
exec KPXLS_SQCInQCIResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QCSeq>188</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027993