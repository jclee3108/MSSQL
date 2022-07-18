IF OBJECT_ID('KPXCM_SEQWorkOrderAcceptInfoGWQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkOrderAcceptInfoGWQueryCHE
GO 

-- v2015.10.14 

-- 작업접수조회 그룹웨어 조회 by이재천 
 /************************************************************    
  설  명 - 데이터-작업접수현황조회 : 일반조회    
  작성일 - 20110430    
  작성자 - 김수용    
 ************************************************************/    
 CREATE PROC KPXCM_SEQWorkOrderAcceptInfoGWQueryCHE 
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT             = 0,    
     @ServiceSeq     INT             = 0,    
     @WorkingTag     NVARCHAR(10)    = '',    
     @CompanySeq     INT             = 1,    
     @LanguageSeq    INT             = 1,    
     @UserSeq        INT             = 0,    
     @PgmSeq         INT             = 0    
 AS    

    DECLARE @docHandle  INT,  
            @ReceiptSeq INT 
          
          
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
    
    CREATE TABLE #TEQWorkOrderReceiptMasterCHE ( ReceiptSeq INT ) 
    
    INSERT INTO #TEQWorkOrderReceiptMasterCHE ( ReceiptSeq ) 
     SELECT  ISNULL(ReceiptSeq, 0)      
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
       WITH (      
             ReceiptSeq      INT      
            ) 
    
    SELECT DISTINCT 
           ISNULL(C2.IsPrn, '0') AS IsPrn,  
           A.ReceiptSeq       AS ReceiptSeq,     
           B.WOReqSeq         AS WOReqSeq,     
           B.WOReqSerl        AS WOReqSerl,     
           C.WONo             AS WONo,    
           ISNULL(D2.DeptName,'')  AS DeptName      ,     
           C.DeptSeq               AS DeptSeq,    
           ISNULL(E2.EmpName,'')   AS EmpName       ,     
           C.EmpSeq                AS EmpSeq        ,    
           C.ReqDate               AS ReqDate        ,     
           C.WorkName                                ,    
           ISNULL(F1.MinorName,'')     AS WorkTypeName     ,     
           ISNULL(C.ReqCloseDate,'')   AS ReqCloseDate       ,    
           ISNULL(F2.MinorName,'')     AS WorkOperName     ,     
           C.WorkContents              AS WorkContents,    
           ISNULL(F3.MinorName,'')     AS WorkOperSerlName,    
           B.WorkOperSerl,
           ISNULL(G.FactUnitName,'')   AS PdAccUnitName    ,     
           ISNULL(H1.ToolNo,'')        AS ToolNo           ,     
           ISNULL(H1.ToolName,'')      AS ToolName         ,     
           ISNULL(J.SectionName,'')    AS SectionName      ,     
           ISNULL(I.CCtrName,'')       AS CCtrName         ,  
           ISNULL(C2.ToolNo,'')        AS NonCodeToolNo    ,     
           ISNULL(F4.MinorName,'')     AS ProgTypeName     ,     
           ISNULL(D1.DeptName,'')      AS RcpDeptName      ,     
           ISNULL(E1.EmpName,'')       AS RcpEmpName       ,     
           A.ReceiptDate               AS ReceiptDate      ,  
           A.ReceiptNo   AS ReceiptNo    
    
      FROM  #TEQWorkOrderReceiptMasterCHE AS Z 
      JOIN _TEQWorkOrderReceiptMasterCHE AS A ON ( A.CompanySeq = @CompanySeq AND A.ReceiptSeq = Z.ReceiptSeq ) 
      JOIN _TEQWorkOrderReceiptItemCHE AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq   AND A.ReceiptSeq = B.ReceiptSeq        
      LEFT JOIN _TEQWorkOrderReqMasterCHE AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq AND B.WOReqSeq   = C.WOReqSeq        
      LEFT JOIN _TEQWorkOrderReqItemCHE   AS C2 WITH  (NOLOCK) ON B.CompanySeq = C2.CompanySeq AND B.WOReqSeq   = C2.WOReqSeq  AND B.WOReqSerl = C2.WOReqSerl      
      LEFT OUTER JOIN _TDADept AS D1 WITH (NOLOCK)  ON  A.CompanySeq = D1.CompanySeq  AND A.DeptSeq = D1.DeptSeq         
      LEFT OUTER JOIN _TDAEmp AS E1 WITH (NOLOCK) ON  A.CompanySeq = E1.CompanySeq  AND A.EmpSeq = E1.EmpSeq    
      LEFT OUTER JOIN _TDADept AS D2 WITH (NOLOCK) ON  C.CompanySeq = D2.CompanySeq    AND C.DeptSeq = D2.DeptSeq         
      LEFT OUTER JOIN _TDAEmp AS E2 WITH (NOLOCK) ON  C.CompanySeq = E2.CompanySeq   AND C.EmpSeq = E2.EmpSeq    
      LEFT OUTER JOIN _TDAUMinor AS F1 WITH (NOLOCK) ON A.CompanySeq = F1.CompanySeq AND A.WorkType = F1.MinorSeq    -- 작업구분    
      LEFT OUTER JOIN _TDAUMinor AS F2 WITH (NOLOCK) ON A.CompanySeq = F2.CompanySeq AND B.WorkOperSeq = F2.MinorSeq    -- 작업수행과    
      LEFT OUTER JOIN _TDAUMinor AS F3 WITH (NOLOCK) ON A.CompanySeq = F3.CompanySeq AND B.WorkOperSerl = F3.MinorSeq    -- 직종    
      LEFT OUTER JOIN _TDAUMinor AS F4 WITH (NOLOCK) ON A.CompanySeq = F4.CompanySeq AND A.ProgType = F4.MinorSeq    -- 진행상태    
      LEFT OUTER JOIN _TPDTool   AS H1  WITH (NOLOCK) ON C2.CompanySeq = H1.CompanySeq AND C2.ToolSeq   = H1.ToolSeq    -- 설비    
      LEFT OUTER JOIN _TPDToolUserDefine AS H2 WITH(NOLOCK) ON H1.CompanySeq = H2.CompanySeq AND H1.ToolSeq =H2.ToolSeq AND H2.MngSerl =1000003   -- 섹션코드    
      LEFT OUTER JOIN _TPDToolUserDefine AS H3 WITH(NOLOCK) ON H1.CompanySeq = H3.CompanySeq AND H1.ToolSeq =H3.ToolSeq AND H3.MngSerl =1000005   -- 활동센터    
      LEFT OUTER JOIN _TDACCtr   AS I WITH (NOLOCK) ON H3.CompanySeq = I.CompanySeq AND H3.MngValSeq = I.CCtrSeq 
      LEFT OUTER JOIN _TPDSectionCodeCHE AS J WITH (NOLOCK) On J.CompanySeq = @CompanySeq AND J.FactUnit = C2.PdAccUnitSeq AND H2.MngValText = J.SectionCode 
      LEFT OUTER JOIN _TDAFactUnit AS G WITH (NOLOCK) ON C2.CompanySeq = G.CompanySeq AND C2.PdAccUnitSeq = G.FactUnit    -- 생산사업장    
    
     RETURN    
go
EXEC _SCOMGroupWarePrint 2, 1, 1, 1025848, 'OrderReceipt_CM', 'GROUP000000000000220', ''

--select * From _TCAPgm where Caption like '%전자결재%'

--_TEQWorkOrderReceiptMasterCHE_Confirm
