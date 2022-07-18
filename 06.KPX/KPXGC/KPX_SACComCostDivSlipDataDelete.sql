  
IF OBJECT_ID('KPX_SACComCostDivSlipDataDelete') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipDataDelete
GO  
  
-- v2014.11.10  
  
-- 공통활동센터 비용배부 대체전표처리-전표삭제 by 이재천   
CREATE PROC KPX_SACComCostDivSlipDataDelete  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TACComCostDivSlip (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACComCostDivSlip'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @CostYM NCHAR(6) 
    
    SELECT @CostYM = (SELECT TOP 1 CostYM FROM #KPX_TACComCostDivSlip)
    
    
    IF EXISTS (SELECT 1 FROM KPX_TACComCostDivSlip AS A 
                        JOIN _TACSlip              AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SlipMstSeq = A.SlipMstSeq AND B.IsSet = '1' ) 
                       WHERE A.CompanySeq = @CompanySeq 
                         AND A.CostYM = @CostYM 
              ) 
    BEGIN
        UPDATE A 
           SET Result = '승인 된 전표가 있어 삭제 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #KPX_TACComCostDivSlip AS A 
    END 
    ELSE 
    BEGIN
        
        SELECT SlipMstSeq INTO #SlipMstSeq FROM KPX_TACComCostDivSlip WHERE CompanySeq = @CompanySeq AND CostYM = @CostYM 
        
        
        SELECT 'D' AS WorkingTag, 
               ROW_NUMBER() OVER (ORDER BY A.SlipMstSeq) AS IDX_NO, 
               A.SlipMstSeq, 
               0 AS Status 
          INTO #TACSlip
          FROM _TACSlip AS A 
          JOIN #SlipMstSeq AS B ON ( B.SlipMstSeq = A.SlipMstSeq ) 
         WHERE CompanySeq = @CompanySeq  
        
        -- 로그 남기기    
        DECLARE @TableColumns NVARCHAR(4000)    
      
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TACSlip')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TACSlip'    , -- 테이블명        
                      '#TACSlip'    , -- 임시 테이블명        
                      'SlipMstSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        
        SELECT 'D' AS WorkingTag, 
               ROW_NUMBER() OVER (ORDER BY A.SlipSeq) AS IDX_NO, 
               A.SlipSeq, 
               0 AS Status 
          INTO #TACSlipRow 
          FROM _TACSlipRow AS A 
          JOIN #SlipMstSeq AS B ON ( B.SlipMstSeq = A.SlipMstSeq ) 
         WHERE CompanySeq = @CompanySeq  
        
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TACSlipRow')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TACSlipRow'    , -- 테이블명        
                      '#TACSlipRow'    , -- 임시 테이블명        
                      'SlipSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        
        SELECT 'D' AS WorkingTag, 
               ROW_NUMBER() OVER (ORDER BY A.SlipSeq,A.Serl) AS IDX_NO, 
               A.SlipSeq, 
               1 AS Serl, 
               0 AS Status 
          INTO #TACSlipCost
          FROM _TACSlipCost AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.SlipSeq IN ( SELECT SlipSeq FROM #TACSlipRow ) 
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TACSlipCost')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TACSlipCost'    , -- 테이블명        
                      '#TACSlipCost'    , -- 임시 테이블명        
                      'SlipSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
    
        
        SELECT 'D' AS WorkingTag, 
               ROW_NUMBER() OVER (ORDER BY A.SlipSeq,A.RemSeq) AS IDX_NO, 
               A.SlipSeq, 
               A.RemSeq, 
               0 AS Status 
          INTO #TACSlipRem
          FROM _TACSlipRem AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.SlipSeq IN ( SELECT SlipSeq FROM #TACSlipRow ) 
    
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TACSlipRem')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TACSlipRem'    , -- 테이블명        
                      '#TACSlipRem'    , -- 임시 테이블명        
                      'SlipSeq,RemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
        
        DELETE A
          FROM _TACSlip AS A 
          JOIN #TACSlip AS B ON ( B.SlipMstSeq = A.SlipMstSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
        
        DELETE A 
          FROM _TACSlipRow AS A 
          JOIN #TACSlipRow AS B ON ( B.SlipSeq = A.SlipSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
        
        DELETE A 
          FROM _TACSlipCost AS A 
          JOIN #TACSlipCost AS B ON ( B.SlipSeq = A.SlipSeq AND B.Serl = A.Serl ) 
         WHERE A.CompanySeq = @CompanySeq 
         
        DELETE A 
          FROM _TACSlipRem AS A 
          JOIN #TACSlipRem AS B ON ( B.SlipSeq = A.SlipSeq AND B.RemSeq = A.RemSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
    END 

    
    UPDATE B
       SET SlipMstSeq = 0 
        FROM #KPX_TACComCostDivSlip AS A 
        JOIN KPX_TACComCostDivSlip  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                       AND B.CostYM = A.CostYM 
                                                       AND B.SMCostMng = A.SMCostMng 
                                                       AND B.RevCCtrSeq = A.RecvCCtrSeq 
                                                       AND B.CostAccSeq = A.CostAccSeq 
                                                         ) 
    
    
    UPDATE A
       SET SlipMstID = '',  
           SlipMstSeq = 0, 
           SlipMstID2 = '', 
           SlipMstSeq2 = 0 
      FROM #KPX_TACComCostDivSlip AS A  

    SELECT * FROM #KPX_TACComCostDivSlip 
    
    RETURN 
go
/*
begin tran 
exec KPX_SACComCostDivSlipDataDelete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <AccUnitName>기존사업부</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CostAccName>소모공기구비-(제조)(생산공통)</CostAccName>
    <CostAccSeq>471</CostAccSeq>
    <SendCCtrName>공무팀</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <TgtAmt>10000</TgtAmt>
    <RecvAccName>DMC 사업부</RecvAccName>
    <RecvAccSeq>2</RecvAccSeq>
    <RecvCCtrName>공무팀_DMC</RecvCCtrName>
    <RecvCCtrSeq>25</RecvCCtrSeq>
    <RevAmt>2000</RevAmt>
    <DrAmt>-2000</DrAmt>
    <CrAmt>-2000</CrAmt>
    <SlipMstID />
    <SlipMstSeq>0</SlipMstSeq>
    <CostYM>201410</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <InsertKind>1</InsertKind>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <RecvAccUnitName2>DMC 사업부</RecvAccUnitName2>
    <RecvAccUnit2>0</RecvAccUnit2>
    <CostAccName2>소모공기구비-(제조)(생산공통)</CostAccName2>
    <CostAccSeq2>471</CostAccSeq2>
    <RevAmt2>2000</RevAmt2>
    <DrAmt2>2000</DrAmt2>
    <CrAmt2>2000</CrAmt2>
    <CCtrName2>공무팀</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <SendAccUnitName2>기존사업부</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SlipMstID2>A0-S1-20141111-0013</SlipMstID2>
    <SlipMstSeq2>51284</SlipMstSeq2>
    <InsertKind2>1</InsertKind2>
    <SlipUnit>1</SlipUnit>
    <AccDate>20141111</AccDate>
    <AccUnit>1</AccUnit>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <AccUnitName>기존사업부</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CostAccName>소모공기구비-(제조)(생산공통)</CostAccName>
    <CostAccSeq>471</CostAccSeq>
    <SendCCtrName>공무팀</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <TgtAmt>10000</TgtAmt>
    <RecvAccName>AM 사업부</RecvAccName>
    <RecvAccSeq>3</RecvAccSeq>
    <RecvCCtrName>공무팀_AM</RecvCCtrName>
    <RecvCCtrSeq>34</RecvCCtrSeq>
    <RevAmt>2000</RevAmt>
    <DrAmt>-2000</DrAmt>
    <CrAmt>-2000</CrAmt>
    <SlipMstID />
    <SlipMstSeq>0</SlipMstSeq>
    <CostYM>201410</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <InsertKind>1</InsertKind>
    <RecvAccUnitName2>AM 사업부</RecvAccUnitName2>
    <RecvAccUnit2>0</RecvAccUnit2>
    <CostAccName2>소모공기구비-(제조)(생산공통)</CostAccName2>
    <CostAccSeq2>471</CostAccSeq2>
    <RevAmt2>2000</RevAmt2>
    <DrAmt2>2000</DrAmt2>
    <CrAmt2>2000</CrAmt2>
    <CCtrName2>공무팀</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <SendAccUnitName2>기존사업부</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SlipMstID2>A0-S1-20141111-0014</SlipMstID2>
    <SlipMstSeq2>51285</SlipMstSeq2>
    <InsertKind2>1</InsertKind2>
    <SlipUnit>1</SlipUnit>
    <AccDate>20141111</AccDate>
    <AccUnit>1</AccUnit>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <AccUnitName>기존사업부</AccUnitName>
    <AccUnitSeq>1</AccUnitSeq>
    <CostAccName>소모공기구비-(제조)(생산공통)</CostAccName>
    <CostAccSeq>471</CostAccSeq>
    <SendCCtrName>공무팀</SendCCtrName>
    <SendCCtrSeq>14</SendCCtrSeq>
    <TgtAmt>10000</TgtAmt>
    <RecvAccName>기존사업부</RecvAccName>
    <RecvAccSeq>1</RecvAccSeq>
    <RecvCCtrName>공무팀_기존사업</RecvCCtrName>
    <RecvCCtrSeq>39</RecvCCtrSeq>
    <RevAmt>6000</RevAmt>
    <DrAmt>0</DrAmt>
    <CrAmt>0</CrAmt>
    <SlipMstID>A0-S1-20141111-0015</SlipMstID>
    <SlipMstSeq>51286</SlipMstSeq>
    <CostYM>201410</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <InsertKind>1</InsertKind>
    <RecvAccUnitName2>기존사업부</RecvAccUnitName2>
    <RecvAccUnit2>0</RecvAccUnit2>
    <CostAccName2>소모공기구비-(제조)(생산공통)</CostAccName2>
    <CostAccSeq2>471</CostAccSeq2>
    <RevAmt2>6000</RevAmt2>
    <DrAmt2>0</DrAmt2>
    <CrAmt2>0</CrAmt2>
    <CCtrName2>공무팀</CCtrName2>
    <CCtrSeq2>14</CCtrSeq2>
    <SendAccUnitName2>기존사업부</SendAccUnitName2>
    <SendAccUnitSeq2>0</SendAccUnitSeq2>
    <SlipMstID2 />
    <SlipMstSeq2>0</SlipMstSeq2>
    <InsertKind2>1</InsertKind2>
    <SlipUnit>1</SlipUnit>
    <AccDate>20141111</AccDate>
    <AccUnit>1</AccUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025697,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1021304

rollback 

*/