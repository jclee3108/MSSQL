
IF OBJECT_ID('_SPRRetroConditionQueryCHE') IS NOT NULL 
    DROP PROC _SPRRetroConditionQueryCHE
GO 

/*********************************************************************************************************************    
    화면명 : 소급조건별조회  
    작성일 : 2011.06.30 전경만  
********************************************************************************************************************/      
CREATE PROCEDURE _SPRRetroConditionQueryCHE 
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
  
AS         
  
    DECLARE @docHandle          INT,  
            @YM     NCHAR(6),  
            @YMFr    NCHAR(6),  
            @YMTo    NCHAR(6),  
   @BizUnit   INT,  
   @MultiBizUnit  NVARCHAR(MAX),  
   @DeptSeq   INT,  
   @MultiDeptSeq  NVARCHAR(MAX),  
   @EmpSeq    INT,  
   @MultiEmpSeq  NVARCHAR(MAX),  
   @WkTeamSeq   INT,  
   @MultiWkTeamSeq  NVARCHAR(MAX),  
   @WkUnit    INT,  
   @MultiWkUnit  NVARCHAR(MAX),  
   @SMSexSeq   INT,  
   @MultiSMSexSeq  NVARCHAR(MAX),  
   @UMUnionStatus  INT,  
   @MultiUMUnionStatus NVARCHAR(MAX),  
   @PbSeq    INT,  
   @MultiPbSeq   NVARCHAR(MAX),  
   @UMSchCareerSeq  INT,  
   @MultiUMSchCareerSeq NVARCHAR(MAX),  
   @PgSeq    INT,  
   @MultiPgSeq   NVARCHAR(MAX),  
   @BaseDate   NCHAR(8)  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
  
    SELECT  @YM     = ISNULL(YM, ''),  
   @YMFr    = ISNULL(YMFr, ''),  
   @YMTo    = ISNULL(YMTo, ''),  
   @BizUnit   = ISNULL(BizUnit, 0),  
   @MultiBizUnit  = ISNULL(MultiBizUnit, ''),  
   @DeptSeq   = ISNULL(DeptSeq, 0),  
   @MultiDeptSeq  = ISNULL(MultiDeptSeq, ''),  
   @EmpSeq    = ISNULL(EmpSeq, 0),  
   @MultiEmpSeq  = ISNULL(MultiEmpSeq, ''),  
   @WkTeamSeq   = ISNULL(WkTeamSeq, 0),  
   @MultiWkTeamSeq  = ISNULL(MultiWkTeamSeq, ''),  
   @WkUnit    = ISNULL(WkUnit, 0),  
   @MultiWkUnit  = ISNULL(MultiWkUnit, ''),  
   @SMSexSeq   = ISNULL(SMSexSeq, 0),  
   @MultiSMSexSeq  = ISNULL(MultiSMSexSeq, ''),  
   @UMUnionStatus  = ISNULL(UMUnionStatus, 0),  
   @MultiUMUnionStatus = ISNULL(MultiUMUnionStatus, ''),  
   @PbSeq    = ISNULL(PbSeq, 0),  
   @MultiPbSeq   = ISNULL(MultiPbSeq, ''),  
   @UMSchCareerSeq  = ISNULL(UMschCareerSeq, 0),  
   @MultiUMSchCareerSeq = ISNULL(MultiUMSchCareerSeq, ''),  
   @PgSeq    = ISNULL(PgSeq, 0),  
   @MultiPgSeq   = ISNULL(MultiPgSeq, '')  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  YM     NCHAR(6),  
   YMFr    NCHAR(6),  
   YMTo    NCHAR(6),  
   BizUnit    INT,  
   MultiBizUnit  NVARCHAR(MAX),  
   DeptSeq    INT,  
   MultiDeptSeq  NVARCHAR(MAX),  
   EmpSeq    INT,  
   MultiEmpSeq   NVARCHAR(MAX),  
   WkTeamSeq   INT,  
   MultiWkTeamSeq  NVARCHAR(MAX),  
   WkUnit    INT,  
   MultiWkUnit   NVARCHAR(MAX),  
   SMSexSeq   INT,  
   MultiSMSexSeq  NVARCHAR(MAX),  
   UMUnionStatus  INT,  
   MultiUMUnionStatus NVARCHAR(MAX),  
   PbSeq    INT,  
   MultiPbSeq   NVARCHAR(MAX),  
   UMSchCareerSeq  INT,  
   MultiUMSchCareerSeq NVARCHAR(MAX),  
   PgSeq    INT,  
   MultiPgSeq   NVARCHAR(MAX))  
   
 SELECT @BaseDate = CONVERT(NCHAR(8), GETDATE(), 112)  
 IF @YM = ''  
  SELECT @YM = @YMFr  
 IF EXISTS (SELECT Code FROM _FCOMXmlToSeq(@PbSeq, @MultiPbSeq) WHERE Code = 0)  
        SELECT @MultiPbSeq = ''  
     -----------------------------------------------------------    
     -- 가변컬럼 헤더정보    
     -----------------------------------------------------------    
     CREATE TABLE #Temp_TPRPayDeducTitle    
     (    
          ColIDX    INT IDENTITY(0, 1),    
          Title1    NVARCHAR(20)  NULL,    -- 지급&공제구분    
          TitleSeq1 INT           NULL,    -- 급여항목    
          Title2    NVARCHAR(100) NULL,    -- 항목명    
          TitleSeq2 INT           NULL,    -- 급여항목    
          DispSeq   INT           NULL     -- 순서    
      )    
  
   -- 대표 급상여구분, Sub급상여구분   
   -- 합산구분체크되어진 급상여구분만 하나로   
   CREATE TABLE #Pb(PbSeq INT, SubPbSeq INT)  
  
   -- 합산이 아니면 자기자신  
   INSERT INTO  #Pb  
   (PbSeq, SubPbSeq)  
     SELECT A.PbSeq, A.PbSeq  
    FROM _TPRBasPb AS A WITH(NOLOCK)  
   WHERE (1=1)  
     AND A.CompanySeq = @CompanySeq  
     AND (PbSeq IN (SELECT Code FROM _FCOMXmlToSeq(@PbSeq, @MultiPbSeq)) OR @MultiPbSeq =  '')     -- 급상여구분  
     --AND (A.PbSeq = @PbSeq OR @PbSeq = 0 )  
     AND A.SMPbType NOT IN (SELECT MinorSeq  
                             FROM _TDASMinorValue WITH(NOLOCK)  
                           WHERE (1=1)  
                             AND CompanySeq = @CompanySeq  
                             AND MajorSeq = 3001  
                             AND Serl = 1000001  
                             AND ValueText = '1' )  
  
   -- 합산기준(대표급상여구분 코드)  
   INSERT INTO  #Pb  
   (PbSeq, SubPbSeq)  
   SELECT B.PbSeq, A.PbSeq  
    FROM _TPRBasPb AS A WITH(NOLOCK)  
     JOIN (SELECT SMPbType, MIN(PbSeq) AS PbSeq  
           FROM _TPRBasPb  WITH(NOLOCK)  
           WHERE CompanySeq = @CompanySeq  
             AND (PbSeq IN (SELECT Code FROM _FCOMXmlToSeq(@PbSeq, @MultiPbSeq)) OR @MultiPbSeq =  '')     -- 급상여구분  
            --AND (PbSeq = @PbSeq OR @PbSeq = 0 )  
           GROUP BY SMPbType  
          ) B ON (A.SMPbType = B.SMPbType)  
   WHERE (1=1)  
     AND A.CompanySeq = @CompanySeq  
     AND A.SMPbType    IN (SELECT MinorSeq  
                             FROM _TDASMinorValue   
                           WHERE (1=1)  
                             AND CompanySeq = @CompanySeq  
                             AND MajorSeq = 3001  
                             AND Serl = 1000001  
                             AND ValueText = '1' )  
  
         INSERT INTO #Temp_TPRPayDeducTitle      
               (Title1, TitleSeq1, Title2, TitleSeq2, DispSeq)      
         SELECT DISTINCT      
               (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 3005001), --3005001-지급, 3005002-공제      
                3005001,       
                C.ItemName,       
                B.ItemSeq,       
                ISNULL(C.DispSeq, 0)      
           FROM _TPRPayResult AS A WITH(NOLOCK)                 
                JOIN _TPRPayPay AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq      
                                                 AND A.PbYm       = B.PbYM      
                                                 AND A.SerialNo   = B.SerialNo      
                                                 AND A.EmpSeq     = B.EmpSeq      
                LEFT OUTER JOIN _TPRBasPayItem AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq      
                                                                AND B.ItemSeq    = C.ItemSeq      
            WHERE (1=1)  
              AND A.CompanySeq = @CompanySeq  
              AND A.PbSeq IN (SELECT SubPbSeq FROM #Pb)  
              AND (@EmpSeq      =  0 OR A.EmpSeq   = @EmpSeq)    
              AND (@DeptSeq     =  0 OR A.DeptSeq  = @DeptSeq)  
         ORDER BY ISNULL(C.DispSeq, 0), C.ItemName           
    
       INSERT INTO #Temp_TPRPayDeducTitle      
                (Title1, TitleSeq1, Title2, TitleSeq2, DispSeq)      
         SELECT DISTINCT      
               (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 3005002), --3005001-지급, 3005002-공제      
                3005002,       
                C.ItemName,       
                B.ItemSeq,       
                ISNULL(C.DispSeq, 0)      
           FROM _TPRPayResult AS A WITH(NOLOCK)                 
                JOIN _TPRPayDeduc AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                   AND A.PbYm       = B.PbYM  
                                                   AND A.SerialNo   = B.SerialNo  
                                                   AND A.EmpSeq     = B.EmpSeq  
                LEFT OUTER JOIN _TPRBasPayItem AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq  
                                                                AND B.ItemSeq    = C.ItemSeq  
            WHERE (1=1)  
              AND A.CompanySeq = @CompanySeq  
              AND A.PbSeq IN (SELECT SubPbSeq FROM #Pb)  
            AND (@EmpSeq      =  0 OR A.EmpSeq   = @EmpSeq)    
              AND (@DeptSeq     =  0 OR A.DeptSeq  = @DeptSeq)  
         ORDER BY ISNULL(C.DispSeq, 0), C.ItemName        
  
      -- 가변컬럼 헤더정보 출력    
     SELECT A.Title1         AS Title,    
            A.TitleSeq1      AS TitleSeq,    
            A.Title2         AS Title2,    
            A.TitleSeq2      AS TitleSeq2    
       FROM #Temp_TPRPayDeducTitle AS A    
      ORDER BY ColIDX  
  
  
   
  
         
 CREATE TABLE #FixCol(RowIDX INT IDENTITY(0,1),YM NCHAR(6), EmpSeq INT, EmpID NVARCHAR(100), EmpName NVARCHAR(100),   
       DeptName NVARCHAR(100), BizUnitName NVARCHAR(100), Ps NVARCHAR(100), PgName NVARCHAR(100),  
       AccNo NVARCHAR(100), PayBankName NVARCHAR(100), WkTeamName NVARCHAR(100), UMUnionStatus INT,SMSexName NVARCHAR(100),PbSeq INT,PbName NVARCHAR(100),  
      DispSeq INT, MS1 INT, MS2 INT )  
   
 INSERT INTO #FixCol  
 SELECT DISTINCT Z.PbYm   AS YM,  
        Z.EmpSeq,  
        E.Empid   AS EmpID,  
     E.EmpName,  
     D.DeptName,  
     I.BizUnitName,  
     Z.Ps,  
     T.MinorName AS PgName,  
     N.AccNo,  
     B.PayBankName,  
     W.WkTeamName,  
     --R.MinorName   AS UMUnionStatusName,  
           ISNULL(O.UMUnionStatus,3092004) AS UMUnionStatus, -- 노조가입상태( 등록이 안되어 있으면 비가입(3092004))    
     P.SMSexName,  
     Y.PbSeq,  
     (SELECT PbName FROM _TPRBasPb WHERE CompanySeq = @CompanySeq AND PbSeq = Y.PbSeq) AS PbName,  
     J.DispSeq, N1.MinorSort, N2.MinorSort  
   FROM _TPRPayResult     AS Z  
     LEFT OUTER JOIN _TDAEmp   AS E WITH(NOLOCK) ON E.CompanySeq = Z.CompanySeq  
                AND E.EmpSeq = Z.EmpSeq  
     LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, @YM+'01') AS P ON P.EmpSeq = E.EmpSeq  
     LEFT OUTER JOIN _TDADept   AS D WITH(NOLOCK) ON D.CompanySeq = Z.CompanySeq  
              AND D.DeptSeq = Z.DeptSeq  
     LEFT OUTER JOIN _TDABizUnit  AS I WITH(NOLOCK) ON I.CompanySeq = D.CompanySeq  
              AND I.BizUnit = D.BizUnit  
     LEFT OUTER JOIN _TDAUMinor  AS T WITH(NOLOCK) ON T.CompanySeq = Z.CompanySeq  
                AND T.MinorSeq = Z.UMPgSeq  
     LEFT OUTER JOIN _THRBasEmpAccNo AS N WITH(NOLOCK) ON N.CompanySeq = Z.CompanySeq  
               AND N.EmpSeq = Z.EmpSeq  
               AND UMAccNoType = 3098001  
     LEFT OUTER JOIN _THRBasBank  AS B WITH(NOLOCK) ON B.CompanySeq = N.CompanySeq  
              AND B.PayBankSeq = N.PayBankSeq  
     LEFT OUTER JOIN _TPRWkEmpTeam AS K WITH(NOLOCK) ON K.CompanySeq = @CompanySeq AND K.EmpSeq = Z.EmpSeq  
                AND Z.PbYm+'01' BETWEEN K.BegDate AND K.EndDate  --현재일기준      
     LEFT OUTER JOIN _TPRWkTeam  AS W WITH(NOLOCK) ON W.CompanySeq = @CompanySeq AND W.WkTeamSeq = K.WkTeamSeq  
     LEFT OUTER JOIN _TPRWkUnit  AS U WITH(NOLOCK) ON U.CompanySeq = @CompanySeq AND U.WkUnitSeq = W.WkUnitSeq  
     --LEFT OUTER JOIN _THRBasUnion AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq AND O.EmpSeq = Z.EmpSeq  
     --                 AND @BaseDate BETWEEN O.BegDate AND O.EndDate  
           LEFT OUTER JOIN (SELECT EmpSeq, MIN(UMUnionStatus) AS UMUnionStatus-- 가입이 우선    
                              FROM _THRBasUnion WITH(NOLOCK)    
                             WHERE (1=1)    
                               AND CompanySeq = @CompanySeq     
                               AND BegDate <= @BaseDate     
                               AND EndDate >= @BaseDate     
                             GROUP BY EmpSeq ) O ON (Z.EmpSeq = O.EmpSeq)    
     LEFT OUTER JOIN _TDAUMinor AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq AND R.MinorSeq = O.UMUnionStatus  
           LEFT OUTER JOIN _THRBasAcademic AS H WITH(NOLOCK) ON H.CompanySeq   = @CompanySeq  
                                                            AND Z.EmpSeq        = H.EmpSeq    
                                                           AND H.IsLastSchCareer = '1'  --최종학력            
      LEFT OUTER JOIN _TDAUMinor  AS M WITH(NOLOCK)ON I.CompanySeq   = @CompanySeq AND H.UMSchCareerSeq = M.MinorSeq    
           --JOIN _TPRBasPb AS X ON X.CompanySeq = Z.CompanySeq AND Z.PbSeq = X.PbSeq  
           --      AND X.SMPbType NOT IN (3001004,3001005)  
           --      AND X.PbSeq NOT IN(26,27)  
     JOIN #Pb AS Y ON Y.PbSeq = Z.PbSeq AND Y.PbSeq NOT IN(26,27)  
     LEFT OUTER JOIN _TDADept AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq  
                  AND J.DeptSeq = P.DeptSeq  
     LEFT OUTER JOIN _TDAUMinor           AS N1 ON N.CompanySeq = @CompanySeq  
                                                    AND N1.MinorSeq = P.UMPgSeq  
     LEFT OUTER JOIN _TDAUMinor           AS N2 ON N2.CompanySeq = @CompanySeq  
                                                    AND N2.MinorSeq = P.UMJpSeq  
     ---- 사원선택 조회      INNER JOIN _FCOMXmlToSeq(@EmpSeq, @MultiEmpSeq) AS BB ON (ISNULL(Z.EmpSeq,0) = CASE WHEN BB.Code = 0 THEN ISNULL(Z.EmpSeq, 0) ELSE BB.Code END)  
     ---- 부서선택 조회      INNER JOIN _FCOMXmlToSeq(@DeptSeq,  @MultiDeptSeq ) AS EE ON (ISNULL(Z.DeptSeq,0) = CASE WHEN EE.Code = 0 THEN ISNULL(Z.DeptSeq,0) ELSE EE.Code END)   
     ---- 사업부문선택 조회      INNER JOIN _FCOMXmlToSeq(@BizUnit,  @MultiBizUnit ) AS ZZ ON (ISNULL(D.BizUnit,0) = CASE WHEN ZZ.Code = 0 THEN ISNULL(D.BizUnit,0) ELSE ZZ.Code END)   
     ---- 직급선택 조회      INNER JOIN _FCOMXmlToSeq(@PgSeq,  @MultiPgSeq ) AS DD ON (ISNULL(Z.UMPgSeq,0) = CASE WHEN DD.Code = 0 THEN ISNULL(Z.UMPgSeq,0) ELSE DD.Code END)  
     ---- 근태작업군선택 조회      INNER JOIN _FCOMXmlToSeq(@WkTeamSeq, @MultiWkTeamSeq) AS WW ON (ISNULL(W.WkTeamSeq, 0) = CASE WHEN WW.Code = 0 THEN ISNULL(W.WkTeamSeq,0) ELSE WW.Code END)  
     ---- 근무조선택 조회      INNER JOIN _FCOMXmlToSeq(@WkUnit, @MultiWkUnit) AS UU ON (ISNULL(U.WkUnitSeq, 0) = CASE WHEN UU.Code = 0 THEN ISNULL(U.WkUnitSeq,0) ELSE UU.Code END)  
     ---- --노조가입선택 조회      --INNER JOIN _FCOMXmlToSeq(@UMUnionStatus, @MultiUMUnionStatus) AS NN ON (ISNULL(O.UMUnionStatus, 0) = CASE WHEN NN.Code = 0 THEN ISNULL(O.UMUnionStatus,0) ELSE NN.Code END)  
     ---- 학력선택 조회      INNER JOIN _FCOMXmlToSeq(@UMSchCareerSeq,  @MultiUMSchCareerSeq ) AS HH ON (ISNULL(H.UMSchCareerSeq,0) = CASE WHEN HH.Code = 0 THEN ISNULL(H.UMSchCareerSeq,0) ELSE HH.Code END)   
     ------ 급상여구분선택 조회  
     --INNER JOIN _FCOMXmlToSeq(@PbSeq, @MultiPbSeq) AS PP ON (ISNULL(Z.PbSeq,0) = CASE WHEN PP.Code = 0 THEN ISNULL(Z.PbSeq,0) ELSE PP.Code END)  
                 
  WHERE Z.CompanySeq = @CompanySeq  
    AND (@YMFr = '' OR Z.PbYm >= @YMFr)  
    AND (@YMTo = '' OR Z.PbYm <= @YMTo)  
 ORDER BY Z.PbYm, PbName, J.DispSeq, N1.MinorSort, N2.MinorSort, E.EmpID  
  
    SELECT A.YM,  
        A.EmpSeq,  
        A.EmpID,  
     A.EmpName,  
     A.DeptName,  
     A.BizUnitName,  
     A.Ps,  
     A.PgName,  
     A.AccNo,  
     A.PayBankName,  
     A.WkTeamName,  
           A.UMUnionStatus, -- 노조가입상태( 등록이 안되어 있으면 비가입(3092004))    
     A.SMSexName,  
     A.PbSeq,  
     A.PbName,  
     DispSeq, MS1, MS2  
           , U.MinorName AS UMUnionStatusName  
      FROM #FixCol AS A  
           LEFT OUTER JOIN _TDAUMinor AS U WITH(NOLOCK) ON U.CompanySeq = @CompanySeq AND U.MinorSeq = A.UMUnionStatus  
           -- --노조가입선택 조회      INNER JOIN _FCOMXmlToSeq(@UMUnionStatus, @MultiUMUnionStatus) AS NN ON (ISNULL(A.UMUnionStatus, 0) = CASE WHEN NN.Code = 0 THEN ISNULL(A.UMUnionStatus,0) ELSE NN.Code END)  
  
   
    --가변항목 조회  
     CREATE TABLE #PayDeducWkAmt  
     (PbYm     NCHAR(6),  
      PbSeq    INT,  
      EmpSeq   INT,  
      ItemSeq  INT,  
      ItemType INT, -- 지급, 공제, 근태  
      Amt      DECIMAL(19,5)  
     )  
 --_TPRPayPay  
 SELECT C.RowIDX,  
     B.ColIDX,  
     --C.PbSeq,  
     CASE WHEN C.PbSeq = 1 THEN ISNULL(Y1.RetroAmt,0)  
         ELSE ISNULL(A.RetroAmt,0) END AS Amt  
   INTO #Spec  
   FROM _TPRPayPay AS A  
     JOIN _TPRPayResult AS R WITH(NOLOCK) ON R.CompanySeq = A.CompanySeq   
                AND R.EmpSeq = A.EmpSeq  
                AND R.PbYm = A.PbYm  
                AND R.SerialNo = A.SerialNo  
     JOIN (SELECT A.EmpSeq, A.PbYm, SUM(A.Amt) AS Amt, SUM(A.RetroAmt) AS RetroAmt, A.ItemSeq, B.PbSeq  
          FROM _TPRPayPay AS A  
          JOIN _TPRPayResult AS B ON B.CompanySeq = A.CompanySeq AND B.PbYm = A.PbYm AND B.EmpSeq = A.EmpSeq AND B.SerialNo = A.SerialNo  
          JOIN _TPRBasPb AS P ON P.CompanySeq = B.CompanySeq AND P.PbSeq = B.PbSeq AND P.SMPbType = 3001001   
         WHERE A.CompanySeq = @CompanySeq GROUP BY A.EmpSeq, A.PbYm, B.PbSeq, A.ItemSeq) AS Y1 ON Y1.EmpSeq = A.EmpSeq AND Y1.PbYm = A.PbYm AND Y1.ItemSeq = A.ItemSeq AND R.PbSeq = Y1.PbSeq  
  
        JOIN #Temp_TPRPayDeducTitle AS B ON B.TitleSeq2 = A.ItemSeq  
        JOIN #FixCol     AS C ON C.EmpSeq = A.EmpSeq  
           AND C.YM = A.PbYm  
           --AND C.PbSeq = Y1.PbSeq  
     JOIN #Pb AS Y ON Y.PbSeq = R.PbSeq   
  WHERE A.CompanySeq = @CompanySeq  
    AND C.PbSeq = 1  
     -- 고정컬럼 대상자 기준으로 지급내역  
     INSERT INTO #PayDeducWkAmt  
     (PbYm, PbSeq, EmpSeq, ItemSeq, ItemType, Amt)  
     SELECT A.Ym, A.PbSeq, A.EmpSeq, B.ItemSeq, 3005001, B.Amt  
      FROM #FixCol A JOIN   
           (SELECT S.EmpSeq, S.PbYm, T.PbSeq, P.ItemSeq,   
                   SUM(P.RetroAmt) AS Amt  
              FROM _TPRPayResult AS S WITH(NOLOCK) JOIN #Pb T ON (S.PbSeq = T.SubPbSeq)  
                   JOIN _TPRPayPay AS P WITH(NOLOCK) ON (S.CompanySeq = P.CompanySeq  
                                                     AND S.PbYm       = P.PbYm  
                                                     AND S.EmpSeq     = P.EmpSeq   
                                                     AND S.SerialNo   = P.SerialNo )  
             WHERE (1=1)  
                AND S.CompanySeq = @CompanySeq  
                --AND (S.PbYm   >= @BaseYMFr OR @BaseYMFr = '') -- 적용년월  
                --AND (S.PbYm   <= @BaseYMTo OR @BaseYMTo = '') -- 적용년월  
             GROUP BY S.EmpSeq, S.PbYm, T.PbSeq, P.ItemSeq ) B ON (A.EmpSeq = B.EmpSeq  
                                                              AND  A.Ym   = B.PbYm  
                                                              AND  A.PbSeq  = B.PbSeq )  
  
     -- 고정컬럼 대상자기준으로 공제내역  
     INSERT INTO #PayDeducWkAmt  
     (PbYm, PbSeq, EmpSeq, ItemSeq, ItemType, Amt)  
     SELECT A.Ym, A.PbSeq, A.EmpSeq, B.ItemSeq, 3005002, B.Amt  
      FROM #FixCol A JOIN   
           (SELECT S.EmpSeq, S.PbYm, T.PbSeq, P.ItemSeq,   
                   SUM(P.RetroAmt)  AS Amt  
              FROM _TPRPayResult AS S WITH(NOLOCK) JOIN #Pb T ON (S.PbSeq = T.SubPbSeq)  
                   JOIN _TPRPayDeduc AS P WITH(NOLOCK) ON (S.CompanySeq = P.CompanySeq  
                                                       AND S.PbYm       = P.PbYm  
                                                       AND S.EmpSeq     = P.EmpSeq   
                                                       AND S.SerialNo   = P.SerialNo )  
             WHERE (1=1)  
                AND S.CompanySeq = @CompanySeq  
                --AND (S.PbYm   >= @BaseYMFr OR @BaseYMFr = '') -- 적용년월  
                --AND (S.PbYm   <= @BaseYMTo OR @BaseYMTo = '') -- 적용년월  
             GROUP BY S.EmpSeq, S.PbYm, T.PbSeq, P.ItemSeq ) B ON (A.EmpSeq = B.EmpSeq  
                                                              AND  A.Ym   = B.PbYm  
                                                              AND  A.PbSeq  = B.PbSeq )  
  
  
    
    SELECT B.RowIDX   AS RowIDX,  
           A.ColIDX   AS ColIDX,  
           ISNULL(C.Amt,0)      AS Amt  
      FROM #Temp_TPRPayDeducTitle AS A   
           LEFT OUTER JOIN #FixCol AS B ON (1=1)  
           LEFT OUTER JOIN #PayDeducWkAmt C ON (A.TitleSeq2  = C.ItemSeq  
                                       AND A.TitleSeq1  = C.ItemType  
                                       AND B.Ym       = C.PbYm  
                                       AND B.PbSeq      = C.PbSeq   
                                       AND B.EmpSeq     = C.EmpSeq  
                                          )  
     WHERE (1=1)  
    ORDER BY B.RowIDX, A.ColIDX  
 --SELECT * FROM #PayDeducWkAmt ORDER BY RowIDX, ColIDX  
RETURN  