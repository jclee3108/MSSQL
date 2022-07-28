
IF OBJECT_ID('_SCACodeHelpLend') IS NOT NULL 
    DROP PROC _SCACodeHelpLend
GO 

-- v2014.02.06 

-- 대여금번호CodeHelp by이재천
CREATE PROCEDURE dbo._SCACodeHelpLend  
    @WorkingTag     NVARCHAR(1),  
    @LanguageSeq    INT,  
    @CodeHelpSeq    INT,  
    @DefQueryOption INT, -- 2: direct search  
    @CodeHelpType   TINYINT,  
    @PageCount      INT = 20,  
    @CompanySeq     INT = 0,  
    @Keyword        NVARCHAR(50) = '',  
    @Param1         NVARCHAR(50) = '',  
    @Param2         NVARCHAR(50) = '',  
    @Param3         NVARCHAR(50) = '',  
    @Param4         NVARCHAR(50) = ''  
AS  
    SET ROWCOUNT @PageCount  
    
    SELECT A.LendSeq,  
           A.LendNo, 
           B.CustName, 
           C.EmpName, 
           A.LendDate, 
           A.ExpireDate, 
           D.AccName 
      FROM _TACLend               AS A 
      LEFT OUTER JOIN _TDACust    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAAccount AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = A.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (@Keyword = '' OR A.LendNo LIKE @Keyword + '%')  
    
    SET ROWCOUNT 0  
    
    RETURN  
  