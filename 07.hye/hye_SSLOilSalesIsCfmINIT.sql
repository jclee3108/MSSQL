 
IF OBJECT_ID('hye_SSLOilSalesIsCfmINIT') IS NOT NULL   
    DROP PROC hye_SSLOilSalesIsCfmINIT  
GO  
  
-- v2016.11.04 
  
-- 주유소판매제출-초기셋팅 by 이재천
CREATE PROC hye_SSLOilSalesIsCfmINIT 
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
            @BizUnit    INT, 
            @StdDate    NCHAR(8), 
            @StdYM      NCHAR(6), 
            @IsCfm      NCHAR(1)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),  
           @StdDate     = ISNULL( StdDate, '' ),  
           @StdYM       = ISNULL( StdYM  , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )       
      WITH (
            BizUnit    INT,       
            StdDate    NCHAR(8),      
            StdYM      NCHAR(6)       
           )    

    SELECT @IsCfm = IsCfm 
      FROM hye_TSLOilSalesIsCfm AS A 
     WHERE A.Companyseq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND A.StdYMDate = CASE WHEN @StdDate = '' THEN @StdYM ELSE @StdDate END 
    
    SELECT ISNULL(@IsCfm,'0') AS IsCfm 
    
RETURN 
GO
exec hye_SSLOilSalesIsCfmINIT @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit>902</BizUnit>
    <StdYM>201606</StdYM>
  </DataBlock15>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730148,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730039

