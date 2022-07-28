
IF OBJECT_ID('_SPDToolUserDefineInfoQueryCHE') IS NOT NULL 
    DROP PROC _SPDToolUserDefineInfoQueryCHE
GO 


/*************************************************************************************************      
 FORM NAME           -       FrmPDTool      
 DESCRIPTION         -     설비등록 조회      
 CREAE DATE          -       2008.08.01      CREATE BY: 김현      
 LAST UPDATE  DATE   -       2008.09.24         UPDATE BY: 김현      
 LAST UPDATE  DATE   -       2010.11.03         UPDATE BY: 김일주 조회순서 QrySort로 변경      
*************************************************************************************************/      
CREATE  PROCEDURE _SPDToolUserDefineInfoQueryCHE      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10)= '',      
      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS      
    DECLARE @docHandle      INT,      
            @ToolSeq        INT      
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      
    SELECT  @ToolSeq        = ISNULL(ToolSeq,0)      
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
    WITH (  ToolSeq         INT)      
      
      
    SELECT A.TitleSerl              AS TitleSerl,      
           A.Title                  AS Title,      
           ''                       AS MngValName,      
           A.SMInputType            AS SMInputType,      
           ISNULL(B.MngValSeq, 0)   AS Seq,      
           B.MngValText             AS MngValText,      
           A.CodeHelpConst          AS CodeHelpSeq,      
           A.CodeHelpParams         AS CodeHelpParams,      
           A.MaskAndCaption         AS Mask,      
           A.IsEss                  AS IsNON,      
           A.QrySort      
      INTO #tmp     
      --select *   
      FROM _TCOMUserDefine AS A      
            LEFT OUTER JOIN _TPDToolUserDefine AS B ON B.CompanySeq = @CompanySeq      
                                                   AND B.ToolSeq    = @ToolSeq      
                                                   AND A.TitleSerl  = B.MngSerl      
     WHERE A.TableName     = '_TPDTool'      
       AND A.CompanySeq    = @CompanySeq      
      
      
    EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#tmp'      
      
  
      
    SELECT  A.TitleSerl         AS MngSerl,      
            A.Title             AS MngName,      
            CASE WHEN A.SMInputType IN ( 1027003, 1027005 ) THEN CASE WHEN ISNULL(A.ValueName,'') <> '' THEN ISNULL(A.ValueName,'')      
                                                                       ELSE ISNULL(A.MngValText,'') END       
                 ELSE ISNULL(A.MngValText,'') END AS MngValName,      
            A.Seq               AS MngValSeq,      
            A.CodeHelpSeq       AS CodeHelpSeq,      
            A.CodeHelpParams    AS CodeHelpParams,      
            A.Mask              AS Mask,      
            A.SMInputType       AS SMInputType,      
            A.IsNON             AS IsNON,    
            A.QrySort           AS QrySort       
    FROM #tmp AS A      
    ORDER BY A.QrySort      
  
  
      
RETURN      