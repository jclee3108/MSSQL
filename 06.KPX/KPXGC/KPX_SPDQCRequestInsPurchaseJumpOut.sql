
IF OBJECT_ID('KPX_SPDQCRequestInsPurchaseJumpOut') IS NOT NULL 
    DROP PROC KPX_SPDQCRequestInsPurchaseJumpOut
GO 

-- v2015.01.15 
    
-- 수입검사의뢰조회-점프조회 by 이재천   
CREATE PROC KPX_SPDQCRequestInsPurchaseJumpOut
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
            @PurQCReqSeq    INT, 
            @ItemSeq        INT, 
            @QCType         INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @PurQCReqSeq = ISNULL( PurQCReqSeq, 0 ), 
           @ItemSeq = ISNULL( ItemSeq, 0), 
           @QCType = ISNULL( QCType, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PurQCReqSeq     INT, 
            ItemSeq         INT, 
            QCType          INT 
           )    
    
    IF NOT EXISTS ( SELECT 1 
                      FROM KPX_TQCTestResult AS A 
                      JOIN KPX_TQCTestResultItem AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq )
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.ReqSeq = A.ReqSeq 
                       AND A.QCtype = @QCType 
                       AND A.ItemSeq = @ItemSeq 
                  ) -- 신규 점프 
    BEGIN 
        
        SELECT A.ReqSeq AS ReqSeq, 
               B.ReqSerl AS ReqSerl, 
               A.ReqNo AS ReqNo, 
               CASE WHEN B.SMSourceType = 1000522007 THEN '수입' WHEN B.SMSourceType = 1000522008 THEN '국내' ELSE '' END AS InOutType, 
               A.CustSeq AS CustSeq, 
               D.CustName AS CustName, 
               CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLDate,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvDate,'') ELSE '' END AS DelvDate, 
               CASE WHEN B.SMSourceType = 1000522007 THEN ISNULL(I.BLNo,'') WHEN B.SMSourceType = 1000522008 THEN ISNULL(H.DelvNo,'') ELSE '' END AS DelvNo, 
               B.ReqQty AS Qty, 
               B.LotNo AS LotNo, 
               A.ReqDate AS ReqDate, 
               B.ItemSeq, 
               G.ItemName, 
               G.ItemNo, 
               G.Spec, 
               B.QCType, 
               J.QCTypeName, 
               A.BizUnit, 
               C.BizUnitName, 
               E.EmpName, 
               F.DeptName 
          FROM KPX_TQCTestRequest                   AS A 
          LEFT OUTER JOIN KPX_TQCTestRequestItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq ) 
          LEFT OUTER JOIN _TDABizUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = A.BizUnit ) 
          LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TDAEmp                   AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TDADept                  AS F ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TDAItem                  AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TPUDelv                  AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = B.SourceSeq ) 
          LEFT OUTER JOIN _TUIImpBL                 AS I ON ( I.CompanySeq = @CompanySeq AND I.BLSeq = B.SourceSeq )
          LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS J ON ( J.CompanySeq = @CompanySeq AND J.QCType = B.QCType ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND ( A.ReqSeq = @PurQCReqSeq ) 
           AND ( B.QCType = @QCType ) 
           AND ( B.ItemSeq = @ItemSeq ) 
        
        SELECT ISNULL(D.TestItemName,'') AS TestItemName, 
               ISNULL(D.TestItemSeq,0) AS TestItemSeq, 
               E.QAAnalysisType AS QAAnalysisType, 
               E.QAAnalysisTypeName AS QAAnalysisName, 
               F.QCUnit, 
               F.QCUnitName, 
               C.SMInputType, 
               G.MinorName AS SMInputTypeName, 
               C.LowerLimit, 
               C.UpperLimit, 
               '0' AS IsExists 
          FROM KPX_TQCTestRequestItem               AS B 
          LEFT OUTER JOIN KPX_TQCTestRequest        AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
          LEFT OUTER JOIN KPX_TQCQASpec             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.QCType = B.QCType AND A.ReqDate BETWEEN C.SDate AND C.EDate ) 
          LEFT OUTER JOIN KPX_TQCQATestItems        AS D ON ( D.CompanySeq = @CompanySeq AND D.TestItemSeq = C.TestItemSeq ) 
          LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON ( E.CompanySeq = @CompanySeq AND E.QAAnalysisType = C.QAAnalysisType ) 
          LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS F ON ( F.CompanySeq = @CompanySeq AND F.QCUnit = C.QCUnit ) 
          LEFT OUTER JOIN _TDASMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.SMInputType ) 
         WHERE B.CompanySeq = @CompanySeq  
           AND ( B.ReqSeq = @PurQCReqSeq ) 
           AND ( B.QCType = @QCType ) 
           AND ( B.ItemSeq = @ItemSeq ) 
           AND ( C.QCType IS NOT NULL OR C.QCType <> 0 )
    
    END 
    ELSE
    BEGIN -- 기존데이터 
        
        SELECT A.QCSeq AS InQCSeq    
          FROM KPX_TQCTestResult                    AS A    
          LEFT OUTER JOIN _TDAItem                  AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq     
          LEFT OUTER JOIN _TDAUMinor                AS C ON A.CompanySeq = C.CompanySeq AND A.SMTestResult = C.MinorSeq    
          LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS D ON ( D.CompanySeq = @CompanySeq AND D.QCType = A.QCType )   
         WHERE A.CompanySeq = @CompanySeq    
           AND A.ReqSeq = @PurQCReqSeq 
           AND A.QCtype = @QCType 
           AND A.ItemSeq = @ItemSeq 
        
        SELECT TOP 1 '1' AS IsExists 
          FROM KPX_TQCTestResultItem        AS A    
          LEFT OUTER JOIN KPX_TQCTestResult AS M ON A.CompanySeq = M.CompanySeq AND A.QCSeq = M.QCSeq    
         WHERE A.CompanySeq = @CompanySeq 
           AND M.ReqSeq = @PurQCReqSeq 
           AND M.QCtype = @QCType 
           AND M.ItemSeq = @ItemSeq 
    
    END 
    
    RETURN  

GO 
exec KPX_SPDQCRequestInsPurchaseJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>23319</ItemSeq>
    <PurQCReqSeq>11</PurQCReqSeq>
    <QCType>0</QCType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027256,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022767