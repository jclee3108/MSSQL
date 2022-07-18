
IF OBJECT_ID('KPXCM_SEQChangeRequestReceiptListCHEGWQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestReceiptListCHEGWQuery
GO 

/************************************************************
 설  명 - 데이터-변경접수조회-KPXCM : 조회
 작성일 - 20150611
 작성자 - 박상준
 수정자 - 
************************************************************/

CREATE PROC dbo.KPXCM_SEQChangeRequestReceiptListCHEGWQuery                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    DECLARE @docHandle              INT,
            @ChangeRequestRecvSeq   INT 
 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @ChangeRequestRecvSeq = ISNULL(ChangeRequestRecvSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ChangeRequestRecvSeq    INT)
   
   SELECT A.CompanySeq,
		  A.ChangeRequestSeq,
		  A.ChangeRequestRecvSeq,
		  A.UMTarget,
		  C.MinorName				AS UMTargetName,
		  A.RecvDate,
		  A.DeptSeq					AS RecvDeptSeq,
		  D.DeptName				AS RecvDeptName,
		  A.EmpSeq					AS RecvEmpSeq,
		  E.EmpName					AS RecvEmpName,
		  A.Remark					AS RecvRemark,
		  B.BaseDate,
		  B.DeptSeq,
		  J.DeptName,
		  B.EmpSeq,
		  K.EmpName,
		  B.Title,
		  B.UMPlantType,
		  F.MinorName				AS UMPlantTypeName,
		  B.UMChangeType,
		  G.MinorName				AS UMChangeTypeName,
		  B.UMChangeReson1,
		  H.MinorName				AS UMChangeReson1Name,
		  B.UMChangeReson2,
		  I.MinorName				AS UMChangeReson2Name,
		  B.Purpose,
		  B.Remark,
		  B.Effect,
		  B.IsPID,
		  B.IsPFD,
		  B.IsLayOut,
		  B.IsProposal,
		  B.IsReport,
		  B.IsMinutes,
		  B.IsReview,
		  B.IsOpinion,
		  B.IsDange,
		  B.Etc,
		  B.FileSeq,
		  L.CfmDate 				  AS RecvCfmDate,
		  B.ChangeRequestNo,
          CASE WHEN B.IsPID = '1' THEN '■' ELSE '□' END + ' P&ID     ' + 
          CASE WHEN B.IsPFD = '1' THEN '■' ELSE '□' END + ' PFD     ' + 
          CASE WHEN B.IsLayOut = '1' THEN '■' ELSE '□' END + ' LayOut' AS Data1, 
          CASE WHEN B.IsProposal = '1' THEN '■' ELSE '□' END + ' 제안서     ' + 
          CASE WHEN B.IsReport = '1' THEN '■' ELSE '□' END + ' 보고서     ' + 
          CASE WHEN B.IsMinutes = '1' THEN '■' ELSE '□' END + ' 회의록 또는 공문(팀장 서명 득)' AS Data2, 
          CASE WHEN B.IsReview = '1' THEN '■' ELSE '□' END + ' 변경검토서     ' + 
          CASE WHEN B.IsOpinion = '1' THEN '■' ELSE '□' END + ' 안전보건환경인하가검토의견서     ' + 
          CASE WHEN B.IsDange = '1' THEN '■' ELSE '□' END + ' 위험성평가서' AS Data3, 
          
          '기타 : ' + B.Etc AS Data4, 
          
          REPLACE(REPLACE ( REPLACE ( REPLACE ( (SELECT FileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = B.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</FileName></KPXERPCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><FileName>','!@test!@'
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><FileName>',''
                             ), '</FileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) ,'!@test!@', NCHAR(13))AS RealFileName -- 첨부자료
    
   FROM KPXCM_TEQChangeRequestRecv AS A
   LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv_Confirm AS A1 WITH(NOLOCK) ON A1.CompanySeq = @CompanySeq
																		AND A1.CfmSeq	  = ChangeRequestRecvSeq
   LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE AS B WITH(NOLOCK) ON B.CompanySeq			=	@CompanySeq
															  AND B.ChangeRequestSeq	=	A.ChangeRequestSeq
   LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm AS B1 WITH(NOLOCK) ON B1.CompanySeq = @CompanySeq
																	   AND B1.CfmSeq	 = B.ChangeRequestSeq
   LEFT OUTER JOIN _TDAUMinor		AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
													 AND C.MinorSeq  = UMTarget
   LEFT OUTER JOIN _TDADept			AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
													 AND D.DeptSeq	  = A.DeptSeq
   LEFT OUTER JOIN _TDAEmp			AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
													 AND E.EmpSeq	  = A.EmpSeq
   LEFT OUTER JOIN _TDAUMinor		AS F WITH(NOLOCK) ON F.CompanySeq = @CompanySeq
													 AND F.MinorSeq	  = B.UMPlantType
   LEFT OUTER JOIN _TDAUMinor		AS G WITH(NOLOCK) ON G.CompanySeq = @CompanySeq
													 AND G.MinorSeq	  = UMChangeType
   LEFT OUTER JOIN _TDAUMinor		AS H WITH(NOLOCK) ON H.CompanySeq = @CompanySeq
													 AND H.MinorSeq	  = B.UMChangeReson1
   LEFT OUTER JOIN _TDAUMinor		AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
													 AND I.MinorSeq	  = B.UMChangeReson2
   LEFT OUTER JOIN _TDADept			AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq
													 AND J.DeptSeq	  = B.DeptSeq
   LEFT OUTER JOIN _TDAEmp			AS K WITH(NOLOCK) ON K.CompanySeq = @CompanySeq
													 AND K.EmpSeq	  = B.EmpSeq
   LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv_Confirm	AS L WITH(NOLOCK) ON L.CompanySeq = @CompanySeq
																		 AND L.CfmSeq	  = A.ChangeRequestSeq
   LEFT OUTER JOIN _TComGroupWare	AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq
													 AND M.TblKey	  = A.ChangeRequestSeq
													 AND M.WorkKind	  = 'EQReqRecv_CM'

   WHERE A.CompanySeq = @CompanySeq 
     AND A.ChangeRequestRecvSeq = @ChangeRequestRecvSeq 

    RETURN
    go
exec KPXCM_SEQChangeRequestReceiptListCHEGWQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ChangeRequestRecvSeq>1</ChangeRequestRecvSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030211,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025215