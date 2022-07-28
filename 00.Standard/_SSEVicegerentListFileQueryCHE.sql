
IF OBJECT_ID('_SSEVicegerentListFileQueryCHE') IS NOT NULL 
    DROP PROC _SSEVicegerentListFileQueryCHE
GO 

-- v2015.01.12 

-- 대관업무조회(파일조회) by이재천
CREATE PROC _SSEVicegerentListFileQueryCHE
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
            @InspectSeq     INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT @InspectSeq = ISNULL(InspectSeq,0)
    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (InspectSeq INT) 
    
    SELECT A.InspectSeq, 
           A.FileSeq 
      FROM _TSEVicegerentCHE AS A WITH (NOLOCK)
     WHERE  A.CompanySeq     = @CompanySeq
       AND  ( A.InspectSeq = @InspectSeq )
    
    RETURN