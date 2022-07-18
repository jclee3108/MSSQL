if object_id('KPXCM_TEQYearRepairReceiptRegCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReceiptRegCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQYearRepairReceiptRegCHE on KPXCM_TEQYearRepairReceiptRegCHE(CompanySeq,ReceiptRegSeq) 
end 


if object_id('KPXCM_TEQYearRepairReceiptRegCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReceiptRegCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 
