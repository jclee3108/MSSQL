
if object_id('KPX_SACSlipMigrationCM') is not null 
    drop proc KPX_SACSlipMigrationCM
go 

-- v2014.10.02 

-- AS400 데이터 Migration(전표-케미칼) by이재천 
create proc KPX_SACSlipMigrationCM

    @CompanySeq INT 
    
as 
    
    --select * into backup_20141008_TACSlip From _TACSlip --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipRow From _TACSlipRow --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipCost From _TACSlipCost --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipRem From _TACSlipRem --where CompanySeq = @CompanySeq  
    
    --select * From _TACSlip where CompanySeq = 1 and left(AccDate,4) = '2014'
    
    --select * from KPX_TACSlipHeader2014 
    
    
    --select * into backup_20150526_TACSlip From _TACSlip where companyseq = 2 
    --select * into backup_20150526_TACSlipRow From _TACSlipRow where companyseq = 2  
    --select * into backup_20150526_TACSlipCost From _TACSlipCost where CompanySeq = 2 
    --select * into backup_20150526_TACSlipRem From _TACSlipRem where CompanySeq = 2  

    
    /* 2014년도 전표 백업 및 삭제 
    
    select * into backup_20150911_TACSlip From _TACSlip where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'
    select * into backup_20150911_TACSlipRow From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'
    select * into backup_20150911_TACSlipCost From _TACSlipCost where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')
    select * into backup_20150911_TACSlipRem From _TACSlipRem where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')
    
    delete From _TACSlipCost where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')
    delete From _TACSlipRem where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')
    delete From _TACSlip where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'
    delete From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'

    
    */ 
    
    
    --delete From _TACSlip where CompanySeq = @CompanySeq 
    --delete From _TACSlipRow where CompanySeq = @CompanySeq 
    --delete From _TACSlipCost where CompanySeq = @CompanySeq 
    --delete From _TACSlipRem where CompanySeq = @CompanySeq 
    
    /* 9월 이상 데이터 
    select * into backup_20150709_TACSlip From _TACSlip where companyseq = 2 and accdate between '20150101' and '20150531'
    select * into backup_20150709_TACSlipRow From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531'
    select * into backup_20150709_TACSlipCost From _TACSlipCost where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531')
    select * into backup_20150709_TACSlipRem From _TACSlipRem where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531') 
    

    
    select * into backup_20141204_TACSlip From _TACSlip where companyseq = 2  and AccDate >= '20140901'
    select * into backup_20141204_TACSlipRow From _TACSlipRow where companyseq = 2 and AccDate >= '20140901'
    select * into backup_20141204_TACSlipCost From _TACSlipCost where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and AccDate >= '20140901')
    select * into backup_20141204_TACSlipRem From _TACSlipRem where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and AccDate >= '20140901') 
    */ 
    
    /* 
    select * into backup_20141224_TACSlip From _TACSlip where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    select * into backup_20141224_TACSlipRow From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    select * into backup_20141224_TACSlipCost From _TACSlipCost where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' ) 
    select * into backup_20141224_TACSlipCostRem From _TACSlipRem where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' ) 
    
    
    */

    
    
   
    
    --update A 
    --   set A.SlipSerl = B.SlipSerl
    --B.slipserl , A.SlipSerl 
    
    --select * from KPX_test1 where accunit = 30000 and accdate = 20110119 and slipno = 201
        
    ----select B.slipserl, A.*
    
    --    update A 
    --   set A.SlipSerl = B.SlipSerl + 1 
    --  from KPX_test2 AS A 
    --  left outer join (select accunit, accdate, slipno, MAX(slipserl) as slipserl 
    --                     from KPX_test1 
    --                    group by accunit, accdate, slipno
    --                  ) as b on ( b.accunit = a.accunit and b.accdate = a.accdate and b.slipno = a.slipno ) 
    --select * 
    --  from KPX_test2
    
    --drop table KPX_TACSlipDetail2014 
    
    
    
    
