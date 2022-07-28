
IF OBJECT_ID('_SCACodeHelpSafeEmpCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpSafeEmpCHE
GO 

/************************************************************  
 설  명 - 코드도움SP : 안전교육대상자  
 작성일 - 20110810  
 작성자 - 천경민  
************************************************************/  
 CREATE PROCEDURE _SCACodeHelpSafeEmpCHE  
     @WorkingTag     NVARCHAR(1),                                
     @LanguageSeq    INT,                                
     @CodeHelpSeq    INT,                                
     @DefQueryOption INT,     -- 2: direct search                                
     @CodeHelpType   TINYINT,                                
     @PageCount      INT = 20,                     
     @CompanySeq     INT = 1,                               
     @Keyword        NVARCHAR(50) = '',                                
     @Param1         NVARCHAR(50) = '',                    
     @Param2         NVARCHAR(50) = '',                    
     @Param3         NVARCHAR(50) = '',                    
     @Param4         NVARCHAR(50) = '',  
     @PageSize       INT = 50                
 AS  
    --SET ROWCOUNT @PageCount  
  
    SELECT M.EmpSeq        AS EmpSeq,      -- 사원코드  
           B.EmpName       AS EmpName,     -- 성명  
           B.EmpID         AS EmpID,       -- 사번  
           B.DeptName      AS DeptName,    -- 소속부서  
           B.UMPgName      AS UMPgName,    -- 직급  
           B.UMPgSeq       AS UMPgSeq,     -- 직급코드  
           B.DeptSeq       AS DeptSeq,     -- 소속부서코드  
           M.WkTeamSeq     AS WkTeamSeq,   -- 근무조내부코드  
           C.WkTeamName    AS WkTeamName   -- 근무조  
      FROM _THRSafeEduCloseCHE AS M  
           JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON M.EmpSeq     = B.EmpSeq  
           JOIN _TPRWkTeam                    AS C ON M.CompanySeq = C.CompanySeq  
                                                  AND M.WkTeamSeq  = C.WkTeamSeq  
           JOIN _TDADept                      AS D ON D.CompanySeq = @CompanySeq  
                                                  AND B.DeptSeq    = D.DeptSeq  
     WHERE M.CompanySeq = @CompanySeq  
       AND (B.EmpName LIKE @Keyword OR B.EmpID LIKE @Keyword)  
       AND M.EduYM = @Param1  
     ORDER BY M.EmpSeq  
  
    --SET ROWCOUNT 0  
  
RETURN  