-- 업무, 운영

if not exists (select 1 from _TCACodeHelpData where CodeHelpSeq = 140028)
begin 
    Insert Into _TCACodeHelpData(CompanySeq,CodeHelpSeq,CodeHelpTitle,CodeHelpSpName,TblKey,CodeHelpType,SortBy,IsGroupSheet,SortKeyCol,SerlCol,DefQueryOption,IsCombo,PageCount,Param1,Param2,Param3,Param4,LastUserSeq,LastDateTime,FixCombo,TableName,SeqColumnName,NameColumnName,RefColumnName,DBType,QuickHelpSpName,QuickHelpSeq,SecuClass,CodeHelpAssistSPName,IsMulti,IsMultiAssist,PagingType,CustSeq,SubConditionCount,IsSPSubCondition,IsUseLocal,WordSeq,CodeHelpComboSpName,QuickOption,UseLoginInfo,DevMode) 
    select 0,140028,N'락탐트랜드조회용시료위치',N'_SCACodeHelpLactamSampleLocCHE',0,1,N'0',N'0',1,1,1,N'0',50,N'',N'',N'',N'',1000204,'2014-07-21 17:28:39.570',N'0',N'_TPDSampleLoc',N'SampleLocSeq',N'SampleLoc',N'',158002,N'',0,N'',N'',N'0',N'0',210001,133,0,N'0',N'1',0,N'',0,N'0',0
end 
if not exists (select 1 from _TCACodeHelpTitle where CodeHelpSeq = 140028 and TitleSeq = 1)
begin 
    Insert Into _TCACodeHelpTitle(CompanySeq,CodeHelpSeq,TitleSeq,TitleName,FieldName,TitleWidth,IsVisible,DataType,MaskFormat,DecMaxLength,FieldType,LastUserSeq,LastDateTime,WordSeq) 
    select 0,140028,1,N'내부코드',N'SampleLocSeq',0,1,1,N'',0,1,1,'2014-05-29 17:24:21.570',1194
end 
if not exists (select 1 from _TCACodeHelpTitle where CodeHelpSeq = 140028 and TitleSeq = 2)
begin 
    Insert Into _TCACodeHelpTitle(CompanySeq,CodeHelpSeq,TitleSeq,TitleName,FieldName,TitleWidth,IsVisible,DataType,MaskFormat,DecMaxLength,FieldType,LastUserSeq,LastDateTime,WordSeq) 
    select 0,140028,2,N'시료위치',N'SampleLoc',0,1,0,N'',0,2,1,'2014-05-29 17:24:21.570',0
end 