--drop  table KPX_TACSlipDetailCM2
    
    
    create table #KPX_TACSlipDetailCM
    (
        IDX_NO          INT IDENTITY, 
        AccUnit         INT, 
        AccUnitName     NVARCHAR(100), 
        AccDate         NCHAR(8), 
        SlipNo          INT, 
        SlipSerl        INT, 
        SlipKindName    NVARCHAR(100), 
        BizUnit         INT, 
        BizUnitName     NVARCHAR(100), 
        InsertDate      NCHAR(8), 
        RegDateTime     NCHAR(8), 
        AccSeq          INT, 
        DrAmt           DECIMAL(19,5), 
        CrAmt           DECIMAL(19,5), 
        Summary         NVARCHAR(500), 
        CoCustSeq       NVARCHAR(100), 
        CostDeptSeq     INT, 
        RemSeq1         INT, 
        RemName1        NVARCHAR(100), 
        RemSeq2         INT, 
        RemName2        NVARCHAR(100), 
        RemSeq3         INT, 
        RemName3        NVARCHAR(100), 
        RemSeq4         INT, 
        RemName4        NVARCHAR(100)
    )
    
    insert into #KPX_TACSlipDetailCM 
    (
        AccUnit         ,AccUnitName     ,AccDate         ,SlipNo          ,SlipSerl        ,
        SlipKindName    ,BizUnit         ,BizUnitName     ,InsertDate      ,RegDateTime     ,
        AccSeq          ,DrAmt           ,CrAmt           ,Summary         ,CoCustSeq       ,
        CostDeptSeq     ,RemSeq1         ,RemName1        ,RemSeq2         ,RemName2        ,
        RemSeq3         ,RemName3        ,RemSeq4         ,RemName4        
    ) 
    select AccUnit         ,AccUnitName     ,AccDate         ,SlipNo          ,SlipSerl        ,
           SlipKindName    ,BizUnit         ,BizUnitName     ,InsertDate      ,RegDateTime     ,
           AccSeq          ,DrAmt           ,CrAmt           ,Summary         ,CoCustSeq       ,
           CostDeptSeq     ,RemSeq1         ,RemName1        ,RemSeq2         ,RemNaem2        ,
           RemSeq3         ,RemName3        ,RemSeq4         ,RemName4 
      from KPX_TACSlipDetailCM_20150708
    
    union all 
    
    select AccUnit         ,AccUnitName     ,AccDate         ,SlipNo          ,SlipSerl        ,
           SlipKindName    ,BizUnit         ,BizUnitName     ,InsertDate      ,RegDateTime     ,
           AccSeq          ,DrAmt           ,CrAmt           ,Summary         ,CoCustSeq       ,
           CostDeptSeq     ,RemSeq1         ,RemName1        ,RemSeq2         ,RemNaem2        ,
           null            ,null            ,null            ,null 
      from KPX_TACSlipDetailCM2_20150708
    
    union all 

    select AccUnit         ,AccUnitName     ,AccDate         ,SlipNo          ,SlipSerl        ,
           SlipKindName    ,BizUnit         ,BizUnitName     ,InsertDate      ,RegDateTime     ,
           AccSeq          ,DrAmt           ,CrAmt           ,Summary         ,CoCustSeq       ,
           CostDeptSeq     ,RemSeq1         ,RemName1        ,RemSeq2         ,RemNaem2        ,
           RemSeq3         ,RemName3        ,RemSeq4         ,RemName4   
      from KPX_TACSlipDetailCM3_20150708
    
    --ALTER TABLE KPX_TACSlipDetailCM3_20150708 ALTER COLUMN RemSeq3 NVARCHAR(500) NULL
    --ALTER TABLE KPX_TACSlipDetailCM3_20150708 ALTER COLUMN RemName3 NVARCHAR(500) NULL
    --ALTER TABLE KPX_TACSlipDetailCM3_20150708 ALTER COLUMN RemSeq4 NVARCHAR(500) NULL
    --ALTER TABLE KPX_TACSlipDetailCM3_20150708 ALTER COLUMN RemName4 NVARCHAR(500) NULL
    

    if not exists (select 1 from syscolumns where id = object_id('#KPX_TACSlipDetailCM') and name = 'NewAccSeq')
    begin
        ALTER TABLE #KPX_TACSlipDetailCM ADD NewAccSeq INT NULL 
    end
    
    if not exists (select 1 from syscolumns where id = object_id('#KPX_TACSlipDetailCM') and name = 'UMCostType')
    begin
        ALTER TABLE #KPX_TACSlipDetailCM ADD UMCostType INT NULL 
    end
    
    --select * from _TDAUMinor where CompanySeq = 1 and MajorSeq = 4001
    
    
    declare @MaxSlipMstSeq  Int, 
            @MaxSlipSeq     INT
    
    
    select @MaxSlipMstSeq = ISNULL((SELECT MAX(SlipMstSeq) FROM _TACSlip WHERE CompanySeq = @CompanySeq),0) + 100 
    select @MaxSlipSeq = ISNULL((SELECT MAX(SlipSeq) FROM _TACSlipRow where CompanySeq = @CompanySeq),0) + 100
    
    --select @MaxSlipMstSeq , @MaxSlipSeq
    
    --return
    
    
    -- 비용구분, 신규계정코드
    update A
       set NewAccSeq = C.AccSeq, 
           UMCostType = CASE WHEN B.UMCostType = 4 then 4001002 
                             when B.UMCostType = 7 then 4001001 
                             else 0 
                             end 
      from #KPX_TACSlipDetailCM AS A 
      JOIN KPX_TACAccountCM AS B ON ( B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAAccount    AS C ON ( C.CompanySeq = @CompanySeq AND convert(int,C.AccNo) = CONVERT(int,B.NewAccSeq) ) 
        

    
    --select * From KPX_TACAccountCM where Newaccseq = '7100079'
    
    --select * From #KPX_TACSlipDetailCM 
    
    
    --return 
    
    --drop table KPX_TACAccountCM
    --select * From KPX_TACSlipDetail2014 where NewAccSeq is null 
    
    --return 
    
    --select * from _TDAAccUnit where companyseq = 2 
    
    
    
    
    SELECT @CompanySeq AS CompanySeq, 
           @MaxSlipMstSeq + row_number() over (order by AccDate, SlipNo, AccUnit ) as SlipMStSeq, 
           --row_number() over (partition by AccDate order by AccDate, SlipNo, AccUnit ) as IDX_NO, 
           
           --'A0-S1-' + convert(nchar(8),AccDate) + '-' + RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate, SlipUnit, NewAccUnit order by AccDate, SlipNo, AccUnit )),4) AS SlipMstID,
           
            --'' AS SlipMstID, 
           CASE WHEN A.AccUnit = 10000 AND E.BizUnit = 70 THEN 5 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 10 THEN 1 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 10 THEN 1 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 10 AND LEFT(A.AccDate,4) IN ('2013','2014') THEN 2 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 90 THEN 1 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 90 THEN 1 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) >= '2013' THEN 2 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) >= '2013' THEN 2 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 3 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 3 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) >= '2013' THEN 3 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) >= '2013' THEN 3 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 40 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 40 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 40 AND LEFT(A.AccDate,6) BETWEEN '201301' AND '201401' THEN 2 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 40 AND LEFT(A.AccDate,6) BETWEEN '201301' AND '201401' THEN 2 
                WHEN A.AccUnit = 51000 AND E.BizUnit = 50 THEN 4
                WHEN A.AccUnit = 52000 AND E.BizUnit = 50 THEN 4 
                ELSE NULL 
                END AS NewAccUnit, 
                
           CASE WHEN A.AccUnit = 10000 AND E.BizUnit = 70 THEN 2 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 10 THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 10 THEN 1 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 10 AND LEFT(A.AccDate,4) IN ('2013','2014') THEN 2 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 90 THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 90 THEN 1 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 1 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) >= '2013' THEN 2 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 20 AND LEFT(A.AccDate,4) >= '2013' THEN 1 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 1 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) >= '2013' THEN 2 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 30 AND LEFT(A.AccDate,4) >= '2013' THEN 1 
                WHEN A.AccUnit = 10000 AND E.BizUnit = 40 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 2 
                WHEN A.AccUnit = 20000 AND E.BizUnit = 40 AND LEFT(A.AccDate,4) IN ('2011','2012') THEN 1 
                WHEN A.AccUnit = 41000 AND E.BizUnit = 40 AND LEFT(A.AccDate,6) BETWEEN '201301' AND '201401' THEN 2 
                WHEN A.AccUnit = 42000 AND E.BizUnit = 40 AND LEFT(A.AccDate,6) BETWEEN '201301' AND '201401' THEN 1 
                WHEN A.AccUnit = 51000 AND E.BizUnit = 50 THEN 2 
                WHEN A.AccUnit = 52000 AND E.BizUnit = 50 THEN 9 
                ELSE NULL 
                END AS SlipUnit, 
                
           A.AccDate, 
           --RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SlipNo, 
           --'' AS SlipNo, 
           10001 AS SlipKind, 
           C.EmpSeq AS RegEmpSeq, 
           D.DeptSeq AS RegDeptSeq, 
           '' AS Remark, 
           0 AS SMCurrStatus, 
           '' AS AptDate, 
           0 AS AptEmpSeq, 
           0 AS AptDeptSeq, 
           '' AS AptRemark, 
           0 AS SMCheckStatus, 
           0 AS CheckOrigin, 
           '1' AS IsSet, 
           --RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SetSlipNo, 
           --'' AS  SetSlipNo, 
           0 AS SetEmpSeq, 
           0 AS SetDeptSeq, 
           1 AS LastUserSeq, 
           GETDATE() AS LastDateTime, 
           convert(datetime,AccDate) AS RegDateTime, 
           AccDate AS RegAccDate, 
           --'A0-' + convert(nchar(8),AccDate) + '-' + RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SetSlipID , 
           --'' AS SetSlipID, 
           
           A.AccUnit AS AccUnitSub, 
           A.AccDate AS AccDateSub, 
           A.SlipNo AS SlipNoSub, 
           E.BizUnit , 
           
           B.EmpId 
      INTO #TACSlip_Sub 
      FROM KPX_TACSlipHeaderCM_20150708 AS A 
      LEFT OUTER JOIN KPX_NewEmpIdCM     AS B ON ( B.EmpId = A.RegEmpId ) 
      LEFT OUTER JOIN _TDAEmpIn          AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpID = B.NewEmpID ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, convert(nchar(8),GETDATE(),112)) AS D ON ( D.EmpSeq = C.EmpSeq ) 
      OUTER APPLY (SELECT Z.BizUnit
                     FROM #KPX_TACSlipDetailCM AS Z 
                    WHERE Z.AccUnit = A.AccUnit 
                      AND Z.SlipNo = A.SlipNo 
                      and Z.AccDate = A.AccDate 
                      --AND Z.BizUnit = A.BizUnit 
                     GROUP BY Z.BizUnit
                 ) AS E 
     ORDER BY A.AccDate, A.SlipNo, A.AccUnit 
    
    --select * From KPX_NewEmpIdCM where empid = '199009'
    --select * From _TDAEmpIN where empid = '19990010'
    --select * From _TDAEmp where empid = '19990010'
    
    --select * from _TDAEmpIN where empseq = 1095
    
    --select * from #TACSlip_Sub where AccDateSub ='20150114' and slipnosub = '51' and accunitsub = '42000'
    
    --return 
    --select * from KPX_NewEmpIdCM where empid = '214066'
    --select * from _TDAEmpIn where empid = '20140115' 
    --select * from #TACSlip_Sub where accdate = '20150325'
    
    --return 
    
    --update A 
    --   set SlipNo = RIGHT('000' + convert(nvarchar(100),row_number() over (partition by AccDate order by AccDate, SlipNo, NewAccUnit )),4)
    --  from #TACSlip AS A 
    
    
    --select A.accdate , A.NewAccUnit , A.SlipUnit , MAX(b.MaxSerl) as MaxSerl1, MAX(c.MaxSerl) as MaxSerl2 --, MAX(c.maxno) as maxno2
    --  from #TACSlip_Sub as a 
      
    --  join _TCOMCreateNoMaxAC as b on ( b.CompanySeq = @CompanySeq 
    --                                and b.TableName = '_TACSlip' 
    --                                and b.YMDInfo = a.accdate 
    --                                and b.FirstInfo =  (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = a.NewAccUnit) 
    --                                and b.NoColumnName = 'slipmstid' 
    --                                and b.SecondInfo = (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033008 and unit = a.SlipUnit )
    --                                  ) 
    --  join _TCOMCreateNoMaxAC as c on ( c.CompanySeq = @CompanySeq 
    --                                and c.TableName = '_TACSlip' 
    --                                and c.YMDInfo = a.accdate 
    --                                and c.FirstInfo =  (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = a.NewAccUnit) 
    --                                and c.NoColumnName = 'SetSlipID' 
    --                                --and c.SecondInfo = (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033008 and unit = a.SlipUnit )
    --                                  ) 
    -- where left(accdate,6) = '201508'
    --group by A.accdate , A.NewAccUnit , A.SlipUnit 
      
    --select * From _TCOMCreateNoMaxAC where companyseq = 2 and TableName = '_TACSlip'
    
    --return 
    
    SELECT (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = A.NewAccUnit) + '-' +
           (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033008 and unit = A.SlipUnit ) + '-' + A.AccDate + '-' + 
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate, A.SlipUnit, A.NewAccUnit order by A.AccDate, A.SlipUnit, A.NewAccUnit) + isnull(b.maxserl1,0)),4) AS SlipMstID, 
           
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate, A.SlipUnit, A.NewAccUnit order by A.AccDate, A.SlipUnit, A.NewAccUnit)),4) AS SlipNo, 
           
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate, A.SlipUnit, A.NewAccUnit order by A.AccDate, A.SlipUnit, A.NewAccUnit)),4) AS SetSlipNo, 
           
           (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = A.NewAccUnit) + '-' + 
           convert(nchar(8),A.AccDate) + '-' + 
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate, A.SlipUnit, A.NewAccUnit order by A.AccDate, A.SlipUnit, A.NewAccUnit)+isnull(b.maxserl2,0)),4) AS SetSlipID ,
           a.* 
      INTO #TACSlip  
      FROM #TACSlip_Sub as a 
      left outer join ( 
                        select z.accdate , z.NewAccUnit , z.SlipUnit , MAX(convert(int,y.MaxSerl)) as MaxSerl1, MAX(convert(int,q.MaxSerl)) as MaxSerl2 --, MAX(c.maxno) as maxno2
                          from #TACSlip_Sub as z 
                          
                          join _TCOMCreateNoMaxAC as y on ( y.CompanySeq = @CompanySeq 
                                                        and y.TableName = '_TACSlip' 
                                                        and y.YMDInfo = z.accdate 
                                                        and y.FirstInfo =  (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = z.NewAccUnit) 
                                                        and y.NoColumnName = 'slipmstid' 
                                                        and y.SecondInfo = (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033008 and unit = z.SlipUnit )
                                                          ) 
                          join _TCOMCreateNoMaxAC as q on ( q.CompanySeq = @CompanySeq 
                                                        and q.TableName = '_TACSlip' 
                                                        and q.YMDInfo = z.accdate 
                                                        and q.FirstInfo =  (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033001 and unit = z.NewAccUnit) 
                                                        and q.NoColumnName = 'SetSlipID' 
                                                        --and c.SecondInfo = (select Initial from _TCOMUnitInitial where companyseq = @CompanySeq and sminitialunit = 1033008 and unit = a.SlipUnit )
                                                          ) 
                         where left(accdate,6) = '201508'
                        group by z.accdate , z.NewAccUnit , z.SlipUnit 
                    ) as b on ( b.accdate = a.accdate and b.NewAccUnit = a.NewAccUnit and b.SlipUnit = a.SlipUnit ) 
      

    --select * from #TACSlip 
    
    --return 
    --select * from #KPX_TACSlipDetailCM
    --return 
    --select * from _TDAEmp where companyseq = 2 
    
    --select A.RegEmpId, B.EmpID, B.NewEmpId 
    --  from KPX_TACSlipHeader2014 AS A 
    --        LEFT OUTER JOIN KPX_THREmpInData AS B ON ( B.EmpId = A.RegEmpId ) 
    --  LEFT OUTER JOIN _TDAEmp          AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpID = B.NewEmpID ) 
    -- where C.EmpSeq is null 
    
    --insert into KPX_THREmpInData (EmpID , NewEmpId ) 
    --select '214033', '20140110'
    
    ----select * from KPX_THREmpInData where EmpID = '201433'
    
    ----select * From #TACSlip where regempseq is null 
    
    --select * from #TACSlip where isnull(newaccunit,0) = 0  
    --return 
    --return 
    --select * from #KPX_TACSlipDetailCM where accdate = '20150109' and slipno = '101' and accunit = 20000 
    
    select IDX_NO, AccUnit, AccDate, SlipNo, BizUnit, row_number() over( partition by AccUnit, AccDate, SlipNo, BizUnit order by AccUnit, AccDate, SlipNo, BizUnit ) as SlipSerl 
      into #NewSlipSerl 
      from #KPX_TACSlipDetailCM 
	
    
    update A 
        set SlipSerl = B.SlipSerl 
      FROM #KPX_TACSlipDetailCM AS A 
      JOIN #NewSlipSerl         AS B on ( b.IDX_NO = a.IDX_NO ) 
	--return 

