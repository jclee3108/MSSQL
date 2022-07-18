IF OBJECT_ID('KPXCM_SEQWorkAcceptDJumpQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkAcceptDJumpQueryCHE
GO 

-- 2015.09.10 
/************************************************************      
  설  명 - 데이터-작업접수등록 : JumpD조회(작업요청에서 점프)      
  작성일 - 20110504      
  작성자 - 김수용      
 ************************************************************/      
 CREATE PROC KPXCM_SEQWorkAcceptDJumpQueryCHE      
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT             = 0,      
     @ServiceSeq     INT             = 0,      
     @WorkingTag     NVARCHAR(10)    = '',      
     @CompanySeq     INT             = 1,      
     @LanguageSeq    INT             = 1,      
     @UserSeq        INT             = 0,      
     @PgmSeq         INT             = 0      
 AS      
           
        
        DECLARE  @docHandle      INT,      
                 @ReceiptSeq     INT       
                   
       
                   
     CREATE TABLE #_TEQWorkOrderReceiptItemCHE (WorkingTag NCHAR(1) NULL)      
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#_TEQWorkOrderReceiptItemCHE'            
           
      --select * from #_TEQWorkOrderReceiptItemCHE  
       
     SELECT  DISTINCT 
             0 AS Sel,      
             0 AS ReceiptSeq,      
             B.WOReqSeq AS WOReqSeq,      
             B.WOReqSerl AS WOReqSerl,      
             C.ReqDate  AS ReqDate,      
             A.DeptName AS DeptName,      
             C.DeptSeq  AS DeptSeq,      
             C.EmpSeq   AS EmpSeq,      
             A.EmpName  AS EmpName,      
             A.WorkTypeName AS WorkTypeName,      
             C.WorkType AS WorkType,      
             C.ReqCloseDate AS ReqCloseDate,      
             C.WorkContents AS WorkContents,      
             C.WONo  AS WONo,      
             C.FileSeq AS FileSeq,      
             0 AS ProgType,      
             '' AS  ModifyNo,      
             '' AS  SpendNo,      
             '' AS ModifyType,      
             '' AS AddDocYn,      
             '' As MRIssueYn,      
             '' AS SafeCfmType,      
             C.WorkName AS WorkName,      
             B.PdAccUnitSeq AS FactUnit,      
             S.FactUnitName AS FactUnitName,      
             B.ToolSeq AS ToolSeq,      
             K3.MngValText AS ToolName,      
             B.WorkOperSeq AS WorkOperSeq,      
             B.SectionSeq AS SectionSeq,      
             A.SectionCode AS SectionCode,      
             I.ToolNo AS ToolNo,      
             O.MinorName AS WorkOperName,      
             B.ToolNo AS NonCodeToolNo,      
             CASE WHEN I1.MngValSeq =0 THEN K2.CCtrName ELSE I2.CCtrName END AS  ActCenterName, -- ISNULL(I1.MngValSeq,K1.MngValSeq) AS ActCenterSeq,      
             CASE WHEN I1.MngValSeq =0 THEN K1.MngValSeq  ELSE I1.MngValSeq  END AS  ActCenterSeq, -- ISNULL(I1.MngValSeq,K1.MngValSeq) AS ActCenterSeq,      
             B.AddType AS AddType      
       FROM #_TEQWorkOrderReceiptItemCHE AS A       
            JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK) ON 1 = 1 AND   B.CompanySeq = @CompanySeq  AND A.WOReqSeq = B.WOReqSeq   
             --AND A.WOReqSerl = B.WOReqSerl      
            JOIN _TEQWorkOrderReqMasterCHE AS C  WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq      
            LEFT OUTER JOIN _TPDTool AS I WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq = I.CompanySeq AND B.ToolSeq = I.ToolSeq      
            LEFT OUTER JOIN _TPDTool AS K WITH (NOLOCK) ON 1 = 1 AND B.CompanySeq =K.CompanySeq AND  B.ToolSeq = K.ToolSeq      
            LEFT OUTER JOIN _TPDToolUserDefine AS I1 WITH (NOLOCK) ON 1 = 1 AND I.CompanySeq =I1.CompanySeq AND I.ToolSeq =I1.ToolSeq AND I1.MngSerl =1000005      
            LEFT OUTER JOIN _TPDToolUserDefine AS K1 WITH (NOLOCK) ON 1 = 1 AND K.CompanySeq =K1.CompanySeq AND K.ToolSeq =K1.ToolSeq AND K1.MngSerl =1000005      
            LEFT OUTER JOIN _TDACCtr AS I2  WITH (NOLOCK) ON 1 = 1 AND I1.CompanySeq =I2.CompanySeq AND I1.MngValSeq =I2.CCtrSeq     
            LEFT OUTER JOIN _TDACCtr AS K2  WITH (NOLOCK) ON 1 = 1 AND K1.CompanySeq =K2.CompanySeq AND K1.MngValSeq =K2.CCtrSeq   
            LEFT OUTER JOIN _TDAFactUnit AS S WITH (NOLOCK) ON B.CompanySeq = S.CompanySeq     
                                                           AND B.PdAccUnitSeq = S.FactUnit    -- 생산사업장   
            LEFT OUTER JOIN _TDAUMinor AS O WITH(NOLOCK) ON O.CompanySeq = B.CompanySeq    
                                                        AND O.MinorSeq = B.WorkOperSeq                                                                     
            LEFT OUTER JOIN _TPDToolUserDefine AS K3 WITH (NOLOCK) ON 1 = 1 AND K.CompanySeq =K3.CompanySeq AND K.ToolSeq =K3.ToolSeq AND K3.MngSerl =2
     WHERE 1 = 1      
       AND B.CompanySeq = @CompanySeq      
         
      RETURN     
      go  
exec KPXCM_SEQWorkAcceptDJumpQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WOReqSeq>40</WOReqSeq>
    <ReqDate>20150910</ReqDate>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <WorkType>20104005</WorkType>
    <WorkTypeName>일반보수작업</WorkTypeName>
    <ReqCloseDate>20150910</ReqCloseDate>
    <WorkContents>asdgasdgdfg</WorkContents>
    <WONo>GP-150910-002</WONo>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031983,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025844