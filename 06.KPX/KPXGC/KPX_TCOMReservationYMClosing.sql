if object_id('KPX_TCOMReservationYMClosing') is null
begin 
CREATE TABLE KPX_TCOMReservationYMClosing
(
    CompanySeq		INT 	 NOT NULL, 
    ClosingSeq      INT         NOT NULL, 
    ClosingYM		NCHAR(6) 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    IsCancel		NCHAR(1) 	 NOT NULL, 
    ReservationDate		NCHAR(8) 	 NOT NULL, 
    ReservationTime		NCHAR(4) 	 NOT NULL, 
    ProcDate		NCHAR(12) 	 NULL, 
    ProcResult		NVARCHAR(500) 	 NULL,
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPX_TCOMReservationYMClosing on KPX_TCOMReservationYMClosing(CompanySeq,ClosingSeq) 
end 

if object_id('KPX_TCOMReservationYMClosingLog') is null
begin 
CREATE TABLE KPX_TCOMReservationYMClosingLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ClosingSeq      INT         NOT NULL, 
    ClosingYM		NCHAR(6) 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    IsCancel		NCHAR(1) 	 NOT NULL, 
    ReservationDate		NCHAR(8) 	 NOT NULL, 
    ReservationTime		NCHAR(4) 	 NOT NULL, 
    ProcDate		NCHAR(12) 	 NULL, 
    ProcResult		NVARCHAR(500) 	 NULL,
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 


