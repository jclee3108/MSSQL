  
IF OBJECT_ID('KPXCM_SARBizTripCostSave') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostSave  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-저장 by 이재천   
CREATE PROC KPXCM_SARBizTripCostSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TARBizTripCost (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TARBizTripCost'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TARBizTripCost')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TARBizTripCost'    , -- 테이블명        
                  '#KPXCM_TARBizTripCost'    , -- 임시 테이블명        
                  'BizTripSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    
    
    -- 결근자 입력 (기초데이터) 
    CREATE TABLE #TPRWkAbsEmp
    (
        IDX_NO          INT IDENTITY, 
        BizTripSeq      INT, 
        AbsDate         NCHAR(8), 
        EmpSeq          INT, 
        WkItemSeq       INT, 
        IsHalf          NCHAR(1), 
        Remark          NVARCHAR(500)
    )
    INSERT INTO #TPRWkAbsEmp ( BizTripSeq, AbsDate, EmpSeq, WkItemSeq, IsHalf, Remark ) 
    SELECT A.BizTripSeq, B.Solar, A.TripEmpSeq, A.WkItemSeq, '0' AS IsHalf, A.Purpose AS Remark 
      FROM #KPXCM_TARBizTripCost AS A 
      JOIN _TCOMCalendar AS B ON ( B.Solar BETWEEN A.TripFrDate AND TripToDate ) 
     WHERE NOT EXISTS (SELECT 1 FROM _TCOMCalendarHoliday WHERE CompanySeq = @CompanySeq AND Solar = B.Solar) 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCost WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXCM_TARBizTripCost AS A   
          JOIN KPXCM_TARBizTripCost AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #KPXCM_TARBizTripCost     AS A   
          JOIN KPXCM_TARBizTripCostItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  

        DELETE C  
          FROM #KPXCM_TARBizTripCost        AS A 
          JOIN KPXCM_TARBizTripCostAbsEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq ) 
          JOIN _TPRWkAbsEmp                 AS C ON ( C.CompanySeq = @CompanySeq AND C.AbsDate = B.AbsDate AND C.EmpSeq = B.EmpSeq AND C.WkItemSeq = B.WkItemSeq ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN  
        
        DELETE B
          FROM #KPXCM_TARBizTripCost        AS A 
          JOIN KPXCM_TARBizTripCostAbsEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN 
        
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCost WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.RegDate         = A.RegDate       ,  
               B.RegEmpSeq       = A.RegEmpSeq     ,  
               B.TripEmpSeq      = A.TripEmpSeq    ,  
               B.TripDeptSeq     = A.TripDeptSeq   ,  
               B.TripCCtrSeq     = A.TripCCtrSeq   ,  
               B.CostSeq         = A.CostSeq       ,  
               B.RemValSeq       = A.RemValSeq     ,  
               B.TripPlace       = A.TripPlace     ,  
               B.TripCust        = A.TripCust      ,  
               B.TripFrDate      = A.TripFrDate    ,  
               B.TripToDate      = A.TripToDate    ,  
               B.Purpose         = A.Purpose       ,  
               B.Contents        = A.Contents      ,  
               B.TripPerson      = A.TripPerson    ,  
               B.PayReqDate      = A.PayReqDate    ,  
               B.AccUnit         = A.AccUnit       ,  
               B.WkitemSeq       = A.WkitemSeq     , 
               B.LastUserSeq     = @UserSeq        ,  
               B.LastDateTime    = GETDATE()       ,  
               B.PgmSeq          = @PgmSeq    
          FROM #KPXCM_TARBizTripCost AS A   
          JOIN KPXCM_TARBizTripCost AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE C  
          FROM #KPXCM_TARBizTripCost        AS A 
          JOIN KPXCM_TARBizTripCostAbsEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq ) 
          JOIN _TPRWkAbsEmp                 AS C ON ( C.CompanySeq = @CompanySeq AND C.AbsDate = B.AbsDate AND C.EmpSeq = B.EmpSeq AND C.WkItemSeq = B.WkItemSeq ) 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN  
        
        DELETE B
          FROM #KPXCM_TARBizTripCost        AS A 
          JOIN KPXCM_TARBizTripCostAbsEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq ) 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN 
        
        -- 연결테이블 
        INSERT INTO KPXCM_TARBizTripCostAbsEmp 
        ( 
            CompanySeq, BizTripSeq, AbsDate, EmpSeq, WkItemSeq, 
            LastUserSeq, LastDateTime, PgmSeq 
        ) 
        SELECT @CompanySeq, BizTripSeq, AbsDate, EmpSeq, WkItemSeq, 
               @UserSeq, GETDATE(), @PgmSeq 
          FROM #TPRWkAbsEmp 
        
        -- 결근자 입력 
        INSERT INTO _TPRWkAbsEmp 
        (
            CompanySeq, AbsDate, EmpSeq, WkItemSeq, IsHalf, 
            Remark, LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, AbsDate, EmpSeq, WkItemSeq, IsHalf, 
               Remark, @UserSeq, GETDATE() 
          FROM #TPRWkAbsEmp
        
        
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCost WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TARBizTripCost  
        (   
           CompanySeq, BizTripSeq, BizTripNo, RegDate, RegEmpSeq, 
           TripEmpSeq, TripDeptSeq, TripCCtrSeq, CostSeq, RemValSeq, 
           TripPlace, TripCust, TripFrDate, TripToDate, Purpose, 
           Contents, TripPerson, PayReqDate, AccUnit, WkItemSeq, 
           LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.BizTripSeq, A.BizTripNo, A.RegDate, A.RegEmpSeq, 
               A.TripEmpSeq, A.TripDeptSeq, A.TripCCtrSeq, A.CostSeq, A.RemValSeq, 
               A.TripPlace, A.TripCust, A.TripFrDate, A.TripToDate, A.Purpose, 
               A.Contents, A.TripPerson, A.PayReqDate, A.AccUnit, A.WkItemSeq, 
               @UserSeq, GETDATE(), @PgmSeq   
          FROM #KPXCM_TARBizTripCost AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
        
        -- 연결테이블 
        INSERT INTO KPXCM_TARBizTripCostAbsEmp 
        ( 
            CompanySeq, BizTripSeq, AbsDate, EmpSeq, WkItemSeq, 
            LastUserSeq, LastDateTime, PgmSeq 
        ) 
        SELECT @CompanySeq, BizTripSeq, AbsDate, EmpSeq, WkItemSeq, 
               @UserSeq, GETDATE(), @PgmSeq 
          FROM #TPRWkAbsEmp 
        
        -- 결근자 입력 
        INSERT INTO _TPRWkAbsEmp 
        (
            CompanySeq, AbsDate, EmpSeq, WkItemSeq, IsHalf, 
            Remark, LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, AbsDate, EmpSeq, WkItemSeq, IsHalf, 
               Remark, @UserSeq, GETDATE() 
          FROM #TPRWkAbsEmp
        
    END     
    
    SELECT * FROM #KPXCM_TARBizTripCost   
      
    RETURN  
go 
begin tran 
exec KPXCM_SARBizTripCostSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <AccUnit>1</AccUnit>
    <AccUnitName>본사</AccUnitName>
    <BizTripNo>201509030001</BizTripNo>
    <BizTripSeq>4</BizTripSeq>
    <Contents>1박2일 일정</Contents>
    <CostName>일반</CostName>
    <CostSeq>1011517003</CostSeq>
    <PayReqDate>20150912</PayReqDate>
    <Purpose>비즈니스</Purpose>
    <RegDate>20150903</RegDate>
    <RegEmpName>이재천</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <RemValName />
    <RemValSeq>0</RemValSeq>
    <TripCCtrName />
    <TripCCtrSeq>0</TripCCtrSeq>
    <TripCust>출장업체</TripCust>
    <TripDeptName>사업개발팀</TripDeptName>
    <TripDeptSeq>147</TripDeptSeq>
    <TripEmpName>이재천</TripEmpName>
    <TripEmpSeq>2028</TripEmpSeq>
    <TripFrDate>20150901</TripFrDate>
    <TripPerson>이재천</TripPerson>
    <TripPlace>일본</TripPlace>
    <TripToDate>20150910</TripToDate>
    <WkItemName>외출</WkItemName>
    <WkItemSeq>90</WkItemSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397

--select * from KPXCM_TARBizTripCost 
--select * from KPXCM_TARBizTripCostAbsEmp 
--select * from _TPRWkAbsEmp where lastuserseq = 50322
rollback 