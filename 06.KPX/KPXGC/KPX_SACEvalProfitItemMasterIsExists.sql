  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterIsExists') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterIsExists  
GO  
  
-- v2014.12.20  
  
-- 평가손익상품마스터- 데이터존재여부 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterIsExists  
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
            @StdDate    NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate   = ISNULL( StdDate, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdDate    NCHAR(8))    
    
    -- 최종조회   
    IF EXISTS (SELECT 1 FROM KPX_TACEvalProfitItemMaster WHERE CompanySeq = @CompanySeq AND StdDate = @StdDate) 
    BEGIN
        SELECT '1' AS IsExists 
    END 
    ELSE 
    BEGIN
        SELECT '0' AS IsExists 
    END 
    
    RETURN  