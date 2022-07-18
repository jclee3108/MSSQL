  
IF OBJECT_ID('KPX_SACComCostDivSlipQuery') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipQuery  
GO  
  
-- v2014.11.10  
  
-- 공통활동센터 비용배부 대체전표처리-조회 by 이재천   
CREATE PROC KPX_SACComCostDivSlipQuery  
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
            @CostYM  INT,  
            @AccUnit INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CostYM   = ISNULL( CostYM, 0 ), 
           @AccUnit  = ISNULL( AccUnit, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            CostYM  INT,
            AccUnit INT     
           )
    
    -- 최종조회   
    SELECT A.AllocSeq, 
           A.CostKeySeq, 
           AC.AccSeq, 
           E.AccName, 
           AC.AccSeq AS AccSeq2, 
           E.AccName AS AccName2, 
           SU.AccUnit AS AccUnitSeq, 
           SU.AccUnitName AS AccUnitName, 
           RU.AccUnit AS RecvAccSeq, 
           RU.AccUnitNAme AS RecvAccName, 
           K.CostYM, 
           K.SMCostMng, 
           S.SendCCtrSeq, 
           SC.CCtrName AS SendCCtrName, 
           B.RevCCtrSeq AS RecvCCtrSeq, 
           RC.CCtrNAme AS RecvCCtrName, 
           Z.CostAccSeq, 
           AC.CostAccName,
           Z.Amt AS TgtAmt,
           B.Amt AS RevAmt, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN 0 ELSE B.Amt * (-1) END AS DrAmt, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN 0 ELSE B.Amt * (-1) END  AS CrAmt, 
           C.DriverValue, 
           
           SU.AccUnit AS SendAccUnit2, 
           SU.AccUnitName AS SendAccUnitName2, 
           RU.AccUnit AS RecvAccUnitSeq2, 
           RU.AccUnitNAme AS RecvAccUnitName2, 
           S.SendCCtrSeq AS CCtrSeq2, 
           SC.CCtrName AS CCtrName2, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN 0 ELSE B.Amt END AS DrAmt2, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN 0 ELSE B.Amt END AS CrAmt2, 
           B.Amt AS RevAmt2,
           Z.CostAccSeq AS CostAccSeq2, 
           AC.CostAccName AS CostAccName2, 
           ISNULL(D.InsertKind,'0') AS InsertKind, 
           ISNULL(D.InsertKind,'0') AS InsertKind2, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN D.SlipMstSeq ELSE 0 END AS SlipMstSeq, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN 0 ELSE D.SlipMstSeq END AS SlipMstSeq2, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN D.SlipMstID ELSE '' END AS SlipMstID, 
           CASE WHEN SU.AccUnit = RU.AccUnit THEN '' ELSE D.SlipMstID END AS SlipMstID2 
      FROM _TESMDProdAllocName          AS A WITH(NOLOCK)    
      JOIN _TESMDCostKey                AS K WITH(NOLOCK) ON ( A.CompanySeq = K.CompanySeq AND A.CostKeySeq = K.CostKeySeq ) 
      JOIN _TESMDProdCCtrSend           AS S WITH(NOLOCK) ON ( A.AllocSeq = S.AllocSeq AND A.CompanySEq = S.CompanySeq ) 
      JOIN _TESMCProdComCCtrTgtAmt      AS Z WITH(NOLOCK) ON ( A.AllocSeq = Z.AllocSeq AND A.CompanySeq = Z.CompanySeq ) 
      JOIN _TESMCProdComCCtrRlt         AS B WITH(NOLOCK) ON ( A.AllocSeq = B.AllocSeq AND A.CompanySeq = B.CompanySeq ) 
      JOIN _TESMCProdComCCtrRevAccRate  AS C WITH(NOLOCK) ON ( B.AllocSeq = C.AllocSeq  
                                                           AND A.CompanySeq = C.CompanySeq  
                                                           AND B.RevCCtrSeq = C.RevCCtrSeq  
                                                           AND B.SendCCtrSeq = C.SendCCtrSeq  
                                                           AND B.CostAccSeq = C.CostAccSeq  
                                                             )
      LEFT OUTER JOIN _TDACCtr          AS SC WITH(NOLOCK) ON SC.companySeq = S.CompanySeq AND SC.CctrSeq = S.SendCCtrSeq
      LEFT OUTER JOIN _TDACCtr          AS RC WITH(NOLOCK) ON RC.CompanySeq = B.companySeq AND RC.CCtrSeq = B.RevCCtrSeq
      LEFT OUTER JOIN _TDAAccUnit       AS SU WITH(NOLOCK) ON SU.CompanySeq = SC.CompanySeq AND SU.AccUnit = SC.AccUnit
      LEFT OUTER JOIN _TDAAccUnit       AS RU with(nolock) ON RU.companySeq = RC.CompanySeq AND RU.AccUnit = RC.AccUnit
      LEFT OUTER JOIN _TESMBAccount     AS AC WITH(nolock) ON AC.CompanySeq = Z.companySeq AND AC.CostAccSeq = Z.CostAccseq
      LEFT OUTER JOIN _TDAAccount       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = AC.AccSeq ) 
      OUTER APPLY (SELECT '1' InsertKind, Y.SlipMstSeq, Q.SlipMstID
                     FROM KPX_TACComCostDivSlip AS Y 
                     LEFT OUTER JOIN _TACSlip   AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.SlipMstSeq = Y.SlipMstSeq ) 
                    WHERE Y.CompanySeq = @CompanySeq 
                      AND Y.CostYM = K.CostYM 
                      AND Y.SMCostMng = K.SMCostMng 
                      AND Y.SendCCtrSeq = S.SendCCtrSeq 
                      AND Y.RevCCtrSeq = B.RevCCtrSeq 
                  )AS D 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AccUnit = @AccUnit 
       AND K.CostYM = @CostYM 
    
    RETURN  
GO 
/*
exec KPX_SACComCostDivSlipQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccUnit>1</AccUnit>
    <CostYM>201410</CostYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025697,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021304
*/