IF OBJECT_ID('KPXCM_SQCInStockInspectionResultItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionResultItemQuery
GO 

-- v2016.06.15 

/************************************************************  
 설  명 - 데이터-재고검사등록 : 재고검사등록I조회  
 작성일 - 20141204  
 작성자 - 오정환  
 수정자 -   
************************************************************/  
CREATE PROC KPXCM_SQCInStockInspectionResultItemQuery
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
AS          
      
    DECLARE @docHandle      INT,  
            @StockQCSerl    INT ,  
            @StockQCSeq     INT    
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    SELECT @StockQCSerl      = StockQCSerl,  
           @StockQCSeq       = StockQCSeq          
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)  
      WITH (StockQCSerl       INT ,  
            StockQCSeq        INT )  
    SELECT A.QCSeq              AS StockQCSeq       ,  
           A.QCSerl             AS StockQCSerl      ,  
           A.TestItemSeq                            ,  
           B.TestItemName     ,  
           B.InTestItemName     AS InTestItemName   ,  
           A.QAAnalysisType     AS AnalysisSeq      ,  
           C.QAAnalysisTypeName AS AnalysisName     ,  
           S.SMInputType                            ,  
           D.MinorName          AS SMInputTypeName  ,  
           S.LowerLimit                             ,  
           S.UpperLimit                             ,  
           A.QCUnit             AS QCUnitSeq        ,  
           E.QCUnitName                             ,  
           A.TestValue                              ,  
           A.SMTestResult                           ,  
           F.MinorName          AS SMTestResultName ,  
           A.IsSpecial                              ,  
           A.EmpSeq                                 ,  
           G.EmpName                                ,  
           A.TestDate                               ,  
           H.CreateDate                             ,  
           H.RegDate            AS InDate           ,  
           I.CustName           AS SupplyCustName   ,  
           H.SupplyCustSeq                          ,  
           CONVERT(NVARCHAR(8), A.RegDate, 112) AS RegDate    ,  
           CONVERT(NVARCHAR(5), A.RegDate, 108) AS RegTime    ,  
           A.RegEmpSeq                              ,  
           J.EmpName            AS RegEmpName       ,  
           A.Remark                                 ,  
           A.Contents                               , 
           CASE WHEN A.RegDate IS NULL THEN NULL ELSE (CASE WHEN A.LastDateTime = A.RegDate THEN '' ELSE CONVERT(NVARCHAR(100), A.LastDateTime, 20) END) END AS LastDate, -- 수정일자 2016.06.01 by이재천  
           CASE WHEN A.RegDate IS NULL THEN NULL ELSE (CASE WHEN A.LastDateTime = A.RegDate THEN '' ELSE CONVERT(NVARCHAR(100), K.UserName) END) END AS LastEmpName -- 수정자 추가 2016.06.01 by이재천 
    
      FROM KPX_TQCTestResultItem              AS A WITH (NOLOCK) JOIN KPX_TQCTestResult                     M ON A.CompanySeq   = M.CompanySeq  
                                                                                                             AND A.QCSeq        = M.QCSeq  
													  LEFT OUTER JOIN KPX_TQCTestRequest					M1 ON M.CompanySeq  =M1.CompanySeq
																											 AND  M.ReqSeq		=M1.ReqSeq
                                                      LEFT OUTER JOIN KPX_TQCQASpec                         S ON A.CompanySeq   = S.CompanySeq  
                                                                                                             AND M.QCType       = S.QCType  
                                                                                                             AND M.ItemSeq      = S.ItemSeq  
                                                                                AND A.TestItemSeq  = S.TestItemSeq  
                                                                                                             AND A.QAAnalysisType  = S.QAAnalysisType  
                                                  AND A.QCUnit       = S.QCUnit
																											 AND M1.ReqDate BETWEEN S.SDate AND S.EDate  
                                                      LEFT OUTER JOIN KPX_TQCQATestItems                    B ON A.CompanySeq    = B.CompanySeq  
                                                                                                             AND A.TestItemSeq  = B.TestItemSeq  
                                                      LEFT OUTER JOIN KPX_TQCQAAnalysisType                 C ON A.CompanySeq   = C.CompanySeq  
                                                                                                             AND A.QAAnalysisType = C.QAAnalysisType  
                                                      LEFT OUTER JOIN _TDASMinor                            D ON S.CompanySeq   = D.CompanySeq  
                                                                                                             AND S.SMInputType  = D.MinorSeq  
                                                      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                E ON A.CompanySeq   = E.CompanySeq  
                                                                                                             AND A.QCUnit       = E.QCUnit  
                                                      LEFT OUTER JOIN _TDASMinor                            F ON A.CompanySeq   = F.CompanySeq  
                                                                                                             AND A.SMTestResult = F.MinorSeq  
                                                      LEFT OUTER JOIN _TDAEmp                               G ON A.CompanySeq   = G.CompanySeq  
                                                                                                             AND A.EmpSeq       = G.EmpSeq  
                                                      LEFT OUTER JOIN _TLGLotMaster                         H ON M.CompanySeq   = H.CompanySeq  
                                                                                                             AND M.ItemSeq      = H.ItemSeq  
                                                                                                             AND M.LotNo        = H.LotNo  
                                                      LEFT OUTER JOIN _TDACust                              I ON H.CompanySeq   = I.CompanySeq  
                                                                                                             AND H.SupplyCustSeq = I.CustSeq  
                                                      LEFT OUTER JOIN _TDAEmp                               J ON A.CompanySeq   = J.CompanySeq  
                                                                                                             AND A.RegEmpSeq    = J.EmpSeq  
                                                      LEFT OUTER JOIN _TCAUser                              K ON ( K.CompanySeq = @CompanySeq AND K.UserSeq = A.LastUserSeq ) 
     WHERE 1=1  
       AND A.CompanySeq     = @CompanySeq  
       AND A.QCSeq          = @StockQCSeq         
  ORDER BY S.Sort      
    
RETURN
GO


exec KPXCM_SQCInStockInspectionResultItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StockQCSeq>235</StockQCSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026424,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030582