--select * from #KPX_TACSlipDetailCM

--return 
    
    --select *
    --  from #TACSlip AS A
    --  LEFT OUTER JOIN #KPX_TACSlipDetailCM AS B ON ( B.AccDate = A.AccDateSub AND B.SlipNo = A.SlipNoSub AND B.AccUnit = A.AccUnitSub AND B.BizUnit = A.BizUnit ) 
      
    --return 
        --return 
        
        --select * from KPX_TACSlipDetailCM_20150708 where accdate ='20150109' and slipno = '101' and accunit = 20000
        --select * from KPX_TACSlipDetailCM3_20150708 where accdate ='20150109' and slipno = '101' and accunit = 20000
    
    --select count(1) , AccUnit, AccDate, SlipNo, SlipSerl 
    --  from #KPX_TACSlipDetailCM 
    -- group by AccUnit, AccDate, SlipNo, SlipSerl
    -- having count(1) > 1 
    
    --return 
	
    select @CompanySeq AS CompanySeq, 
           @MaxSlipSeq + row_number() over (order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl ) as SlipSeq, 
           A.SlipMstSeq, 

           A.SlipMstID + '-' + RIGHT('00' + convert(nvarchar(20),B.SlipSerl),3) AS SlipID, 
           A.NewAccUnit, 
           A.SlipUnit, 
           A.AccDate, 
           A.SlipNo, 
           RIGHT('00' + convert(nvarchar(20),B.SlipSerl),3) AS RowNo, 
           A.SlipUnit AS RowSlipUnit, 
           B.NewAccSeq AS AccSeq, 
           ISNULL(B.UMCostType,0) AS UMCostType, 
           case when ISNULL(B.DrAmt,0) = 0 then -1 else 1 end as SMDrOrCr, 
           ISNULL(B.DrAmt,0) AS DrAmt, 
           ISNULL(B.CrAmt,0) AS CrAmt, 
           0 AS DrForAmt, 
           0 AS CrForAmt, 
           0 AS CurrSeq, 
           0 AS ExRate, 
           0 AS DivExRate, 
           0 AS EvidSeq, 
           null AS TaxKindSeq, 
           null AS NDVATAmt, 
           0 AS cashitemSeq, 
           0 AS SMCostItemKind, 
           0 AS CostItemSeq, 
           ISNULL(B.Summary,'') AS Summary, 
           0 AS BgtDeptSeq, 
           0 AS BgtCCtrSeq, 
           0 AS BgtSeq, 
           '1' AS IsSet, 
           0 AS CoCustSeq, 
           GETDATE() AS LastDateTime, 
           1 AS LastUserSeq, 
           
           B.RemSeq1, 
           B.RemName1, 
           B.RemSeq2, 
           B.RemName2, 
           B.RemSeq3, 
           B.RemName3,
           B.RemSeq4, 
           B.RemName4, 
           
           B.AccDate AS AccDateSub, 
           B.SlipNo AS SlipNoSub, 
           B.AccUnit AS AccUnitSub, 
           B.SlipSerl AS SlipSerlSub, 
           A.RegEmpSeq, 
           B.CostDeptSeq
      INTO #TACSlipRow 
      from #TACSlip AS A
      LEFT OUTER JOIN #KPX_TACSlipDetailCM AS B ON ( B.AccDate = A.AccDateSub AND B.SlipNo = A.SlipNoSub AND B.AccUnit = A.AccUnitSub AND B.BizUnit = A.BizUnit ) 
     Order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl
    
    
    --select * from #KPX_TACSlipDetailCM where costdeptseq = '21120'
    --return 
    --select * from #TACSlipRow where 
    
    --return 
    --select * from #TACSlip where slipnosub = 1 
    
    --select * from KPX_TACSlipDetail2014 
    --select * From #TACSlipRow 
    --return 
    
