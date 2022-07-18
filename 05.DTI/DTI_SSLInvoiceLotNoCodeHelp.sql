
IF OBJECT_ID('DTI_SSLInvoiceLotNoCodeHelp') IS NOT NULL
    DROP PROC DTI_SSLInvoiceLotNoCodeHelp
 GO

--v2013.12.19 
  
--거래명세서LotNo코드도움_DTI By이재천  
 CREATE PROC DTI_SSLInvoiceLotNoCodeHelp      
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
      
    DECLARE @EnvValue1 INT,  
            @EnvValue2 INT  
      
    SELECT @EnvValue1 = (SELECT EnvValue FROM DTI_TCOMEnv WHERE CompanySeq = 1 AND EnvSeq = 3)  
    SELECT @EnvValue2 = (SELECT EnvValue FROM DTI_TCOMEnv WHERE CompanySeq = 1 AND EnvSeq = 2)   
      
    SELECT B.LotNo, B.ItemSeq      
      FROM (SELECT A.CompanySeq, B.Memo1 AS CustSeq, B.Memo2 AS EndUserSeq, A.EmpSeq, B.ItemSeq, B.LotNo      
              FROM _TPUDelv AS A LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq ) AS B    
     WHERE B.CompanySeq = @CompanySeq       
       AND B.LotNo LIKE @Keyword     
       AND B.CustSeq = @param1  
       AND B.EndUserSeq = @param2  
       AND B.EmpSeq = @param3    
       AND B.ItemSeq = @param4   
  
    UNION 
      
    SELECT B.LotNo, B.ItemSeq   
      FROM (SELECT A.CompanySeq, B.Memo1 AS CustSeq, B.Memo2 AS EndUserSeq, A.EmpSeq, B.ItemSeq, B.LotNo      
              FROM _TPUDelv AS A LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq ) AS B  
     WHERE B.CompanySeq = @CompanySeq  
       AND B.LotNo LIKE @Keyword   
       AND (B.EndUserSeq = @EnvValue1 AND B.CustSeq = @EnvValue2)  
       AND B.EmpSeq = @param3    
       AND B.ItemSeq = @param4    
      
    SET ROWCOUNT 0      
      
    RETURN 