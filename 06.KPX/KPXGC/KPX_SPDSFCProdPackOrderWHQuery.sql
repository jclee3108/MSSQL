  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderWHQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderWHQuery  
GO  
  
-- v2014.11.25 
  
-- 포장작업지시입력- 창고 조회 by 작성자   
CREATE PROC KPX_SPDSFCProdPackOrderWHQuery  
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
            @FactUnit   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FactUnit   = ISNULL( FactUnit, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (FactUnit   INT)    
    
    -- 최종조회   
    SELECT TOP 1 
           A.WHSeq AS OutWHSeq, 
           A.WHName AS OutWHName, 
           B.WHSeq AS InWHSeq, 
           B.WHName AS InWHName, 
           C.WHSeq AS SubOutWHSeq, 
           C.WHName AS SubOutWHName
      FROM _TDAWH AS A  
      OUTER APPLY (SELECT TOP 1 WHSeq, WHName 
                     FROM _TDAWH AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.FactUnit = A.FactUnit 
                      AND WMSCode = '2' 
                  ) AS B 
      OUTER APPLY (SELECT TOP 1 WHSeq, WHName 
                     FROM _TDAWH AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.FactUnit = A.FactUnit 
                      AND WMSCode = '3' 
                  ) AS C 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND A.WMSCode = '1' 
      
    RETURN  
GO 
exec KPX_SPDSFCProdPackOrderWHQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349