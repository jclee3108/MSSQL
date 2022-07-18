IF OBJECT_ID('KPX_TPDSFCProdPackReportRelation') IS NULL
BEGIN  
CREATE TABLE KPX_TPDSFCProdPackReportRelation
(
    CompanySeq		INT 	 NOT NULL, 
    WorkOrderSeq		INT 	 NOT NULL, 
    WorkOrderSerl		INT 	 NOT NULL, 
    DataKind            INT NOT NULL, 
    InOutType		INT 	 NOT NULL, 
    InOutSeq		INT 	 NOT NULL, 
    InOutSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TPDSFCProdPackReportRelation on KPX_TPDSFCProdPackReportRelation(CompanySeq,WorkOrderSeq,WorkOrderSerl,DataKind,InOutType,InOutSeq,InOutSerl)
END 


IF OBJECT_ID('KPX_TPDSFCProdPackReportRelationLog') IS NULL
BEGIN  
CREATE TABLE KPX_TPDSFCProdPackReportRelationLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WorkOrderSeq		INT 	 NOT NULL, 
    WorkOrderSerl		INT 	 NOT NULL, 
    DataKind            INT NOT NULL, 
    InOutType		INT 	 NOT NULL, 
    InOutSeq		INT 	 NOT NULL, 
    InOutSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
END 


