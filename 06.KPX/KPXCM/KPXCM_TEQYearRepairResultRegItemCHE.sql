if object_id('KPXCM_TEQYearRepairResultRegItemCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairResultRegItemCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultSerl		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegSerl		INT 	 NOT NULL, 
    ProgType		INT 	 NOT NULL, 
    UMProtectKind		INT 	 NOT NULL, 
    UMWorkReason		INT 	 NOT NULL, 
    UMPreProtect		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TEQYearRepairResultRegItemCHE on KPXCM_TEQYearRepairResultRegItemCHE(CompanySeq,ResultSeq,ResultSerl) 
end 

if object_id('KPXCM_TEQYearRepairResultRegItemCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairResultRegItemCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultSerl		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegSerl		INT 	 NOT NULL, 
    ProgType		INT 	 NOT NULL, 
    UMProtectKind		INT 	 NOT NULL, 
    UMWorkReason		INT 	 NOT NULL, 
    UMPreProtect		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 