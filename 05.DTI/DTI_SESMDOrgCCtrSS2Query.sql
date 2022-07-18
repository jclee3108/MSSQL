
IF OBJECT_ID('DTI_SESMDOrgCCtrSS2Query') IS NOT NULL 
    DROP PROC DTI_SESMDOrgCCtrSS2Query
GO 

-- v2014.06.24 

-- 손익조직등록_DTI(시트2조회) by이재천
CREATE PROC DTI_SESMDOrgCCtrSS2Query                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       
AS        
    
    DECLARE @docHandle  INT,
            @CCtrSeqOld INT, 
            @CostYM     NCHAR(6)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CCtrSeqOld = ISNULL(CCtrSeqOld,0), 
           @CostYM = ISNULL(CostYM,'') 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            CCtrSeqOld INT, 
            CostYM     NCHAR(6) 
           )
    
    SELECT A.CostYM,
           A.CCtrSeq, 
           A.PrevCCtrSeq, 
           A.CCtrSeq AS CCtrSeqOld, 
           A.PrevCCtrSeq AS PrevCCtrSeqOld, 
           B.CCtrName, 
           C.CCtrName AS PrevCCtrName 
      FROM DTI_TESMDOrgCCtrPrevCCtr AS A 
      LEFT OUTER JOIN _TDACCtr      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.PrevCCtrSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CostYM = @CostYM 
       AND A.CCtrSeq = @CCtrSeqOld 
    
    RETURN
GO
exec DTI_SESMDOrgCCtrSS2Query @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <CCtrSeqOld>3144</CCtrSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CostYM>201403</CostYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016289,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013962
