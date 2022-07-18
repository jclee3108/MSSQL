
if object_id('KPX_SACSlipMigrationGC') is not null 
    drop proc KPX_SACSlipMigrationGC
go 

-- v2014.10.02 

-- AS400 데이터 Migration(전표-그린케미칼) by이재천 
create proc KPX_SACSlipMigrationGC

    @CompanySeq INT 
    
as 
    --select * into backup_20141008_TACSlip From _TACSlip --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipRow From _TACSlipRow --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipCost From _TACSlipCost --where CompanySeq = @CompanySeq 
    --select * into backup_20141008_TACSlipRem From _TACSlipRem --where CompanySeq = @CompanySeq  
    
    --select * From _TACSlip where CompanySeq = 1 and left(AccDate,4) = '2014'
    
    --select * from KPX_TACSlipHeader2014 
    
    /* 2014년도 전표 백업 및 삭제 
    
    select * into backup_20150123_TACSlip From _TACSlip where CompanySeq = 1 and left(AccDate,4) = '2014'
    select * into backup_20150123_TACSlipRow From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014'
    select * into backup_20150123_TACSlipCost From _TACSlipCost where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    select * into backup_20150123_TACSlipRem From _TACSlipRem where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    
    delete From _TACSlip where CompanySeq = 1 and left(AccDate,4) = '2014'
    delete From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014'
    delete From _TACSlipCost where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    delete From _TACSlipRem where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    
    */ 
    
    
    --delete From _TACSlip where CompanySeq = @CompanySeq 
    --delete From _TACSlipRow where CompanySeq = @CompanySeq 
    --delete From _TACSlipCost where CompanySeq = @CompanySeq 
    --delete From _TACSlipRem where CompanySeq = @CompanySeq 
    
    /* 9월 이상 데이터 
    select * into backup_20141129_TACSlip From _TACSlip where companyseq = 1  and AccDate >= '20140901'
    select * into backup_20141129_TACSlipRow From _TACSlipRow where companyseq = 1 and AccDate >= '20140901'
    select * into backup_20141129_TACSlipCost From _TACSlipCost where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901')
    select * into backup_20141129_TACSlipRem From _TACSlipRem where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901') 
    
    
    select * into backup_20141204_TACSlip From _TACSlip where companyseq = 1  and AccDate >= '20140901'
    select * into backup_20141204_TACSlipRow From _TACSlipRow where companyseq = 1 and AccDate >= '20140901'
    select * into backup_20141204_TACSlipCost From _TACSlipCost where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901')
    select * into backup_20141204_TACSlipRem From _TACSlipRem where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901') 
    */ 
    
    /* 
    select * into backup_20141224_TACSlip From _TACSlip where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    select * into backup_20141224_TACSlipRow From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831'
    select * into backup_20141224_TACSlipCost From _TACSlipCost where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' ) 
    select * into backup_20141224_TACSlipCostRem From _TACSlipRem where CompanySeq = 1 and SlipSeq in ( select slipseq From _TACSlipRow where CompanySeq = 1 and AccDate between '20140701' and '20140831' ) 
    
    
    */
    --delete From _TACSlip where companyseq = 1  and AccDate >= '20140901'
    --delete From _TACSlipRow where companyseq = 1 and AccDate >= '20140901'
    --delete From _TACSlipCost where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901')
    --delete From _TACSlipRem where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901') 
    
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
    
    
    if not exists (select 1 from syscolumns where id = object_id('KPX_TACSlipDetail2014') and name = 'NewAccSeq')
    begin
        ALTER TABLE KPX_TACSlipDetail2014 ADD NewAccSeq INT NULL 
    end
    
    if not exists (select 1 from syscolumns where id = object_id('KPX_TACSlipDetail2014') and name = 'UMCostType')
    begin
        ALTER TABLE KPX_TACSlipDetail2014 ADD UMCostType INT NULL 
    end
    
    --select * from _TDAUMinor where CompanySeq = 1 and MajorSeq = 4001
    
    
    declare @MaxSlipMstSeq  Int, 
            @MaxSlipSeq     INT
    
    
    select @MaxSlipMstSeq = (SELECT MAX(SlipMstSeq) FROM _TACSlip WHERE CompanySeq = @CompanySeq) 
    select @MaxSlipSeq = (SELECT MAX(SlipSeq) FROM _TACSlipRow where CompanySeq = @CompanySeq)
    
    --select @MaxSlipMstSeq , @MaxSlipSeq
    
    --return
    
    
    -- 비용구분, 신규계정코드
    update A
       set NewAccSeq = C.AccSeq, 
           UMCostType = CASE WHEN B.UMCostType = 4 then 4001002 
                             when B.UMCostType = 7 then 4001001 
                             else 0 
                             end 
      from KPX_TACSlipDetail2014 AS A 
      JOIN KPX_TACAccount AS B ON ( B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAAccount    AS C ON ( C.CompanySeq = @CompanySeq AND convert(int,C.AccNo) = CONVERT(int,B.NewAccSeq) ) 
    
    
    --select * From KPX_TACSlipDetail2014 where NewAccSeq is null 
    
    --return 
    SELECT @CompanySeq AS CompanySeq, 
           @MaxSlipMstSeq + row_number() over (order by AccDate, SlipNo, AccUnit ) as SlipMStSeq, 
           --row_number() over (partition by AccDate order by AccDate, SlipNo, AccUnit ) as IDX_NO, 
           'A0-S1-' + convert(nchar(8),AccDate) + '-' + RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SlipMstID,
           CASE WHEN AccUnit = 30000 THEN 1 
                WHEN AccUnit = 40000 THEN 2 
                END AS NewAccUnit, 
           1 AS SlipUnit, 
           A.AccDate, 
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SlipNo, 
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
           RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SetSlipNo, 
           0 AS SetEmpSeq, 
           0 AS SetDeptSeq, 
           1 AS LastUserSeq, 
           GETDATE() AS LastDateTime, 
           convert(datetime,AccDate) AS RegDateTime, 
           AccDate AS RegAccDate, 
           'A0-' + convert(nchar(8),AccDate) + '-' + RIGHT('000' + convert(nvarchar(100),row_number() over (partition by A.AccDate order by AccDate, SlipNo, AccUnit )),4) AS SetSlipID , 
           
           A.AccUnit AS AccUnitSub, 
           A.AccDate AS AccDateSub, 
           A.SlipNo AS SlipNoSub 
      INTO #TACSlip 
      FROM KPX_TACSlipHeader2014 AS A 
      LEFT OUTER JOIN KPX_THREmpInData AS B ON ( B.EmpId = A.RegEmpId ) 
      LEFT OUTER JOIN _TDAEmp          AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpID = B.NewEmpID ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, convert(nchar(8),GETDATE(),112)) AS D ON ( D.EmpSeq = C.EmpSeq ) 
     ORDER BY A.AccDate, A.SlipNo, A.AccUnit 
    
    
    --select A.RegEmpId, B.EmpID, B.NewEmpId 
    --  from KPX_TACSlipHeader2014 AS A 
    --        LEFT OUTER JOIN KPX_THREmpInData AS B ON ( B.EmpId = A.RegEmpId ) 
    --  LEFT OUTER JOIN _TDAEmp          AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpID = B.NewEmpID ) 
    -- where C.EmpSeq is null 
    
    --insert into KPX_THREmpInData (EmpID , NewEmpId ) 
    --select '214033', '20140110'
    
    ----select * from KPX_THREmpInData where EmpID = '201433'
    
    ----select * From #TACSlip where regempseq is null 
    
    --return 
    select @CompanySeq AS CompanySeq, 
           @MaxSlipSeq + row_number() over (order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl ) as SlipSeq, 
           A.SlipMstSeq, 
           A.SlipMstID + '-' + RIGHT('00' + convert(nvarchar(20),row_number() over (order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl )),3) AS SlipID, 
           A.NewAccUnit, 
           A.SlipUnit, 
           A.AccDate, 
           A.SlipNo, 
           RIGHT('00' + convert(nvarchar(20),row_number() over (order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl )),3) AS RowNo, 
           A.SlipUnit AS RowSlipUnit, 
           B.NewAccSeq AS AccSeq, 
           ISNULL(B.UMCostType,0) AS UMCostType, 
           case when ISNULL(B.DrAmt,0) = 0 then -1 else 1 end as SMDrOrCr, 
           ISNULL(B.DrAmt,0) AS DrAmt, 
           ISNULL(B.CrAmt,0) AS CrAmt, 
           ISNULL(B.DrAmt,0) AS DrForAmt, 
           ISNULL(B.CrAmt,0) AS CrForAmt, 
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
           B.RemNaem2, 
           B.RemSeq3, 
           B.RemName3,
           B.RemSeq4, 
           B.RemName4, 
           
           B.AccDate AS AccDateSub, 
           B.SlipNo AS SlipNoSub, 
           B.AccUnit AS AccUnitSub, 
           B.SlipSerl AS SlipSerlSub, 
           A.RegEmpSeq
      INTO #TACSlipRow 
      from #TACSlip AS A
      LEFT OUTER JOIN KPX_TACSlipDetail2014 AS B ON ( B.AccDate = A.AccDateSub AND B.SlipNo = A.SlipNoSub AND B.AccUnit = A.AccUnitSub ) 
     Order by B.AccDate, B.SlipNo, B.AccUnit, B.SlipSerl
    
    --select * from #TACSlip where slipnosub = 1 
    
    --select * from KPX_TACSlipDetail2014 
    --select * From #TACSlipRow 
    
    
