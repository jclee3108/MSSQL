IF OBJECT_ID('KPX_SDAUMToolKindTreeSheetQueryCHE') IS NOT NULL 
    DROP PROC KPX_SDAUMToolKindTreeSheetQueryCHE
GO 

/************************************************************
  설  명 - 설비유형분류 시트조회
  작성일 - 2011/03/17
  작성자 - shpark
 ************************************************************/
 CREATE PROC KPX_SDAUMToolKindTreeSheetQueryCHE
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
             @MinorName  NVARCHAR(100),
             @IsNotExists    NCHAR(1)
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
      
      SELECT @MinorName		 = ISNULL(LTRIM(RTRIM(MinorName)),''),
             @IsNotExists    = ISNULL(LTRIM(RTRIM(IsNotExists)),'0')
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)   
       WITH (MinorName   NVARCHAR(100),
             IsNotExists     NCHAR(1))  
     
      IF @IsNotExists = '1'
     BEGIN
      SELECT  A.MinorSeq,
                 A.MinorName,
                 A.MinorSort,
                 A.Remark,
                 A.IsUse
           FROM _TDAUMinor AS A WITH (NOLOCK)             
          WHERE A.CompanySeq = @CompanySeq
            AND A.MajorSeq   = 6009
            AND (@MinorName  = '' OR A.MinorName like @MinorName + '%')
			 AND A.MinorSeq NOT IN (SELECT UMToolKind 
                                     FROM _TDAUMToolKindTreeCHE 
                                    WHERE CompanySeq = @CompanySeq)
     END
     ELSE
     BEGIN
      SELECT  A.MinorSeq,
                 A.MinorName,
                 A.MinorSort,
                 A.Remark,
                 A.IsUse
           FROM _TDAUMinor AS A WITH (NOLOCK)             
          WHERE A.CompanySeq = @CompanySeq
            AND A.MajorSeq   = 6009
            AND (@MinorName  = '' OR A.MinorName like @MinorName + '%')
        
     END
  
  
           

 RETURN
GO


