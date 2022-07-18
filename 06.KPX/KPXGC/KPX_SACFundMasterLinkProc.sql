
IF OBJECT_ID('KPX_SACFundMasterLinkProc') IS NOT NULL 
    DROP PROC KPX_SACFundMasterLinkProc
GO 

-- v2014.12.16 

-- 마스터데이터연동 - 금융상품명세서 by이재천 
 CREATE PROC KPX_SACFundMasterLinkProc
    @CompanySeq INT = 1,
    @PgmSeq     INT 
 AS
    
    
    SELECT IDENTITY(INT, 1,1) AS IDX,
           CompanySeq     
      INTO #Company
      FROM _TCACompany
     WHERE CompanySeq <> @CompanySeq
    
    
    DELETE KPX_TACFundMaster
     WHERE CompanySeq <> @CompanySeq
          
    INSERT INTO KPX_TACFundMaster
    (
        CompanySeq, FundSeq, FundName, FundCode, UMBond, BankSeq, 
        TitileName, FundKindM, FundKindS, ItemResult, BeforeRate, 
        FixRate, Hudle, Act, SalesName, EmpName, 
        ActCompany, BillCompany, SetupTypeName, BaseCost, ActType, 
        Trade, TagetAdd, OpenInterest, InvestType, OldFundSeq, 
        SetupDate, DurDate, AccDate, Interest, Barrier, 
        EarlyRefund, TrustLevel, Remark1, Remark2, Remark3, 
        FileSeq, LastUserSeq, LastDateTime
    )
    SELECT B.CompanySeq, A.FundSeq, A.FundName, A.FundCode, A.UMBond, A.BankSeq, 
           A.TitileName, A.FundKindM, A.FundKindS, A.ItemResult, A.BeforeRate, 
           A.FixRate, A.Hudle, A.Act, A.SalesName, A.EmpName, 
           A.ActCompany, A.BillCompany, A.SetupTypeName, A.BaseCost, A.ActType, 
           A.Trade, A.TagetAdd, A.OpenInterest, A.InvestType, A.OldFundSeq, 
           A.SetupDate, A.DurDate, A.AccDate, A.Interest, A.Barrier, 
           A.EarlyRefund, A.TrustLevel, A.Remark1, A.Remark2, A.Remark3, 
           A.FileSeq, A.LastUserSeq, A.LastDateTime
      FROM KPX_TACFundMaster    AS A WITH(NOLOCK)
      LEFT OUTER JOIN #Company  AS B ON 1=1                
     WHERE A.CompanySeq = @CompanySeq
    
    
    UPDATE KPX_TDAMasterDataPgm
       SET LastInsertTime = GETDATE()
     WHERE PgmSeq = @PgmSeq
    
    RETURN
GO 
begin tran 
exec KPX_SACFundMasterLinkProc @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1024282,@WorkingTag=N'',@CompanySeq=99,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1022318

select * From KPX_TACFundMaster

rollback 