IF OBJECT_ID('KPXCM_TPDSFCWorkOrderPilot') IS NULL 
begin 
CREATE TABLE KPXCM_TPDSFCWorkOrderPilot
(
    CompanySeq		INT 	 NOT NULL, 
    PilotSeq		INT 	 NOT NULL, 
    ProdPlanSeq		INT 	 NOT NULL, 
    WorkOrderSeq		INT 	 NOT NULL, 
    WorkCenterSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    SrtDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    SrtHour		NCHAR(5) 	 NOT NULL, 
    EndHour		NCHAR(5) 	 NOT NULL, 
    Duration		DECIMAL(19,5) 	 NOT NULL, 
    DurHour		NCHAR(5) 	 NOT NULL, 
    ProdQty     DECIMAL(19,5) NOT NULL, 
    PatternSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    AfterWorkSeq		INT 	 NOT NULL, 
    IsCfm		NCHAR(1) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TPDSFCWorkOrderPilot on KPXCM_TPDSFCWorkOrderPilot(CompanySeq,PilotSeq) 

end 




IF OBJECT_ID('KPXCM_TPDSFCWorkOrderPilotLog') IS NULL 
begin 
CREATE TABLE KPXCM_TPDSFCWorkOrderPilotLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PilotSeq		INT 	 NOT NULL, 
    ProdPlanSeq		INT 	 NOT NULL, 
    WorkOrderSeq		INT 	 NOT NULL, 
    WorkCenterSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    SrtDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    SrtHour		NCHAR(5) 	 NOT NULL, 
    EndHour		NCHAR(5) 	 NOT NULL, 
    Duration		DECIMAL(19,5) 	 NOT NULL, 
    DurHour		NCHAR(5) 	 NOT NULL, 
    ProdQty     DECIMAL(19,5) NOT NULL, 
    PatternSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    AfterWorkSeq		INT 	 NOT NULL, 
    IsCfm		NCHAR(1) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 



--drop table KPXCM_TPDSFCWorkOrderPilot 
--drop table KPXCM_TPDSFCWorkOrderPilotLog