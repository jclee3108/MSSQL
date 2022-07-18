


--drop proc test1_jclee1

--go
--create proc test1_jclee1 

--as 


--selecT *from _TPDTool where umtoolkind = 68 


--select * from _TDAUMinor where companyseq = 2 and majorseq = 6009 and minorseq  > 200
 
 
 --select * 
 --  into backup_20150724_TDAUMinor
 --  from _TDAUMinor 
 --  where companyseq = 2 and majorseq = 6009
   

-- 운영, 업무 

delete from _TDAUMinor where companyseq = 2 and majorseq = 6009 and minorseq  > 200
update A
   set MinorSeq = CONVERT(NVARCHAR(100), MajorSeq) + RIGHT('000' + CONVERT(NVARCHAR(10),MinorSeq),3)
  from _TDAUMinor AS A 
  where companyseq = 2 and majorseq = 6009 and minorseq < 200
 
 select *from _TDAUMinor where companyseq = 2 and majorseq = 6009 
 
 insert into _TDAUMinor
 select *from KPXERP.dbo._TDAUMinor where companyseq = 2 and majorseq = 6009 
 
delete from _TCOMUserDefine where companyseq = 2 and tablename = '_TDAUMajor_6009' and defineunitseq > 200 
 update a 
    set defineunitseq = '6009' + RIGHT('000' + CONVERT(NVARCHAR(10),defineunitseq),3)
   from _TCOMUserDefine as a 
  where companyseq = 2 
    and tablename = '_TDAUMajor_6009' 
  
  --select *from _TCOMUserDefine where companyseq = 2 and tablename = '_TDAUMajor_6009' 
 
 --insert into _TCOMUserDefine 
 --select *from KPXERP.dbo._TCOMUserDefine where companyseq = 2 and tablename = '_TDAUMajor_6009' 
     

-- 업무 
update A 
   set UMToolKind = '6009' + RIGHT('000' + CONVERT(NVARCHAR(10),UMToolKind),3)
  from _TPDTool AS A 
 where companyseq = 2 


update A 
   set UMToolKind = '6009' + RIGHT('000' + CONVERT(NVARCHAR(10),UMToolKind),3)
  from _TDAUMToolKindTreeCHE  AS A 
 where companyseq = 2 
 
 

 
 
 
 --return 
 
 --go 
 --exec test1_jclee1