--select A.AccDateSub, AB.SlipNoSub, .NewAccSeq
-- from #TACSlip AS A
--      LEFT OUTER JOIN KPX_TACSlipDetail2014 AS B ON ( B.AccDate = A.AccDateSub AND B.SlipNo = A.SlipNoSub AND B.AccUnit = A.AccUnitSub )  
--    return 
    --select * from #TACSlipRow 
    --return 




    create table #TEMP_REM 
    (
        SlipSeq     INT, 
        RemSeq      NVARCHAR(2), 
        RemName     NVARCHAR(100) 
    )
    
    insert into #TEMP_REM ( SlipSeq, RemSeq, RemName ) 
    select SlipSeq, RemSeq1 AS RemSeq, RemName1 AS RemName 
      from #TACSlipRow 
     where RemSeq1 = '01'
    union all 
    select SlipSeq, RemSeq2 AS RemSeq, RemName2 AS RemName 
      from #TACSlipRow 
     where RemSeq2 = '01'
    union all 
    select SlipSeq, RemSeq3 AS RemSeq, RemName3 AS RemName 
      from #TACSlipRow 
     where RemSeq3 = '01'
    union all 
    select SlipSeq, RemSeq4 AS RemSeq, RemName4 AS RemName 
      from #TACSlipRow 
     where RemSeq4 = '01'
     
     
    insert into #TEMP_REM ( SlipSeq, RemSeq, RemName ) 
    select SlipSeq, RemSeq1 AS RemSeq, RemName1 AS RemName 
      from #TACSlipRow 
     where RemSeq1 = '07'
    union all 
    select SlipSeq, RemSeq2 AS RemSeq, RemName2 AS RemName 
      from #TACSlipRow 
     where RemSeq2 = '07'
    union all 
    select SlipSeq, RemSeq3 AS RemSeq, RemName3 AS RemName 
      from #TACSlipRow 
     where RemSeq3 = '07'
    union all 
    select SlipSeq, RemSeq4 AS RemSeq, RemName4 AS RemName 
      from #TACSlipRow 
     where RemSeq4 = '07'
	
	
    delete from #TEMP_REM where RemName is null
    

    
    --return 
    --select * 
    --  from #TEMP_REM AS A 
    --  left outer JOIN _TDACust AS B ON ( B.CompanySeq = @CompanySeq AND B.CustNo = A.RemName ) 
      
    --  select * from _TDACust where custno = ''
    
    --return 
    --delete C
    --  from #TEMP_REM AS A 
    --  left outer JOIN _TDACust AS B ON ( B.CompanySeq = @CompanySeq AND B.CustNo = A.RemName ) 
    --  LEFT OUTER JOIN #TACSlipRow AS C ON ( C.SlipSeq = A.SlipSeq ) 
    -- where b.CustSeq is null 
    
    --delete A 
    --  from #TACSlip AS A 
    -- where not exists (select  SlipMstSeq from #TACSlipRow where SlipMstSeq = A.SlipMstSeq)

 
    
    select @CompanySeq AS CompanySeq, 
           A.SlipSeq AS SlipSeq,  
           1 AS Serl, 
           B.DeptSeq AS CostDeptSeq, 
           0 AS CostCCtrSeq, 
           0 AS DivRate, 
           A.DrAmt AS DrAmt, 
           A.CrAmt AS CrAmt, 
           A.DrAmt AS DrForAmt, 
           A.CrAmt AS CrForAmt, 
           A.CostDeptSeq As dept
      into #TACSlipCost
      from #TACSlipRow AS A 
      --LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, convert(nchar(8),GETDATE(),112)) AS B ON ( B.EmpSeq = A.RegEmpSeq ) 
      left outer join _TDADept AS B ON ( B.CompanySeq = @CompanySeq and B.Remark = A.CostDeptSeq ) 
    
    --select * From _TDAAccount where accseq = 357 
    --select * From #TACSlipRow
    
    --return 
    
    
    
    
    declare @Count int, 
            @Seq   int
    
    select @Count = count(1) 
      from ( 
            select distinct RemName 
              from #TEMP_REM AS Z 
             where RemSeq = 7  
               and not exists (select 1 from _TDABankAcc where companyseq = @companyseq and BankAccno = Z.RemName) 
           )  AS A 
    
    IF @Count > 0
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TDABankAcc', 'BankAccSeq', @Count
    END   
     

    
    --select @Count , @Seq 
    --return 
    
    
    INSERT INTO _TDABankAcc 
    (
        CompanySeq, BankAccSeq, BankAccNo, BankAccName, BizUnit, 
        SMBankAccKind, BankSeq, AccSeq, Owner, OwnerEngName, 
        OpenDate, ExpireDate, PayDate, MonthPayAmt, InterestRate, 
        limitAmt, DepositAmt, SuretyAmt, IsAccruedIncomeTrans, IsFoCurrTrans, 
        IsClose, IsFund, TaxUnit, Remark, SMFBSCycle, 
        LastUserSeq, LastDateTime, ClosingDate, IsSaleAcc, CMSCode
    )
    select @CompanySeq AS CompanySeq, @Seq + Row_Number() over (Order by A.RemName) AS BankAccSeq, A.RemName, A.RemName, 1, 
           4028001, 0, 5,  '', '', 
           '', '', 0, 0, 0, 
           0, 0, 0, '0', '0', 
           '0', '0', '0', '전표마이그레이션 관리항목 생성', 0, 
           1, getdate(), '', '0', ''
      from ( 
            select distinct RemName 
              from #TEMP_REM AS Z 
             where RemSeq = 7  
               and not exists (select 1 from _TDABankAcc where companyseq = @companyseq and BankAccno = Z.RemName) 
           )  AS A 
    
    
    
    
    --select DISTINCT A.RemName
    --  from #TEMP_REM AS A 
    --  LEFT OUTER JOIN _TDACust    AS C ON ( C.CompanySeq = @CompanySeq AND C.CustNo = A.RemName ) 
    -- where A.RemSeq = 1 
    --    and c.custseq is null 
      
    --  return 
    

    
    --select A.slipseq,  count(1) --@CompanySeq AS CompanySeq, A.SlipSeq, 1004 AS RemSeq, C.BankAccSeq AS RemValSeq, '' AS RemValText
    --  from #TEMP_REM AS A 
    --  LEFT OUTER JOIN _TDABankAcc AS C ON ( C.CompanySeq = @CompanySeq AND C.BankAccNo = A.RemName ) 
    -- where A.RemSeq = 7 
    -- group by slipseq 
    -- having count(1) > 1 
    
    
    --select * 
    --  from #TEMP_REM as z 
    --  where Z.slipseq in (     select A.slipseq
    --                          from #TEMP_REM AS A 
    --                          LEFT OUTER JOIN _TDABankAcc AS C ON ( C.CompanySeq = @CompanySeq AND C.BankAccNo = A.RemName ) 
    --                         where A.RemSeq = 7 
    --                         group by slipseq 
    --                     having count(1) > 1 )
    
    

    
    --return 
    
    
  
    create table #TACSlipRem 
    (
        CompanySeq  INT, 
        SlipSeq     INT, 
        RemSeq      INT, 
        RemValSeq   INT, 
        RemValText  NVARCHAR(100) 
    )
    insert into #TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) -- 거래처 
    select @CompanySeq AS CompanySeq, A.SlipSeq, 1017 AS RemSeq, C.CustSeq AS RemValSeq, '' AS RemValText
      from #TEMP_REM AS A 
      LEFT OUTER JOIN _TDACust    AS C ON ( C.CompanySeq = @CompanySeq AND C.CustNo = A.RemName ) 
     where A.RemSeq = 1 
    
    insert into #TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) -- 계좌번호 
    select @CompanySeq AS CompanySeq, A.SlipSeq, 1004 AS RemSeq, C.BankAccSeq AS RemValSeq, '' AS RemValText
      from #TEMP_REM AS A 
      LEFT OUTER JOIN _TDABankAcc AS C ON ( C.CompanySeq = @CompanySeq AND C.BankAccNo = A.RemName ) 
     where A.RemSeq = 7 
     
    insert into #TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) -- 금융기관 
    select @CompanySeq AS CompanySeq, A.SlipSeq, 1003 AS RemSeq, C.BankSeq AS RemValSeq, '' AS RemValText
      from #TEMP_REM AS A 
      LEFT OUTER JOIN _TDABankAcc AS C ON ( C.CompanySeq = @CompanySeq AND C.BankAccNo = A.RemName ) 
     where A.RemSeq = 7 
    
    --return 
