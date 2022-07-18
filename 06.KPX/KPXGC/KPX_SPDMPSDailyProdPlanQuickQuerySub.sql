  
IF OBJECT_ID('KPX_SPDMPSDailyProdPlanQuickQuerySub') IS NOT NULL   
    DROP PROC KPX_SPDMPSDailyProdPlanQuickQuerySub  
GO  
  
-- v2014.10.06  
  
-- 선택배치-Item조회 by 이재천   
CREATE PROC KPX_SPDMPSDailyProdPlanQuickQuerySub  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @WorkCenterSeq  INT,  
            @ProcSeq        INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkCenterSeq = ISNULL( WorkCenterSeq, 0 ),  
           @ProcSeq = ISNULL( ProcSeq, '' )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkCenterSeq   INT ,   
            ProcSeq         INT 
           )    
    
    -- 최종조회   
    SELECT B.ItemName, B.ItemNo, B.Spec, A.ItemSeq 
      FROM KPX_TPDItemWCStd     AS A 
      LEFT OUTER JOIN _TDAItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WorkCenterSeq = @WorkCenterSeq 
    RETURN  
GO
exec KPX_SPDMPSDailyProdPlanQuickQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <WorkCenterSeq>100315</WorkCenterSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024882,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020927