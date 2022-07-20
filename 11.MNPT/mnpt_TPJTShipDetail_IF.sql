if object_id('mnpt_TPJTShipDetail_IF') is null
begin 
    CREATE TABLE mnpt_TPJTShipDetail_IF
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NULL, 
        ShipYear		NCHAR(4) 	 NULL, 
        SerlNo		INT 	 NULL, 
        LastWorkTime		NVARCHAR(12) 	 NULL, 
        ErrMessage		NVARCHAR(200) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipDetail_IF PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC, ShipSerl ASC)

    )
end 


