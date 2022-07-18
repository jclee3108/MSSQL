  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimItemSave') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimItemSave  
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-품목저장 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXHD_TFAFundChargeClaimItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXHD_TFAFundChargeClaimItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXHD_TFAFundChargeClaimItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXHD_TFAFundChargeClaimItem'    , -- 테이블명        
                  '#KPXHD_TFAFundChargeClaimItem'    , -- 임시 테이블명        
                  'FundChargeSeq,FundChargeSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaimItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXHD_TFAFundChargeClaimItem AS A   
          JOIN KPXHD_TFAFundChargeClaimItem AS B ON ( B.CompanySeq = @CompanySeq AND A.FundChargeSeq = B.FundChargeSeq AND A.FundChargeSerl = B.FundChargeSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        IF NOT EXISTS (SELECT 1 
                         FROM KPXHD_TFAFundChargeClaimItem AS A 
                        WHERE A.CompanySeq = @CompanySeq 
                          AND A.FundChargeSeq IN ( SELECT TOP 1 FundChargeSeq FROM #KPXHD_TFAFundChargeClaimItem ) 
                      )
        BEGIN
        

            DELETE B   
              FROM #KPXHD_TFAFundChargeClaimItem AS A   
              JOIN KPXHD_TFAFundChargeClaim      AS B ON ( B.CompanySeq = @CompanySeq AND A.FundChargeSeq = B.FundChargeSeq ) 
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
        END 
        
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaimItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.FundName        = A.FundName        , 
               B.ActAmt          = A.ActAmt          , 
               B.CancelDate      = A.CancelDate      , 
               B.ProfitRate       = A.ProfitRate       , 
               B.ProfitAmt        = A.ProfitAmt        , 
               B.SrtDate         = A.SrtDate         , 
               B.EndDate         = A.EndDate         , 
               B.FromToDate      = A.FromToDate      , 
               B.StdProfitRate    = A.StdProfitRate    , 
               B.ExcessProfitAmt  = A.ExcessProfitAmt  , 
               B.AdviceAmt       = A.AdviceAmt       , 
               B.LastUserSeq     = @UserSeq, 
               B.LastDateTime    = GETDATE(), 
               B.PgmSeq          = @PgmSeq
          FROM #KPXHD_TFAFundChargeClaimItem AS A   
          JOIN KPXHD_TFAFundChargeClaimItem AS B ON ( B.CompanySeq = @CompanySeq AND A.FundChargeSeq = B.FundChargeSeq AND A.FundChargeSerl = B.FundChargeSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXHD_TFAFundChargeClaimItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXHD_TFAFundChargeClaimItem  
        (   
            CompanySeq, FundChargeSeq, FundChargeSerl, FundCode, FundName, 
            ActAmt, CancelDate, ProfitRate, ProfitAmt, SrtDate, 
            EndDate, FromToDate, StdProfitRate, ExcessProfitAmt, AdviceAmt, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.FundChargeSeq, A.FundChargeSerl, A.FundCode, A.FundName, 
               A.ActAmt, A.CancelDate, A.ProfitRate, A.ProfitAmt, A.SrtDate, 
               A.EndDate, A.FromToDate, A.StdProfitRate, A.ExcessProfitAmt, A.AdviceAmt, 
               @UserSeq, GETDATE(), @PgmSeq
          FROM #KPXHD_TFAFundChargeClaimItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXHD_TFAFundChargeClaimItem   
    
    RETURN  
    go
    begin tran
exec KPXHD_SFAFundChargeClaimItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ActAmt>123.00000</ActAmt>
    <AdviceAmt>123.00000</AdviceAmt>
    <CancelDate>20160212</CancelDate>
    <EndDate>20160212</EndDate>
    <ExcessProfitAmt>123.00000</ExcessProfitAmt>
    <FromToDate>1243</FromToDate>
    <FundChargeSeq>3</FundChargeSeq>
    <FundChargeSerl>3</FundChargeSerl>
    <FundCode>201602003</FundCode>
    <FundName>12425</FundName>
    <ProfitAmt>123.00000</ProfitAmt>
    <ProfitRate>124.00000</ProfitRate>
    <SrtDate>20160212</SrtDate>
    <StdProfitRate>123.00000</StdProfitRate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028674
rollback 