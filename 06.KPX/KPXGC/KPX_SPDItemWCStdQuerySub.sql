  
IF OBJECT_ID('KPX_SPDItemWCStdQuerySub') IS NOT NULL   
    DROP PROC KPX_SPDItemWCStdQuerySub  
GO  
  
-- v2014.09.25  
  
-- 제품별설비기준등록-Item조회 by 이재천   
CREATE PROC KPX_SPDItemWCStdQuerySub  
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
            @ItemSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq   = ISNULL( ItemSeq, 0 )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ItemSeq INT)    
      
    -- 최종조회   
    SELECT B.WorkCenterName AS WorkCenter, 
           A.WorkCenterSeq, 
           C.ProcName, 
           A.ProcSeq, 
           A.StdProdTime, 
           ( LEFT(A.StdProdTime,2) * 60 ) + RIGHT(A.StdProdTime,2) AS ProdTimeMin, 
           A.WCCapacity, 
           A.Gravity, 
           A.IsUse, 
           A.WorkCenterSeq AS WorkCenterSeqOld, 
           A.ProcSeq AS ProcSeqOld
      FROM KPX_TPDItemWCStd                 AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDBaseProcess       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProcSeq = A.ProcSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ItemSeq = @ItemSeq 
    
    RETURN  
