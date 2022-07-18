  
IF OBJECT_ID('KPX_SACFundMasterSave') IS NOT NULL   
    DROP PROC KPX_SACFundMasterSave  
GO  
  
-- v2014.12.11  
  
-- 금융상품명세서-저장 by 이재천   
CREATE PROC KPX_SACFundMasterSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TACFundMaster (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACFundMaster'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACFundMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACFundMaster'    , -- 테이블명        
                  '#KPX_TACFundMaster'    , -- 임시 테이블명        
                  'FundSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundMaster WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TACFundMaster AS A   
          JOIN KPX_TACFundMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundMaster WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.FundName = A.FundName,  
               B.FundCode = A.FundCode,  
               B.UMBond = A.UMBond, 
               B.BankSeq = A.BankSeq,  
               B.TitileName = A.TitileName,  
               B.FundKindM = A.FundKindM,  
               B.FundKindS = A.FundKindS,  
               B.ItemResult = A.ItemResult,  
               B.BeforeRate = A.BeforeRate,  
               B.FixRate = A.FixRate,  
               B.Hudle = A.Hudle,  
               B.Act = A.Act,  
               B.SalesName = A.SalesName,  
               B.EmpName = A.EmpName,  
               B.ActCompany = A.ActCompany,  
               B.BillCompany = A.BillCompany,  
               B.SetupTypeName = A.SetupTypeName,  
               B.BaseCost = A.BaseCost,  
               B.ActType = A.ActType,  
               B.Trade = A.Trade,  
               B.TagetAdd = A.TagetAdd,  
               B.OpenInterest = A.OpenInterest,  
               B.InvestType = A.InvestType,  
               B.OldFundSeq = A.OldFundSeq,  
               B.SetupDate = A.SetupDate,  
               B.DurDate = A.DurDate,  
               B.AccDate = A.AccDate,  
               B.Interest = A.Interest,  
               B.Barrier = A.Barrier,  
               B.EarlyRefund = A.EarlyRefund,  
               B.TrustLevel = A.TrustLevel,  
               B.Remark1 = A.Remark1,  
               B.Remark2 = A.Remark2,  
               B.Remark3 = A.Remark3,  
               B.FileSeq =  A.FileSeq,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_TACFundMaster AS A   
          JOIN KPX_TACFundMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACFundMaster WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TACFundMaster  
        (   
            CompanySeq,FundSeq,FundName,FundCode,UMBond,BankSeq,  
            TitileName,FundKindM,FundKindS,ItemResult,BeforeRate,  
            FixRate,Hudle,Act,SalesName,EmpName,  
            ActCompany,BillCompany,SetupTypeName,BaseCost,ActType,  
            Trade,TagetAdd,OpenInterest,InvestType,OldFundSeq,  
            SetupDate,DurDate,AccDate,Interest,Barrier,  
            EarlyRefund,TrustLevel,Remark1,Remark2,Remark3,  
            FileSeq,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.FundSeq,A.FundName,A.FundCode,A.UMBond,A.BankSeq,  
               A.TitileName,A.FundKindM,A.FundKindS,A.ItemResult,A.BeforeRate,  
               A.FixRate,A.Hudle,A.Act,A.SalesName,A.EmpName,  
               A.ActCompany,A.BillCompany,A.SetupTypeName,A.BaseCost,A.ActType,  
               A.Trade,A.TagetAdd,A.OpenInterest,A.InvestType,A.OldFundSeq,  
               A.SetupDate,A.DurDate,A.AccDate,A.Interest,A.Barrier,  
               A.EarlyRefund,A.TrustLevel,A.Remark1,A.Remark2,A.Remark3,  
               A.FileSeq,@UserSeq,GETDATE()   
          FROM #KPX_TACFundMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TACFundMaster   
    
    RETURN  