  
IF OBJECT_ID('KPX_SEISAccQuery') IS NOT NULL   
    DROP PROC KPX_SEISAccQuery  
GO  
  
-- v2015.02.11  
  
-- (경영보고)계정등록-조회 by 이재천   
CREATE PROC KPX_SEISAccQuery  
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
            @KindSeq    INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @KindSeq   = ISNULL( KindSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (KindSeq   INT)    
    
    -- 최종조회   
    SELECT A.*, 
           B.AccName, 
           C.AccName AS AccNameSub
            
      FROM KPX_TEISAcc AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAAccount AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAAccount AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.AccSeqSub ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @KindSeq = 0 OR A.KindSeq = @KindSeq )   
      
    RETURN  