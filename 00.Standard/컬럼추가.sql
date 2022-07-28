alter table _TEQYearRepairPlanManHourCHE add DivSeq int null
alter table _TEQYearRepairPlanManHourCHELog add DivSeq int null


alter table _TEQYearRepairPlanManHourCHE add EmpSeq int null
alter table _TEQYearRepairPlanManHourCHELog add EmpSeq int null


--alter table _TEQYearRepairPlanManHourCHE add WorkOperSeq int null
--alter table _TEQYearRepairPlanManHourCHELog add WorkOperSeq int null





--ALTER TABLE  _TEQYearRepairPlanManHourCHE DROP COLUMN WorkOperSeq 

--ALTER TABLE _TEQYearRepairPlanManHourCHELog DROP COLUMN WorkOperSeq 



--CREATE TABLE _TEQYearRepairPlanManHourCHELog (   LogSeq int identity NOT NULL,    LogUserSeq int NOT NULL,    LogDateTime datetime NOT NULL,    LogType nchar(1) NOT NULL,    CompanySeq int NOT NULL,    ReqSeq int NOT NULL,    ReqSerl int NOT NULL,    RepairYear nchar(4) NOT NULL,    Amd int NOT NULL,    WorkOperSerl int NOT NULL,    ManHour decimal(19,5) NOT NULL,    OTManHour decimal(19,5) NOT NULL,    LastDateTime datetime NOT NULL,    LastUserSeq int NOT NULL,    DivSeq int NULL   ,    EmpSeq int NULL   ) 