
IF OBJECT_ID('_SPDToolUserDefineRightQueryCHE') IS NOT NULL 
    DROP PROC _SPDToolUserDefineRightQueryCHE 
GO 

/************************************************************
  설  명 - 설비등록 제원 조회
  작성일 - 2011/03/17
  작성자 - shpark
 ************************************************************/
 CREATE PROC dbo._SPDToolUserDefineRightQueryCHE
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS 
  DECLARE @docHandle  INT,
             @ToolSeq    INT,
             @UMToolKind INT
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
      
      SELECT @ToolSeq    = ISNULL(LTRIM(RTRIM(ToolSeq)),0),
             @UMToolKind = ISNULL(LTRIM(RTRIM(UMToolKind)),0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)   
       WITH (ToolSeq     INT,
             UMToolKind  INT)  
     
      SELECT  A.QrySort,
             A.Title,
             ISNULL(B.MngValText,'') AS MngValText,
             CASE WHEN ISNULL(C.MngValText,'') = '' THEN A.DataFieldID ELSE C.MngValText END AS DataFieldID,
             ISNULL(B.MngValSeq,0)   AS MngValSeq,
             ISNULL(B.MngSerl,0)     AS MngSerl,
             A.TitleSerl
       FROM _TCOMUserDefine AS A WITH(NOLOCK) LEFT OUTER JOIN _TPDToolUserDefine AS B 
                                                ON A.CompanySeq      = B.CompanySeq
                                               AND A.TitleSerl       = B.MngSerl
                                               AND B.ToolSeq         = @ToolSeq
                                              LEFT OUTER JOIN _TPDToolUserDefine AS C
                                                ON A.CompanySeq      = C.CompanySeq
                                               AND A.TitleSerl       = C.MngSerl
                                               AND C.ToolSeq         = @ToolSeq
      WHERE A.CompanySeq     = @CompanySeq
        AND A.TableName      = '_TDAUMajor_6009'
        AND A.DefineUnitSeq  = @UMToolKind
        AND A.QrySort % 2    = 0    -- 짝수만
            
 RETURN