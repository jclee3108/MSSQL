
IF OBJECT_ID('yw_SLGASProcPlanSave') IS NOT NULL
    DROP PROC yw_SLGASProcPlanSave
GO

-- v2013.07.17

-- AS처리방안_YW(저장) by이재천
CREATE PROC yw_SLGASProcPlanSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    	
    CREATE TABLE #YW_TLGASProcPlan (WorkingTag NCHAR(1) NULL) 
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TLGASProcPlan' 
    IF @@ERROR <> 0 RETURN 
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TLGASProcPlan')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TLGASProcPlan'    , -- 테이블명        
                  '#YW_TLGASProcPlan'    , -- 임시 테이블명        
                  'ASRegSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   	    
    
    UPDATE #YW_TLGASProcPlan
       SET WorkingTag = 'U'
      FROM #YW_TLGASProcPlan AS A
     WHERE ASRegSeq IN (SELECT ASRegSeq FROM YW_TLGASProcPlan WHERE CompanySeq = 1)
       AND WorkingTag = 'U'
       
    UPDATE #YW_TLGASProcPlan
       SET WorkingTag = 'A'
      FROM #YW_TLGASProcPlan AS A
     WHERE ASRegSeq NOT IN (SELECT ASRegSeq FROM YW_TLGASProcPlan WHERE CompanySeq = 1)
       AND WorkingTag = 'U'
    
    

    -- 작업순서 : DELETE -> UPDATE -> INSERT 

	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
        DELETE B
          FROM #YW_TLGASProcPlan A 
          JOIN YW_TLGASProcPlan B ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq ) 
                 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0  
          
        IF @@ERROR <> 0  RETURN
    
	END  


	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET UMLastDecision   = A.UMLastDecision, 
               UMLotMagnitude   = A.UMLotMagnitude, 
               UMBadMagnitude   = A.UMBadMagnitude, 
               UMMkind          = A.UMMkind, 
               UMMtype          = A.UMMtype, 
               UMIsEnd          = A.UMIsEnd, 
               UMProbleSubItem  = A.UMProbleSubItem, 
               UMProbleSemiItem = A.UMProbleSemiItem,	
               UMBadType        = A.UMBadType,
               UMBadLKind       = A.UMBadLKind,
               UMBadMKind       = A.UMBadMKind,
               UMResponsType    = A.UMResponsType, 
               ResponsProc      = A.ResponsProc, 
               ResponsDept      = A.ResponsDept, 
               ProcDept         = A.ProcDept, 
               ProbleCause      = A.ProbleCause, 
               ImsiProc         = A.ImsiProc, 
               ImsiEmp          = A.ImsiEmp, 
               ImsiDate         = A.ImsiDate, 	
               RootProc         = A.RootProc, 	
               RootEmp          = A.RootEmp, 
               RootDate         = A.RootDate, 	
               EndDate          = A.EndDate, 
               LastUserSeq      = @UserSeq, 
               LastDateTime     = GetDate() 
        
          FROM #YW_TLGASProcPlan AS A 
          JOIN YW_TLGASProcPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq ) 
         
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    

        IF @@ERROR <> 0  RETURN
    END  
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO YW_TLGASProcPlan 
        (
         CompanySeq  , ASRegSeq   , UMLastDecision   , UMLotMagnitude  , UMBadMagnitude   ,									
         UMMkind     , UMMtype    , UMIsEnd          , UMProbleSubItem , UMProbleSemiItem , 
         UMBadType   , UMBadLKind , UMBadMKind       , UMResponsType   , ResponsProc      ,
         ResponsDept , ProcDept   , ProbleCause      , ImsiProc        , ImsiEmp          ,
         ImsiDate    , RootProc   , RootEmp,RootDate , EndDate         , LastUserSeq      , LastDateTime
        ) 
        SELECT @CompanySeq , ASRegSeq   , UMLastDecision   , UMLotMagnitude  , UMBadMagnitude   ,									
               UMMkind     , UMMtype    , UMIsEnd          , UMProbleSubItem , UMProbleSemiItem , 
               UMBadType   , UMBadLKind , UMBadMKind       , UMResponsType   , ResponsProc      ,
               ResponsDept , ProcDept   , ProbleCause      , ImsiProc        , ImsiEmp          ,
               ImsiDate    , RootProc   , RootEmp,RootDate , EndDate         , @UserSeq         , GetDate() 
    
          FROM #YW_TLGASProcPlan AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
    
        IF @@ERROR <> 0 RETURN
    
    END   
    
    SELECT * FROM #YW_TLGASProcPlan 
    
    RETURN    

