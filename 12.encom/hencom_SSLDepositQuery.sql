 
IF OBJECT_ID('hencom_SSLDepositQuery') IS NOT NULL   
    DROP PROC hencom_SSLDepositQuery  
GO  

-- v2017.07.24
  
-- 공탁관리-조회 by 이재천
CREATE PROC hencom_SSLDepositQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle      INT,  
            -- 조회조건   
            @DepositDateFr  NCHAR(8),  
            @DepositDateTo  NCHAR(8), 
            @DepositNo      NVARCHAR(200)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DepositDateFr   = ISNULL( DepositDateFr, '' ), 
           @DepositDateTo   = ISNULL( DepositDateTo, '' ), 
           @DepositNo       = ISNULL( DepositNo    , '' )
           
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DepositDateFr   NCHAR(8),    
            DepositDateTo   NCHAR(8),   
            DepositNo       NVARCHAR(200)
           )    
      
    -- 최종조회   
    SELECT A.DepositSeq, 
           A.DepositNo, 
           A.DepositDate, 
           A.DepositAmt, 
           A.InterestAmt, 
           A.ReturnDate, 
           A.DepositAccSeq, 
           B.AccName AS DepositAccName, 
           A.InterestAccSeq, 
           C.AccName AS InterestAccName, 
           A.TotAccSeq, 
           D.AccName AS TotAccName, 
           A.SlipSeq, 
           E.SlipID, 
           A.Remark
      FROM hencom_TSLDeposit        AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.DepositAccSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.InterestAccSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS D ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = A.TotACcSeq ) 
      LEFT OUTER JOIN _TACSlipRow   AS E ON ( E.CompanySeq = @CompanySeq AND E.SlipSeq = A.SlipSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DepositDate BETWEEN @DepositDateFr AND @DepositDateTo 
       AND ( @DepositNo = '' OR A.DepositNo LIKE @DepositNo + '%' ) 
      
    RETURN  
