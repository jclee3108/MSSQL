  
IF OBJECT_ID('KPX_SACComCostDivSlipDelQuery') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipDelQuery  
GO  
  
-- v2016.01.19  
  
-- 공통활동센터비용배부대체전표삭제-조회 by 이재천 
CREATE PROC KPX_SACComCostDivSlipDelQuery  
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
            @CostYM     NCHAR(6), 
            @AccUnit    INT

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CostYM  = ISNULL( CostYM, '' ), 
           @AccUnit = ISNULL( AccUnit, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            CostYM     NCHAR(6),
            AccUnit    INT      
           )    
    
    -- 최종조회   
    SELECT DISTINCT 
           E.AccUnitName, 
           B.AccUnit, 
           F.SlipUnitName, 
           B.SlipUnit, 
           C.DrAmt, 
           C.CrAmt, 
           B.SlipMstID, 
           A.SMCostMng, 
           A.CostYM, 
           A.SlipMstSeq 
      FROM KPX_TACComCostDivSlip    AS A  
      LEFT OUTER JOIN _TACSlip      AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.SlipMstSeq, SUM(Z.DrAmt) AS DrAmt, SUM(Z.CrAmt) AS CrAmt 
                          FROM _TACSlipRow AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.SlipMstSeq 
                      ) AS C ON ( C.SlipMstSeq = B.SlipMstSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS D ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = A.SendCCtrSeq ) 
      LEFT OUTER JOIN _TDAAccUnit   AS E ON ( E.CompanySeq = @CompanySeq AND E.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TACSlipUnit  AS F ON ( F.CompanySeq = @CompanySeq AND F.SlipUnit = B.SlipUnit ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.CostYM = @CostYM ) 
       AND ( @AccUnit = 0 OR B.AccUnit = @AccUnit )
       AND ( D.UMCostType = CASE WHEN @PgmSeq = 1028501 THEN 4001001 WHEN @PgmSeq = 1028502 THEN 4001002 END ) 
       AND ( B.SlipKind = 1000198 ) 
      
    RETURN  
    