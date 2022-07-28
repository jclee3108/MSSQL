
IF OBJECT_ID('_SEQExamCorrectSaveCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectSaveCHE
GO 

-- v2015.03.18 

/************************************************************
  ��  �� - ������-����˱������� : ����
  �ۼ��� - 20110317
  �ۼ��� - �ſ��
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
         
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQExamCorrectCHE', -- �����̺��
                    '#_TEQExamCorrectCHE', -- �������̺��
                    'ToolSeq          ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq      ,ToolSeq         ,AllowableError  ,ManuCompnay     ,RefDate         ,
                     CorrectCycleSeq ,InstallPlace    ,CorrectPlaceSeq ,Remark          ,LastDateTime    ,
                     LastUserSeq,Remark2'
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
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