--select A.AccDateSub, AB.SlipNoSub, .NewAccSeq
-- from #TACSlip AS A
--      LEFT OUTER JOIN KPX_TACSlipDetail2014 AS B ON ( B.AccDate = A.AccDateSub AND B.SlipNo = A.SlipNoSub AND B.AccUnit = A.AccUnitSub )  
--    return 
    

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
    select SlipSeq, RemSeq2 AS RemSeq, RemNaem2 AS RemName 
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
           A.CrAmt AS CrForAmt
      into #TACSlipCost
      from #TACSlipRow AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, convert(nchar(8),GETDATE(),112)) AS B ON ( B.EmpSeq = A.RegEmpSeq ) 
    
    
    select @CompanySeq AS CompanySeq, A.SlipSeq, 1017 AS RemSeq, C.CustSeq AS RemValSeq, '' AS RemValText
      into #TACSlipRem
      from #TEMP_REM AS A 
      LEFT OUTER JOIN _TDACust    AS C ON ( C.CompanySeq = @CompanySeq AND C.CustNo = A.RemName ) 
     where C.CustSeq is not null 
    


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
    
    ----select 1, '_TACSlip', A.AccDate, '' AS FirstInfo, '' AS SecondInfo, '' AS ThirdInfo, MAX(SlipNo) AS SlipNo, 'SlipMstID' AS NoColumnName --B.YMDInfo , MAX(SlipNo) AS SlipNo, B.MaxSerl
    ----  from #TACSlip AS A 
    ----  LEFT OUTER JOIN _TCOMCreateNoMaxAC AS B ON ( B.CompanySeq = 1 and B.YMDInfo = A.AccDate and B.TableName = '_TACSlip' AND B. ) 
    ---- --where 
    ----   where B.TableName IS NULL
    ----group by A.AccDate,  B.YMDInfo, B.MaxSerl, B.FirstInfo 
    
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
      where accseq is not null 

--return         
    INSERT INTO _TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText)
    select DISTINCT CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText
      from #TACSlipRem 
    
    
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
    
return 
go 
begin tran 
exec KPX_SACSlipMigrationGC @CompanySeq = 1

    --select * From _TACSlip where CompanySeq = 1
    --select * From _TACSlipRow where CompanySeq = 1
    --select * From _TACSlipCost where CompanySeq = 1
    --select * From _TACSlipRem where CompanySeq = 1 
    
    --select *  From _TACSlip where CompanySeq = 1 and left(AccDate,4) = '2014'
    --select * From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014'
    --select * From _TACSlipCost where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    --select * From _TACSlipRem where CompanySeq = 1 and SlipSeq in (select slipseq From _TACSlipRow where CompanySeq = 1 and left(AccDate,4) = '2014')
    
    
    --select *  From _TACSlip where companyseq = 1  and AccDate >= '20140901'
    --select *  From _TACSlipRow where companyseq = 1 and AccDate >= '20140901'
    --select *  From _TACSlipCost where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901')
    --select *  From _TACSlipRem where companyseq = 1 and slipseq in ( select slipseq From _TACSlipRow where companyseq = 1 and AccDate >= '20140901') 
    
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