  
IF OBJECT_ID('KPXCM_SPDShutDownQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDShutDownQuery  
GO  
  
-- v2016.04.21  
  
-- SHUT-DOWN일정등록(우레탄)-조회 by 이재천   
CREATE PROC KPXCM_SPDShutDownQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT, 
            @StdYear    NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit    = ISNULL( FactUnit, 0 ),  
           @StdYear     = ISNULL( StdYear, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT,  
            StdYear    NCHAR(8)     
           )    
    
    -- 최종조회   
    SELECT A.SrtDate, 
           A.EndDate, 
           A.SrtTimeSeq, 
           B.MinorName AS SrtTime, 
           A.EndTimeSeq, 
           C.MinorName AS EndTime, 
           A.Remark, 
           A.SDSeq 
      FROM KPXCM_TPDShutDown        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SrtTimeSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.EndTimeSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @StdYear = '' OR LEFT(A.SrtDate,4) = @StdYear ) 
       AND ( @FactUnit = 0 OR A.FactUnit = @FactUnit ) 
      
    RETURN  