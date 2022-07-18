
IF OBJECT_ID('KPXCM_SEQTaskOrderCHEQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHEQuery
GO 
    
-- v2015.06.11    
    
-- 변경기술검토등록-조회 by 이재천     
CREATE PROC KPXCM_SEQTaskOrderCHEQuery    
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
            @TaskOrderSeq  INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @TaskOrderSeq   = ISNULL( TaskOrderSeq, 0 )  
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (TaskOrderSeq   INT)      
      
    -- 최종조회     
    SELECT A.*,   
           K.EmpName AS TaskOrderEmpName, 
           L.DeptName AS TaskOrderDeptName, 
           B.ChangeRequestSeq,   
           B.ChangeRequestNo,   
           B.BaseDate,   
           B.DeptSeq,   
           C.DeptName,   
           B.EmpSeq,    
           D.EmpName,    
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
           
           CASE WHEN ISNULL(I.CfmCode,0) = 0 AND ISNULL(J.IsProg,0) = 0 THEN 1010655001   
             WHEN ISNULL(I.CfmCode,0) = 5 AND ISNULL(J.IsProg,0) = 1 THEN 1010655002   
             WHEN ISNULL(I.CfmCode,0) = 1 THEN 1010655003   
             ELSE 0 END AS TaskOrderProgType,   
             
           (SELECT TOP 1 MinorName   
              FROM _TDAUMinor   
             WHERE CompanySeq = @CompanySeq   
               AND MinorSeq = (CASE WHEN ISNULL(I.CfmCode,0) = 0 AND ISNULL(J.IsProg,0) = 0 THEN 1010655001   
                                 WHEN ISNULL(I.CfmCode,0) = 5 AND ISNULL(J.IsProg,0) = 1 THEN 1010655002   
                                 WHEN ISNULL(I.CfmCode,0) = 1 THEN 1010655003   
                                 ELSE 0 END  
                           )   
           ) AS TaskOrderProgTypeName, 
           
           I.CfmDate AS TaskOrderCfmDate 
           
      FROM KPXCM_TEQTaskOrderCHE AS A   
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq )   
      LEFT OUTER JOIN _TDADept                          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq )   
      LEFT OUTER JOIN _TDAEmp                           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.EmpSeq )   
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm  AS E ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = B.ChangeRequestSeq )   
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType )   
      LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMChangeReson1 )    
      LEFT OUTER JOIN _TDAUMinor                        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = B.UMChangeReson2 )    
      LEFT OUTER JOIN _TDAUMinor                        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMPlantType )   
      LEFT OUTER JOIN _TCOMGroupWare                    AS T ON ( T.CompanySeq = @CompanySeq AND T.WorkKind = 'EQReq_CM' AND T.TblKey = E.CfmSeq )  
      LEFT OUTER JOIN KPXCM_TEQTaskOrderCHE_Confirm      AS I ON ( I.CompanySeq = @CompanySeq AND I.CfmSEq = A.TaskOrderSeq ) 
      LEFT OUTER JOIN _TCOMGroupWare                    AS J ON ( J.CompanySeq = @CompanySeq AND J.WorkKind = 'EQTaskOrder_CM' AND J.TblKey = I.CfmSeq )  
      LEFT OUTER JOIN _TDAEmp                           AS K ON ( K.CompanySeq = @CompanySeq AND K.EmpSeq = A.TaskOrderEmpSeq ) 
      LEFT OUTER JOIN _TDADept                          AS L ON ( L.CompanySeq = @CompanySeq AND L.DeptSeq = A.TaskOrderDeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND ( A.TaskOrderSeq = @TaskOrderSeq )   
    
    RETURN    