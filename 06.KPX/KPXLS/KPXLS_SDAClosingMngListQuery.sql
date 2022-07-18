IF OBJECT_ID('KPXLS_SDAClosingMngListQuery') IS NOT NULL 
    DROP PROC KPXLS_SDAClosingMngListQuery
GO 

-- v2016.04.11 
-- 모듈마감조회-현황조회 by 이재천 
CREATE PROC KPXLS_SDAClosingMngListQuery
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
            @BizUnit    INT,
            @YM         NCHAR(6)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @BizUnit     = ISNULL(BizUnit, 0),
           @YM          = ISNULL(YM, '')
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit     INT,
            YM          NCHAR(6)
           )    
    
    SELECT @YM              AS YM,
           A.BizUnit,
           A.BizUnitName,
           PU.IsClose       AS PUIsEnd,
           CASE WHEN PU.IsClose = '1' THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = PU.LastUserSeq) 
                ELSE '' END AS PUEmpName,
           CASE WHEN PU.IsClose = '1' THEN PU.LastDateTime  
                ELSE NULL END AS PUDateTime,
           SL.IsClose       AS SLIsEnd,
           CASE WHEN SL.IsClose = '1' THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = SL.LastUserSeq) 
                ELSE '' END AS SLEmpName,
           CASE WHEN SL.IsClose = '1' THEN SL.LastDateTime  
                ELSE NULL END AS SLDateTime,
           PD.IsClose       AS PDIsEnd,
           CASE WHEN PD.IsClose = '1' THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = PD.LastUserSeq) 
                ELSE '' END AS PDEmpName,
           CASE WHEN PD.IsClose = '1' THEN PD.LastDateTime  
                ELSE NULL END AS PDDateTime,
           AC.IsClose       AS ACIsEnd,
           CASE WHEN AC.IsClose = '1' THEN (SELECT UserName FROM _TCAUser WHERE UserSeq = AC.LastUserSeq) 
                ELSE '' END AS ACEmpName,
           CASE WHEN AC.IsClose = '1' THEN AC.LastDateTime  
                ELSE NULL END AS ACDateTime,
           Ma.IsClose       AS MatEnd,
           It.IsClose       AS ItemEnd,
           Si.IsClose       AS SlipEnd
      FROM _TDABizUnit AS A
           LEFT OUTER JOIN _TCOMClosingYM AS PU ON PU.CompanySeq = @CompanySeq
                                               AND PU.ClosingYM = @YM
                                               AND PU.ClosingSeq = 1292
                                               AND PU.UnitSeq = A.BizUnit
                                               --AND PU.DtlUnitSeq = 2
           LEFT OUTER JOIN _TCOMClosingYM AS SL ON SL.CompanySeq = @CompanySeq
                                               AND SL.ClosingYM = @YM
                                               AND SL.ClosingSeq = 62
                                               AND SL.UnitSeq = A.BizUnit
                                               AND SL.DtlUnitSeq = 1                                            
           LEFT OUTER JOIN _TCOMClosingYM AS PD ON PD.CompanySeq = @CompanySeq
                                               AND PD.ClosingYM = @YM
                                               AND PD.ClosingSeq = 1290
                                               AND PD.DtlUnitSeq = 1
                                               --AND PD.UnitSeq = (SELECT FactUnit FROM _TDAFactUnit WHERE CompanySEq = @CompanySEq AND BizUnit = A.BizUnit)
                                               AND A.BizUnit = (SELECT BizUnit FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND FactUnit = PD.UnitSeq)
           LEFT OUTER JOIN _TCOMClosingYM AS AC ON AC.CompanySeq = @CompanySeq
                                               AND AC.ClosingYM = @YM
                                               AND AC.ClosingSeq = 1298
                                               AND AC.DtlUnitseq = 1 
                                               AND AC.UnitSeq = A.AccUnit 
           LEFT OUTER JOIN _TCOMClosingYM AS Ma ON Ma.CompanySeq = @CompanySeq
                                               AND Ma.ClosingYM = @YM
                                               AND Ma.ClosingSeq = 69
                                               AND Ma.DtlUnitseq = 1
                                               AND Ma.UnitSeq = A.BizUnit
           LEFT OUTER JOIN _TCOMClosingYM AS It ON It.CompanySeq = @CompanySeq
                                               AND It.ClosingYM = @YM
                                               AND It.ClosingSeq = 69
                                               AND It.DtlUnitseq = 2
                                               AND It.UnitSeq = A.BizUnit
           LEFT OUTER JOIN _TCOMClosingYM AS Si ON Si.CompanySeq = @CompanySeq
                                               AND Si.ClosingYM = @YM
                                               AND Si.ClosingSeq = 1142
                                               AND Si.DtlUnitseq = 0
                                               AND Si.UnitSeq = A.AccUnit                   
     WHERE A.CompanySeq = @CompanySeq
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
     --GROUP BY LEFT(A.Solar, 6)
    
RETURN
GO


