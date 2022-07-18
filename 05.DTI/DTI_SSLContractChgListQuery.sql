
IF OBJECT_ID('DTI_SSLContractChgListQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractChgListQuery 
GO

-- v2014.02.03 

-- 계약변경조회_DTI(조회) by이재천
CREATE PROC DTI_SSLContractChgListQuery                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle          INT,
            @ContractMngNo   NVARCHAR(100) ,
            @ContractNo      NVARCHAR(100)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ContractMngNo    = ISNULL(ContractMngNo,''), 
           @ContractNo       = ISNULL(ContractNo,'') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ContractMngNo       NVARCHAR(100) ,
            ContractNo          NVARCHAR(100) )
    
    CREATE TABLE #DTI_TSLContractMng 
    (
        ContractRev     INT, 
        ContractSeq     INT, 
        ContractMngNo   NVARCHAR(100), 
        ContractNo      NVARCHAR(100), 
        BizUnit         INT, 
        ContractDate    NCHAR(8), 
        SDate           NCHAR(8), 
        EDate           NCHAR(8), 
        CustSeq         INT, 
        EndUserSeq      INT, 
        UMContractKind  INT, 
        UMSalesCond     INT, 
        ContractEndDate NCHAR(8), 
        DeptSeq         INT, 
        EmpSeq          INT, 
        FSumPurAmt      DECIMAL(19,5), 
        FSumSalesAmt    DECIMAL(19,5), 
        FGPSumAmt       DECIMAL(19,5), 
        FGPRate         DECIMAL(19,5) 
    )
    
    -- 최초 차수 데이터 담기(최초차수가 AMD테이블일 경우)
    INSERT INTO #DTI_TSLContractMng 
    (
        ContractRev, 
        ContractSeq, 
        ContractMngNo, 
        ContractNo, 
        BizUnit, 
        ContractDate, 
        SDate, 
        EDate, 
        CustSeq, 
        EndUserSeq, 
        UMContractKind, 
        UMSalesCond, 
        ContractEndDate, 
        DeptSeq, 
        EmpSeq, 
        FSumPurAmt, 
        FSumSalesAmt, 
        FGPSumAmt, 
        FGPRate 
    )
    SELECT A.ContractRev, 
           A.ContractSeq, 
           A.ContractMngNo, 
           A.ContractNo, 
           A.BizUnit, 
           A.ContractDate, 
           A.SDate, 
           A.EDate, 
           A.CustSeq, 
           A.EndUserSeq, 
           A.UMContractKind, 
           A.UMSalesCond, 
           A.ContractEndDate, 
           A.DeptSeq, 
           A.EmpSeq, 
           SUM(PurAmt) AS FSumPurAmt, 
           SUM(SalesAmt) AS FSumSalesAmt, 
           SUM(SalesAmt) - SUM(PurAmt) AS FGPSumAmt,
           (SUM(SalesAmt) - SUM(PurAmt))/SUM(SalesAmt) * 100 AS FGPRate 
      FROM DTI_TSLContractMngRev AS A 
      JOIN DTI_TSLContractMngItemRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractNo = @ContractNo 
       AND (@ContractMngNo = '' OR A.ContractMngNo LIKE @ContractMngNo + '%')
       AND A.ContractRev = 0 
     GROUP BY A.ContractRev, A.ContractSeq, A.ContractMngNo, A.ContractNo, A.BizUnit, 
              A.ContractDate, A.SDate, A.EDate, A.CustSeq, A.EndUserSeq, 
              A.UMContractKind, A.UMSalesCond, A.ContractEndDate, A.DeptSeq, A.EmpSeq 
    
    -- 최초차수 데이터 담기 (최초차수가 본테이블일 경우)
    INSERT INTO #DTI_TSLContractMng 
    (
        ContractRev, 
        ContractSeq, 
        ContractMngNo, 
        ContractNo, 
        BizUnit, 
        ContractDate, 
        SDate, 
        EDate, 
        CustSeq, 
        EndUserSeq, 
        UMContractKind, 
        UMSalesCond, 
        ContractEndDate, 
        DeptSeq, 
        EmpSeq, 
        FSumPurAmt, 
        FSumSalesAmt, 
        FGPSumAmt, 
        FGPRate 
    )
    SELECT A.ContractRev, 
           A.ContractSeq, 
           A.ContractMngNo, 
           A.ContractNo, 
           A.BizUnit, 
           A.ContractDate, 
           A.SDate, 
           A.EDate, 
           A.CustSeq, 
           A.EndUserSeq, 
           A.UMContractKind, 
           A.UMSalesCond, 
           A.ContractEndDate, 
           A.DeptSeq, 
           A.EmpSeq,
           SUM(PurAmt), 
           SUM(SalesAmt), 
           SUM(SalesAmt) - SUM(PurAmt),
           (SUM(SalesAmt) - SUM(PurAmt))/SUM(SalesAmt) * 100
      FROM DTI_TSLContractMng       AS A 
      JOIN DTI_TSLContractMngItem   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractNo = @ContractNo 
       AND (@ContractMngNo = '' OR A.ContractMngNo LIKE @ContractMngNo + '%')
       AND A.ContractRev = 0 
     GROUP BY A.ContractRev, A.ContractSeq, A.ContractMngNo, A.ContractNo, A.BizUnit, 
              A.ContractDate, A.SDate, A.EDate, A.CustSeq, A.EndUserSeq, 
              A.UMContractKind, A.UMSalesCond, A.ContractEndDate, A.DeptSeq, A.EmpSeq 
    
    CREATE TABLE #TMP_ContractRev 
    (
     ContractRev    INT, 
     ContractSeq    INT
    )
    
    -- SS1 출력하기 위한 차수 담기
    INSERT INTO #TMP_ContractRev ( ContractRev, ContractSeq ) 
    SELECT A.ContractRev, A.ContractSeq
      FROM DTI_TSLContractMngRev AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractNo = @ContractNo 
    UNION ALL 
        SELECT A.ContractRev, A.ContractSeq 
      FROM DTI_TSLContractMng AS A WITH (NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq
       AND (@ContractMngNo = '' OR A.ContractMngNo LIKE @ContractMngNo + '%')
       AND A.ContractNo = @ContractNo         
    ORDER BY A.ContractRev 
    
    -- 최종 조회
    SELECT A.ContractRev, 
           A.ContractSeq, 
           C.BizUnitName AS FBizUnitName, 
           B.ContractDate AS FContractDate, 
           B.SDate AS FSDate, 
           B.EDate AS FEDate, 
           D.CustName AS FCustName, 
           D.CustNo AS FCustNo, 
           E.CustName AS FEndUserName, 
           F.MinorName AS FUMContractKindName, 
           G.DeptName AS FDeptName, 
           I.EmpName AS FEmpName, 
           B.ContractNo AS FContractNo, 
           B.ContractMngNo AS FContractMngNo, 
           J.MinorName AS FUMSalesCondName, 
           B.ContractEndDate AS FContractEndDate, 
           B.FSumPurAmt, 
           B.FSumSalesAmt, 
           B.FGPSumAmt, 
           B.FGPRate
           
      FROM #TMP_ContractRev         AS A 
      JOIN #DTI_TSLContractMng      AS B ON ( 1 = 1 ) 
      LEFT OUTER JOIN _TDABizUnit   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = B.BizUnit ) 
      LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.EndUserSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMContractKind ) 
      LEFT OUTER JOIN _TDADept      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.UMSalesCond ) 
    
    RETURN
GO
exec DTI_SSLContractChgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractNo>201402040004</ContractNo>
    <ContractMngNo>asdfasdf</ContractMngNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020773,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017476


--select * from DTI_TSLContractMng where companyseq  = 1 and contractno = '201401140003' 
--select * from DTI_TSLContractMngRev where companyseq = 1 and contractno = '201401140003' 