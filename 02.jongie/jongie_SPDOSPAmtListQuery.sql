  
IF OBJECT_ID('jongie_SPDOSPAmtListQuery') IS NOT NULL   
    DROP PROC jongie_SPDOSPAmtListQuery  
GO  
  
-- v2013.10.29 
  
-- 외주비이체조회_jongie by이재천
CREATE PROC jongie_SPDOSPAmtListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @DelvDateYM NVARCHAR(6), 
            @DeptSeq    INT, 
            @EmpSeq     INT, 
            @CustSeq    INT, 
            @CustNo     NVARCHAR(50) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvDateYM = ISNULL(DelvDateYM,''),  
           @DeptSeq    = ISNULL(DeptSeq,0), 
           @EmpSeq     = ISNULL(EmpSeq,0), 
           @CustSeq    = ISNULL(CustSeq,0),  
           @CustNo     = ISNULL(CustNo,'')  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      
      WITH (
            DelvDateYM NVARCHAR(6),
            DeptSeq    INT, 
            EmpSeq     INT, 
            CustSeq    INT, 
            CustNo     NVARCHAR(50)
           )    
      
    -- 최종조회   
    SELECT A.CustSeq, 
           MAX(C.CustName) AS CustName, 
           MAX(D.UMBankHQ) AS UMBankHQ, -- 금융기관코드
           MAX(E.MinorName) AS UMBankHQName, -- 금융기관
           MAX(D.BankAccNo) AS BankAccNo, -- 계좌번호 
           MAX(D.Owner) AS Owner, -- 예금주 
           SUM(ISNULL(B.CurAmt,0)) AS CurAmt, 
           SUM(ISNULL(B.CurVAT,0)) AS CurVAT, 
           SUM(ISNULL(B.CurAmt,0)) + SUM(ISNULL(B.CurVAT,0)) AS TotCurAmt, 
           MAX(dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq)) AS PersonId, -- 주민번호 
           MAX(F.DeptName) AS DeptName, 
           A.DeptSeq AS DeptSeq, 
           MAX(G.EmpName) AS EmpName, 
           A.EmpSeq AS EmpSeq, 
           MAX(C.CustNo) AS CustNo 
           
           
      FROM _TPDOSPDelvIn AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDOSPDelvInItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OSPDelvInSeq = A.OSPDelvInSeq ) 
      LEFT OUTER JOIN _TDACust          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACustBankAcc   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.UMBankHQ ) 
      LEFT OUTER JOIN _TDADept          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.EmpSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND @DelvDateYM = LEFT(A.OSPDelvInDate,6) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
       AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%') 
     GROUP BY A.CustSeq, A.DeptSeq, A.EmpSEq
    
    RETURN  
    GO
exec jongie_SPDOSPAmtListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DelvDateYM>201308</DelvDateYM>
    <DeptSeq />
    <EmpSeq />
    <CustSeq />
    <CustNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018913,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016022