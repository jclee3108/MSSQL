  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderSubQty') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderSubQty
GO  
  
-- v2014.11.25 
  
-- 포장작업지시입력- 용기수량 조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderSubQty  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @SubItemSeq    INT, 
            @OrderQty      DECIMAL(19,5)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @SubItemSeq   = ISNULL( SubItemSeq, 0 ),
           @OrderQty   = ISNULL( OrderQty, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (SubItemSeq   INT,
            OrderQty      DECIMAL(19,5)
           )    
    
    SELECT CASE WHEN ISNULL(A.STDLoadConvQty,0) = 0 THEN 0 ELSE @OrderQty / A.STDLoadConvQty END AS SubQty
      FROM _TDAItemStock AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @SubItemSeq 
      
    RETURN  
go
exec KPX_SPDSFCProdPackOrderItemInfo @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>27439</ItemSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349


--select * from _TDAItemUserDefine  where companyseq = 1 and itemseq = 27439