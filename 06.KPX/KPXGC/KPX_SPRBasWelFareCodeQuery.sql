  
IF OBJECT_ID('KPX_SPRBasWelFareCodeQuery') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeQuery  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-조회 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeQuery  
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
            @WelCodeName NVARCHAR(100)  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WelCodeName  = ISNULL( WelCodeName, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WelCodeName  NVARCHAR(100))    
      
    -- 최종조회   
    SELECT A.WelCodeSeq, 
           A.WelCodeName, 
           A.SMRegType, 
           B.MinorName AS SMRegTypeName, 
           A.YearLimite, 
           A.WelFareKind, 
           C.MinorName AS WelFareKindName 
           
      FROM KPX_THRWelCode               AS A 
      LEFT OUTER JOIN _TDASMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMRegType ) 
      LEFT OUTER JOIN _TDASMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.WelFareKind ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @WelCodeName = '' OR A.WelCodeName LIKE @WelCodeName + '%' )  
      
    RETURN  