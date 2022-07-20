INSERT INTO _TDAUMinor(CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)SELECT A.CompanySeq,6017001,6017,N'주간',1,N'',0,167,'2017-09-22 13:13:57.270',N'1'
  from _TCACompany AS A 
 where not exists (select 1 from _TDAUMinor where companyseq = a.companyseq and minorseq = 6017001)

INSERT INTO _TDAUMinor(CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)SELECT A.CompanySeq,6017002,6017,N'야간',1,N'',0,167,'2017-09-22 13:13:57.270',N'1' from _TCACompany AS A 
 where not exists (select 1 from _TDAUMinor where companyseq = a.companyseq and minorseq = 6017002)