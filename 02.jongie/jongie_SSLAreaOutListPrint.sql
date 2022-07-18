
IF OBJECT_ID('jongie_SSLAreaOutListPrint')IS NOT NULL
    DROP PROC jongie_SSLAreaOutListPrint
GO

-- v2013.10.02 
      
-- 차량별출고현황_jongie(지방화물출고명세서) by이재천
CREATE PROC jongie_SSLAreaOutListPrint
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,       
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS       
    DECLARE @docHandle          INT,    
            @UnitSeq            INT,                 
            -- 조회조건    
            @OrderDateFrom      NVARCHAR(8)  ,    
            @OrderDateTo        NVARCHAR(8)  ,    
            @OrderNoFrom        NVARCHAR(20) ,    
            @OrderNoTo          NVARCHAR(20) ,    
            @CustSeq            INT          ,    
            @UMDVConditionSeq   INT          ,    
            @ItemName           NVARCHAR(100),    
            @ItemNo             NVARCHAR(100)     
                      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
          
    SELECT @OrderDateFrom     = ISNULL( OrderDateFrom    , '' ),      
           @OrderDateTo       = ISNULL( OrderDateTo      , '' ),      
           @OrderNoFrom       = ISNULL( OrderNoFrom      , '' ),    
           @OrderNoTo         = ISNULL( OrderNoTo        , '' ),    
           @CustSeq           = ISNULL( CustSeq          , 0  ),    
           @UMDVConditionSeq  = ISNULL( UMDVConditionSeq , 0  ),    
           @ItemName          = ISNULL( ItemName         , '' ),    
           @ItemNo            = ISNULL( ItemNo           , '' )    
               
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )           
      WITH (OrderDateFrom      NVARCHAR(8)  ,    
            OrderDateTo        NVARCHAR(8)  ,    
            OrderNoFrom        NVARCHAR(20) ,    
            OrderNoTo          NVARCHAR(20) ,    
            CustSeq            INT          ,    
            UMDVConditionSeq   INT          ,    
            ItemName           NVARCHAR(100),    
            ItemNo             NVARCHAR(100)     
           )        
  
    IF @OrderNoTo   = '' SELECT @OrderNoTo   = '999912319999'     
        
        
    -- 최종조회       
    SELECT DISTINCT ISNULL(D.CustName,'') AS CustNm, 
           ISNULL(C.MinorName,'') AS AgentNm, 
           CONVERT(NCHAR(8),GETDATE(),112) AS today 
           

      FROM _TSLOrder AS A WITH(NOLOCK)    
      JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq )    
      LEFT OUTER JOIN _TDAUMinor AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMDVConditionSeq )    
      LEFT OUTER JOIN _TDACust AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq )    
      LEFT OUTER JOIN _TDAItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq )    
    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.OrderDate BETWEEN @OrderDateFrom AND @OrderDateTo    
       AND A.OrderNo BETWEEN @OrderNoFrom AND @OrderNoTo    
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq )    
       AND ( @UMDVConditionSeq = 0 OR A.UMDVConditionSeq = @UMDVConditionSeq )    
       AND E.ItemName LIKE @ItemName+'%'    
       AND E.ItemNo LIKE @ItemNo+'%'    
           
     ORDER BY AgentNm, CustNm 
         
      RETURN     
GO
exec jongie_SSLAreaOutListPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <OrderDateFrom>20130101</OrderDateFrom>
    <OrderDateTo>20131002</OrderDateTo>
    <OrderNoFrom />
    <OrderNoTo />
    <CustSeq />
    <UMDVConditionSeq />
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017064,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014584