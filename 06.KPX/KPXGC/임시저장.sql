       
        select C.OrdDate, A.RetireDate,   CONVERT(NCHAR(8),GETDATE(),112) as getdate1, A.RetireDate , *
        FROM _TDAEmpIn AS A            
        JOIN _TDAEmp       AS B ON (A.CompanySeq = B.CompanySeq
                                      AND  A.EmpSeq     = B.EmpSeq)
     LEFT OUTER JOIN _THRAdmOrdEmp AS C ON A.CompanySeq = C.CompanySeq
                                      AND  A.EmpSeq     = C.EmpSeq
                                      AND C.OrdDate    <= CASE WHEN ISNULL(A.RetireDate,'') > CONVERT(NCHAR(8),GETDATE(),112) THEN CONVERT(NCHAR(8),GETDATE(),112) ELSE A.RetireDate END
                                      AND C.OrdEndDate >= CASE WHEN ISNULL(A.RetireDate,'') > CONVERT(NCHAR(8),GETDATE(),112) THEN CONVERT(NCHAR(8),GETDATE(),112) ELSE A.RetireDate END
                                      AND C.IsOrdDateLast = '1'
     --LEFT OUTER JOIN _THRAdmWkOrdEmp AS D ON (A.CompanySeq   = D.CompanySeq
     --                                  AND  A.EmpSeq       = D.EmpSeq 
     --                                  AND  D.OrdDate     <= CASE WHEN ISNULL(A.RetireDate,'') >= CONVERT(NCHAR(8),GETDATE(),112) THEN CONVERT(NCHAR(8),GETDATE(),112) ELSE A.RetireDate END
     --                                  AND  D.OrdEndDate  >= CASE WHEN ISNULL(A.RetireDate,'') >= CONVERT(NCHAR(8),GETDATE(),112) THEN CONVERT(NCHAR(8),GETDATE(),112) ELSE A.RetireDate END
     --                                  AND  D.SMSourceType = 3052002)    -- 근무발령만
     --LEFT OUTER JOIN _THROrgJob      AS E WITH(NOLOCK) ON (C.CompanySeq = E.CompanySeq
     --       AND  C.JobSeq     = E.JobSeq)
        WHERE A.CompanySeq = 1 
          and A.EmpSeq = 121
  
    select * from _THRAdmOrdEmp where CompanySeq = 1 and EmpSeq = 121 --and OrdDate <= 
    
    select * from _THRAdmWkOrdEmp where CompanySeq = 1 and EmpSeq = 121
    
    
    
    
    
    
    select * from _THRAdmWkOrdEmp where CompanySeq <> 1 
    
select * from _THRAdmOrdEmp where companyseq =1 and EmpSeq = 102 and IntSeq = 9 and OrdSeq = 21  
  
update _THRAdmWkOrdEmp
   set wkintseq = 8 
from _THRAdmWkOrdEmp where CompanySeq = 1 and EmpSeq = 102 and WkIntSeq = 9 

  select * from KPX_THRAdmOrdData where EmpName like '배%양'
  
  select * from _TDAEmp where CompanySeq =1 and EmpName = '김영언'
  
  select * from _THRAdmOrdEmp where CompanySeq = 1 and EmpSeq = 121
  select * from _THRAdmWkOrdEmp where CompanySeq = 1 and EmpSeq = 121
  
  
  
  select * from backup_20140924_THRAdmOrdEmp where companyseq = 1 
  
  
  select * from _TDAEmp where CompanySeq = 1 and EmpSeq = 134
  select * from _TDAEmp where CompanySeq = 1 and EmpSeq = 134
  
    select A.EmpSeq, A.OrdDate 
      from _THRAdmOrdEmp AS A 
      JOIN (select EmpSeq, OrdDate, COUNT(1) AS Cnt from _THRAdmOrdEmp where CompanySeq = 1 group by empseq, OrdDate having COUNT(1) > 1) AS B ON ( b.EmpSeq = A.EmpSeq AND B.OrdDate = A.OrdDate) 
     where A.EmpSeq = 121 
    group by A.EmpSeq, A.OrdDate 
    
    select * from _THRAdmOrdEmp where CompanySeq = 1 
  
    select A.EmpSeq, A.OrdDate, MAX(IntSeq) AS IntSeq
      from _THRAdmOrdEmp AS A 
      JOIN (select EmpSeq, OrdDate, COUNT(1) AS Cnt from _THRAdmOrdEmp where CompanySeq = 1 group by empseq, OrdDate having COUNT(1) > 1) AS B ON ( b.EmpSeq = A.EmpSeq AND B.OrdDate = A.OrdDate)
    group by A.EmpSeq, A.OrdDate  
    
    
    --update _THRAdmOrdEmp 
    --   set IsOrdDateLast = '1'
    
    begin tran 
    update Z
       set IsOrdDateLast = '0'
      from _THRAdmOrdEmp AS Z 
      JOIN (select EmpSeq, OrdDate, COUNT(1) AS Cnt from _THRAdmOrdEmp where CompanySeq = 1 group by empseq, OrdDate having COUNT(1) > 1) AS B ON ( b.EmpSeq = Z.EmpSeq AND B.OrdDate = Z.OrdDate)
     where IntSeq NOT IN ( select MAX(IntSeq) AS IntSeq
                          from _THRAdmOrdEmp AS A 
                          JOIN (select EmpSeq, OrdDate, COUNT(1) AS Cnt from _THRAdmOrdEmp where CompanySeq = 1 group by empseq, OrdDate having COUNT(1) > 1) AS B ON ( b.EmpSeq = A.EmpSeq AND B.OrdDate = A.OrdDate)
                         where A.EmpSeq = Z.EmpSeq
                             and A.OrdDate = Z.ordDate 
                        group by A.EmpSeq, A.OrdDate )
       and Z.CompanySeq = 1 
       
    select * from _THRAdmOrdEmp where CompanySeq = 1 and empseq = 121
                        
rollback 
    
    
    
    select *from _THRAdmOrdEmp where CompanySeq = 1 and EmpSeq = 121



select * from _THRAdmOrdEmp where CompanySeq =1 and EmpSeq = 101



select * from _TDADept where CompanySeq = 1 and DeptSeq = 41000



--delete A 
select * 
  from _THRAdmWkOrdEmp AS A 
  JOIN (select A.EmpSeq, A.OrdDate, MIN(WkIntSeq) as MinWkIntSeq
          from _THRAdmWkOrdEmp as A 
          JOIN (select EmpSeq, OrdDate, COUNT(1) as cnt from _THRAdmWkOrdEmp where CompanySeq = 1 group by EmpSeq, OrdDate having COUNT(1) > 1 ) AS B ON ( B.EmpSeq = A.EmpSeq AND B.OrdDate = A.OrdDate ) 
          group by A.EmpSeq, A.OrdDate        
       )  AS B ON ( B.EmpSeq = A.EmpSeq AND B.OrdDate = A.OrdDate AND B.MinWkIntSeq <> A.WkIntSeq ) 
    order by A.EmpSeq 
    
    
    select * From _THRAdmWkOrdEmp where CompanySeq = 1 and EmpSeq = 102 