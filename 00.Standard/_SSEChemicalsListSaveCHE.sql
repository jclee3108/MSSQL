
IF OBJECT_ID('_SSEChemicalsListSaveCHE') IS NOT NULL 
    DROP PROC _SSEChemicalsListSaveCHE 
GO 

/************************************************************
  설  명 - 데이터-화학물질품목관리_capro : 저장
  작성일 - 20110602
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC dbo._SSEChemicalsListSaveCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
    CREATE TABLE #_TSEChemicalsListCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEChemicalsListCHE'
     IF @@ERROR <> 0 RETURN
  
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEChemicalsListCHE', -- 원테이블명
                    '#_TSEChemicalsListCHE', -- 템프테이블명
                    'ChmcSeq       ' , -- 키가 여러개일 경우는 , 로 연결한다.
                    'CompanySeq  ,ChmcSeq     ,ItemSeq     ,ToxicName   ,
                     MainPurpose ,Content     ,PrintName   ,Remark      ,
                     LastDateTime,LastUserSeq,
                     Acronym,        CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
                     StdExpo,        Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
                     IsCaustic,      IsStatus,   UseDaily,       State,              PoisonKind,
                     DangerKind,     SafeKind,   SaveKind  '
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #_TSEChemicalsListCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE _TSEChemicalsListCHE
           FROM _TSEChemicalsListCHE A
             JOIN #_TSEChemicalsListCHE B ON ( A.ChmcSeq       = B.ChmcSeq )
           WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN
          
         DELETE _TSEChemicalsWkListCHE
           FROM _TSEChemicalsWkListCHE A
             JOIN #_TSEChemicalsListCHE B ON ( A.ChmcSeq       = B.ChmcSeq )
           WHERE A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'D'
            AND B.Status = 0
           IF @@ERROR <> 0  RETURN         
          
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #_TSEChemicalsListCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE _TSEChemicalsListCHE
            SET ItemSeq      = B.ItemSeq      ,
                ToxicName    = B.ToxicName    ,
                MainPurpose  = B.MainPurpose  ,
                Content      = B.Content      ,
                PrintName    = B.PrintName    ,
                Remark       = B.Remark       ,
                LastDateTime = GETDATE()      ,
                LastUserSeq  = @UserSeq       ,
                Acronym         = B.Acronym, 
                CasNo           =  B.CasNo, 
                Molecular       =  B.Molecular, 
                ExplosionBottom =  B.ExplosionBottom, 
                ExplosionTop    =  B.ExplosionTop, 
                StdExpo         =  B.StdExpo, 
                Toxic           =  B.Toxic,
                FlashPoint      =  B.FlashPoint,
                IgnitionPoint   =  B.IgnitionPoint,
                Pressure        =  B.Pressure,
                IsCaustic       =  B.IsCaustic,
                IsStatus        =  B.IsStatus,
                UseDaily        =  B.UseDaily,
                State           =  B.State,
                PoisonKind      =  B.PoisonKind,
                DangerKind      =  B.DangerKind,
                SafeKind        =  B.SafeKind,
                SaveKind        =  B.SaveKind
           FROM _TSEChemicalsListCHE AS A
             JOIN #_TSEChemicalsListCHE AS B ON ( A.ChmcSeq       = B.ChmcSeq )
           WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
         
     END
      -- INSERT
    IF EXISTS (SELECT 1 FROM #_TSEChemicalsListCHE WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO _TSEChemicalsListCHE 
        ( 
            CompanySeq  ,   ChmcSeq,    ItemSeq,        ToxicName,          MainPurpose ,
            Content     ,   PrintName,  Remark,         LastDateTime,       LastUserSeq,
            Acronym,        CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
            StdExpo,        Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
            IsCaustic,      IsStatus,   UseDaily,       State,              PoisonKind,
            DangerKind,     SafeKind,   SaveKind                                              

        )
        SELECT @CompanySeq ,    ChmcSeq     ,ItemSeq     ,ToxicName   ,MainPurpose ,
               Content     ,    PrintName   ,Remark      ,GETDATE()   ,@UserSeq, 
               Acronym,         CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
               StdExpo,         Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
               IsCaustic,       IsStatus,   UseDaily,       State,              PoisonKind,
               DangerKind,      SafeKind,   SaveKind
               
          FROM #_TSEChemicalsListCHE AS A
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0
    IF @@ERROR <> 0 RETURN
    END
    
    SELECT * FROM #_TSEChemicalsListCHE
    
    RETURN
GO 

          