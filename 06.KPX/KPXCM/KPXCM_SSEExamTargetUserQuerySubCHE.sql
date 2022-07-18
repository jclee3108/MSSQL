IF OBJECT_ID('KPXCM_SSEExamTargetUserQuerySubCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEExamTargetUserQuerySubCHE
GO 

-- v2015.08.05 

-- 검진대상자 등록 (사원조회) by이재천 
CREATE PROC [dbo].KPXCM_SSEExamTargetUserQuerySubCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    
    DECLARE @docHandle          INT,
            @SubExamTargetSeq   INT, 
            @SubEmpName         NVARCHAR(100) 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

    SELECT @SubExamTargetSeq    = ISNULL(SubExamTargetSeq,0), 
           @SubEmpName          = ISNULL(SubEmpName,'') 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH (
               SubExamTargetSeq INT, 
               SubEmpName       NVARCHAR(100)   
           )
    
    SELECT  A.ExamTargetSeq     ,
            A.ExamTargetUserSeq ,
            A.EmpSeq            ,
            B.EmpId             ,
            B.EmpName           ,
            B.DeptSeq           ,
            B.DeptName          ,
            E.ResidId           ,
            C.MedNo2    AS MedNo,
            B.EntDate           ,        
            D.CellPhone AS CellPhoneASPhone,
            A.MaterialSeq1      ,
            A.MaterialSeq2      ,
            A.Remark
      FROM  KPXCM_TSEExamTargetUserCHE AS A WITH (NOLOCK)
            LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'')    AS B ON A.EmpSeq = B.EmpSeq
            LEFT OUTER JOIN _THRBasEmpPayInfo                   AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq
            LEFT OUTER JOIN _TDAEmpIn                           AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq
            LEFT OUTER JOIN _TDAEmp                             AS E WITH (NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq    = @CompanySeq
       AND A.ExamTargetSeq = @SubExamTargetSeq 
       AND (@SubEmpName = '' OR B.EmpName LIKE @SubEmpName + '%') 

    RETURN

	go
exec KPXCM_SSEExamTargetUserQuerySubCHE @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SubExamTargetSeq>3</SubExamTargetSeq>
    <SubEmpName>이재천</SubEmpName>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030968,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025819