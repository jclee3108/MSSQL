
if object_id('KPX_SCAUserMigrationGC') is not null 
    drop proc KPX_SCAUserMigrationGC
go 

-- v2014.09.22 

-- AS400 데이터 Migration(내부사용자 -그린케미칼) by이재천 
create proc KPX_SCAUserMigrationGC
    
    @companyseq int 
as 

    create table #temp ( userid nvarchar(20), empid nvarchar(20) )
    
    insert into #temp (userid, empid)
    select 'test1', '187016'
    union all 
    select 'test2', '191046'
    union all 
    select 'test3', '191047'
    union all 
    select 'test4', '191035'
    
    --select * from _TCAUser where companyseq = 1 and userid = 'test_id'
    
    declare @maxseq int 
    select @maxseq = max(userseq) from _TCAUser where companyseq = 1 and userseq < 1000001
    
    --insert into _TCAUser 
    --(
    --    CompanySeq,     UserSeq,            UserId,         UserType,       UserName, 
    --    EmpSeq,         LoginPwd,           Password1 ,     Password2 ,     Password3, 
    --    CustSeq,        DeptSeq,            UserSecu,       LoginStatus,    LoginDate, 
    --    PwdChgDate,     PassHis,            PwdMailAdder,   LoginFailCnt,   PwdType, 
    --    LoginType,      ManagementType,     LastUserSeq,    LastDateTime,   Dsn ,
    --    Remark,         LoginFailFirstTime, IsLayoutAdmin , UserlimitDate,  IsGroupWareUser ,
    --    SMUserType,     LicenseType
    --)
    select @CompanySeq, 
           row_number() over(order by A.empid) + @maxseq, 
           A.UserId, B.EmpName, C.NewEmpID, 
           
           '1111', '', '', '', 0
           
           (select DeptSeq from _THRAdmOrdEmp where companyseq = @CompanySeq and empseq = D.EmpSeq and islast = '1' ), 
           0, 18001, '', '', 
           
           '', '', 0, 0, 0, 
           
           0, 1, getdate(), '', '', 
           
           null, 0, '', 0, 1, 1112001
    
      from #temp AS A 
      JOIN (SELECT DISTINCT EmpID, EmpName FROM KPX_THRAdmOrdData) AS B ON ( B.EmpID = A.EmpID ) 
      JOIN KPX_THRNewEmpId AS C ON ( C.EmpID = B.EmpID ) 
      JOIN _TDAEmp AS D ON ( D.EmpID = C.NewEmpID ) 
go 
begin tran 

exec KPX_SCAUserMigrationGC @companyseq = 1 

rollback 
      
    