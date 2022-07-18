
IF OBJECT_ID('DTI_SCACodeHelpSlipID') IS NOT NULL 
    DROP PROC DTI_SCACodeHelpSlipID 
GO

-- v2013.12.18 

-- 전표번호_DTI(코드헬프) by이재천
CREATE PROCEDURE DTI_SCACodeHelpSlipID   
    @WorkingTag     NVARCHAR(1),                                  
    @LanguageSeq    INT,                                  
    @CodeHelpSeq    INT,                                  
    @DefQueryOption INT, -- 2: direct search                                  
    @CodeHelpType   TINYINT,                                  
    @PageCount      INT = 20,                       
    @CompanySeq     INT = 1,                                 
    @Keyword        NVARCHAR(50) = '',                                  
    @Param1         NVARCHAR(50) = '',                      
    @Param2         NVARCHAR(50) = '',                      
    @Param3         NVARCHAR(50) = '',                      
    @Param4         NVARCHAR(50) = ''      
AS    
    SET ROWCOUNT @PageCount
    
    SELECT A.SlipID, 
           A.SlipSeq, 
           A.AccSeq,  
           B.AccName, 
           A.DrAmt, 
           A.CrAmt, 
           A.Summary, 
           CASE WHEN A.DrAmt <> 0 THEN A.DrAmt ELSE A.CrAmt END AS SlipAmt 
           
           
      FROM _TACSlipRow AS A
      JOIN _TDAAccount AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.SlipID like @KeyWord+'%' 
       AND LEFT(A.AccDate,6) = @Param1

    SET ROWCOUNT 0  
      
    RETURN
GO
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1001778',@Keyword=N'%%',@Param1=N'201312',@Param2=N'0',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'500',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=147,@WkDeptSeq=59,@EmpSeq=2028,@UserSeq=50322