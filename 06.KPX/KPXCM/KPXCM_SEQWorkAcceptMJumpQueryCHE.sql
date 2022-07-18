IF OBJECT_ID('KPXCM_SEQWorkAcceptMJumpQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkAcceptMJumpQueryCHE
GO 

-- v2014.01.20 
  -- JOIN - > LEFT OUTER JOIN 으로 변경 by이재천 
 /************************************************************  
   설  명 - 데이터-작업접수등록 : JumpM조회(작업요청에서 점프)  
   작성일 - 20110504  
   작성자 - 김수용  
  ************************************************************/  
  CREATE PROC KPXCM_SEQWorkAcceptMJumpQueryCHE 
      @xmlDocument    NVARCHAR(MAX),  
      @xmlFlags       INT             = 0,  
      @ServiceSeq     INT             = 0,  
      @WorkingTag     NVARCHAR(10)    = '',  
      @CompanySeq     INT             = 1,  
      @LanguageSeq    INT             = 1,  
      @UserSeq        INT             = 0,  
      @PgmSeq         INT             = 0  
  AS  
        
      DECLARE @docHandle      INT ,  
              @DeptName       NVARCHAR(30),  
              @DeptSeq        INT,  
              @EmpName        NVARCHAR(30),
              @EmpSeq         INT  
        
                
      CREATE TABLE #_TEQWorkOrderReceiptMasterCHE (WorkingTag NCHAR(1) NULL)  
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReceiptMasterCHE'        
     
    
     SELECT @EmpName = LTRIM(RTRIM(B.EmpName)),  
            @EmpSeq  = B.EmpSeq,
            @DeptSeq = B.DeptSeq,  
            @DeptName = LTRIM(RTRIM(ISNULL(B.DeptName,'')))  
       FROM _TCAUser AS A WITH (NOLOCK)   
            LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,CONVERT(CHAR(8),GETDATE(),112)) AS B ON  A.EmpSeq = B.EmpSeq
      WHERE 1 = 1  
        AND A.CompanySeq  = @CompanySeq  
        AND A.UserSeq     = @UserSeq      
     
     
     --SELECT * FROM #_TEQWorkOrderReceiptMasterCHE
     
      SELECT  DISTINCT 
              0  AS ReceiptSeq    ,   
              CONVERT(NCHAR(8),GETDATE(),112)  AS ReceiptDate    ,   
              @DeptName       AS DeptName,  
              @DeptSeq        AS DeptSeq,  
              @EmpName        AS EmpName,  
                
              @EmpSeq         AS EmpSeq,   
              D.DeptName      AS ReqDeptName,    
              B.DeptSeq       AS ReqDeptSeq,  
              C.EmpName       AS ReqEmpName,  
              B.EmpSeq        AS ReqEmpSeq,  
                         
              A.WorkTypeName  AS WorkTypeName  ,               
              A.WorkType      AS WorkType,  
              ''              AS  ProgTypeName  ,   
              0               AS ProgType ,   
                
              ''              AS  ReceiptReason  ,   
              ''              AS ReceiptNo   ,   
              --A.WorkOperName  AS WorkOperName      ,   
              --A.WorkOperSeq   AS WorkOperSeq   ,   
              --''  AS WorkOperSerlName ,   
    
              --0   AS WorkOperSerl     ,   
              B.ReqDate   AS ReqDate,  
              B.ReqCloseDate AS ReqCloseDate,  
              ''  AS WorkSubName,   
              0   AS WorkSubSeq       ,   
              A.WorkContents AS WorkContents     ,   
              CASE WHEN A.WorkType IN (1000726001,1000726002) THEN 1000733001 ELSE 0 END   AS WorkOwner        ,   
     
              CASE WHEN A.WorkType IN (1000726001,1000726002) THEN 1000734001 ELSE 0 END   AS NormalYn          ,   
              A.DeptSeq AS ReqDeptSeq       ,   
              A.DeptName AS ReqDeptName      ,   
              ''  AS WorkOwnerName    ,   
              ''  AS NormalYnName  , 
              A.WOReqSeq AS  WOReqSeq ,  
              B.WONo     AS WONo      ,
              '무' AS MRIssueYnName    , 
              F.ChangeCd     , 
              F1.MinorName AS ChangeName  ,
              B.AddDocYn,
              E1.MinorName AS AddDocYnName,
              B.SafeCfmType,
              E3.MinorName AS SafeCfmTypeName,
              B.FileSeq, 
              G.FactUnitName 
        FROM  #_TEQWorkOrderReceiptMasterCHE  AS A   
              JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  ON A.WOReqSeq = B.WOReqSeq AND B.CompanySeq =@CompanySeq  
              LEFT OUTER JOIN _TDAEmp AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND B.EmpSeq = C.EmpSeq    
              LEFT OUTER JOIN _TDADept AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND B.DeptSeq = D.DeptSeq 
              LEFT OUTER JOIN _TEQChangeReviewCHE AS F ON B.CompanySeq = F.CompanySeq AND B.Seq = F.Seq
              LEFT OUTER JOIN _TDASMinor AS E1 WITH(NOLOCK) ON B.CompanySeq = E1.CompanySeq  AND  B.AddDocYn = E1.MinorSeq
              LEFT OUTER JOIN _TDAUMinor AS F1 WITH(NOLOCK) ON F.CompanySeq = F1.CompanySeq  AND  F.ChangeCd = F1.MinorSeq
              LEFT OUTER JOIN _TDASMinor AS E3 WITH(NOLOCK) ON B.CompanySeq = E3.CompanySeq  AND  B.SafeCfmType = E3.MinorSeq              
              OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq  
                              FROM _TEQWorkOrderReqItemCHE AS Z   
                              LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq )   
                             WHERE Z.CompanySeq = @CompanySeq   
                               AND Z.WOReqSeq = A.WOReqSeq   
                          ) AS G 
      RETURN
      go
      exec KPXCM_SEQWorkAcceptMJumpQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WOReqSeq>39</WOReqSeq>
    <ReqDate>20150910</ReqDate>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <WorkType>20104005</WorkType>
    <WorkTypeName>일반보수작업</WorkTypeName>
    <ReqCloseDate>20150910</ReqCloseDate>
    <WorkContents>ㄴㄷㅅㅁㄴㄷㅅ</WorkContents>
    <WONo>GP-150910-001</WONo>
    <ProgTypeName>요청</ProgTypeName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025844