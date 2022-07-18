
IF OBJECT_ID('KPXCM_SEQChangeRequestReceiptCHEJumpQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestReceiptCHEJumpQuery
GO 
    
-- v2015.06.15  
    
-- 변경접수등록-점프조회 by 이재천     
CREATE PROC KPXCM_SEQChangeRequestReceiptCHEJumpQuery    
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
    
    DECLARE @docHandle              INT,    
            -- 조회조건     
            @ChangeRequestRecvSeq   INT, 
            @ChangeRequestSeq       INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @ChangeRequestRecvSeq   = ISNULL( ChangeRequestRecvSeq, 0 )  
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (ChangeRequestRecvSeq   INT)      
    
    
    SELECT @ChangeRequestSeq = (SELECT ChangeRequestSeq FROM KPXCM_TEQChangeRequestRecv WHERE CompanySeq = @CompanySeq AND ChangeRequestRecvSeq = @ChangeRequestRecvSeq) 

    IF EXISTS (SELECT 1 FROM KPXCM_TEQTaskOrderCHE WHERE CompanySeq = @CompanySeq AND ChangeRequestSeq = @ChangeRequestSeq ) 
    BEGIN 
        SELECT '이미 진행 된 데이터입니다.' AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
               
    END 
    --ELSE IF (SELECT CfmCode FROM KPXCM_TEQChangeRequestRecv_Confirm WHERE CompanySeq = @CompanySeq AND CfmSeq = @ChangeRequestRecvSeq) <> 1 
    --BEGIN
    --    SELECT '확정되지 않은 데이터입니다.' AS Result, 
    --           1234 AS Status, 
    --           1234 AS MessageType 
    --END 
    ELSE
    BEGIN 
        -- 최종조회     
        SELECT 0 AS Status, 
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
                               )   ) AS ProgTypeName,   
               E.CfmDate, 
               B.FileSeq AS ReqRileSeq 
          
          FROM KPXCM_TEQChangeRequestRecv AS A 
          LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ChangeRequestSeq = A.ChangeRequestSeq )   
          LEFT OUTER JOIN _TDADept                          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq )   
          LEFT OUTER JOIN _TDAEmp                           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = B.EmpSeq )   
          LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm  AS E ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = B.ChangeRequestSeq )   
          LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = B.UMChangeType )   
          LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMChangeReson1 )    
          LEFT OUTER JOIN _TDAUMinor                        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = B.UMChangeReson2 )    
          LEFT OUTER JOIN _TDAUMinor                        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMPlantType )   
          LEFT OUTER JOIN _TCOMGroupWare                    AS T ON ( T.CompanySeq = @CompanySeq AND T.WorkKind = 'EQReq_CM' AND T.TblKey = E.CfmSeq )  
         WHERE A.CompanySeq = @CompanySeq    
           AND ( A.ChangeRequestRecvSeq = @ChangeRequestRecvSeq )   
    END 
    RETURN    
GO
exec KPXCM_SEQChangeRequestReceiptCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ChangeRequestRecvSeq>4</ChangeRequestRecvSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030211,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025229