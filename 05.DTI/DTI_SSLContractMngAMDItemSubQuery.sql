
IF OBJECT_ID('DTI_SSLContractMngAMDItemSubQuery') IS NOT NULL 
    DROP PROC DTI_SSLContractMngAMDItemSubQuery 
GO 

-- v2013.12.30 

-- 계약관리등록(AMD조회)_DTI(품목조회) by이재천
  
CREATE PROC DTI_SSLContractMngAMDItemSubQuery                    
    @xmlDocument    NVARCHAR(MAX),   
    @xmlFlags       INT = 0,   
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',   
    @CompanySeq     INT = 1,   
    @LanguageSeq    INT = 1,   
    @UserSeq        INT = 0,   
    @PgmSeq         INT = 0   
AS            
      
    DECLARE @docHandle      INT,   
            @ContractSeq    INT,   
            @ContractRev    INT   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
      
    SELECT @ContractSeq = ISNULL(ContractSeq,0),   
           @ContractRev = ISNULL(ContractRev,0)   
      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)    
      WITH (  
            ContractSeq INT,   
            ContractRev INT   
           )   
    
    --최종조회    
    SELECT C.ItemNo       ,    
           C.Spec         ,    
           A.SalesYM      ,     
           A.SalesPrice   ,    
           A.Qty          ,    
           A.PurYM        ,     
           A.Remark       ,    
           C.ItemName     ,    
           A.ContractSerl ,     
           A.PurPrice     ,    
           A.ContractSeq  ,    
           A.ItemSeq      ,    
           (A.Qty*A.PurPrice)   AS PurAmt,    
           (A.Qty*A.SalesPrice) AS SalesAmt,           
           B.FileSeq      ,    
           (A.SalesAmt-A.PurAmt) AS GPPrice     ,    
           CASE WHEN A.SalesAmt = 0 THEN 0 ELSE ((A.SalesAmt-A.PurAmt)/A.SalesAmt*100) END AS GPRate      ,    
           CASE WHEN A.ContractSeq = CONVERT(INT,G.Memo3) AND A.ContractSerl = CONVERT(INT,G.Memo4)
                THEN 1 
                ELSE 0
                END AS PurChk, 
           CASE WHEN A.ContractSeq = CONVERT(INT,J.Dummy6) AND A.ContractSerl = CONVERT(INT,J.Dummy7) 
                THEN 1
                ELSE 0 
                END AS SalesChk,  
           A.ContractRev,     
           A.IsStock,     
           I.ApproReqNo,     
           K.OrderNo,     
           P.DelvNo, 
           L.LotNo  
               
      FROM DTI_TSLContractMngItemRev         AS A WITH(NOLOCK)     
      JOIN DTI_TSLContractMngRev             AS B WITH(NOLOCK) ON A.CompanySeq   = B.CompanySeq    
                                                              AND A.ContractSeq  = B.ContractSeq    
                                                              AND A.ContractRev  = B.ContractRev   
      LEFT OUTER JOIN _TDAItem               AS C WITH(NOLOCK) ON A.Companyseq   =C.Companyseq    
                                                              AND A.ItemSeq      =C.ItemSeq           
      LEFT OUTER JOIN _TPUORDApprovalReqItem AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.Memo3 = A.ContractSeq AND G.Memo4 = A.ContractSerl )     
      LEFT OUTER JOIN _TPUORDApprovalReq     AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.ApproReqSeq = G.ApproReqSeq )      
      LEFT OUTER JOIN _TPUDelvItem           AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.Memo3 = A.ContractSeq AND L.Memo4 = A.ContractSerl )     
      LEFT OUTER JOIN _TPUDelv               AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.DelvSeq = L.DelvSeq )     
      LEFT OUTER JOIN _TSLOrderItem          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.Dummy6 = A.ContractSeq AND J.Dummy7 = A.ContractSerl )     
      LEFT OUTER JOIN _TSLOrder              AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = J.OrderSeq )     
      
     WHERE A.CompanySeq    = @CompanySeq    
       AND A.ContractSeq   = @ContractSeq   
       AND A.ContractRev   = @ContractRev  
     ORDER BY A.SalesYM, A.ContractSerl   
      
    RETURN    
GO
exec DTI_SSLContractMngAMDItemSubQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <ContractSeq>1000052</ContractSeq>
    <ContractRev>0</ContractRev>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020185,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016970