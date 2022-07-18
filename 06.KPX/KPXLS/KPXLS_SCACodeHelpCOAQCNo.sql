IF OBJECT_ID('KPXLS_SCACodeHelpCOAQCNo') IS NOT NULL 
    DROP PROC KPXLS_SCACodeHelpCOAQCNo
GO 

-- v2016.01.06 

-- 검사번호(COA)_KPXLS by 이재천 
      
CREATE PROC KPXLS_SCACodeHelpCOAQCNo
    @WorkingTag     NVARCHAR(1),                                  
    @LanguageSeq    INT,                                  
    @CodeHelpSeq    INT,                                  
    @DefQueryOption INT,                
    @CodeHelpType   TINYINT,                                  
    @PageCount      INT = 20,                       
    @CompanySeq     INT = 1,                                 
    @Keyword        NVARCHAR(200) = '',                                  
    @Param1         NVARCHAR(50) = 0,       
    @Param2         NVARCHAR(50) = '',       
    @Param3         NVARCHAR(50) = '',                      
    @Param4         NVARCHAR(50) = ''         
          
    WITH RECOMPILE                
AS          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
            
    SET ROWCOUNT @PageCount                
    
    SELECT B.TestDate AS QCDate, 
           A.QCNo, 
           C.QCTypeName, 
           A.QCSeq, 
           A.QCType, 
           E.InTestItemName, 
           D.TestItemSeq, 
           D.TestValue, 
           D.SMTestResult, 
           F.MinorName AS SMTestResultName 
           
      FROM KPX_TQCTestResult AS A 
      LEFT OUTER JOIN KPX_TQCTestResultItem     AS D ON ( D.CompanySeq = A.CompanySeq AND D.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd    AS B ON ( B.CompanySeq = A.CompanySeq AND B.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS C ON ( C.CompanySeq = A.CompanySeq AND C.QCType = A.QCType )   
      LEFT OUTER JOIN KPX_TQCQATestItems        AS E ON ( E.CompanySeq = D.CompanySeq AND E.TestItemSeq = D.TestItemSeq ) 
      LEFT OUTER JOIN _TDASMinor                AS F ON ( F.CompanySeq = D.CompanySeq AND F.MinorSeq = D.SMTestResult ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ItemSeq = @Param1 
       AND A.LotNo = @Param3 
       AND A.QCType IN ( 
                        SELECT Z.QCType 
                          FROM KPX_TQCQAQualityAssuranceSpec AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.CustSeq = @Param2 
                           AND Z.ItemSeq = @Param1 
                       )
    
    SET ROWCOUNT 0          
            
RETURN    
go
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1020959',@Keyword=N'%%',@Param1=N'1001098',@Param2=N'27753',@Param3=N'aaa',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=2,@FactUnit=0,@DeptSeq=1300,@WkDeptSeq=147,@EmpSeq=2028,@UserSeq=50322