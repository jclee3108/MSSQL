
IF OBJECT_ID('_SEQGWorkOrderReqItemSaveCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqItemSaveCHE
GO 

-- v2015.01.27 

/************************************************************
  ��  �� - ������-�۾���ûItem : ����(�Ϲ�)
  �ۼ��� - 20110429
  �ۼ��� - �ſ��
 ************************************************************/
 CREATE PROC dbo._SEQGWorkOrderReqItemSaveCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #_TEQWorkOrderReqItemCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqItemCHE'
     IF @@ERROR <> 0 RETURN
         
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQWorkOrderReqItemCHE', -- �����̺��
                    '#_TEQWorkOrderReqItemCHE', -- �������̺��
                    'WOReqSeq      ,WOReqSerl     ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq    ,WOReqSeq        ,WOReqSerl       ,ComAccUnitDiv   ,PdAccUnitSeq    ,
                     ToolSeq       ,WorkOperSeq     ,SectionSeq      ,ToolNo          ,ActCenterSeq    ,
                     ProgType      ,AddType         ,ModWorkOperSeq  ,CfmReqEmpseq    ,CfmReqDate      ,
                     CfmEmpseq     ,CfmDate         ,LastDateTime    ,LastUserSeq    '
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TEQWorkOrderReqItemCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TEQWorkOrderReqItemCHE
           FROM _TEQWorkOrderReqItemCHE A
                JOIN #_TEQWorkOrderReqItemCHE B ON ( A.WOReqSeq      = B.WOReqSeq ) 
                                                 AND ( A.WOReqSerl     = B.WOReqSerl ) 
          WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReqItemCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TEQWorkOrderReqItemCHE
            SET PdAccUnitSeq   = A.AccUnitSeq   ,
                ToolSeq        = A.ToolSeq        ,
                WorkOperSeq    = A.WorkOperSeq    ,
                SectionSeq     = A.SectionSeq     ,
                ToolNo         = A.ToolNo         ,
                ProgType       = ISNULL(A.ProgType,0)       ,
                LastDateTime   = GETDATE()        , 
                LastUserSeq    = @UserSeq
           FROM #_TEQWorkOrderReqItemCHE AS A
                JOIN _TEQWorkOrderReqItemCHE AS B ON ( A.WOReqSeq      = B.WOReqSeq ) 
                                                   AND ( A.WOReqSerl     = B.WOReqSerl ) 
          WHERE B.CompanySeq = @CompanySeq
            AND A.WorkingTag = 'U'
            AND A.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReqItemCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO _TEQWorkOrderReqItemCHE ( CompanySeq     ,WOReqSeq       ,WOReqSerl      ,ComAccUnitDiv  ,PdAccUnitSeq   ,
                                                 ToolSeq        ,WorkOperSeq    ,SectionSeq     ,ToolNo         ,ActCenterSeq   ,
                                                 ProgType       ,AddType        ,ModWorkOperSeq ,CfmReqEmpseq   ,CfmReqDate     ,
                                                 CfmEmpseq      ,CfmDate        ,LastDateTime   ,LastUserSeq)
             SELECT @CompanySeq     ,WOReqSeq       ,WOReqSerl       ,0              ,AccUnitSeq   ,
                    ToolSeq         ,WorkOperSeq    ,SectionSeq      ,''             ,0              ,
                    20109001      ,0              ,WorkOperSeq     ,0              ,'' ,
                    0               ,''             ,GETDATE()       ,@UserSeq
               FROM #_TEQWorkOrderReqItemCHE AS A
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TEQWorkOrderReqItemCHE
      RETURN