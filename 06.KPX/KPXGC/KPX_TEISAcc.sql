if object_id('KPX_TEISAcc') is null
begin 
    CREATE TABLE KPX_TEISAcc
    (
        CompanySeq		INT 	 NOT NULL, 
        Seq		INT 	 NOT NULL, 
        KindSeq INT NULL, 
        AccSeq		INT 	 NULL, 
        TextCode		NVARCHAR(200) 	 NULL, 
        TextName		NVARCHAR(200) 	 NULL, 
        AccSeqSub		INT 	 NULL, 
        TextCodeSub		NVARCHAR(200) 	 NULL, 
        TextNameSub		NVARCHAR(200) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL 
    )
create unique clustered index idx_KPX_TEISAcc on KPX_TEISAcc(CompanySeq,Seq) 
end 


if object_id('KPX_TEISAccLog') is null
begin 
CREATE TABLE KPX_TEISAccLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Seq		INT 	 NOT NULL, 
    KindSeq INT NULL, 
    AccSeq		INT 	 NULL, 
    TextCode		NVARCHAR(200) 	 NULL, 
    TextName		NVARCHAR(200) 	 NULL, 
    AccSeqSub		INT 	 NULL, 
    TextCodeSub		NVARCHAR(200) 	 NULL, 
    TextNameSub		NVARCHAR(200) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 