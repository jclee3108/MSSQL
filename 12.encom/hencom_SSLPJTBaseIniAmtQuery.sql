IF OBJECT_ID('hencom_SSLPJTBaseIniAmtQuery') IS NOT NULL 
    DROP PROC hencom_SSLPJTBaseIniAmtQuery
GO 

-- v2017.02.23 

-- 수금금액, 채권잔액 추가 by이재천
/************************************************************  
 설  명 - 데이터-현장별기초잔액등록_hencom : 조회  
 작성일 - 20160219  
 작성자 - 박수영  
************************************************************/  
  
CREATE PROC dbo.hencom_SSLPJTBaseIniAmtQuery                  
 @xmlDocument    NVARCHAR(MAX) ,              
 @xmlFlags     INT  = 0,              
 @ServiceSeq     INT  = 0,              
 @WorkingTag     NVARCHAR(10)= '',                    
 @CompanySeq     INT  = 1,              
 @LanguageSeq INT  = 1,              
 @UserSeq     INT  = 0,              
 @PgmSeq         INT  = 0           
      
AS          
   
    DECLARE @docHandle      INT,  
            @CustSeq        INT ,  
            @DeptSeq        INT ,  
            @PJTSeq         INT ,
            @BizUnit        INT   
   
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT  @CustSeq   = CustSeq    ,  
            @DeptSeq   = DeptSeq    ,  
            @PJTSeq    = PJTSeq    ,
            @BizUnit    = BizUnit   
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
   WITH (CustSeq    INT ,  
        DeptSeq    INT ,  
        PJTSeq     INT ,
        BizUnit     INT)  
    
    
    SELECT A.DeptSeq, A.BizUnit, A.CustSeq, B.PJTSeq, SUM(B.DomAmt) AS DomAmt
      INTO #TSLReceipt
      FROM _TSLReceipt                  AS A WITH(NOLOCK)
      JOIN _TSLReceiptDesc              AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND NOT EXISTS (SELECT 1 FROM _TSLReceiptBill WHERE CompanySeq = @CompanySeq AND ReceiptSeq = A.ReceiptSeq) 
     GROUP BY A.DeptSeq, A.BizUnit, A.CustSeq, B.PJTSeq
    

    --select * From _TSLReceipt where receiptno = '2017022300001'
    --select * From _TSLReceiptDESC where companyseq = 1 and ReceiptSeq = 167 


    --select * from #TSLReceipt 
    --return 

    -- 최종조회 
    SELECT A.CompanySeq ,  
           A.CBDRegSeq ,  
           A.CustSeq ,  
           A.DeptSeq ,  
           A.PJTSeq ,  
           A.CurrSeq ,  
           A.Qty ,  
           A.CurAmt ,  
           A.CurVAT ,  
           A.DomAmt ,  
           A.DomVat ,  
           A.Remark ,  
           (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq)  AS DeptName ,  
           (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq ) AS PJTName ,  
           (SELECT PJTNO FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq ) AS PJTNo ,  
           (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq ) AS CustName ,  
           (SELECT BizNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq )  AS BizNo,  
           A.LastUserSeq ,  
           A.LastDateTime ,
           A.BizUnit , 
           ISNULL(B.DomAmt,0) AS ReceiptAmt , 
           ISNULL(CurAmt,0) - ISNULL(B.DomAmt,0) AS DiffAmt

      FROM hencom_TSLSalesCreditBasicData   AS A WITH(NOLOCK)   
      LEFT OUTER JOIN #TSLReceipt           AS B              ON ( B.CustSeq = A.CustSeq 
                                                               AND B.DeptSeq = A.DeptSeq 
                                                               AND B.PJTSeq = A.PJTSeq 
                                                               AND B.BizUnit = A.BizUnit 
                                                                 ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq )    
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )     
       AND (@PJTSeq = 0 OR A.PJTSeq = @PJTSeq   )
       AND (@BizUnit  = 0 OR A.BizUnit = @BizUnit)
  
RETURN
go
exec hencom_SSLPJTBaseIniAmtQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DeptSeq />
    <PJTSeq />
    <CustSeq />
    <BizUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035199,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029096