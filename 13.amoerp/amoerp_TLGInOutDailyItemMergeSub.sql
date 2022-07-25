
IF OBJECT_ID('amoerp_TLGInOutDailyItemMergeSub') IS NULL 
BEGIN

    CREATE TABLE amoerp_TLGInOutDailyItemMergeSub
    (
        CompanySeq		INT 	 NOT NULL, 
        InOutSeq		INT 	 NOT NULL, 
        InOutSerl		INT 	 NOT NULL, 
        InOutSubSerl		INT 	 NOT NULL, 
        LotNo		NVARCHAR(50) 	 NULL, 
        Qty		DECIMAL(19,5) 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL, 
    CONSTRAINT PKamoerp_TLGInOutDailyItemMergeSub PRIMARY KEY CLUSTERED (CompanySeq ASC, InOutSeq ASC, InOutSerl ASC, InOutSubSerl ASC)
    )
END 

IF OBJECT_ID('amoerp_TLGInOutDailyItemMergeSubLog') IS NULL 
BEGIN
    
    CREATE TABLE amoerp_TLGInOutDailyItemMergeSubLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        InOutSeq		INT 	 NOT NULL, 
        InOutSerl		INT 	 NOT NULL, 
        InOutSubSerl		INT 	 NOT NULL, 
        LotNo		NVARCHAR(50) 	 NULL, 
        Qty		DECIMAL(19,5) 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempamoerp_TLGInOutDailyItemMergeSubLog ON amoerp_TLGInOutDailyItemMergeSubLog (LogSeq)

END