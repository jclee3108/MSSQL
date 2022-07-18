  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimTotCal') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimTotCal  
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-Tot계산 by 이재천 
CREATE PROC KPXHD_SFAFundChargeClaimTotCal  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    CREATE TABLE #KPXHD_TFAFundChargeClaim (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXHD_TFAFundChargeClaim'   
    IF @@ERROR <> 0 RETURN    

--select * from #KPXHD_TFAFundChargeClaim 
--return 

    -- 최종조회   
    SELECT SUM(A.AdviceAmt) AS TotAdviceAmt, 
           SUM(A.ExcessProfitAmt) AS TotExcessProfitAmt, 
           CASE WHEN MAX(B.StdYMClaimAmt) < 0 THEN MAX(B.StdYMClaimAmt) * (-1) ELSE 0 END AS LastYMClaimAmt, 
           SUM(A.AdviceAmt) - CASE WHEN MAX(B.StdYMClaimAmt) < 0 THEN MAX(B.StdYMClaimAmt) * (-1) ELSE 0 END AS StdYMClaimAmt 
      FROM #KPXHD_TFAFundChargeClaim            AS A 
      LEFT OUTER JOIN KPXHD_TFAFundChargeClaim  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMHelpCom = A.UMHelpCom AND B.StdYM = CONVERT(NCHAR(6),DATEADD(MONTH, -1 ,A.StdYM + '01'),112) ) 
     --WHERE A.CompanySeq = @CompanySeq  
    
    RETURN  
    GO
exec KPXHD_SFAFundChargeClaimTotCal @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ExcessProfitAmt>3000213</ExcessProfitAmt>
    <AdviceAmt>0</AdviceAmt>
    <FundChargeSeq>0</FundChargeSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <UMHelpCom>1010494001</UMHelpCom>
    <StdYM>201602</StdYM>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028674