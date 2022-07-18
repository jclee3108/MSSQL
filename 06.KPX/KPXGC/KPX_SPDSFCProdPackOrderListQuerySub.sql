  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderListQuerySub') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderListQuerySub  
GO  
  
-- v2014.11.26  
  
-- 포장작업지시조회-Item조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderListQuerySub  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @PackOrderSeq   INT, 
            @PackOrderSerl  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PackOrderSeq   = ISNULL( PackOrderSeq, 0 ),  
           @PackOrderSerl  = ISNULL( PackOrderSerl, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PackOrderSeq    INT,   
            PackOrderSerl   INT
           )    
    
    -- 최종조회   
    SELECT D.ItemName AS SubItemName, 
           D.ItemNo AS SubItemNo, 
           A.ItemSeq AS SubItemSeq, 
           E.CustName, 
           B.CustSeq, 
           B.OutDate, 
           B.ReOutDate           
           
      FROM KPX_TPDSFCProdPackOrderItem                  AS A 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItemCust   AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq AND B.PackOrderSerl = A.PackOrderSerl ) 
      LEFT OUTER JOIN _TDAItem                          AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACust                          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PackOrderSeq = @PackOrderSeq 
       AND A.PackOrderSerl = @PackOrderSerl 
    
    SELECT A.PackOrderSubSerl,
           A.InDate,
           A.InQty,
           A.Remark
           
      FROM KPX_TPDSFCProdPackOrderItemSub AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PackOrderSeq = @PackOrderSeq 
       AND A.PackOrderSerl = @PackOrderSerl 
    
    RETURN  
GO 
exec KPX_SPDSFCProdPackOrderListQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <PackOrderSeq>16</PackOrderSeq>
    <PackOrderSerl>0</PackOrderSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026191,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021350