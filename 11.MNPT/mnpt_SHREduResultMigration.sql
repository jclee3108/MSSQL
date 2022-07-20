if object_id('mnpt_SHREduResultMigration') is not null
    drop proc mnpt_SHREduResultMigration
go 

create proc mnpt_SHREduResultMigration

as 


--update a
--   set EmpName = '정건'
-- from mnpt_THREduResultMigration as a 
-- where EmpName = '전건'


 select A.EmpSeq, B.EmpName
   into #Emp
   from _TDAEmpIn AS A 
   left outer join _TDAEmp AS B ON ( B.CompanySEq = 1 and B.EmpSeq = A.EmpSeq ) 
   WHERE A.CompanySEq = 1 
     and A.empid in ( 
                     select MAX(EmpID) AS EmpID 
                      from _fnAdmEmpOrd(1,'') 
                     where left(Empid,1) = 'P'
                    group by empname 
                  ) 


select 
       5 + row_number() over(order by UMEduGrpTypeName) AS IDX_NO, 
       A.UMEduGrpTypeName, 
       B.MInorSeq  AS UMEduGrpType, 
       A.EduClassName, 
       C.EduClassSeq, 
       A.EduCourseName, 
       D.EduCourseSeq, 
       A.UMInstituteName, 
       E.MInorSeq  AS UMInstitute, 
       A.UMlocationName, 
       F.MInorSeq  AS UMLoaction, 
       A.EduTypeName, 
       G.EduTypeSeq, 
       A.EmpName, 
       H.EmpSeq, 
       replace(replace(A.EduBegDate,'.',''),'-','') as EduBegDate, 
       replace(replace(A.EduEndDate,'.',''),'-','') as EduEndDate, 
       ISNULL(A.EduDd,0) AS EduDd, 
       ISNULL(A.EduTm,0) AS EduTm
  into #temp 
  from mnpt_THREduResultMigration   AS A 
  LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = 1 and b.MinorName = A.UMEduGrpTypeName AND B.Majorseq = 3908 ) 
  LEFT OUTER JOIN _THREduClass      AS C ON ( C.CompanySEq = 1 and c.EduClassName = A.EduClassName ) 
  LEFT OUTER JOIN _THREduCourse     AS D ON ( D.CompanySeq = 1 and D.EduCourseName = A.EduCourseName ) 
  LEFT OUTER JOIN _TDAUMinor        AS E On ( E.CompanySEq = 1 And e.MinorName = A.UMInstituteName and e.majorseq = 3904 ) 
  LEFT OUTER JOIN _TDAUMinor        AS F On ( F.CompanySEq = 1 And F.MinorName = A.UMlocationName and F.majorseq = 3905 ) 
  left outer join _THREduType       as g on ( g.companyseq = 1 and g.EduTypeName = A.EduTypeName ) 
  left outer join #Emp              as h on ( h.empname = a.empname ) 
 
 --where B.MinorSEq IS NULL
 --   OR C.EduClassSeq IS NULL
 --   OR D.EduCourseSeq IS NULL 
 --   or E.MInorSeq is null 
 --   or F.MInorSeq IS null 
 --   or G.EduTypeSeq is null 
 --   or H.EmpSeq is null 
 
 --select * from #temp
 --return 



 --select * from MNPT171220.._THREduPersRst 

 --/*
 INsert into _THREduPersRst 
 (
 CompanySeq
,RstSeq
,RstNo
,RegDate
,EmpSeq
,EduClassSeq
,UMEduGrpType
,EduTypeSeq
,EduCourseSeq
,EtcCourseName
,SMInOutType
,EduBegDate
,EduEndDate
,EduDd
,EduTm
,RstSummary
,RstRem
,SatisRate
,EduOkDd
,EduOkTm
,SMGradeSeq
,IsEndEval
,IsEnd
,FileNo
,SMEduPlanType
,LastUserSeq
,LastDateTime
,CfmEmpSeq
,ReqSeq
,SatisLevel
,UMInstitute
,UMlocation
,LecturerSeq
,EduPoint
,EduOKPoint
,ProgFromSeq
,ProgFromSerl
,ProgFromSubSerl
,ProgFromTableSeq
,IsBatchReq
,EtcInstitute
,Etclocation
,EtcLecturer
)
 select 1 AS CompanySeq 
        ,IDX_NO AS RstSeq 
        ,'201801' + RIGHT('0000' + CONVERT(NVARCHAR(10),IDX_NO),4) AS RstNo 
        ,'20180101' AS RegDate
        ,EmpSeq
        ,EduClassSeq 
        ,UMEduGrpType 
        ,EduTypeSeq 
        ,EduCourseSeq 
        ,'' 
        ,0 
        ,RTRIM(EduBegDate)
        ,RTRIM(EduEndDate)
        ,EduDd 
        ,EduTm 
        ,'' AS RstSummary 
        ,'' AS RstRem 
        ,NULL AS SatisRate 
        ,EduDd AS EduOkDd 
        ,EduTm AS EduOkTm 
        ,NULL AS SMGradeSeq 
        ,NULL AS IsEndEval 
        ,'1' AS IsEnd 
        ,0 AS FileNo 
        ,0 AS SMEduPlanType 
        ,1 AS LastUserSeq 
        ,GETDATE() AS LastDateTime 
        ,0 AS CfmEmpSeq 
        ,0 AS ReqSEq 
        ,0 AS SatisLevel 
        ,ISNULL(UMInstitute,0) 
        ,UMLoaction 
        ,0 AS LecturerSeq 
        ,0 AS EduPoint 
        ,0 AS EduOKPotin 
        ,NULL 
        ,Null 
        ,NULL 
        ,NULL 
        ,'1' AS IsBatchReq 
        ,'' 
        ,'' 
        ,''

   from #temp 




--select * from MNPT171220.._THREduPersRstObj 

insert into _THREduPersRstObj
select 1 AS CompanySeq, 
       IDX_NO AS RstSeq, 
       EmpSeq, 
       1 AS LastUserSEq,
       GETDATE() AS LastDateTime 
  from #temp 
 

--select * from MNPT171220.._THREduPersRst_Confirm
insert into _THREduPersRst_Confirm 
select 1 AS CompanySeq, 
       IDX_NO AS CfmSeq, 
       0 AS CfmSerl, 
       0 AS CfmSubSerl, 
       6330, 
       '0', 
       1, 
       '20180101', 
       1, 
       0, 
       '', 
       GETDATE()
  from #temp

 


  
--select * From MNPT171220.._TCOMCreateNoMaxHR where tablename = '_THREduPersRst'

insert into _TCOMCreateNoMaxHR 
select 1, 
       '_THREduPersRst', 
       '201801', 
       '', 
       '', 
       '', 
       '0687', 
       '2017010687', 
       'RstNo'

    
    delete from _TCOMCreateSeqMax where tablename = '_THREduPersRst'
    --*/
return 
go
begin tran 

exec mnpt_SHREduResultMigration

select * from _THREduPersRst 
select * from _THREduPersRstObj 
select * from _THREduPersRst_Confirm 
rollback 

select * from _TCOMCreateSeqMax where tablename = '_THREduPersRst'


select * from _THREduPersRst where rstseq = 295 
select * from _THREduPersRstObj where rstseq = 295 

295

--update a
--   set MaxSerl = '0687', 
--       MaxNo = '201801687'
--From _TCOMCreateNoMaxHR as a 
-- where tablename = '_THREduPersRst'
--and ymdinfo ='201801'