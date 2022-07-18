
if object_id('KPXCM_TARBizTripCost_Confirm') is null 
begin 
CREATE TABLE KPXCM_TARBizTripCost_Confirm 
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
CREATE UNIQUE CLUSTERED INDEX IDX_UNICLUSTERED on KPXCM_TARBizTripCost_Confirm(CompanySeq, CfmSeq, CfmSerl, CfmSubSerl)
end 


if object_id('KPXCM_TARBizTripCost_ConfirmLog') is null 
begin 
CREATE TABLE KPXCM_TARBizTripCost_ConfirmLog 
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
CREATE UNIQUE CLUSTERED INDEX IDX_UNICLUSTERED on KPXCM_TARBizTripCost_ConfirmLog(LogSeq)
CREATE  INDEX IDX_Key1 on KPXCM_TARBizTripCost_ConfirmLog(CompanySeq, CfmSeq, CfmSerl, CfmSubSerl)
end 