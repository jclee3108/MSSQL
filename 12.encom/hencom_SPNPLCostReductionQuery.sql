 
IF OBJECT_ID('hencom_SPNPLCostReductionQuery') IS NOT NULL   
    DROP PROC hencom_SPNPLCostReductionQuery  
GO  
  
-- v2017.04.27 
  
-- 원가절감목표금액등록_hencom-조회 by 이재천
CREATE PROC hencom_SPNPLCostReductionQuery  
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
            @DeptSeq    INT, 
            @PlanSeq    INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DeptSeq   = ISNULL( DeptSeq, 0 ),  
           @PlanSeq   = ISNULL( PlanSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              DeptSeq    INT, 
              PlanSeq    INT 
           )    
    
    -- 최종조회   
    SELECT DeptSeq, PlanSeq, PlanSerl, Month01, Month02, 
           Month03, Month04, Month05, Month06, Month07, 
           Month08, Month09, Month10, Month11, Month12, 
           Remark
      FROM hencom_TPNPLCostReduction AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.DeptSeq = @DeptSeq 
       AND A.PlanSeq = @PlanSeq 
    
    RETURN  