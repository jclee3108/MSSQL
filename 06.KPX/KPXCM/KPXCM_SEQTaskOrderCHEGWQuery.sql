
IF OBJECT_ID('KPXCM_SEQTaskOrderCHEGWQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHEGWQuery
GO 
    
-- v2015.06.11    
    
-- 변경기술검토등록-그룹웨어조회 by 이재천     
CREATE PROC KPXCM_SEQTaskOrderCHEGWQuery    
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
           B.Title,   
           B.UMChangeType,   
           ISNULL(F.MinorName  ,'') AS UMChangeTypeName,   
           B.UMChangeReson1,   
           ISNULL(G.MinorName  ,'') AS UMChangeResonName1,   
           B.UMChangeReson2,   
           ISNULL(M.MinorName  ,'') AS UMChangeResonName2,   
           B.Remark,   
           B.Purpose,  
           B.Effect,   
           O.EmpName AS TaskOrderEmpName1, 
           P.EmpName AS TaskOrderEmpName2, 
           Q.EmpName AS TaskOrderEmpName3, 
           R.EmpName AS TaskOrderEmpName4, 
           S.EmpName AS TaskOrderEmpName5, 
           
           CASE WHEN A.IsPID = '1' THEN '■' ELSE '□' END + ' P&ID     ' + 
           CASE WHEN A.IsPFD = '1' THEN '■' ELSE '□' END + ' PFD     ' + 
           CASE WHEN A.IsLayOut = '1' THEN '■' ELSE '□' END + ' LayOut     ' + 
           CASE WHEN A.IsProposal = '1' THEN '■' ELSE '□' END + ' 제안서' AS Data1, 
           
           CASE WHEN A.IsReport = '1' THEN '■' ELSE '□' END + ' 보고서     ' + 
           CASE WHEN A.IsMinutes = '1' THEN '■' ELSE '□' END + ' 회의록 또는 공문(팀장 서명 득)     ' + 
           CASE WHEN A.IsReview = '1' THEN '■' ELSE '□' END + ' 변경검토서     '  AS Data2, 
           CASE WHEN A.IsOpinion = '1' THEN '■' ELSE '□' END + ' 안전보건환경인하가검토의견서     ' + 
           CASE WHEN A.IsDange = '1' THEN '■' ELSE '□' END + ' 위험성평가서     ' + 
           CASE WHEN A.IsMSDS = '1' THEN '■' ELSE '□' END + ' MSDS' AS Data3, 
          
          '기타 : ' + A.Etc AS Data4, 
           
           REPLACE(REPLACE ( REPLACE ( REPLACE ( (SELECT FileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = A.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</FileName></KPXERPCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><FileName>','!@test!@'
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><FileName>',''
                             ), '</FileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) ,'!@test!@', NCHAR(13))AS RealFileName -- 첨부자료
    
           
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
      LEFT OUTER JOIN _TDAEmp                           AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = A.TaskOrderEmpSeq1 ) 
      LEFT OUTER JOIN _TDAEmp                           AS P ON ( P.CompanySeq = @CompanySeq AND P.EmpSeq = A.TaskOrderEmpSeq2 ) 
      LEFT OUTER JOIN _TDAEmp                           AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.EmpSeq = A.TaskOrderEmpSeq3 ) 
      LEFT OUTER JOIN _TDAEmp                           AS R ON ( R.CompanySeq = @CompanySeq AND R.EmpSeq = A.TaskOrderEmpSeq4 ) 
      LEFT OUTER JOIN _TDAEmp                           AS S ON ( S.CompanySeq = @CompanySeq AND S.EmpSeq = A.TaskOrderEmpSeq5 ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND ( A.TaskOrderSeq = @TaskOrderSeq )   
    
    RETURN    
    go
    exec KPXCM_SEQTaskOrderCHEGWQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <TaskOrderSeq>8</TaskOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030226,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025227


--select * From _TCAPgm where caption like '%기술검토%'