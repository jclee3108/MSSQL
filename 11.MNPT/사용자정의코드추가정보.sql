INSERT INTO _TDAUMinorValue(CompanySeq,MinorSeq,Serl,MajorSeq,ValueSeq,ValueText,LastUserSeq,LastDateTime)SELECT A.COmpanySeq,1015816001,1000001,1015816,0,N'1',167,'2017-10-11 14:20:41.610'
  from _TCACompany AS A 
 where not exists (select 1 from _TDAUMinorValue where companyseq = a.companyseq and minorseq = 1015816001 and serl = 1000001) 

INSERT INTO _TDAUMinorValue(CompanySeq,MinorSeq,Serl,MajorSeq,ValueSeq,ValueText,LastUserSeq,LastDateTime)SELECT A.CompanySeq,1015816002,1000001,1015816,0,N'1',167,'2017-10-11 14:20:41.610' from _TCACompany AS A 
 where not exists (select 1 from _TDAUMinorValue where companyseq = a.companyseq and minorseq = 1015816002 and serl = 1000001) 


 INSERT INTO _TCOMUserDefine(CompanySeq,TableName,DefineUnitSeq,TitleSerl,Title,IsEss,CodeHelpConst,CodeHelpParams,SMInputType,MaskAndCaption,QrySort,IsFix,DataFieldID,IsCodeHelpTitle,LastUserSeq,LastDateTime,DecLen,WordSeq)SELECT 1,N'_TDAUMajor',1015816,1000001,N'본선작업여부',N'0',0,N'',1027006,N'',1,N'0',N'',N'0',167,'2017-10-11 14:20:37.517',0,NULL   from _TCACompany AS A  where not exists (Select 1 from _TCOMUserDefine where companyseq = a.companyseq and TableName = '_TDAUMajor' and DefineUnitSeq = 1015816 and TitleSerl = 1000001)