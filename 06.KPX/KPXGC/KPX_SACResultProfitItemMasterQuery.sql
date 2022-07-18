  
IF OBJECT_ID('KPX_SACResultProfitItemMasterQuery') IS NOT NULL   
    DROP PROC KPX_SACResultProfitItemMasterQuery  
GO  
  
-- v2014.12.20  
  
-- 실현손익상품마스터-조회 by 이재천   
CREATE PROC KPX_SACResultProfitItemMasterQuery  
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
            @StdDate        NCHAR(8), 
            @FundCode       NVARCHAR(100), 
            @FundName       NVARCHAR(100), 
            @UMHelpCom      INT, 
            @FundKIndSeq    INT, 
            @FundKindLSeq   INT, 
            @FundKindMSeq   INT, 
            @FundKindSSeq   INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT  @StdDate       = ISNULL(StdDate     , '' ),  
            @FundCode      = ISNULL(FundCode    , '' ),
            @FundName      = ISNULL(FundName    , '' ),  
            @UMHelpCom     = ISNULL(UMHelpCom   , 0 ),  
            @FundKIndSeq   = ISNULL(FundKIndSeq , 0 ),  
            @FundKindLSeq  = ISNULL(FundKindLSeq, 0 ),  
            @FundKindMSeq  = ISNULL(FundKindMSeq, 0 ),  
            @FundKindSSeq  = ISNULL(FundKindSSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate        NCHAR(8), 
            FundCode       NVARCHAR(100),
            FundName       NVARCHAR(100),
            UMHelpCom      INT, 
            FundKIndSeq    INT, 
            FundKindLSeq   INT, 
            FundKindMSeq   INT, 
            FundKindSSeq   INT 
           )    
    
    -- 최종조회   
    SELECT A.ResultProfitSeq, 
           Z.MinorName AS UMHelpComName, 
           A.UMHelpCom, 
           A.FundSeq, 
           B.FundName, 
           B.FundCode, 
           C.MinorName AS FundKindSName,   
           D.MinorName AS FundKindMName,   
           F.MinorName AS FundKindLName,   
           L.MinorName AS FundKindName,   
           B.TitileName, 
           A.CancelDate, 
           A.CancelAmt, 
           A.CancelResultAmt, 
           A.AllCancelDate, 
           A.AllCancelAmt, 
           A.AllCancelResultAmt, 
           A.SplitDate, 
           A.SliptAmt, 
           A.ResultReDate, 
           A.ResultReAmt, 
           A.ResultAmt, 
           A.Remark1, 
           A.Remark2, 
           A.Remark3 
           
      FROM KPX_TACResultProfitItemMaster    AS A 
      LEFT OUTER JOIN KPX_TACFundMaster     AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS Z ON ( Z.CompanySeq = @CompanySeq AND Z.MinorSeq = A.UMHelpCom ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.FundKindS )   
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.FundKindM )   
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 )   
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq )   
      LEFT OUTER JOIN _TDAUMinorValue       AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = F.MinorSeq AND K.Serl = 1000002 )   
      LEFT OUTER JOIN _TDAUMinor            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.StdDate = @StdDate ) 
       AND ( @FundCode = '' OR B.FundCode LIKE @FundCode + '%' ) 
       AND ( @FundName = '' OR B.FundName LIKE @FundName + '%' ) 
       AND ( @UMHelpCom = 0 OR A.UMHelpCom = @UMHelpCom ) 
       AND ( @FundKIndSeq = 0 OR L.MinorSeq = @FundKIndSeq ) 
       AND ( @FundKindLSeq = 0 OR F.MinorSeq = @FundKindLSeq ) 
       AND ( @FundKindMSeq = 0 OR D.MinorSeq = @FundKindMSeq ) 
       AND ( @FundKindSSeq = 0 OR C.MinorSeq = @FundKindSSeq )  
      
    RETURN  
GO 
exec KPX_SACResultProfitItemMasterQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate>20141220</StdDate>
    <FundCode />
    <FundName />
    <FundKIndSeq />
    <FundKindLSeq />
    <FundKindMSeq />
    <FundKindSSeq />
    <UMHelpComName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026968,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020386