
IF OBJECT_ID('DTI_SSLReceiptConsignQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignQuery
GO 

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁조회) by이재천
CREATE PROC DTI_SSLReceiptConsignQuery    
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
    DECLARE @docHandle    INT,    
            @ReceiptSeq   INT,   
            @ReceiptNo    NCHAR(12),  
            @TotCurAmt    DECIMAL(19,5),  
            @TotDomAmt    DECIMAL(19,5)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    -- Temp에 INSERT      
    
    SELECT @ReceiptSeq = ReceiptSeq,   
           @ReceiptNo  = ReceiptNo  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
      WITH (
            ReceiptSeq INT, 
            ReceiptNo NCHAR(12)
           )    
    
    SELECT @TotCurAmt = SUM(CurAmt * SMDrOrCr),  
           @TotDomAmt = SUM(DomAmt * SMDrOrCr)  
      FROM DTI_TSLReceiptConsignDesc  
     WHERE CompanySeq = @CompanySeq   
       AND ReceiptSeq = @ReceiptSeq  
  
    SELECT A.ReceiptSeq         AS ReceiptSeq,  
           E.CustName           AS CustName,        --거래처  
           A.CustSeq            AS CustSeq,         --거래처코드  
           A.ReceiptDate        AS ReceiptDate,     --입금일  
           A.ReceiptNo          AS ReceiptNo,       --입금번호  
           D.EmpName            AS EmpName,         --담당자  
           A.EmpSeq             AS EmpSeq,          --담당자코드  
           C.DeptName           AS DeptName,        --부서  
           A.DeptSeq            AS DeptSeq,         --부서코드  
           A.ExRate             AS ExRate,          --환율  
           F.CurrName           AS CurrName,        --통화  
           A.CurrSeq            AS CurrSeq,         --통화코드  
           A.OppAccSeq          AS OppAccSeq   ,--상대정산항목  
           ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.OppAccSeq),'') AS OppAccName,--상대정산항목코드  
           ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq), '') AS SlipID,          --전표번호  
           A.SlipSeq            AS SlipSeq,         --전표코드  
           @TotCurAmt           AS TotCurAmt,--입금액계  
           @TotDomAmt           AS TotDomAmt,--입금액계(원화)  
           0,--처리액계  
           0 --처리액계(원화) 
      FROM DTI_TSLReceiptConsign    AS A WITH(NOLOCK)  
      LEFT OUTER JOIN _TDADept      AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CustSeq = E.CustSeq ) 
      LEFT OUTER JOIN _TDACurr      AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.CurrSeq = F.CurrSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.ReceiptSeq = @ReceiptSeq) 
    RETURN  