--return 
    
    
    --select * from #TACSlipCost 
    
    --return 
    
    --select * from #TACSlipRem 
    --return 

    --return 
    --delete From _TACSlip where CompanySeq = @CompanySeq 
    --delete From _TACSlipRow where CompanySeq = @CompanySeq 
    --delete From _TACSlipCost where CompanySeq = @CompanySeq 
    --delete From _TACSlipRem where CompanySeq = @CompanySeq  
    
    --delete From _TACSlipRem where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' )     
    --delete From _TACSlipCost where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' ) 
    --delete From _TACSlip where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    --delete From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    
    --select * From #TACSlip 
    
    --select 2, '_TACSlip', A.AccDate, '' AS FirstInfo, '' AS SecondInfo, '' AS ThirdInfo, MAX(SlipNo) AS SlipNo, 'SlipMstID' AS NoColumnName --B.YMDInfo , MAX(SlipNo) AS SlipNo, B.MaxSerl
    --  from #TACSlip AS A 
    --  LEFT OUTER JOIN _TCOMCreateNoMaxAC AS B ON ( B.CompanySeq = 1 and B.YMDInfo = A.AccDate and B.TableName = '_TACSlip' AND B. ) 
    -- --where 
    --   where B.TableName IS NULL
    --group by A.AccDate,  B.YMDInfo, B.MaxSerl, B.FirstInfo 
    
    
    
    
    --select * from #TACSlip where isnull(regempseq,0) = 0 
    --select * from #TACSlipRow 
    --select * from #TACSlipCost
    --select * from #TACSlipRem 
    
    
    
    --insert into _TCOMCreateNoMaxAC 
    --select 2, '_TACSlip', AccDate, LEFT(SlipMstID,2), SUBSTRING(SlipMstID,4,2), '', MAX(RIGHT(SlipMstID,4)), MAX(SlipMstID), 'SlipMstID'
    --  from _TACSlip 
    -- group by AccDate, LEFT(SlipMstID,2), SUBSTRING(SlipMstID,4,2)
     
    --insert into _TCOMCreateNoMaxAC 
    --select 2, '_TACSlip', AccDate, LEFT(SetSlipID,2), '', '', MAX(RIGHT(SetSlipID,4)), MAX(SetSlipID), 'SetSlipID'
    --  from _TACSlip 
    -- group by AccDate, LEFT(SetSlipID,2), SUBSTRING(SetSlipID,4,2)
    
    
    --delete from _TCOMCreateSeqMax where companyseq = 2 AND TableName = '_TACSlipRow'
    
    
    --select * from _TCOMCreateNoMaxAC where tablename = '_TACSlip' and companyseq = 2 and nocolumnname = 'SetSlipID'
    
    
    
    --delete  From _TACSlipRem where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531') 
    --delete  From _TACSlipCost where companyseq = 2 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531')
    --delete  From _TACSlipRow where companyseq = 2 and accdate between '20150101' and '20150531'
    --delete  From _TACSlip where companyseq = 2 and accdate between '20150101' and '20150531'
    
    --select  * from #TACSlipRem  where remvalseq is null 
    
    --return 
    

    
    INSERT INTO _TACSlip 
    (
        CompanySeq,     SlipMstSeq,         SlipMstID,      AccUnit,        SlipUnit, 
        AccDate,        SlipNo,             SlipKind,       RegEmpSeq,      RegDeptSeq, 
        Remark,         SMCurrStatus,       AptDate,        AptEmpSeq,      AptDeptSeq, 
        AptRemark,      SMCheckStatus,      CheckOrigin,    IsSet,          SetSlipNo, 
        SetEmpSeq,      SetDeptSeq,         LastUserSeq,    LastDateTime,   RegDateTime, 
        RegAccDate,     SetSlipID
    )
    select CompanySeq,     SlipMstSeq,         SlipMstID,      NewAccUnit,     SlipUnit, 
           AccDate,        SlipNo,             SlipKind,       RegEmpSeq,      RegDeptSeq, 
           Remark,         SMCurrStatus,       AptDate,        AptEmpSeq,      AptDeptSeq, 
           AptRemark,      SMCheckStatus,      CheckOrigin,    IsSet,          SetSlipNo, 
           SetEmpSeq,      SetDeptSeq,         LastUserSeq,    LastDateTime,   RegDateTime, 
           RegAccDate,     SetSlipID
      from #TACSlip
