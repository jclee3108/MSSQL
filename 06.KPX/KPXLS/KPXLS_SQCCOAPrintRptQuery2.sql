IF OBJECT_ID('KPXLS_SQCCOAPrintRptQuery2') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintRptQuery2
GO 

-- v2015.12.28 
  
-- 시험성적서발행(COA)-출력2 by 이재천   
CREATE PROC KPXLS_SQCCOAPrintRptQuery2
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
            @COASeq     INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @COASeq   = ISNULL( COASeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (COASeq   INT)    
    
    
    SELECT ROW_NUMBER() OVER(ORDER BY ISNULL(C.TestItemGroupName,''),G.Sort) AS IDX_NO, 
           C.OutTestItemName, 
           Z.ShipDate, 
           CASE WHEN ISNULL(T.CustItemName,'') = '' THEN I.ItemName ELSE T.CustItemName END AS ItemName, 
           Z.CasNo, 
           A.LotNo, 
           CASE WHEN G.SMInputType = 1018001 THEN CONVERT(NVARCHAR(100),B.TestValue) + ' ' + E.QCUnitName ELSE B.TestValue END AS TestValue, 
           D.QAAnalysisTypeName AS AnalysisName, 
           CASE WHEN G.SMInputType = 1018002 THEN G.UpperLimit 
                WHEN 'min ' + G.UpperLimit = '' THEN G.LowerLimit + ' ' + E.QCUnitName 
                WHEN 'max ' + G.LowerLimit = '' THEN G.LowerLimit + ' ' + E.QCUnitName 
                WHEN G.LowerLimit <> '' AND G.UpperLimit <> '' THEN G.LowerLimit + ' ~ ' + G.UpperLimit + ' ' + E.QCUnitName 
                ELSE '' 
                END AS SpecSub, 
           Z.OriWeight + Z.TotWeight AS TotWeight
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
                 --JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
                 --                                                 AND G.ItemSeq = A.ItemSeq 
                 --                                                 AND G.QCType = CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END
                 --                                                 AND G.TestItemSeq = B.TestItemSeq 
                 --                                                 AND G.QAAnalysisType = D.QAAnalysisType
                 --                                                 AND G.QCUnit = E.QCUnit 
                 --                                                 AND G.IsProd = '1' 
                 --                                                 AND G.CustSeq = Z.CustSeq
																 -- AND (CASE WHEN Z.QCDate = '' THEN '99991231' ELSE Z.QCDate END) BETWEEN G.SDate AND G.EDate
                 --                                                 --AND G.DVPlaceSeq = CASE WHEN ISNULL(Z.DVPlaceSeq,0) = 0 THEN G.DVPlaceSeq
                 --                                                 --                        ELSE Z.DVPlaceSeq END
                 --                                                   )
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
     WHERE Z.CompanySeq = @CompanySeq  
       AND Z.COASeq = @COASeq 
       --AND (ISNULL(G.DVPlaceSeq,0) = 0 OR ISNULL(G.DVPlaceSeq,0) = CASE WHEN ISNULL(Z.DVPlaceSeq,0) = 0 THEN 0
       --                                      ELSE Z.DVPlaceSeq END)
    
    RETURN  
GO

exec KPXLS_SQCCOAPrintRptQuery2 @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <COASeq>5</COASeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033540,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027778