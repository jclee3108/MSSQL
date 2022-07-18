
IF OBJECT_ID('DTI_SPJTSalesProfitListCreateCheck') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListCreateCheck
GO 

-- v2014.03.19 

-- 프로젝트별매출이익현황_DTI(계획집계체크) by이재천
CREATE PROC dbo.DTI_SPJTSalesProfitListCreateCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   
    
    DECLARE @MessageType INT, 
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TPJTSalesProfitPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPJTSalesProfitPlan' 
    
    IF (
         SELECT MAX(B.Rev)
         FROM #DTI_TPJTSalesProfitPlan AS A 
         JOIN DTI_TPJTSalesProfitPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
       ) <> 0 
    BEGIN 
        UPDATE #DTI_TPJTSalesProfitPlan
           SET Result = N'차수 등록 된 데이터는 계획집계를 할 수 없습니다.',  
               MessageType = 1234, 
               Status = 1234
    END 
    
    SELECT * FROM #DTI_TPJTSalesProfitPlan 
    
    RETURN    
