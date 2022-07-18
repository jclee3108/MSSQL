
IF OBJECT_ID('DTI_SPNPayPlanCheck') IS NOT NULL
    DROP PROC DTI_SPNPayPlanCheck
    
GO

-- v2013.07.01

-- [경영계획]급여계획등록(확인)_DTI by 이재천
CREATE PROC DTI_SPNPayPlanCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @MessageType    INT,
            @Status         INT,
            @Results        NVARCHAR(250)
  					
    CREATE TABLE #DTI_TPNPayPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPNPayPlan'
    IF @@ERROR <> 0 RETURN  

    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리 
     
    IF @WorkingTag <> 'Delete'
    IF NOT EXISTS ( SELECT 1   
                      FROM #DTI_TPNPayPlan AS A   
                      JOIN DTI_TPNPayPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.AccUnit = B.AccUnit AND A.PlanYear = B.PlanYear AND A.Serl = B.Serl )   
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #DTI_TPNPayPlan  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- 체크1, 회계단위, 계획년도별 MAX값으로 연속적이게 채번되도록   
     
    DECLARE @MaxSerl INT,
            @Count   INT
    SELECT @Count = Count(1) FROM #DTI_TPNPayPlan WHERE WorkingTag = 'A' AND Status = 0
    SELECT @MaxSerl = ISNULL(MAX(B.Serl),0) 
      FROM #DTI_TPNPayPlan AS A
      LEFT OUTER JOIN  DTI_TPNPayPlan AS B ON ( B.CompanySeq= 1 AND B.AccUnit = A.AccUnit AND B.PlanYear = A.PlanYear ) 
     GROUP BY A.AccUnit,A.PlanYear
    
    IF @Count > 0
    BEGIN
        UPDATE A
           SET A.Serl = @MaxSerl + A.DataSeq
          FROM #DTI_TPNPayPlan AS A 

         WHERE WorkingTag = 'A'
           AND Status = 0
    END
    
    -- 체크1, END
          
    SELECT * FROM #DTI_TPNPayPlan 
    
    RETURN    
GO