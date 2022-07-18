IF OBJECT_ID('KPXCM_SACBizTripCostRegQuery') IS NOT NULL 
    DROP PROC KPXCM_SACBizTripCostRegQuery
GO 

-- v2015.09.24 

-- 출장상신(조회) by이재천   Save As
 /************************************************************
  설  명 - 데이터-일반증빙상신_kpx : 조회
  작성일 - 20150811
  작성자 - 민형준
 ************************************************************/
  CREATE PROC dbo.KPXCM_SACBizTripCostRegQuery                
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS        
  
    DECLARE @docHandle      INT,
            @AccUnit        INT ,
            @DeptSeq        INT ,
            @ToDate         NCHAR(8) ,
            @FrDate         NCHAR(8) ,
            @SMSlipProc     INT ,
            @EmpSeq         INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
   SELECT @AccUnit      = ISNULL(AccUnit,0), 
          @DeptSeq      = ISNULL(DeptSeq,0), 
          @ToDate       = ISNULL(ToDate,''), 
          @FrDate       = ISNULL(FrDate,''), 
          @SMSlipProc   = ISNULL(SMSlipProc,0), 
          @EmpSeq       = ISNULL(EmpSeq,0)
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (
            AccUnit          INT ,
            DeptSeq          INT ,
            ToDate           NCHAR(8) ,
            FrDate           NCHAR(8) ,
            SMSlipProc       INT ,
            EmpSeq           INT 
         )
  
    IF @FrDate = '' SELECT @FrDate = '19000101'
    IF @ToDate = '' SELECT @ToDate = '29991231' 
    
    SELECT  
             A.Seq,
             A.AccUnit,
             A.CostDate,
             A.CostAccSeq,
             A.CostAccSeq AS CostAccSeqOld,
             A.Amt,
             A.DeptSeq,
             A.EmpSeq,
             A.CCtrSeq,
             A.RemSeq,
             A.RemValSeq,
             A.UMCostType,
             A.Remark,
             A.OppAccSeq,
             A.CashDate,
             A.SlipSeq,
             B.AccName AS CostAccName,
             C.AccName AS OppAccName,
             D.DeptName,
             E.EmpName,
             F.MinorName AS UMCostTypeName,
             G.SlipID,
             H.RemName,
             I.RemValueName AS RemValue,
             J.CCtrName,
             CASE WHEN ISNULL(G.SlipID,'') <> '' THEN '1' ELSE '' END AS IsSlip,
             ISNULL(H.CodeHelpSeq   , 0) AS MCodeHelpSeq    ,
             ISNULL(H.CodeHelpParams, '') AS MCodeHelpParams           
       FROM  KPXCM_TACBizTripCostReg AS A WITH (NOLOCK) 
             LEFT OUTER JOIN _TDAAccount AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                          AND A.CostAccSeq   = B.AccSeq
             LEFT OUTER JOIN _TDAAccount AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                          AND A.OppAccSeq   = C.AccSeq  
             LEFT OUTER JOIN _TDADept    AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                          AND A.DeptSeq      = D.DeptSeq
             LEFT OUTER JOIN _TDAEmp     AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                                                          AND A.EmpSeq       = E.EmpSeq                                                       
             LEFT OUTER JOIN _TDAUMinor AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq
                                                         AND A.UMCostType = F.MinorSeq
             LEFT OUTER JOIN _TACSlipRow AS G WITH(NOLOCK) ON A.CompanySeq= G.CompanySeq
                                                          AND A.SlipSeq   = G.SlipSeq
             LEFT OUTER JOIN _TDAAccountRem AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq
                                                             AND A.RemSeq     = H.RemSeq
             LEFT OUTER JOIN _TDAAccountRemValue AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq
                                        AND A.RemSeq   = I.RemSeq
             AND A.RemValSeq = I.RemValueSerl
             LEFT OUTER JOIN _TDACCtr    AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq
                                                          AND A.CCtrSeq      = J.CCtrSeq                                                         
     WHERE A.CompanySeq = @CompanySeq
       AND (@AccUnit = 0 OR A.AccUnit          = @AccUnit)
       AND (@DeptSeq = 0 OR A.DeptSeq          = @DeptSeq)         
       AND A.CostDate         BETWEEN @FrDate AND @ToDate          
       AND (@SMSlipProc = 0 
            OR (@SMSlipProc = 1039001 AND ISNULL(G.SlipSeq,0) <> 0)
            OR (@SMSlipProc = 1039002 AND ISNULL(G.SlipSeq,0) = 0)
           )
       AND (@EmpSeq = 0 OR A.EmpSeq           = @EmpSeq)  
  RETURN