
IF OBJECT_ID('_SEQYearRepairRltManHourSaveCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairRltManHourSaveCHE
GO 

-- v2014.12.02
    
/************************************************************
  ��  �� - ������-�������� ����  Item : ����
  �ۼ��� - 20110704
  �ۼ��� - �����
 ************************************************************/
 CREATE PROC [dbo].[_SEQYearRepairRltManHourSaveCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #_TEQYearRepairRltManHourCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQYearRepairRltManHourCHE'
     IF @@ERROR <> 0 RETURN
         
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQYearRepairRltManHourCHE', -- �����̺��
                    '#_TEQYearRepairRltManHourCHE', -- �������̺��
                    'WONo, RltSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq,WONo, RltSerl,RepairYear, Amd, WorkOperSerl,ManHour,OTManHour,LastDateTime,LastUserSeq,EmpSeq,DivSeq'
  
 -- _TEQYearRepairMngCHEManHour
  
  
     -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE  _TEQYearRepairRltManHourCHE
           FROM  _TEQYearRepairRltManHourCHE A
                JOIN #_TEQYearRepairRltManHourCHE B 
                  ON 1 = 1
                 AND A.WONo    = B.WONo    
                 AND A.RltSerl   = B.RltSerl
          WHERE 1 = 1
            AND A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE  _TEQYearRepairRltManHourCHE
            SET 
                 RepairYear      = B.RepairYear,
                 Amd             = B.Amd,
                 WorkOperSerl    = B.WorkOperSerl,
                 ManHour         = B.ManHour,
                 OTManHour       = B.OTManHour,
                 DivSeq          = B.DivSeq, 
                 EmpSeq          = B.EmpSeqSub, 
                 LastDateTime    = GETDATE(),
                 LastUserSeq     = @UserSeq
           FROM  _TEQYearRepairRltManHourCHE AS A
                JOIN #_TEQYearRepairRltManHourCHE AS B 
                  ON 1 = 1
                 AND A.WONo    = B.WONo    
                 AND A.RltSerl   = B.RltSerl
          WHERE 1 = 1
            AND A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO  _TEQYearRepairRltManHourCHE (
                                                     CompanySeq      ,WONo         ,RltSerl        ,RepairYear         ,Amd,
                                                     WorkOperSerl    ,ManHour      ,OTManHour        ,LastDateTime       ,LastUserSeq, 
                                                     DivSeq,          EmpSeq
                                                    )
             SELECT @CompanySeq      ,WONo         ,RltSerl        ,RepairYear     ,Amd, 
                    WorkOperSerl     ,ManHour      ,OTManHour        ,GETDATE()      ,@UserSeq, 
                    A.DivSeq,         A.EmpSeqSub
               FROM #_TEQYearRepairRltManHourCHE AS A
              WHERE 1 = 1
                AND A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TEQYearRepairRltManHourCHE
      RETURN