if object_id('KPX_TPDSFCProdPackOrder_Confirm') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackOrder_Confirm 
(   
    CompanySeq int NULL   ,    
    CfmSeq int NULL   ,    
    CfmSerl int NULL   ,    
    CfmSubSerl int NULL   ,    
    CfmSecuSeq int NULL   ,    
    IsAuto nchar(1) NULL   ,    
    CfmCode int NULL   ,    
    CfmDate nchar(8) NULL   ,    
    CfmEmpSeq int NULL   ,    
    UMCfmReason int NULL   ,    
    CfmReason nvarchar(500) NULL   ,    
    LastDateTime datetime NULL   
) 
CREATE UNIQUE CLUSTERED INDEX IDX_UNICLUSTERED on KPX_TPDSFCProdPackOrder_Confirm(CompanySeq, CfmSeq, CfmSerl, CfmSubSerl)

end 

if object_id('KPX_TPDSFCProdPackOrder_ConfirmLog') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackOrder_ConfirmLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NULL   ,    
    LogDateTime datetime NULL   ,   
    LogType nchar(1) NULL   ,    
    CompanySeq int NULL   ,    
    CfmSeq int NULL   ,    
    CfmSerl int NULL   ,    
    CfmSubSerl int NULL   ,   
    CfmSecuSeq int NULL   ,   
    IsAuto nchar(1) NULL   ,   
    CfmCode int NULL   ,   
    CfmDate nchar(8) NULL   ,   
    CfmEmpSeq int NULL   ,   
    UMCfmReason int NULL   ,   
    CfmReason nvarchar(500) NULL   ,   
    LastDateTime datetime NULL   ,    
    LogPgmSeq int NULL   
) 
end 

