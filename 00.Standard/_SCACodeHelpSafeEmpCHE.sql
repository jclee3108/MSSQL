
IF OBJECT_ID('_SCACodeHelpSafeEmpCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpSafeEmpCHE
GO 

/************************************************************  
 ��  �� - �ڵ嵵��SP : �������������  
 �ۼ��� - 20110810  
 �ۼ��� - õ���  
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
  
    SELECT M.EmpSeq        AS EmpSeq,      -- ����ڵ�  
           B.EmpName       AS EmpName,     -- ����  
           B.EmpID         AS EmpID,       -- ���  
           B.DeptName      AS DeptName,    -- �ҼӺμ�  
           B.UMPgName      AS UMPgName,    -- ����  
           B.UMPgSeq       AS UMPgSeq,     -- �����ڵ�  
           B.DeptSeq       AS DeptSeq,     -- �ҼӺμ��ڵ�  
           M.WkTeamSeq     AS WkTeamSeq,   -- �ٹ��������ڵ�  
           C.WkTeamName    AS WkTeamName   -- �ٹ���  
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