  
IF OBJECT_ID('yw_SPJTToolTestResultQuery') IS NOT NULL   
    DROP PROC yw_SPJTToolTestResultQuery  
GO  
  
-- v2014.07.02  
  
-- 금형테스트이력등록_YW-조회 by 이재천   
CREATE PROC yw_SPJTToolTestResultQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PJTSeq     INT, 
            @ToolSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @PJTSeq      = ISNULL( PJTSeq, 0 ),  
           @ToolSeq     = ISNULL( ToolSeq, 0 )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PJTSeq      INT, 
            ToolSeq     INT 
           )    
    
    -- 최종조회   
    SELECT Serl,
           Results, 
           RevResults,
           RevDate, 
           RevEndDate, 
           TestRegDate 
      FROM yw_TPJTToolResult AS A WITH(NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @PJTSeq = 0 OR A.PJTSeq = @PJTSeq ) 
       AND ( @ToolSeq = 0 OR A.ToolSeq = @ToolSeq ) 
    
    RETURN  