GO
begin tran
exec yw_SLGASProcPlanSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ASRegSeq>48</ASRegSeq>
    <ASRegDate>20130717</ASRegDate>
    <ASRegNo>AS-201307-0022</ASRegNo>
    <ASState>ff</ASState>
    <BadRate>1.00000</BadRate>
    <Confirm>0</Confirm>
    <CustEmpName>이재천</CustEmpName>
    <CustItemName>11</CustItemName>
    <CustName>(명)새한감정평가법인</CustName>
    <CustRemark>fffffff</CustRemark>
    <CustSeq>37606</CustSeq>
    <EndDate>20130712</EndDate>
    <ImsiDate>23</ImsiDate>
    <ImsiEmp>251</ImsiEmp>
    <ImsiEmpName>anh</ImsiEmpName>
    <ImsiProc>31</ImsiProc>
    <IsStop>1</IsStop>
    <ItemName>12345678901234567890123456789012345678901</ItemName>
    <ItemNo>12345612</ItemNo>
    <ItemSeq>24789</ItemSeq>
    <OrderItemNo>130700039</OrderItemNo>
    <OutDate xml:space="preserve">        </OutDate>
    <ProbleCause>2</ProbleCause>
    <ProcDept>1512</ProcDept>
    <ProcDeptName>3</ProcDeptName>
    <ResponsDept>131</ResponsDept>
    <ResponsProc>12</ResponsProc>
    <RootDate>123412</RootDate>
    <RootEmp>251</RootEmp>
    <RootEmpName>anh</RootEmpName>
    <RootProc>12</RootProc>
    <Sel>0</Sel>
    <SMLocalType>8918001</SMLocalType>
    <SMLocalTypeName>내수</SMLocalTypeName>
    <TargetQty>5.00000</TargetQty>
    <UMASMClass>10011001</UMASMClass>
    <UMASMClassName>TestM</UMASMClassName>
    <UMBadLKind>1008287002</UMBadLKind>
    <UMBadLKindName>불량유형대2</UMBadLKindName>
    <UMBadMagnitude>1008280001</UMBadMagnitude>
    <UMBadMagnitudeName>결점심각도1</UMBadMagnitudeName>
    <UMBadMKind>1008288002</UMBadMKind>
    <UMBadMKindName>불량유형중2</UMBadMKindName>
    <UMBadType>1008286002</UMBadType>
    <UMBadTypeName>불량구분2</UMBadTypeName>
    <UMFindKind>1008276001</UMFindKind>
    <UMFindKindName>입고검사</UMFindKindName>
    <UMIsEnd>1008283001</UMIsEnd>
    <UMIsEndName>종결여부1</UMIsEndName>
    <UMLastDecision>1008278001</UMLastDecision>
    <UMLastDecisionName>최종판단1</UMLastDecisionName>
    <UMLotMagnitude>1008279001</UMLotMagnitude>
    <UMLotMagnitudeName>Lot심각도1</UMLotMagnitudeName>
    <UMMkind>1008281001</UMMkind>
    <UMMkindName>4m분류1</UMMkindName>
    <UMMtype>1008282001</UMMtype>
    <UMMtypeName>4m내용1</UMMtypeName>
    <UMProbleSemiItem>1008285002</UMProbleSemiItem>
    <UMProbleSemiItemName>문제부품2</UMProbleSemiItemName>
    <UMProbleSubItem>1008284002</UMProbleSubItem>
    <UMProbleSubItemName>문제반제품2</UMProbleSubItemName>
    <UMResponsType>1008289001</UMResponsType>
    <UMResponsTypeName>귀책구분1</UMResponsTypeName>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ASRegSeq>49</ASRegSeq>
    <ASRegDate>20130717</ASRegDate>
    <ASRegNo>AS-201307-0023</ASRegNo>
    <ASState>ㄷㅅㄴㄷㄱㄴㅇㄹ</ASState>
    <BadRate>123.00000</BadRate>
    <Confirm>1</Confirm>
    <CustEmpName>이재천</CustEmpName>
    <CustItemName />
    <CustName>(주)지에스왓슨스</CustName>
    <CustRemark>ㄴㅇㄹㄹ</CustRemark>
    <CustSeq>42125</CustSeq>
    <EndDate>20130712</EndDate>
    <ImsiDate>23</ImsiDate>
    <ImsiEmp>251</ImsiEmp>
    <ImsiEmpName>anh</ImsiEmpName>
    <ImsiProc>31</ImsiProc>
    <IsStop>0</IsStop>
    <ItemName>선풍기_희정</ItemName>
    <ItemNo>선풍기_희정</ItemNo>
    <ItemSeq>24762</ItemSeq>
    <OrderItemNo>20120210</OrderItemNo>
    <OutDate>20130712</OutDate>
    <ProbleCause>2</ProbleCause>
    <ProcDept>1512</ProcDept>
    <ProcDeptName>3</ProcDeptName>
    <ResponsDept>131</ResponsDept>
    <ResponsProc>12</ResponsProc>
    <RootDate>12</RootDate>
    <RootEmp>251</RootEmp>
    <RootEmpName>anh</RootEmpName>
    <RootProc>12</RootProc>
    <Sel>0</Sel>
    <SMLocalType>8918001</SMLocalType>
    <SMLocalTypeName>내수</SMLocalTypeName>
    <TargetQty>23.00000</TargetQty>
    <UMASMClass>10011001</UMASMClass>
    <UMASMClassName>TestM</UMASMClassName>
    <UMBadLKind>1008287002</UMBadLKind>
    <UMBadLKindName>불량유형대2</UMBadLKindName>
    <UMBadMagnitude>1008280001</UMBadMagnitude>
    <UMBadMagnitudeName>결점심각도1</UMBadMagnitudeName>
    <UMBadMKind>1008288002</UMBadMKind>
    <UMBadMKindName>불량유형중2</UMBadMKindName>
    <UMBadType>1008286002</UMBadType>
    <UMBadTypeName>불량구분2</UMBadTypeName>
    <UMFindKind>1008276001</UMFindKind>
    <UMFindKindName>입고검사</UMFindKindName>
    <UMIsEnd>1008283001</UMIsEnd>
    <UMIsEndName>종결여부1</UMIsEndName>
    <UMLastDecision>1008278001</UMLastDecision>
    <UMLastDecisionName>최종판단1</UMLastDecisionName>
    <UMLotMagnitude>1008279001</UMLotMagnitude>
    <UMLotMagnitudeName>Lot심각도1</UMLotMagnitudeName>
    <UMMkind>1008281001</UMMkind>
    <UMMkindName>4m분류1</UMMkindName>
    <UMMtype>1008282001</UMMtype>
    <UMMtypeName>4m내용1</UMMtypeName>
    <UMProbleSemiItem>1008285002</UMProbleSemiItem>
    <UMProbleSemiItemName>문제부품2</UMProbleSemiItemName>
    <UMProbleSubItem>1008284002</UMProbleSubItem>
    <UMProbleSubItemName>문제반제품2</UMProbleSubItemName>
    <UMResponsType>1008289001</UMResponsType>
    <UMResponsTypeName>귀책구분1</UMResponsTypeName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197
rollback