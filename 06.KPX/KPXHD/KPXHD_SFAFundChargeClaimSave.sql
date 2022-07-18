  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimSave') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimSave  
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-저장 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimSave  
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
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXHD_TFAFundChargeClaim'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXHD_TFAFundChargeClaim')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXHD_TFAFundChargeClaim'    , -- 테이블명        
                  '#KPXHD_TFAFundChargeClaim'    , -- 임시 테이블명        
                  'FundChargeSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaim WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXHD_TFAFundChargeClaim AS A   
          JOIN KPXHD_TFAFundChargeClaim AS B ON ( B.CompanySeq = @CompanySeq AND A.FundChargeSeq = B.FundChargeSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaim WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.TotExcessProfitAmt  = A.TotExcessProfitAmt,  
               B.TotAdviceAmt       = A.TotAdviceAmt,  
               B.LastYMClaimAmt     = A.LastYMClaimAmt,  
               B.StdYMClaimAmt      = A.StdYMClaimAmt,  
               B.LastUserSeq        = @UserSeq, 
               B.LastDateTime       = GETDATE(), 
               B.PgmSeq             = @PgmSeq
          FROM #KPXHD_TFAFundChargeClaim AS A   
          JOIN KPXHD_TFAFundChargeClaim AS B ON ( B.CompanySeq = @CompanySeq AND A.FundChargeSeq = B.FundChargeSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaim WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXHD_TFAFundChargeClaim  
        (   
            CompanySeq, FundChargeSeq, StdYM, UMHelpCom, TotExcessProfitAmt, 
            TotAdviceAmt, LastYMClaimAmt, StdYMClaimAmt, LastUserSeq, LastDateTime, 
            PgmSeq
        )   
        SELECT @CompanySeq, A.FundChargeSeq, A.StdYM, A.UMHelpCom, A.TotExcessProfitAmt, 
               A.TotAdviceAmt, A.LastYMClaimAmt, A.StdYMClaimAmt, @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #KPXHD_TFAFundChargeClaim AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXHD_TFAFundChargeClaim   
      
    RETURN  