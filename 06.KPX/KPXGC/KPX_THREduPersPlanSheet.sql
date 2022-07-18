if object_id('KPX_THREduPersPlanSheet') is null
begin 

CREATE TABLE KPX_THREduPersPlanSheet
(
    CompanySeq		INT 	 NOT NULL, 
    PlanSeq		INT 	 NOT NULL, 
    PlanKindSeq		INT 	 NOT NULL, 
    ExpectBegDate		NCHAR(8) 	 NOT NULL, 
    ExpectEndDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    EduCourseSeq		INT 	 NOT NULL, 
    EduCenterSeq		INT 	 NOT NULL, 
    EtcCourseName		NVARCHAR(200) 	 NULL, 
    ExpectDd		DECIMAL(19,5) 	 NULL, 
    ExpectTm		DECIMAL(19,5) 	 NULL, 
    EduPoint		DECIMAL(19,5) 	 NULL, 
    ExpectCost		DECIMAL(19,5) 	 NULL, 
    EduEffect		NVARCHAR(200) 	 NULL, 
    EduObject		NVARCHAR(200) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL, 

)
create unique clustered index idx_KPX_THREduPersPlanSheet on KPX_THREduPersPlanSheet(CompanySeq,PlanSeq) 
end 


if object_id('KPX_THREduPersPlanSheetLog') is null
 begin 
CREATE TABLE KPX_THREduPersPlanSheetLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlanSeq		INT 	 NOT NULL, 
    PlanKindSeq		INT 	 NOT NULL, 
    ExpectBegDate		NCHAR(8) 	 NOT NULL, 
    ExpectEndDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    EduCourseSeq		INT 	 NOT NULL, 
    EduCenterSeq		INT 	 NOT NULL, 
    EtcCourseName		NVARCHAR(200) 	 NULL, 
    ExpectDd		DECIMAL(19,5) 	 NULL, 
    ExpectTm		DECIMAL(19,5) 	 NULL, 
    EduPoint		DECIMAL(19,5) 	 NULL, 
    ExpectCost		DECIMAL(19,5) 	 NULL, 
    EduEffect		NVARCHAR(200) 	 NULL, 
    EduObject		NVARCHAR(200) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 