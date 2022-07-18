
IF OBJECT_ID('DTI_SSLContractMngAMDSubQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractMngAMDSubQuery
GO 

-- v2013.12.26 

-- 계약관리등록(AMD조회)_DTI(마스터조회) by이재천
CREATE PROC DTI_SSLContractMngAMDSubQuery                  
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle      INT, 
            @ContractRev    INT, 
            @ContractSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @ContractRev = ISNULL(ContractRev,0), 
           @ContractSeq = ISNULL(ContractSeq,0)           
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            ContractSeq INT ,  
            ContractRev INT
           )  
    
    
    SELECT A.ContractSeq, SUM(B.SalesAmt) AS SumSalesAmt, SUM(B.PurAmt) AS SumPurAmt  
      INTO #TMP1  
      FROM DTI_TSLContractMngRev             AS A  WITH(NOLOCK)   
      LEFT OUTER JOIN DTI_TSLContractMngItem AS B  WITH(NOLOCK) ON ( A.CompanySeq =B.CompanySeq AND A.ContractSeq=B.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev 
     GROUP BY A.ContractSeq  
    
    SELECT G.EmpName            , A.ContractDate       , A.EmpSeq       , A.FileSeq            , A.DeptSeq  ,   
           A.SDate              , A.IsCfm              , A.CfmEmpSeq    , A.EDate              , A.Remark   ,  
           A.CustSeq            , Temp.SumSalesAmt     , A.ContractSeq  , A.ContractNo         ,   
           A.ContractEndDate    , E.BizUnitName        , H.DeptName     ,   
           A.ContractMngNo      , A.BKCustSeq          , Temp.SumPurAmt , F.MinorName AS UMContractKindName ,   
           A.BizUnit            , A.UMContractKind     , A.CfmDate      , D.CustNo             ,             
           D.CustName           , I.EmpName AS CfmEmpName,  
           (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.EndUserSeq) AS EndUserName,  
           (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.BKCustSeq) AS BKCustName,             
           A.ContractRev, A.RevRemark, A.UMSalesCond, B.MinorName AS UMSalesCondName  
    
      FROM DTI_TSLContractMngRev    AS A  WITH(NOLOCK)   
      LEFT OUTER JOIN _TDACust      AS D  WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.CustSeq = D.CustSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS E  WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.BizUnit = E.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinor    AS F  WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.UMContractKind = F.MinorSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS G  WITH(NOLOCK) ON ( A.CompanySeq = G.Companyseq AND A.EmpSeq = G.EmpSeq ) 
      LEFT OUTER JOIN _TDADept      AS H  WITH(NOLOCK) ON ( A.CompanySeq = H.CompanySeq AND A.DeptSeq = H.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS I  WITH(NOLOCK) ON ( A.CompanySeq = I.Companyseq AND A.CfmEmpSeq =I.EmpSeq ) 
      LEFT OUTER JOIN #TMP1         AS Temp            ON ( A.ContractSeq=Temp.ContractSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMSalesCond )   
    
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev 
    
    RETURN  
GO
exec DTI_SSLContractMngAMDSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ContractRev>3</ContractRev>
    <ContractSeq>1000052</ContractSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020185,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016970