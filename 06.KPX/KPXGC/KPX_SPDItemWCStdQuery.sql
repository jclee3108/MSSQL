  
IF OBJECT_ID('KPX_SPDItemWCStdQuery') IS NOT NULL   
    DROP PROC KPX_SPDItemWCStdQuery  
GO  
  
-- v2014.09.25  
  
-- 제품별설비기준등록-조회 by 이재천   
CREATE PROC KPX_SPDItemWCStdQuery  
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
            @ItemSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq = ISNULL( ItemSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ItemSeq   INT)    
    
    -- 최종조회   
    SELECT A.ItemName, A.ItemNo, A.Spec, A.ItemSeq 
      FROM _TDAItem AS A WITH(NOLOCK)   
      JOIN _TDAItemAsset AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.AssetSeq = A.AssetSeq AND B.SMAssetGrp IN ( 6008002, 6008004 ) ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq )   
    
    RETURN  
GO 
exec KPX_SPDItemWCStdQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024754,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020849