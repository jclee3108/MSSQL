if object_id('mnpt_TPJTShipDetail') is null
begin 

    CREATE TABLE mnpt_TPJTShipDetail
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(50) 	 NOT NULL, 
        ShipSerlNo		NCHAR(7) 	 NOT NULL, 
        InPlanDateTime		NVARCHAR(50) 	 NULL, 
        OutPlanDateTime		NVARCHAR(50) 	 NULL, 
        InDateTime		NVARCHAR(50) 	 NULL, 
        ApproachDateTime		NVARCHAR(50) 	 NULL, 
        WorkSrtDateTime		NVARCHAR(50) 	 NULL, 
        WorkEndDateTime		NVARCHAR(50) 	 NULL, 
        OutDateTime		NVARCHAR(50) 	 NULL, 
        DiffApproachTime    DECIMAL(19,5) NULL,
        BERTH		NVARCHAR(50) 	 NULL, 
        BRIDGE		NVARCHAR(50) 	 NULL, 
        FROM_BIT		NVARCHAR(50) 	 NULL, 
        TO_BIT		NVARCHAR(50) 	 NULL, 
        PORT		NVARCHAR(50) 	 NULL, 
        TRADECode		NVARCHAR(50) 	 NULL, 
        BULKCNTR		NVARCHAR(50) 	 NULL, 
        BizUnitCode		NVARCHAR(50) 	 NULL, 
        AgentName		NVARCHAR(200) 	 NULL, 
        UMApplyTon      INT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipDetail PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC, ShipSerl ASC)

    )
end 

if object_id('mnpt_TPJTShipDetailLog') is null
begin 
    CREATE TABLE mnpt_TPJTShipDetailLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(50) 	 NOT NULL, 
        ShipSerlNo		NCHAR(7) 	 NOT NULL, 
        InPlanDateTime		NVARCHAR(50) 	 NULL, 
        OutPlanDateTime		NVARCHAR(50) 	 NULL, 
        InDateTime		NVARCHAR(50) 	 NULL, 
        ApproachDateTime		NVARCHAR(50) 	 NULL, 
        WorkSrtDateTime		NVARCHAR(50) 	 NULL, 
        WorkEndDateTime		NVARCHAR(50) 	 NULL, 
        OutDateTime		NVARCHAR(50) 	 NULL, 
        DiffApproachTime    DECIMAL(19,5) NULL,
        BERTH		NVARCHAR(50) 	 NULL, 
        BRIDGE		NVARCHAR(50) 	 NULL, 
        FROM_BIT		NVARCHAR(50) 	 NULL, 
        TO_BIT		NVARCHAR(50) 	 NULL, 
        PORT		NVARCHAR(50) 	 NULL, 
        TRADECode		NVARCHAR(50) 	 NULL, 
        BULKCNTR		NVARCHAR(50) 	 NULL, 
        BizUnitCode		NVARCHAR(50) 	 NULL, 
        AgentName		NVARCHAR(200) 	 NULL, 
        UMApplyTon      INT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTShipDetailLog ON mnpt_TPJTShipDetailLog (LogSeq)
end 


