      
IF OBJECT_ID('DTI_SESMDEmpCCtrRatioCheck') IS NOT NULL   
    DROP PROC DTI_SESMDEmpCCtrRatioCheck  
GO  
    
-- v2013.06.26 
  
-- 사원별 활동센터 배부율 등록(확인)_DTI by 이재천 
CREATE PROC DTI_SESMDEmpCCtrRatioCheck  
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
  					
    CREATE TABLE #DTI_TESMDEmpCCtrRatio (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMDEmpCCtrRatio'
    IF @@ERROR <> 0 RETURN	
    
    --데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리 
     
    IF @WorkingTag <> 'Delete'
    AND NOT EXISTS ( SELECT 1   
                      FROM #DTI_TESMDEmpCCtrRatio AS A   
                      JOIN DTI_TESMDEmpCCtrRatio  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.CostYM = B.CostYM AND A.EmpSeqOld = B.EmpSeq AND A.CCtrSeqOld = B.CCtrSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0 
                  )  
    BEGIN  
        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
        
        UPDATE #DTI_TESMDEmpCCtrRatio  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- 체크대상 담기 
    SELECT A1.CostYM, A1.CCtrSeq, A1.EmpSeq, A1.EmpCnt
      INTO #TEMP_DTI_TESMDEmpCCtrRatio 
      FROM #DTI_TESMDEmpCCtrRatio AS A1  
     WHERE A1.WorkingTag IN ('A', 'U')  
       AND A1.Status = 0  
    
    UNION ALL   
    
    SELECT A1.CostYM, A1.CCtrSeq, A1.EmpSeq, A1.EmpCnt 
      FROM DTI_TESMDEmpCCtrRatio AS A1  
     WHERE A1.CompanySeq = @CompanySeq  
       AND A1.CostYM = (SELECT TOP 1 CostYM FROM #DTI_TESMDEmpCCtrRatio)
       AND NOT EXISTS (SELECT 1 FROM #DTI_TESMDEmpCCtrRatio   
                               WHERE WorkingTag IN ('U','D')   
                                 AND Status = 0   
                                 AND CostYM = A1.CostYM
                                 AND EmpSeqOld = A1.EmpSeq
                                 AND CCtrSeqOld = A1.CCtrSeq
                      )  
    
    -- 체크1, 소속부서의 활동센터가 아닌경우 저장 및 수정 할 수 없습니다.
    
    UPDATE A    
       SET A.Result       = N'소속부서의 활동센터가 아닌경우 저장 및 수정 할 수 없습니다.',    
           A.MessageType  = 1234,    
           A.Status       = 1234    
      FROM #DTI_TESMDEmpCCtrRatio AS A 
     WHERE WorkingTag IN ('A','U')
       AND Status = 0 
       AND NOT EXISTS (SELECT TOP 1 1 FROM _THROrgDeptCCtr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq AND DeptSeq = A.DeptSeq )

    -- 체크1, END
    
    -- 체크2, (원가년월+사원+손익활동센터)별 인원수의 합은 1이어야 합니다. 
    
    UPDATE A  
       SET A.Result       = N'(원가년월,사원)별 인원수의 합은 1이어야 합니다.',  
           A.MessageType  = 1234,  
           A.Status       = 1234  
      FROM #DTI_TESMDEmpCCtrRatio AS A 
     WHERE A.WorkingTag IN ('A', 'U')
       AND A.Status = 0  
       AND EXISTS (SELECT 1 
                     FROM #TEMP_DTI_TESMDEmpCCtrRatio AS S
                    GROUP BY S.EmpSeq, S.CostYM
                   HAVING SUM(S.EmpCnt) <> 1 
                  )
    
    -- 체크2, END 
    
    -- 체크3, 인원수가 0이 아니면 시트삭제가 되지 않도록
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT, 
						  @Status      OUTPUT, 
						  @Results     OUTPUT, 
						  1167              , -- @1은(는) 삭제할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%삭제%') 
						  @LanguageSeq       ,  
						  0,'인원수가 0이 아닌 것' 

	UPDATE #DTI_TESMDEmpCCtrRatio   
       SET Result        = @Results,   
           MessageType   = @MessageType,   
           Status        = @Status 
      FROM #DTI_TESMDEmpCCtrRatio AS A
      JOIN DTI_TESMDEmpCCtrRatio  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeqOld AND B.CCtrSeq = A.CCtrSeqOld AND B.EmpCnt <> 0)
     WHERE A.WorkingTag = 'D'
       AND A.Status = 0 
    
    -- 체크3, END 
    
    -- 체크4, 중복여부 체크 (원가년월,사원,활동센터)
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0,'',
                          0,''
    
    UPDATE A  
       SET A.Result       = @Results, --REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
           A.MessageType  = @MessageType,  
           A.Status       = @Status  
      FROM #DTI_TESMDEmpCCtrRatio AS A   
      JOIN (SELECT S.CCtrSeq, S.CostYM, S.EmpSeq  
              FROM #TEMP_DTI_TESMDEmpCCtrRatio AS S  
             GROUP BY S.CCtrSeq, S.CostYM, S.EmpSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.CostYM = B.CostYM AND A.CCtrSeq = B.CCtrSeq AND A.EmpSeq = B.EmpSeq )   
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- 체크4, END 
    
    SELECT * FROM #DTI_TESMDEmpCCtrRatio 
    
    RETURN 
    
GO