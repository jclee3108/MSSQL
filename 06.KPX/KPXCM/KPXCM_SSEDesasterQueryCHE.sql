IF OBJECT_ID('KPXCM_SSEDesasterQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEDesasterQueryCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천 
    
/************************************************************    
  설  명 - 데이터-상해관리_capro : 조회    
  작성일 - 20110325    
  작성자 - 박헌기    
 ************************************************************/    
 CREATE PROC KPXCM_SSEDesasterQueryCHE    
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT             = 0,    
     @ServiceSeq     INT             = 0,    
     @WorkingTag     NVARCHAR(10)    = '',    
     @CompanySeq     INT             = 1,    
     @LanguageSeq    INT             = 1,    
     @UserSeq        INT             = 0,    
     @PgmSeq         INT             = 0    
 AS    
     
     DECLARE @docHandle      INT,    
             @AccidentSeq      INT    
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
     
     SELECT  @AccidentSeq      = AccidentSeq    
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
       WITH  (AccidentSeq       INT )    
     
     SELECT  A.EmpSeq           ,    
             C.EmpName          ,    
             C.SMSexName        ,    
             A.DeptSeq          ,    
             D.DeptName         ,    
             C.PtName           , --정규직 구분    
             E.AcademicName     , --최종학벌    
             C.EntDate          , --입사일    
             C.UMJdName         , --직급    
             F.BirthType        , --생일구분    
             F.BirthDate        , --생일    
             A.AccidentSeq      ,    
             B.InjurySeq        ,    
             B.InjuryName       ,    
             B.InjuryDate       ,    
             B.HappenTime       ,    
             B.DisasterType     ,    
             G.MinorName AS DisasterTypeName ,    
             B.RelSftool        ,    
             H.MinorName AS RelSftoolName    ,    
             B.OperStatus       ,    
             I.MinorName AS OperStatusName   ,    
             B.Weather          ,    
             J.MinorName AS WeatherName      ,    
             B.HappenPlaceName      ,    
             --K.MinorName AS HappenPlaceName  ,    
             B.HappenOpnt       ,    
             R.MinorName AS HappenOpntName   ,    
             B.HappenType       ,    
             L.MinorName AS HappenTypeName   ,    
             B.SimWorkMan       ,    
             B.InjuryCauseName      ,    
             --M.MinorName AS InjuryCauseName  ,    
             B.InjuryHrmName        ,    
             --N.MinorName AS InjuryHrmName    ,    
             B.WorkContent      ,    
             O.MinorName AS WorkContentName  ,    
             B.RelsEqm          ,    
             B.InjuryKind       ,    
             P.MinorName AS InjuryKindName   ,    
             B.InjuryPart       ,    
             Q.MinorName AS InjuryPartName   ,    
             B.InjuryCnt        ,    
             B.CloseDay         ,    
             B.CureDay          ,    
             B.NotSftyStatus    ,    
             S.MinorName AS NotSftyStatusName,    
             B.NotSftyAct         ,    
             T.MinorName AS NotSftyActName ,    
             B.ManageCause        ,    
             U.MinorName AS  ManageCauseName,    
             B.ReportDate       ,    
             B.ReprotUserSeq    ,    
             V.EmpName AS ReprotUserName    ,    
             B.surveyFromDate   ,    
             B.surveyToDate     ,    
             B.surveyUserSeq    ,    
             B.AccidentOutline  ,    
             B.AccidentCause    ,    
             B.MngRemark        ,    
             B.AccidentInjury   ,    
             B.PreventMeasure   ,    
             B.FileSeq          ,    
             B.IndAcctSubDate   ,    
             B.IndAcctApprDate  ,    
             B.ClosePayReqDate  ,    
             B.ClosePayReqAmt   ,    
             B.DisCompBlDate    ,    
             B.DisCompBlAmt     ,    
             B.DisCompGrade     ,    
             B.HospitalDay      ,    
             B.RecuLossAmt      ,    
             B.IndCloseReAmt    ,    
             B.ComCloseReAmt ,    
             B.GSAmt            ,    
             B.DisRewardAmt     ,    
             B.ReplacementAmt   ,    
             B.ProdLossAmt    
       FROM  _TSEAccidentCHE                                          AS A WITH (NOLOCK)    
             LEFT OUTER JOIN KPXCM_TSEDesasterCHE                     AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccidentSeq = B.AccidentSeq    
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
             LEFT OUTER JOIN _TDASMinor AS G ON A.CompanySeq   = G.CompanySeq    
                                            AND B.DisasterType = G.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS H ON A.CompanySeq   = H.CompanySeq    
                                            AND B.RelSftool    = H.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS I ON A.CompanySeq   = I.CompanySeq    
                                            AND B.OperStatus   = I.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS J ON A.CompanySeq   = J.CompanySeq    
                                            AND B.Weather      = J.MinorSeq    
             --LEFT OUTER JOIN _TDASMinor AS K ON A.CompanySeq   = K.CompanySeq    
             --                               AND B.HappenPlace  = K.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS L ON A.CompanySeq   = L.CompanySeq    
                                            AND B.HappenType   = L.MinorSeq    
             --LEFT OUTER JOIN _TDASMinor AS M ON A.CompanySeq   = M.CompanySeq    
             --                               AND B.InjuryCause  = M.MinorSeq    
             --LEFT OUTER JOIN _TDASMinor AS N ON A.CompanySeq   = N.CompanySeq    
             --                               AND B.InjuryHrm    = N.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS O ON A.CompanySeq   = O.CompanySeq    
                                            AND B.WorkContent  = O.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS P ON A.CompanySeq   = P.CompanySeq    
                                            AND B.InjuryKind   = P.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS Q ON A.CompanySeq   = Q.CompanySeq    
                                            AND B.InjuryPart   = Q.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS R ON A.CompanySeq   = R.CompanySeq    
                                            AND  B.HappenOpnt   = R.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS S ON A.CompanySeq   = S.CompanySeq    
                                         AND B.NotSftyStatus= S.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS T ON A.CompanySeq   = T.CompanySeq    
                                            AND B.NotSftyAct   = T.MinorSeq    
             LEFT OUTER JOIN _TDASMinor AS U ON A.CompanySeq   = U.CompanySeq    
                                            AND B.ManageCause  = U.MinorSeq    
             LEFT OUTER JOIN _TDAEmp    AS V ON A.CompanySeq   = V.CompanySeq    
                                            AND B.ReprotUserSeq= V.EmpSeq    
      WHERE  A.CompanySeq   = @CompanySeq    
        AND  A.AccidentSeq  = @AccidentSeq    
        AND  A.AccidentSerl = '1'    
     
     
     RETURN