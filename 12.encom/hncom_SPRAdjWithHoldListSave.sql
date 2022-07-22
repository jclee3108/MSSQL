  
IF OBJECT_ID('hncom_SPRAdjWithHoldListSave') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListSave
GO  
  
-- v2017.02.08
      
-- 원천세신고목록-저장 by 이재천   
CREATE PROC hncom_SPRAdjWithHoldListSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hncom_TAdjWithHoldList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN     
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hncom_TAdjWithHoldList')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hncom_TAdjWithHoldList'    , -- 테이블명        
                  '#hncom_TAdjWithHoldList'    , -- 임시 테이블명        
                  'AdjSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hncom_TAdjWithHoldList WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hncom_TAdjWithHoldList  AS A   
          JOIN hncom_TAdjWithHoldList   AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hncom_TAdjWithHoldList WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMTypeSeq      = A.UMTypeSeq  
              ,B.EmpName        = A.EmpName  
              ,B.EmpCnt         = A.EmpCnt  
              ,B.TotAmt         = A.TotAmt  
              ,B.TaxEmpCnt      = A.TaxEmpCnt  
              ,B.TaxAmt         = A.TaxAmt  
              ,B.TaxShortageAmt = A.TaxShortageAmt  
              ,B.IncomeTaxAmt   = A.IncomeTaxAmt  
              ,B.ResidentTaxAmt = A.ResidentTaxAmt  
              ,B.RuralTaxAmt    = A.RuralTaxAmt
              ,B.LastUserSeq    = @UserSeq  
              ,B.LastDateTime   = GETDATE()  
              ,B.PgmSeq         = @PgmSeq    
          FROM #hncom_TAdjWithHoldList  AS A   
          JOIN hncom_TAdjWithHoldList   AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hncom_TAdjWithHoldList WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hncom_TAdjWithHoldList
        (   
            CompanySeq, AdjSeq, BizSeq, StdYM, EndDateFr, 
            EndDateTo, EndDate, UMTypeSeq, EmpName,EmpCnt, 
            TotAmt, TaxEmpCnt, TaxAmt, TaxShortageAmt, IncomeTaxAmt, 
            ResidentTaxAmt, RuralTaxAmt, IsSum, LastUserSeq, LastDateTime, 
            PgmSeq
        )   
        SELECT @CompanySeq, A.AdjSeq, A.BizSeq, A.StdYM, A.EndDateFr, 
               A.EndDateTo, '', A.UMTypeSeq, A.EmpName, A.EmpCnt, 
               A.TotAmt, A.TaxEmpCnt, A.TaxAmt, A.TaxShortageAmt, A.IncomeTaxAmt, 
               A.ResidentTaxAmt, A.RuralTaxAmt, '0', @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #hncom_TAdjWithHoldList AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hncom_TAdjWithHoldList   
      
    RETURN  
GO
--begin tran 
--exec hncom_SPRAdjWithHoldListSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <UMTypeName>잡금</UMTypeName>
--    <UMTypeSeq>1014736012</UMTypeSeq>
--    <EmpName>1</EmpName>
--    <EmpCnt>2.00000</EmpCnt>
--    <TotAmt>3.00000</TotAmt>
--    <TaxEmpCnt>4.00000</TaxEmpCnt>
--    <TaxAmt>5.00000</TaxAmt>
--    <TaxShortageAmt>6.00000</TaxShortageAmt>
--    <IncomeTaxAmt>7.00000</IncomeTaxAmt>
--    <ResidentTaxAmt>8.00000</ResidentTaxAmt>
--    <RuralTaxAmt>1.00000</RuralTaxAmt>
--    <StdYM>201702</StdYM>
--    <EndDateFr>20170108</EndDateFr>
--    <EndDateTo>20170208</EndDateTo>
--    <BizSeq>1</BizSeq>
--    <AdjSeq>2</AdjSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1511151,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032789
--select * from hncom_TAdjWithHoldList 
--rollback 