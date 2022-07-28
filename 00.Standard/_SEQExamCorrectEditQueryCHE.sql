
IF OBJECT_ID('_SEQExamCorrectEditQueryCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectEditQueryCHE
GO 

-- v2015.07.13 

/************************************************************
  설  명 - 데이터-설비검교정등록 : 조회
  작성일 - 20110724
  작성자 - 신용식
 ************************************************************/
CREATE PROC dbo._SEQExamCorrectEditQueryCHE                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags     INT  = 0,            
    @ServiceSeq     INT  = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT  = 1,            
    @LanguageSeq INT  = 1,            
    @UserSeq     INT  = 0,            
    @PgmSeq         INT  = 0         
AS        
  
    DECLARE @docHandle      INT,
            @ToolName      NVARCHAR(100) ,
            @ToolNo        NVARCHAR(100) ,
            @CorrectDateFr NCHAR(8) ,
            @CorrectDateTo NCHAR(8), 
            @FactUnit      INT 
  
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
   SELECT  @ToolName        = ISNULL(ToolName,'')       ,
             @ToolNo        = ISNULL(ToolNo,'')         ,
             @CorrectDateFr = ISNULL(CorrectDateFr,'')  ,
             @CorrectDateTo = ISNULL(CorrectDateTo,'')  , 
             @FactUnit      = ISNULL(FactUnit,0) 
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (
            ToolName       NVARCHAR(100) ,
            ToolNo         NVARCHAR(100) ,
            CorrectDateFr  NCHAR(8) ,
            CorrectDateTo  NCHAR(8) , 
            FactUnit      INT 
         )
             
    IF @CorrectDateFr = '' SELECT @CorrectDateFr = '19000101'
    IF @CorrectDateTo = '' SELECT @CorrectDateTo = '99991231'             
    
    SELECT A.CorrectSeq    , 
           A.ToolSeq       , 
           B.ToolName      , 
           B.ToolNo        , 
           B.FactUnit      , 
           ISNULL(C.FactUnitName,'') AS FactUnitName ,
           A.CorrectDate   , 
           A.WkContent     , 
           A.FileSeq AS FileSeq1      
      FROM _TEQExamCorrectEditCHE AS A WITH (NOLOCK) 
             LEFT OUTER JOIN _TPDTool AS B ON A.CompanySeq = B.CompanySeq
                                          AND A.ToolSeq    = B.ToolSeq
             LEFT OUTER JOIN _TDAFactUnit AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq 
                                                            AND B.FactUnit   = C.FactUnit    -- 생산사업장       
   WHERE  A.CompanySeq = @CompanySeq
        AND  (@ToolNo  = '' OR B.ToolNo LIKE '%'+@ToolNo+'%'  )
        AND  (@ToolName  = '' OR B.ToolName LIKE '%'+@ToolName+'%'  )    
        AND  A.CorrectDate  BETWEEN  @CorrectDateFr AND @CorrectDateTo 
        AND ( @FactUnit = 0 OR B.FactUnit = @FactUnit ) 
    
  RETURN