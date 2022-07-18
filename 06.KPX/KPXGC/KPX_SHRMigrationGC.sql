
IF OBJECT_ID('KPX_SHRMigrationGC') IS NOT NULL 
    DROP PROC KPX_SHRMigrationGC
GO 

-- v2014.10.02 

-- AS400 데이터 Migration(인사마스타-그린케미칼) by이재천 

CREATE PROC KPX_SHRMigrationGC

    @CompanySeq INT 
    
AS 
    
    /*************************************************************************************
    |    테이블 backup                                                                  |
    |                                                                                    |
    |    select *                                                                        |
    |      into backup_20141015_TDAEmp                                                   |
    |      from _TDAEmp                                                                  |
    |                                                                                    |
    |    select *                                                                        |
    |      into backup_20141015_TDAEmpIn                                                 |
    |     from _TDAEmpIn                                                                 |
    |                                                                                    |
    |    select *                                                                        |
    |      into backup_20141015_THRBasAcademic                                           |
    |      from _THRBasAcademic                                                          |
    |                                                                                    |
    |    select *                                                                        |
    |      into backup_20141015_THRBasAddress                                            |
    |      from _THRBasAddress                                                           |
    |                                                                                    |
    |     select *                                                                       |
    |      into backup_20141015_TDAEmpDate                                               |
    |      from _TDAEmpDate                                                              |
    |                                                                                    |
    *************************************************************************************/
    
    delete from _TDAEmp where CompanySeq = @CompanySeq and UMEmptype <> 3059003 and empseq <> 1
    delete from _TDAEmpIn where CompanySeq = @CompanySeq
    delete from _THRBasAcademic where CompanySeq = @CompanySeq 
    delete from _THRBasAddress where CompanySeq= @CompanySeq
    delete from _TDAEmpDate where companyseq = @CompanySeq 
    
    if not exists (select 1 from syscolumns where id = object_id('KPX_THREmpInDataHD') and name = 'EmpSeq')
    begin
        ALTER TABLE KPX_THREmpInDataHD ADD EmpSeq INT NULL 
    end

    if not exists (select 1 from syscolumns where id = object_id('KPX_THREmpInDataHD') and name = 'NewEmpId')
    begin
        ALTER TABLE KPX_THREmpInDataHD ADD NewEmpId NVARCHAR(20) NULL 
    end
    
    update A
        set A.NewEmpID = B.NewEmpID 
      from KPX_THREmpInDataHD AS A 
      JOIN KPXDEV.dbo.KPX_THRNewEmpId AS B ON ( B.EmpId = A.EmpID AND B.Company = 'HD' ) 
    
    CREATE TABLE #TDAEmp 
    (
        IDX_NO          INT IDENTITY, 
        EmpName         NVARCHAR(100), 
        ResidID         NVARCHAR(200), 
        EmpFamilyName   NVARCHAR(100), 
        EmpFirstName    NVARCHAR(100), 
        EmpChnName      NVARCHAR(100), 
        EmpEngFirstName NVARCHAR(100), 
        EmpEngLastName  NVARCHAR(100), 
        UMEmpType       INT, 
        Empid           NVARCHAR(20), 
        DeptSeq         INT, 
        WkDeptSeq       INT, 
        NewEmpID        NVARCHAR(20)
    ) 

    CREATE TABLE #TDAEmpIn 
    (
        EmpID           NVARCHAR(200), 
        UMEmpType       INT, 
        EntDate         NCHAR(8), 
        RetireDate      NCHAR(8), 
        IsDisabled      NCHAR(1), 
        IsForeigner     NCHAR(1), 
        SMBirthType     INT, 
        BirthDate       NCHAR(8), 
        UMNationSeq     INT, 
        SMSexSeq        INT, 
        IsMarriage      NCHAR(1), 
        MarriageDate    NCHAR(8), 
        UMReligionSeq   INT, 
        Hobby           NVARCHAR(200), 
        Speciality      NVARCHAR(200), 
        Phone           NVARCHAR(20),  
        Cellphone       NVARCHAR(20),  
        Extension       NVARCHAR(20),  
        Email           NVARCHAR(50),   
        Remark          NVARCHAR(600),   
        UMEmployType    INT, 
        WishTask1       NVARCHAR(200), 
        WishTask2       NVARCHAR(200), 
        Recommender     NVARCHAR(200), 
        RcmmndrCom      NVARCHAR(200), 
        RcmmndrRank     NVARCHAR(200), 
        PrevEmpSeq      INT, 
        Height          DECIMAL(19,5), 
        Weight          DECIMAL(19,5), 
        SMBloodType     INT, 
        UMHandiType     INT,  
        UMHandiGrd      INT, 
        HandiAppdate    NCHAR(8), 
        IsVeteranEmp    NCHAR(1), 
        VeteranNo       NVARCHAR(50), 
        UMRelSeq        INT, 
        IsJobEmp        NCHAR(1), 
        EyeLt           DECIMAL(19,5), 
        EyeRt           DECIMAL(19,5), 
        People          INT, 
        UMHouseSort     INT, 
        NewEmpID        NVARCHAR(20)
    ) 

    INSERT INTO #TDAEmp(EmpName, ResidID, EmpFamilyName, EmpFirstName, EmpChnName, EmpEngFirstName, EmpEngLastName, UMEmpType, Empid, DeptSeq, WkDeptSeq, NewEmpID)
    SELECT REPLACE(EmpName,'　','') AS EmpName, 
           dbo._FCOMEncrypt(ResidID,'_TDAEmp','ResidID',@CompanySeq) AS ResidID, 
           ----dbo._FCOMEncrypt(ResidID, `_TDAEmp`, `ResidID`, 1)  AS ResidID, 
           ISNULL(LEFT(EmpName,1),'') AS EmpFamilyName, 
           case when @CompanySeq in( 3,4 ) then SUBSTRING(EmpName,2,10) else ISNULL(Replace(RIGHT(EmpName,charindex('　',EmpName)),'　',''),'') end AS EmpFirstName, 
           ISNULL(REPLACE(EmpChnName,'　',''),'') AS EmpChnName, 
           ISNULL(LEFT(EmpEngName,charindex(' ',EmpEngName)),'') AS EmpEngFirstName, 
           ISNULL(REPLACE(EmpEngName, ISNULL(LEFT(EmpEngName,charindex(' ',EmpEngName)),''), ''),'') AS EmpEngLastName, 
           3059001, 
           ISNULL(EmpID,'') AS EmpID, 
           0, 
           0, 
           ISNULL(NewEmpID,'') AS NewEmpID
      FROM KPX_THREmpInDataHD 
     order by EmpID 

    INSERT INTO #TDAEmpIn 
    (
        EmpID       ,     UMEmpType   ,     EntDate      ,     RetireDate  ,     IsDisabled  ,
        IsForeigner ,     SMBirthType ,     BirthDate    ,     UMNationSeq ,     SMSexSeq    ,
        IsMarriage  ,     MarriageDate,     UMReligionSeq,     Hobby       ,     Speciality  ,
        Phone       ,     Cellphone   ,     Extension    ,     Email       ,     Remark      ,
        UMEmployType,     WishTask1   ,     WishTask2    ,     Recommender ,     RcmmndrCom  ,
        RcmmndrRank ,     PrevEmpSeq  ,     Height       ,     Weight      ,     SMBloodType ,
        UMHandiType ,     UMHandiGrd  ,     HandiAppdate ,     IsVeteranEmp,     VeteranNo   ,
        UMRelSeq    ,     IsJobEmp    ,     EyeLt        ,     EyeRt       ,     People      ,
        UMHouseSort ,     NewEmpID        
    )
    SELECT EmpId, 3059001, replace(replace(EntDate,'-',''),'/',''),
           case when @CompanySeq = 3 then '99991231' 
                else case when IsRetire = 'Y' THEN replace(RetireDate,'/','') ELSE '99991231' END
                end AS RetireDate, '0', 
           '0', 
           CASE WHEN SMBirthType = 1 THEN 1009001 WHEN SMBirthType = 2 THEN 1009002 ELSE 0 END, 
           replace(BirthDate,'-',''), 0, 
           
           (case when substring(replace(ResidID,'-',''),7,1) IN( 1,5 ) then 1010001 when substring(replace(ResidID,'-',''),7,1) IN ( 2,6 ) then 1010002 else 0 end), 
            
           
           CASE WHEN IsMarriage = 'Y' THEN '1' ELSE '0' END, 
           '', CASE WHEN UMReligionSeq = 1 THEN 3060001 WHEN UMReligionSeq = 2 THEN 3060002 WHEN UMReligionSeq = 3 THEN 3060004 ELSE 3060012 END, 
           '','', 
           
           ISNULL(Phone1,'') + '-' + convert(nvarchar(10),Phone2) + '-' + ISNULL(Phone3,''), '', '', CASE WHEN @CompanySeq = 4 THEN Email ELSE null end , '', 
           
           0, '', '', Recommender, '', 
           
           '', null, 0, 0, 0, 
           
           0, 0, '', 0, '', 
           
           0, 0, 0, 0, 0, 
           
           0, NewEmpID
    
      FROM KPX_THREmpInDataHD AS A 
     Order by A.EmpID 
    
    ---- 테이블의 MAX값 
    --DECLARE @MaxEmpSeq INT 
    --SELECT @MaxEmpSeq =  MaxSeq 
    --  FROM _TCOMCreateSeqMax			
    -- WHERE Tablename = '_TDAEmp'			
    
    INSERT INTO _TDAEmp 
    (
        CompanySeq, EmpSeq, ResidID, EmpName, EmpFamilyName, 
        EmpFirstName, EmpChnName, EmpEngFirstName, EmpEngLastName, UMEmpType, 
        Empid, DeptSeq, WkDeptSeq, LastUserSeq, LastDateTime 
    ) 
    SELECT @CompanySeq, 700 + IDX_NO, ResidID, EmpName, EmpFamilyName, 
            EmpFirstName, EmpChnName, EmpEngFirstName, EmpEngLastName, UMEmpType,
            NewEmpID, DeptSeq, WkDeptSeq, 1, GETDATE()
      FROM #TDAEmp 
    
    INSERT INTO _TDAEmpIn 
    (
        CompanySeq, EmpSeq, EmpID, UMEmpType, EntDate, 
        RetireDate, IsDisabled, IsForeigner, SMBirthType, BirthDate, 
        UMNationSeq, SMSexSeq, IsMarriage, MarriageDate, UMReligionSeq, 
        Hobby, Speciality, Phone, Cellphone, Extension, 
        Email, Remark, UMEmployType, WishTask1, WishTask2, 
        Recommender, RcmmndrCom, RcmmndrRank, PrevEmpSeq, 
        LastUserSeq, LastDateTime, Height, Weight ,SMBloodType, 
        UMHandiType, UMHandiGrd ,HandiAppdate ,IsVeteranEmp ,VeteranNo ,
        UMRelSeq, IsJobEmp, EyeLt ,EyeRt ,People, UMHouseSort
    ) 
    SELECT @CompanySeq, B.EmpSeq, A.NewEmpID, A.UMEmpType, A.EntDate, 
           A.RetireDate, A.IsDisabled, A.IsForeigner, A.SMBirthType, A.BirthDate, 
           A.UMNationSeq, A.SMSexSeq, A.IsMarriage, A.MarriageDate, A.UMReligionSeq, 
           A.Hobby, A.Speciality, A.Phone, A.Cellphone, A.Extension, 
           A.Email, A.Remark, A.UMEmployType, A.WishTask1, A.WishTask2, 
           A.Recommender, A.RcmmndrCom, A.RcmmndrRank, A.PrevEmpSeq, 
           1, GETDATE(), A.Height, A.Weight ,A.SMBloodType, 
           A.UMHandiType, A.UMHandiGrd ,A.HandiAppdate ,A.IsVeteranEmp ,A.VeteranNo ,
           A.UMRelSeq, A.IsJobEmp, A.EyeLt ,A.EyeRt ,A.People, A.UMHouseSort
      FROM #TDAEmpIn AS A 
      JOIN  (SELECT 700 + IDX_NO AS EmpSeq, * 
               FROM #TDAEmp 
            ) AS B ON ( B.EmpID = A.EmpID) 
    
    /********************************************************************************
    |                                                                               |
    |   select * From _TDAEmp where empseq = 1000141                                |
    |   select * From _TDAEmpIn where empseq = 1000141                              |
    |   select * From _TDAUminor where companyseq =1 and majorseq= 3060             |
    |   select * From _TDAUminor where companyseq =1 and MinorSeq= 3061001          |
    |                                                                               |
    |   기독교 -- 1 - 3060001                                                      |
    |   불교 -- 2  - 3060002                                                       |
    |   천주교 -- 3 - 3060004                                                      |
    |                                                                               |
    ********************************************************************************/

    
    if @CompanySeq NOT IN ( 3, 4 ) 
    begin 
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 학력 
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 테이블의 MAX값 
    DECLARE @MaxAcademicSeq INT 
    SELECT @MaxAcademicSeq = ISNULL(MAX(AcademicSeq),0) FROM _THRBasAcademic WHERE companyseq = @CompanySeq  
    
    INSERT INTO _THRBasAcademic 
    (
        CompanySeq, EmpSeq, AcademicSeq, UMSchCareerSeq, EtcSchNm, 
        UMSchSeq, UMMajorDepart, UMMinorDepart, SMDayNightType, EntYm, 
        GrdYm, DegreeNo, ThesisNm, Loc, IsLastSchCareer, 
        IsAppSchCareer, DispSeq, LastUserSeq, LastDateTime, UMMajorCourse, 
        UMMinorCourse, MajorCourse, MinorCourse, UMDegreeType, UMUniversityType
    )
    SELECT @CompanySeq , 700 + B.IDX_NO AS EmpSeq, 
           @MaxAcademicSeq + B.IDX_NO AS AcademicSeq, 
           CASE WHEN A.UMSchCareerSeq = 10 THEN 3063028 
                WHEN A.UMSchCareerSeq = 20 THEN 3063008 
                WHEN A.UMSchCareerSeq = 30 THEN 3063012 
                WHEN A.UMSchCareerSeq = 40 THEN 3063017 
                WHEN A.UMSchCareerSeq = 50 THEN 3063020 
                WHEN A.UMSchCareerSeq = 60 THEN 3063023 
                ELSE 0 END, 
           '', 
           
           0, 0, 0, 0, '', 
           
           '', '', '', '', '0', 
           
           '0', 0, 1, getdate(), 0, 
           0, '', '', 0, 0
      FROM KPX_THREmpInDataHD AS A
      JOIN #TDAEmp     AS B ON ( B.EmpID = A.EmpID ) 
    
    /********************************************************************************
    |   select * from _THRBasAcademic where empseq = 1000141                        |
    |   select * From _TDAUminor where companyseq =1 and majorseq= 3063             |
    |   select * From _TDAUminor where companyseq =1 and MinorSeq= 3061001          |
    |   대학원 -- 10 - 3063028                                                     |
    |   대학교 -- 20 - 3063008                                                     |
    |   전문대 -- 30 - 3063012                                                     |
    |   고등학교 -- 40 - 3063017                                                   |
        중학교 -- 50 -3063020
        초등학교 -- 60 - 3063023
    ********************************************************************************/
    end 
    
    --select * from KPX_THREmpInDataHD where (addr1 is null and addr2 is not null ) or (addr1 is not null and addr2 is null)
    --return 

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 주소관리  
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    CREATE TABLE #THRBasAddress
    (
        EmpSeq          INT, 
        EmpID           NVARCHAR(100), 
        SMAddressType   INT, 
        AddrZip         NVARCHAR(200), 
        Addr            NVARCHAR(500), 
        BegDate         NCHAR(8)
    )
    IF @CompanySeq IN ( 3, 4 ) 
    BEGIN
        INSERT INTO #THRBasAddress ( EmpSeq, EmpID, SMAddressType, AddrZip, Addr, BegDate ) 
        SELECT 700 + B.IDX_NO AS EmpSeq, A.EmpID, 3055003 AS SMAddressType, ISNULL(AddrZip1,''), ISNULL(Addr1,''), replace(replace(EntDate,'-',''),'/','') -- 실거주지 
          FROM KPX_THREmpInDataHD AS A 
          JOIN #TDAEmp     AS B ON ( B.EmpID = A.EmpID ) 
         where addr1 is not null
         ORDER BY EmpSeq, SMAddressType 
    END 
    ELSE 
    BEGIN 
        INSERT INTO #THRBasAddress ( EmpSeq, EmpID, SMAddressType, AddrZip, Addr, BegDate ) 
        SELECT 700 + B.IDX_NO AS EmpSeq , A.EmpID, 3055001 AS SMAddressType, ISNUll(AddrZip2,''), ISNULL(Addr2,''), replace(EntDate,'-','')  -- 본적 
          FROM KPX_THREmpInDataHD AS A 
          JOIN #TDAEmp     AS B ON ( B.EmpID = A.EmpID ) 
         where addr2 is not null
          UNION ALL 
        SELECT 700 + B.IDX_NO AS EmpSeq, A.EmpID, 3055003 AS SMAddressType, ISNULL(AddrZip1,''), ISNULL(Addr1,''), replace(EntDate,'-','') -- 실거주지 
          FROM KPX_THREmpInDataHD AS A 
          JOIN #TDAEmp     AS B ON ( B.EmpID = A.EmpID ) 
         where addr1 is not null
        ORDER BY EmpSeq, SMAddressType 
    END 
    
    
    INSERT INTO _THRBasAddress 
    (
        CompanySeq, EmpSeq, AddressSeq, SMAddressType, BegDate, 
        EndDate, AddrZip, Addr1, Addr2, LastUserSeq, 
        LastDateTime, AddrEng1, AddrEng2
    ) 
    SELECT @CompanySeq, EmpSeq, ROW_NUMBER() OVER(partition by empseq Order by EmpSeq), SMAddressType, BegDate, 
           '', STUFF(AddrZip,4,0,'-') AS AddrZip, Addr, '', 1, 
           GETDATE(), '', '' 
      FROM #THRBasAddress 
    
    /********************************************************************************
    |   select AddrZip1, Addr1, AddrZip2, Addr2 from KPX_THREmpInDataHD                 |
    |   select * from _THRBasAddress where empseq = 1000141                         |
    |   select * From _TDASminor where companyseq =1 and majorseq= 3055             |
    |   select * From _TDASminor where companyseq =1 and MinorSeq= 3055001          |
    ********************************************************************************/
    
    UPDATE A 
       SET EmpSeq = B.EmpSeq 
      FROM KPX_THREmpInDataHD AS A 
      JOIN _TDAEmp     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpId = A.EmpId ) 
    
    
    create table #TDAEmpDate
    (
        name            nvarchar(100), 
        empid           nvarchar(20), 
        SmDateType      int, 
        EmpDate         NCHAR(8), 
        lastuserseq     int, 
        lastdatetime    datetime
    )
    
    insert into #TDAEmpDate
    select '그룹입사일' as name, A.NewEmpid AS EmpID, 3054001 AS SmDateType, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate()
      from KPX_THREmpInDataHD AS A 
    union all 
    select '입사일' as name, A.NewEmpid, 3054002, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '수습만료일' as name, A.NewEmpid, 3054003, '', 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '퇴사일' as name, A.NewEmpid, 3054004, case when @CompanySeq = 3 then '99991231' else case when IsRetire = 'Y' then replace(RetireDate,'/','') else '99991231' end end, 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '퇴직금기산일' as name, A.NewEmpid, 3054005, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '연차기산일' as name, A.NewEmpid, 3054007, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '월차기산일' as name, A.NewEmpid, 3054008, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '근속기산일' as name, A.NewEmpid, 3054009, replace(replace(A.EntDate,'-',''),'/',''), 1, getdate() 
      from KPX_THREmpInDataHD AS A 
    union all 
    select '현부서근무일' as name, A.NewEmpid, 3054014, B.OrdDate, 1, getdate() 
      from KPX_THREmpInDataHD AS A 
      left outer join (select EmpId, max(OrdDate) as orddate From KPX_THRAdmOrdData GROUP By empid) AS B ON ( B.Empid = A.Empid ) 
    union all 
    select '현부서포지션근무일' as name, A.NewEmpid, 3054015, B.OrdDate, 1, getdate() 
      from KPX_THREmpInDataHD AS A 
      left outer join (select EmpId, max(OrdDate) as orddate From KPX_THRAdmOrdData GROUP By empid) AS B ON ( B.Empid = A.Empid ) 
     order by EmpID, SmDateType
    
    --select * from #TDAEmpDate 
    --return 
    --select * from _TDAEmpDate where CompanySeq = 2 
    INSERT INTO _TDAEmpDate ( CompanySeq, EmpSeq, SMDateType, EmpDate, LastUserSeq, LastDateTime )
    
    select @CompanySeq, B.EmpSeq, A.SmDateType, A.EmpDate, A.lastuserseq, A.lastdatetime
      From #TDAEmpDate AS A 
      JOIN _TDAEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.Empid = A.empid ) 
    
    --select * From KPX_THREmpInDataHD where empid = '214031'
    --select * from KPX_THRAdmOrdData where EmpID = '2014031'
    
return 
go 
begin tran 
exec KPX_SHRMigrationGC @CompanySeq = 4
    --select * from _TDAEmp where CompanySeq = 4
    --select * from _TDAEmpIn where CompanySeq = 4
    --select * from _THRBasAcademic where CompanySeq = 4
    --select * from _THRBasAddress where CompanySeq= 4
    --select * from _TDAEmpDate where CompanySeq = 4

rollback 
 