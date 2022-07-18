
IF OBJECT_ID('KPXLS_SQCCOAPrintQuery') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintQuery
GO 

-- v2015.12.08 
  
-- 시험성적서발행(COA)-조회 by 이재천   
CREATE PROC KPXLS_SQCCOAPrintQuery
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
            @COASeq     INT, 
            @KindSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @COASeq   = ISNULL( COASeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (COASeq   INT)    
    
    SELECT
           Z.COASeq, 
           C.InTestItemName, 
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           G.LowerLimit, 
           G.UpperLimit, 
           E.QCUnitName, 
           B.TestValue, 
           H.Remark AS Remark,
           Z.CustSeq,
           J.CustName,
           Z.COANo,
           Z.ItemSeq,
           I.ItemName,
           I.ItemNo,
           A.LotNo,
           Z.COADate,
           Z.ShipDate,
           Z.COACount, 
           Z.QCSeq, 
           Z.KindSeq, 
           Z.QCType,
           H.QCTypeName,
           --K.EngCustSName AS CustEngName ,
           --L.CustItemName, 
           M.UnitName,
           Z.LifeCycle AS LifeCycle,
           Z.Remark AS MasterRemark,
           G.Remark AS Remark2,
           --B.TestDate AS QCDate,
           B.SMSourceType,
           B.QCSeq,
           Z.QCDate,
           Z.CustEngName,
           Z.DVPlaceSeq,
           Y.DVPlaceName,
           T.CustItemName,
           T.CustItemNo,
           Z.DVPlaceSeq,
           G.Sort, 
           Z.CasNo, 
           Z.TestEmpName, 
           Z.OriWeight, 
           Z.TotWeight, 
           Z.CreateDate, 
           Z.ReTestDate, 
           Z.TestResultDate, 
           C.TestItemGroupName, 
           Z.FromPgmSeq, 
           Z.SourceSeq, 
           Z.SourceSerl, 
           L.MinorName AS SMTestResultName, 
           B.SMTestResult, 
           A.QCNo 
      FROM KPXLS_TQCCOAPrint AS Z 
      LEFT OUTER JOIN KPX_TQCTestResult						AS A ON ( A.CompanySeq = @CompanySeq AND A.QCSeq = Z.QCSeq)-- A.ItemSeq = Z.ItemSeq AND A.LotNo = Z.LotNo AND A.QCType = Z.QCType ) --해당 품목 Lot 검사공정에 대한 검사 결과가 모두 나오도록 수정
      LEFT OUTER JOIN (SELECT QCSeq, TestItemSeq, QAAnalysisType, QCUnit, QCType, MAX(QCSerl) AS QCSerl
                         FROM KPX_TQCTestResultItem 
                        WHERE CompanySeq = @CompanySeq
                        GROUP BY QCSeq, TestItemSeq, QAAnalysisType, QCUnit, QCType
                      ) AS X ON X.QCSeq = A.QCSeq

      LEFT OUTER JOIN KPX_TQCTestResultItem					AS B ON ( Z.CompanySeq = @CompanySeq AND X.QCSeq = B.QCSeq AND B.QCSerl = X.QCSerl)   
      LEFT OUTER JOIN KPX_TQCQATestItems                    AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = B.QCUnit ) 
      --LEFT OUTER JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
      --                                                            AND G.ItemSeq = A.ItemSeq 
      --                                                            AND G.QCType = CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END
      --                                                            AND G.TestItemSeq = B.TestItemSeq 
      --                                                            AND G.QAAnalysisType = D.QAAnalysisType
      --                                                            AND G.QCUnit = E.QCUnit 
      --                                                            AND G.IsProd = '1' 
      --                                                            AND G.CustSeq = Z.CustSeq
						--										  AND (CASE WHEN Z.QCDate = '' THEN '99991231' ELSE Z.QCDate END) BETWEEN G.SDate AND G.EDate
      --                                                            --AND G.DVPlaceSeq = CASE WHEN ISNULL(Z.DVPlaceSeq,0) = 0 THEN G.DVPlaceSeq
      --                                                            --                        ELSE Z.DVPlaceSeq END
      --                                                              )
      LEFT OUTER JOIN KPX_TQCQASpec             AS G ON ( G.CompanySeq = @CompanySeq      
                                                      AND G.ItemSeq = A.ItemSeq      
                                                      AND G.TestItemSeq = B.TestItemSeq      
                                                      AND G.QAAnalysisType = B.QAAnalysisType      
                                                      AND G.QCUnit = B.QCUnit      
                                                      AND CONVERT(NCHAR(8),B.RegDate,112) BETWEEN G.SDate AND G.EDate 
                                                        ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType                AS H ON ( Z.CompanySeq = H.CompanySeq AND  Z.QCtype = H.QCType )
      LEFT OUTER JOIN _TDAItem                              AS I ON ( Z.CompanySeq = I.CompanySeq AND Z.ItemSeq = I.ItemSeq )
      LEFT OUTER JOIN _TDACust								AS J ON ( Z.CompanySeq = J.CompanySeq AND Z.CustSeq = J.CustSeq )
      LEFT OUTER JOIN _TDACustAdd							AS K ON ( K.CompanySeq = Z.CompanySeq AND K.CustSeq = Z.CustSeq ) 
      LEFT OUTER JOIN _TDAUnit								AS M ON ( M.CompanySeq = I.CompanySeq AND M.UnitSeq = I.UnitSeq )  
      LEFT OUTER JOIN _TDAitemStock                         AS N ON ( N.CompanySeq = Z.CompanySeq AND N.ItemSeq = I.ItemSeq )    
      LEFT OUTER JOIN _TSLDeliveryCust                      AS Y ON ( Y.CompanySeq = Z.CompanySeq AND Y.DVPlaceSeq = Z.DVPlaceSeq ) 
      LEFT OUTER JOIN KPX_TSLCustItem                       AS T ON ( T.CompanySeq = Z.CompanySeq
		                                                          AND T.CustSeq = Z.CustSeq
		                                                          AND T.ItemSeq = Z.ItemSeq
		                                                          AND T.DVPlaceSeq = Z.DVPlaceSeq 
		                                                            )
      LEFT OUTER JOIN _TDASMinor                            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = B.SMTestResult ) 
     WHERE Z.CompanySeq = @CompanySeq  
       AND Z.COASeq = @COASeq 
       --AND (ISNULL(G.DVPlaceSeq,0) = 0 OR ISNULL(G.DVPlaceSeq,0) = CASE WHEN ISNULL(Z.DVPlaceSeq,0) = 0 THEN 0
       --                                      ELSE Z.DVPlaceSeq END)
     ORDER BY G.Sort,G.Serl
    
    RETURN  
GO

exec KPXLS_SQCCOAPrintQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <COASeq>6</COASeq>
    <SMSourceType />
    <SMSourceTypeName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033540,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028324