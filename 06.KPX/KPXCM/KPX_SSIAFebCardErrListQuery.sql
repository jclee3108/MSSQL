  
IF OBJECT_ID('KPX_SSIAFebCardErrListQuery') IS NOT NULL   
    DROP PROC KPX_SSIAFebCardErrListQuery  
GO  
  
-- v2015.08.10  
  
-- 법인카드에러내역확인 및 재처리-조회 by 이재천   
CREATE PROC KPX_SSIAFebCardErrListQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @CardSeq        INT, 
            @FrAUTH_DD      NCHAR(8), 
            @ToAUTH_DD      NCHAR(8), 
            @BUY_CLT_NO     NVARCHAR(200), 
            @AUTH_NO        NVARCHAR(200), 
            @FrLAST_USE_DD  NCHAR(8), 
            @ToLAST_USE_DD  NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CardSeq         = ISNULL( CardSeq      , 0 ),  
           @FrAUTH_DD       = ISNULL( FrAUTH_DD    , '' ),  
           @ToAUTH_DD       = ISNULL( ToAUTH_DD    , '' ),  
           @BUY_CLT_NO      = ISNULL( BUY_CLT_NO   , '' ),  
           @AUTH_NO         = ISNULL( AUTH_NO      , '' ),  
           @FrLAST_USE_DD   = ISNULL( FrLAST_USE_DD, '' ),  
           @ToLAST_USE_DD   = ISNULL( ToLAST_USE_DD, '' )
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            CardSeq        INT, 
            FrAUTH_DD      NCHAR(8), 
            ToAUTH_DD      NCHAR(8), 
            BUY_CLT_NO     NVARCHAR(200), 
            AUTH_NO        NVARCHAR(200), 
            FrLAST_USE_DD  NCHAR(8), 
            ToLAST_USE_DD  NCHAR(8)
           )    
    
    IF @ToAUTH_DD = '' SELECT @ToAUTH_DD = '99991231'
    IF @ToLAST_USE_DD = '' SELECT @ToLAST_USE_DD = '99991231'
    
    -- 최종조회   
    SELECT A.IsReProcess, 
           C.MinorName AS CardKindName, 
           ISNULL(B.CardNo,A.CARD_NO) AS CardNo, 
           B.CardSeq, 
           E.CompanyShortName AS ERPCompanyName, 
           G.GrpNm1 AS GWCompanyName, 
           A.AUTH_NO, 
           A.AUTH_DD, 
           STUFF(STUFF(A.AUTH_HH,3,0,':'),6,0,':') AS AUTH_HH, 
           A.BUY_DD, 
           A.BUY_CLT_NO, 
           A.MER_NM, 
           STUFF(STUFF(A.MER_BIZNO,4,0,'-'),7,0,'-') AS MER_BIZNO, 
           A.SUPP_PRICE, 
           A.SURTAX, 
           A.AUTH_AMT, 
           D.DeptName, 
           A.MER_CEONM, 
           A.Error, 
           STUFF(STUFF(LEFT(A.LST_USE_DDHH,8),5,0,'-'),8,0,'-') + ' ' + STUFF(STUFF(RIGHT(A.LST_USE_DDHH,6),3,0,':'),6,0,':') AS LST_USE_DDHH,
           A.STM_KEY, 
           A.SEQ_NO, 
           A.BUY_STS
      FROM HIST_CORPCD_ERR          AS A 
      LEFT OUTER JOIN _TDACard      AS B ON ( REPLACE(B.CardNo,'-','') = A.CARD_NO ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMCardKind ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS D ON ( D.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TCACompany   AS E ON ( E.CompanySeq = B.CompanySeq ) 
      LEFT OUTER JOIN [KPXGW].SmartBillDB.dbo.[HIST_CORPCD_LIMT] AS F ON ( F.CARD_NO = A.CARD_NO AND F.x_active = '1' ) 
      LEFT OUTER JOIN [KPXGW].CrewworksV80_kpx.dbo.[CMONGroup]   AS G ON ( G.GrpCd = F.GrpCd ) 
     WHERE ( @CardSeq = 0 OR B.CardSeq = @CardSeq ) 
       AND ( A.AUTH_DD BETWEEN @FrAUTH_DD AND @ToAUTH_DD ) 
       AND ( LEFT(A.LST_USE_DDHH,8) BETWEEN @FrLAST_USE_DD AND @ToLAST_USE_DD ) 
       AND ( @BUY_CLT_NO = '' OR A.BUY_CLT_NO LIKE '%' + @BUY_CLT_NO + '%' ) 
       AND ( @AUTH_NO = '' OR A.AUTH_NO LIKE '%' + @AUTH_NO + '%' ) 
     ORDER BY A.CARD_NO, AUTH_DD, AUTH_NO 
    
    RETURN  
GO 
begin tran 
exec KPX_SSIAFebCardErrListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CardSeq />
    <FrAUTH_DD>20150701</FrAUTH_DD>
    <ToAUTH_DD>20150907</ToAUTH_DD>
    <BUY_CLT_NO />
    <AUTH_NO />
    <FrLAST_USE_DD>20150701</FrLAST_USE_DD>
    <ToLAST_USE_DD>20150907</ToLAST_USE_DD>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031355,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026098
rollback 
    