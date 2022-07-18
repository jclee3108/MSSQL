  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimItemQuery') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimItemQuery 
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-품목조회 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimItemQuery
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
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            StdYM       NCHAR(6),   
            UMHelpCom   INT
           )    
      
    -- 최종조회   
    SELECT B.* 
      FROM KPXHD_TFAFundChargeClaim         AS A 
      JOIN KPXHD_TFAFundChargeClaimItem     AS B ON ( B.CompanySeq = @CompanySeq AND B.FundChargeSeq = A.FundChargeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYM = @StdYM 
       AND UMHelpCom = @UMHelpCom 
    
    RETURN  
    go
exec KPXHD_SFAFundChargeClaimItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201602</StdYM>
    <UMHelpCom>1010494001</UMHelpCom>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028674