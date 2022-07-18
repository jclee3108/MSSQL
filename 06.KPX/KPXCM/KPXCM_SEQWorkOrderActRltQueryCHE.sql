IF OBJECT_ID('KPXCM_SEQWorkOrderActRltQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkOrderActRltQueryCHE
GO 

-- v2015.09.10

/************************************************************
  설  명 - 데이터-작업실적Master : 조회(일반)
  작성일 - 20110518
  작성자 - 신용식
 ************************************************************/
 CREATE PROC dbo.KPXCM_SEQWorkOrderActRltQueryCHE
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
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (ReceiptSeq     INT )
     
     SELECT  A.ReceiptSeq    , 
             A.ReceiptDate   , 
             A.DeptSeq AS RecDeptSeq       , 
             --A.DeptName      , 
             A.EmpSeq AS RecEmpSeq        , 
             --A.EmpName       , 
             A.WorkType      , 
             --A.WorkTypeName  , 
             A.ProgType      , 
             --A.ProgTypeName  , 
             A.ReceiptReason , 
             A.ReceiptNo     , 
             A.WorkContents  , 
             A.WorkOwner     , 
             A.NormalYn      , 
             (CASE WHEN ISNULL(RTRIM(A.ActRltDate),'') = '' THEN CONVERT(NCHAR(8),GETDATE(),112) ELSE A.ActRltDate END) AS ActRltDate, 
             A.CommSeq       , 
             --A.CommName    , 
             A.WkSubSeq      , 
             F.MinorName AS WkSubName,
             --A.WkSubName     , 
             C.ReqDate       , 
             E.DeptName      , 
             C.DeptSeq       , 
             C.EmpSeq        , 
             D.EmpName       , 
             --A.WorkTypeName  , 
             C.WorkType      , 
             C.ReqCloseDate  , 
             C.WONo          , 
             C.FileSeq       ,
             A.DeptClassSeq  ,
             G.MinorName AS DeptClassName, 
             H.FactUnitName, 
             I.EmpName AS AcceptEmpName, 
             J.DeptName AS AcceptDeptName, 
             L.DeptName AS SaveDeptName, 
             L.EmpName AS SaveEmpName 
       FROM  _TEQWorkOrderReceiptMasterCHE    AS A WITH (NOLOCK)
             JOIN _TEQWorkOrderReceiptItemCHE AS B ON A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq
             LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq    -- 작업요청 Master
             LEFT OUTER JOIN _TDAEmp    AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq AND C.EmpSeq = D.EmpSeq
             LEFT OUTER JOIN _TDADept   AS E WITH(NOLOCK) ON C.CompanySeq = E.CompanySeq AND C.DeptSeq = E.DeptSeq
             LEFT OUTER JOIN _TDAUMinor AS F WITH(NOLOCK) ON F.CompanySeq = A.CompanySeq AND A.WkSubSeq = F.MinorSeq
             LEFT OUTER JOIN _TDAUMinor AS G WITH (NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.DeptClassSeq = G.MinorSeq                    
             OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq  
                             FROM _TEQWorkOrderReqItemCHE AS Z   
                             LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq )   
                            WHERE Z.CompanySeq = @CompanySeq   
                              AND Z.WOReqSeq = C.WOReqSeq   
                         ) AS H 
             LEFT OUTER JOIN _TDAEmp   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = A.EmpSeq ) 
             LEFT OUTER JOIN _TDADept  AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = A.DeptSeq ) 
             LEFT OUTER JOIN _TCAUser                              AS K ON ( K.CompanySeq = @CompanySeq AND K.UserSeq = A.LastUserSeq ) 
             LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS L ON ( L.EmpSeq = K.EmpSeq ) 
      WHERE  A.CompanySeq = @CompanySeq
        AND  A.ReceiptSeq = @ReceiptSeq    
    
    RETURN
GO 
begin tran 
exec KPXCM_SEQWorkOrderActRltQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>12</ReceiptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10223,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025850
rollback 