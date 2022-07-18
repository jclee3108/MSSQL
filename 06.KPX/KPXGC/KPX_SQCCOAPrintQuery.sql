  
IF OBJECT_ID('KPX_SQCCOAPrintQuery') IS NOT NULL   
    DROP PROC KPX_SQCCOAPrintQuery  
GO  
  
-- v2014.12.18  
  
-- 시험성적서발행(COA)-조회 by 이재천   
CREATE PROC KPX_SQCCOAPrintQuery  
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
    
    
    SELECT @KindSeq = KindSeq FROM KPX_TQCCOAPrint WHERE CompanySeq = @CompanySeq AND COASeq = @COASeq 
    
    CREATE TABLE #Result 
    (
        COASeq          INT, 
        OutTestItemName NVARCHAR(100),
        AnalysisName    NVARCHAR(100), 
        LowerLimit      NVARCHAR(100),
        UpperLimit      NVARCHAR(100),     
        QCUnitName      NVARCHAR(100),
        TestValue       NVARCHAR(100),
        Remark          NVARCHAR(100)
    )
    
    IF @KindSeq = 1 
    BEGIN 
        
        INSERT INTO #Result 
        ( 
            COASeq, OutTestItemName, AnalysisName, LowerLimit, UpperLimit, 
            QCUnitName, TestValue, Remark
        )
        SELECT Z.COASeq, 
               C.OutTestItemName, 
               D.QAAnalysisTypeName AS AnalysisName, 
               G.LowerLimit, 
               G.UpperLimit, 
               E.QCUnitName, 
               B.TestValue, 
               '' AS Remark 
          FROM KPX_TQCCOAPrint AS Z 
          LEFT OUTER JOIN KPX_TQCInStockInspectionResult        AS A ON ( A.CompanySeq = @CompanySeq AND A.StockQCSeq = Z.QCSeq ) 
          LEFT OUTER JOIN KPX_TQCInStockInspectionResultItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StockQCSeq = A.StockQCSeq ) 
          LEFT OUTER JOIN KPX_TQCQATestItems                    AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
          LEFT OUTER JOIN KPX_TQCQAAnalysisType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.AnalysisSeq ) 
          LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = B.QCUnitSeq ) 
          LEFT OUTER JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
                                                                  AND G.ItemSeq = A.ItemSeq 
                                                                  AND G.QCType = A.QCType 
                                                                  AND G.TestItemSeq = B.TestItemSeq 
                                                                  AND G.QAAnalysisType = D.QAAnalysisType
                                                                  AND G.QCUnit = E.QCUnit 
                                                                  AND G.IsProd = '1' 
                                                                        )
         WHERE Z.CompanySeq = @CompanySeq  
           AND Z.COASeq = @COASeq 
    END 
    ELSE IF @KindSeq = 2 
    BEGIN
        
        INSERT INTO #Result 
        ( 
            COASeq, OutTestItemName, AnalysisName, LowerLimit, UpperLimit, 
            QCUnitName, TestValue, Remark
        )
        SELECT Z.COASeq, 
               C.OutTestItemName, 
               D.QAAnalysisTypeName AS AnalysisName, 
               G.LowerLimit, 
               G.UpperLimit, 
               E.QCUnitName, 
               B.TestValue, 
               '' AS Remark 
          FROM KPX_TQCCOAPrint AS Z 
          LEFT OUTER JOIN KPX_TQCTermInspectionResult           AS A ON ( A.CompanySeq = @CompanySeq AND A.TermQCSeq = Z.QCSeq ) 
          LEFT OUTER JOIN KPX_TQCTermInspectionResultItem       AS B ON ( B.CompanySeq = @CompanySeq AND B.TermQCSeq = A.TermQCSeq ) 
          LEFT OUTER JOIN KPX_TQCQATestItems                    AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
          LEFT OUTER JOIN KPX_TQCQAAnalysisType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.QAAnalysisType ) 
          LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = B.QCUnit ) 
          LEFT OUTER JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
                                                                      AND G.ItemSeq = A.ItemSeq 
                                                                      AND G.QCType = A.QCType 
                                                                      AND G.TestItemSeq = B.TestItemSeq 
                                                                      AND G.QAAnalysisType = D.QAAnalysisType
                                                                      AND G.QCUnit = E.QCUnit 
                                                                      AND G.IsProd = '1' 
                                                                        )
         WHERE Z.CompanySeq = @CompanySeq  
           AND Z.COASeq = @COASeq 
    
    END 
    
    SELECT A.*, 
           B.CustSeq, 
           B.COANo,
           D.CustName, 
           B.ItemSeq, 
           C.ItemName, 
           B.LotNo, 
           B.ShipDate, 
           B.COADate, 
           B.COACount, 
           B.QCSeq, 
           B.KindSeq, 
           B.QCType, 
           E.QCTypeName, 
           F.EngCustSName AS CustEngName, 
           G.CustItemName, 
           H.UnitName, 
           I.LimitTerm AS LifeCycle
      FROM #Result              AS A 
      JOIN KPX_TQCCOAPrint      AS B ON ( B.CompanySeq = @CompanySeq AND B.COASeq = A.COASeq ) 
      LEFT OUTER JOIN _TDAItem  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDACust  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType AS E ON ( E.CompanySeq = @CompanySeq AND E.QCType = B.QCType ) 
      LEFT OUTER JOIN _TDACustAdd AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TSLCustItem AS G ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.Itemseq AND G.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS H ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDAitemStock AS I ON ( I.COmpanySeq = @CompanySeq AND I.ItemSeq = B.ItemSeq ) 
    
    RETURN  
GO 
exec KPX_SQCCOAPrintQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <COASeq>3</COASeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026900,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022490
