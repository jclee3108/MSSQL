
IF OBJECT_ID('amoerp_TLGInOutDailyItemMerge') IS NULL 
BEGIN

    CREATE TABLE amoerp_TLGInOutDailyItemMerge
    (
        CompanySeq		INT 	 NOT NULL, 
        InOutType		INT 	 NOT NULL, 
        InOutSeq		INT 	 NOT NULL, 
        InOutSerl		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        InOutRemark		NVARCHAR(200) 	 NULL, 
        CCtrSeq		INT 	 NULL, 
        DVPlaceSeq		INT 	 NULL, 
        InWHSeq		INT 	 NULL, 
        OutWHSeq		INT 	 NULL, 
        UnitSeq		INT 	 NULL, 
        Qty		DECIMAL(19,5) 	 NULL, 
        STDQty		DECIMAL(19,5) 	 NULL, 
        Amt		DECIMAL(19,5) 	 NULL, 
        EtcOutAmt		DECIMAL(19,5) 	 NULL, 
        EtcOutVAT		DECIMAL(19,5) 	 NULL, 
        InOutKind		INT 	 NULL, 
        InOutDetailKind		INT 	 NULL, 
        LotNo		NVARCHAR(30) 	 NULL, 
        SerialNo		NVARCHAR(30) 	 NULL, 
        IsStockSales		NCHAR(1) 	 NULL, 
        OriUnitSeq		INT 	 NULL, 
        OriItemSeq		INT 	 NULL, 
        OriQty		DECIMAL(19,5) 	 NULL, 
        OriSTDQty		DECIMAL(19,5) 	 NULL, 
        OriLotNo		NVARCHAR(30) 	 NULL, 
        PJTSeq		INT 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        ProgFromSeq		INT 	 NULL, 
        ProgFromSerl		INT 	 NULL, 
        ProgFromSubSerl		INT 	 NULL, 
        ProgFromTableSeq		INT 	 NULL, 
        PgmSeq		INT 	 NULL, 
    CONSTRAINT PKamoerp_TLGInOutDailyItemMerge PRIMARY KEY CLUSTERED (CompanySeq ASC, InOutType ASC, InOutSeq ASC, InOutSerl ASC)
    )

END


IF OBJECT_ID('amoerp_TLGInOutDailyItemMergeLog') IS NULL 
BEGIN

    CREATE TABLE amoerp_TLGInOutDailyItemMergeLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        InOutType		INT 	 NOT NULL, 
        InOutSeq		INT 	 NOT NULL, 
        InOutSerl		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        InOutRemark		NVARCHAR(200) 	 NULL, 
        CCtrSeq		INT 	 NULL, 
        DVPlaceSeq		INT 	 NULL, 
        InWHSeq		INT 	 NULL, 
        OutWHSeq		INT 	 NULL, 
        UnitSeq		INT 	 NULL, 
        Qty		DECIMAL(19,5) 	 NULL, 
        STDQty		DECIMAL(19,5) 	 NULL, 
        Amt		DECIMAL(19,5) 	 NULL, 
        EtcOutAmt		DECIMAL(19,5) 	 NULL, 
        EtcOutVAT		DECIMAL(19,5) 	 NULL, 
        InOutKind		INT 	 NULL, 
        InOutDetailKind		INT 	 NULL, 
        LotNo		NVARCHAR(30) 	 NULL, 
        SerialNo		NVARCHAR(30) 	 NULL, 
        IsStockSales		NCHAR(1) 	 NULL, 
        OriUnitSeq		INT 	 NULL, 
        OriItemSeq		INT 	 NULL, 
        OriQty		DECIMAL(19,5) 	 NULL, 
        OriSTDQty		DECIMAL(19,5) 	 NULL, 
        OriLotNo		NVARCHAR(30) 	 NULL, 
        PJTSeq		INT 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        ProgFromSeq		INT 	 NULL, 
        ProgFromSerl		INT 	 NULL, 
        ProgFromSubSerl		INT 	 NULL, 
        ProgFromTableSeq		INT 	 NULL, 
        PgmSeq		INT 	 NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempamoerp_TLGInOutDailyItemMergeLog ON amoerp_TLGInOutDailyItemMergeLog (LogSeq)

END