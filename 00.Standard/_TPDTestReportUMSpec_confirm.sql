if OBJECT_ID('_TPDTestReportUMSpec_confirm') is null 
begin 
CREATE TABLE _TPDTestReportUMSpec_confirm 
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
end 

if OBJECT_ID('_TPDTestReportUMSpec_confirmlog') is null 
begin 
CREATE TABLE _TPDTestReportUMSpec_confirmlog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
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
end 