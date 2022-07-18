if object_id('KPXCM_TPDShutDown') is null

begin 

CREATE TABLE KPXCM_TPDShutDown
(
    CompanySeq		INT 	 NULL, 
    SDSeq		INT 	 NULL, 
    FactUnit		INT 	 NULL, 
    SrtDate		NCHAR(8) 	 NULL, 
    EndDate		NCHAR(8) 	 NULL, 
    SrtTimeSeq  INT 	 NULL, 
    EndTimeSeq  INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL

)
create unique clustered index idx_KPXCM_TPDShutDown on KPXCM_TPDShutDown(CompanySeq,SDSeq) 
end 


if object_id('KPXCM_TPDShutDownLog') is null
begin 
CREATE TABLE KPXCM_TPDShutDownLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NULL, 
    SDSeq		INT 	 NULL, 
    FactUnit		INT 	 NULL, 
    SrtDate		NCHAR(8) 	 NULL, 
    EndDate		NCHAR(8) 	 NULL, 
    SrtTimeSeq  INT 	 NULL, 
    EndTimeSeq  INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

end 


