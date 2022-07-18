
drop proc test_jclee1

go
create proc test_jclee1 

as 



create table #temp 
(
FactUnitName nvarchar(300), 
ToolKindName nvarchar(300), 
ToolNo       nvarchar(300), 
ToolName     nvarchar(300), 
MngValText1   nvarchar(300), 
MngValText2   nvarchar(300), 
MngValText3   nvarchar(300), 
MngValText4   nvarchar(300), 
MngValText5   nvarchar(300),
MngValText6   nvarchar(300),
MngValText7   nvarchar(300),
MngValText8   nvarchar(300),
MngValText9   nvarchar(300),
MngValText10   nvarchar(300),
MngValText11   nvarchar(300),
MngValText12   nvarchar(300),
MngValText13   nvarchar(300),
MngValText14   nvarchar(300),
MngValText15   nvarchar(300),
MngValText16   nvarchar(300),
MngValText17   nvarchar(300),
MngValText18   nvarchar(300),
MngValText19   nvarchar(300),
MngValText20   nvarchar(300),
MngValText21   nvarchar(300),
MngValText22   nvarchar(300),
MngValText23   nvarchar(300),
MngValText24  nvarchar(300),
MngValText25   nvarchar(300),
MngValText26   nvarchar(300),
MngValText27   nvarchar(300),
MngValText28   nvarchar(300),
MngValText29   nvarchar(300),
MngValText30   nvarchar(300),
MngValText31   nvarchar(300),
MngValText32   nvarchar(300),
MngValText33   nvarchar(300),
MngValText34   nvarchar(300),
MngValText35   nvarchar(300)
) 



    
    
    insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText1) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 1 
    
    
    insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText2) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 2 
    
    insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText3) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 3 
       
insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText4) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 4 
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText5) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2
       and titleserl = 5 
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText6) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 6
       
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText7) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 7 
       
       
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText8) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 8
       
        

        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText9) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 9 
       
       
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText10) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 10
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText11) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 11
       
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText12) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 12
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText13) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 13
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText14) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 14
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText15) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 15
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText16) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 16 

        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText17) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 17 
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText18) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 18 
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText19) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 19
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText20) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 20 
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText21) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 21 
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText22) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 22
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText23) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 23
        
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText24) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 24 
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText25) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 25 
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText26) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 26
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText27) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 27 
       
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText28) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 28 
       
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText29) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 29 
       
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText30) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 30 
       
       insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText31) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 31
       
              insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText32) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 32 
       
       
        insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText33) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 33 
       
       
              insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText34) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 34
       
       
              insert into #temp (factunitName ,ToolKindName, ToolNo, ToolName, MngValText35) 
    select e.factunitName, f.minorname, a.toolno, a.toolname, c.MngValText
      from _TPDTool as a 
      left outer join _TCOMUserDefine as b on ( b.companyseq = a.companyseq and b.tablename = '_TDAUMajor_6009' and b.defineunitseq = a.UMToolkind ) 
      left outer join _TPDToolUserDefine as c on ( c.companyseq = b.companyseq and c.Mngserl = b.titleserl and c.toolseq = a.toolseq ) 
      --left outer join _TPDToolUserDefineCHE as d on ( d.companyseq = b.companyseq and d.Mngserl = b.TitleSerl and d.toolseq = a.toolseq ) 
      left outer join _TDAfactunit           as e on ( e.companyseq = a.companyseq and e.factunit = a.FactUnit ) 
      left outer join _TDAUMinor                as f on ( f.companyseq = a.companyseq and a.UMToolkind = f.minorseq ) 
     where a.companyseq = 2 
       and titleserl = 35
       
    
    

 
 
 select factunitName ,ToolKindName, ToolNo, ToolName, 
MAX(MngValText1 )MngValText1 , 
MAX(MngValText2 )MngValText2 , 
MAX(MngValText3 )MngValText3 , 
MAX(MngValText4 )MngValText4 , 
MAX(MngValText5 )MngValText5 , 
MAX(MngValText6 )MngValText6 , 
MAX(MngValText7 )MngValText7 , 
MAX(MngValText8 )MngValText8 , 
MAX(MngValText9 )MngValText9 , 
MAX(MngValText10)MngValText10, 
MAX(MngValText11)MngValText11, 
MAX(MngValText12)MngValText12, 
MAX(MngValText13)MngValText13, 
MAX(MngValText14)MngValText14, 
MAX(MngValText15)MngValText15, 
MAX(MngValText16)MngValText16, 
MAX(MngValText17)MngValText17, 
MAX(MngValText18)MngValText18, 
MAX(MngValText19)MngValText19, 
MAX(MngValText20)MngValText20, 
MAX(MngValText21)MngValText21, 
MAX(MngValText22)MngValText22, 
MAX(MngValText23)MngValText23, 
MAX(MngValText24)MngValText24, 
MAX(MngValText25)MngValText25, 
MAX(MngValText26)MngValText26, 
MAX(MngValText27)MngValText27, 
MAX(MngValText28)MngValText28, 
MAX(MngValText29)MngValText29, 
MAX(MngValText30)MngValText30, 
MAX(MngValText31)MngValText31, 
MAX(MngValText32)MngValText32, 
MAX(MngValText33)MngValText33, 
MAX(MngValText34)MngValText34, 
MAX(MngValText35)MngValText35 
   from #temp 
  group by factunitName ,ToolKindName, ToolNo, ToolName
 
 
 return 
 
 go 
 exec test_jclee1