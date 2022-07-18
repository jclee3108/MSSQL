IF OBJECT_ID('KPX_SPDSFCProdPackOrderQuerySub') IS NOT NULL 
    DROP PROC KPX_SPDSFCProdPackOrderQuerySub
GO 

-- v2014.11.25 

-- 포장작업지시입력-품목Sub 조회 by 이재천   
CREATE PROC dbo.KPX_SPDSFCProdPackOrderQuerySub                
    @xmlDocument    NVARCHAR(MAX) , 
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
            @PackOrderSerl  INT,
            @PackOrderSeq   INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @PackOrderSerl = ISNULL(PackOrderSerl,0), 
           @PackOrderSeq = ISNULL(PackOrderSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH (
            PackOrderSerl    INT ,
            PackOrderSeq     INT 
           )
    
    SELECT A.OutDate, 
           B.CustName, 
           A.CustSeq, 
           A.ReOutDate 
    
      FROM KPX_TPDSFCProdPackOrderItemCust AS A 
      LEFT OUTER JOIN _TDACust             AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PackOrderSeq = @PackOrderSeq 
       AND A.PackOrderSerl = @PackOrderSerl 
    
    SELECT A.PackOrderSubSerl, 
           A.Remark, 
           A.InDate, 
           A.InQty            
      FROM KPX_TPDSFCProdPackOrderItemSub AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PackOrderSeq = @PackOrderSeq 
       AND A.PackOrderSerl = @PackOrderSerl 
    
    RETURN

GO 
exec KPX_SPDSFCProdPackOrderQuerySub @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <PackOrderSeq>8</PackOrderSeq>
    <PackOrderSerl>2</PackOrderSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349