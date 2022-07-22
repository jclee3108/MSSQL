IF OBJECT_ID('hencom_SCACodeHelpBankAccMove') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpBankAccMove
GO 

-- v2017.05.22 

-- 계좌명(계좌간이동입력) CodeHelp by이재천 
CREATE PROCEDURE dbo.hencom_SCACodeHelpBankAccMove
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

    SELECT A.BankAccSeq, 
           A.Memo2 AS BankAccName, 
           B.BankAccNo, 
           C.BankName, 
           B.BankSeq, 
           B.AccSeq, 
           D.AccName 
      FROM hencom_TDABankAccAdd     AS A 
                 JOIN _TDABankAcc   AS B ON ( B.CompanySeq = @CompanySeq AND B.BankAccSeq = A.BankAccSeq ) 
      LEFT OUTER JOIN _TDABank      AS C ON ( C.CompanySeq = @CompanySeq AND C.BankSeq = B.BankSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS D ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = B.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND ISNULL(A.Memo2,'') <> ''
       AND (@Keyword = '' OR A.Memo2 LIKE '%' + @Keyword + '%')
    
    SET ROWCOUNT 0
    
    RETURN