--return 
    
    INSERT INTO _TACSlipRow 
    (
        CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit, 
        SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit, 
        AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt, 
        DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         DivExRate, 
        EvidSeq,        TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind, 
        CostItemSeq,    Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq, 
        IsSet,          CoCustSeq,      LastDateTime,   LastUserSeq    
    )
    select CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         NewAccUnit, 
           SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit, 
           AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt, 
           DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         DivExRate, 
           EvidSeq,        TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind, 
           CostItemSeq,    Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq, 
           IsSet,          CoCustSeq,      LastDateTime,   LastUserSeq    
      from #TACSlipRow 
      --where accseq is not null 


    INSERT INTO _TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText)
    select DISTINCT CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText
      from #TACSlipRem 
    
    --select * from _TACSlipRem where companyseq = 2 and slipseq = 551586 and remseq = 1004 
    --return 
    
    INSERT INTO _TACSlipCost
    (
        CompanySeq, SlipSeq,    Serl,   CostDeptSeq,    CostCCtrSeq, 
        DivRate,    DrAmt,      CrAmt,  DrForAmt,       CrForAmt
    )
    select CompanySeq, SlipSeq,    Serl,   CostDeptSeq,    CostCCtrSeq, 
           DivRate,    DrAmt,      CrAmt,  DrForAmt,       CrForAmt
      from #TACSlipCost
    
    --IF @@ERROR <> 0 
    --BEGIN 
    --    ROLLBACK 
    --    RETURN 
    --END 
    
    --COMMIT TRAN 
    
    --select * from #TACSlip
    --select top 1 * from _TACSlipRow 
    --select * from #TACSlipRow
    --select * from #TACSlipRem 
    --select * from #TACSlipCost 

	
    delete from _TCOMCreateSeqMax where companyseq = @CompanySeq AND TableName = '_TACSlip'
    delete from _TCOMCreateSeqMax where companyseq = @CompanySeq AND TableName = '_TACSlipRow'
    
    delete from _TCOMCreateNoMaxAC where tablename = '_TACSlip' and companyseq = @CompanySeq and nocolumnname = 'SlipMstID'
    insert into _TCOMCreateNoMaxAC 
    select 2, '_TACSlip', AccDate, LEFT(SlipMstID,2), SUBSTRING(SlipMstID,4,2), '', MAX(RIGHT(SlipMstID,4)), MAX(SlipMstID), 'SlipMstID'
      from _TACSlip 
     group by AccDate, LEFT(SlipMstID,2), SUBSTRING(SlipMstID,4,2)
    
    delete from _TCOMCreateNoMaxAC where tablename = '_TACSlip' and companyseq = @CompanySeq and nocolumnname = 'SetSlipID'
    insert into _TCOMCreateNoMaxAC 
    select 2, '_TACSlip', AccDate, LEFT(SetSlipID,2), '', '', MAX(RIGHT(SetSlipID,4)), MAX(SetSlipID), 'SetSlipID'
      from _TACSlip 
     group by AccDate, LEFT(SetSlipID,2), SUBSTRING(SetSlipID,4,2) 
    
    

