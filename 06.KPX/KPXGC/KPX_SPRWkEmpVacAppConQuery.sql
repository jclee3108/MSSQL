
IF OBJECT_ID('KPX_SPRWkEmpVacAppConQuery') IS NOT NULL 
    DROP PROC KPX_SPRWkEmpVacAppConQuery
GO 

-- v2014.11.27 

-- 휴가신청(경조금조회) by이재천 
CREATE PROC KPX_SPRWkEmpVacAppConQuery                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,
            @WkItemSeq  INT ,
            @CCSeq      INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @WkItemSeq = ISNULL(WkItemSeq,0), 
           @CCSeq     = ISNULL(CCSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (WkItemSeq  INT ,
            CCSeq      INT )
    
    SELECT TOP 1 
           B.ItemName + ' * ' + CONVERT(NVARCHAR(10),CONVERT(INT,A.Numerator)) + '/' + CONVERT(NVARCHAR(10),CONVERT(INT,A.Denominator)) AS StdCon, -- 기준 
           0 AS ConAmt  -- 경조금 
      FROM KPX_THRWelConAmt AS A 
      LEFT OUTER JOIN _TPRBasPayItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.WkItemSeq ) 
      WHERE A.CompanySeq = @CompanySeq
        AND A.ConSeq = @CCSeq 
        AND A. WkItemSeq = @WkItemSeq 
    
    RETURN
GO 
exec KPX_SPRWkEmpVacAppConQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WkItemSeq>1</WkItemSeq>
    <CCSeq>1</CCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026265,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022017    
