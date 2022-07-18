if object_id('KPX_TPRPayEstItem') is null
begin 
CREATE TABLE KPX_TPRPayEstItem
(
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    IsBase		NCHAR(1) 	 NULL, 
    IsFix		NCHAR(1) 	 NULL, 
    IsWkLink		NCHAR(1) 	 NULL, 
    IsEst		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TPRPayEstItem on KPX_TPRPayEstItem(CompanySeq,ItemSeq) 
end 

if object_id('KPX_TPRPayEstItemLog') is null
begin 
CREATE TABLE KPX_TPRPayEstItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    IsBase		NCHAR(1) 	 NULL, 
    IsFix		NCHAR(1) 	 NULL, 
    IsWkLink		NCHAR(1) 	 NULL, 
    IsEst		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 