update A
   set AccSeq = 315
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 202 
   and left(a.accdate,4) = '2015'
   and A.CrAmt <> 0 


update A
   set AccSeq = 317
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 210 
   and left(a.accdate,4) = '2015'
    

update A
   set AccSeq = 857
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 733 
   and left(a.accdate,4) = '2015'


update A
   set AccSeq = 687
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 685 
   and left(a.accdate,4) = '2015'


update A
   set AccSeq = 220
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 219 
   and left(a.accdate,4) = '2015'
   
update A
   set AccSeq = 879
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 511 
   and left(a.accdate,4) = '2015'


update A
   set AccSeq = 102
  from _TACSlipRow AS A 
 where A.CompanySeq = 2 
   and A.AccSeq = 103 
   and left(a.accdate,4) = '2015'
  


--select * From _TDAAccount where CompanySeq = 2 and AccName = '외화단기차입금'
--select * From _TDAAccount where CompanySeq = 2 and AccName = '외화수출차입금'


--update A 
--   set accseq = 349 
--from _TACSlipRow  AS A 
--where CompanySeq = 2 
--  and AccSeq = 13 

    
return 
go 
begin tran 
exec KPX_SACSlipMigrationCM @CompanySeq = 2
    
    select * From _TACSlip where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'
    select * From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507'
    select * From _TACSlipCost where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')
    select * From _TACSlipRem where CompanySeq = 2 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 2 and left(AccDate,6) between '201501' and '201507')

rollback 


--begin tran 
--update _TACSlipRow
--  set UMCostType = 0 
----select * 
--  From _TACSlipRow 
-- where CompanySeq = 1 
--   and AccDate between '20140701' and '20140831' 
--   and AccSeq in ( 195 , 199, 857 ) 
 

--rollback 



--select * From KPX_TACAccountCM where NewAccSeq = '2110104'

--select * From KPX_TACAccountCM where NewAccSeq = '2110102'

--select * from _TDAAccount where AccNo = '2110102'


--select * from _TACSlipRow where accseq = 103 and left(AccDate,4) = '2015'


--103 -> 102
