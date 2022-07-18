IF OBJECT_ID('KPXCM_SSEDesasterPrintCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEDesasterPrintCHE
GO

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천  
/************************************************************
  설  명 - 데이터-상해관리_capro : 출력
  작성일 - 20110802
  작성자 - 신용식
 ************************************************************/
  CREATE PROC dbo.KPXCM_SSEDesasterPrintCHE                
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
       @AccidentSeq       INT  
  
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
   SELECT  @AccidentSeq       = AccidentSeq        
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (AccidentSeq        INT )
  
  SELECT  ISNULL(A.EmpSeq, 0)             AS EmpSeq          ,    
             ISNULL(C.EmpName, '')           AS EmpName         ,    
             ISNULL(C.EmpID, '')             AS EmpID           ,
             DATEDIFF(dd, C.EntDate, B.InjuryDate) AS CareerCnt,
             (SELECT COUNT(1) FROM _TSEDesasterCHE WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq AND AccidentSeq <> A.AccidentSeq) AS AccidentCnt,
             ISNULL(C.SMSexName, '')         AS SMSexName       ,    
             ISNULL(A.DeptSeq, 0)            AS DeptSeq         ,    
             ISNULL(D.DeptName, '')          AS DeptName        ,    
             ISNULL(C.PtName, '')            AS PtName           , --정규직 구분    
             ISNULL(E.AcademicName, '')      AS AcademicName    , --최종학벌    
             ISNULL(C.EntDate, '')           AS EntDate          , --입사일    
             ISNULL(C.UMJdName, '')          AS UMJdName        , --직급    
             ISNULL(F.BirthType, '')         AS BirthType       , --생일구분    
             ISNULL(F.BirthDate, '')         AS BirthDate       , --생일    
             ISNULL(A.AccidentSeq, 0)        AS AccidentSeq     ,  
             Y.MinorName                     AS AccidentGradeName ,
             A.AccidentArea                  AS AccidentArea,  
             X.MinorName                     AS AccidentWeatherName     ,
             ISNULL(B.InjurySeq, 0)          AS InjurySeq         ,    
             ISNULL(B.InjuryName, '')        AS InjuryName      ,    
             ISNULL(B.InjuryDate, '')        AS InjuryDate      , 
             ISNULL(LEFT(B.HappenTime,2)+':'+SUBSTRING(B.HappenTime,3,2),'') AS HappenTime  ,
             ISNULL(B.DisasterType, 0)       AS DisasterType    ,    
             ISNULL(G.MinorName, '')         AS DisasterTypeName ,    
             ISNULL(B.RelSftool, 0)          AS RelSftool       ,    
             ISNULL(H.MinorName, '')         AS RelSftoolName    ,    
             ISNULL(B.OperStatus, 0)         AS OperStatus      ,    
             ISNULL(I.MinorName, '')         AS OperStatusName   ,    
             ISNULL(B.Weather, 0)            AS Weather         ,    
             ISNULL(J.MinorName, '')         AS WeatherName      ,    
             ISNULL(B.HappenPlaceName, '')        AS HappenPlaceName     ,    
             --ISNULL(K.MinorName, '')         AS HappenPlaceName  ,    
             ISNULL(B.HappenOpnt, 0)         AS HappenOpnt      ,    
             ISNULL(R.MinorName, '')         AS HappenOpntName   ,    
             ISNULL(B.HappenType, 0)         AS HappenType      ,    
             ISNULL(L.MinorName, '')         AS HappenTypeName   ,    
             ISNULL(B.SimWorkMan, 0)         AS SimWorkMan      ,    
             ISNULL(B.InjuryCauseName, '')        AS InjuryCauseName     ,    
             --ISNULL(M.MinorName, '')         AS InjuryCauseName  ,    
             ISNULL(B.InjuryHrmName, '')          AS InjuryHrmName       ,    
             --ISNULL(N.MinorName, '')         AS InjuryHrmName    ,    
             ISNULL(B.WorkContent, 0)        AS WorkContent     ,    
             ISNULL(O.MinorName, '')         AS WorkContentName  ,    
             ISNULL(B.RelsEqm, '')        AS RelsEqm          ,    
             ISNULL(B.InjuryKind, 0)         AS InjuryKind      ,    
             ISNULL(P.MinorName, '')         AS InjuryKindName   ,    
             ISNULL(B.InjuryPart, 0)         AS InjuryPart      ,    
             ISNULL(Q.MinorName, '')         AS InjuryPartName   ,    
             ISNULL(B.InjuryCnt, 0)          AS InjuryCnt       ,    
             ISNULL(B.CloseDay, 0)           AS CloseDay        ,    
             ISNULL(B.CureDay , 0)           AS CureDay        ,    
             ISNULL(B.NotSftyStatus, 0)      AS NotSftyStatus   ,    
             ISNULL(S.MinorName, '')         AS NotSftyStatusName,    
             ISNULL(B.NotSftyAct, 0)         AS NotSftyAct        ,    
             ISNULL(T.MinorName, '')         AS NotSftyActName ,    
             ISNULL(B.ManageCause, 0)        AS ManageCause       ,    
             ISNULL(U.MinorName, '')         AS  ManageCauseName,    
             ISNULL(B.ReportDate, '')        AS ReportDate       ,    
             ISNULL(B.ReprotUserSeq, 0)      AS ReprotUserSeq    ,    
             ISNULL(V.EmpName, '')           AS ReprotUserName    ,    
             ISNULL(B.surveyFromDate, '')    AS surveyFromDate   ,    
             ISNULL(B.surveyToDate, '')      AS surveyToDate ,    
             ISNULL(B.surveyUserSeq, 0)      AS surveyUserSeq,    
             ISNULL(B.AccidentOutline, '')   AS AccidentOutline ,    
             ISNULL(B.AccidentCause, '')     AS AccidentCause ,    
             ISNULL(B.MngRemark, '')         AS MngRemark ,    
             ISNULL(B.AccidentInjury, '')    AS AccidentInjury ,    
             ISNULL(B.PreventMeasure, '')    AS PreventMeasure ,    
             ISNULL(B.FileSeq, 0)            AS FileSeq,    
             ISNULL(B.IndAcctSubDate, '')    AS IndAcctSubDate ,    
             ISNULL(B.IndAcctApprDate, '')   AS IndAcctApprDate,    
             ISNULL(B.ClosePayReqDate, '')   AS ClosePayReqDate,    
             ISNULL(B.ClosePayReqAmt, 0)     AS ClosePayReqAmt,    
             ISNULL(B.DisCompBlDate, '')     AS DisCompBlDate,    
             ISNULL(B.DisCompBlAmt, 0)       AS DisCompBlAmt,    
             ISNULL(B.DisCompGrade, 0)       AS DisCompGrade,    
             ISNULL(B.HospitalDay, 0)        AS HospitalDay,    
             ISNULL(B.RecuLossAmt, 0)        AS RecuLossAmt,    
             ISNULL(B.IndCloseReAmt, 0)      AS IndCloseReAmt,    
             ISNULL(B.ComCloseReAmt, 0)      AS ComCloseReAmt,    
             ISNULL(B.GSAmt, 0)              AS GSAmt,    
             ISNULL(B.DisRewardAmt, 0)       AS DisRewardAmt,    
             ISNULL(B.ReplacementAmt, 0)     AS ReplacementAmt,    
             ISNULL(B.ProdLossAmt, 0)        AS ProdLossAmt   ,
             ISNULL(W.Remark,'')             AS FileRemark  
       FROM  _TSEAccidentCHE                                          AS A WITH (NOLOCK)    
                        JOIN KPXCM_TSEDesasterCHE                     AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccidentSeq = B.AccidentSeq    
             LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,CONVERT(CHAR(8),GETDATE(),112)) AS C ON A.EmpSeq = C.EmpSeq    
             LEFT OUTER JOIN _TDADept                                                     AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.DeptSeq = D.DeptSeq    
             LEFT OUTER JOIN ( SELECT L1.CompanySeq, L1.EmpSeq, L1.AcademicSeq, L2.MinorName AS AcademicName    
                                FROM _THRBasAcademic            AS L1 WITH(NOLOCK)    
                                     LEFT OUTER JOIN _TDAUMinor AS L2 WITH(NOLOCK) ON L1.CompanySeq     = L2.CompanySeq    
                                                                                  AND L1.UMSchCareerSeq = L2.MinorSeq) AS E ON A.CompanySeq = E.CompanySeq    
                                                                     AND A.EmpSeq     = E.EmpSeq    
             LEFT OUTER JOIN ( SELECT L1.CompanySeq , L1.EmpSeq, (SELECT MinorName    
                                                                   FROM _TDASMinor AS H1    
                                                                   WHERE H1.CompanySeq = L1.CompanySeq    
                                                                     AND H1.MinorSeq   =L2.SMBirthType) BirthType,    
                                      L2.BirthDate    
                                 FROM _TDAEmp                   AS L1    
                                      LEFT OUTER JOIN _tdaempin AS L2 ON L1.CompanySeq = L2.CompanySeq    
                                                                     AND L1.EmpSeq     = L2.EmpSeq    
                              ) AS F ON A.CompanySeq = F.CompanySeq    
                                    AND A.EmpSeq     = F.EmpSeq  
             LEFT OUTER JOIN _TDAUMinor AS G ON B.CompanySeq   = G.CompanySeq    
                                            AND B.DisasterType = G.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS H ON B.CompanySeq   = H.CompanySeq    
                                            AND B.RelSftool    = H.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS I ON A.CompanySeq   = I.CompanySeq    
                                            AND B.OperStatus   = I.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS J ON A.CompanySeq   = J.CompanySeq    
                                            AND B.Weather      = J.MinorSeq    
             --LEFT OUTER JOIN _TDAUMinor AS K ON A.CompanySeq   = K.CompanySeq    
             --                               AND B.HappenPlace  = K.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS L ON A.CompanySeq   = L.CompanySeq    
                                            AND B.HappenType   = L.MinorSeq    
             --LEFT OUTER JOIN _TDAUMinor AS M ON A.CompanySeq   = M.CompanySeq    
             --                               AND B.InjuryCause  = M.MinorSeq    
             --LEFT OUTER JOIN _TDAUMinor AS N ON A.CompanySeq   = N.CompanySeq    
             --                               AND B.InjuryHrm    = N.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS O ON A.CompanySeq   = O.CompanySeq    
                                            AND B.WorkContent  = O.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS P ON A.CompanySeq   = P.CompanySeq    
                                            AND B.InjuryKind   = P.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS Q ON A.CompanySeq   = Q.CompanySeq    
                                            AND B.InjuryPart   = Q.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS R ON A.CompanySeq   = R.CompanySeq    
                                            AND B.HappenOpnt   = R.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS S ON A.CompanySeq   = S.CompanySeq    
                                            AND B.NotSftyStatus= S.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS T ON A.CompanySeq   = T.CompanySeq    
                                            AND B.NotSftyAct   = T.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS U ON A.CompanySeq   = U.CompanySeq    
                                            AND B.ManageCause  = U.MinorSeq    
             LEFT OUTER JOIN _TDAEmp    AS V ON A.CompanySeq   = V.CompanySeq    
                                            AND B.ReprotUserSeq= V.EmpSeq    
             LEFT OUTER JOIN CAPROCommon.dbo._TCAAttachFileData AS W ON B.FileSeq    = W.AttachFileSeq  
             LEFT OUTER JOIN _TDAUMinor AS X WITH(NOLOCK) ON A.CompanySeq    = X.CompanySeq
                                                         AND A.Weather       = X.MinorSeq   
             LEFT OUTER JOIN _TDAUMinor AS Y WITH(NOLOCK) ON A.CompanySeq    = Y.CompanySeq
              AND A.AccidentGrade = Y.MinorSeq                                                                                                           
      WHERE  A.CompanySeq   = @CompanySeq    
        AND  A.AccidentSeq  = @AccidentSeq  
  RETURN