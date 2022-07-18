if object_id('KPXCM_THREduPersRst') is null

begin 

--drop table KPXCM_THREduPersRst 
CREATE TABLE KPXCM_THREduPersRst
(
    CompanySeq		INT 	 NOT NULL, 
    RstSeq		INT 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    RstNo		NVARCHAR(200) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    UMEduGrpType		INT 	 NOT NULL, 
    EduClassSeq		INT 	 NOT NULL, 
    EduCourseName		NVARCHAR(200) 	 NOT NULL, 
    EduTypeSeq		INT 	 NOT NULL, 
    EtcCourseName		NVARCHAR(500) 	 NOT NULL, 
    SMInOutType		INT 	 NOT NULL, 
    EduBegDate		NCHAR(8) 	 NOT NULL, 
    EduEndDate		NCHAR(8) 	 NOT NULL, 
    EduDd		INT 	 NOT NULL, 
    EduTm		DECIMAL(19,5) 	 NOT NULL, 
    EduPoint		INT         NOT NULL, 
    IsEI		NCHAR(1) 	 NOT NULL, 
    SMComplate		INT 	 NOT NULL, 
    RstCost		DECIMAL(19,5) 	 NOT NULL, 
    ReturnAmt		DECIMAL(19,5) 	 NOT NULL, 
    RstSummary		NVARCHAR(600) 	 NOT NULL, 
    RstRem		NVARCHAR(500) 	 NOT NULL, 
    UMEduCost		INT 	 NOT NULL, 
    UMEduReport		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_THREduPersRst on KPXCM_THREduPersRst(CompanySeq,RstSeq) 
end 

if object_id('KPXCM_THREduPersRstLog') is null

begin 
--drop table KPXCM_THREduPersRstLog
CREATE TABLE KPXCM_THREduPersRstLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    RstSeq		INT 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    RstNo		NVARCHAR(200) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    UMEduGrpType		INT 	 NOT NULL, 
    EduClassSeq		INT 	 NOT NULL, 
    EduCourseName		NVARCHAR(200) 	 NOT NULL, 
    EduTypeSeq		INT 	 NOT NULL, 
    EtcCourseName		NVARCHAR(500) 	 NOT NULL, 
    SMInOutType		INT 	 NOT NULL, 
    EduBegDate		NCHAR(8) 	 NOT NULL, 
    EduEndDate		NCHAR(8) 	 NOT NULL, 
    EduDd		INT 	 NOT NULL, 
    EduTm		DECIMAL(19,5) 	 NOT NULL, 
    EduPoint		NVARCHAR(200) 	 NOT NULL, 
    IsEI		NCHAR(1) 	 NOT NULL, 
    SMComplate		INT 	 NOT NULL, 
    RstCost		DECIMAL(19,5) 	 NOT NULL, 
    ReturnAmt		DECIMAL(19,5) 	 NOT NULL, 
    RstSummary		NVARCHAR(600) 	 NOT NULL, 
    RstRem		NVARCHAR(500) 	 NOT NULL, 
    UMEduCost		INT 	 NOT NULL, 
    UMEduReport		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 