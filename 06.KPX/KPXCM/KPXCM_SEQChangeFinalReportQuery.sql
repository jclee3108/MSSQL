  
IF OBJECT_ID('KPXCM_SEQChangeFinalReportQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQChangeFinalReportQuery  
GO  
  
-- v2015.06.12  
  
-- 변경실행결과등록-조회 by 이재천     
CREATE PROC KPXCM_SEQChangeFinalReportQuery      
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
    
    DECLARE @docHandle          INT,      
            -- 조회조건       
            @FinalReportSeq     INT    
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
      
    SELECT @FinalReportSeq   = ISNULL( FinalReportSeq, 0 )    
          
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )           
      WITH (FinalReportSeq   INT)        
    
    -- 최종조회       
    SELECT A.FinalReportSeq, 
           A.FinalReportDate, 
           A.ResultDateFr, 
           A.ResultDateTo, 
           A.FinalReportDeptSeq, 
           A.ResultRemark, 
           C.DeptName AS FinalReportDeptName, 
           A.FinalReportEmpSeq, 
           D.EmpName AS FinalReportEmpName, 
           A.IsPID AS IsFinalPID, 
           A.IsPFD AS IsFinalPFD, 
           A.IsLayOut AS IsFinalLayOut, 
           A.IsProposal AS IsFinalProposal, 
           A.IsReport AS IsFinalReport, 
           A.IsMinutes AS IsFinalMinutes, 
           A.IsReview AS IsFinalReview, 
           A.IsOpinion AS IsFinalOpinion, 
           A.IsDange AS IsFinalDange, 
           A.IsMSDS AS IsFinalMSDS, 
           A.IsCheckList, 
           A.IsResultCheck, 
           A.IsEduJoin, 
           A.IsSkillReport, 
           A.Etc AS FinalEtc, 
           A.FileSeq, 
           A.ChangeRequestSeq, 
           B.ChangeRequestNo,     
           B.BaseDate,     
           B.DeptSeq,     
           O.DeptName,     
           B.EmpSeq,      
           Q.EmpName,      
           ISNULL(E.CfmDate  ,'') AS CfmDate,     
           B.Title,     
           B.UMChangeType,     
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName,     
           B.UMChangeReson1,     
           ISNULL(G.MinorName  ,'') AS UMChangeResonName1,     
           B.UMChangeReson2,     
           ISNULL(M.MinorName  ,'') AS UMChangeResonName2,     
           B.UMPlantType,     
           ISNULL(H.MinorName  ,'') AS UMPlantTypeName,     
           B.Remark,     
           B.Purpose,    
           B.Effect,     
           B.FileSeq AS ReqFileSeq, 
           
           CASE WHEN ISNULL(E.CfmCode,0) = 0 AND ISNULL(T.IsProg,0) = 0 THEN 1010655001     
             WHEN ISNULL(E.CfmCode,0) = 5 AND ISNULL(T.IsProg,0) = 1 THEN 1010655002     
             WHEN ISNULL(E.CfmCode,0) = 1 THEN 1010655003     
             ELSE 0 END AS ProgType,     
           (SELECT TOP 1 MinorName     
              FROM _TDAUMinor     
             WHERE CompanySeq = @CompanySeq     
               AND MinorSeq = (CASE WHEN ISNULL(E.CfmCode,0) = 0 AND ISNULL(T.IsProg,0) = 0 THEN 1010655001     
                                 WHEN ISNULL(E.CfmCode,0) = 5 AND ISNULL(T.IsProg,0) = 1 THEN 1010655002     
                                 WHEN ISNULL(E.CfmCode,0) = 1 THEN 1010655003     
                                 ELSE 0 END    
                           )     
           ) AS ProgTypeName,     
           E.CfmDate, 
           
           I.IsPID, 
           I.IsPFD, 
           I.IsLayOut, 
           I.IsProposal, 
           I.IsReport, 
           I.IsMinutes, 
           I.IsReview, 
           I.IsOpinion, 
           I.IsDange, 
           I.IsMSDS, 
           I.Etc, 
           I.FileSeq AS SubFileSeq

             
      FROM KPXCM_TEQChangeFinalReport AS A 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm  AS E ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = B.ChangeRequestSeq )     
      LEFT OUTER JOIN _TCOMGroupWare                    AS T ON ( T.CompanySeq = @CompanySeq AND T.WorkKind = 'EQReq_CM' AND T.TblKey = E.CfmSeq )   
      LEFT OUTER JOIN _TDADept                          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.FinalReportDeptSeq ) 
      LEFT OUTER JOIN _TDAEmp                           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.FinalReportEmpSeq ) 
      LEFT OUTER JOIN _TDADept                          AS O ON ( O.CompanySeq = @CompanySeq AND O.DeptSeq = B.DeptSeq )     
      LEFT OUTER JOIN _TDAEmp                           AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.EmpSeq = B.EmpSeq )           
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType )     
      LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMChangeReson1 )      
      LEFT OUTER JOIN _TDAUMinor                        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = B.UMChangeReson2 )      
      LEFT OUTER JOIN _TDAUMinor                        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMPlantType )   
      LEFT OUTER JOIN KPXCM_TEQTaskOrderCHE             AS I ON ( I.CompanySeq = @CompanySeq AND I.ChangeRequestSeq = B.ChangeRequestSeq ) 
     WHERE A.CompanySeq = @CompanySeq      
       AND ( A.FinalReportSeq = @FinalReportSeq )     
      
      RETURN     