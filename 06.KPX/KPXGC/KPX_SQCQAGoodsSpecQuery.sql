  
IF OBJECT_ID('KPX_SQCQAGoodsSpecQuery') IS NOT NULL   
    DROP PROC KPX_SQCQAGoodsSpecQuery  
GO  
  
-- v2014.11.20  
  
-- 품목검사규격등록(생산품)-조회 by 이재천   
CREATE PROC KPX_SQCQAGoodsSpecQuery  
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
            @ItemSeq    INT, 
            @QCTypeQ    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ItemSeq   = ISNULL( ItemSeq, 0 ), 
           @QCTypeQ   = ISNULL( QCTypeQ, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq     INT,
            QCTypeQ     INT 
           )    
    
    /*
    KPX_TQCQAProcessQCType -- 검사공정등록 
    KPX_TQCQATestItems -- 검사항목등록
    KPX_TQCQAAnalysisType -- 분석방법등록
    KPX_TQCQAProcessQCUnit -- 검사단위등록
    */
    
    -- 최종조회   
    SELECT -- 검사항목 
           B.TestItemSeq, 
           B.TestItemName, 
           B.OutTestItemName, 
           B.InTestItemName, 
           B.TestItemSeq AS TestItemSeqOld, 
           
           -- 분석방법 
           C.QAAnalysisType, 
           C.QAAnalysisTypeNo, 
           C.QAAnalysisTypeName, 
           C.QAAnalysisType AS QAAnalysisTypeOld, 
           
           E.MinorName AS SMInputTypeName, 
           A.SMInputType, 
           A.LowerLimit, 
           A.UpperLimit, 
           
           -- 검사단위 
           D.QCUnit, 
           D.QCUnitName, 
            
           A.SDate, 
           A.EDate, 
           A.RegEmpSeq, 
           F.EmpName AS RegEmpName, 
           CONVERT(NCHAR(8),A.RegDateTime,112) AS RegDateTime, 
           
           CASE WHEN A.RegDateTime = A.LastDateTime THEN 0 ELSE G.EmpSeq END AS LastUserSeq, 
           CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE H.EmpName END AS LastUserName, 
           CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE CONVERT(NCHAR(8),A.LastDateTime,112) END AS LastDateTime, 
           
           A.Remark, 
           A.Serl, 
           
           A.ItemSeq AS ItemSeqOld, 
           A.QCType, 
           I.QCTypeName, 
           A.QCType AS QCTypeOld 
           
    
      FROM KPX_TQCQASpec        AS A 
      LEFT OUTER JOIN KPX_TQCQATestItems        AS B ON ( B.CompanySeq = @CompanySeq AND B.TestItemSeq = A.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS C ON ( C.CompanySeq = @CompanySeq AND C.QAAnalysisType = A.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS D ON ( D.CompanySeq = @CompanySeq AND D.QCUnit = A.QCUnit ) 
      LEFT OUTER JOIN _TDASMinor                AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMInputType ) 
      LEFT OUTER JOIN _TDAEmp                   AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.RegEmpSeq ) 
      LEFT OUTER JOIN _TCAUser                  AS G ON ( G.CompanySeq = @CompanySeq AND G.UserSeq = A.LastUserSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = G.EmpSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS I ON ( I.CompanySeq = @CompanySeq AND I.QCType = A.QCType ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq ) 
       AND ( @QCTypeQ = 0 OR A.QCType = @QCTypeQ ) 
       AND ( A.IsProd = CASE WHEN @PgmSeq = 1021431 THEN '1' ELSE '0' END )

    
    RETURN  
GO 
exec KPX_SQCQAGoodsSpecQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ItemSeq>27255</ItemSeq>
    <QCTypeQ>3</QCTypeQ>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021431