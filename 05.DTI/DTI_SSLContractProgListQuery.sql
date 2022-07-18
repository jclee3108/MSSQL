
IF OBJECT_ID('DTI_SSLContractProgListQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractProgListQuery
GO 

-- v2014.03.28 

-- 계약별진행현황_DTI(조회) by이재천
CREATE PROC DTI_SSLContractProgListQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle          INT, 
            @CustSeq            INT, 
            @ContractDateFr     NCHAR(8), 
            @EmpSeq             INT, 
            @DeptSeq            INT, 
            @ContractName       NVARCHAR(100), 
            @ContractNo         NVARCHAR(100), 
            @IsComplete         NCHAR(1), 
            @ContractMngNo      NVARCHAR(100), 
            @EndUserSeq         INT, 
            @ContractDateTo     NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CustSeq          = ISNULL(CustSeq           ,0  ), 
           @ContractDateFr   = ISNULL(ContractDateFr    ,'' ), 
           @EmpSeq           = ISNULL(EmpSeq            ,0  ), 
           @DeptSeq          = ISNULL(DeptSeq           ,0  ), 
           @ContractName     = ISNULL(ContractName      ,'' ), 
           @ContractNo       = ISNULL(ContractNo        ,'' ), 
           @IsComplete       = ISNULL(IsComplete        ,'0'), 
           @ContractMngNo    = ISNULL(ContractMngNo     ,'' ), 
           @EndUserSeq       = ISNULL(EndUserSeq        ,0  ), 
           @ContractDateTo   = ISNULL(ContractDateTo    ,'' ) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags) 
    
      WITH (
            CustSeq            INT, 
            ContractDateFr     NCHAR(8), 
            EmpSeq             INT, 
            DeptSeq            INT, 
            ContractName       NVARCHAR(100),
            ContractNo         NVARCHAR(100),
            IsComplete         NCHAR(1), 
            ContractMngNo      NVARCHAR(100),
            EndUserSeq         INT, 
            ContractDateTo     NCHAR(8) 
           )
    
    IF @ContractDateTo = '' SELECT @ContractDateTo = '99991231' 
    
    -- Mapping정보에서 Super권한인 아니면 로그인부서만 조회할수 있도록 설정 
    IF (SELECT DeptSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) NOT IN (SELECT DeptSeq FROM DTI_TCOMEnvContractEmp WHERE CompanySeq = @CompanySeq) OR
       (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) NOT IN (SELECT EmpSeq FROM DTI_TCOMEnvContractEmp WHERE CompanySeq = @CompanySeq) 
    BEGIN 
        SELECT @DeptSeq = (SELECT DeptSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) 
    END 
    
    -- 기준 데이터 담기 
    CREATE TABLE #TSLOrderItem 
    (
        IDX_NO          INT IDENTITY(1,1), 
        ContractSeq     INT, 
        ContractSerl    INT, 
        OrderSeq        INT, 
        OrderSerl       INT, 
        DelvSeq         INT, 
        DelvSerl        INT, 
        IsComplete      NCHAR(1), 
    )
    INSERT INTO #TSLOrderItem 
    (
        ContractSeq ,ContractSerl  ,OrderSeq  ,OrderSerl ,DelvSeq, 
        DelvSerl    ,IsComplete 
    )
    
    SELECT A.ContractSeq, B.ContractSerl, C.OrderSeq, C.OrderSerl, D.DelvSeq, 
           DelvSerl, A.IsComplete 
      FROM DTI_TSLContractMng AS A 
      LEFT OUTER JOIN DTI_TSLContractMngItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN _TSLOrderItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND CONVERT(INT,C.Dummy6) = B.ContractSeq AND CONVERT(INT,C.Dummy7) = B.ContractSerl ) 
      LEFT OUTER JOIN _TPUDelvItem           AS D WITh(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND CONVERT(INT,D.Memo3) = B.ContractSeq AND CONVERT(INT,D.Memo4) = B.ContractSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@ContractName = '' OR A.ContractName LIKE @ContractName + '%') 
       AND (@ContractNo = '' OR A.ContractNo LIKE @ContractNo + '%') 
       AND (@ContractMngNo = '' OR A.ContractMngNo LIKE @ContractMngNo + '%') 
       AND (A.ContractDate BETWEEN @ContractDateFr AND @ContractDateTo) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
       AND (@EndUserSeq = 0 OR A.EndUserSeq = @EndUserSeq) 
       AND ISNULL(B.IsStop,'0') = '0' 
    
    -- 완료포함이 체크되지 않으면 완료된건 지우기 
    IF @IsComplete = '0'
    BEGIN
        DELETE FROM #TSLOrderItem WHERE IsComplete = '1' 
    END 
    
    CREATE TABLE #TMP_ProgressTable (IDOrder INT, TableName NVARCHAR(100)) 
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TSLSalesItem'   -- 데이터 찾을 테이블
    
    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TSLOrderItem',    -- 기준이 되는 테이블
            @TempTableName = '#TSLOrderItem',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'OrderSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'OrderSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
    CREATE TABLE #TMP_Result_Sub 
    (
        ContractSeq         INT, 
        SalesRate           DECIMAL(19,5), 
        SalesCntItem        INT, 
        SalesCntYM          INT, 
        SumSalesAmt         DECIMAL(19,5), 
        SumPurAmt           DECIMAL(19,5), 
        SumGPAmt            DECIMAL(19,5), 
        SumGPRate           DECIMAL(19,5), 
        CptSalesCntItem     INT,
        CptSalesCntYM       INT,
        CptSalesAmt         DECIMAL(19,5), 
        CptPurAmt           DECIMAL(19,5), 
        CptGPAmt            DECIMAL(19,5), 
        CptGPRate           DECIMAL(19,5) 
    )
    --계약현황
    INSERT INTO #TMP_Result_Sub 
    (
        ContractSeq         ,SalesRate           ,SalesCntItem        ,SalesCntYM          ,SumSalesAmt         ,
        SumPurAmt           ,SumGPAmt            ,SumGPRate           ,CptSalesCntItem     ,CptSalesCntYM       ,
        CptSalesAmt         ,CptPurAmt           ,CptGPAmt            ,CptGPRate           
    ) 
    SELECT A.ContractSeq, 0, COUNT(DISTINCT B.ItemSeq), COUNT(DISTINCT B.SalesYM), SUM(B.SalesAmt), 
           SUM(B.PurAmt), SUM(B.SalesAmt) - SUM(B.PurAmt), (SUM(B.SalesAmt) - SUM(B.PurAmt))/SUM(B.SalesAmt) * 100, 0, 0, 
           0, 0, 0, 0
      FROM #TSLOrderItem                     AS A 
      LEFT OUTER JOIN DTI_TSLContractMngItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
     GROUP BY A.ContractSeq 
    
    -- 매출 완료 현황
    INSERT INTO #TMP_Result_Sub
    (
        ContractSeq         ,SalesRate           ,SalesCntItem        ,SalesCntYM          ,SumSalesAmt         ,
        SumPurAmt           ,SumGPAmt            ,SumGPRate           ,CptSalesCntItem     ,CptSalesCntYM       ,
        CptSalesAmt         ,CptPurAmt           ,CptGPAmt            ,CptGPRate           
    ) 
    SELECT A.ContractSeq, 0, 0, 0, 0, 
           0, 0, 0, COUNT(DISTINCT A.ItemSeq), COUNT(DISTINCT A.SalesYM), 
           SUM(A.SalesAmt), SUM(A.PurAmt), SUM(A.SalesAmt) - SUM(A.PurAmt), (SUM(A.SalesAmt) - SUM(A.PurAmt))/SUM(A.SalesAmt) * 100 
      FROM DTI_TSLContractMngItem AS A 
      JOIN ( SELECT A.ContractSeq, A.ContractSerl 
               FROM #TSLOrderItem                     AS A 
               LEFT OUTER JOIN #TCOMProgressTracking  AS B              ON ( B.IDX_NO = A.IDX_NO ) 
               LEFT OUTER JOIN _TSLSalesItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.Seq AND C.SalesSerl = B.Serl ) 
              WHERE ISNULL(B.Serl,0) <> 0 
              GROUP BY A.ContractSeq, A.ContractSerl 
             HAVING SUM(C.DomAmt) <> 0  
           ) AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
     GROUP BY A.ContractSeq 
    
    SELECT A.ContractSeq, 
           MAX(SalesRate) AS SalesRate, 
           MAX(SalesCntItem) AS SalesCntItem, 
           MAX(SalesCntYM) AS SalesCntYM, 
           MAX(SumSalesAmt) AS SumSalesAmt, 
           MAX(SumPurAmt) AS SumPurAmt, 
           MAX(SumGPAmt) AS SumGPAmt, 
           MAX(SumGPRate) AS SumGPRate, 
           MAX(CptSalesCntItem) AS CptSalesCntItem, 
           MAX(CptSalesCntYM) AS CptSalesCntYM, 
           MAX(CptSalesAmt) AS CptSalesAmt, 
           MAX(CptPurAmt) AS CptPurAmt, 
           MAX(CptGPAmt) AS CptGPAmt, 
           MAX(CptGPRate) AS CptGPRate 
      INTO #TMP_Result
      FROM #TMP_Result_Sub AS A 
     GROUP BY A.ContractSeq 
    
    SELECT A.ContractSeq, 
           B.IsComplete, -- 완료여부 
           B.ContractName, -- 계약명 
           B.ContractNo, -- 계약번호 
           B.ContractMngNo, -- 계약관리번호 
           B.ContractDate, -- 계약일 
           C.DeptName, -- 부서명 
           B.DeptSeq, -- 부서코드 
           D.EmpName, -- 담당자 
           B.EmpSeq, -- 담당자코드 
           E.CustName, -- 매출처 
           B.CustSeq, -- 매출처코드 
           F.CustName AS EndUser, -- EndUser
           B.EndUserSeq, -- EndUser코드 
           G.MinorName AS UMSalesCondName, -- 매출유형 
           B.UMSalesCond, -- 매출유형코드 
           B.SDate, -- 계약기간(시작일) 
           B.EDate, -- 계약기간(종료일) 
           CASE WHEN ISNULL(A.SalesCntItem,0) = 0 THEN 0 ELSE (CONVERT(DECIMAL(19,5),A.CptSalesCntItem) / CONVERT(DECIMAL(19,5),A.SalesCntItem)) * 100 END AS SalesRate, -- 매출진행율 
           --계약현황
           A.SalesCntItem, --총매출횟수(품목별)
           A.SalesCntYM, --총매출횟수(유형별)
           A.SumSalesAmt, -- 매출총금액
           A.SumPurAmt, -- 매입총금액
           A.SumGPAmt,  -- GP금액
           A.SumGPRate, -- GP율 
           -- 매출완료현황 
           A.CptSalesCntItem, -- 총매출횟수(품목별)
           A.CptSalesCntYM, -- 총매출횟수(유형별)
           A.CptSalesAmt, -- 매출액
           A.CptPurAmt, -- 매입원가
           A.CptGPAmt, -- GP금액
           A.CptGPRate, -- GP율 
           -- 잔여매출현황 
           (A.SalesCntItem - A.CptSalesCntItem) AS RestSalesCntItem, -- 잔여매출횟수(품목별) 
           A.SalesCntYM - A.CptSalesCntYM AS RestSalesCntYM, -- 잔여매출횟수(유형별)
           A.SumSalesAmt - A.CptSalesAmt AS RestSalesAmt, -- 잔여매출금액
           A.SumPurAmt -  A.CptPurAmt AS RestPurAmt, -- 잔여매입원가 
           A.SumGPAmt - A.CptGPAmt AS RestGPAmt, -- GP금액
           CASE WHEN (ISNULL(A.SumSalesAmt,0) - ISNULL(A.CptSalesAmt,0)) = 0   
                THEN 0   
                ELSE ((A.SumSalesAmt - A.CptSalesAmt) - (A.SumPurAmt -  A.CptPurAmt)) / (ISNULL(A.SumSalesAmt,0) - ISNULL(A.CptSalesAmt,0)) * 100   
                END AS RestGPRate, -- GP율  
           B.ContractRev --AMD변경횟수 
           
      FROM #TMP_Result AS A 
      LEFT OUTER JOIN DTI_TSLContractMng AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN _TDADept           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDACust           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDACust           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySEq AND F.CustSeq = B.EndUserSeq ) 
      LEFT OUTER JOIN _TDAUMinor         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMSalesCond ) 
    
    RETURN
GO
exec DTI_SSLContractProgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ContractName />
    <ContractNo>201403270001</ContractNo>
    <ContractMngNo />
    <ContractDateFr />
    <ContractDateTo />
    <DeptSeq />
    <EmpSeq />
    <CustSeq />
    <EndUserSeq />
    <IsComplete>0</IsComplete>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021908,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018402