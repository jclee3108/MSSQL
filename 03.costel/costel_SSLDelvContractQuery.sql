  
IF OBJECT_ID('costel_SSLDelvContractQuery') IS NOT NULL   
    DROP PROC costel_SSLDelvContractQuery  
GO  
  
-- v2013.09.05 
  
-- 납품계약등록_costel(조회) by이재천
CREATE PROC costel_SSLDelvContractQuery  
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
            @ContractSeq INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ContractSeq   = ISNULL( ContractSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ContractSeq   INT)    
    
    -- 최종조회   
    SELECT A.ContractSeq, 
           A.ContractRev, 
           A.PJTName, 
           A.PJTNo, 
           A.BizUnit, 
           B.BizUnitName, 
           A.CustSeq, 
           C.CustName, 
           A.BKCustSeq, 
           J.CustName AS BKCustName,
           A.ContractDate, 
           A.RegDate, 
           A.SalesEmpSeq, 
           D.EmpName AS SalesEmpName, 
           A.SalesDeptSeq, 
           E.DeptName AS SalesDeptName, 
           A.ContractDateFr, 
           A.ContractDateTo, 
           A.SMExpKind, 
           F.MinorName AS SMExpKindName, 
           A.BizEmpSeq, 
           G.EmpName AS BizEmpName, 
           A.BizDeptSeq, 
           H.DeptName AS BizDeptName, 
           A.MHOpenDate, 
           A.CurrSeq, 
           I.CurrName, 
           A.ExRate, 
           A.IsCfm, 
           A.CfmDate, 
           A.Remark, 
           A.IsStop, 
           A.StopDate,   
           CASE WHEN A.IsStop = 1 
                THEN 7027002   
                WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WITH(NOLOCK) WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = A.ContractSeq) = 
                     (SELECT COUNT(1) FROM costel_TSLDelvContractItem AS X WITH(NOLOCK) WHERE X.CompanySeq = @CompanySeq AND X.ContractSeq = A.ContractSeq)
                THEN 7027004
                WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WITH(NOLOCK) WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = A.ContractSeq) <> 0 AND
                     (SELECT COUNT(1) FROM _TSLOrderItem AS Z WITH(NOLOCK) WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = A.ContractSeq) < 
                     (SELECT COUNT(1) FROM costel_TSLDelvContractItem AS X WITH(NOLOCK) WHERE X.CompanySeq = @CompanySeq AND X.ContractSeq = A.ContractSeq) 
                THEN 7027005 
                WHEN A.IsCfm = 1 
                THEN 7027003 
                WHEN (SELECT COUNT(1) FROM _TSLOrderItem AS Z WITH(NOLOCK) WHERE Z.CompanySeq = @CompanySeq AND Z.Dummy6 = A.ContractSeq) = 0
                THEN 7027001
                END AS SMStatusSeq 
           
      FROM costel_TSLDelvContract AS A   
      LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.SalesEmpSeq ) 
      LEFT OUTER JOIN _TDADept    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.SalesDeptSeq ) 
      LEFT OUTER JOIN _TDASMinor  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.SMExpKind ) 
      LEFT OUTER JOIN _TDAEmp     AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.BizEmpSeq ) 
      LEFT OUTER JOIN _TDADept    AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.DeptSeq = A.BizDeptSeq ) 
      LEFT OUTER JOIN _TDACurr    AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDACust    AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.CustSeq = A.BKCustSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ContractSeq = @ContractSeq
    
    RETURN  
GO
exec costel_SSLDelvContractQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractSeq>48</ContractSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985