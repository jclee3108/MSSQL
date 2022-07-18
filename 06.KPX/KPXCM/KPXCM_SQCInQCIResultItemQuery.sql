IF OBJECT_ID('KPXCM_SQCInQCIResultItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCIResultItemQuery
GO 

-- v2016.06.01 
-- 테이블 수정 by이재천 
/************************************************************  
 설  명 - 데이터-수입검사등록_KPX : 조회  
 작성일 - 20141219  
 작성자 - 박상준  
 수정자 -   
************************************************************/  
CREATE PROC KPXCM_SQCInQCIResultItemQuery
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
    
    DECLARE @docHandle  INT,  
            @InQCSeq    INT    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @InQCSeq = ISNULL(InQCSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)  
      WITH (InQCSeq INT )  
    
    SELECT A.QCSeq AS InQCSeq  
          ,A.QCSerl AS InQCSerl  
          ,A.TestItemSeq  
          ,B.InTestItemName
          ,A.QAAnalysisType  
          ,C.QAAnalysisTypeName AS QAAnalysisName  
          ,A.QCUnit  
          ,E.QCUnitName  
          ,A.TestValue  
          ,A.SMTestResult  
          ,F.MinorName AS SMTestResultName            
          ,A.IsSpecial  
          ,A.TestHour  
          ,A.EmpSeq  
          ,G.EmpName  
          ,CONVERT(NCHAR(8),A.RegDate,112) RegDate  
          ,CONVERT(NVARCHAR(5), A.RegDate, 108) AS RegTime    
          ,A.RegEmpSeq  
          ,J.EmpName AS RegEmpName  
          ,A.Remark  
          ,A.LastUserSeq  
          ,CASE WHEN A.LastDateTime = A.RegDate THEN '' ELSE CONVERT(NVARCHAR(100),A.LastDateTime,20) END AS LastDateTime
          ,S.SMInputType                             
          ,D.MinorName AS SMInputTypeName            
          ,S.LowerLimit                              
          ,S.UpperLimit                              
          ,CASE WHEN A.LastDateTime = A.RegDate THEN '' ELSE K.UserName END AS LastUserName 
      FROM KPX_TQCTestResultItem AS A  
      LEFT OUTER JOIN KPX_TQCTestResult      AS M ON A.CompanySeq = M.CompanySeq AND A.QCSeq = M.QCSeq  
      LEFT OUTER JOIN KPX_TQCQATestItems     AS B ON A.CompanySeq = B.CompanySeq AND A.TestItemSeq  = B.TestItemSeq  
      LEFT OUTER JOIN KPX_TQCQASpec          AS S ON A.CompanySeq   = S.CompanySeq  
                                                  AND M.ItemSeq      = S.ItemSeq  
                                                  AND A.TestItemSeq  = S.TestItemSeq  
                                                  AND A.QAAnalysisType  = S.QAAnalysisType  
                                                  AND A.QCUnit    = S.QCUnit  
                                                  AND CONVERT(NCHAR(8),A.RegDate,112) BETWEEN S.SDate AND S.EDate
												  AND S.QCType = CASE WHEN ISNULL(M.QCType, 0) = 0 THEN A.QCType ELSE M.QCType END
											
      LEFT OUTER JOIN KPX_TQCQAAnalysisType  AS C ON A.CompanySeq   = C.CompanySeq  
                                                 AND A.QAAnalysisType = C.QAAnalysisType  
      LEFT OUTER JOIN _TDASMinor             AS D ON S.CompanySeq   = D.CompanySeq  
                                                 AND S.SMInputType  = D.MinorSeq  
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit AS E ON A.CompanySeq   = E.CompanySeq  
                                                 AND A.QCUnit       = E.QCUnit  
      LEFT OUTER JOIN _TDASMinor             AS F ON A.CompanySeq   = F.CompanySeq  
                                                 AND A.SMTestResult = F.MinorSeq  
      LEFT OUTER JOIN _TDAEmp                AS G ON A.CompanySeq   = G.CompanySeq  
                                                 AND A.EmpSeq       = G.EmpSeq  
      LEFT OUTER JOIN _TLGLotMaster          AS H ON M.CompanySeq   = H.CompanySeq  
                                                 AND M.ItemSeq      = H.ItemSeq
                                                 AND M.LotNo        = H.LotNo  
      LEFT OUTER JOIN _TDACust               AS I ON H.CompanySeq   = I.CompanySeq  
                                                 AND H.SupplyCustSeq = I.CustSeq  
      LEFT OUTER JOIN _TDAEmp                AS J ON A.CompanySeq   = J.CompanySeq  
                                                 AND A.RegEmpSeq    = J.EmpSeq  
      LEFT OUTER JOIN _TCAUser               AS K ON ( K.CompanySeq = @CompanySeq AND K.UserSeq = A.LastUserSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.QCSeq = @InQCSeq   
  ORDER BY S.Sort
  
RETURN  

GO
exec KPXCM_SQCInQCIResultItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InQCSeq>2419</InQCSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030782,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026945


