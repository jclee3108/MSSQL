if object_id('KPX_TPRWKEmpOTGroupApp_Confirm') is null
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupApp_Confirm 
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
CREATE UNIQUE CLUSTERED INDEX IDX_UNICLUSTERED on KPX_TPRWKEmpOTGroupApp_Confirm(CompanySeq, CfmSeq, CfmSerl, CfmSubSerl)
end 


if object_id('KPX_TPRWKEmpOTGroupApp_ConfirmLog') is null 
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupApp_ConfirmLog 
(   
    LogSeq int NOT NULL,    
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
CREATE UNIQUE CLUSTERED INDEX IDX_UNICLUSTERED on KPX_TPRWKEmpOTGroupApp_ConfirmLog(LogSeq)
CREATE  INDEX IDX_Key1 on KPX_TPRWKEmpOTGroupApp_ConfirmLog(CompanySeq, CfmSeq, CfmSerl, CfmSubSerl)
end 