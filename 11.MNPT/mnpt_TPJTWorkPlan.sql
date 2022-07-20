if object_id('mnpt_TPJTWorkPlan') is null
begin 

    CREATE TABLE mnpt_TPJTWorkPlan
    (
        CompanySeq		INT 	 NOT NULL, 
        WorkPlanSeq		INT 	 NOT NULL, 
        WorkDate		NCHAR(8) 	 NOT NULL, 
        UMWeather		INT 	 NULL, 
        MRemark		NVARCHAR(2000) 	 NULL, 
        ManRemark   NVARCHAR(2000)  NULL, 
        IsCfm		NCHAR(1) 	 NULL, 
        PJTSeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NULL, 
        ShipSerl		INT 	 NULL, 
        UMLoadType      INT NULL, 
        UMWorkType		INT 	 NOT NULL, 
        UMWorkTeam      INT NULL, 
        TodayQty		DECIMAL(19,5) 	 NULL, 
        TodayMTWeight		DECIMAL(19,5) 	 NULL, 
        TodayCBMWeight		DECIMAL(19,5) 	 NULL, 
        ExtraGroupSeq		NVARCHAR(500) 	 NULL, 
        WorkSrtTime		NCHAR(4) 	 NULL, 
        WorkEndTime		NCHAR(4) 	 NULL, 
        RealWorkTime    DECIMAL(19,5) NULL, 
        EmpSeq		INT 	 NULL, 
        DRemark		NVARCHAR(2000) 	 NULL, 
        IsTemplate          NCHAR(1) NULL, 
        TemplateUserSeq     INT NULL, 
        TemplateDateTime    DATETIME NULL, 
        SourceWorkPlanSeq   INT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTWorkPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, WorkPlanSeq ASC)

    )
end 

if objecT_id('mnpt_TPJTWorkPlanLog') is null
begin 

    CREATE TABLE mnpt_TPJTWorkPlanLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        WorkPlanSeq		INT 	 NOT NULL, 
        WorkDate		NCHAR(8) 	 NOT NULL, 
        UMWeather		INT 	 NULL, 
        MRemark		NVARCHAR(2000) 	 NULL, 
        ManRemark   NVARCHAR(2000)  NULL, 
        IsCfm		NCHAR(1) 	 NULL, 
        PJTSeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NULL, 
        ShipSerl		INT 	 NULL, 
        UMLoadType      INT NULL, 
        UMWorkType		INT 	 NOT NULL, 
        UMWorkTeam      INT NULL, 
        TodayQty		DECIMAL(19,5) 	 NULL, 
        TodayMTWeight		DECIMAL(19,5) 	 NULL, 
        TodayCBMWeight		DECIMAL(19,5) 	 NULL, 
        ExtraGroupSeq		NVARCHAR(500) 	 NULL, 
        WorkSrtTime		NCHAR(4) 	 NULL, 
        WorkEndTime		NCHAR(4) 	 NULL, 
        RealWorkTime    DECIMAL(19,5) NULL, 
        EmpSeq		INT 	 NULL, 
        DRemark		NVARCHAR(2000) 	 NULL, 
        IsTemplate          NCHAR(1) NULL, 
        TemplateUserSeq     INT NULL, 
        TemplateDateTime    DATETIME NULL, 
        SourceWorkPlanSeq   INT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTWorkPlanLog ON mnpt_TPJTWorkPlanLog (LogSeq)
end 


