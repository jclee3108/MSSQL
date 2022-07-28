IF OBJECT_ID('_SEQExamCorrectQueryCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectQueryCHE
GO 

-- 2015.03.18 

/************************************************************
  설  명 - 데이터-설비검교정정보 : 조회
  작성일 - 20110317
  작성자 - 신용식
 ************************************************************/
 CREATE PROC [dbo].[_SEQExamCorrectQueryCHE]
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
             @ToolSeq          INT 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @ToolSeq          = ISNULL(ToolSeq,0)           
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (ToolSeq           INT )
     
     SELECT  A.CompanySeq       , 
             A.ToolSeq          , 
             A.AllowableError   , 
             A.RefDate          , 
             A.CorrectCycleSeq  , 
             A.InstallPlace     , 
             A.CorrectPlaceSeq  , 
             A.Remark           , 
             B.ToolName         ,
             B.ToolNo           , 
             B.FactUnit         ,
             ISNULL(F.FactUnitName,'') AS FactUnitName ,  
             A.ManuCompnay      , 
             C.MinorName AS CorrectCycleName , 
             E.MinorName AS CorrectPlaceName, 
             A.Remark2 
       FROM  _TEQExamCorrectCHE AS A WITH (NOLOCK)
             LEFT OUTER JOIN _TPDTool AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                             AND A.ToolSeq    = B.ToolSeq
             LEFT OUTER JOIN _TDAUMinor AS C WITH (NOLOCK)ON A.CompanySeq       = C.CompanySeq 
                                                         AND A.CorrectCycleSeq  = C.MinorSeq   
             LEFT OUTER JOIN _TDAUMinor AS E WITH (NOLOCK)ON A.CompanySeq      = E.CompanySeq 
                                                         AND A.CorrectPlaceSeq = E.MinorSeq     
             LEFT OUTER JOIN _TDAFactUnit AS F WITH (NOLOCK) ON B.CompanySeq = F.CompanySeq 
                                                            AND B.FactUnit   = F.FactUnit    -- 생산사업장                                                                                                                                                                       
      WHERE  A.CompanySeq = @CompanySeq
        AND  (A.ToolSeq    = @ToolSeq OR @ToolSeq = 0)
      RETURN