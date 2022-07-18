  
IF OBJECT_ID('jongie_SSLOrderSumListQuery') IS NOT NULL   
    DROP PROC jongie_SSLOrderSumListQuery  
GO  
  
-- v2013.08.07  
  
-- 주문장(박스)_jongie-조회 by이재천   
CREATE PROC jongie_SSLOrderSumListQuery  
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
            @OrderDateFr NVARCHAR(8) ,
            @OrderDateTo NVARCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
	SELECT @OrderDateFr = OrderDateFr, 
           @OrderDateTo = OrderDateTo 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
	  WITH (
            OrderDateFr  NVARCHAR(8),
            OrderDateTo  NVARCHAR(8)
           )
    IF @OrderDateTo = '' SELECT  @OrderDateTo = '99991231'
    
    -- 최종조회     
    SELECT B.ItemSeq,   
           MAX(C.ItemName) AS ItemName,   
           MAX(C.ItemNo) AS ItemNo,   
           MAX(C.Spec) AS Spec,   
           ISNULL(MAX(D.Remark),'') AS UMDVConditionName,   
           ISNULL(A.UMDVConditionSeq,0) AS UMDVConditionSeq,
           FLOOR(SUM(B.STDQty) / MAX(F.ConvNum / F.ConvDen)) AS BoxQty,
           @OrderDateFr AS OrderDate
        
      FROM _TSLOrder AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq )   
      LEFT OUTER JOIN _TDAItem      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq )   
      LEFT OUTER JOIN _TDAUMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMDVConditionSeq ) 
      LEFT OUTER JOIN jongie_TCOMEnv AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EnvSeq = 1 ) 
      LEFT OUTER JOIN _TDAItemUnit   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = E.EnvValue AND F.ItemSeq = B.ItemSeq ) 
       
     WHERE A.CompanySeq = @CompanySeq    
       AND (A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo) 
     GROUP BY B.ItemSeq, A.UMDVConditionSeq
     HAVING FLOOR(SUM(B.STDQty) / MAX(F.ConvNum / F.ConvDen)) <> 0  
     ORDER BY ISNULL(MAX(D.Remark),'')DESC, MAX(C.ItemName) 
    
    RETURN  
Go
exec jongie_SSLOrderSumListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <OrderDateFr>20130101</OrderDateFr>
    <OrderDateTo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017045,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1014564
