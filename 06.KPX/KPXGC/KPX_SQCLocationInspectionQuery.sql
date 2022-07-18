  
IF OBJECT_ID('KPX_SQCLocationInspectionQuery') IS NOT NULL   
    DROP PROC KPX_SQCLocationInspectionQuery  
GO  
  
-- v2014.12.04  
  
-- 공정검사위치등록-조회 by 이재천   
CREATE PROC KPX_SQCLocationInspectionQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PlantName NVARCHAR(100)  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlantName  = ISNULL( PlantName, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlantName  NVARCHAR(100) )    
      
    -- 최종조회   
    SELECT A.PlantName, 
           A.PlantSeq 
      FROM KPX_TQCPlant AS A WITH(NOLOCK)   
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @PlantName = '' OR A.PlantName LIKE @PlantName + '%' )  
      
    RETURN  