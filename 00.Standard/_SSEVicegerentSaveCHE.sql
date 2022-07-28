
IF OBJECT_ID('_SSEVicegerentSaveCHE') IS NOT NULL 
    DROP PROC _SSEVicegerentSaveCHE
GO 

/************************************************************
  설  명 - 데이터-대관업무관리_capro : 저장
  작성일 - 20110329
  작성자 - 마스터
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
    
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEVicegerentCHE', -- 원테이블명
                    '#_TSEVicegerentCHE', -- 템프테이블명
                    'InspectSeq      ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq    ,InspectSeq    ,InspectDate   ,
                     InspectOrgan  ,InspectResult ,Inspector     ,
                     InspectContent,Pointed       ,Remark        ,
                     LastDateTime  ,LastUserSeq, JoinEmpName,MRemark'
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
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
