
IF OBJECT_ID('DTI_SESMBGPCostAdjStdQuery') IS NOT NULL 
    DROP PROC DTI_SESMBGPCostAdjStdQuery 
GO

-- v2014.01.03 

-- 손익분석 비용조정 기준등록_DTI(조회) by이재천
CREATE PROC DTI_SESMBGPCostAdjStdQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0       
AS        
    
    DECLARE @docHandle      INT,
            @CostYM        NCHAR(6)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CostYM = CostYM         
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (CostYM NCHAR(6))
    
    SELECT D.Minorname AS SMAccTypeName, 
           A.CCtrSeq, 
           A.AdjCCtrSeq, 
           A.SMAccType, 
           C.CCtrName AS AdjCCtrName, 
           B.CCtrName AS CCtrName, 
           A.CCtrSeq AS CCtrSeqOld, 
           A.SMAccType AS SMAccTypeOld 
      FROM DTI_TESMBGPCostAdjStd    AS A  
      LEFT OUTER JOIN _TDACCtr      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.AdjCCtrSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMAccType ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.CostYM = @CostYM        
    
    RETURN

