  
IF OBJECT_ID('DTI_SSLCreditLimitReqPrint') IS NOT NULL   
    DROP PROC DTI_SSLCreditLimitReqPrint  
GO  
  
-- v2014.04.29 
  
-- 포괄여신한도신청_DTI(출력물) by이재천 
CREATE PROC DTI_SSLCreditLimitReqPrint  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    --SET NOCOUNT ON
    --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    
    CREATE TABLE #DTI_TSLCreditLimitReq (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLCreditLimitReq'     
    IF @@ERROR <> 0 RETURN     
    
    -- 최종조회   
    SELECT B.CustName,
           C.MinorName AS SMCustStatusName,
           B.BizNo AS CustNo,
           H.SuretyAmt,
           E.EmpName,
           A.BegYM,
           A.EndYM,
           A.CreditAmt,
           F.CurrName,
           A.Remark,
           A.TotBondAmt,
           A.TotOverdueAmt,
           A.ThisReceiptTgtAmt,
           A.NextReceiptTgtAmt,
           A.NoOutOrdAmt,
           A.NoSalesInvAmt,
           A.TermSalesAmt,
           A.NoOrdContractAmt,
           A.Serl,
           A.CustSeq,
           A.EmpSeq,
           A.CurrSeq,
           B.SMCustStatus,
           A.IsStop,
           A.StopDate,
           A.StopEmpSeq,
           G.EmpName AS StopEmpName,
           D.DeptName,
           A.DeptSeq
      FROM #DTI_TSLCreditLimitReq           AS Z 
                 JOIN DTI_TSLCreditLimitReq AS A WITH(NOLOCK) ON ( A.CompanySeq = @Companyseq AND A.DeptSeq = Z.DeptSeq AND A.Serl = Z.Serl ) 
      LEFT OUTER JOIN _TDACust              AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq )
      LEFT OUTER JOIN _TDASMinor            AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.SMCustStatus )
      LEFT OUTER JOIN _TDADept              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq )
      LEFT OUTER JOIN _TDAEmp               AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq )
      LEFT OUTER JOIN _TDACurr              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CurrSeq = A.CurrSeq )
      LEFT OUTER JOIN _TDAEmp               AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.StopEmpSeq )
      CROSS APPLY ( SELECT SUM(SpecCreditAmt) AS SuretyAmt
                      FROM _TSLCustSpecCredit WITH(NOLOCK) 
                     WHERE CompanySeq = @CompanySeq 
                       AND CustSeq = A.CustSeq 
                       AND DeptSeq = A.DeptSeq
                       --AND EmpSeq = A.EmpSeq
                       AND ISNULL(IsCfm,'0') = '1'
                       AND CONVERT(NCHAR(8), GETDATE(),112) BETWEEN SDate AND EDate  
                  ) AS H
     ORDER BY A.DeptSeq, A.Serl  
     
       
    RETURN  