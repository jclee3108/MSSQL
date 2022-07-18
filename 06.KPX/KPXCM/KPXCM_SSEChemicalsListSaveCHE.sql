
IF OBJECT_ID('KPXCM_SSEChemicalsListSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEChemicalsListSaveCHE
GO 

-- v2015.06.22 

-- 사이트로 개발 by이재천 
/************************************************************
설  명 - 데이터-화학물질품목관리_capro : 저장
작성일 - 20110602
작성자 - 박헌기
************************************************************/
CREATE PROC dbo.KPXCM_SSEChemicalsListSaveCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    CREATE TABLE #KPXCM_TSEChemicalsListCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEChemicalsListCHE'
    IF @@ERROR <> 0 RETURN
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TSEChemicalsListCHE')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TSEChemicalsListCHE'    , -- 테이블명        
                  '#KPXCM_TSEChemicalsListCHE'    , -- 임시 테이블명        
                   'ChmcSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , ''
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
    -- DELETE
    IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE A
          FROM KPXCM_TSEChemicalsListCHE A
          JOIN #KPXCM_TSEChemicalsListCHE B ON ( A.ChmcSeq       = B.ChmcSeq )
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
        IF @@ERROR <> 0  RETURN
           
        DELETE A
          FROM _TSEChemicalsWkListCHE A
          JOIN #KPXCM_TSEChemicalsListCHE B ON ( A.ChmcSeq = B.ChmcSeq )
         WHERE A.CompanySeq  = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
        IF @@ERROR <> 0  RETURN         
    
    END
    
    -- UPDATE
    IF EXISTS (SELECT 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        
        UPDATE A
           SET ItemSeq      = B.ItemSeq      ,
               ToxicName    = B.ToxicName    ,
               MainPurpose  = B.MainPurpose  ,
               Content      = B.Content      ,
               PrintName    = B.PrintName    ,
               Remark       = B.Remark       ,
               LastDateTime = GETDATE()      ,
               LastUserSeq  = @UserSeq       ,
               Acronym         = B.Acronym, 
               CasNo           = B.CasNo, 
               Molecular       = B.Molecular, 
               ExplosionBottom = B.ExplosionBottom, 
               ExplosionTop    = B.ExplosionTop, 
               StdExpo         = B.StdExpo, 
               Toxic           = B.Toxic,
               FlashPoint      = B.FlashPoint,
               IgnitionPoint   = B.IgnitionPoint,
               Pressure        = B.Pressure,
               IsCaustic       = B.IsCaustic,
               IsStatus        = B.IsStatus,
               UseDaily        = B.UseDaily,
               State           = B.State,
               PoisonKind      = B.PoisonKind,
               DangerKind      = B.DangerKind,
               SafeKind        = B.SafeKind,
               SaveKind        = B.SaveKind, 
               GroupKind       = B.GroupKind, 
               MakeCountry     = B.MakeCountry, 
               CustSeq         = B.CustSeq, 
               IsSave          = B.IsSave 
               
          FROM KPXCM_TSEChemicalsListCHE AS A
          JOIN #KPXCM_TSEChemicalsListCHE AS B ON ( A.ChmcSeq = B.ChmcSeq )
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'U'
           AND B.Status = 0
        
        IF @@ERROR <> 0  RETURN
    
    END
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPXCM_TSEChemicalsListCHE 
        ( 
            CompanySeq  ,   ChmcSeq,    ItemSeq,        ToxicName,          MainPurpose ,
            Content     ,   PrintName,  Remark,         LastDateTime,       LastUserSeq,
            Acronym,        CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
            StdExpo,        Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
            IsCaustic,      IsStatus,   UseDaily,       State,              PoisonKind,
            DangerKind,     SafeKind,   SaveKind,       GroupKind,          MakeCountry, 
            CustSeq,        IsSave
        )
        SELECT @CompanySeq ,    ChmcSeq     ,ItemSeq     ,ToxicName   ,MainPurpose ,
               Content     ,    PrintName   ,Remark      ,GETDATE()   ,@UserSeq, 
               Acronym,         CasNo,      Molecular,      ExplosionBottom,    ExplosionTop, 
               StdExpo,         Toxic,      FlashPoint,     IgnitionPoint,      Pressure,
               IsCaustic,       IsStatus,   UseDaily,       State,              PoisonKind,
               DangerKind,      SafeKind,   SaveKind,       GroupKind,          MakeCountry, 
               CustSeq,        IsSave
                
          FROM #KPXCM_TSEChemicalsListCHE AS A
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0
        
        IF @@ERROR <> 0 RETURN
    END
     
    SELECT * FROM #KPXCM_TSEChemicalsListCHE
     
    RETURN