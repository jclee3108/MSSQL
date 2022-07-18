  
IF OBJECT_ID('KPX_SACBranchSlipOnRegQuery') IS NOT NULL   
    DROP PROC KPX_SACBranchSlipOnRegQuery  
GO  
  
-- v2015.02.25  
  
-- 본지점대체전표생성(건별반제)-조회 by 이재천   
CREATE PROC KPX_SACBranchSlipOnRegQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @SendAccUnit    INT, 
            @AccDateFr      NCHAR(8),  
            @AccDateTo      NCHAR(8), 
            @SMComplete     INT, 
            @RegDeptSeq     INT, 
            @RegEmpSeq      INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SendAccUnit = ISNULL ( SendAccUnit, 0 ), 
           @AccDateFr   = ISNULL(AccDateFr  , '' ),  
           @AccDateTo   = ISNULL(AccDateTo  , '' ),  
           @SMComplete  = ISNULL(SMComplete , 0 ),  
           @RegDeptSeq  = ISNULL(RegDeptSeq , 0 ),  
           @RegEmpSeq   = ISNULL(RegEmpSeq  , 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            SendAccUnit INT, 
            AccDateFr   NCHAR(8), 
            AccDateTo   NCHAR(8), 
            SMComplete  INT, 
            RegDeptSeq  INT, 
            RegEmpSeq   INT
           ) 
    
    SELECT A.AccUnit AS SendAccUnit, 
           G.AccUnitName AS SendAccUnitName, 
           H.SlipMstID, 
           A.SlipID, 
           A.SlipSeq, 
           I.AccName AS CrAccName, 
           I.AccSeq AS CrAccSeq, 
           A.CrAmt, 
           D.CustName AS RemCustName, 
           D.CustSeq AS RemCustSeq, 
           F.AccUnit AS RemAccUnit, 
           F.AccUnitName AS RemAccUnitName, 
           A.Summary AS CrSummary, 
           J.MinorName AS SMCashMethodName, -- 출납방법 
           B.SMCashMethod AS SMCashMethod, -- 출납방법코드
           K.MinorName AS SMInOrOutName, -- 입출금 
           B.SMInOrOut AS SMInOrOut, -- 입출금코드 
           B.CashDate AS CashDate, 
           CASE WHEN ISNULL(BB.SlipSeq,0) = 0 THEN 1039002 ELSE 1039001 END AS SMComplete, 
           CASE WHEN ISNULL(BB.SlipSeq,0) = 0 THEN (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1039002) 
                                             ELSE (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1039001) END AS SMCompleteName, 
           
           EE.AccName AS CNewDrAccName, 
           GG.CustName AS CNewRemCustName, 
           DD.SlipID AS CNewSlipID , 
           DD.SlipSeq AS CNewSlipSeq, 
           HH.AccName AS NewCrAccName, 
           KK.AccName AS NewDrAccName, 
           OO.CustName AS NewDrRemCustName, 
           BB.SlipID AS NewSlipID, 
           BB.SlipSeq AS NewSlipSeq, 
           CC.SlipSeq AS NewCrSlipSeq, 
           PP.SlipMstID AS NewSlipMstID, 
           QQ.SlipMstID AS CNewSlipMstID, 
           RR.AccUnitName AS CNewAccUnitName, 
           SS.AccUnitName AS NewDrRemAccUnitName, 
           JJ.AccUnitName AS NewCrRemAccUnitName
    
      FROM _TACSlipRow              AS A 
      LEFT OUTER JOIN _TACCashOn    AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlipRem   AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = A.SlipSeq AND C.RemSeq = 1017 ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.RemValSeq ) 
      LEFT OUTER JOIN _TACSlipRem   AS E ON ( E.CompanySeq = @CompanySeq AND E.SlipSeq = A.SlipSeq AND E.RemSeq = 1031 ) 
      LEFT OUTER JOIN _TDAAccUnit   AS F ON ( F.CompanySeq = @CompanySeq AND F.AccUnit = E.RemValSeq ) 
      LEFT OUTER JOIN _TDAAccUnit   AS G ON ( G.CompanySeq = @CompanySeq AND G.AccUnit = A.AccUnit ) 
      LEFT OUTER JOIN _TACSlip      AS H ON ( H.CompanySeq = @CompanySeq AND H.SlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS I ON ( I.CompanySeq = @CompanySeq AND I.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.SMCashMethod ) 
      LEFT OUTER JOIN _TDASMinor    AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = B.SMInOrOut ) 
      LEFT OUTER JOIN KPX_TACBranchSlipOnReg AS L ON ( L.CompanySeq = @CompanySeq AND L.SlipSeq = A.SlipSeq ) 
        
      LEFT OUTER JOIN _TACSlipRow AS BB ON ( BB.CompanySeq = @CompanySeq AND BB.SlipSeq = L.NewDrSlipSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS CC ON ( CC.CompanySeq = @CompanySeq AND CC.SlipSeq = L.NewCrSlipSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS DD ON ( DD.CompanySeq = @CompanySeq AND DD.SlipSeq = L.CNewSlipSeq ) 
      LEFT OUTER JOIN _TDAAccount AS EE ON ( EE.CompanySeq = @CompanySeq AND EE.AccSeq = DD.AccSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS FF ON ( FF.CompanySeq = @CompanySeq AND FF.SlipSeq = DD.SlipSeq AND FF.RemSeq = 1017 ) 
      LEFT OUTER JOIN _TDACust    AS GG ON ( GG.CompanySeq = @CompanySeq AND GG.CustSeq = FF.RemValSeq ) 
      LEFT OUTER JOIN _TDAAccount AS HH ON ( HH.CompanySeq = @CompanySeq AND HH.AccSeq = CC.AccSeq ) 
      --LEFT OUTER JOIN _TACSlipRem AS II ON ( II.CompanySeq = @CompanySeq AND II.SlipSeq = CC.SlipSeq AND II.RemSeq = 1031 ) 
      LEFT OUTER JOIN _TDAAccUnit AS JJ ON ( JJ.CompanySeq = @CompanySeq AND JJ.AccUnit = CC.AccUnit ) 
      LEFT OUTER JOIN _TDAAccount AS KK ON ( KK.CompanySeq = @CompanySeq AND KK.AccSeq = BB.AccSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS LL ON ( LL.CompanySeq = @CompanySeq AND LL.SlipSeq = BB.SlipSeq AND LL.RemSeq = 1031 ) 
      LEFT OUTER JOIN _TDAAccUnit AS MM ON ( MM.CompanySeq = @CompanySeq AND MM.AccUnit = LL.RemValSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS NN ON ( NN.CompanySeq = @CompanySeq AND NN.SlipSeq = BB.SlipSeq AND NN.RemSeq = 1017 ) 
      LEFT OUTER JOIN _TDACust    AS OO ON ( OO.CompanySeq = @CompanySeq AND OO.CustSeq = NN.RemValSeq ) 
      LEFT OUTER JOIN _TACSlip    AS PP ON ( PP.CompanySeq = @CompanySeq AND PP.SlipMstSeq = BB.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlip    AS QQ ON ( QQ.CompanySeq = @CompanySeq AND QQ.SlipMstSeq = DD.SlipMstSeq ) 
      LEFT OUTER JOIN _TDAAccUnit AS SS ON ( SS.CompanySeq = @CompanySeq AND SS.AccUnit = PP.AccUnit ) 
      LEFT OUTER JOIN _TDAAccUnit AS RR ON ( RR.CompanySeq = @CompanySeq AND RR.AccUnit = QQ.AccUnit ) 
    
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AccDate BETWEEN @AccDateFr AND @AccDateTo 
       AND A.AccUnit = @SendAccUnit 
       AND ISNULL(A.CrAmt,0) <> 0 
       AND (@SMComplete = 0 OR CASE WHEN ISNULL(BB.SlipSeq,0) = 0 THEN 1039002 ELSE 1039001 END = @SMComplete) 
       AND (NOT EXISTS ( SELECT 1 FROM _TACSlipOff WHERE CompanySeq = @CompanySeq AND OnSlipSeq = A.SlipSeq ) 
            OR EXISTS (SELECT 1 FROM KPX_TACBranchSlipOnReg WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq) 
           )
       AND EXISTS (SELECT 1 FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 30 AND EnvValue = I.AccSeq ) 
     ORDER BY A.SlipSeq 
    
    RETURN  
GO


