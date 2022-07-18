  
IF OBJECT_ID('KPXLS_SQCInQCIResultItemQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultItemQuery  
GO  
  
-- v2015.12.15  
  
-- (검사품)수입검사등록-디테일조회 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultItemQuery 
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
      WITH (QCSeq   INT)    
    
    SELECT A.QCSeq, 
           A.QCSerl, 
           A.TestItemSeq, 
           B.InTestItemName, 
           B.OutTestItemName, 
           A.QAAnalysisType, 
           C.QAAnalysisTypeName AS QAAnalysisName, 
           A.QCUnit, 
           E.QCUnitName, 
           A.TestValue, 
           A.SMTestResult, 
           F.MinorName AS SMTestResultName, 
           A.IsSpecial, 
           A.TestHour, 
           A.EmpSeq, 
           G.EmpName, 
           CONVERT(NCHAR(8),A.RegDate,112) RegDate, 
           A.RegEmpSeq, 
           J.EmpName AS RegEmpName, 
           A.Remark, 
           CASE WHEN A.LastDateTIme <> A.RegDate THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = A.LastUserSeq) ELSE '' END AS UpdateEmpName, 
           CASE WHEN A.LastDateTIme <> A.RegDate THEN CONVERT(NCHAR(8),A.lastDateTime,112) ELSE '' END AS UpdateDate, 
           S.SMInputType, 
           D.MinorName AS SMInputTypeName, 
           S.LowerLimit, 
           S.UpperLimit, 
           
           CASE WHEN A.LastDateTIme <> A.RegDate THEN LEFT(CONVERT(NVARCHAR(100),A.LastDateTime,114),8) ELSE '' END AS UpdateTime, 
           LEFT(CONVERT(NVARCHAR(100),A.RegDate,114),8) AS RegTime
    
      FROM KPX_TQCTestResultItem AS A    
      LEFT OUTER JOIN KPX_TQCTestResult      AS M ON A.CompanySeq = M.CompanySeq AND A.QCSeq = M.QCSeq    
      LEFT OUTER JOIN KPX_TQCQATestItems     AS B ON A.CompanySeq = B.CompanySeq AND A.TestItemSeq  = B.TestItemSeq    
      LEFT OUTER JOIN KPX_TQCQASpec          AS S ON A.CompanySeq   = S.CompanySeq    
                                                 AND M.ItemSeq = S.ItemSeq    
                                                 AND A.TestItemSeq = S.TestItemSeq    
                                                 AND A.QAAnalysisType = S.QAAnalysisType    
                                                 AND A.QCUnit = S.QCUnit    
                                                 AND CONVERT(NCHAR(8),A.RegDate,112) BETWEEN S.SDate AND S.EDate  
                                                 AND S.QCType = CASE WHEN ISNULL(M.QCType, 0) = 0 THEN A.QCType ELSE M.QCType END  
      LEFT OUTER JOIN KPX_TQCQAAnalysisType  AS C ON A.CompanySeq = C.CompanySeq AND A.QAAnalysisType = C.QAAnalysisType    
      LEFT OUTER JOIN _TDASMinor             AS D ON S.CompanySeq = D.CompanySeq AND S.SMInputType = D.MinorSeq    
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit AS E ON A.CompanySeq = E.CompanySeq AND A.QCUnit = E.QCUnit    
      LEFT OUTER JOIN _TDASMinor             AS F ON A.CompanySeq = F.CompanySeq AND A.SMTestResult = F.MinorSeq    
      LEFT OUTER JOIN _TDAEmp                AS G ON A.CompanySeq = G.CompanySeq AND A.EmpSeq = G.EmpSeq 
      LEFT OUTER JOIN _TLGLotMaster          AS H ON M.CompanySeq = H.CompanySeq AND M.ItemSeq = H.ItemSeq AND M.LotNo = H.LotNo    
      LEFT OUTER JOIN _TDACust               AS I ON H.CompanySeq = I.CompanySeq AND H.SupplyCustSeq = I.CustSeq    
      LEFT OUTER JOIN _TDAEmp                AS J ON A.CompanySeq = J.CompanySeq AND A.RegEmpSeq = J.EmpSeq    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.QCSeq = @QCSeq     
     ORDER BY S.Sort  
    
    RETURN  
go
exec KPXLS_SQCInQCIResultItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QCSeq>182</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027993