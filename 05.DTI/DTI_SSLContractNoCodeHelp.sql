
IF OBJECT_ID('DTI_SSLContractNoCodeHelp') IS NOT NULL 
    DROP PROC DTI_SSLContractNoCodeHelp 
GO

-- v2014.01.27  
      
-- 계약번호코드도움_DTI By이재천      
  CREATE PROC DTI_SSLContractNoCodeHelp          
      @WorkingTag     NVARCHAR(1)      ,    -- WorkingTag              
      @LanguageSeq    INT              ,    -- 언어              
      @CodeHelpSeq    INT              ,    -- 코드도움(코드)              
      @DefQueryOption INT              ,    -- 2: direct search              
      @CodeHelpType   TINYINT          ,              
      @PageCount      INT = 20         ,              
      @CompanySeq     INT = 1          ,              
      @Keyword        NVARCHAR(50) = '',              
      @Param1         NVARCHAR(50) = '',              
      @Param2         NVARCHAR(50) = '',              
      @Param3         NVARCHAR(50) = '',              
      @Param4         NVARCHAR(50) = '',              
      @PageSize       INT = 50              
   AS              
    
    SET ROWCOUNT @PageCount 
    
    SELECT A.ContractSeq, 
           A.ContractNo, 
           A.ContractDate, 
           B.BizUnitName, 
           C.CustName, 
           D.CustName AS EndUserName, 
           A.ContractMngNo 
      FROM DTI_TSLContractMng AS A 
      LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACust    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.EndUserSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ContractNo LIKE @Keyword + '%'
    ORDER BY A.ContractSeq DESC  
    
    SET ROWCOUNT 0          
    
    RETURN    