
IF OBJECT_ID('KPXCM_SEQChangeRequestCHESave') IS NOT NULL 
    DROP PROC KPXCM_SEQChangeRequestCHESave
GO 

-- v2015.06.10 

-- 변경등록-저장 by이재천 
CREATE PROC dbo.KPXCM_SEQChangeRequestCHESave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT     = 0,    
    @ServiceSeq     INT     = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT     = 1,    
    @LanguageSeq    INT     = 1,    
    @UserSeq        INT     = 0,    
    @PgmSeq         INT     = 0    
AS  

    DECLARE @docHandle      INT,  
            @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250),  
            @Seq            INT,  
            @Count          INT,  
            @MaxSeq         INT  
    
    CREATE TABLE #KPXCM_TEQChangeRequestCHE (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQChangeRequestCHE'  
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQChangeRequestCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQChangeRequestCHE'    , -- 테이블명        
                  '#KPXCM_TEQChangeRequestCHE'    , -- 임시 테이블명        
                  'ChangeRequestSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    
    --DEL  
    IF EXISTS (SELECT 1 FROM #KPXCM_TEQChangeRequestCHE WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE A   
          FROM KPXCM_TEQChangeRequestCHE AS A  
          JOIN #KPXCM_TEQChangeRequestCHE AS B WITH(NOLOCK) ON B.ChangeRequestSeq = A.ChangeRequestSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND B.WorkingTag = 'D'  
           AND B.Status = 0   
        
        --DELETE B  
        --  FROM #KPXCM_TEQChangeRequestCHE AS A   
        --  JOIN KPXCM_TEQChangeRequestCHE_Confirm AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.ChangeRequestSeq )   
        -- WHERE A.WorkingTag = 'D'  
        --   AND A.Status = 0   
    END  
    
    --UPDATE  
    IF EXISTS (SELECT 1 FROM #KPXCM_TEQChangeRequestCHE WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
        UPDATE A  
           SET BaseDate         = B.BaseDate         ,  
               DeptSeq          = B.DeptSeq          ,  
               EmpSeq           = B.EmpSeq           ,  
               Title            = B.Title            ,  
               UMPlantType      = B.UMPlantType      ,  
               UMChangeType     = B.UMChangeType     ,  
               UMChangeReson1   = B.UMChangeReson1   ,  
               UMChangeReson2   = B.UMChangeReson2   ,  
               Purpose          = B.Purpose          ,  
               Remark           = B.Remark           ,  
               Effect           = B.Effect           ,  
               IsPID            = B.IsPID            ,  
               IsPFD            = B.IsPFD            ,  
               IsLayOut         = B.IsLayOut         ,  
               IsProposal       = B.IsProposal       ,  
               IsReport         = B.IsReport         ,  
               IsMinutes        = B.IsMinutes        ,  
               IsReview         = B.IsReview         ,  
               IsOpinion        = B.IsOpinion        ,  
               IsDange          = B.IsDange          ,  
               Etc              = B.Etc              ,  
               FileSeq          = B.FileSeq          ,  
               LastUserSeq      = @UserSeq           , 
               LastDateTime     = GETDATE()
          FROM KPXCM_TEQChangeRequestCHE    AS A  
          JOIN #KPXCM_TEQChangeRequestCHE   AS B ON ( B.ChangeRequestSeq = A.ChangeRequestSeq ) 
         WHERE A.CompanySeq = @CompanySeq  
           AND B.WorkingTag = 'U'  
           AND B.Status = 0  
    END  
    
    --SAVE      
    IF EXISTS (SELECT 1 FROM #KPXCM_TEQChangeRequestCHE WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO KPXCM_TEQChangeRequestCHE
        (
            CompanySeq, ChangeRequestSeq, ChangeRequestNo, BaseDate, DeptSeq, 
            EmpSeq, Title, UMPlantType, UMChangeType, UMChangeReson1, 
            UMChangeReson2, Purpose, Remark, Effect, IsPID, 
            IsPFD, IsLayOut, IsProposal, IsReport, IsMinutes, 
            IsReview, IsOpinion, IsDange, Etc, FileSeq, 
            LastUserSeq, LastDateTime
        )  
        SELECT @CompanySeq, ChangeRequestSeq, ChangeRequestNo, BaseDate, DeptSeq, 
               EmpSeq, Title, UMPlantType, UMChangeType, UMChangeReson1, 
               UMChangeReson2, Purpose, Remark, Effect, IsPID, 
               IsPFD, IsLayOut, IsProposal, IsReport, IsMinutes, 
               IsReview, IsOpinion, IsDange, Etc, FileSeq, 
               @UserSeq, GETDATE()
          FROM #KPXCM_TEQChangeRequestCHE  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    END  
      
    SELECT * FROM #KPXCM_TEQChangeRequestCHE  
      
RETURN  
go
begin tran 
exec KPXCM_SEQChangeRequestCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ChangeRequestNo>CR-D-15-001</ChangeRequestNo>
    <BaseDate>20150610</BaseDate>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <Title>ㅇㅅㄷㅅ</Title>
    <UMChangeType>20139001</UMChangeType>
    <UMChangeTypeName>정상변경</UMChangeTypeName>
    <UMChangeReson1>20140001</UMChangeReson1>
    <UMChangeResonName1>원단위향상</UMChangeResonName1>
    <UMChangeReson2>20140001</UMChangeReson2>
    <UMChangeResonName2>원단위향상</UMChangeResonName2>
    <UMPlantType>1010356001</UMPlantType>
    <UMPlantTypeName>DMC</UMPlantTypeName>
    <FileSeq>0</FileSeq>
    <Purpose />
    <Effect>ㅅㄴㄷㅅㄴㄷㅅ</Effect>
    <Remark>ㅅㄴㄷㅅㄴㄷ</Remark>
    <IsPID>0</IsPID>
    <IsPFD>1</IsPFD>
    <IsLayOut>0</IsLayOut>
    <IsProposal>0</IsProposal>
    <IsMinutes>0</IsMinutes>
    <IsReview>1</IsReview>
    <IsOpinion>0</IsOpinion>
    <IsDange>1</IsDange>
    <Etc />
    <IsReport>1</IsReport>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030192,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025199
rollback 