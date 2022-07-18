  
IF OBJECT_ID('KPXLS_SQCCOAPrintResultQuery') IS NOT NULL   
    DROP PROC KPXLS_SQCCOAPrintResultQuery  
GO  
  
-- v2016.01.06 
  
-- 시험성적서저장(COA)-결과조회 by 이재천 
CREATE PROC KPXLS_SQCCOAPrintResultQuery  
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
    
    -- 최종조회   
    SELECT A.QCSeq, 
           B.TestItemSeq, 
           C.TestItemGroupName, 
           C.OutTestItemName, 
           C.InTestItemName, 
           B.QAAnalysisType, 
           D.QAAnalysisTypeName AS AnalysisName, 
           E.LowerLimit,   
           E.UpperLimit,   
           B.SMTestResult, 
           F.MinorName AS SMTestResultName, 
           B.QCUnit, 
           G.QCUnitName, 
           B.TestValue, 
           B.Remark, 
           E.Remark AS Remark2,
           M.CreateDate, 
           I.ValiDate AS ReTestDate, 
           CASE WHEN LEFT(CONVERT(NCHAR(8),J.CfmDateTime,112),4) = '1900' THEN '' ELSE CONVERT(NCHAR(8),J.CfmDateTime,112) END AS TestResultDate  , 
           A.ItemSeq, 
           A.LotNo 
      FROM KPX_TQCTestResult                        AS A  
      LEFT OUTER JOIN KPX_TQCTestResultItem         AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPX_TQCQATestItems            AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType         AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQASpec                 AS E ON ( E.CompanySeq = @CompanySeq      
                                                      AND E.ItemSeq = A.ItemSeq      
                                                      AND E.TestItemSeq = B.TestItemSeq      
                                                      AND E.QAAnalysisType = B.QAAnalysisType      
                                                      AND E.QCUnit = B.QCUnit      
                                                      AND CONVERT(NCHAR(8),B.RegDate,112) BETWEEN E.SDate AND E.EDate 
                                                        ) 
      LEFT OUTER JOIN _TDASMinor                    AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.SMTestResult ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit        AS G ON ( G.CompanySeq = @CompanySeq AND G.QCUnit = B.QCUnit ) 
      LEFT OUTER JOIN _TLGLotMaster                 AS I ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq AND I.LotNo = A.LotNo ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd        AS J ON ( J.CompanySeq = @CompanySeq AND J.QCSeq = A.QCSeq )   
      LEFT OUTER JOIN KPXLS_TQCRequestItem          AS K ON ( K.CompanySeq = @CompanySeq AND K.ReqSeq = A.ReqSeq AND K.ReqSerl = A.ReqSerl )   
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PDB   AS M ON ( M.CompanySeq = @CompanySeq AND M.ReqSeq = K.ReqSeq AND M.ReqSerl = K.ReqSerl )   
      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.QCSeq = @QCSeq 
      
    RETURN  
    go
    exec KPXLS_SQCCOAPrintResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QCSeq>171</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033540,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028324