  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterQuerySub') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterQuerySub  
GO  
  
-- v2014.12.20  
  
-- 평가손익상품마스터- SS2 조회 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterQuerySub  
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
            @FundSeq    INT,  
            @UMHelpCom  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FundSeq   = ISNULL( FundSeq, 0 ),  
           @UMHelpCom  = ISNULL( UMHelpCom, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FundSeq    INT,
            UMHelpCom  INT 
           )    
    
    -- 최종조회   
    SELECT A.StdDate, 
           A.EvalProfitSeq, 
           Z.MinorName AS UMHelpComName, 
           A.UMHelpCom, 
           A.FundSeq, 
           B.FundName AS FundName, 
           B.FundCode AS FundCode, 
           C.MinorName AS FundKindSName,   
           D.MinorName AS FundKindMName,   
           F.MinorName AS FundKindLName,   
           L.MinorName AS FundKindName,   
           B.TitileName, 
           A.SrtDate, 
           A.DurDate, 
           A.ActAmt,
           A.PrevAmt,
           A.InvestAmt, 
           A.TestAmt, 
           A.AddAmt, 
           A.DiffActDate, 
           A.TagetAdd, 
           A.StdAdd, 
           A.Risk, 
           A.TrustLevel, 
           A.Remark1, 
           A.Remark2, 
           A.Remark3 
    
      FROM KPX_TACEvalProfitItemMaster       AS A 
      LEFT OUTER JOIN KPX_TACFundMaster     AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS Z ON ( Z.CompanySeq = @CompanySeq AND Z.MinorSeq = A.UMHelpCom ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.FundKindS )   
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.FundKindM )   
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 )   
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq )   
      LEFT OUTER JOIN _TDAUMinorValue       AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = F.MinorSeq AND K.Serl = 1000002 )   
      LEFT OUTER JOIN _TDAUMinor            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FundSeq = @FundSeq 
       AND A.UMHelpCom = @UMHelpCom 
     ORDER BY A.StdDate DESC 
    RETURN  