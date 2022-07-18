
 
IF OBJECT_ID('yw_SLGASProcPlanCheck') IS NOT NULL   
    DROP PROC yw_SLGASProcPlanCheck  
GO 

-- v2013.07.17

-- AS처리방안_YW(확인) by이재천
CREATE PROC yw_SLGASProcPlanCheck
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
    				
    CREATE TABLE #YW_TLGASProcPlan (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TLGASProcPlan'
    IF @@ERROR <> 0 RETURN 

    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리                  
    IF EXISTS ( SELECT 1   
                  FROM #YW_TLGASProcPlan AS A   
                  LEFT OUTER JOIN YW_TLGASReg AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq )  
                 WHERE A.WorkingTag IN ( 'U', 'D' )  
                   AND Status = 0
                   AND B.ASRegSeq IS NULL   
                  )  
    BEGIN               
        
        UPDATE A  
           SET Result       = 'AS접수 데이터가 존재하지 않습니다.',  
               MessageType  = @MessageType,  
               Status       = 123412  
          FROM #YW_TLGASProcPlan AS A
          LEFT OUTER JOIN YW_TLGASReg AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq )
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0 
           AND B.ASRegSeq IS NULL
    END   

    -- 체크1, 중복여부 체크 (ASRegSeq(AS접수코드))
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0,'',
                          0,''
      
    UPDATE #YW_TLGASProcPlan  
       SET Result       = @Results, --REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #YW_TLGASProcPlan AS A   
      JOIN (SELECT S.ASRegSeq  
              FROM (SELECT A1.ASRegSeq 
                      FROM #YW_TLGASProcPlan AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ASRegSeq  
                      FROM YW_TLGASProcPlan AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #YW_TLGASProcPlan   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ASRegSeq = A1.ASRegSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ASRegSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ASRegSeq = B.ASRegSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0 
    
    -- 체크1, END 
    
    SELECT * FROM #YW_TLGASProcPlan 
    
    RETURN 
Go
exec yw_SLGASProcPlanCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <Confirm>0</Confirm>
    <IsStop>0</IsStop>
    <ASRegDate>20130717</ASRegDate>
    <SMLocalTypeName>내수</SMLocalTypeName>
    <UMASMClassName>TestM</UMASMClassName>
    <CustName>(주)지에스왓슨스</CustName>
    <CustEmpName>이재천</CustEmpName>
    <CustItemName />
    <ItemNo>선풍기_희정</ItemNo>
    <ItemName>선풍기_희정</ItemName>
    <OrderItemNo>20120210</OrderItemNo>
    <OutDate />
    <TargetQty>5</TargetQty>
    <ASState>asdglkjasdlkf</ASState>
    <CustRemark>asdfasdf</CustRemark>
    <UMFindKindName>입고검사</UMFindKindName>
    <UMLastDecisionName>최종판단1</UMLastDecisionName>
    <UMLotMagnitudeName>Lot심각도1</UMLotMagnitudeName>
    <UMBadMagnitudeName>결점심각도1</UMBadMagnitudeName>
    <UMMkindName>4m분류1</UMMkindName>
    <UMMtypeName>4m내용1</UMMtypeName>
    <UMIsEndName>종결여부1</UMIsEndName>
    <UMProbleSubItemName>문제반제품2</UMProbleSubItemName>
    <UMProbleSemiItemName>문제부품2</UMProbleSemiItemName>
    <UMBadTypeName>불량구분2</UMBadTypeName>
    <UMBadLKindName>불량유형대2</UMBadLKindName>
    <UMBadMKindName>불량유형중2</UMBadMKindName>
    <UMResponsTypeName>귀책구분1</UMResponsTypeName>
    <ResponsProc>12</ResponsProc>
    <ResponsDept>131</ResponsDept>
    <ProcDeptName>3</ProcDeptName>
    <ProbleCause>2</ProbleCause>
    <ImsiProc>31</ImsiProc>
    <ImsiEmpName>anh</ImsiEmpName>
    <ImsiDate>23</ImsiDate>
    <RootProc>12</RootProc>
    <RootEmpName>anh</RootEmpName>
    <RootDate>12</RootDate>
    <EndDate>20130712</EndDate>
    <BadRate>1</BadRate>
    <ASRegNo>AS-201307-0022</ASRegNo>
    <ASRegSeq>48</ASRegSeq>
    <SMLocalType>8918001</SMLocalType>
    <UMASMClass>10011001</UMASMClass>
    <CustSeq>42125</CustSeq>
    <ItemSeq>24762</ItemSeq>
    <UMFindKind>1008276001</UMFindKind>
    <UMLastDecision>1008278001</UMLastDecision>
    <UMLotMagnitude>1008279001</UMLotMagnitude>
    <UMBadMagnitude>1008280001</UMBadMagnitude>
    <UMMkind>1008281001</UMMkind>
    <UMMtype>1008282001</UMMtype>
    <UMIsEnd>1008283001</UMIsEnd>
    <UMProbleSubItem>1008284002</UMProbleSubItem>
    <UMProbleSemiItem>1008285002</UMProbleSemiItem>
    <UMBadType>1008286002</UMBadType>
    <UMBadLKind>1008287002</UMBadLKind>
    <UMBadMKind>1008288002</UMBadMKind>
    <UMResponsType>1008289001</UMResponsType>
    <ProcDept>1512</ProcDept>
    <ImsiEmp>251</ImsiEmp>
    <RootEmp>251</RootEmp>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197