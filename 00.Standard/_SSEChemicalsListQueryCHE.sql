
IF OBJECT_ID('_SSEChemicalsListQueryCHE') IS NOT NULL 
    DROP PROC _SSEChemicalsListQueryCHE
GO 

/************************************************************
  설  명 - 데이터-화학물질품목관리_capro : 조회
  작성일 - 20110602
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC dbo._SSEChemicalsListQueryCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
      DECLARE @docHandle      INT,
             @ItemSeq     INT
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @ItemSeq     = ItemSeq
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (ItemSeq      INT )
      SELECT A.ChmcSeq     , 
             A.ItemSeq     , 
             B.ItemName    , 
             B.ItemNo      , 
             B.UnitSeq     ,
             C.UnitName    , 
             B.Spec        , 
             A.ToxicName   , 
             A.MainPurpose , 
             A.Content     ,
             A.PrintName   , 
             A.Remark      , 
             A.Acronym,
             A.CasNo,
             A.Molecular,
             A.ExplosionBottom,
             A.ExplosionTop,
             A.StdExpo,
             A.Toxic,
             A.FlashPoint,
             A.IgnitionPoint,
             A.Pressure,
             A.IsCaustic,
             A.IsStatus,
             A.UseDaily,
             A.State,
             A.PoisonKind,
             A.DangerKind,
             A.SafeKind,
             A.SaveKind
       FROM  _TSEChemicalsListCHE   AS A WITH (NOLOCK)
             JOIN _TDAItem            AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                        AND A.ItemSeq    = B.ItemSeq
             LEFT OUTER JOIN _TDAUnit AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                        AND B.UnitSeq    = C.UnitSeq
      WHERE  A.CompanySeq = @CompanySeq
        AND  (@ItemSeq = 0 or A.ItemSeq    = @ItemSeq)
      RETURN