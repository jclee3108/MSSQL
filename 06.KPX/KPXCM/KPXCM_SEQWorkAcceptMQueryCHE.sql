IF OBJECT_ID('KPXCM_SEQWorkAcceptMQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkAcceptMQueryCHE
GO 


-- v2015.09.10
  /************************************************************  
   설  명 - 데이터-작업접수등록 : M조회  
   작성일 - 20110504  
   작성자 - 김수용  
  ************************************************************/  
  CREATE PROC KPXCM_SEQWorkAcceptMQueryCHE  
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
              @ReceiptSeq     INT ,  
              @ReqDeptSeq     INT,  
              @ReqDeptName    NCHAR(30),  
              @ReqDate        NCHAR(8),  
              @ReqCloseDate   NCHAR(8),  
              @WOReqSeq       INT  
                
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    
      SELECT  @ReceiptSeq       = ReceiptSeq,  
              @WOReqSeq         = WOReqSeq  
        FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
        WITH  (ReceiptSeq        INT,  
               WOReqSeq          INT )  
        
        
        
        
        SELECT  @ReqDeptSeq   = MIN(B.DeptSeq),  
                @ReqDate      = MIN(B.ReqDate),  
                @ReqCloseDate = MIN(B.ReqCloseDate)  
          FROM _TEQWorkOrderReceiptItemCHE AS A WITH (NOLOCK)   
               JOIN _TEQWorkOrderReqMasterCHE AS B  ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.WOReqSeq =B.WOReqSeq  
         WHERE 1 = 1  
           AND A.CompanySeq = @CompanySeq  
           AND A.ReceiptSeq = @ReceiptSeq  
        
        SELECT @ReqDeptName = Ltrim(Rtrim(DeptName))   
          FROM _TDADept   
         WHERE 1 = 1  
           AND CompanySeq = @CompanySeq  
           AND DeptSeq  = @ReqDeptSeq  
     
   
     
      SELECT  A.ReceiptSeq      AS ReceiptSeq    ,   
              A.ReceiptDate     AS ReceiptDate    ,   
              DeptName          AS DeptName,  
              A.DeptSeq         AS DeptSeq     ,   
              C.EmpName         AS EmpName,  
              A.EmpSeq          AS EmpSeq     ,   
              D1.MinorName      AS WorkTypeName         ,   
                
              A.WorkType        AS WorkType,  
              D2.MinorName      AS  ProgTypeName         ,   
              A.ProgType        AS ProgType,   
              ReceiptReason     AS ReceiptReason,   
              ReceiptNo         AS ReceiptNo,   
              --D3.MinorName AS WorkOperName      ,   
              --WorkOperSeq      ,   
                
              --D4.MinorName AS     WorkOperSerlName ,   
              --WorkOperSerl     ,   
                
              --D5.MinorName AS       WorkSubName,   
              --WorkSubSeq       ,   
              A.WorkContents     ,   
              A.WorkOwner        ,   
              A.NormalYn          ,   
              @ReqDeptSeq       AS ReqDeptSeq       ,   
              @ReqDeptName      AS ReqDeptName      ,   
              D6.MinorName      AS WorkOwnerName    ,   
              D7.MinorName      AS NormalYnName    ,  
              @ReqDate          AS ReqDate,  
              @ReqCloseDate     AS ReqcloseDate ,  
              '' AS  ModifyNo,  
              '' AS  SpendNo,  
              '무' AS MRIssueYnName    , 
              F.ChangeCd     , 
              F1.MinorName AS ChangeName  ,
              E.AddDocYn,
              E1.MinorName AS AddDocYnName,
              E.SafeCfmType,
              E3.MinorName AS SafeCfmTypeName,  
              E.WorkName,
              E.FileSeq, 
              A.FileSeq AS FileSeqSub, 
              G.FactUnitName 
        FROM  _TEQWorkOrderReceiptMasterCHE AS A WITH (NOLOCK)   
              
              LEFT OUTER JOIN _TDADept AS B WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq  
              LEFT OUTER JOIN _TDAEmp AS C WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq  
              LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE AS E ON A.CompanySeq = E.CompanySeq AND E.WOReqSeq = @WOReqSeq
              LEFT OUTER JOIN _TEQChangeReviewCHE AS F ON E.CompanySeq = F.CompanySeq AND E.Seq = F.Seq
              LEFT OUTER JOIN _TDAUMinor AS D1  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D1.CompanySeq AND A.WorkType = D1.MinorSeq   
              LEFT OUTER JOIN _TDAUMinor AS D2  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D2.CompanySeq AND A.ProgType = D2.MinorSeq   
              --LEFT OUTER JOIN _TDAUMinor AS D3  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D3.CompanySeq AND A.WorkOperSeq = D3.MinorSeq   
              --LEFT OUTER JOIN _TDAUMinor AS D4  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D4.CompanySeq AND A.WorkOperSerl = D4.MinorSeq   
              --LEFT OUTER JOIN _TDAUMinor AS D5  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D5.CompanySeq AND A.WorkSubSeq = D5.MinorSeq   
              LEFT OUTER JOIN _TDAUMinor AS D6  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D6.CompanySeq AND A.WorkOwner = D6.MinorSeq   
              LEFT OUTER JOIN _TDAUMinor AS D7  WITH (NOLOCK) ON 1 =1 AND A.CompanySeq = D7.CompanySeq AND A.NormalYn = D7.MinorSeq 
              LEFT OUTER JOIN _TDASMinor AS E1 WITH(NOLOCK) ON E.CompanySeq = E1.CompanySeq  AND  E.AddDocYn = E1.MinorSeq
              LEFT OUTER JOIN _TDAUMinor AS F1 WITH(NOLOCK) ON F.CompanySeq = F1.CompanySeq  AND  F.ChangeCd = F1.MinorSeq
              LEFT OUTER JOIN _TDASMinor AS E3 WITH(NOLOCK) ON E.CompanySeq = E3.CompanySeq  AND  E.SafeCfmType = E3.MinorSeq              
              OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq  
                              FROM _TEQWorkOrderReqItemCHE AS Z   
                              LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq )   
                             WHERE Z.CompanySeq = @CompanySeq   
                               AND Z.WOReqSeq = E.WOReqSeq   
                          ) AS G 
       WHERE  A.CompanySeq = @CompanySeq  
         AND A.ReceiptSeq  = @ReceiptSeq        
           
    
      RETURN
      go
      exec KPXCM_SEQWorkAcceptMQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReceiptSeq>12</ReceiptSeq>
    <WOReqSeq>40</WOReqSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025844