
IF OBJECT_ID('DTI_SSLContractChgListSubQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractChgListSubQuery 
GO

-- v2014.02.04 

-- 계약변경조회_DTI(서브조회) by이재천
CREATE PROC DTI_SSLContractChgListSubQuery                
    @xmlDocument    NVARCHAR(MAX) , 
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
            ContractRev INT, 
            ContractSeq INT 
           )
    
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
        ChgSumPurAmt    DECIMAL(19,5), 
        ChgSumSalesAmt  DECIMAL(19,5), 
        ChgGPSumAmt     DECIMAL(19,5), 
        ChgGPRate       DECIMAL(19,5) 
    )
    
    -- 더블클릭한 차수의 데이터 담기( AMD테이블일 경우 )
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
        ChgSumPurAmt, 
        ChgSumSalesAmt, 
        ChgGPSumAmt, 
        ChgGPRate 
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
           SUM(PurAmt) AS ChgSumPurAmt, 
           SUM(SalesAmt) AS ChgSumSalesAmt, 
           SUM(SalesAmt) - SUM(PurAmt) AS ChgGPSumAmt,
           (SUM(SalesAmt) - SUM(PurAmt))/SUM(SalesAmt) * 100 AS ChgGPRate 
      FROM DTI_TSLContractMngRev AS A 
      JOIN DTI_TSLContractMngItemRev AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractRev = A.ContractRev ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev
       AND ISNULL(B.IsStop,'0') = '0' 
     GROUP BY A.ContractRev, A.ContractSeq, A.ContractMngNo, A.ContractNo, A.BizUnit, 
              A.ContractDate, A.SDate, A.EDate, A.CustSeq, A.EndUserSeq, 
              A.UMContractKind, A.UMSalesCond, A.ContractEndDate, A.DeptSeq, A.EmpSeq 

    -- 더블클릭한 차수의 데이터 담기( 본테이블일 경우 )
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
        ChgSumPurAmt, 
        ChgSumSalesAmt, 
        ChgGPSumAmt, 
        ChgGPRate 
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
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev 
       AND ISNULL(B.IsStop,'0') = '0' 
     GROUP BY A.ContractRev, A.ContractSeq, A.ContractMngNo, A.ContractNo, A.BizUnit, 
              A.ContractDate, A.SDate, A.EDate, A.CustSeq, A.EndUserSeq, 
              A.UMContractKind, A.UMSalesCond, A.ContractEndDate, A.DeptSeq, A.EmpSeq 
    
    -- 변경된 내역 컨트롤 데이터
    SELECT C.BizUnitName AS ChgBizUnitName, 
           B.ContractDate AS ChgContractDate, 
           B.SDate AS ChgSDate, 
           B.EDate AS ChgEDate, 
           D.CustName AS ChgCustName, 
           D.CustNo AS ChgCustNo, 
           E.CustName AS ChgEndUserName, 
           F.MinorName AS ChgUMContractKindName, 
           G.DeptName AS ChgDeptName, 
           I.EmpName AS ChgEmpName, 
           B.ContractNo AS ChgContractNo, 
           B.ContractMngNo AS ChgContractMngNo, 
           J.MinorName AS ChgUMSalesCondName, 
           B.ContractEndDate AS ChgContractEndDate, 
           B.ContractRev AS ChgContractRev, 
           B.ChgSumPurAmt, 
           B.ChgSumSalesAmt, 
           B.ChgGPSumAmt, 
           B.ChgGPRate 
      INTO #DTI_TSLContractMng_SUB
      FROM #DTI_TSLContractMng      AS B 
      LEFT OUTER JOIN _TDABizUnit   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = B.BizUnit ) 
      LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.EndUserSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMContractKind ) 
      LEFT OUTER JOIN _TDADept      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.UMSalesCond ) 
    
    CREATE TABLE #DTI_TSLContractMngItem
    (
        ContractSeq     INT, 
        ContractSerl    INT, 
        IsStop          NCHAR(1) 
    )
    
    INSERT INTO #DTI_TSLContractMngItem ( ContractSeq, ContractSerl, IsStop ) 
    SELECT A.ContractSeq, A.ContractSerl, IsStop
      FROM DTI_TSLContractMngItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = 0 
    UNION ALL 
    SELECT A.ContractSeq, A.ContractSerl, IsStop 
      FROM DTI_TSLContractMngItemRev AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = 0 

    CREATE TABLE #DTI_TSLContractMngItem_Cng
    (
        ContractSeq     INT, 
        ContractSerl    INT, 
        ItemSeq         INT, 
        IsStock         NCHAR(1), 
        PurYM           NCHAR(6), 
        PurPrice        DECIMAL(19,5), 
        PurAmt          DECIMAL(19,5), 
        SalesYM         NCHAR(6), 
        SalesPrice      DECIMAL(19,5), 
        SalesAmt        DECIMAL(19,5), 
        IsStop          NCHAR(1), 
        Remark          NVARCHAR(1000), 
        GPAmt           DECIMAL(19,5), 
        LotNo           NVARCHAR(100), 
        SalesChk        NCHAR(1), 
        PurChk          NCHAR(1), 
        Qty             DECIMAL(19,5) 
    )
    
    -- 중단, 추가, 변경된 데이터 담기위한 초기 데이터
    INSERT INTO #DTI_TSLContractMngItem_Cng 
    ( 
        ContractSeq, ContractSerl, ItemSeq, IsStock, PurYM, 
        PurPrice, PurAmt, SalesYM, SalesPrice, SalesAmt, 
        IsStop, Remark, GPAmt, LotNo, SalesChk, 
        PurChk, Qty 
    ) 
    SELECT A.ContractSeq, A.ContractSerl, A.ItemSeq, A.IsStock, A.PurYM, 
           A.PurPrice, A.PurAmt, A.SalesYM, A.SalesPrice, A.SalesAmt, 
           A.IsStop, A.Remark, ISNULL(A.SalesAmt,0)-ISNULL(A.PurAmt,0), A.LotNo, CASE WHEN B.OrderSeq IS NULL THEN '0' ELSE '1' END, 
           CASE WHEN C.ApproReqSeq IS NULL THEN '0' ELSE '1' END, A.Qty
      FROM DTI_TSLContractMngItem            AS A 
      LEFT OUTER JOIN _TSLOrderItem          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND CONVERT(INT,Dummy6) = A.ContractSeq AND CONVERT(INT,Dummy7) = A.ContractSerl )
      LEFT OUTER JOIN _TPUORDApprovalReqItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND CONVERT(INT,C.Memo3) = A.ContractSeq AND CONVERT(INT,C.Memo4) = A.ContractSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev 
    UNION ALL 
    SELECT A.ContractSeq, A.ContractSerl, A.ItemSeq, A.IsStock, A.PurYM, 
           A.PurPrice, A.PurAmt, A.SalesYM, A.SalesPrice, A.SalesAmt, 
           A.IsStop, A.Remark, ISNULL(A.SalesAmt,0)-ISNULL(A.PurAmt,0), A.LotNo, CASE WHEN B.OrderSeq IS NULL THEN '0' ELSE '1' END, 
           CASE WHEN C.ApproReqSeq IS NULL THEN '0' ELSE '1' END, A.Qty
      FROM DTI_TSLContractMngItemRev         AS A 
      LEFT OUTER JOIN _TSLOrderItem          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND CONVERT(INT,Dummy6) = A.ContractSeq AND CONVERT(INT,Dummy7) = A.ContractSerl )
      LEFT OUTER JOIN _TPUORDApprovalReqItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND CONVERT(INT,C.Memo3) = A.ContractSeq AND CONVERT(INT,C.Memo4) = A.ContractSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
       AND A.ContractRev = @ContractRev
    
    CREATE TABLE #Result 
    (
        ContractSeq  INT, 
        ContractSerl INT, 
        ContractRev  INT, 
        ItemSeq      INT, 
        IsStock      NCHAR(1), 
        PurYM        NCHAR(6), 
        PurPrice     DECIMAL(19,5), 
        PurAmt       DECIMAL(19,5), 
        SalesYM      NCHAR(6), 
        SalesPrice   DECIMAL(19,5), 
        SalesAmt     DECIMAL(19,5), 
        IsStop       NCHAR(1), 
        Remark       NVARCHAR(1000), 
        GPAmt        DECIMAL(19,5), 
        LotNo        NVARCHAR(100), 
        SalesChk     NCHAR(1), 
        PurChk       NCHAR(1), 
        Qty          DECIMAL(19,5), 
        ItemName     NVARCHAR(100), 
        ItemNo       NVARCHAR(100), 
        Spec         NVARCHAR(100), 
        GPPrice      DECIMAL(19,5), 
        GPRate       DECIMAL(19,5), 
        KindName     NVARCHAR(100), 
        Kind         INT
    )
    
    -- 중단, 추가, 변경된 데이터 담기
    INSERT INTO #Result ( ContractSeq, ContractSerl, ContractRev, ItemSeq, IsStock, 
                          PurYM, PurPrice ,PurAmt, SalesYM, SalesPrice, 
                          SalesAmt, IsStop, Remark, GPAmt, LotNo, 
                          SalesChk ,PurChk, Qty, ItemName, ItemNo, 
                          Spec, GPPrice, GPRate, KindName, Kind 
                        )
    SELECT A.ContractSeq  ,
           A.ContractSerl ,
           @ContractRev AS ContractRev, 
           A.ItemSeq      ,
           A.IsStock      ,
           A.PurYM        ,
           A.PurPrice     ,
           A.PurAmt       ,
           A.SalesYM      ,
           A.SalesPrice   ,
           A.SalesAmt     ,
           A.IsStop       ,
           A.Remark       ,
           A.GPAmt        ,
           A.LotNo        ,
           A.SalesChk     ,
           A.PurChk       , 
           A.Qty          ,
           C.ItemName     , 
           C.ItemNo       , 
           C.Spec         , 
           ISNULL(A.SalesAmt,0) - ISNULL(A.PurAmt,0) AS GPPrice, 
           CASE WHEN ISNULL(A.SalesAmt,0) = 0 THEN 0 ELSE (ISNULL(A.SalesAmt,0) - ISNULL(A.PurAmt,0)) / ISNULL(A.SalesAmt,0) * 100 END AS GPRate, 
           CASE WHEN A.IsStop = '1' THEN '중단' ELSE '추가' END AS KindName, 
           CASE WHEN A.IsStop = '1' THEN 3 ELSE 1 END AS Kind
      FROM #DTI_TSLContractMngItem_Cng  AS A 
      LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE (A.IsStop = '1' OR A.ContractSerl NOT IN ( SELECT ContractSerl FROM #DTI_TSLContractMngItem ))
    UNION 
    SELECT B.ContractSeq  ,
           B.ContractSerl ,
           @ContractRev AS ContractRev, 
           B.ItemSeq      ,
           B.IsStock      ,
           B.PurYM        ,
           B.PurPrice     ,
           B.PurAmt       ,
           B.SalesYM      ,
           B.SalesPrice   ,
           B.SalesAmt     ,
           B.IsStop       ,
           B.Remark       ,
           B.GPAmt        ,
           B.LotNo        ,
           B.SalesChk     ,
           B.PurChk       , 
           B.Qty          ,
           C.ItemName     , 
           C.ItemNo       , 
           C.Spec         , 
           ISNULL(B.SalesAmt,0) - ISNULL(B.PurAmt,0) AS GPPrice, 
           CASE WHEN ISNULL(B.SalesAmt,0) = 0 THEN 0 ELSE (ISNULL(B.SalesAmt,0) - ISNULL(B.PurAmt,0)) / ISNULL(B.SalesAmt,0) * 100 END AS GPRate, 
           '변경' AS KindName, 
           2 AS Kind
      FROM DTI_TSLContractMngItemRev   AS A 
      JOIN #DTI_TSLContractMngItem_Cng AS B              ON ( B.ContractSeq = A.ContractSeq and B.ContractSerl = A.Contractserl ) 
      LEFT OUTER JOIN _TDAItem         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq AND A.ContractSeq = @ContractSeq AND A.ContractRev = 0 
       AND (A.Qty <> B.Qty OR A.PurYM <> B.PurYM OR A.SalesYM <> B.SalesYM OR A.PurAmt <> B.PurAmt OR A.SalesAmt <> B.SalesAmt)  
     ORDER BY A.ContractSerl 
    
    -- 최종 조회
    SELECT * 
      FROM #DTI_TSLContractMng_SUB AS A 
      LEFT OUTER JOIN #Result AS B ON ( 1 = 1 ) 
    
    RETURN
GO
exec DTI_SSLContractChgListSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ContractRev>0</ContractRev>
    <ContractSeq>1000133</ContractSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020773,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017476