--select * from KPXCM_TEQTaskOrderCHE


if not exists (select 1 from syscolumns where id = object_id('KPXCM_TEQTaskOrderCHE') and name = 'TaskOrderEmpName1')
begin

    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpName1 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderDate1 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderResult1 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpSeq1 int null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpName2 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderDate2 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderResult2 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpSeq2 int null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpName3 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderDate3 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderResult3 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpSeq3 int null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpName4 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderDate4 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderResult4 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpSeq4 int null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpName5 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderDate5 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderResult5 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHE add TaskOrderEmpSeq5 int null 
    alter table KPXCM_TEQTaskOrderCHE add WorkDateFr nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHE add WorkDateTo nchar(8) null 

    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpName1 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderDate1 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderResult1 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpSeq1 int null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpName2 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderDate2 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderResult2 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpSeq2 int null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpName3 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderDate3 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderResult3 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpSeq3 int null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpName4 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderDate4 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderResult4 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpSeq4 int null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpName5 nvarchar(200) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderDate5 nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderResult5 nvarchar(500) null 
    alter table KPXCM_TEQTaskOrderCHELog add TaskOrderEmpSeq5 int null 
    alter table KPXCM_TEQTaskOrderCHELog add WorkDateFr nchar(8) null 
    alter table KPXCM_TEQTaskOrderCHELog add WorkDateTo nchar(8) null 



    ALTER TABLE  KPXCM_TEQTaskOrderCHE DROP COLUMN changePlan 
    ALTER TABLE  KPXCM_TEQTaskOrderCHE DROP COLUMN TaskOrder 



    ALTER TABLE  KPXCM_TEQTaskOrderCHELog DROP COLUMN changePlan 
    ALTER TABLE  KPXCM_TEQTaskOrderCHELog DROP COLUMN TaskOrder 

end 




--select * from KPXCM_TEQTaskOrderCHE