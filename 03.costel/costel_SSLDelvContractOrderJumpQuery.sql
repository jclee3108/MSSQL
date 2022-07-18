  
IF OBJECT_ID('costel_SSLDelvContractOrderJumpQuery') IS NOT NULL   
    DROP PROC costel_SSLDelvContractOrderJumpQuery  
GO  
  
-- v2013.09.06  
  
-- 납품계약등록_costel(수주점프) by이재천 
CREATE PROC costel_SSLDelvContractOrderJumpQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0         
AS        
    
	CREATE TABLE #costel_TSLDelvContractItem (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItem'     
	IF @@ERROR <> 0 RETURN      
    
     UPDATE A
        SET Result = N'해당 건은 이미 진행되어 한번 더 진행  할 수 없습니다.', 
            STATUS = 124124
     
      FROM #costel_TSLDelvContractItem AS A 
     WHERE EXISTS (
                   SELECT Dummy6, Dummy7 
                     FROM _TSLOrderItem AS B
                    WHERE B.CompanySeq = @CompanySeq AND B.Dummy6 = A.ContractSeq AND B.Dummy7 = A.ContractSerl
                  )
    
    -- 최종조회   
    SELECT B.BizUnit, 
           D.BizUnitName, 
           B.CustSeq, 
           E.CustName, 
           B.BizEmpSeq, 
           F.EmpName AS BizEmpName, 
           B.BizDeptSeq, 
           G.DeptName AS BizDeptName, 
           B.BKCustSeq, 
           I.CustName AS BKCustName, 
           ISNULL(A.Result,'') AS SubResult, 
           B.ContractSeq
    
      FROM #costel_TSLDelvContractItem AS A WITH(NOLOCK) 
      JOIN costel_TSLDelvContract      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      JOIN costel_TSLDelvContractItem  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = A.ContractSeq AND C.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDABizUnit      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = B.BizUnit ) 
      LEFT OUTER JOIN _TDACust         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = B.BizEmpSeq ) 
      LEFT OUTER JOIN _TDADept         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = B.BizDeptSeq ) 
      LEFT OUTER JOIN _TDAUnit         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDACust         AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = B.BKCustSeq ) 

    SELECT C.ContractSeq,
           C.ContractSerl,
           CASE WHEN C.ChgDelvExpectDate <> '' THEN C.ChgDelvExpectDate  ELSE C.DelvExpectDate END AS ChangeDeliveyDate, 
           C.ItemSeq, 
           D.ItemName, 
           D.ItemNo, 
           D.Spec, 
           C.DelvPrice, 
           C.DelvQty, 
           C.DelvCurAmt AS DelvAmt, 
           C.DelvCurVAT AS DelvVatAmt, 
           C.DelvCurAmt + C.DelvCurVat AS CurAmtTotal, 
           C.DelvCurAmt AS DomAmt, 
           C.DelvCurVAT AS DomVAT, 
           C.DelvCurAmt + C.DelvCurVat AS DomAmtTotal, 
           C.UnitSeq, 
           E.UnitName, 
           C.UnitSeq AS STDUnitSeq, 
           E.UnitName AS STDUnitName,
           ISNULL(A.Result,'') AS SubResult, 
           G.VATRate
      
      FROM #costel_TSLDelvContractItem           AS A WITH(NOLOCK) 
      LEFT OUTER JOIN costel_TSLDelvContract     AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN costel_TSLDelvContractItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = A.ContractSeq AND C.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDAItem                   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAVATRate                AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND (H.RegDate BETWEEN G.SDate AND G.EDate) AND G.SMVatType = F.SMVatType )
    
    RETURN  
GO
exec costel_SSLDelvContractItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractSeq>47</ContractSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985