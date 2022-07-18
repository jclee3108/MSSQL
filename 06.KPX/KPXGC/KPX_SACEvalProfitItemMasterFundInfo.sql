
IF OBJECT_ID('KPX_SACEvalProfitItemMasterFundInfo') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterFundInfo  
GO  
  
-- v2014.12.20  
  
-- 평가손익상품마스터- 상품 정보 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterFundInfo  
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
            @FundSeq    INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FundSeq   = ISNULL( FundSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (FundSeq    INT)    
    
    SELECT C.MinorName AS FundKindSName, 
           D.MinorName AS FundKindMName, 
           F.MinorName AS FundKindName, 
           L.MinorName AS FundKindLName, 
           A.TitileName 
           
      FROM KPX_TACFundMaster            AS A 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.FundKindS ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.FundKindM ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = F.MinorSeq AND K.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.FundSeq = @FundSeq 
    
    RETURN  
GO 
exec KPX_SACResultProfitItemMasterFundInfo @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FundSeq>12</FundSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026968,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020386