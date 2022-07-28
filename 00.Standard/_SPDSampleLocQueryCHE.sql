
IF OBJECT_ID('_SPDSampleLocQueryCHE') IS NOT NULL 
    DROP PROC _SPDSampleLocQueryCHE
GO 

/************************************************************    
 설  명 - 데이터-시료위치등록 : 시료위치조회    
 작성일 - 20110329    
 작성자 - 천경민    
************************************************************/    
CREATE PROC _SPDSampleLocQueryCHE    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT             = 0,    
    @ServiceSeq     INT             = 0,    
    @WorkingTag     NVARCHAR(10)    = '',    
    @CompanySeq     INT             = 1,    
    @LanguageSeq    INT             = 1,    
    @UserSeq        INT             = 0,    
    @PgmSeq         INT             = 0    
AS    
        
    DECLARE @docHandle     INT,    
            @FactUnit      INT,    
            @SectionSeq    INT,    
            @MatDiv        INT      
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT @FactUnit    = ISNULL(FactUnit, 0) ,    
           @SectionSeq  = ISNULL(SectionSeq, 0),    
           @MatDiv      = ISNULL(MatDiv, 0)    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (FactUnit      INT,    
            SectionSeq    INT,    
            MatDiv        INT)    
    
    
    SELECT C.FactUnitName ,    
           A.FactUnit    ,    
           B.SectionCode  ,    
           A.SectionSeq   ,    
           A.SampleLoc    ,    
           A.SampleLocSeq ,    
           A.ApplyDate    ,    
           A.MatDiv       ,    
           D.MinorName as MatDivName,    
           A.Serl         ,    
           A.Remark       ,    
           A.EndDate    
      FROM _TPDSampleLoc AS A WITH(NOLOCK)    
           JOIN _TPDSectionCode    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                         AND A.SectionSeq = B.SectionSeq    
           LEFT OUTER JOIN _TDAFactUnit AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                                                         AND A.FactUnit   = C.FactUnit    
           LEFT OUTER JOIN _TDAUMinor   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.MatDiv     = D.MinorSeq                                                           
     WHERE A.CompanySeq = @CompanySeq    
       AND (@FactUnit   = 0 OR A.FactUnit   = @FactUnit)    
       AND (@SectionSeq = 0 OR A.SectionSeq = @SectionSeq)    
       AND (@MatDiv     = 0 OR A.MatDiv     = @MatDiv)     
     ORDER BY B.Serl,A.Serl    
    
  RETURN   