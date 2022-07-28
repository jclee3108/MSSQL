
Insert Into _TCOMConfirmDef(CompanySeq,ConfirmSeq,ConfirmName,ConfirmID,ConfirmTableSeq,AutoConfirmSPName,IsNotUsed,LastUserSeq,LastDateTime,ISDisableCheck) 
select A.CompanySeq,6418,N'시험성적서확정',N'estReportUMSpecConfirm',6431,N'',N'0',1000204,'2014-07-22 16:58:17.947',N'0'
  from _TCACompany AS A 
 where not exists ( select 1 from _TCOMConfirmDef where CompanySeq = A.CompanySeq and ConfirmSeq = 6418 ) 
 
Insert Into _TCOMConfirmTable(CompanySeq,ConfirmTableSeq,ConfirmTableName,ConfirmTableDESC,ProgressTableName,ProgressCheckLevel,LastUserSeq,LastDateTime,ConfirmCheckLevel) 
select A.CompanySeq,6431,N'_TPDTestReportUMSpec',N'시험성적서등록',N'',0,1000204,'2014-07-22 16:56:35.940',1
  from _TCACompany AS A 
where not exists ( select 1 from _TCOMConfirmDef where CompanySeq = A.CompanySeq and ConfirmTableSeq = 6431 ) 

Insert Into _TCOMConfirmPgm(CompanySeq,ConfirmSeq,ConfirmSerl,PGMSeq,LastUserSeq,LastDateTime) 
select A.CompanySeq,6418,1,100438,1000204,'2014-07-22 16:58:47.840' 
  from _TCACompany AS A 
 where not exists ( select 1 from _TCOMConfirmDef where CompanySeq = A.CompanySeq and ConfirmSeq = 6418 and ConfirmSerl = 1 ) 

Insert Into _TCOMConfirmPgm(CompanySeq,ConfirmSeq,ConfirmSerl,PGMSeq,LastUserSeq,LastDateTime) 
select A.CompanySeq,6418,2,100439,1000204,'2014-07-22 16:58:47.840' 
  from _TCACompany AS A 
where not exists ( select 1 from _TCOMConfirmDef where CompanySeq = A.CompanySeq and ConfirmSeq = 6418 and ConfirmSerl = 2 ) 
