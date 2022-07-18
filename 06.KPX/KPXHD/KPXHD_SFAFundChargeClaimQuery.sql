  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimQuery') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimQuery  
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-조회 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimQuery  
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
            @StdYM      NCHAR(6),
            @UMHelpCom  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' ),  
           @UMHelpCom  = ISNULL( UMHelpCom, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYM       NCHAR(6),   
            UMHelpCom   INT
           )    
      
    -- 최종조회   
    SELECT TOP 1 
           A.TotExcessProfitAmt, 
           A.TotAdviceAmt, 
           --A.LastYMClaimAmt, 
           CASE WHEN ISNULL(B.StdYMClaimAmt,0) < 0 THEN ISNULL(B.StdYMClaimAmt,0) * (-1) ELSE 0 END AS LastYMClaimAmt , 
           A.TotAdviceAmt - CASE WHEN ISNULL(B.StdYMClaimAmt,0) < 0 THEN ISNULL(B.StdYMClaimAmt,0) * (-1) ELSE 0 END AS StdYMClaimAmt, 
           --A.StdYMClaimAmt,
           A.FundChargeSeq 
      FROM KPXHD_TFAFundChargeClaim AS A 
      LEFT OUTER JOIN KPXHD_TFAFundChargeClaim AS B ON ( B.CompanySeq = @CompanySeq AND B.StdYM = CONVERT(NCHAR(6),DATEADD(MONTH,-1,@StdYM + '01'),112) AND B.UMHelpCom = A.UMHelpCom ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
       AND A.UMHelpCom = @UMHelpCom 
    
    
    
    RETURN  
    go
exec KPXHD_SFAFundChargeClaimQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201602</StdYM>
    <UMHelpCom>1010494001</UMHelpCom>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=4,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028674