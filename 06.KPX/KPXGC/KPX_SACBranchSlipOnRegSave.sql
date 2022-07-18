
IF OBJECT_ID('KPX_SACBranchSlipOnRegSave') IS NOT NULL   
    DROP PROC KPX_SACBranchSlipOnRegSave  
GO  
  
-- v2015.02.25  
  
-- 본지점대체전표생성(건별반제)-저장 by 이재천   
CREATE PROC KPX_SACBranchSlipOnRegSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #TACSlip (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TACSlip'   
    IF @@ERROR <> 0 RETURN    
    
    ALTER TABLE #TACSlip ADD NewSlipNo NVARCHAR(100) NULL 
    ALTER TABLE #TACSlip ADD NewSlipMstSeq NVARCHAR(100) NULL 
    
    ALTER TABLE #TACSlip ADD CNewSlipNo NVARCHAR(100) NULL 
    ALTER TABLE #TACSlip ADD CNewSlipMstSeq NVARCHAR(100) NULL 
    
    DECLARE @Cnt        INT, 
            @AccUnit    INT, 
            @AccDate    NCHAR(8), 
            @SlipMstID  NVARCHAR(100), 
            @SlipUnit   INT, 
            @SlipNo     NVARCHAR(100), 
            @Count      INT, 
            @Seq        INT, 
            @EnvAccSeq  INT 
    
    SELECT @EnvAccSeq = (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 32 AND EnvSerl = 1) 
    
    SELECT @EnvAccSeq = ISNULL(@EnvAccSeq,0)
    
    ---------------------------------------------------------------------------------------------
    -- 기표번호 생성 
    ---------------------------------------------------------------------------------------------
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN
    
        SELECT @AccUnit = A.SendAccUnit, 
               @AccDate = A.NewAccDate, 
               @SlipUnit = C.SlipUnit
          FROM #TACSlip AS A 
          LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
          LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
         WHERE A.IDX_NO = @Cnt 
        
        SELECT @SlipNo = '', @SlipMstID = '' 
        
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
        
        UPDATE A 
           SET NewSlipMstID = @SlipMstID, 
               NewSlipNo = @SlipNo
          FROM #TACSlip AS A 
         WHERE A.IDX_NO = @Cnt 
        
        IF @Cnt = ( SELECT MAX(IDX_NO) FROM #TACSlip ) 
        BEGIN 
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
    ---------------------------------------------------------------------------------------------
    -- 기표번호 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 기표코드 생성
    ---------------------------------------------------------------------------------------------
    SELECT @Count = ( SELECT COUNT(1) FROM #TACSlip )
    
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlip', 'SlipMstSeq', @Count 
    
    UPDATE A 
       SET NewSlipMstSeq = @Seq + DataSeq 
      FROM #TACSlip AS A 
    ---------------------------------------------------------------------------------------------
    -- 기표코드 생성, END 
    ---------------------------------------------------------------------------------------------
    
    --SELECT TOP 10 * FROM _TACSlip WHERE CompanySeq = 1 order by  lastdatetime desc
    
    
    CREATE TABLE #Slip 
    (
        SlipMstSeq      INT, 
        SlipMstID       NVARCHAR(100), 
        AccUnit         INT, 
        SlipUnit        INT, 
        AccDate         NCHAR(8), 
        SlipNo          NVARCHAR(10), 
        SlipKind        INT, 
        RegEmpSeq       INT, 
        RegDeptSeq      INT
    ) 
    

    DECLARE @EmpSeq INT 
    
    SELECT @EmpSeq = (SELECT TOP 1 EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq ) 
    INSERT INTO #Slip 
    ( 
        SlipMstSeq,     SlipMstID,      AccUnit,        SlipUnit,       AccDate, 
        SlipNo,         SlipKind,       RegEmpSeq,      RegDeptSeq
    )
    SELECT A.NewSlipMstSeq, A.NewSlipMstID, A.SendAccUnit, C.SlipUnit, A.NewAccDate, 
           A.NewSlipNo, SlipKind, ISNULL(D.EmpSeq,1), ISNULL(D.DeptSeq,0) 
      FROM #TACSlip AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS D ON ( D.EmpSeq = @EmpSeq ) 
      
    
--SELECT TOP 10 * FROM _TACSlipRow WHERE CompanySeq = 1 order by  lastdatetime desc
    
    CREATE TABLE #SlipRow 
    (
        IDX_NO      INT IDENTITY, 
        SlipSeq     INT, 
        SlipMstSeq  INT, 
        SlipID      NVARCHAR(100), 
        AccUnit     INT, 
        SlipUnit    INT, 
        AccDate     NVARCHAR(100), 
        SlipNo      NVARCHAR(10), 
        RowNo       NVARCHAR(10), 
        RowSlipUnit INT, 
        AccSeq      INT, 
        UMCostType  INT, 
        SMDrOrCr    INT, 
        DrAmt       DECIMAL(19,5), 
        CrAmt       DECIMAL(19,5), 
        DrForAmt    DECIMAL(19,5),   
        CrForAmt    DECIMAL(19,5),  
        CurrSeq     INT, 
        ExRate      DECIMAL(19,5), 
        SlipMstID   NVARCHAR(100), 
        Summary     NVARCHAR(500), 
        Sub_No      INT 
    ) 
    
    CREATE TABLE #SlipRow_Sub
    (
        IDX_NO      INT IDENTITY, 
        SlipSeq     INT, 
        SlipMstSeq  INT, 
        SlipID      NVARCHAR(100), 
        AccUnit     INT, 
        SlipUnit    INT, 
        AccDate     NVARCHAR(100), 
        SlipNo      NVARCHAR(10), 
        RowNo       NVARCHAR(10), 
        RowSlipUnit INT, 
        AccSeq      INT, 
        UMCostType  INT, 
        SMDrOrCr    INT, 
        DrAmt       DECIMAL(19,5), 
        CrAmt       DECIMAL(19,5), 
        DrForAmt    DECIMAL(19,5),   
        CrForAmt    DECIMAL(19,5),  
        CurrSeq     INT, 
        ExRate      DECIMAL(19,5), 
        SlipMstID   NVARCHAR(100), 
        Summary     NVARCHAR(500) 
    )
    
    INSERT INTO #SlipRow_Sub   
    (  
        SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit,   
        AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq,   
        UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
        CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary  
    )  
    SELECT NewSlipSeq, NewSlipMstSeq, '', SendAccUnit, C.SlipUnit,   
           NewAccDate, NewSlipNo, '', B.RowSlipUnit, CrAccSeq,   
           0, 1 AS SMDrOrCr, A.CrAmt, 0, B.CrForAmt, 
           0, B.CurrSeq, B.ExRate, NewSlipMstID, B.Summary  
      FROM #TACSlip AS A   
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq )   
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq )   
      
    UNION ALL   
      
    SELECT NewSlipSeq, NewSlipMstSeq, '', SendAccUnit, C.SlipUnit,   
           NewAccDate, NewSlipNo, '', B.RowSlipUnit, @EnvAccSeq,   
           0, -1, 0, A.CrAmt, 0, 
           B.CrForAmt, B.CurrSeq, B.ExRate, NewSlipMstID, B.Summary  
      FROM #TACSlip AS A   
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq )   
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq )   
       ORDER BY NewSlipMstSeq, SMDrOrCr DESC    
    
    INSERT INTO #SlipRow  
    (  
        SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit,   
        AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq,   
        UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
        CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary,    
        Sub_No  
    )  
    SELECT SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit,   
           AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq,   
           UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
           CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary,   
           ROW_NUMBER() OVER(PARTITION BY SlipMstSeq ORDER BY SlipSeq) AS Sum_No  
      FROM #SlipRow_Sub   
      
    ---------------------------------------------------------------------------------------------
    -- 전표코드 생성 
    ---------------------------------------------------------------------------------------------
    
    SELECT @Count = (SELECT COUNT(1) FROM #SlipRow) 
    
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlipRow', 'SlipSeq', @Count
    
    UPDATE A
       SET SlipSeq = @Seq + IDX_NO 
      FROM #SlipRow AS A 
    
    ---------------------------------------------------------------------------------------------
    -- 전표코드 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 전표번호 생성
    ---------------------------------------------------------------------------------------------
    DECLARE @RowCnt INT 
    
    EXEC dbo._SCOMEnv @CompanySeq,4011,@UserSeq,@@PROCID, @RowCnt OUTPUT
    IF @RowCnt = 0 OR @RowCnt IS NULL SELECT @RowCnt = 3
    
    UPDATE #SlipRow
       SET RowNo = RIGHT('0000' + CAST(ISNULL(B.RowNo,0) + A.Sub_No AS NVARCHAR), @RowCnt)
      FROM #SlipRow AS A 
      LEFT OUTER JOIN ( SELECT A.AccDate, A.AccUnit, A.SlipUnit, MAX(CONVERT(INT,A.RowNo)) AS RowNo
                          FROM _TACSlipRow AS A 
                         WHERE CompanySeq = @CompanySeq 
                           AND EXISTS (SELECT 1 FROM #SlipRow WHERE AccDate = A.AccDate)
                         GROUP BY A.AccDate, A.AccUnit, A.SlipUnit
                      ) AS B ON ( B.AccDate = A.AccDate AND B.AccUnit = A.AccUnit AND B.SlipUnit = A.SlipUnit ) 
    
    UPDATE #SlipRow
       SET SlipID = SlipMstID + '-' + RowNo
    
    ---------------------------------------------------------------------------------------------
    -- 전표번호 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 관리항목 생성
    ---------------------------------------------------------------------------------------------
    CREATE TABLE #SlipRem
    (
        SlipSeq     INT, 
        RemSeq      INT, 
        RemValSeq   INT, 
        RemValText  NVARCHAR(100), 
        AccSeq      INT
    )
    
    INSERT INTO #SlipRem ( SlipSeq, RemSeq, RemValSeq, RemValText, AccSeq ) 
    SELECT A.SlipSeq, F.RemSeq, F.RemValSeq, F.RemValText, A.AccSeq
      FROM #SlipRow AS A  
      LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
      --LEFT OUTER JOIN _TACSlipRow AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
      --LEFT OUTER JOIN _TACSlip    AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipMstSeq = C.SlipMstSeq ) 
      --LEFT OUTER JOIN _TACSlipRow AS E ON ( E.CompanySeq = @CompanySeq AND E.SlipMstSeq = D.SlipMstSeq AND E.SlipSeq = B.SlipSeq) 
      LEFT OUTER JOIN _TACSlipRem AS F ON ( F.CompanySeq = @CompanySeq AND F.SlipSeq = B.SlipSeq ) 
     WHERE A.SMDrOrCr = 1 
    
    UNION ALL 
    
    SELECT A.SlipSeq, 1031, B.RecvAccUnit, '', A.AccSeq
      FROM #SlipRow AS A 
      LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
     WHERE SMDrOrCr = -1 
    ORDER BY SlipSeq, RemSeq
    
    
    --SELECT A.SlipSeq AS SlipSeq, 1017 AS RemSeq, B.RemCustSeq AS RemValSeq, '' AS RemValText
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = 1 
    
    --UNION ALL 
    
    --SELECT A.SlipSeq, 1031, B.RemAccUnit, '' 
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = 1 
    
    --UNION ALL 
    
    --SELECT A.SlipSeq, 1031, B.RecvAccUnit, '' 
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = -1 

    ---------------------------------------------------------------------------------------------
    -- 관리항목 생성, END 
    ---------------------------------------------------------------------------------------------
    --select * from #SlipRem 
    
    
    --SELECT TOP 10 * FROM _TACSlipCost WHERE CompanySeq = 1 
    ---------------------------------------------------------------------------------------------
    -- 전표의비용배부 데이터 생성
    ---------------------------------------------------------------------------------------------
    CREATE TABLE #SlipCost
    (
        SlipSeq     INT, 
        Serl        INT, 
        CostDeptSeq INT, 
        CostCCtrSeq INT, 
        DivRate     DECIMAL(19,5), 
        DrAmt       DECIMAL(19,5), 
        CrAmt       DECIMAL(19,5), 
        DrForAmt    DECIMAL(19,5), 
        CrForAmt    DECIMAL(19,5) 
    )
    INSERT INTO #SlipCost 
    (
        SlipSeq,    Serl,   CostDeptSeq,    CostCCtrSeq,    DivRate, 
        DrAmt,      CrAmt,  DrForAmt,       CrForAmt 
    )
    SELECT A.SlipSeq, 1, B.RegDeptSeq, 0, 100, 
           A.DrAmt, A.CrAmt, A.DrAmt, A.CrAmt 
      FROM #SlipRow AS A 
      JOIN #Slip    AS B ON ( B.SlipMstSeq = A.SlipMstSeq ) 
      
    ---------------------------------------------------------------------------------------------
    -- 전표의비용배부 데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    --select * from #SlipCost 
    
    --return 
    
    ---------------------------------------------------------------------------------------------
    -- 반제데이터 생성
    ---------------------------------------------------------------------------------------------
    CREATE TABLE #SlipOff 
    (
        SlipSeq     INT, 
        OnSlipSeq   INT, 
        SmDrOrCr    INT, 
        OffAmt      DECIMAL(19,5), 
        OffForAmt   DECIMAL(19,5), 
        ExRate      DECIMAL(19,5) 
    )
    INSERT INTO #SlipOff 
    (
        SlipSeq, OnSlipSeq, SmDrOrCr, OffAmt, OffForAmt, ExRate
    )
    SELECT A.SlipSeq, B.SlipSeq, 1, C.CrAmt, C.CrForAmt, C.ExRate
      FROM #SlipRow AS A 
      LEFT OUTER JOIN #TACSlip AS B ON ( B.NewSlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
     WHERE A.SMDrOrCr = 1  
    
    ---------------------------------------------------------------------------------------------
    -- 반제데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 실 데이터 생성 
    ---------------------------------------------------------------------------------------------
    INSERT INTO _TACSlip -- 전표마스터 
    (
        CompanySeq,     SlipMstSeq,     SlipMstID,      AccUnit,        SlipUnit,         
        AccDate,        SlipNo,         SlipKind,       RegEmpSeq,      RegDeptSeq,         
        Remark,         SMCurrStatus,   AptDate,        AptEmpSeq,      AptDeptSeq,         
        AptRemark,      SMCheckStatus,  CheckOrigin,    IsSet,          SetSlipNo,         
        SetEmpSeq,      SetDeptSeq,     LastUserSeq,    LastDateTime,   RegDateTime,         
        RegAccDate,     SetSlipID
    ) 
    SELECT @CompanySeq, SlipMstSeq, SlipMstID, AccUnit, SlipUnit, 
           AccDate, SlipNo, SlipKind, RegEmpSeq, RegDeptSeq, 
           '', 0, '', 0, 0, 
           '', 0, 0, '0', '', 
           0, 0, @UserSeq, GETDATE(), GETDATE(), 
           AccDate, '' 
      FROM #Slip 
    
    --select *from #SlipRow 
    
    INSERT INTO _TACSlipRow -- 전표Row 
    (
        CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,     
        SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit,     
        AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,     
        DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         DivExRate,     
        EvidSeq,        TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind,     
        CostItemSeq,    Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq,     
        IsSet,          CoCustSeq,      LastDateTime,   LastUserSeq
    ) 
    SELECT @CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,     
            SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit,     
            AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,     
            DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         0,     
            0,              NULL,           NULL,           0,              0,     
            0,              Summary , 0,          0,     0,     
            '0',            0,              GETDATE(),      @UserSeq
      FROM #SlipRow
    
    INSERT INTO _TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) -- 관리항목 
    SELECT @CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText
      FROM #SlipRem  
    
    
    INSERT INTO _TACSlipCost -- 전표비용배부
    (
        CompanySeq,     SlipSeq,    Serl,       CostDeptSeq,    CostCCtrSeq,     
        DivRate,        DrAmt,      CrAmt,      DrForAmt,       CrForAmt
    )
    SELECT @CompanySeq,     SlipSeq,    Serl,       CostDeptSeq,    CostCCtrSeq,     
            DivRate,        DrAmt,      CrAmt,      DrForAmt,       CrForAmt
      FROM #SlipCost 
    
    
    
    INSERT INTO _TACSlipOff (CompanySeq, SlipSeq, OnSlipSeq, SMDrOrCr, OffAmt, OffForAmt) -- 반제
    SELECT @CompanySeq, SlipSeq, OnSlipSeq, SMDrOrCr, OffAmt, OffForAmt
      FROM #SlipOff 
    
    INSERT INTO _TACCashOff (CompanySeq, SlipSeq, OffAmt, OffForAmt, OnSlipSeq, LastUserSeq, LastDateTime) -- 반제 
    SELECT @CompanySeq, SlipSeq, OffAmt, OffForAmt, OnSlipSeq, @UserSeq, GETDATE()
      FROM #SlipOff
    
    ---------------------------------------------------------------------------------------------
    -- 실 데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    
    
    
    
    /******************************************************************************************************************************************************
    -- 받는 부서 기준 전표 
    ******************************************************************************************************************************************************/
    
    ---------------------------------------------------------------------------------------------
    -- 기표번호 생성 
    ---------------------------------------------------------------------------------------------
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN
    
        SELECT @AccUnit = A.RecvAccUnit, 
               @AccDate = A.NewAccDate, 
               @SlipUnit = C.SlipUnit
          FROM #TACSlip AS A 
          LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
          LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
         WHERE A.IDX_NO = @Cnt 
        
        SELECT @SlipNo = '', @SlipMstID = '' 
        
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
        
        UPDATE A 
           SET CNewSlipMstID = @SlipMstID, 
               CNewSlipNo = @SlipNo
          FROM #TACSlip AS A 
         WHERE A.IDX_NO = @Cnt 
        
        IF @Cnt = ( SELECT MAX(IDX_NO) FROM #TACSlip ) 
        BEGIN 
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
    ---------------------------------------------------------------------------------------------
    -- 기표번호 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 기표코드 생성
    ---------------------------------------------------------------------------------------------
    SELECT @Count = ( SELECT COUNT(1) FROM #TACSlip )
    
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlip', 'SlipMstSeq', @Count 
    
    UPDATE A 
       SET CNewSlipMstSeq = @Seq + DataSeq 
      FROM #TACSlip AS A 
    ---------------------------------------------------------------------------------------------
    -- 기표코드 생성, END 
    ---------------------------------------------------------------------------------------------
    
    TRUNCATE TABLE #Slip
    INSERT INTO #Slip 
    ( 
        SlipMstSeq,     SlipMstID,      AccUnit,        SlipUnit,       AccDate, 
        SlipNo,         SlipKind,       RegEmpSeq,      RegDeptSeq
    )
    SELECT A.CNewSlipMstSeq, A.CNewSlipMstID, A.RecvAccUnit, C.SlipUnit, A.NewAccDate, 
           A.CNewSlipNo, C.SlipKind, ISNULL(D.EmpSeq,1), ISNULL(D.DeptSeq,0) 
      FROM #TACSlip AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS D ON ( D.EmpSeq = @EmpSeq ) 
    
    TRUNCATE TABLE #SlipRow_Sub
    INSERT INTO #SlipRow_Sub 
    (
        SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit, 
        AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq, 
        UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
        CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary
    )
    SELECT CNewSlipSeq, CNewSlipMstSeq, '', RecvAccUnit, C.SlipUnit, 
           NewAccDate, CNewSlipNo, '', B.RowSlipUnit, @EnvAccSeq, 
           0, 1 AS SMDrOrCr, A.CrAmt, 0, B.CrForAmt, 
           0, B.CurrSeq, B.ExRate, CNewSlipMstID, B.Summary
      FROM #TACSlip AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
    
    UNION ALL 
    
    SELECT CNewSlipSeq, CNewSlipMstSeq, '', RecvAccUnit, C.SlipUnit, 
           NewAccDate, CNewSlipNo, '', B.RowSlipUnit, CrAccSeq, 
           0, -1, 0, A.CrAmt, 0, CrForAmt, 
           B.CurrSeq, B.ExRate, CNewSlipMstID, B.Summary
      FROM #TACSlip AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip    AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
     ORDER BY CNewSlipMstSeq, SMDrOrCr DESC
    
    TRUNCATE TABLE #SlipRow 
    INSERT INTO #SlipRow
    (
        SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit, 
        AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq, 
        UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
        CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary,    
        Sub_No 
    )
    SELECT SlipSeq,        SlipMstSeq,     SlipID,     AccUnit,        SlipUnit, 
           AccDate,        SlipNo,         RowNo,      RowSlipUnit,    AccSeq, 
           UMCostType,     SMDrOrCr,       DrAmt,      CrAmt,          DrForAmt, 
           CrForAmt,       CurrSeq,        ExRate,     SlipMstID,      Summary,
           ROW_NUMBER() OVER(PARTITION BY SlipMstSeq ORDER BY SlipSeq) AS Sum_No
      FROM #SlipRow_Sub 
    
    ---------------------------------------------------------------------------------------------
    -- 전표코드 생성 
    ---------------------------------------------------------------------------------------------
    
    SELECT @Count = (SELECT COUNT(1) FROM #SlipRow) 
    
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlipRow', 'SlipSeq', @Count
    
    UPDATE A
       SET SlipSeq = @Seq + IDX_NO 
      FROM #SlipRow AS A 
    
    ---------------------------------------------------------------------------------------------
    -- 전표코드 생성, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 전표번호 생성
    ---------------------------------------------------------------------------------------------
    UPDATE #SlipRow
       SET RowNo = RIGHT('0000' + CAST(ISNULL(B.RowNo,0) + A.Sub_No AS NVARCHAR), @RowCnt)
      FROM #SlipRow AS A 
      LEFT OUTER JOIN ( SELECT A.AccDate, A.AccUnit, A.SlipUnit, MAX(CONVERT(INT,A.RowNo)) AS RowNo
                          FROM _TACSlipRow AS A 
                         WHERE CompanySeq = @CompanySeq 
                           AND EXISTS (SELECT 1 FROM #SlipRow WHERE AccDate = A.AccDate)
                         GROUP BY A.AccDate, A.AccUnit, A.SlipUnit
                      ) AS B ON ( B.AccDate = A.AccDate AND B.AccUnit = A.AccUnit AND B.SlipUnit = A.SlipUnit ) 
    
    UPDATE #SlipRow
       SET SlipID = SlipMstID + '-' + RowNo
    
    ---------------------------------------------------------------------------------------------
    -- 전표번호 생성, END 
    --------------------------------------------------------------------------------------------- 
    
    ---------------------------------------------------------------------------------------------
    -- 관리항목 생성
    ---------------------------------------------------------------------------------------------
    TRUNCATE TABLE #SlipRem 
    INSERT INTO #SlipRem ( SlipSeq, RemSeq, RemValSeq, RemValText, AccSeq ) 
    SELECT A.SlipSeq, 1031 AS RemSeq, B.RemAccUnit, '', A.AccSeq
      FROM #SlipRow AS A 
      LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
     WHERE SMDrOrCr = 1 
    
    UNION ALL 
    
    SELECT A.SlipSeq, F.RemSeq, F.RemValSeq, F.RemValText, A.AccSeq
      FROM #SlipRow AS A  
      LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
      --LEFT OUTER JOIN _TACSlipRow AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
      --LEFT OUTER JOIN _TACSlip    AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipMstSeq = C.SlipMstSeq ) 
      --LEFT OUTER JOIN _TACSlipRow AS E ON ( E.CompanySeq = @CompanySeq AND E.SlipMstSeq = D.SlipMstSeq AND E.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS F ON ( F.CompanySeq = @CompanySeq AND F.SlipSeq = B.SlipSeq ) 
     WHERE A.SMDrOrCr = -1 
    ORDER BY SlipSeq, RemSeq

    
    
    --SELECT A.SlipSeq, 1031 AS RemSeq, B.RemAccUnit, '' 
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = 1 
    
    --UNION ALL 
    
    --SELECT A.SlipSeq AS SlipSeq, 1017 , B.RemCustSeq AS RemValSeq, '' AS RemValText
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = -1 
    
    --UNION ALL 
    
    --SELECT A.SlipSeq, 1031, B.SendAccUnit, '' 
    --  FROM #SlipRow AS A 
    --  LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
    -- WHERE SMDrOrCr = -1 

    ---------------------------------------------------------------------------------------------
    -- 관리항목 생성, END 
    ---------------------------------------------------------------------------------------------
    --return 
    ---------------------------------------------------------------------------------------------
    -- 전표의비용배부 데이터 생성
    ---------------------------------------------------------------------------------------------
    TRUNCATE TABLE #SlipCost
    INSERT INTO #SlipCost 
    (
        SlipSeq,    Serl,   CostDeptSeq,    CostCCtrSeq,    DivRate, 
        DrAmt,      CrAmt,  DrForAmt,       CrForAmt 
    )
    SELECT A.SlipSeq, 1, B.RegDeptSeq, 0, 100, 
           A.DrAmt, A.CrAmt, A.DrAmt, A.CrAmt 
      FROM #SlipRow AS A 
      JOIN #Slip    AS B ON ( B.SlipMstSeq = A.SlipMstSeq ) 
    ---------------------------------------------------------------------------------------------
    -- 전표의비용배부 데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    
    /*
    ---------------------------------------------------------------------------------------------
    -- 반제데이터 생성
    ---------------------------------------------------------------------------------------------
    TRUNCATE TABLE #SlipOff
    INSERT INTO #SlipOff 
    (
        SlipSeq, OnSlipSeq, SmDrOrCr, OffAmt, OffForAmt 
    )
    SELECT A.SlipSeq, B.SlipSeq, 1, A.CrAmt, 0 
      FROM #SlipRow AS A 
      LEFT OUTER JOIN #TACSlip AS B ON ( B.CNewSlipMstSeq = A.SlipMstSeq ) 
     WHERE A.SMDrOrCr = -1 
    ---------------------------------------------------------------------------------------------
    -- 반제데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    */
    
    ---------------------------------------------------------------------------------------------
    -- 실 데이터 생성 
    ---------------------------------------------------------------------------------------------
    INSERT INTO _TACSlip -- 전표마스터 
    (
        CompanySeq,     SlipMstSeq,     SlipMstID,      AccUnit,        SlipUnit,         
        AccDate,        SlipNo,         SlipKind,       RegEmpSeq,      RegDeptSeq,         
        Remark,         SMCurrStatus,   AptDate,        AptEmpSeq,      AptDeptSeq,         
        AptRemark,      SMCheckStatus,  CheckOrigin,    IsSet,          SetSlipNo,         
        SetEmpSeq,      SetDeptSeq,     LastUserSeq,    LastDateTime,   RegDateTime,         
        RegAccDate,     SetSlipID
    ) 
    SELECT @CompanySeq, SlipMstSeq, SlipMstID, AccUnit, SlipUnit, 
           AccDate, SlipNo, SlipKind, RegEmpSeq, RegDeptSeq, 
           '', 0, '', 0, 0, 
           '', 0, 0, '0', '', 
           0, 0, @UserSeq, GETDATE(), GETDATE(), 
           AccDate, '' 
      FROM #Slip 
    
    --select *from #SlipRow 
    
    INSERT INTO _TACSlipRow -- 전표Row 
    (
        CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,     
        SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit,     
        AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,     
        DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         DivExRate,     
        EvidSeq,        TaxKindSeq,     NDVATAmt,       CashItemSeq,    SMCostItemKind,     
        CostItemSeq,    Summary,        BgtDeptSeq,     BgtCCtrSeq,     BgtSeq,     
        IsSet,          CoCustSeq,      LastDateTime,   LastUserSeq
    ) 
    SELECT @CompanySeq,     SlipSeq,        SlipMstSeq,     SlipID,         AccUnit,     
            SlipUnit,       AccDate,        SlipNo,         RowNo,          RowSlipUnit,     
            AccSeq,         UMCostType,     SMDrOrCr,       DrAmt,          CrAmt,     
            DrForAmt,       CrForAmt,       CurrSeq,        ExRate,         0,     
            0,              NULL,           NULL,           0,              0,     
            0,              Summary,        0,              0,              0,     
            '0',            0,              GETDATE(),      @UserSeq
      FROM #SlipRow
    
    INSERT INTO _TACSlipRem (CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText) -- 관리항목 
    SELECT @CompanySeq, SlipSeq, RemSeq, RemValSeq, RemValText
      FROM #SlipRem  
    --select * from _TDACust where CustSeq = 376
    
    INSERT INTO _TACSlipCost -- 전표비용배부
    (
        CompanySeq,     SlipSeq,    Serl,       CostDeptSeq,    CostCCtrSeq,     
        DivRate,        DrAmt,      CrAmt,      DrForAmt,       CrForAmt
    )
    SELECT @CompanySeq,     SlipSeq,    Serl,       CostDeptSeq,    CostCCtrSeq,     
            DivRate,        DrAmt,      CrAmt,      DrForAmt,       CrForAmt
      FROM #SlipCost 
    
    
    --select * from _TACSlipOn where 
    --select * from _TACCashOn where CompanySeq =1 and SlipSeq = 17001220 
    
    INSERT INTO _TACSlipOn (CompanySeq, SlipSeq, RemSeq, RemValSeq, OnAmt, OnForAmt, CurrSeq, ExRate, DivExRate) 
    SELECT @CompanySeq, A.SlipSeq, B.RemSeq, B.RemValSeq, A.CrAmt, D.CrForAmt, D.CurrSeq, D.ExRate, 0 
      FROM #SlipRow AS A 
      LEFT OUTER JOIN #SlipRem AS B ON ( B.SlipSeq = A.SlipSeq AND B.AccSeq = A.AccSeq AND B.RemSeq <> 1031 ) 
      LEFT OUTER JOIN #TACSlip AS C ON ( C.CNewSlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlipRow AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = C.SlipSeq ) 
     WHERE A.SMDrOrCr = -1 
    
    --SELECT SlipMstSeq
    --  FROM #SlipRow AS A
    
    --select CNewSlipMstSeq from #TACSlip 
    
    --return 
    
    
    --select * from _TACCashOn 
    INSERT INTO _TACCashOn 
    (
        CompanySeq, SlipSeq, IsIni, CashDate, SMCashMethod, 
        SMInOrOut, IsCfm, IsAccCfm, Memo, OnAmt, 
        OnForAmt, CustSeq, CustBankAccSerl, EmpSeq, UMAccNoType, 
        BillNo, BankSeq, DrawDate, DueDate, BillCardSeq, 
        PayBillSeq, LastUserSeq, LastDateTime, PayBillNo
    )
    SELECT @CompanySeq, C.SlipSeq, D.IsIni, D.CashDate, D.SMCashMethod, 
           D.SMInOrOut, '0', '0', '', C.CrAmt, 
           D.OnForAmt, D.CustSeq, D.CustBankAccSerl, D.EmpSeq, D.UMAccNoType, 
           D.BillNo, D.BankSeq, D.DrawDate, D.DueDate, D.BillCardSeq, 
           D.PayBillSeq, @UserSeq , GETDATE(), D.PayBillNo
      FROM #TACSlip AS A 
      LEFT OUTER JOIN #Slip AS B ON ( B.SlipMstSeq = A.CNewSlipMstSeq ) 
      LEFT OUTER JOIN #SlipRow AS C ON ( C.SlipMstSeq = B.SlipMstSeq AND C.SMDrOrCr = -1 ) 
      LEFT OUTER JOIN _TACCashOn AS D ON ( D.SlipSeq = A.SlipSeq ) 
    --select * from #SlipRow 
    --return 
    
    
    --INSERT INTO _TACSlipOff (CompanySeq, SlipSeq, OnSlipSeq, SMDrOrCr, OffAmt, OffForAmt) -- 반제
    --SELECT @CompanySeq, SlipSeq, OnSlipSeq, SMDrOrCr, OffAmt, OffForAmt
    --  FROM #SlipOff 
    
    --INSERT INTO _TACCashOff (CompanySeq, SlipSeq, OffAmt, OffForAmt, OnSlipSeq, LastUserSeq, LastDateTime) -- 반제 
    --SELECT @CompanySeq, SlipSeq, OffAmt, OffForAmt, OnSlipSeq, @UserSeq, GETDATE()
    --  FROM #SlipOff
    
    ---------------------------------------------------------------------------------------------
    -- 실 데이터 생성, END 
    ---------------------------------------------------------------------------------------------
    ALTER TABLE #TACSlip ADD NewCrSlipSeq INT NULL 
    
    UPDATE A
       SET CNewDrAccName = E.AccName, 
           --CNewRemCustName = G.CustName, 
           CNewSlipID = D.SlipID, 
           CNewSlipSeq = D.SlipSeq, 
           NewCrAccName = H.AccName, 
           NewDrAccName = K.AccName, 
           NewDrRemCustName = O.CustName, 
           NewSlipID = B.SlipID, 
           NewSlipSeq = B.SlipSeq, 
           NewCrSlipSeq = C.SlipSeq, 
           SMComplete = 1039001, 
           SMCompleteName = (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1039001), 
           CNewAccUnitName = RR.AccUnitName, 
           NewDrRemAccUnitName = SS.AccUnitName, 
           NewCrRemAccUnitName = J.AccUnitName
    
      FROM #TACSlip AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipMstSeq = A.NewSlipMstSeq AND B.SMDrOrCr = 1 ) 
      LEFT OUTER JOIN _TACSlipRow AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = A.NewSlipMstSeq AND C.SMDrOrCr = -1 ) 
      LEFT OUTER JOIN _TACSlipRow AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipMstSeq = A.CNewSlipMstSeq AND D.SMDrOrCr = 1 ) 
      LEFT OUTER JOIN _TDAAccount AS E ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = D.AccSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS F ON ( F.CompanySeq = @CompanySeq AND F.SlipSeq = D.SlipSeq AND F.RemSeq = 1017 ) 
      LEFT OUTER JOIN _TDACust    AS G ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = F.RemValSeq ) 
      LEFT OUTER JOIN _TDAAccount AS H ON ( H.CompanySeq = @CompanySeq AND H.AccSeq = C.AccSeq ) 
      --LEFT OUTER JOIN _TACSlipRem AS I ON ( I.CompanySeq = @CompanySeq AND I.SlipSeq = C.SlipSeq AND I.RemSeq = 1031 ) 
      LEFT OUTER JOIN _TDAAccUnit AS J ON ( J.CompanySeq = @CompanySeq AND J.AccUnit = C.AccUnit ) 
      LEFT OUTER JOIN _TDAAccount AS K ON ( K.CompanySeq = @CompanySeq AND K.AccSeq = B.AccSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS L ON ( L.CompanySeq = @CompanySeq AND L.SlipSeq = B.SlipSeq AND L.RemSeq = 1031 ) 
      LEFT OUTER JOIN _TDAAccUnit AS M ON ( M.CompanySeq = @CompanySeq AND M.AccUnit = L.RemValSeq ) 
      LEFT OUTER JOIN _TACSlipRem AS N ON ( N.CompanySeq = @CompanySeq AND N.SlipSeq = B.SlipSeq AND N.RemSeq = 1017 ) 
      LEFT OUTER JOIN _TDACust    AS O ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = N.RemValSeq ) 
      LEFT OUTER JOIN _TDAAccUnit AS SS ON ( SS.CompanySeq = @CompanySeq AND SS.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAAccUnit AS RR ON ( RR.CompanySeq = @CompanySeq AND RR.AccUnit = D.AccUnit ) 
    

    DELETE B 
      FROM #TACSlip AS A
      JOIN KPX_TACBranchSlipOnReg AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
    
    INSERT INTO KPX_TACBranchSlipOnReg (CompanySeq, SlipSeq, NewDrSlipSeq, NewCrSlipSeq, CNewSlipSeq, LastUserSeq, LastDateTime) 
    SELECT @CompanySeq, SlipSeq, NewSlipSeq, NewCrSlipSeq, CNewSlipSeq, @UserSeq, GETDATE()
      FROM #TACSlip AS A 
    
    SELECT * FROM #TACSlip 
    
    RETURN
GO 

begin tran 

exec KPX_SACBranchSlipOnRegSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CashDate>20150604</CashDate>
    <CNewDrAccName />
    <CNewAccUnitName />
    <CNewSlipID />
    <CNewSlipMstID />
    <CNewSlipSeq>0</CNewSlipSeq>
    <CrAccName>외화외상매입금</CrAccName>
    <CrAccSeq>103</CrAccSeq>
    <CrSummary>2015031604  물품대</CrSummary>
    <NewAccDate>99991231</NewAccDate>
    <NewCrAccName />
    <NewCrRemAccUnitName />
    <NewDrAccName />
    <NewDrRemAccUnitName />
    <NewDrRemCustName />
    <NewSlipID />
    <NewSlipMstID />
    <NewSlipSeq>0</NewSlipSeq>
    <RecvAccUnit>1</RecvAccUnit>
    <RemAccUnit>5</RemAccUnit>
    <RemAccUnitName>AM 사업부</RemAccUnitName>
    <RemCustName>BASF SOUTH EAST ASIA PTE LTD.</RemCustName>
    <RemCustSeq>50</RemCustSeq>
    <Sel>1</Sel>
    <SendAccUnit>5</SendAccUnit>
    <SendAccUnitName>AM 사업부</SendAccUnitName>
    <SlipID>C0-D1-20150528-0005-014</SlipID>
    <SlipMstID>C0-D1-20150528-0005</SlipMstID>
    <SlipSeq>4450532</SlipSeq>
    <SMCashMethod>4008003</SMCashMethod>
    <SMCashMethodName>예금지급</SMCashMethodName>
    <SMComplete>1039002</SMComplete>
    <SMCompleteName>미처리</SMCompleteName>
    <CrAmt>42067943.00000</CrAmt>
    <SMInOrOut>4003002</SMInOrOut>
    <SMInOrOutName>출금</SMInOrOutName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1028117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1023536

rollback 