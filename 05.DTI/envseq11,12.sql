if not exists (select 1 from DTI_TCOMEnv where envseq = 11)
begin
Insert Into DTI_TCOMEnv(CompanySeq,EnvSeq,EnvSerl,EnvName,Description,EnvValue,ModuleSeq,SMControlType,CodeHelpSeq,MinorSeq,SMUseType,QuerySort,LastUserSeq,LastDateTime,DecLength,AddCheckScript,AddSaveScript) 
select 1,11,1,N'H/W',N'H/W 해당 프로젝트 예상과목',N'0',0,84003,70009,0,0,11,1,getdate(),0,N'',N''
end

if not exists (select 1 from DTI_TCOMEnv where envseq = 12)
begin
Insert Into DTI_TCOMEnv(CompanySeq,EnvSeq,EnvSerl,EnvName,Description,EnvValue,ModuleSeq,SMControlType,CodeHelpSeq,MinorSeq,SMUseType,QuerySort,LastUserSeq,LastDateTime,DecLength,AddCheckScript,AddSaveScript) 
select 1,12,1,N'S/W',N'S/W 해당 프로젝트 예상과목',N'0',0,84003,70009,0,0,12,1,getdate(),0,N'',N''
end
