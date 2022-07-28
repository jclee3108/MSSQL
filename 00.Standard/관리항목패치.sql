 Insert Into _TDAAccountRem(CompanySeq,RemSeq,RemName,SMSourceKind,MajorSeq,SMInputType,Remark,CodeHelpSeq,CodeHelpParams,WordSeq,IsSystem,LastUserSeq,LastDateTime) 
 select A.CompanySeq,2059,N'´ë¿©',4017002,0,4016002,N'',120077,N'',0,N'1',1000204,'2014-02-06 16:08:54.383'
   from _TCACompany AS A
  where not exists (select 1 from _TDAAccountRem where CompanySeq = A.CompanySeq and RemSeq = 2059)