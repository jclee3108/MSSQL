
if object_id('KPX_SPDToolTechScript') is not null 
    drop proc KPX_SPDToolTechScript
go
 
-- v2014.10.28 

-- 설비제원스크립트 by이재천

create proc KPX_SPDToolTechScript
    
    @CompanySeq INT 

as 
    
    create table #temp 
    (
        MinorName NVARCHAR(500), 
        Name      NVARCHAR(500), 
        Serl      INT 
    )
    
    insert into #temp (MinorName, Name, Serl) 
    select MinorName, Name1, 1 AS Serl 
      from KPX_TPDToolData 
     where Name1 is not null 
    
    union all 
    
    select MinorName, Name2, 2
      from KPX_TPDToolData 
     where Name2 is not null 
     
    union all 
    
    select MinorName, Name3, 3 
      from KPX_TPDToolData 
     where Name3 is not null 
    
    union all 
    
    select MinorName, Name4, 4
      from KPX_TPDToolData 
     where Name4 is not null 
    
    union all 
      
    select MinorName, Name5, 5 
      from KPX_TPDToolData 
     where Name5 is not null 
    
    union all 
      
    select MinorName, Name6, 6 
      from KPX_TPDToolData 
     where Name6 is not null 
    
    union all 
    
    select MinorName, Name7, 7 
      from KPX_TPDToolData 
     where Name7 is not null 
    
    union all 
    
      
    select MinorName, Name8, 8 
      from KPX_TPDToolData 
     where Name8 is not null 
    
    union all 
    
    select MinorName, Name9, 9 
      from KPX_TPDToolData 
     where Name9 is not null 
    
    union all 
    
    select MinorName, Name10, 10
      from KPX_TPDToolData 
     where Name10 is not null 
    
    union all 
    
    select MinorName, Name11, 11
      from KPX_TPDToolData 
     where Name11 is not null 
    
    union all 
    
    select MinorName, Name12, 12 
      from KPX_TPDToolData 
     where Name12 is not null 
    
    union all 
    
    select MinorName, Name13, 13 
      from KPX_TPDToolData 
     where Name13 is not null 
    
    union all 
    
    select MinorName, Name14, 14 
      from KPX_TPDToolData 
     where Name14 is not null 

    Order by MinorName, Serl 
    
    
    select ROW_NUMBER() over(partition by MinorName order by MinorName, Serl) as Number, * 
      into #temp_sub
      from #temp 
    
    
    insert into _TCOMUserDefine 
    (
        CompanySeq,     TableName,          DefineUnitSeq,          TitleSerl,          Title,         
        IsEss,          CodeHelpConst,      CodeHelpParams,         SMInputType,        MaskAndCaption,         
        QrySort,        IsFix,              DataFieldID,            IsCodeHelpTitle,    LastUserSeq,         
        LastDateTime,   DecLen
    )
    select @CompanySeq AS CompanySeq, 
           '_TDAUMajor_6009' AS TableName, 
           B.MinorSeq AS DefineUnitSeq, 
           A.Number AS TitleSerl, 
           A.Name AS Title, 
           
           '0' AS IsEss, 
           0 AS CodeHelpConst, 
           '' AS CodeHelpParams, 
           0 AS SMInputType, 
           '' AS MaskAndCaption, 
           
           A.Number AS QrySort, 
           '0' AS IsFix, 
           '' AS DataFieldID, 
           '0' AS IsCodeHelpTitle, 
           1 AS LastUserSeq, 
           
           GETDATE() as lastdatetime, 
           NULL DecLen 
           
      from #temp_sub as a
      join _TDAUMinor as b on ( B.CompanySeq = @CompanySeq AND b.MinorName = a.MinorName and B.MajorSeq = 6009 ) 
    

    

return 
go
begin tran 
exec KPX_SPDToolTechScript @COmpanySeq = 1 


--select * from _TCOMUserDefine where companyseq = 1 and tablename = '_TDAUMajor_6009' --and defineunitseq not in ( 6009003 , 6009004 ) 
rollback 