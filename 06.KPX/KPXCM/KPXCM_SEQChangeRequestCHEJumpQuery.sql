
IF OBJECT_ID('KPXCM_SEQChangeRequestCHEJumpQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestCHEJumpQuery
GO 

-- v2015.06.12 

-- 변경등록-점프조회 by이재천
CREATE PROC dbo.KPXCM_SEQChangeRequestCHEJumpQuery  
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
    
    
    IF EXISTS (SELECT 1 FROM KPXCM_TEQChangeRequestRecv WHERE CompanySeq = @CompanySeq AND ChangeRequestSeq = @ChangeRequestSeq ) 
    BEGIN 
        SELECT '이미 진행 된 데이터입니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
               
    END 
    --ELSE IF (SELECT CfmCode FROM KPXCM_TEQChangeRequestCHE_Confirm WHERE CompanySeq = @CompanySeq AND CfmSeq = @ChangeRequestSeq) <> 1 
    --BEGIN
    --    SELECT '확정되지 않은 데이터입니다.' AS Result, 
    --           1234 AS Status, 
    --           1234 AS MessageType 
    --END 
    ELSE
    BEGIN 
    
        
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
               X.MinorName AS UMTargetName, 
               0 AS Status 
        
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
    END 
    
    RETURN 
GO 
exec KPXCM_SEQChangeRequestCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ChangeRequestNo>CR-D-15-002</ChangeRequestNo>
    <BaseDate>20150610</BaseDate>
    <ChangeRequestSeq>5</ChangeRequestSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030192,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025207