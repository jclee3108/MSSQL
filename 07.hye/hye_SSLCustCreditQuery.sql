   
IF OBJECT_ID('hye_SSLCustCreditQuery') IS NOT NULL     
    DROP PROC hye_SSLCustCreditQuery    
GO    
    
-- v2016.08.29  
    
-- 거래처별여신한도등록_hye-조회 by 이재천 
CREATE PROC hye_SSLCustCreditQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,    
            -- 조회조건     
            @UpDeptSeq      INT, 
            @StdDate        NCHAR(8), 
            @SrtDate        NCHAR(8), 
            @EndDate        NCHAR(8), 
            @IsLimit        NCHAR(1), 
            @CustName       NVARCHAR(100), 
            @CustNo         NVARCHAR(100), 
            @BizNo          NVARCHAR(100), 
            @SMCustStatus   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @UpDeptSeq     = ISNULL( UpDeptSeq     , 0 ), 
           @StdDate       = ISNULL( StdDate       , '' ), 
           @SrtDate       = ISNULL( SrtDate       , '' ), 
           @EndDate       = ISNULL( EndDate       , '' ), 
           @IsLimit       = ISNULL( IsLimit       , '0' ), 
           @CustName      = ISNULL( CustName      , '' ), 
           @CustNo        = ISNULL( CustNo        , '' ), 
           @BizNo         = ISNULL( BizNo         , '' ), 
           @SMCustStatus  = ISNULL( SMCustStatus  , 0 )
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (
            UpDeptSeq      INT, 
            StdDate        NCHAR(8),       
            SrtDate        NCHAR(8),       
            EndDate        NCHAR(8),       
            IsLimit        NCHAR(1),       
            CustName       NVARCHAR(100),       
            CustNo         NVARCHAR(100),       
            BizNo          NVARCHAR(100),       
            SMCustStatus   INT      
           )      
    
    -- 거래처별 기준일 한도금액 보여주기 
    SELECT A.CustSeq, 
           MAX(A.LimitSerl) AS LimitSerl
      INTO #hye_TDACustLimitInfo 
      FROM hye_TDACustLimitInfo AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND @StdDate BETWEEN A.SrtDate AND A.EndDate 
     GROUP BY A.CustSeq 

    SELECT A.CustSeq, A.LimitAmt 
      INTO #CustLimitAmt 
      FROM hye_TDACustLimitInfo    AS A 
      JOIN #hye_TDACustLimitInfo   AS B ON ( B.CustSeq = A.CustSeq AND B.LimitSerl = A.LimitSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
    -- 거래처별 기준일 한도금액 보여주기 
    
    -- 한도일에 해당하는 것만 조회 되도록 
    SELECT DISTINCT A.CustSeq 
      INTO #CustSeq 
      FROM hye_TDACustLimitInfo AS A 
     WHERE CompanySeq = @CompanySeq 
       AND ( SrtDate BETWEEN @SrtDate AND @EndDate OR EndDate BETWEEN @SrtDate AND @EndDate ) 
    

    
    -- 최종조회     
    SELECT D.DeptName AS UpDeptName, 
           B.UpDeptSeq AS UpDeptSeq, 
           A.CustName AS CustName, 
           A.CustNo AS CustNo, 
           A.CustSeq AS CustSeq, 
           ISNULL(C.LimitAmt,0) AS LimitAmt, 
           0 AS PromiseAmt 
      INTO #Result 
      FROM _TDACust                         AS A 
      LEFT OUTER JOIN hye_TDACustMainInfo   AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN #CustLimitAmt         AS C ON ( C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept              AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.UpDeptSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( @UpDeptSeq = 0 OR B.UpDeptSeq = @UpDeptSeq ) 
       AND ( @CustName = '' OR A.CustName LIKE @CustName + '%' ) 
       AND ( @CustNo = '' OR A.CustNo LIKE @CustNo + '%' ) 
       AND ( @BizNo = '' OR REPLACE(A.BizNo, '-', '') LIKE REPLACE(@BizNo,'-','') + '%' ) 
       AND ( @SMCustStatus = 0 OR A.SMCustStatus = @SMCustStatus ) 
    
    
    IF @IsLimit = '1' 
    BEGIN
        DELETE A
          FROM #Result AS A 
         WHERE NOT EXISTS (SELECT 1 FROM #CustSeq WHERE CustSeq = A.CustSeq)
    END 

    SELECT * FROM #Result 

    RETURN   
GO
exec hye_SSLCustCreditQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UpDeptSeq />
    <StdDate>20160829</StdDate>
    <SrtDate>20160801</SrtDate>
    <EndDate>20160829</EndDate>
    <IsLimit>1</IsLimit>
    <CustName />
    <CustNo />
    <BizNo />
    <SMCustStatusName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730094,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730020