  
IF OBJECT_ID('KPXCM_SPDMPSDailyProdPlanQuickBaseGroupQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDMPSDailyProdPlanQuickBaseGroupQuery  
GO  
  
-- v206.04.06
  
-- 선택배치-초기그룹 by 이재천
CREATE PROC KPXCM_SPDMPSDailyProdPlanQuickBaseGroupQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @ProdPlanSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ProdPlanSeq   = ISNULL( ProdPlanSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ProdPlanSeq   INT)    
    
    -- 최종조회   
    SELECT DISTINCT C.ValueText AS WCFlg
      FROM _TPDMPSDailyProdPlan             AS Z 
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS A ON ( A.CompanySeq = Z.CompanySeq AND A.WorkCenterSeq = Z.WorkcenterSeq ) 
      Left Outer Join _TDAUMinorValue       AS B ON ( A.CompanySeq = B.CompanySeq And B.MajorSeq = 1011333 and B.SERL = 1000001 And A.WorkCenterSeq = B.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS C ON ( B.CompanySeq = C.CompanySeq AND C.MinorSeq = B.MinorSeq  AND C.Serl = 1000002 ) 
     WHERE Z.CompanySeq = @CompanySeq
       AND Z.ProdPlanSeq = @ProdPlanSeq  
    
    RETURN  