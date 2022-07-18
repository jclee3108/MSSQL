
IF OBJECT_ID('KPXCM_SEQChangeRequestCHEGWQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestCHEGWQuery
GO 

-- v2015.06.25  
 
-- 변경등록-그룹웨어 조회 by이재천
CREATE PROC dbo.KPXCM_SEQChangeRequestCHEGWQuery  
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
           CASE WHEN A.IsPID = '1' THEN '■' ELSE '□' END + ' P&ID     ' + 
           CASE WHEN A.IsPFD = '1' THEN '■' ELSE '□' END + ' PFD     ' + 
           CASE WHEN A.IsLayOut = '1' THEN '■' ELSE '□' END + ' LayOut' AS Data1, 
           CASE WHEN A.IsProposal = '1' THEN '■' ELSE '□' END + ' 제안서     ' + 
           CASE WHEN A.IsReport = '1' THEN '■' ELSE '□' END + ' 보고서     ' + 
           CASE WHEN A.IsMinutes = '1' THEN '■' ELSE '□' END + ' 회의록 또는 공문(팀장 서명 득)' AS Data2, 
           
           CASE WHEN A.IsReview = '1' THEN '■' ELSE '□' END + ' 변경검토서     ' + 
           CASE WHEN A.IsOpinion = '1' THEN '■' ELSE '□' END + ' 안전보건환경인하가검토의견서     ' + 
           CASE WHEN A.IsDange = '1' THEN '■' ELSE '□' END + ' 위험성평가서' AS Data3, 
           
           '기타 : ' + A.Etc AS Data4, 
           
           REPLACE(REPLACE ( REPLACE ( REPLACE ( (SELECT FileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = A.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</FileName></KPXERPCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><FileName>','!@test!@'
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><FileName>',''
                             ), '</FileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) ,'!@test!@', NCHAR(13))AS RealFileName -- 첨부자료
    
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
EXEC _SCOMGroupWarePrint 2, 1, 1, 1025199, 'EQReq_CM', '15', ''



--select * From _TCAPgm where caption like '%변경%등록%'

--<KPXERPCommon.DBO._TCAAttachFileData><FileName>테스트.txt</FileName></KPXERPCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><FileName>테스트.txt</FileName></KPXERPCommon.DBO._TCAAttachFileData>