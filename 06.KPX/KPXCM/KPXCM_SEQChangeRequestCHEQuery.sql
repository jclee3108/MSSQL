
IF OBJECT_ID('KPXCM_SEQChangeRequestCHEQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestCHEQuery
GO 

-- v2015.06.10 

-- 변경등록-조회 by이재천
CREATE PROC dbo.KPXCM_SEQChangeRequestCHEQuery  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT     = 0,    
    @ServiceSeq     INT     = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT     = 1,    
    @LanguageSeq    INT     = 1,    
    @UserSeq        INT     = 0,    
    @PgmSeq         INT     = 0    
AS  

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
    
    DECLARE @docHandle          INT,  
            @ChangeRequestSeq   INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    
    SELECT @ChangeRequestSeq = ISNULL(ChangeRequestSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (ChangeRequestSeq INT)  
    
    SELECT A.ChangeRequestSeq,  
           A.ChangeRequestNo,  
           A.BaseDate,  
           A.DeptSeq,  
           D.DeptName,   
           A.EmpSeq,  
           E.EmpName,   
           A.Title,  
           A.UMChangeType,  
           H.MinorName          AS UMChangeTypeName,  
           A.UMChangeReson1,  
           R.MinorName          AS UMChangeResonName1,  
           A.UMChangeReson2,  
           U.MinorName          AS UMChangeResonName2,  
           A.UMPlantType,  
           P.MinorName          AS UMPlantTypeName,  
           A.Purpose,  
           A.Remark,  
           A.Effect,  
           A.IsPID, 
           A.IsPFD  ,
           A.IsLayOut,
           A.IsProposal,
           A.IsReport,
           A.IsMinutes,
           A.IsReview,
           A.IsOpinion,
           A.IsDange,
           A.Etc,  
           A.FileSeq,   
           CASE WHEN ISNULL(Q.CfmCode,0) = 0 AND ISNULL(S.IsProg,0) = 0 THEN 1010655001   
                WHEN ISNULL(Q.CfmCode,0) = 5 AND ISNULL(S.IsProg,0) = 1 THEN 1010655002   
                WHEN ISNULL(Q.CfmCode,0) = 1 THEN 1010655003   
                ELSE 0 END AS ProgType,   
           (SELECT TOP 1 MinorName   
              FROM _TDAUMinor   
             WHERE CompanySeq = @CompanySeq   
               AND MinorSeq = (CASE WHEN ISNULL(Q.CfmCode,0) = 0 AND ISNULL(S.IsProg,0) = 0 THEN 1010655001   
                                 WHEN ISNULL(Q.CfmCode,0) = 5 AND ISNULL(S.IsProg,0) = 1 THEN 1010655002   
                                 WHEN ISNULL(Q.CfmCode,0) = 1 THEN 1010655003   
                                 ELSE 0 END  
                              )   
           ) AS ProgTypeName,   
           Q.CfmDate,  
           T.UMJdSeq,  
           T.UMJdName, 
           
           W.UMTarget, 
           X.MinorName AS UMTargetName 
    
      FROM KPXCM_TEQChangeRequestCHE        AS A  
      LEFT OUTER JOIN _TDADept              AS D ON ( D.CompanySeq = A.CompanySeq AND D.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS E ON ( E.CompanySeq = A.CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS H ON ( H.CompanySeq = A.CompanySeq AND H.MinorSeq = A.UMChangeType ) 
      LEFT OUTER JOIN _TDAUMinor            AS R ON ( R.CompanySeq = A.CompanySeq AND R.MinorSeq = A.UMChangeReson1 ) 
      LEFT OUTER JOIN _TDAUMinor            AS U ON ( U.CompanySeq = A.CompanySeq AND U.MinorSeq = A.UMChangeReson2 ) 
      LEFT OUTER JOIN _TDAUMinor            AS P ON ( P.CompanySeq = A.CompanySeq AND P.MinorSeq = A.UMPlantType ) 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.CfmSeq = A.ChangeRequestSeq )   
      LEFT OUTER JOIN _TCOMGroupWare                   AS S ON ( S.CompanySeq = @CompanySeq AND S.WorkKind = 'EQReq_CM' AND S.TblKey = Q.CfmSeq )  
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, CONVERT(NCHAR(8),GETDATE(),112)) AS T ON ( A.EmpSeq = T.EmpSeq ) 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv       AS W ON ( W.CompanySeq = @CompanySeq AND W.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN _TDAUMinor                       AS X ON ( X.CompanySeq = @CompanySeq AND X.MinorSeq = W.UMTarget ) 
             
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ChangeRequestSeq = @ChangeRequestSeq  
    
    RETURN 
GO 
exec KPXCM_SEQChangeRequestCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ChangeRequestSeq>6</ChangeRequestSeq>
    <ChangeRequestNo>CR-D-15-003</ChangeRequestNo>
    <BaseDate>20150612</BaseDate>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030192,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025199