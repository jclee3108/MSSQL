 
IF OBJECT_ID('hencom_SACBankAccMoveQuery') IS NOT NULL   
    DROP PROC hencom_SACBankAccMoveQuery  
GO  
  
-- v2017.05.15
  
-- 계좌간이동입력-조회 by 이재천
CREATE PROC hencom_SACBankAccMoveQuery  
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
            @StdDateFr      NCHAR(8), 
            @StdDateTo      NCHAR(8), 
            @OutBankAccSeq  INT, 
            @InBankAccSeq   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDateFr       = ISNULL(StdDateFr,''), 
           @StdDateTo       = ISNULL(StdDateTo,''), 
           @OutBankAccSeq   = ISNULL(OutBankAccSeq,0), 
           @InBankAccSeq    = ISNULL(InBankAccSeq,0)
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDateFr      NCHAR(8),
            StdDateTo      NCHAR(8),
            OutBankAccSeq  INT,       
            InBankAccSeq   INT
           )    
    
    IF @StdDateTo = '' 
    BEGIN 
        SELECT @StdDateTo = '99991231'
    END 
    
    -- 최종조회   
    SELECT A.MoveSeq, 
           A.StdDate, 
           A.OutBankAccSeq, 
           A.InBankAccSeq, 
           F.Memo2          AS OutBankAccName,  -- 출금-계좌명
           B.BankAccNo      AS OutBankAccNo,    -- 출금-계좌번호
           D.BankName       AS OutBankName,     -- 출금-금융기관
           G.Memo2          AS InBankAccName,   -- 입금-계좌명
           C.BankAccNo      AS InBankAccNo,     -- 입금-계좌번호 
           E.BankName       AS InBankName,      -- 입금-금융기관
           A.OutAmt, 
           A.InAmt, 
           A.AddAmt, 
           A.Remark, 
           A.DrAccSeq, 
           H.AccName        AS DrAccName,       -- 차변계정
           A.CrAccSeq, 
           I.AccName        AS CrAccName,       -- 대변계정
           A.AddAccSeq, 
           J.AccName        AS AddAccName,      -- 수수료계정
           A.SlipSeq,       
           K.SlipID, 
           E.BankSeq        AS InBankSeq,       -- 입금-금융기관코드
           D.BankSeq        AS OutBankSeq      -- 출금-금융기관코드
           
      FROM hencom_TACBankAccMove            AS A 
      LEFT OUTER JOIN hencom_TDABankAccAdd  AS F ON ( F.CompanySeq = @CompanySeq AND F.BankAccSeq = A.OutBankAccSeq ) 
      LEFT OUTER JOIN hencom_TDABankAccAdd  AS G ON ( G.CompanySeq = @CompanySeq AND G.BankAccSeq = A.InBankAccSeq ) 
      LEFT OUTER JOIN _TDABankAcc           AS B ON ( B.CompanySeq = @CompanySeq AND B.BankAccSeq = F.BankAccSeq ) 
      LEFT OUTER JOIN _TDABankAcc           AS C ON ( C.CompanySeq = @CompanySeq AND C.BankAccSeq = G.BankAccSeq ) 
      LEFT OUTER JOIN _TDABank              AS D ON ( D.CompanySeq = @CompanySeq AND D.BankSeq = B.BankSeq ) 
      LEFT OUTER JOIN _TDABank              AS E ON ( E.CompanySeq = @CompanySeq AND E.BankSeq = C.BankSeq ) 
      LEFT OUTER JOIN _TDAAccount           AS H ON ( H.CompanySeq = @CompanySeq AND H.AccSeq = A.DrAccSeq ) 
      LEFT OUTER JOIN _TDAAccount           AS I ON ( I.CompanySeq = @CompanySeq AND I.AccSeq = A.CrAccSeq ) 
      LEFT OUTER JOIN _TDAAccount           AS J ON ( J.CompanySeq = @CompanySeq AND J.AccSeq = A.AddAccSeq ) 
      LEFT OUTER JOIN _TACSlipRow           AS K ON ( K.CompanySeq = @CompanySeq AND K.SlipSeq = A.SlipSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.StdDate BETWEEN @StdDateFr AND @StdDateTo)
       AND (@OutBankAccSeq = 0 OR A.OutBankAccSeq = @OutBankAccSeq) 
       AND (@InBankAccSeq = 0 OR A.InBankAccSeq = @InBankAccSeq) 
    
    RETURN  
go
exec hencom_SACBankAccMoveQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate />
    <OutBankAccSeq />
    <InBankAccSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512197,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033591