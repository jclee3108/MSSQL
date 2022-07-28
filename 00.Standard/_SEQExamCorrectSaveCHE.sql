
IF OBJECT_ID('_SEQExamCorrectSaveCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectSaveCHE
GO 

-- v2015.03.18 

/************************************************************
  설  명 - 데이터-설비검교정정보 : 저장
  작성일 - 20110317
  작성자 - 신용식
 ************************************************************/
 CREATE PROC [dbo].[_SEQExamCorrectSaveCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #_TEQExamCorrectCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQExamCorrectCHE'
     IF @@ERROR <> 0 RETURN
         
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQExamCorrectCHE', -- 원테이블명
                    '#_TEQExamCorrectCHE', -- 템프테이블명
                    'ToolSeq          ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq      ,ToolSeq         ,AllowableError  ,ManuCompnay     ,RefDate         ,
                     CorrectCycleSeq ,InstallPlace    ,CorrectPlaceSeq ,Remark          ,LastDateTime    ,
                     LastUserSeq,Remark2'
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TEQExamCorrectCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TEQExamCorrectCHE
           FROM _TEQExamCorrectCHE A
           JOIN #_TEQExamCorrectCHE B ON ( A.ToolSeq = B.ToolSeq )               
          WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TEQExamCorrectCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TEQExamCorrectCHE
            SET AllowableError    = A.AllowableError    ,
                ManuCompnay       = A.ManuCompnay       ,
                RefDate           = A.RefDate           ,
                CorrectCycleSeq   = A.CorrectCycleSeq   ,
                InstallPlace      = A.InstallPlace      ,
                CorrectPlaceSeq   = A.CorrectPlaceSeq   ,
                Remark            = A.Remark            ,
                LastDateTime      = GETDATE()           ,
                LastUserSeq       = @UserSeq         , 
                Remark2           = A.Remark2 
           FROM #_TEQExamCorrectCHE AS A
             JOIN _TEQExamCorrectCHE AS B ON ( A.ToolSeq = B.ToolSeq ) 
          WHERE B.CompanySeq = @CompanySeq
            AND A.WorkingTag = 'U'
            AND A.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TEQExamCorrectCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO _TEQExamCorrectCHE ( CompanySeq        ,ToolSeq           ,AllowableError    ,ManuCompnay       ,RefDate           ,
                                            CorrectCycleSeq   ,InstallPlace      ,CorrectPlaceSeq   ,Remark            ,LastDateTime      ,
                                            LastUserSeq, Remark2 
                                           )
             SELECT @CompanySeq       ,ToolSeq           ,AllowableError    ,ManuCompnay       ,RefDate           ,
                    CorrectCycleSeq   ,InstallPlace      ,CorrectPlaceSeq   ,Remark            ,GETDATE()         ,
                    @UserSeq, Remark2 
               FROM #_TEQExamCorrectCHE AS A
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TEQExamCorrectCHE
      RETURN