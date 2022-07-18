
IF OBJECT_ID('DTI_SPJTSalesProfitListRevSet') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListRevSet
GO 

-- v2014.03.20 

-- 프로젝트별매출이익현황_DTI(최종차수셋팅) by이재천
CREATE PROC dbo.DTI_SPJTSalesProfitListRevSet
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TPJTSalesProfitPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPJTSalesProfitPlan' 
    
    UPDATE A 
       SET PlanRev = (SELECT MAX(Rev) FROM DTI_TPJTSalesProfitPlan WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq)
      FROM #DTI_TPJTSalesProfitPlan AS A 
     
    SELECT * FROM #DTI_TPJTSalesProfitPlan 
    
    RETURN 
