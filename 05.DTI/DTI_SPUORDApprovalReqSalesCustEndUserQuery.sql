
IF OBJECT_ID('DTI_SPUORDApprovalReqSalesCustEndUserQuery') IS NOT NULL
    DROP PROC DTI_SPUORDApprovalReqSalesCustEndUserQuery

GO
    
--v2013.06.14

--구매품의매출처EndUser점프인조회 By이재천
CREATE PROC DTI_SPUORDApprovalReqSalesCustEndUserQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq	INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0         
AS        
    
    DECLARE @docHandle    INT,
            @ApproReqSerl INT,
            @ApproReqSeq  INT  
    
    CREATE TABLE #TPUORDApprovalReqItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDApprovalReqItem'     
    
    IF @@ERROR <> 0 RETURN  
    
    UPDATE #TPUORDApprovalReqItem
       SET SalesCustName = D.CustName,
           SalesCustSeq  = C.CustSeq,
           EndUserName   = E.CustName,
           EndUserSeq    = B.BKCustSeq
    --SELECT B.BKCustSeq AS EndUserSeq,
    --       E.CustName  AS EndUserName, 
    --       C.CustSeq   AS SalesCustSeq, 
    --       D.CustName  AS SalesCustName 
      FROM #TPUORDApprovalReqItem   AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.ProgFromSeq AND B.OrderSerl = A.ProgFromSerl ) 
      LEFT OUTER JOIN _TSLOrder     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = B.OrderSeq )
      LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.BKCustSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ApproReqSerl = @ApproReqSerl  
       AND A.ApproReqSeq = @ApproReqSeq   

    SELECT * FROM #TPUORDApprovalReqItem
    
    RETURN

