  
IF OBJECT_ID('KPX_SACComCostDivSlipDataCreate') IS NOT NULL   
    DROP PROC KPX_SACComCostDivSlipDataCreate  
GO  
  
-- v2014.11.10  
  
-- 공통활동센터 비용배부 대체전표처리-전표생성 by 이재천   
CREATE PROC KPX_SACComCostDivSlipDataCreate    
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
      
    DECLARE @AccUnit    INT,   
            @AccDate    NCHAR(8),   
            @SlipMstId  NVARCHAR(100),   
            @SlipUnit   INT,   
            @SlipNo     NVARCHAR(100),   
            @Cnt        INT,   
            @Seq        INT,   
            @Count      INT,   
            @MAXID      INT, 
            @AccSeq     INT 
      
    ALTER TABLE #KPX_TACComCostDivSlip ADD SlipNo NVARCHAR(100) NULL   
      
    CREATE TABLE #TEMP  
    (  
        IDX_NO      INT IDENTITY,   
        DrAmt       DECIMAL(19,5),   
        CrAmt       DECIMAL(19,5),   
        AccSeq      INT,   
        AccDate     NCHAR(8),   
        AccUnitSeq  INT,   
        CCtrSeq     INT,   
        RemValSeq   INT,   
        SlipMstID   NVARCHAR(100),   
        SlipMstSeq  INT,   
        SlipMstID2  NVARCHAR(100),   
        SlipMstSeq2 INT,   
        SlipUnit    INT,   
        SlipID      NVARCHAR(100),    
        SlipNo      NVARCHAR(100),   
        SlipSeq     INT,   
    )  
    
    --select * from sysobjects where name like 'KPX[_]TCOMEnv%'
    SELECT @AccSeq = (SELECT TOP 1 EnvValue
                        FROM KPX_TCOMEnv AS A 
                        JOIN KPX_TCOMEnvItem AS B ON ( B.CompanySeq = @CompanySeq AND B.EnvSeq = A.EnvSeq ) 
                        WHERE A.CompanySeq = @CompanySeq 
                          AND A.EnvSeq = 3 
                     )
    
    SELECT @Cnt = 1   
      
    WHILE ( 1 = 1 )   
    BEGIN  
      
        SELECT @AccUnit = AccUnitSeq,   
               @AccDate = AccDate,   
               @SlipUnit = SlipUnit   
         FROM #KPX_TACComCostDivSlip   
        WHERE DataSeq = @Cnt   
        
        EXEC dbo._SCOMCreateNo  'AC'        , -- 회계(HR/AC/SL/PD/ESM/PMS/SI/SITE)  
                                '_TACSlip'  , -- 테이블  
                                @CompanySeq , -- 법인코드  
                                @AccUnit    , -- 부문코드  
                                @AccDate    ,  -- 취득일  
                                @SlipMstID  OUTPUT,  
                                @SlipUnit   ,  
                                0           ,  
                                @SlipNo     OUTPUT,  
                                'SlipMstID'   --컬럼명    
        
        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlip', 'SlipMstSeq', 1  
          
        SELECT @MAXID = CONVERT(INT,RIGHT(SlipMstID,4))  
         FROM _TACSlip    
        WHERE CompanySeq = @CompanySeq   
          AND AccDate = @AccDate   
          
          
        IF EXISTS (SELECT 1 FROM #KPX_TACComCostDivSlip WHERE DataSeq = @Cnt AND AccUnitSeq <> RecvAccSeq)  
        BEGIN  
            UPDATE A   
               SET SlipMstId2 = REPLACE(@SlipMstId,RIGHT(@SlipMstId,4),'') + RIGHT('000' + CONVERT(NVARCHAR(10),@MAXID + (@Cnt)),4),   
                   SlipNo = RIGHT('000' + CONVERT(NVARCHAR(10),@MAXID + (@Cnt)),4)  
              FROM #KPX_TACComCostDivSlip AS A   
             WHERE DataSeq = @Cnt   
                     -- Temp Talbe 에 생성된 키값 UPDATE  
            UPDATE #KPX_TACComCostDivSlip  
               SET SlipMstSeq2 = @Seq + 1  
             WHERE DataSeq = @Cnt   
               AND Status = 0  
        END   
        ELSE   
        BEGIN  
            UPDATE A   
               SET SlipMstId = REPLACE(@SlipMstId,RIGHT(@SlipMstId,4),'') + RIGHT('000' + CONVERT(NVARCHAR(10),@MAXID + (@Cnt)),4),   
                   SlipNo = RIGHT('000' + CONVERT(NVARCHAR(10),@MAXID + (@Cnt)),4)  
              FROM #KPX_TACComCostDivSlip AS A   
             WHERE DataSeq = @Cnt   
            UPDATE #KPX_TACComCostDivSlip  
               SET SlipMstSeq = @Seq + 1  
             WHERE DataSeq = @Cnt   
               AND Status = 0  
        END   
          
        IF EXISTS (SELECT 1 FROM #KPX_TACComCostDivSlip WHERE DataSeq = @Cnt AND AccUnitSeq = RecvAccSeq)  
        BEGIN  
     INSERT INTO #TEMP (DrAmt, CrAmt, AccSeq, AccDate, AccUnitSeq, CCtrSeq, RemValSeq, SlipMstId, SlipMstSeq, SlipUnit, SlipNo)  
            SELECT SUM(A.RevAmt) * (-1) AS DrAmt,   
                   0 AS CrAmt,   
                   B.AccSeq,   
                   MAX(A.AccDate) AS AccDate,   
                   A.AccUnitSeq,   
                   A.SendCCtrSeq AS CCtrSeq,   
                   0 AS RemValSeq,   
                   C.SlipMstId,   
                   C.SlipMstSeq,   
                   MAX(A.SlipUnit),   
                   MAX(C.SlipNo)  
              FROM #KPX_TACComCostDivSlip   AS A   
              LEFT OUTER JOIN _TESMBAccount AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostAccSeq = A.CostAccSeq )   
              LEFT OUTER JOIN #KPX_TACComCostDivSlip AS C ON ( C.DataSeq = @Cnt )   
             WHERE A.DataSeq <> @Cnt   
             GROUP BY A.AccUnitSeq, B.AccSeq, A.SendCCtrSeq, C.SlipMstId, C.SlipMstSeq  
              
            UNION ALL   
              
            SELECT 0 AS DrAmt,   
                   A.RevAmt * (-1) AS CrAmt,   
                   @AccSeq AS AccSeq,   
                   A.AccDate,   
                   A.AccUnitSeq,   
                   0 AS CCtrSeq,   
                   A.RecvAccSeq AS RemValSeq,   
                   C.SlipMstId,   
                   C.SlipMstSeq,   
                   A.SlipUnit,   
                   A.SlipNo   
              FROM #KPX_TACComCostDivSlip AS A   
              LEFT OUTER JOIN #KPX_TACComCostDivSlip AS C ON ( C.DataSeq = @Cnt )   
             WHERE A.AccUnitSeq <> A.RecvAccSeq  
             ORDER BY C.SlipMstSeq   
        END   
        ELSE   
        BEGIN  
            INSERT INTO #TEMP (DrAmt, CrAmt, AccSeq, AccDate, AccUnitSeq, CCtrSeq, RemValSeq, SlipMstId2, SlipMstSeq2, SlipUnit, SlipNo)  
            SELECT A.RevAmt AS DrAmt,   
                   0 AS CrAmt,   
                   B.AccSeq,   
                   A.AccDate,   
                   A.RecvAccSeq AS AccUnitSeq,   
                   RecvCCtrSeq AS CCtrSeq,   
                   0 AS RemValSeq,   
                   A.SlipMstId2,   
                   A.SlipMstSeq2,   
                   A.SlipUnit,   
                   A.SlipNo   
              FROM #KPX_TACComCostDivSlip AS A   
              LEFT OUTER JOIN _TESMBAccount AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostAccSeq = A.CostAccSeq )   
             WHERE DataSeq = @Cnt  
              
            UNION ALL   
              
            SELECT 0 AS DrAmt,   
                   A.RevAmt AS CrAmt,   
                   @AccSeq AS AccSeq,   
                   A.AccDate,   
                   A.RecvAccSeq AS AccUnitSeq,   
                   0 AS CCtrSeq,   
                   A.AccUnitSeq AS RemValSeq,   
                   A.SlipMstId2,   
                   A.SlipMstSeq2,   
                   A.SlipUnit,   
                   A.SlipNo   
              FROM #KPX_TACComCostDivSlip AS A   
              LEFT OUTER JOIN _TESMBAccount AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostAccSeq = A.CostAccSeq )   
             WHERE DataSeq = @Cnt  
           
        END   
              
          
        IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TACComCostDivSlip)  
        BEGIN   
            BREAK  
        END   
        ELSE   
        BEGIN  
            SELECT @Cnt = @Cnt + 1   
        END   
    END   
      
      
    SELECT @Count = (SELECT COUNT(1) FROM #TEMP)   
      
    IF @Count > 0   
    BEGIN  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlipRow', 'SlipSeq', @Count  
          
        UPDATE A   
           SET SlipSeq = @Seq + A.IDX_NO   
          FROM #TEMP AS A   
    END   
      
      
    DECLARE @SlipKind   INT,  
            @RegEmpSeq  INT,   
            @RegDeptSeq INT   
      
    SELECT @SlipKind = 10001   
    SELECT @RegEmpSeq = ISNULL((SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),0)   
      SELECT @RegDeptSeq = ISNULL((SELECT DeptSeq FROM _fnAdmEmpOrd(@CompanySeq, '') WHERE EmpSeq = (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq)),0)  
          
    -- 전표 마스터   
    INSERT INTO _TACSlip   
    (  
        CompanySeq,     SlipMstSeq,     SlipMstID,      AccUnit,            SlipUnit,  
        AccDate,        SlipNo,         SlipKind,       RegEmpSeq,          RegDeptSeq,       
        Remark,         SMCurrStatus,   AptDate,        AptEmpSeq,          AptDeptSeq,       
        AptRemark,      SMCheckStatus,  CheckOrigin,    IsSet,              SetSlipNo,  
        SetEmpSeq,      SetDeptSeq,     LastUserSeq,    LastDateTime,       RegDateTime,      
        RegAccDate,     SetSlipID      
    )  
    SELECT @CompanySeq,     CASE WHEN ISNULL(SlipMstSeq,0) = 0 THEN SlipMstSeq2 ELSE SlipMstSeq END,       
           CASE WHEN ISNULL(SlipMstID,'') = '' THEN SlipMstID2 ELSE SlipMstID END,       
           AccUnitSeq,     SlipUnit,   
             
           AccDate,         SlipNo,         @SlipKind,      @RegEmpSeq,     @RegDeptSeq,   
             
           '',              0,              '',             0,              0,       
             
           '',              0,              0,              '0',            '',  
             
           0,               0,              @UserSeq,       GETDATE(),      GETDATE(),      
             
           AccDate,         ''     
      
      FROM #KPX_TACComCostDivSlip   
      
    IF @@ERROR <> 0  RETURN    
      
      
    -- 전표 Row  
    INSERT INTO _TACSlipRow   
    (  
        CompanySeq,         SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,      
        SlipUnit,           AccDate,        SlipNo,         RowNo,          RowSlipUnit,      
        AccSeq,             UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,      
        DrForAmt,           CrForAmt,       CurrSeq,        ExRate,         DivExRate,      
        EvidSeq,            TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind,  
        CostItemSeq,        Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq,      
        IsSet,CoCustSeq,    LastDateTime,   LastUserSeq      
    )  
    SELECT @CompanySeq,     A.SlipSeq,        
           CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN A.SlipMstSeq2 ELSE A.SlipMstSeq END,    
           CASE WHEN ISNULL(A.SlipMstID,'') = '' THEN SlipMstID2 ELSE A.SlipMstID END  + '-' +   
           RIGHT('000' + CONVERT(NVARCHAR(10),ROW_NUMBER() OVER(PARTITION BY (CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN SlipMstSeq2 ELSE A.SlipMstSeq END) ORDER BY (CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN SlipMstSeq2 ELSE A.SlipMstSeq END))),3),   
           A.AccUnitSeq,      
             
           A.SlipUnit,      A.AccDate,      A.SlipNo,           
           RIGHT('000' + CONVERT(NVARCHAR(10),ROW_NUMBER() OVER(PARTITION BY (CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN SlipMstSeq2 ELSE A.SlipMstSeq END) ORDER BY (CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN SlipMstSeq2 ELSE A.SlipMstSeq END))),3),   
           A.SlipUnit,     
             
           A.AccSeq,        B.SMCostAccType,       
           CASE WHEN DrAmt = 0 THEN -1 ELSE 1 END,         
           DrAmt,           CrAmt,      
             
           0,   0,      0,      0,  0,      
             
           0,   null,   null,   0,  0,  
             
           0,   STUFF(STUFF(A.AccDate,5,0,'-'),8,0,'-') + ' 공통활동센터 비용배부 대체전표처리',          
           0,     0,     0,      
             
           '0', 0,  GETDATE(),  @UserSeq  
      FROM #TEMP AS A   
      LEFT OUTER JOIN _TDAAccount AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq )   
      
    IF @@ERROR <> 0  RETURN    
      
    -- 귀속부서   
    INSERT INTO _TACSlipCost   
    (  
        CompanySeq,     SlipSeq,    Serl,       CostDeptSeq,    CostCCtrSeq,          
        DivRate,        DrAmt,      CrAmt,      DrForAmt,       CrForAmt  
    )  
    SELECT @CompanySeq,     SlipSeq,    1,      0,      CCtrSeq,          
           100,             DrAmt,      CrAmt,  0,      0  
      FROM #TEMP AS A   
      
      IF @@ERROR <> 0  RETURN     
      
    -- 관리항목   
    INSERT INTO _TACSlipRem  
    (  
        CompanySeq,     SlipSeq,    RemSeq,     RemValSeq,  RemValText  
    )  
    SELECT @CompanySeq, SlipSeq, 1031, RemValSeq, 0   
      FROM #TEMP   
     WHERE RemValSeq <> 0   
      
    IF @@ERROR <> 0  RETURN    
      
      
    UPDATE B  
       SET SlipMstSeq = CASE WHEN ISNULL(A.SlipMstSeq,0) = 0 THEN A.SlipMstSeq2 ELSE A.SlipMstSeq END   
      FROM #KPX_TACComCostDivSlip   AS A   
      JOIN KPX_TACComCostDivSlip    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq   
                                                       AND B.CostYM = A.CostYM   
                                                       AND B.SMCostMng = A.SMCostMng   
                                                       AND B.SendCCtrSeq = A.SendCCtrSeq   
                                                       AND B.RevCCtrSeq = A.RecvCCtrSeq   
                                                       AND B.CostAccSeq =  A.CostAccSeq   
                                                         )   
        
        
    SELECT * FROM #KPX_TACComCostDivSlip   
      
      
    RETURN   
go


/*
begin tran 
exec KPX_SACComCostDivSlipDataCreate @xmlDocument=N'<ROOT>
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
    <SlipMstID2 />
    <SlipMstSeq2>0</SlipMstSeq2>
    <InsertKind2>1</InsertKind2>
    <SlipUnit>2</SlipUnit>
    <AccDate>20141111</AccDate>
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
    <SlipMstID2 />
    <SlipMstSeq2>0</SlipMstSeq2>
    <InsertKind2>1</InsertKind2>
    <SlipUnit>2</SlipUnit>
    <AccDate>20141111</AccDate>
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
    <SlipMstID />
    <SlipMstSeq>0</SlipMstSeq>
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
    <SlipUnit>2</SlipUnit>
    <AccDate>20141111</AccDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025697,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1021304

rollback 

*/