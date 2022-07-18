  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterDataCopy') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterDataCopy  
GO  
  
-- v2014.12.20  
  
-- 평가손익상품마스터- 이전데이터 복사 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterDataCopy  
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
    
    CREATE TABLE #KPX_TACEvalProfitItemMaster( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMaster'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = 'D' 
      FROM #KPX_TACEvalProfitItemMaster AS A 
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACEvalProfitItemMaster')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACEvalProfitItemMaster'    , -- 테이블명        
                  '#KPX_TACEvalProfitItemMaster'    , -- 임시 테이블명        
                  'StdDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    DELETE B
      FROM #KPX_TACEvalProfitItemMaster AS A 
      JOIN KPX_TACEvalProfitItemMaster  AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
    
    DECLARE @MaxStdDate NCHAR(8), 
            @StdDate    NCHAR(8) 
    
    SELECT @MaxStdDate = MAX(ISNULL(StdDate,'')) FROM KPX_TACEvalProfitItemMaster WHERE CompanySeq = @CompanySeq 
    SELECT @StdDate = StdDate FROM #KPX_TACEvalProfitItemMaster 
    
    -- 최종조회   
    SELECT Z.MinorName AS UMHelpComName, 
           A.UMHelpCom, 
           A.FundSeq, 
           B.FundName, 
           B.FundCode, 
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
           DATEDIFF(Day, A.SrtDate, @StdDate) AS DiffActDate, 
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
       AND A.StdDate = @MaxStdDate
    
    RETURN  
    
    
