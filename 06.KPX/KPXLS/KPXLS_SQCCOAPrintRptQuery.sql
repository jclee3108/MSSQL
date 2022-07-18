
IF OBJECT_ID('KPXLS_SQCCOAPrintRptQuery') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintRptQuery
GO 

-- v2015.12.24 
  
-- 시험성적서발행(COA)-출력 by 이재천   
CREATE PROC KPXLS_SQCCOAPrintRptQuery
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
           Z.COASeq, 
           C.InTestItemName, 
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           G.SMInputType, 
           G.LowerLimit, 
           G.UpperLimit, 
           E.QCUnitName, 
           B.TestValue, 
           H.Remark AS Remark,
           Z.CustSeq,
           CASE WHEN ISNULL(K.EngCustName,'') = '' THEN J.CustName ELSE K.EngCustName END AS CustName,
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
           --B.QCSeq,
           Z.QCDate,
           Z.CustEngName,
           --Z.DVPlaceSeq,
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
           ISNULL(C.TestItemGroupName,'') AS TestItemGroupName
      INTO #Temp 
      FROM KPXLS_TQCCOAPrint AS Z 
      --LEFT OUTER JOIN KPX_TQCTestResultItem					AS B ON ( Z.CompanySeq = @CompanySeq AND Z.QCSeq = B.QCSeq AND B.SMSourceType IN (1000522001, 1000522002) ) 
      --LEFT OUTER JOIN KPX_TQCTestResult						AS A ON ( A.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq )
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
     ORDER BY TestItemGroupName, Sort
    
    
    -- 넘버 만들기 위한 로직 
    DECLARE @MaxIdx_No  INT 
    
    SELECT @MaxIdx_No = MAX(IDX_NO)
      from #Temp  AS Z 
     WHERE Z.TestItemGroupName = '' 
    
    CREATE TABLE #Number
    (
        IDX_NO              INT IDENTITY, 
        TestItemGroupName   NVARCHAR(100) 
    )
    INSERT INTO #Number(TestItemGroupName)
    SELECT DISTINCT TestItemGroupName
      from #Temp  AS Z 
     WHERE Z.TestItemGroupName <> ''
    -- 넘버 만들기 위한 로직, END 
    
    
    SELECT CONVERT(NVARCHAR(20),Z.IDX_NO) + '. ' + Z.InTestItemName + NCHAR(13) + '  ' + Z.OutTestItemName AS QCList, 
           Z.CasNo, Z.OriWeight, Z.TotWeight, Z.CreateDate, Z.ReTestDate, Z.TestResultDate, Z.CustName, Z.AnalysisName, Z.TestValue, Z.ItemName, 
           Z.LotNo, Z.UnitName, 
           --Z.SMInPutType, Z.LowerLimit, Z.UpperLimit, Z.QCUnitName 
           CASE WHEN Z.SMInPutType = 1018002 THEN Z.UpperLimit 
                WHEN Z.UpperLimit = '' THEN Z.LowerLimit + ' ' + Z.QCUnitName + ' min.'
                WHEN Z.LowerLimit = '' THEN Z.UpperLimit + ' ' + Z.QCUnitName + ' max.'
                WHEN Z.LowerLimit <> '' AND Z.UpperLimit <> '' THEN Z.LowerLimit + ' ~ ' + Z.UpperLimit + ' ' + Z.QCUnitName 
                ELSE ''
                END AS Spec
           
           
      FROM #Temp AS Z 
     WHERE Z.TestItemGroupName = ''
    
    UNION ALL 
    
    SELECT CONVERT(NVARCHAR(20),Q.IDX_NO) + '. ' + Z.TestItemGroupName + NCHAR(13) + REPLACE(Y.Title1,'@!@!@!@!', NCHAR(13)) AS QCList, 
           Z.CasNo, Z.OriWeight, Z.TotWeight, Z.CreateDate, Z.ReTestDate, Z.TestResultDate, Z.CustName, Z.AnalysisName, Z.TestValue, Z.ItemName, 
           Z.LotNo, Z.UnitName, 
           --Z.SMInPutType, Z.LowerLimit, Z.UpperLimit, Z.QCUnitName
           CASE WHEN Z.SMInPutType = 1018002 THEN Z.UpperLimit 
                WHEN Z.UpperLimit = '' THEN Z.LowerLimit + ' ' + Z.QCUnitName + ' min.'
                WHEN Z.LowerLimit = '' THEN Z.UpperLimit + ' ' + Z.QCUnitName + ' max.'
                WHEN Z.LowerLimit <> '' AND Z.UpperLimit <> '' THEN Z.LowerLimit + ' ~ ' + Z.UpperLimit + ' ' + Z.QCUnitName 
                ELSE ''
                END AS Spec 
      FROM #Temp AS Z 
      JOIN (
            SELECT B.TestItemGroupName,  
                   replace(replace(replace((select A.OutTestItemName from #Temp AS A WHERE A.TestItemGroupName = B.TestItemGroupName  FOR XML AUTO, ELEMENTS),'</OutTestItemName></A><A><OutTestItemName>','@!@!@!@!- '),'<A><OutTestItemName>','- '),'</OutTestItemName></A>','') AS Title1
              FROM #Temp AS B  	
             WHERE B.TestItemGroupName <> ''
             GROUP BY B.TestItemGroupName	
           ) AS Y ON ( Y.TestItemGroupName = Z.TestItemGroupName )
      JOIN (
            SELECT @MaxIdx_No + IDX_NO AS IDX_NO, TestItemGroupName
              FROM #Number 
           ) AS Q ON ( Q.TestItemGroupName = Z.TestItemGroupName ) 

     WHERE Z.TestItemGroupName <> '' 
    
    RETURN  
GO


exec KPXLS_SQCCOAPrintRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=1033540,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027778