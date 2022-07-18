
IF OBJECT_ID('KPX_QCTermInspectionRequestListJumpOut') IS NOT NULL 
    DROP PROC KPX_QCTermInspectionRequestListJumpOut
GO 

-- v2015.01.18 

-- 유효기간검사의뢰 -> 유효기간검사 점프 by이재천 
CREATE PROC KPX_QCTermInspectionRequestListJumpOut
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
 
AS 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle          INT,  
            @QCTermReqSeq       INT, 
            @QCTermReqSerl      INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @QCTermReqSeq = ISNULL(QCTermReqSeq, 0),  
           @QCTermReqSerl = ISNULL(QCTermReqSerl, 0)
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (QCTermReqSeq       INT,
            QCTermReqSerl      INT
           )    
    
    IF NOT EXISTS ( SELECT 1 
                      FROM KPX_TQCTestResult AS A 
                      JOIN KPX_TQCTestResultItem AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq )
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.ReqSeq = @QCTermReqSeq 
                       AND A.ReqSerl = @QCTermReqSerl 
    
                  ) -- 신규 점프 
    BEGIN 
        
        SELECT A.ReqSeq, 
               A.ReqSerl, 
               C.BizUnit                            ,  
               D.BizUnitName                        ,  
               K.SMTestResult                       ,  
               CASE WHEN ISNULL(K.SMTestResult, 0) = 0 THEN '미검사' ELSE  N.MinorName END AS SMTestResultName ,   -- 검사구분  
               M.ReqNo          AS QCTermReqNo      ,  
               M.DeptSeq                            ,  
               I.DeptName                           ,  
               M.EmpSeq                             ,   
               J.EmpName                            ,   
               A.QCType                             ,   
               B.QCTypeName                         ,  
               A.WHSeq                              ,   
               C.WHName                             ,  
               A.LotNo                              ,   
               A.ItemSeq                            ,   
               F.ItemName                         ,     
               F.ItemNo                             ,  
               F.Spec                             ,  
               A.ReqQty                             ,   
               F.UnitSeq                            ,   
               G.UnitName                           ,   
               E.ValiDate       AS ValidDate        ,  
               E.CreateDate                         ,  
               E.RegDate        AS InDate           ,  
               E.SupplyCustSeq                      ,   
               H.CustName       AS  SupplyName       ,  
               A.Remark                             ,  
               M.ReqDate        AS TestDate  
      
          FROM KPX_TQCTestRequest                   AS M 
          JOIN KPX_TQCTestRequestItem               AS A ON M.CompanySeq = A.CompanySeq AND M.ReqSeq = A.ReqSeq  
          LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS B ON A.CompanySeq = B.CompanySeq AND A.QCType = B.QCType  
          LEFT OUTER JOIN _TDAWH                    AS C ON A.CompanySeq = C.CompanySeq AND A.WHSeq = C.WHSeq          
          LEFT OUTER JOIN _TDABizUnit               AS D ON C.CompanySeq = D.CompanySeq AND C.BizUnit = D.BizUnit  
          LEFT OUTER JOIN _TLGLotMaster             AS E ON A.CompanySeq = E.CompanySeq AND A.ItemSeq = E.ItemSeq AND A.LotNo = E.LotNo  
          LEFT OUTER JOIN _TDAItem                  AS F ON A.CompanySeq = F.CompanySeq AND A.ItemSeq = F.ItemSeq  
          LEFT OUTER JOIN _TDAUnit                  AS G ON F.CompanySeq = G.CompanySeq AND F.UnitSeq = G.UnitSeq  
          LEFT OUTER JOIN _TDACust                  AS H ON E.CompanySeq = H.CompanySeq AND E.SupplyCustSeq = H.CustSeq  
          LEFT OUTER JOIN _TDADept                  AS I ON M.CompanySeq = I.CompanySeq AND M.DeptSeq = I.DeptSeq  
          LEFT OUTER JOIN _TDAEmp                   AS J ON M.CompanySeq = J.CompanySeq AND M.EmpSeq = J.EmpSeq  
          LEFT OUTER JOIN KPX_TQCTestResult         AS K ON A.CompanySeq = K.CompanySeq AND A.ReqSeq = K.ReqSeq AND A.ReqSerl = K.ReqSerl  
          LEFT OUTER JOIN _TDAUMinor                AS N ON K.CompanySeq = N.CompanySeq AND K.SMTestResult = N.MinorSeq  
         
         WHERE 1=1  
            AND A.CompanySeq = @CompanySeq  
            AND ( @QCTermReqSeq = A.ReqSeq ) 
            AND ( @QCTermReqSerl = A.ReqSerl ) 
            AND A.SMSourceType  = 1000522002  
         ORDER BY A.ReqSeq, A.ReqSerl  
        
        SELECT ISNULL(D.TestItemName,'') AS TestItemName, 
               ISNULL(D.TestItemSeq,0) AS TestItemSeq, 
               ISNULL(D.InTestItemName,'') AS InTestItemName, 
               E.QAAnalysisType AS QAAnalysisType, 
               E.QAAnalysisTypeName AS QAAnalysisTypeName, 
               F.QCUnit, 
               F.QCUnitName, 
               C.SMInputType, 
               G.MinorName AS SMInputTypeName, 
               C.LowerLimit, 
               C.UpperLimit, 
               '0' AS IsExists 
          FROM KPX_TQCTestRequestItem               AS B 
          LEFT OUTER JOIN KPX_TQCTestRequest        AS A ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq ) 
          LEFT OUTER JOIN KPX_TQCQASpec             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.QCType = B.QCType AND A.ReqDate BETWEEN C.SDate AND C.EDate ) 
          LEFT OUTER JOIN KPX_TQCQATestItems        AS D ON ( D.CompanySeq = @CompanySeq AND D.TestItemSeq = C.TestItemSeq ) 
          LEFT OUTER JOIN KPX_TQCQAAnalysisType     AS E ON ( E.CompanySeq = @CompanySeq AND E.QAAnalysisType = C.QAAnalysisType ) 
          LEFT OUTER JOIN KPX_TQCQAProcessQCUnit    AS F ON ( F.CompanySeq = @CompanySeq AND F.QCUnit = C.QCUnit ) 
          LEFT OUTER JOIN _TDASMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.SMInputType ) 
         WHERE B.CompanySeq = @CompanySeq  
           AND ( @QCTermReqSeq = B.ReqSeq ) 
           AND ( @QCTermReqSerl = B.ReqSerl ) 
           AND B.SMSourceType  = 1000522002  
           AND ( C.QCType IS NOT NULL OR C.QCType <> 0 )
    
    END 
    ELSE
    BEGIN -- 기존데이터 
        
        SELECT A.QCSeq AS TermQCSeq    
          FROM KPX_TQCTestResult                    AS A    
          LEFT OUTER JOIN _TDAItem                  AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq     
          LEFT OUTER JOIN _TDAUMinor                AS C ON A.CompanySeq = C.CompanySeq AND A.SMTestResult = C.MinorSeq    
          LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS D ON ( D.CompanySeq = @CompanySeq AND D.QCType = A.QCType )   
         WHERE A.CompanySeq = @CompanySeq    
           AND A.ReqSeq = @QCTermReqSeq 
           AND A.ReqSerl = @QCTermReqSerl 
        
        SELECT TOP 1 '1' AS IsExists 
          FROM KPX_TQCTestResultItem        AS A    
          LEFT OUTER JOIN KPX_TQCTestResult AS M ON A.CompanySeq = M.CompanySeq AND A.QCSeq = M.QCSeq    
         WHERE A.CompanySeq = @CompanySeq 
           AND M.ReqSeq = @QCTermReqSeq 
           AND M.ReqSerl = @QCTermReqSerl 
    
    END 
    
    
    RETURN  
GO 
exec KPX_QCTermInspectionRequestListJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QCTermReqSeq>16</QCTermReqSeq>
    <QCTermReqSerl>2</QCTermReqSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026574,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022265