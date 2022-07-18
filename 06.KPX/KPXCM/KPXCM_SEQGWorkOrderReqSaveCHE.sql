IF OBJECT_ID('KPXCM_SEQGWorkOrderReqSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQGWorkOrderReqSaveCHE
GO 

-- v2015.02.12 
/************************************************************
 설  명 - 데이터-작업요청Master : 저장(일반)
 작성일 - 20110429
 작성자 - 신용식
************************************************************/
CREATE PROC dbo.KPXCM_SEQGWorkOrderReqSaveCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    
    CREATE TABLE #_TEQWorkOrderReqMasterCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqMasterCHE'
    IF @@ERROR <> 0 RETURN
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   '_TEQWorkOrderReqMasterCHE', -- 원테이블명
                   '#_TEQWorkOrderReqMasterCHE', -- 템프테이블명
                   'WOReqSeq      ' , -- 키가 여러개일 경우는 , 로 연결한다.
                   'CompanySeq    ,WOReqSeq      ,ReqDate       ,DeptSeq       ,EmpSeq        ,
                    WorkType      ,ReqCloseDate  ,WorkContents  ,WONo          ,FileSeq       ,
                    ProgType      ,WorkName      ,LastDateTime  ,LastUserSeq   ,FirstDateTime' 
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
    -- DELETE
    IF EXISTS (SELECT TOP 1 1 FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE _TEQWorkOrderReqMasterCHE
          FROM _TEQWorkOrderReqMasterCHE A
          JOIN #_TEQWorkOrderReqMasterCHE B ON ( A.WOReqSeq      = B.WOReqSeq ) 
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
        
        IF @@ERROR <> 0  RETURN
         
        DELETE _TEQWorkOrderReqItemCHE
          FROM _TEQWorkOrderReqItemCHE A
          JOIN #_TEQWorkOrderReqMasterCHE B ON ( A.WOReqSeq      = B.WOReqSeq ) 
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0 
           
        IF @@ERROR <> 0  RETURN
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        UPDATE _TEQWorkOrderReqMasterCHE
           SET ReqDate       = A.ReqDate       ,
               DeptSeq       = A.DeptSeq       ,
               EmpSeq        = A.EmpSeq        ,
               WorkType      = A.WorkType      ,
               ReqCloseDate  = A.ReqCloseDate  ,
               WorkContents  = A.WorkContents  ,
               WONo          = A.WONo          ,
               FileSeq       = ISNULL(A.FileSeq,0),
               LastDateTime  = GETDATE()       , 
               LastUserSeq   = @UserSeq
          FROM #_TEQWorkOrderReqMasterCHE AS A
          JOIN _TEQWorkOrderReqMasterCHE AS B ON ( A.WOReqSeq      = B.WOReqSeq )          
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U'
           AND A.Status = 0
        
        IF @@ERROR <> 0  RETURN
    END 
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO _TEQWorkOrderReqMasterCHE 
        ( 
            CompanySeq, WOReqSeq, ReqDate, DeptSeq, EmpSeq,
            WorkType, ReqCloseDate, WorkContents, WONo, FileSeq,
            ProgType, LastDateTime, LastUserSeq,  FirstDateTime
        )
        SELECT @CompanySeq, WOReqSeq, ReqDate, DeptSeq, EmpSeq,
               WorkType, ReqCloseDate, WorkContents, WONo, ISNULL(FileSeq,0),
               20109001,GETDATE(),@UserSeq, GETDATE()
          FROM #_TEQWorkOrderReqMasterCHE AS A
         WHERE A.WorkingTag = 'A'
               AND A.Status = 0
         IF @@ERROR <> 0 RETURN
    END
    
    UPDATE A 
       SET ProgTypeName = (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 20109001), 
           GWProgTypeName = (SELECT TOP 1 MinorName     
                               FROM _TDAUMinor     
                              WHERE CompanySeq = @CompanySeq     
                                AND MinorSeq = (CASE WHEN ISNULL(C.CfmCode,0) = 0 AND ISNULL(D.IsProg,0) = 0 THEN 1010655001     
                                                  WHEN ISNULL(C.CfmCode,0) = 5 AND ISNULL(D.IsProg,0) = 1 THEN 1010655002     
                                                  WHEN ISNULL(C.CfmCode,0) = 1 THEN 1010655003     
                                                  ELSE 0 END    
                                               )     
                            )
      FROM #_TEQWorkOrderReqMasterCHE AS A 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm  AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.WOReqSeq )   
      LEFT OUTER JOIN _TCOMGroupWare                    AS D ON ( D.CompanySeq = @CompanySeq AND D.WorkKind = 'EQOrderReq_CM' AND D.TblKey = C.CfmSeq )    
      
    SELECT * FROM #_TEQWorkOrderReqMasterCHE
    
    RETURN
GO
begin tran 
exec KPXCM_SEQGWorkOrderReqSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <WOReqSeq>100</WOReqSeq>
    <ReqDate>20150909</ReqDate>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150909</ReqCloseDate>
    <WorkContents>sadgergserg</WorkContents>
    <WONo>GP-150909-007</WONo>
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030987,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025832

rollback 