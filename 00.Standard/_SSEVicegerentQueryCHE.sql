
IF OBJECT_ID('_SSEVicegerentQueryCHE') IS NOT NULL 
    DROP PROC _SSEVicegerentQueryCHE
GO 

/************************************************************
  설  명 - 데이터-대관업무관리_capro : 조회
  작성일 - 20110329
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC [dbo].[_SSEVicegerentQueryCHE]
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
             @InspectSeq        INT 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @InspectSeq        = InspectSeq         
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (InspectSeq         INT )
     
     SELECT  A.InspectSeq        , 
             A.InspectDate       , 
             A.InspectOrgan      , 
             A.InspectResult     , 
             B.MinorName AS InspectResultName,
             A.Inspector         , 
             A.InspectContent    , 
             A.Pointed           ,
             A.Remark            , 
             A.FileSeq           , 
             A.JoinEmpName       , 
             A.MRemark 
       FROM  _TSEVicegerentCHE AS A WITH (NOLOCK)
             LEFT OUTER JOIN _TDAUMinor AS B WITH (NOLOCK) ON A.CompanySeq   = B.CompanySeq
                                                          AND A.InspectResult= B.MinorSeq
      WHERE  A.CompanySeq  = @CompanySeq
        AND  A.InspectSeq  = @InspectSeq        
         
      RETURN