
IF OBJECT_ID('DTI_SSLReceiptConsignDescQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignDescQuery
GO 

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁세부조회) by이재천
 CREATE PROCEDURE DTI_SSLReceiptConsignDescQuery    
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
            @ReceiptNo    NCHAR(12)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ReceiptSeq = ReceiptSeq,   
           @ReceiptNo  = ReceiptNo  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)       
      WITH (ReceiptSeq INT, ReceiptNo NCHAR(12))    
    
    SELECT B.ReceiptSerl            AS ReceiptSerl,         --입금순번  
           C.MinorName              AS ReceiptKindName,     --입금구분  
           B.UMReceiptKind          AS UMReceiptKind,       --입금구분코드  
           D.MinorName              AS DrOrCrName,          --차대구분  
           B.SMDrOrCr               AS SMDrOrCr,            --차대구분코드  
           ISNULL(B.CurAmt, 0)      AS CurAmt,              --입금액  
           ISNULL(B.DomAmt, 0)      AS DomAmt,              --원화입금액  
           E.BankName               AS BankName,            --입금은행  
           B.BankSeq                AS BankSeq,             --입금은행코드  
           F.BankAccName            AS BankAccName,         --계좌  
           F.BankAccNo              AS BankAccNo,           --계좌번호  
           B.BankAccSeq             AS BankAccSeq,          --계좌코드  
           B.Remark                 AS Remark,              --비고  
           B.CustSeq                AS CustSeq, 
           I.CustName               AS CustName, 
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN ISNULL(G.ValueSeq,0) ELSE 0 END AS AccSeqDr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN 0 ELSE ISNULL(G.ValueSeq,0) END AS AccSeqCr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN (SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = ISNULL(G.ValueSeq,0)) ELSE '' END AS AccNameDr,  
           CASE WHEN ISNULL(H.ValueSeq,'1') = '1' THEN '' ELSE (SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = ISNULL(G.ValueSeq,0)) END AS AccNameCr
   
      FROM DTI_TSLReceiptConsign                   AS A WITH(NOLOCK)  
                 JOIN DTI_TSLReceiptConsignDesc    AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
                 JOIN _TDAUMinor                   AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND B.UMReceiptKind = C.MinorSeq ) 
      LEFT OUTER JOIN _TDASMinor                   AS D WITH(NOLOCK) ON ( B.CompanySeq = D.CompanySeq AND D.MajorSeq = 4001 AND B.SMDrOrCr = D.MinorValue ) 
      LEFT OUTER JOIN _TDABank                     AS E WITH(NOLOCK) ON ( B.CompanySeq = E.CompanySeq AND B.BankSeq = E.BankSeq ) 
      LEFT OUTER JOIN _TDABankAcc                  AS F WITH(NOLOCK) ON ( B.CompanySeq = F.CompanySeq AND B.BankAccSeq = F.BankAccSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue              AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND B.UMReceiptKind = G.MinorSeq AND G.Serl = 1001 ) 
      LEFT OUTER JOIN _TDAUMinorValue              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND B.UMReceiptKind = H.MinorSeq AND H.Serl = 1002 ) 
      LEFT OUTER JOIN _TDACust                     AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = B.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.ReceiptNo = @ReceiptNo OR A.ReceiptSeq = @ReceiptSeq)  
    
    RETURN
GO
exec DTI_SSLReceiptConsignDescQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>7</ReceiptSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019203