if object_id('KPX_THRWelmediAccCCtr') is null
 begin 
CREATE TABLE KPX_THRWelmediAccCCtr
(
    CompanySeq		INT 	 NOT NULL, 
    EnvValue		INT 	 NOT NULL, 
    YM		NCHAR(6) 	 NOT NULL, 
    GroupSeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    AccSeq		INT 	 NULL, 
    UMCostType		INT 	 NULL, 
    OppAccseq		INT 	 NULL, 
    VATAccSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_THRWelmediAccCCtr on KPX_THRWelmediAccCCtr(CompanySeq,EnvValue,YM,GroupSeq,WelCodeSeq) 
end 

if object_id('KPX_THRWelmediAccCCtrLog') is null 
begin 
CREATE TABLE KPX_THRWelmediAccCCtrLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    EnvValue		INT 	 NOT NULL, 
    YM		NCHAR(6) 	 NOT NULL, 
    GroupSeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    AccSeq		INT 	 NULL, 
    UMCostType		INT 	 NULL, 
    OppAccseq		INT 	 NULL, 
    VATAccSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 