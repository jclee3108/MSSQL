  
IF OBJECT_ID('KPX_SQCCOAPrintQuerySub') IS NOT NULL   
    DROP PROC KPX_SQCCOAPrintQuerySub  
GO  
  
-- v2014.12.18  
  
-- 시험성적서발행(COA)- SS1 조회 by 이재천   
CREATE PROC KPX_SQCCOAPrintQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemSeq    INT, 
            @LotNo      NVARCHAR(100), 
            @QCType     INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq = ISNULL( ItemSeq, 0 ),  
           @LotNo   = ISNULL( LotNo, '' ), 
           @QCType  = ISNULL( QCType, 0 ) 
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq    INT, 
            LotNo      NVARCHAR(100), 
            QCType     INT 
           )
    
    CREATE TABLE #BaseData 
    (
        QCSeq           INT, 
        KindSeq         INT, 
        OutTestItemName NVARCHAR(100), 
        AnalysisName    NVARCHAR(100), 
        LowerLimit      NVARCHAR(100), 
        UpperLimit      NVARCHAR(100), 
        QCUnitName      NVARCHAR(100), 
        TestValue       NVARCHAR(100), 
        Remark          NVARCHAR(100)
    )
    
    CREATE TABLE #MAXData 
    (
        QCSeq           INT, 
        LastDateTime    DATETIME, 
        Kind            INT 
    )
    
    INSERT INTO #MAXData ( QCSeq, LastDateTime, Kind ) 
    SELECT StockQCSeq, LastDateTime, 1 -- 재고검사등록
      FROM KPX_TQCInStockInspectionResult AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND A.LotNo = @LotNo 
       AND A.QCType = @QCType 
    
    UNION ALL 
    
    SELECT TermQCSeq, LastDateTime, 2 -- 유효기간검사
      FROM KPX_TQCTermInspectionResult AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND A.LotNo = @LotNo 
       AND A.QCType = @QCType 
    
    ORDER BY LastDateTime DESC 
    
    --SELECT TOP 1 * FROM #MAXData 
    --return 
    
    INSERT INTO #BaseData 
    (
        QCSeq, 
        KindSeq, 
        OutTestItemName,
        AnalysisName   , 
        LowerLimit     ,
        UpperLimit     ,     
        QCUnitName     ,
        TestValue      ,
        Remark
    ) 
    
    SELECT A.StockQCSeq, 
           F.Kind, 
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           G.LowerLimit, 
           G.UpperLimit, 
           E.QCUnitName, 
           B.TestValue, 
           '' AS Remark 
      FROM KPX_TQCInStockInspectionResult                   AS A  
                 JOIN ( SELECT TOP 1 QCSeq, Kind
                           FROM #MAXData
                      ) AS F ON ( F.QCSeq = A.StockQCSeq AND F.Kind = 1 )
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
     
     WHERE A.CompanySeq = @CompanySeq 
    
    UNION ALL 
    
    SELECT A.TermQCSeq, 
           F.Kind, 
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           G.LowerLimit, 
           G.UpperLimit, 
           E.QCUnitName, 
           B.TestValue, 
           '' AS Remark 
      FROM KPX_TQCTermInspectionResult                      AS A  
                 JOIN ( SELECT TOP 1 QCSeq, Kind
                           FROM #MAXData
                      ) AS F ON ( F.QCSeq = A.TermQCSeq AND F.Kind = 2 )
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
     
     WHERE A.CompanySeq = @CompanySeq 
    
    SELECT * FROM #BaseData
    
    RETURN  
GO 
exec KPX_SQCCOAPrintQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ItemSeq>27255</ItemSeq>
    <LotNo>P201401120002-1</LotNo>
    <QCType>3</QCType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026900,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022490