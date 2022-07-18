    
IF OBJECT_ID('costel_SSLDelvContractPrintQuery') IS NOT NULL 
    DROP PROC costel_SSLDelvContractPrintQuery
GO

-- v2013.11.14 
    
-- 납품계약등록_costel(조회) by이재천  
CREATE PROC costel_SSLDelvContractPrintQuery
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
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (ContractSeq   INT)      
      
    -- 최종조회     
    SELECT A.PJTName,   
           A.PJTNo,   
           A.CustSeq,   
           C.CustName,   
           A.ContractDate,   
           A.RegDate,   
           A.SalesEmpSeq,   
           D.EmpName AS SalesEmpName,   
           A.SalesDeptSeq,   
           E.DeptName AS SalesDeptName,   
           A.SMExpKind,   
           F.MinorName AS SMExpKindName,   
           A.BizEmpSeq,   
           G.EmpName AS BizEmpName,   
           A.BizDeptSeq,   
           H.DeptName AS BizDeptName,   
           A.MHOpenDate,   
           A.CurrSeq,   
           I.CurrName,   
           A.Remark, 
           L.ItemName, 
           L.ItemNo, 
           L.Spec, 
           M.UnitName, 
           ISNULL(K.DelvQty,0) AS Qty, 
           ISNULL(K.DelvPrice,0) AS Price, 
           ISNULL(K.DelvCurAmt,0) AS CurAmt, 
           ISNULL(K.DelvCurVAT,0) AS CurVAT, 
           ISNULL(K.DelvCurAmt,0) + ISNULL(K.DelvCurVAT,0) AS TotCurAmt, 
           K.DelvExpectDate, -- 납품예정일
           K.SalesExpectDate, -- 매출예정일 
           K.Remark AS SheetRemark, 
           CONVERT(NVARCHAR(8),GETDATE(),112) AS Present
           
           
             
      FROM costel_TSLDelvContract AS A    
      LEFT OUTER JOIN  costel_TSLDelvContractItem AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit )   
      LEFT OUTER JOIN _TDACust    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq )   
      LEFT OUTER JOIN _TDAEmp     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.SalesEmpSeq )   
      LEFT OUTER JOIN _TDADept    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.SalesDeptSeq )   
      LEFT OUTER JOIN _TDASMinor  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.SMExpKind )   
      LEFT OUTER JOIN _TDAEmp     AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.BizEmpSeq )   
      LEFT OUTER JOIN _TDADept    AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.DeptSeq = A.BizDeptSeq )   
      LEFT OUTER JOIN _TDACurr    AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = A.CurrSeq )   
      LEFT OUTER JOIN _TDACust    AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.CustSeq = A.BKCustSeq )   
      LEFT OUTER JOIN _TDAItem    AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.ItemSeq = K.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit    AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.UnitSeq = K.UnitSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq    
         AND A.ContractSeq  = @ContractSeq  
      
    RETURN   