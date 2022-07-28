
IF OBJECT_ID('_SSEBracerIndividualManageSaveCHE') IS NOT NULL 
    DROP PROC _SSEBracerIndividualManageSaveCHE
GO 

-- v2015.07.30 

/************************************************************
  ��  �� - ������-��ȣ���������� : ����
  �ۼ��� - 20110328
  �ۼ��� - ������
 ************************************************************/
  
 CREATE PROC [dbo].[_SSEBracerIndividualManageSaveCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #_TSEBracerCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEBracerCHE'
     IF @@ERROR <> 0 RETURN
         
         
      DECLARE @vcGiveType INT   -- ���ޱ��� (����/�ϰ�)
       SELECT @vcGiveType = 20064001
         
         
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEBracerCHE', -- �����̺��
                    '#_TSEBracerCHE', -- �������̺��
                    'BracerSeq     ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq   ,BracerSeq    ,GiveType, EmpSeq       ,BrKind       ,BrType       ,GiveDate     ,GiveCnt      ,BrSize       ,Remark ,LastDateTime, LastUserSeq   '
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TSEBracerCHE
           FROM _TSEBracerCHE A
                JOIN #_TSEBracerCHE B ON ( A.BracerSeq     = B.BracerSeq AND A.EmpSeq = B.EmpSeqOld) 
          WHERE 1 = 1
            AND A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TSEBracerCHE
            SET     EmpSeq       = B.EmpSeq       ,
                    BrKind       = B.BrKind       ,
                    BrType       = B.BrType       ,
                    GiveDate     = B.GiveDate     ,
                    GiveCnt      = B.GiveCnt      ,
                    BrSize       = B.BrSize       ,
                    Remark       = B.Remark       ,
                    LastDateTime = GETDATE(),
                    LastUserSeq  = @UserSeq
           FROM _TSEBracerCHE AS A
                JOIN #_TSEBracerCHE AS B ON ( A.BracerSeq     = B.BracerSeq AND A.EmpSeq = B.EmpSeqOld) 
          WHERE 1 = 1
            AND A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO _TSEBracerCHE ( CompanySeq   ,BracerSeq    , GiveType ,    EmpSeq       ,BrKind       ,
                                       BrType       ,GiveDate     ,GiveCnt      , BrSize       ,Remark,       
                                       LastDateTime, LastUserSeq
                                     )
             SELECT  @CompanySeq   ,BracerSeq,  @vcGiveType,    EmpSeq       , BrKind       , 
                     BrType       , GiveDate     ,GiveCnt      ,BrSize       ,Remark       , 
                     GETDATE(),     @UserSeq
               FROM #_TSEBracerCHE AS A
              WHERE 1 = 1
                AND A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TSEBracerCHE
      RETURN