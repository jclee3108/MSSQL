
IF OBJECT_ID('_SEQGWorkOrderReqSaveCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqSaveCHE
GO 

-- v2015.02.12 
/************************************************************
  ��  �� - ������-�۾���ûMaster : ����(�Ϲ�)
  �ۼ��� - 20110429
  �ۼ��� - �ſ��
 ************************************************************/
 CREATE PROC dbo._SEQGWorkOrderReqSaveCHE
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
         
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQWorkOrderReqMasterCHE', -- �����̺��
                    '#_TEQWorkOrderReqMasterCHE', -- �������̺��
                    'WOReqSeq      ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq    ,WOReqSeq      ,ReqDate       ,DeptSeq       ,EmpSeq        ,
                     WorkType      ,ReqCloseDate  ,WorkContents  ,WONo          ,FileSeq       ,
                     ProgType      ,WorkName      ,LastDateTime  ,LastUserSeq   ,FirstDateTime'
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
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
         INSERT INTO _TEQWorkOrderReqMasterCHE ( CompanySeq    ,WOReqSeq      ,ReqDate       ,DeptSeq       ,EmpSeq        ,
                                                   WorkType      ,ReqCloseDate  ,WorkContents  ,WONo          ,FileSeq       ,
                                                   ProgType      ,LastDateTime  ,LastUserSeq, FirstDateTime)
             SELECT @CompanySeq   ,WOReqSeq      ,ReqDate       ,DeptSeq       ,EmpSeq        ,
                    WorkType      ,ReqCloseDate  ,WorkContents  ,WONo          ,ISNULL(FileSeq,0)       ,
                    20109001    ,GETDATE()     ,@UserSeq, GETDATE()
               FROM #_TEQWorkOrderReqMasterCHE AS A
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TEQWorkOrderReqMasterCHE
      RETURN
      
      
