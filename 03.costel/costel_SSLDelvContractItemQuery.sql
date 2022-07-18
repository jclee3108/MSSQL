  
IF OBJECT_ID('costel_SSLDelvContractItemQuery') IS NOT NULL   
    DROP PROC costel_SSLDelvContractItemQuery
GO  
  
-- v2013.09.05 
  
-- 납품계약등록_costel(품목조회) by이재천
CREATE PROC costel_SSLDelvContractItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ContractSeq INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ContractSeq   = ISNULL( ContractSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ContractSeq   INT)    
      
    -- 최종조회   
    SELECT D.ContractSeq, 
           D.ContractSerl, 
           D.DelvExpectDate, 
           D.ChgDelvExpectDate AS ChangeDeliveyDate, 
           D.ItemSeq, 
           B.ItemName, 
           B.ItemNo, 
           B.Spec, 
           D.UnitSeq, 
           C.UnitName, 
           D.DelvQty, 
           D.DelvPrice, 
           D.DelvCurAmt AS DelvAmt, 
           D.DelvCurVAT AS DelvVatAmt, 
           D.DelvCurAmt + D.DelvCurVAT AS SUMDelvAmt,  
           D.SalesExpectDate, 
           D.Remark, 
           D.ChangeReason, 
           D.CollectExpectDate AS ExpReceiptDate, 
           F.VATRate
           
      FROM costel_TSLDelvContract AS A   
      LEFT OUTER JOIN costel_TSLDelvContractItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND A.ContractSeq = D.ContractSeq ) 
      LEFT OUTER JOIN _TDAItem        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = D.UnitSeq ) 
      LEFT OUTER JOIN _TDAItemSales   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDAVATRate     AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND (A.RegDate BETWEEN F.SDate AND F.EDate) AND F.SMVatType = E.SMVatType ) 
     
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ContractSeq = @ContractSeq
    
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