if object_id('mnpt_TPJTShipMaster_IF') is null
begin 
    CREATE TABLE mnpt_TPJTShipMaster_IF
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		    INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NOT NULL, 
        LastWorkTime    NVARCHAR(12)    NOT NULL, 
        ErrMessage      NVARCHAR(200) NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime    DATETIME 	 NOT NULL, 
        PgmSeq		    INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipMaster_IF PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC)
    )
end 