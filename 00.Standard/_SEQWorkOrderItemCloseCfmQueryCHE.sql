
IF OBJECT_ID('_SEQWorkOrderItemCloseCfmQueryCHE') IS NOT NULL
    DROP PROC _SEQWorkOrderItemCloseCfmQueryCHE
GO 

-- v2015.01.26 
/************************************************************  
  설  명 - 데이터-작업완료확인승인 : 조회  
  작성일 - 20110518  
  작성자 - 김수용    
   
 ************************************************************/  
 CREATE PROC [dbo].[_SEQWorkOrderItemCloseCfmQueryCHE]  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT             = 0,  
     @ServiceSeq     INT             = 0,  
     @WorkingTag     NVARCHAR(10)    = '',  
     @CompanySeq     INT             = 1,  
     @LanguageSeq    INT             = 1,  
     @UserSeq        INT             = 0,  
     @PgmSeq         INT             = 0  
 AS  
       
     DECLARE @docHandle       INT,  
             @QryReqDeptSeq   INT ,  
             @ReqFrDate       NCHAR(8) ,  
             @ReqToDate       NCHAR(8) ,  
             @QryProgType     INT,  
             @QryWorkType     INT,
             @EmpSeq          INT,
             @WorkOperSeq     INT,
             @ToolSeq         INT,
             @WorkContents    NVARCHAR(400),
             @FactUnit        INT,
             @SectionCode     NVARCHAR(100),  
             @ReqDateFr       NCHAR(8),
             @ReqDateTo       NCHAR(8)
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
   
     SELECT  @QryReqDeptSeq   = ISNULL(QryReqDeptSeq,0)    ,  
             @ReqFrDate       = ISNULL(ReqFrDate,'')       ,  
             @ReqToDate       = ISNULL(ReqToDate,'')       ,  
             @QryProgType     = ISNULL(QryProgType,0)      ,  
             @QryWorkType     = ISNULL(QryWorkType,0)      ,
             @EmpSeq          = ISNULL(EmpSeq,0)           ,
             @WorkOperSeq     = ISNULL(WorkOperSeq,0)      ,
             @ToolSeq         = ISNULL(ToolSeq,0)          ,
             @WorkContents    = ISNULL(WorkContents,'')    ,
             @FactUnit        = ISNULL(FactUnit,0)         ,
             @SectionCode     = ISNULL(SectionCode,'')     ,
             @ReqDateFr       = ISNULL(ReqDateFr,'')       ,
             @ReqDateTo       = ISNULL(ReqDateTo,'')       
             
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
       WITH  (QryReqDeptSeq    INT ,  
              ReqFrDate        NCHAR(8) ,  
              ReqToDate        NCHAR(8) ,  
              QryProgType      INT,  
              QryWorkType      INT,
              EmpSeq           INT,
              WorkOperSeq      INT,
              ToolSeq          INT,
              WorkContents     NVARCHAR(400),
              FactUnit         INT,
              SectionCode      NVARCHAR(100),
              ReqDateFr        NCHAR(8),
              ReqDateTo        NCHAR(8))  
     
     
     IF @ReqDateFr = ''
         SELECT @ReqDateFr = '19991231'    
     IF @ReqDateTo = ''
         SELECT @ReqDateTo = '99991231'
         
       
     SELECT    
             CASE WHEN ISNULL(B.CfmEmpseq,0)=0 THEN 0 ELSE 1 END AS CfmYn,  
             A.WOReqSeq      AS WOReqSeq        ,   
             B.WOReqSerl     AS WOReqSerl       ,   
             A.WONo          AS   WONo             ,   
             E.DeptName      AS ReqDeptName     ,   
   
             D1.EmpName      AS  EmpName         ,   
             C1.MinorName    AS WorkTypeName    ,   
             A.ReqDate       AS  ReqDate       ,   
             C2.MinorName    AS  WorkOperName    ,   
             A.ReqCloseDate  AS ReqCloseDate  ,   
    
             A.WorkContents  AS WorkContents  ,   
             C3.MinorName    AS ProgTypeName    ,   
             C4.MinorName    AS ModWorkOperName ,   
             F.FactUnitName  AS PdAccUnitName   ,   
             B.AddType       AS  AddType        ,   
    
             G.ToolNo        AS ToolNo          ,   
             D2.EmpName      AS CfmReqEmpName    ,   
             G.ToolName      AS ToolName        ,   
             I.CCtrName      AS ActcenterName   ,   
             B.CfmReqDate    AS CfmReqDate      ,   
    
             B.ToolNo        AS NonToolNo,  
             A.WorkName      AS WorkName,         
             B.ProgType      AS ProgType,  
             A.WorkType      AS WorkType,  
             ISNULL(D3.EmpName,'')      AS CfmEmpName,  
               
             B.CfmDate       AS CfmDate  
               
       FROM  _TEQWorkOrderReqMasterCHE AS A WITH (NOLOCK)  
             JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq   
             LEFT OUTER JOIN _TEQWorkOrderReceiptItemCHE AS B1 WITH(NOLOCK) ON 1 = 1 AND B1.CompanySeq = @CompanySeq AND B1.WOReqSeq = B.WOReqSeq AND B1.WOReqSerl = B.WOReqSerl
             LEFT OUTER JOIN _TDAUMinor AS C1 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = C1.CompanySeq AND A.WorkType = C1.MinorSeq  
             LEFT OUTER JOIN _TDAUMinor AS C2 WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C2.CompanySeq AND B1.WorkOperSeq = C2.MinorSeq  
             LEFT OUTER JOIN _TDAUMinor AS C3 WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C3.CompanySeq AND B.ProgType = C3.MinorSeq  
             LEFT OUTER JOIN _TDAUMinor AS C4 WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C4.CompanySeq AND B.ModWorkOperSeq = C4.MinorSeq  
             LEFT OUTER JOIN _TDAEmp  AS D1  WITH (NOLOCK) ON 1 = 1 AND  A.CompanySeq = D1.CompanySeq AND A.EmpSeq = D1.EmpSeq  
             LEFT OUTER JOIN _TDAEmp  AS D2  WITH (NOLOCK) ON 1 = 1 AND  B.CompanySeq = D2.CompanySeq AND B.CfmReqEmpseq = D2.EmpSeq  
             LEFT OUTER JOIN _TDAEmp  AS D3  WITH (NOLOCK) ON 1 = 1 AND  B.CompanySeq = D3.CompanySeq AND B.CfmEmpseq = D3.EmpSeq  
             LEFT OUTER JOIN _TDADept AS E  WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = E.CompanySeq AND A.DeptSeq = E.DeptSeq  
             LEFT OUTER JOIN _TDAFactUnit AS F  WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = F.CompanySeq AND B.PdAccUnitSeq =F.FactUnit  
             LEFT OUTER JOIN _TPDTool AS G WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = G.CompanySeq AND B.ToolSeq = G.ToolSeq   
             LEFT OUTER JOIN _TPDToolUserDefine AS H WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = H.CompanySeq AND B.ToolSeq = H.ToolSeq AND H.MngSerl = 1000005  
             LEFT OUTER JOIN _TDACCtr AS I WITH (NOLOCK) ON 1 = 1 AND H.CompanySeq = I.CompanySeq AND H.MngValSeq = I.CCtrSeq 
             LEFT OUTER JOIN _TPDSectionCodeCHE AS SC WITH(NOLOCK) ON B.CompanySeq = SC.CompanySeq  
                                                                   AND B.SectionSeq = SC.SectionSeq  
      WHERE  1 = 1  
        AND (A.CompanySeq = @CompanySeq)  
        AND (A.DeptSeq    = @QryReqDeptSeq OR @QryReqDeptSeq='' )     
        AND (A.ReqDate BETWEEN @ReqDateFr AND  @ReqDateTo )  
        AND (B.CfmReqDate BETWEEN @ReqFrDate AND  @ReqToDate )  
        AND (@QryProgType = 0 OR B.ProgType   = @QryProgType)  
        AND (A.WorkType   = @QryWorkType OR @QryWorkType='')  
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)  
        AND (@WorkOperSeq = 0 OR B.WorkOperSeq = @WorkOperSeq) 
        AND (@ToolSeq = 0 OR B.ToolSeq = @ToolSeq)  
        AND (@WorkContents = '' OR A.WorkContents LIKE '%'+ @WorkContents + '%')         
        AND (@FactUnit = 0 OR B.PdAccUnitSeq = @FactUnit) 
        AND (@SectionCode = '' OR SC.SectionCode LIKE @SectionCode + '%')  
           
  RETURN