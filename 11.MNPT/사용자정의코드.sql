INSERT INTO _TDAUMajor(CompanySeq,MajorSeq,MajorName,MajorSort,SMInputMethod,Remark,WordSeq,FixCombo,IsCombo,LastUserSeq,LastDateTime,AddCheckScript,AddSaveScript)SELECT A.CompanySeq,1015786,N'화물구분_mnpt',0,0,N'',0,N'0',N'0',167,'2017-09-06 11:54:33.947',N'',N''  from _TCACompany AS A  where not exists (Select 1 from _TDAUMajor where companyseq = A.CompanySeq AND Majorseq = 1015786)INSERT INTO _TDAUMinor(CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)SELECT A.CompanySeq,1015786001,1015786,N'CNTR',1,N'',0,167,'2017-09-06 11:56:11.320',N'1'
  from _TCACompany AS A 
 where not exists (select 1 from _TDAUMinor where companyseq = a.companyseq and minorseq = 1015786001)

INSERT INTO _TDAUMinor(CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)SELECT A.CompanySeq,1015786002,1015786,N'BULK',2,N'',0,167,'2017-09-06 11:56:11.320',N'1'
from _TCACOmpany AS A 
where not exists (select 1 from _TDAUMinor where companyseq = a.companyseq and minorseq = 1015786002)

INSERT INTO _TDAUMinor(CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)SELECT A.CompanySeq,1015786003,1015786,N'혼합선',3,N'',0,167,'2017-09-06 11:56:11.320',N'1'  from _TCACOmpany AS A  where not exists (select 1 from _TDAUMinor where companyseq = a.companyseq and minorseq = 1015786003)INSERT INTO _TDAUMinorValue(CompanySeq,MinorSeq,Serl,MajorSeq,ValueSeq,ValueText,LastUserSeq,LastDateTime)SELECT A.CompanySEq,1015786001,1000001,1015786,0,N'C',167,'2017-09-06 11:56:11.550'
  from _TCACOmpany AS A 
 where not exists (select 1 from _TDAUMinorValue where companyseq = a.companyseq and minorseq = 1015786001 and serl = 1000001) 

INSERT INTO _TDAUMinorValue(CompanySeq,MinorSeq,Serl,MajorSeq,ValueSeq,ValueText,LastUserSeq,LastDateTime)SELECT A.CompanySeq,1015786002,1000001,1015786,0,N'B',167,'2017-09-06 11:56:11.550'
 from _TCACOmpany AS A 
 where not exists (select 1 from _TDAUMinorValue where companyseq = a.companyseq and minorseq = 1015786002 and serl = 1000001) 

INSERT INTO _TDAUMinorValue(CompanySeq,MinorSeq,Serl,MajorSeq,ValueSeq,ValueText,LastUserSeq,LastDateTime)SELECT A.CompanySeq,1015786003,1000001,1015786,0,N'P',167,'2017-09-06 11:56:11.550' from _TCACOmpany AS A 
 where not exists (select 1 from _TDAUMinorValue where companyseq = a.companyseq and minorseq = 1015786003 and serl = 1000001) INSERT INTO _TCOMUserDefine(CompanySeq,TableName,DefineUnitSeq,TitleSerl,Title,IsEss,CodeHelpConst,CodeHelpParams,SMInputType,MaskAndCaption,QrySort,IsFix,DataFieldID,IsCodeHelpTitle,LastUserSeq,LastDateTime,DecLen,WordSeq)SELECT A.CompanySeq,N'_TDAUMajor',1015786,1000001,N'운영정보코드',N'0',0,N'',1027001,N'',1,N'0',N'',N'0',167,'2017-09-06 11:55:42.630',0,NULL   from _TCACompany AS A  where not exists (Select 1 from _TCOMUserDefine where companyseq = a.companyseq and TableName = '_TDAUMajor' AND DefineUnitSeq = 1015786 and TitleSerl = 1000001)