
IF OBJECT_ID('_SEQWorkAcceptDQueryCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDQueryCHE
GO 

-- v2014.12.04 

/************************************************************  
  설  명 - 데이터-작업접수등록 : D조회  
  작성일 - 20110504  
  작성자 - 김수용  
 ************************************************************/  
 CREATE PROC [dbo].[_SEQWorkAcceptDQueryCHE]  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT             = 0,  
     @ServiceSeq     INT             = 0,  
     @WorkingTag     NVARCHAR(10)    = '',  
     @CompanySeq     INT             = 1,  
     @LanguageSeq    INT             = 1,  
     @UserSeq        INT             = 0,  
     @PgmSeq         INT             = 0  
 AS  
       
     DECLARE @docHandle      INT,  
             @ReceiptSeq    INT   
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
   
     SELECT  @ReceiptSeq    = ReceiptSeq       
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)  
       WITH  (ReceiptSeq     INT )  
       
     --SELECT  ReceiptSeq    ,   
     --        WOReqSeq      , WOReqSerl     , ReqDate       , DeptName      , DeptSeq       ,   
     --        EmpSeq        , EmpName       , WorkTypeName  , WorkType      , ReqCloseDate  ,   
     --        WorkContents  , WONo          , FileSeq       , ProgType      , ModifyNo      ,   
     --        SpendNo       , ModifyType    , AddDocYn      , MRIssueYn     , SafeCfmType   ,   
     --        WorkName      , PdAccUnitSeq  , PdAccUnitName , ToolSeq       , ToolName      ,   
     --        WorkOperSeq   , SectionSeq    , SectionCode   , ToolNo        , WorkOperName  ,   
     --        NonCodeToolNo  
     --  FROM  _TEQWorkOrderReceiptItemCHE AS A WITH (NOLOCK)  
     -- WHERE 1 = 1  
     --   AND A.CompanySeq = @CompanySeq  
     --   AND A.ReceiptSeq = @ReceiptSeq     
     SELECT 0 AS Sel,  
             A.ReceiptSeq,  
             A.WOReqSeq,  
             A.WOReqSerl,  
             C.ReqDate,  
             E.DeptName,  
             D.DeptSeq,  
             D.EmpSeq,  
             F.EmpName,  
             G1.MinorName AS WorkTypeName,  
             D.WorkType AS WorkType,  
             ReqCloseDate,  
             D.WorkContents AS WorkContents,  
             WONo,  
             C.FileSeq, 
             B.ProgType AS ProgType,  
             PdAccUnitSeq,  
             H.FactUnitName AS PdAccUnitName,  
             B.ToolSeq,  
             I.ToolName AS ToolName,  
             G2.MinorName AS WorkOperName,  
             A.WorkOperSeq AS WorkOperSeq,  
             G3.MinorName AS WorkOperSerlName,  
             A.WorkOperSerl AS WorkOperSerl,  
             B.SectionSeq,  
             J.SectionCode,  
             I.ToolNo AS ToolNo,  
             G2.MinorName AS WorkOperName,  
             B.ToolNo AS NonCodeToolNo,  
             CASE WHEN I1.MngValSeq =0 THEN K2.CCtrName ELSE I2.CCtrName END AS  ActCenterName, -- ISNULL(I1.MngValSeq,K1.MngValSeq) AS ActCenterSeq,  
             CASE WHEN I1.MngValSeq =0 THEN K1.MngValSeq  ELSE I1.MngValSeq  END AS  ActCenterSeq, -- ISNULL(I1.MngValSeq,K1.MngValSeq) AS ActCenterSeq,  
             B.AddType AS AddType  
       FROM _TEQWorkOrderReceiptItemCHE AS A WITH (NOLOCK)  
            LEFT OUTER JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq AND A.WOReqSerl = B.WOReqSerl  
            LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE AS C  WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq  
            LEFT OUTER JOIN _TEQWorkOrderReceiptMasterCHE AS D  WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = D.CompanySeq AND A.ReceiptSeq = D.ReceiptSeq  
            LEFT OUTER JOIN _TDADept AS E WITH (NOLOCK) ON 1 =1 AND D.CompanySeq = E.CompanySeq AND D.DeptSeq = E.DeptSeq  
            LEFT OUTER JOIN _TDAEmp AS F WITH (NOLOCK) ON 1 =1 AND D.CompanySeq = F.CompanySeq AND D.EmpSeq = F.EmpSeq  
            LEFT OUTER JOIN _TDAUMinor AS G1 WITH (NOLOCK) ON 1 = 1 AND D.CompanySeq = G1.CompanySeq AND  D.WorkType = G1.MinorSeq  
            LEFT OUTER JOIN _TDAUMinor AS G2 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = G2.CompanySeq AND  A.WorkOperSeq = G2.MinorSeq              
            LEFT OUTER JOIN _TDAUMinor AS G3 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = G3.CompanySeq AND  A.WorkOperSerl = G3.MinorSeq             
            LEFT OUTER JOIN _TDAFactUnit AS H  WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = H.CompanySeq AND B.PdAccUnitSeq = H.FactUnit  
            LEFT OUTER JOIN _TPDTool AS I WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = I.CompanySeq AND B.ToolSeq = I.ToolSeq  
            LEFT OUTER JOIN _TPDTool AS K WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq =K.CompanySeq AND  B.ToolSeq = K.ToolSeq  
            LEFT OUTER JOIN _TPDToolUserDefine AS I1 WITH (NOLOCK) ON 1 = 1 AND I.CompanySeq =I1.CompanySeq AND I.ToolSeq =I1.ToolSeq AND I1.MngSerl =1000005  
            LEFT OUTER JOIN _TPDToolUserDefine AS K1 WITH (NOLOCK) ON 1 = 1 AND K.CompanySeq =K1.CompanySeq AND K.ToolSeq =K1.ToolSeq AND K1.MngSerl =1000005  
            LEFT OUTER JOIN _TDACCtr AS I2  WITH (NOLOCK) ON 1 = 1 AND I1.CompanySeq =I2.CompanySeq AND I1.MngValSeq =I2.CCtrSeq  
            LEFT OUTER JOIN _TDACCtr AS K2  WITH (NOLOCK) ON 1 = 1 AND K1.CompanySeq =K2.CompanySeq AND K1.MngValSeq =K2.CCtrSeq  
            LEFT OUTER JOIN _TPDSectionCodeCHE AS J WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = J.CompanySeq AND B.SectionSeq =J.SectionSeq  
     WHERE 1 = 1  
        AND A.CompanySeq = @CompanySeq  
        AND A.ReceiptSeq = @ReceiptSeq     
      RETURN
GO 
exec _SEQWorkAcceptDQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>17</ReceiptSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150