
IF OBJECT_ID('DTI_SPUDelvAddQuery') IS NOT NULL
    DROP PROC DTI_SPUDelvAddQuery

GO

--v2013.06.14

--구매납품품목추가조회_DTI By이재천
CREATE PROC DTI_SPUDelvAddQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags	      INT 	= 0,            
    @ServiceSeq	    INT 	= 0,            
    @WorkingTag	    NVARCHAR(10)= '',                  
    @CompanySeq	    INT 	= 1,            
    @LanguageSeq	  INT 	= 1,            
    @UserSeq	      INT 	= 0,            
    @PgmSeq	        INT 	= 0         
AS        
    
    DECLARE @docHandle  INT,
            @DelvSerl   INT ,
            @DelvSeq    INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @DelvSerl = DelvSerl,
           @DelvSeq  = DelvSeq       
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH (DelvSerl    INT,
            DelvSeq     INT)
    
    SELECT B.CustName AS SalesCustName,
           C.CustName AS EndUSerSeq,
           A.SalesCustSeq, 
           A.EndUserSeq, 
           A.DelvSeq, 
           A.DelvSerl
           
      FROM DTI_TPUDelvItem         AS A WITH(NOLOCK) 
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DelvSeq = A.DelvSeq AND D.DelvSerl = A.DelvSerl ) 
      LEFT OUTER JOIN _TDACust     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.SalesCustSeq ) 
      LEFT OUTER JOIN _TDACust     AS C WITh(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.EndUserSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq
       AND A.DelvSerl = @DelvSerl     
       AND A.DelvSeq = @DelvSeq      
    
    RETURN
GO
exec DTI_SPUDelvAddQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DelvSerl>1</DelvSerl>
    <DelvSeq>133700</DelvSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015994,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553