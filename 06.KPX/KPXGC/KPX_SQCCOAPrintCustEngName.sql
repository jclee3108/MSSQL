
IF OBJECT_ID('KPX_SQCCOAPrintCustEngName') IS NOT NULL 
    DROP PROC KPX_SQCCOAPrintCustEngName
GO 

-- v2014.12.18    
    
-- 시험성적서발행(COA)-거래처 영어명 by 이재천     
CREATE PROC KPX_SQCCOAPrintCustEngName    
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
            @CustSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
      
    SELECT @CustSeq   = ISNULL( CustSeq, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (
            CustSeq    INT 
           )    
    
    SELECT A.EngCustSName AS CustEngName
      FROM _TDACustAdd AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CustSeq = @CustSeq 
    
    RETURN 
