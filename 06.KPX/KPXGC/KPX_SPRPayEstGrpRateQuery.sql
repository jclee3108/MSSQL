  
IF OBJECT_ID('KPX_SPRPayEstGrpRateQuery') IS NOT NULL   
    DROP PROC KPX_SPRPayEstGrpRateQuery  
GO  
  
-- v2014.12.15  
  
-- 급여추정 직급별인상율-조회 by 이재천   
CREATE PROC KPX_SPRPayEstGrpRateQuery  
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
            @YY         NCHAR(4), 
            @UMPayType  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YY   = ISNULL( YY, 0 ), 
           @UMPayType = ISNULL( UMPayType, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (    
            YY          NCHAR(4), 
            UMPayType   INT 
           )    
    
    -- 최종조회   
    SELECT A.YY, 
           A.UMPayType, 
           B.MinorName AS UMPayTypeName, -- 급여형태
           A.UMPgSeq, 
           C.MinorName AS UMPgName, -- 직급 
           A.UMPgSeq AS UMPgSeqOld, 
           A.EstRate, 
           A.AddRate, 
           A.Remark 
      FROM KPX_TPRPayEstGrpRate     AS A  
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPayType ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMPgSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.YY = @YY )   
       AND ( @UMPayType = A.UMPayType ) 
      
    RETURN  