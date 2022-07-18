  
IF OBJECT_ID('KPX_SACFundMasterKindQuery') IS NOT NULL   
    DROP PROC KPX_SACFundMasterKindQuery  
GO  
  
-- v2014.12.16 
  
-- 금융상품명세서-구분1 구분2 조회 by 이재천   
CREATE PROC KPX_SACFundMasterKindQuery  
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
            @FundKindM  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FundKindM   = ISNULL( FundKindM, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (FundKindM   INT)    
    
    -- 최종조회   
    SELECT E.MinorName AS FundKind, 
           C.MinorName AS FundKindL
           
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.MinorSeq = @FundKindM
    
    RETURN  
GO 
