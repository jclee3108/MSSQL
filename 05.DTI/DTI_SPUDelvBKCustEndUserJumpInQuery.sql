
IF OBJECT_ID('DTI_SPUDelvBKCustEndUserJumpInQuery') IS NOT NULL
    DROP PROC DTI_SPUDelvBKCustEndUserJumpInQuery

GO

--v2013.06.12

--구매납품매출처EndUser점프조회_DTI By이재천   
CREATE PROC DTI_SPUDelvBKCustEndUserJumpInQuery
    @xmlDocument    NVARCHAR(MAX),            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',            
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0            
AS      
               
    DECLARE @docHandle   INT,             
            @FromSeq     INT,        
            @FromSerl    INT 

    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'         

    IF @@ERROR <> 0 RETURN 
    
    UPDATE #TPUDelvItem
       SET SalesCustName = E.CustName,
           SalesCustSeq  = D.Memo1,
           EndUserName   = F.CustName,
           EndUserSeq    = D.Memo2
    --SELECT E.CustName AS SalesCustName, D.Memo1 AS SalesCustSeq, F.CustName AS EndUserName, D.Memo2 AS EndUserSeq
      FROM #TPUDelvItem AS A WITH(NOLOCK)
      --LEFT OUTER JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TPUORDPOItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.FromSeq AND C.POSerl = A.FromSerl )
      LEFT OUTER JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ProgFromSeq = C.POSeq AND B.ProgFromSerl = C.POSerl ) 
      LEFT OUTER JOIN _TPUORDApprovalReqItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ApproReqSeq = C.ProgFromSeq AND D.ApproReqSerl = C.ProgFromSerl ) 
      LEFT OUTER JOIN _TDACust      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = D.Memo1 )
      LEFT OUTER JOIN _TDACust      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = D.Memo2 ) 

    SELECT * FROM #TPUDelvItem
     
    RETURN

GO
exec DTI_SPUDelvBKCustEndUserJumpInQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FromSerl>1</FromSerl>
    <FromSeq>38518766</FromSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553