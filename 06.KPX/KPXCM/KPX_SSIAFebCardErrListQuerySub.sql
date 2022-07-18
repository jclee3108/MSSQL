  
IF OBJECT_ID('KPX_SSIAFebCardErrListQuerySub') IS NOT NULL   
    DROP PROC KPX_SSIAFebCardErrListQuerySub  
GO  
  
-- v2015.08.10  
  
-- 법인카드에러내역확인 및 재처리-Item조회 by 이재천   
CREATE PROC KPX_SSIAFebCardErrListQuerySub  
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
            @BUY_STS    NVARCHAR(100), 
            @AUTH_NO    NVARCHAR(100), 
            @CardSeq    INT, 
            @AUTH_AMT   DECIMAL(19,5), 
            @AUTH_DD    NCHAR(8), 
            @SEQ_NO     INT 

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BUY_STS     = ISNULL( BUY_STS , '' ),  
           @AUTH_NO     = ISNULL( AUTH_NO , '' ),  
           @CardSeq     = ISNULL( CardSeq , 0 ),  
           @AUTH_AMT    = ISNULL( AUTH_AMT, 0 ),  
           @AUTH_DD     = ISNULL( AUTH_DD , '' ),  
           @SEQ_NO      = ISNULL( SEQ_NO  , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BUY_STS    NVARCHAR(100), 
            AUTH_NO    NVARCHAR(100), 
            CardSeq    INT, 
            AUTH_AMT   DECIMAL(19,5), 
            AUTH_DD    NCHAR(8), 
            SEQ_NO     INT 
           )    
    
    -- 최종조회   
    SELECT CASE WHEN EXISTS (SELECT 1 FROM HIST_CORPCD_VERIFICATION WHERE A.SEQ_NO = SEQ_NO) 
                THEN '처리'
                ELSE '미처리'
                END AS StatusName, 
           C.MinorName AS CardKindName, 
           B.CardNo, 
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
           STUFF(STUFF(LEFT(A.LST_USE_DDHH,8),5,0,'-'),8,0,'-') + ' ' + STUFF(STUFF(RIGHT(A.LST_USE_DDHH,6),3,0,':'),6,0,':') AS LST_USE_DDHH, 
           A.STM_KEY, 
           A.SEQ_NO
      FROM HIST_CORPCD_BUY AS A 
      LEFT OUTER JOIN _TDACard      AS B ON ( REPLACE(B.CardNo,'-','') = A.CARD_NO ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMCardKind ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS D ON ( D.EmpSeq = B.EmpSeq ) 
     WHERE A.BUY_STS = @BUY_STS 
       AND A.AUTH_NO = @AUTH_NO 
       AND (@CardSeq = 0 OR B.CardSeq = @CardSeq) -- 카드번호가 없는 경우도 있기 때문에 추가.. 0 코드 추가 
       AND A.AUTH_AMT = @AUTH_AMT 
       AND A.AUTH_DD = @AUTH_DD 
       AND A.SEQ_NO <> @SEQ_NO 
    
    RETURN  
GO
exec KPX_SSIAFebCardErrListQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>29</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <CardSeq>0</CardSeq>
    <AUTH_NO>08912258</AUTH_NO>
    <AUTH_DD>20150716</AUTH_DD>
    <AUTH_AMT>18500</AUTH_AMT>
    <SEQ_NO>36220</SEQ_NO>
    <BUY_STS>03</BUY_STS>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031355,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026098