
IF OBJECT_ID('_SEQWorkOrderResultListQueryCHE') IS NOT NULL 
    DROP PROC _SEQWorkOrderResultListQueryCHE
GO 

-- v2015.01.26 

/************************************************************    
  설  명 - 데이터-작업실적조회 : 조회    
  작성일 - 20110519    
  작성자 - 김수용    
 ************************************************************/    
 CREATE PROC dbo._SEQWorkOrderResultListQueryCHE
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT             = 0,    
     @ServiceSeq     INT             = 0,    
     @WorkingTag     NVARCHAR(10)    = '',    
     @CompanySeq     INT             = 1,    
     @LanguageSeq    INT             = 1,    
     @UserSeq        INT             = 0,    
     @PgmSeq         INT             = 0    
 AS    
         
     DECLARE @docHandle           INT,    
             @QryFrDate           NCHAR(8) ,    
             @QryToDate           NCHAR(8) ,    
             @QryAccUnitSeq       INT ,    
             @QryWorkOperSerl     INT ,    
             @QryProgType         INT ,
             @WorkOperSeq         INT ,
             @QryWkDiv    INT ,
             @EmpSeq     INT ,
             @DeptClassSeq        INT
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
     
     SELECT  @QryFrDate           = QryFrDate            ,    
             @QryToDate           = QryToDate            ,    
             @QryAccUnitSeq       = QryAccUnitSeq        ,    
             @QryWorkOperSerl     = QryWorkOperSerl      ,    
             @QryProgType         = QryProgType          ,
             @WorkOperSeq         = WorkOperSeq   ,
             @QryWkDiv    = ISNULL(QryWkDiv, 0) ,
             @EmpSeq     = ISNULL(EmpSeq, 0)    ,
             @DeptClassSeq        = ISNULL(DeptClassSeq,0)
                           
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
       WITH  (QryFrDate            NCHAR(8) ,    
              QryToDate            NCHAR(8) ,    
              QryAccUnitSeq        INT ,    
              QryWorkOperSerl      INT ,    
              QryProgType          INT ,
              WorkOperSeq          INT ,
              QryWkDiv     INT ,
              EmpSeq      INT ,
              DeptClassSeq         INT)    
  
  IF @QryWkDiv = 6028004    
  BEGIN    
   SELECT @QryWkDiv = 20104001    
  END    
  ELSE IF @QryWkDiv = 6028005    
  BEGIN    
   SELECT @QryWkDiv = 20104005    
  END    
   
     SELECT DISTINCT  A.WorkType        ,
             E.FactUnitName  AS PdAccUnitName        ,     
             C.PdAccUnitSeq  AS PdAccUnitSeq         ,     
             F.ToolNo        AS ToolNo               ,     
             F.ToolName      AS  ToolName            ,     
             C.ToolSeq       AS  ToolSeq             ,     
                 
             G.SectionCode   AS SectionCode          ,     
             C.SectionSeq    AS  SectionSeq          ,     
             H.CCtrName      AS ActCenterName        ,     
             F1.MngValSeq    AS CCtrSeq              ,     
             I2.MinorName    AS ProgTypeName         ,     
             C2.MinorName    AS WorkOperName         ,  
                 
             C.ProgType      AS ProgType             ,     
             J.DeptName      AS ReqDeptName          ,     
             D.DeptSeq       AS ReqDeptSeq           ,     
             K.EmpName       AS ReqEmpName           ,     
             D.EmpSeq        AS ReqEmpSeq            ,     
             D.WorkName                              ,    
             D.ReqDate       AS ReqDate              ,     
             D.WONo          AS WONo                 ,     
             D.ReqCloseDate  AS ReqCloseDate         ,     
             A.WorkContents  AS WorkContents         ,     
             I1.MinorName    AS WorkOperSerlName     ,     
                 
             B.WorkOperSerl  AS WorkOperSerl         ,    
             B.WOReqSeq      AS WOReqSeq             ,    
             B.WOReqSerl     AS WOReqSerl            ,    
             B.ReceiptSeq    AS ReceiptSeq           ,
             A.DeptClassSeq               ,
             W4.MinorName    AS DeptClassName        ,
             CASE WHEN W1.ValueText = '1' THEN 'FrmEQWorkOrderActRltCHE'
                  WHEN W2.ValueText = '1' THEN 'FrmEQSWorkOrderActRltCHE'
                  WHEN W3.ValueText = '1' THEN 'FrmEQPreventRepairRltRegCHE'END AS JumpPgmId -- 111214 추가 by 천경민
       FROM  _TEQWorkOrderReceiptMasterCHE             AS A WITH (NOLOCK)    
             JOIN _TEQWorkOrderReceiptItemCHE          AS B WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq    
             JOIN _TEQWorkOrderReqItemCHE              AS C WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq AND B.WOReqSerl = C.WOReqSerl    
             LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE AS D WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = D.CompanySeq AND B.WOReqSeq = D.WOReqSeq
             LEFT OUTER JOIN _TDAFactUnit                AS E WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = E.CompanySeq AND C.PdAccUnitSeq = E.FactUnit    
             LEFT OUTER JOIN _TPDTool                    AS F WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = F.CompanySeq AND C.ToolSeq = F.ToolSeq    
             LEFT OUTER JOIN _TPDToolUserDefine          AS F1 WITH (NOLOCK) ON 1 = 1 AND F.CompanySeq = F1.CompanySeq AND F.ToolSeq = F1.ToolSeq AND F1.MngSerl = 1000005    
             LEFT OUTER JOIN _TPDSectionCodeCHE        AS G WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = G.CompanySeq AND C.SectionSeq = G.SectionSeq    
             LEFT OUTER JOIN _TDACCtr                    AS H WITH (NOLOCK) ON 1 = 1 AND F1.CompanySeq = H.CompanySeq AND F1.MngValSeq = H.CCtrSeq    
             LEFT OUTER JOIN _TDAUMinor                  AS I1 WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = I1.CompanySeq AND B.WorkOperSerl = I1.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor                  AS I2 WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = I2.CompanySeq AND C.ProgType = I2.MinorSeq    
             LEFT OUTER JOIN _TDADept                    AS J  WITH (NOLOCK) ON 1 = 1 AND D.CompanySeq = J.CompanySeq AND D.DeptSeq = J.DeptSeq    
             LEFT OUTER JOIN _TDAEmp                     AS K  WITH (NOLOCK) ON 1 = 1 AND D.CompanySeq = K.CompanySeq AND D.EmpSeq = K.EmpSeq    
             LEFT OUTER JOIN _TDAUMinor                  AS C2 WITH (NOLOCK) ON 1 = 1 AND C.CompanySeq = C2.CompanySeq AND C.WorkOperSeq = C2.MinorSeq
    LEFT OUTER JOIN _TDAUMinorValue             AS W1 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W1.CompanySeq AND A.WorkType = W1.MinorSeq AND W1.MinorSeq = 20104005 AND W1.Serl = 1000001 -- 일반작업
    LEFT OUTER JOIN _TDAUMinorValue             AS W2 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W2.CompanySeq AND A.WorkType = W2.MinorSeq AND W2.MinorSeq IN (20104001, 20104002) AND W2.Serl = 1000002 -- 자산화/특수
    LEFT OUTER JOIN _TDAUMinorValue             AS W3 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W3.CompanySeq AND A.WorkType = W3.MinorSeq AND W3.MinorSeq = 20104004 AND W3.Serl = 1000001 -- 예방정비
             LEFT OUTER JOIN (SELECT ReceiptSeq, EmpSeq FROM _TEQWorkRealResultCHE WHERE CompanySeq = @CompanySeq AND DivSeq = 20117001 AND EmpSeq = @EmpSeq) AS L ON A.ReceiptSeq = L.ReceiptSeq
             LEFT OUTER JOIN _TDAUMinor AS W4 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq    = W4.CompanySeq  AND A.DeptClassSeq  = W4.MinorSeq      
      WHERE 1 = 1    
        AND (A.CompanySeq    = @CompanySeq)    
        AND (A.ActRltDate    BETWEEN @QryFrDate AND @QryToDate)              
        AND (C.PdAccUnitSeq  = @QryAccUnitSeq  OR  @QryAccUnitSeq ='')    
        AND (B.WorkOperSerl  = @QryWorkOperSerl OR @QryWorkOperSerl ='')    
        AND (C.ProgType      = @QryProgType OR @QryProgType='')  
        AND (C.WorkOperSeq   = @WorkOperSeq OR @WorkOperSeq='')     
        AND (A.WorkType  = @QryWkDiv OR @QryWkDiv = 0)    
        AND (L.EmpSeq  = @EmpSeq OR @EmpSeq = 0)
        AND (A.DeptClassSeq  = @DeptClassSeq OR @DeptClassSeq = 0)
   
     UNION ALL
    
     SELECT A.WorkType        ,
             E.FactUnitName  AS PdAccUnitName        ,     
             C.FactUnit  AS PdAccUnitSeq         ,     
             F.ToolNo        AS ToolNo               ,     
             F.ToolName      AS  ToolName            ,     
             C.ToolSeq       AS  ToolSeq             ,     
                 
             G.SectionCode   AS SectionCode          ,     
             C.SectionSeq    AS  SectionSeq          ,     
             H.CCtrName      AS ActCenterName        ,     
             F1.MngValSeq    AS CCtrSeq              ,     
             '' AS ProgTypeName,
             C2.MinorName    AS WorkOperName         ,  
                 
             0 AS ProgType,
             '' AS ReqDeptName,
             0 AS ReqDeptSeq,
             '' AS ReqEmpName,
             0 AS ReqEmpSeq,
             '' WorkName,    
             A.ReceiptDate       AS ReqDate              ,     
             B.WorkOrderNo          AS WONo                 ,     
             '' AS ReqCloseDate,
             CASE WHEN A.WorkType = 20104004 THEN A.RltContents END  AS WorkContents         ,     
             I1.MinorName    AS WorkOperSerlName     ,     
                 
             0  AS WorkOperSerl         ,    
             B.WOReqSeq      AS WOReqSeq             ,    
             0 AS WOReqSerl,
             A.ReceiptSeq    AS ReceiptSeq           ,
             A.DeptClassSeq                          ,
             W4.MinorName    AS DeptClassName        ,            
             CASE WHEN W1.ValueText = '1' THEN 'FrmEQWorkOrderActRltCHE'
                  WHEN W2.ValueText = '1' THEN 'FrmEQSWorkOrderActRltCHE' 
                  WHEN W3.ValueText = '1' THEN 'FrmEQPreventRepairRltRegCHE'END AS JumpPgmId -- 111214 추가 by 천경민
  FROM _TEQPreventRepairRltMasterCHE              AS A WITH (NOLOCK)   
   LEFT JOIN _TEQPreventRepairWorkOrderCHE     AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq    
                        AND A.WOReqSeq = B.WOReqSeq
   LEFT OUTER JOIN _TEQPreventRepairRltItemCHE AS C  WITH (NOLOCK) ON 1 = 1 
                                                                    AND A.CompanySeq = C.CompanySeq 
                                                                    AND A.ReceiptSeq = C.ReceiptSeq  
   LEFT OUTER JOIN _TDAFactUnit                  AS E  WITH (NOLOCK) ON 1 = 1 
                                                                    AND A.CompanySeq = E.CompanySeq 
                                                                    AND C.FactUnit = E.FactUnit    
   LEFT OUTER JOIN _TPDTool                      AS F  WITH (NOLOCK) ON 1 = 1 
                                                                    AND A.CompanySeq = F.CompanySeq 
                                                                    AND C.ToolSeq = F.ToolSeq    
   LEFT OUTER JOIN _TPDToolUserDefine            AS F1 WITH (NOLOCK) ON 1 = 1 
                                                                    AND F.CompanySeq = F1.CompanySeq 
                                                                    AND F.ToolSeq = F1.ToolSeq 
                                                                    AND F1.MngSerl = 1000005    
   LEFT OUTER JOIN _TPDSectionCodeCHE          AS G  WITH (NOLOCK) ON 1 = 1 
                                                                    AND A.CompanySeq = G.CompanySeq 
                                                                    AND C.SectionSeq = G.SectionSeq    
   LEFT OUTER JOIN _TDACCtr                      AS H  WITH (NOLOCK) ON 1 = 1 
                                                                    AND F1.CompanySeq = H.CompanySeq 
                                                                    AND F1.MngValSeq = H.CCtrSeq    
   LEFT OUTER JOIN _TDAUMinor                    AS I1 WITH (NOLOCK) ON 1 = 1 
                                                                    AND B.CompanySeq = I1.CompanySeq 
                                                                    AND A.WorkOperSerl = I1.MinorSeq    
   LEFT OUTER JOIN _TDAUMinor                    AS C2 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = C2.CompanySeq AND A.WorkOperSeq = C2.MinorSeq
   LEFT OUTER JOIN _TDAUMinorValue               AS W1 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W1.CompanySeq AND A.WorkType = W1.MinorSeq AND W1.MinorSeq = 20104005 AND W1.Serl = 1000001 -- 일반작업
   LEFT OUTER JOIN _TDAUMinorValue               AS W2 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W2.CompanySeq AND A.WorkType = W2.MinorSeq AND W2.MinorSeq IN (20104001, 20104002) AND W2.Serl = 1000002 -- 자산화/특수
   LEFT OUTER JOIN _TDAUMinorValue               AS W3 WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = W3.CompanySeq AND A.WorkType = W3.MinorSeq AND W3.MinorSeq = 20104004 AND W3.Serl = 1000001 -- 예방정비
         LEFT OUTER JOIN (SELECT ReceiptSeq, DivSeq 
                            FROM _TEQPreventRepairRealResultCHE 
                           WHERE CompanySeq = @CompanySeq 
                             AND DivType = 20117001 
                             AND DivSeq = @EmpSeq) AS L ON A.ReceiptSeq = L.ReceiptSeq
         LEFT OUTER JOIN _TDAUMinor AS W4 WITH (NOLOCK) ON 1 = 1  
                                                       AND A.CompanySeq    = W4.CompanySeq  
                                                       AND A.DeptClassSeq  = W4.MinorSeq    
  WHERE (A.CompanySeq    = @CompanySeq)               
        AND (A.ReceiptDate   BETWEEN @QryFrDate AND @QryToDate)     
        AND (A.WorkType      = @QryWkDiv     OR @QryWkDiv ='')   -- 1000726004
        AND (A.WorkOperSeq   = @WorkOperSeq  OR @WorkOperSeq ='')    
        AND (L.DivSeq  = @EmpSeq OR @EmpSeq = 0)
        AND (A.DeptClassSeq  = @DeptClassSeq OR @DeptClassSeq = 0)
        
 RETURN
  GO
exec _SEQWorkOrderResultListQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QryWkDiv />
    <EmpSeq />
    <DeptClassSeq />
    <QryAccUnitSeq />
    <QryFrDate>20140101</QryFrDate>
    <QryToDate>20150126</QryToDate>
    <QryProgType />
    <WorkOperSeq />
    <QryWorkOperSerl />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10144,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100163


