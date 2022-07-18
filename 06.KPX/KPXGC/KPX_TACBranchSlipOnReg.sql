IF OBJECt_ID('KPX_TACBranchSlipOnReg') IS NULL
begin 
    CREATE TABLE KPX_TACBranchSlipOnReg
    (
        CompanySeq		INT 	 NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        NewDrSlipSeq		INT 	 NULL, 
        NewCrSlipSeq		INT 	 NULL, 
        CNewSlipSeq		INT 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL
    )
    create unique clustered index idx_KPX_TACBranchSlipOnReg on KPX_TACBranchSlipOnReg(CompanySeq,SlipSeq) 
end 

if object_id('KPX_TACBranchSlipOnRegLog') is null
begin 
    CREATE TABLE KPX_TACBranchSlipOnRegLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        NewDrSlipSeq		INT 	 NULL, 
        NewCrSlipSeq		INT 	 NULL, 
        CNewSlipSeq		INT 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL
    )
end 


