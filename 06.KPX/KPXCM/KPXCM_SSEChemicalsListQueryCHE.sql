
IF OBJECT_ID('KPXCM_SSEChemicalsListQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEChemicalsListQueryCHE
GO 

-- v2015.06.22 

-- 사이트로 개발 by이재천 

/************************************************************
설  명 - 데이터-화학물질품목관리_capro : 조회
작성일 - 20110602
작성자 - 박헌기
************************************************************/
CREATE PROC dbo.KPXCM_SSEChemicalsListQueryCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
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
           A.SaveKind, 
           A.GroupKind, 
           A.MakeCountry, 
           A.CustSeq, 
           D.CustName, 
           A.IsSave
      FROM KPXCM_TSEChemicalsListCHE    AS A 
                 JOIN _TDAItem          AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq
      LEFT OUTER JOIN _TDAUnit          AS C ON B.CompanySeq = C.CompanySeq AND B.UnitSeq = C.UnitSeq
      LEFT OUTER JOIN _TDACust          AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq )
    
    RETURN