  
IF OBJECT_ID('KPXCM_SPDDailyProdBasisQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyProdBasisQuery  
GO  
  
-- v2016.05.10  
  
-- 일일생산량관리기준정보입력(전자재료)-조회 by 이재천   
CREATE PROC KPXCM_SPDDailyProdBasisQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @UMItemKind INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @UMItemKind = ISNULL( UMItemKind, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( UMItemKind INT )    
      
    -- 최종조회   
    SELECT UnitProcSeq, UnitProcName, Sort, Remark 
      FROM KPXCM_TPDDailyProdBasis AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND A.UMItemKind  = @UMItemKind 
    
    RETURN  