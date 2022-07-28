
IF OBJECT_ID('_SSEVicegerentSaveCHE') IS NOT NULL 
    DROP PROC _SSEVicegerentSaveCHE
GO 

/************************************************************
  ��  �� - ������-�����������_capro : ����
  �ۼ��� - 20110329
  �ۼ��� - ������
 ************************************************************/
 CREATE PROC [dbo].[_SSEVicegerentSaveCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #_TSEVicegerentCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEVicegerentCHE'
     IF @@ERROR <> 0 RETURN
    
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEVicegerentCHE', -- �����̺��
                    '#_TSEVicegerentCHE', -- �������̺��
                    'InspectSeq      ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq    ,InspectSeq    ,InspectDate   ,
                     InspectOrgan  ,InspectResult ,Inspector     ,
                     InspectContent,Pointed       ,Remark        ,
                     LastDateTime  ,LastUserSeq, JoinEmpName,MRemark'
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TSEVicegerentCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TSEVicegerentCHE
           FROM _TSEVicegerentCHE A
             JOIN #_TSEVicegerentCHE B ON ( A.InspectSeq = B.InspectSeq )
          WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TSEVicegerentCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TSEVicegerentCHE
            SET InspectDate        = B.InspectDate        ,
                InspectOrgan       = B.InspectOrgan       ,
                InspectResult      = B.InspectResult      ,
                Inspector          = B.Inspector          ,
                InspectContent     = B.InspectContent     ,
                Pointed            = B.Pointed            ,
                Remark             = B.Remark             ,
                LastDateTime       = GETDATE()            ,
                LastUserSeq        = @UserSeq             , 
                FileSeq            = B.FileSeq            , 
                JoinEmpName        = B.JoinEmpName        , 
                MRemark            = B.MRemark 
           FROM _TSEVicegerentCHE AS A
                JOIN #_TSEVicegerentCHE AS B ON ( A.InspectSeq      = B.InspectSeq ) 
                         
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TSEVicegerentCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO _TSEVicegerentCHE ( CompanySeq    ,InspectSeq    ,InspectDate   ,
                                           InspectOrgan  ,InspectResult ,Inspector     ,
                                           InspectContent,Pointed       ,Remark        ,
                                           LastDateTime  ,LastUserSeq   , FileSeq, JoinEmpName, MRemark)
                                    SELECT @CompanySeq   ,InspectSeq    ,InspectDate   ,
                                           InspectOrgan  ,InspectResult ,Inspector     ,
                                           InspectContent,Pointed       ,Remark        ,
                                           GETDATE()  ,@UserSeq         , A.FileSeq , A.JoinEmpName, A.MRemark
                                      FROM #_TSEVicegerentCHE AS A
                                     WHERE A.WorkingTag = 'A'
                                       AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TSEVicegerentCHE
      RETURN
