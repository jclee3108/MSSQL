
IF OBJECT_ID('DTI_SSLInterTransferPJTQuery') IS NOT NULL 
    DROP PROC DTI_SSLInterTransferPJTQuery
GO 

-- v2014.01.10 

-- 사내대체등록(프로젝트)_DTI(조회) by이재천
CREATE PROC dbo.DTI_SSLInterTransferPJTQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle          INT,
            @ReceiptDeptSeq     INT ,
            @SendDeptSeq        INT ,
            @StdYM              NCHAR(6)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ReceiptDeptSeq     = ReceiptDeptSeq      ,
           @SendDeptSeq        = SendDeptSeq         ,
           @StdYM              = StdYM              
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ReceiptDeptSeq      INT ,
            SendDeptSeq         INT ,
            StdYM               NCHAR(6) )
    
    SELECT @StdYM AS StdYM,  
           C.DeptName AS ReceiptDeptName, 
           A.ReceiptDeptSeq, 
           A.SendDeptSeq, 
           D.DeptName AS SendDeptName, 
           A.ResourceSeq, 
           E.ItemName AS ResourceName, 
           B.PJTName, 
           A.InputYM, 
           A.InterBillingAmt, 
           A.PreInterBillingAmt, 
           A.SalesAmt, 
           --F.InterBillingRate AS OwnershipRate, 
           G.CustName, 
           B.CustSeq, 
           A.PJTProcRate, 
           A.GPAmt, 
           B.PJTSeq 
    
      FROM DTI_TSLInterTransferPJT AS A 
      LEFT OUTER JOIN _TPJTProject AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDADept     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.ReceiptDeptSeq ) 
      LEFT OUTER JOIN _TDADept     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.SendDeptSeq ) 
      LEFT OUTER JOIN _TDAItem     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ResourceSeq ) 
      --LEFT OUTER JOIN #Tmp_InterBilling AS F WITH(NOLOCK) ON ( F.PJTSeq = F.PJTSeq AND F.InPutYM = F.InPutYM ) 
      LEFT OUTER JOIN _TDACust          AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = B.CustSeq ) 
        
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYm = @StdYM 
       AND (@ReceiptDeptSeq = 0 OR A.ReceiptDeptSeq = @ReceiptDeptSeq) 
       AND (@SendDeptSeq = 0 OR A.SendDeptSeq = @SendDeptSeq) 
    
    RETURN

