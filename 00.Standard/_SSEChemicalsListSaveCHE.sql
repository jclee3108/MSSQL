
IF OBJECT_ID('_SSEChemicalsListSaveCHE') IS NOT NULL 
    DROP PROC _SSEChemicalsListSaveCHE 
GO 

/************************************************************
  ��  �� - ������-ȭ�й���ǰ�����_capro : ����
  �ۼ��� - 20110602
  �ۼ��� - �����
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
  
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSEChemicalsListCHE', -- �����̺��
                    '#_TSEChemicalsListCHE', -- �������̺��
                    'ChmcSeq       ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq  ,ChmcSeq     ,ItemSeq     ,ToxicName   ,
                     MainPurpose ,Content     ,PrintName   ,Remark      ,
                     LastDateTime,LastUserSeq,
                     Acronym,        CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
                     StdExpo,        Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
                     IsCaustic,      IsStatus,   UseDaily,       State,              PoisonKind,
                     DangerKind,     SafeKind,   SaveKind  '
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
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

          