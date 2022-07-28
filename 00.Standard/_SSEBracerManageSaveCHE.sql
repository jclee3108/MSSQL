
IF OBJECT_ID('_SSEBracerManageSaveCHE') IS NOT NULL 
    DROP PROC _SSEBracerManageSaveCHE
GO 

-- v2015.07.13 
/************************************************************
  설  명 - 데이터-보호구일괄지급 : 저장
  작성일 - 20110328
  작성자 - 마스터
 ************************************************************/
 CREATE PROC [dbo].[_SSEBracerManageSaveCHE]
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
         
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEBracerCHE', -- 원테이블명
                    '#_TSEBracerCHE', -- 템프테이블명
                    'BracerSeq     ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq  ,BracerSeq   ,GiveType    ,
                     EmpSeq      ,BrKind      ,BrType      ,
                     GiveDate    ,GiveCnt     ,BrSize      ,
                     Remark      ,LastDateTime,LastUserSeq '
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TSEBracerCHE
           FROM _TSEBracerCHE A
             JOIN #_TSEBracerCHE B ON ( A.BracerSeq     = B.BracerSeq ) 
          WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TSEBracerCHE
            SET GiveType    = B.GiveType    ,
                EmpSeq      = B.EmpSeq      ,
                BrKind      = B.BrKind      ,
                BrType      = B.BrType      ,
                BrSize      = B.BrSize      ,
                GiveDate    = B.GiveDate    ,
                GiveCnt     = B.GiveCnt     ,
                Remark      = B.Remark      ,
                LastDateTime= GETDATE()     ,
                LastUserSeq = @UserSeq
           FROM _TSEBracerCHE AS A
             JOIN #_TSEBracerCHE AS B ON ( A.BracerSeq     = B.BracerSeq )
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #_TSEBracerCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO _TSEBracerCHE ( CompanySeq  ,BracerSeq   ,GiveType    ,
                                       EmpSeq      ,BrKind      ,BrType      ,
                                       GiveDate    ,GiveCnt     ,BrSize      ,
                                       Remark      ,LastDateTime,LastUserSeq )
                                SELECT @CompanySeq ,BracerSeq   ,20064002  ,
                                       EmpSeq      ,BrKind      ,BrType      ,
                                       GiveDate    ,GiveCnt     ,BrSize      ,
                                       Remark      ,GETDATE()   ,@UserSeq 
                                  FROM #_TSEBracerCHE AS A
                                 WHERE A.WorkingTag = 'A'
                                   AND A.Status = 0
         IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #_TSEBracerCHE
      RETURN