  
IF OBJECT_ID('KPXLS_SQCInspecHistoryQuerySub') IS NOT NULL   
    DROP PROC KPXLS_SQCInspecHistoryQuerySub  
GO  
  
-- v2016.03.15  
  
-- 검사이력조회-Item조회 by 이재천   
CREATE PROC KPXLS_SQCInspecHistoryQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @QCSeq      INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QCSeq   = ISNULL( QCSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (QCSeq   INT)    
    
    SELECT A.TestItemSeq, 
           I.TestItemName, 
           I.InTestItemName, 
           I.OutTestItemName, 
           E.QAAnalysisTypeName AS QAAnalysisName, 
           A.QAAnalysisType, 
           F.MinorName AS SMInputTypeName, 
           C.SMInputType, 
           C.LowerLimit, 
           C.UpperLimit, 
           G.QCUnitName, 
           A.QCUnit, 
           J.EmpName AS QCEEmpName, 
           A.EmpSeq AS QCEEmpSeq, 
           A.TestValue, 
           A.SMTestResult, 
           H.MinorName AS SMTestResultName, 
           A.IsSpecial, 
           A.Remark, 
           K.EmpName AS RegEmpName, 
           A.RegEmpSeq AS RegEmpSeq, 
           CONVERT(NCHAR(8),A.RegDate,112) AS RegDate, 
           CASE WHEN A.LastDateTIme <> A.RegDate THEN (SELECT UserSeq FROM _TCAUser WHERE UserSeq = A.LastUserSeq) ELSE '' END AS UpdateEmpSeq,   -- UserSeq 
           CASE WHEN A.LastDateTIme <> A.RegDate THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = A.LastUserSeq) ELSE '' END AS UpdateEmpName,   
           CASE WHEN A.LastDateTIme <> A.RegDate THEN CONVERT(NCHAR(8),A.lastDateTime,112) ELSE '' END AS UpdateDate,   
           A.QCSeq, 
           A.QCSerl 
           
      FROM KPX_TQCTestResultItem                AS A 
      LEFT OUTER JOIN KPX_TQCTestResult         AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd    AS D ON ( D.CompanySeq = @CompanySeq AND D.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPX_TQCQASpec             AS C ON ( C.CompanySeq = @CompanySeq 
                                                      AND C.ItemSeq = B.ItemSeq 
                                                      AND C.QCType = CASE WHEN ISNULL(B.QCType ,0) = 0 THEN A.QCType ELSE B.QCType END
                                                      AND C.TestItemSeq = A.TestItemSeq 
                                                      AND C.QAAnalysisType = A.QAAnalysisType 
                                                      AND C.QCUnit = A.QCUnit 
                                                      AND C.IsProd = '1' 
                                                      AND (CASE WHEN D.TestDate = '' THEN '99991231' ELSE D.TestDate END) BETWEEN C.SDate AND C.EDate
                                                        )
      LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON ( E.CompanySeq = @CompanySeq AND E.QAAnalysisType = A.QAAnalysisType ) 
      LEFT OUTER JOIN _TDASMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = C.SMInputType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS G ON ( G.CompanySeq = @CompanySeq AND G.QCUnit = A.QCUnit ) 
      LEFT OUTER JOIN _TDASMinor                AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.SMTestResult ) 
      LEFT OUTER JOIN KPX_TQCQATestItems        AS I ON ( I.CompanySeq = @CompanySeq AND I.TestItemSeq = A.TestItemSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS K ON ( K.CompanySeq = @CompanySeq AND K.EmpSeq = A.RegEmpSeq ) 
      
     WHERE A.QCSeq = @QCSeq 
    
    RETURN  
go
exec KPXLS_SQCInspecHistoryQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <QCSeq>182</QCSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035772,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029461

--select * from sysobjects where name like '%TestItem%'