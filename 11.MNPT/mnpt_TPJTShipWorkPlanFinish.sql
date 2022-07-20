if object_id('mnpt_TPJTShipWorkPlanFinish') is null
begin 
    CREATE TABLE mnpt_TPJTShipWorkPlanFinish
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipPlanFinishSeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        DockPJTSeq  INT  NULL, 
        PlanQty		DECIMAL(19,5) 	 NULL, 
        PlanMTWeight		DECIMAL(19,5) 	 NULL, 
        PlanCBMWeight		DECIMAL(19,5) 	 NULL, 
        IsCfm		NCHAR(1) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipWorkPlanFinish PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipPlanFinishSeq ASC)

    )
end 


if object_id('mnpt_TPJTShipWorkPlanFinishLog') is null
begin 
    CREATE TABLE mnpt_TPJTShipWorkPlanFinishLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ShipPlanFinishSeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        DockPJTSeq  INT  NULL, 
        PlanQty		DECIMAL(19,5) 	 NULL, 
        PlanMTWeight		DECIMAL(19,5) 	 NULL, 
        PlanCBMWeight		DECIMAL(19,5) 	 NULL, 
        IsCfm		NCHAR(1) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTShipWorkPlanFinishLog ON mnpt_TPJTShipWorkPlanFinishLog (LogSeq)
end 
