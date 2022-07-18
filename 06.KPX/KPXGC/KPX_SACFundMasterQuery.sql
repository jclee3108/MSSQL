  
IF OBJECT_ID('KPX_SACFundMasterQuery') IS NOT NULL   
    DROP PROC KPX_SACFundMasterQuery  
GO  
  
-- v2014.12.16 
  
-- 금융상품명세서-조회 by 이재천   
CREATE PROC KPX_SACFundMasterQuery  
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
            @QFundSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QFundSeq   = ISNULL( QFundSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (QFundSeq   INT)    
    
    -- 최종조회   
    SELECT B.BankName, 
           C.MinorName AS FundKindSName, 
           D.MinorName AS FundKindMName, 
           L.MinorName AS FundKind, 
           F.MinorName AS FundKindL, 
           J.FundName AS OldFundName, 
           D.MinorName AS UMBondName, -- 시세/채권 구분 
           A.* 
           
      FROM KPX_TACFundMaster            AS A 
      LEFT OUTER JOIN _TDABank          AS B ON ( B.CompanySeq = @CompanySeq AND B.BankSeq = A.BankSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.FundKindS ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.FundKindM ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = F.MinorSeq AND K.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
      LEFT OUTER JOIN KPX_TACFundMaster AS J ON ( J.CompanySeq = @CompanySeq AND J.FundSeq = A.OldFundSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMBond ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FundSeq = @QFundSeq 
    
    RETURN  
GO 

exec KPX_SACFundMasterQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QFundSeq>8</QFundSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026661,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022318