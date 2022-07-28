
IF OBJECT_ID('_SEQGWorkOrderReqItemSaveCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqItemSaveCHE
GO 

-- v2015.01.27 

/************************************************************
  설  명 - 데이터-작업요청Item : 저장(일반)
  작성일 - 20110429
  작성자 - 신용식
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
         
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQWorkOrderReqItemCHE', -- 원테이블명
                    '#_TEQWorkOrderReqItemCHE', -- 템프테이블명
                    'WOReqSeq      ,WOReqSerl     ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq    ,WOReqSeq        ,WOReqSerl       ,ComAccUnitDiv   ,PdAccUnitSeq    ,
                     ToolSeq       ,WorkOperSeq     ,SectionSeq      ,ToolNo          ,ActCenterSeq    ,
                     ProgType      ,AddType         ,ModWorkOperSeq  ,CfmReqEmpseq    ,CfmReqDate      ,
                     CfmEmpseq     ,CfmDate         ,LastDateTime    ,LastUserSeq    '
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
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