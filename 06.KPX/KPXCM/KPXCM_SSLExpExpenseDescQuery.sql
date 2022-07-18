IF OBJECT_ID('KPXCM_SSLExpExpenseDescQuery') IS NOT NULL 
    DROP PROC KPXCM_SSLExpExpenseDescQuery
GO 

-- v2015.09.30 

-- 물품대상세 추가 by이재천 
/*********************************************************************************************************************
     화면명 : 수출비용_상세조회
     SP Name: _SSLExpExpenseDescQuery
     작성일 : 2009. 3 : CREATEd by 김준모
     수정일 : 
 ********************************************************************************************************************/
 CREATE PROCEDURE KPXCM_SSLExpExpenseDescQuery  
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
             @ExpenseSerl   INT
      CREATE TABLE #TSLExpExpenseDesc (WorkingTag NCHAR(1) NULL)      
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLExpExpenseDesc'       
   
     SELECT @ExpenseSerl = ExpenseSerl  
       FROM #TSLExpExpenseDesc  
    
    
  /***********************************************************************************************************************************************/
     SELECT  A.ExpenseSeq  AS ExpenseSeq,
    A.ExpenseSerl AS ExpenseSerl,
             ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMExpenseGroup), '') AS UMExpenseGroupName,
             A.UMExpenseGroup     AS UMExpenseGroup,
             ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMExpenseItem), '')  AS UMExpenseItemName,
             A.UMExpenseItem      AS UMExpenseItem,
             ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CostCustSeq), '')     AS CostCustName,
             A.CostCustSeq        AS CostCustSeq,
             A.CostDate           AS CostDate,
             ISNULL((SELECT CurrName FROM _TDACurr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq), '')  AS CurrName,
             A.CurrSeq            AS CurrSeq,
             A.ExRate AS ExRate,
             A.IsVAT  AS IsVAT,
             A.IsInclusedVAT AS IsInclusedVAT,
             A.VATRate AS VATRate,
             A.CurAmt AS CurAmt,
             A.CurVAT AS CurVAT,
             A.DomAmt AS DomAmt,
             A.DomVAT AS DomVAT,
             ISNULL(A.DomAmt,0) + ISNULL(A.DomVAT,0) AS TotDomAmt,
             A.Remark AS Remark,
             A.RefBillNo AS RefBillNo,
             ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.AccSeq), '') AS AccName,
             A.AccSeq AS AccSeq,
             ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.VATAccSeq), '') AS VATAccName,
             A.VATAccSeq AS VATAccSeq,
             ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.OppAccSeq), '') AS OppAccName,
             A.OppAccSeq AS OppAccSeq,
             ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq), '') AS SlipID,
             A.SlipSeq AS SlipSeq,
             ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq), '') AS CCtrName,
             A.CCtrSeq AS CCtrSeq,
             ISNULL(B.ValueText,'') AS IsGoodAmtItem,
             ISNULL(A.EtcKey, '') AS EtcKey,
             ISNULL(E.TaxName,'') AS TaxName,
             ISNULL(E.TaxUnit,0) AS TaxUnit,
             ISNULL((SELECT EvidName FROM _TDAEvid WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EvidSeq = A.EvidSeq), '') AS EvidName,
             ISNULL(A.EvidSeq, 0) AS EvidSeq,
             ISNULL((SELECT CustName From _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.PayCustSeq), '') AS PayCustName,
             A.PayCustseq    AS PayCustSeq,
             X.IDX_NO  AS IDX_NO ,
             ISNULL(A.PrePaymentDate,'') AS PrePaymentDate, 
             F.ItemRemark AS ItemRemark 
       FROM #TSLExpExpenseDesc AS X   
             JOIN _TSLExpExpenseDesc AS A WITH(NOLOCK) ON A.CompanySeq = @CompanySeq
                                                      AND X.ExpenseSeq = A.ExpenseSeq  
                                                      AND (@ExpenseSerl IS NULL OR X.ExpenseSerl = A.ExpenseSerl)  
             JOIN _TSLExpExpense     AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                      AND A.ExpenseSeq = C.ExpenseSeq
             LEFT OUTER JOIN _TDAUMinorValue AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                               AND B.MajorSeq = 8212 
                                                               AND B.Serl     = 1003
                                                               AND A.UMExpenseItem = B.MinorSeq
             LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                       AND C.DeptSeq    = D.DeptSeq
             LEFT OUTER JOIN _TDATaxUnit AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
                                                          AND D.TaxUnit    = E.TaxUnit 
             LEFT OUTER JOIN KPXCM_TSLExpExpenseDesc  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ExpenseSeq = A.ExpenseSeq AND F.ExpenseSerl = A.ExpenseSerl ) 
                                       
  
       WHERE A.CompanySeq = @CompanySeq
      ORDER BY A.ExpenseSerl, A.CostDate
 RETURN
 go
 begin tran 
 exec KPXCM_SSLExpExpenseDescQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ExpenseSeq>1000039</ExpenseSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=4354,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5070
rollback 