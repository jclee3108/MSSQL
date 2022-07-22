IF OBJECT_ID('hencom_SCACodeHelpDeposit') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpDeposit
GO 

-- v2017.07.25 

-- 공탁관리 CodeHelp by이재천 
CREATE PROCEDURE dbo.hencom_SCACodeHelpDeposit
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

    SELECT A.DepositNo, 
           A.DepositAmt, 
           A.DepositSeq, 
           A.DepositDate
      FROM hencom_TSLDeposit     AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND (@Keyword = '' OR A.DepositNo LIKE '%' + @Keyword + '%')
    
    SET ROWCOUNT 0
    
    RETURN