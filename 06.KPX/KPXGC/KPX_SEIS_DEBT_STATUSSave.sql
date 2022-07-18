  
IF OBJECT_ID('KPX_SEIS_DEBT_STATUSSave') IS NOT NULL   
    DROP PROC KPX_SEIS_DEBT_STATUSSave  
GO  
  
-- v2014.11.24  
  
-- (경영정보)매입채무-저장 by 이재천   
CREATE PROC KPX_SEIS_DEBT_STATUSSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TEIS_DEBT_STATUS (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_DEBT_STATUS'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @PlanYM NCHAR(6) 
    
    SELECT @PlanYM = (SELECT TOP 1 PlanYM FROM #KPX_TEIS_DEBT_STATUS) 
    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEIS_DEBT_STATUS')    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_DEBT_STATUS WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
    
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_DEBT_STATUS'    , -- 테이블명        
                      '#KPX_TEIS_DEBT_STATUS'    , -- 임시 테이블명        
                      'PlanYM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        DELETE B   
          FROM #KPX_TEIS_DEBT_STATUS AS A   
          JOIN KPX_TEIS_DEBT_STATUS AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM )  
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_DEBT_STATUS WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
    
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TEIS_DEBT_STATUS'    , -- 테이블명        
                      '#KPX_TEIS_DEBT_STATUS'    , -- 임시 테이블명        
                      'PlanYM,UMDEBTItem'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B   
           SET B.ActPlusAmt = A.ActPlusAmt,  
               B.ActMinusAmt = A.ActMinusAmt,  
               B.PlanRestAmt = A.PlanRestAmt,  
               B.PlanPlusAmt = A.PlanPlusAmt,  
               B.PlanMinusAmt = A.PlanMinusAmt,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TEIS_DEBT_STATUS AS A   
          JOIN KPX_TEIS_DEBT_STATUS AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM AND B.UMDEBTItem = A.UMDEBTItem )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEIS_DEBT_STATUS WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        INSERT INTO KPX_TEIS_DEBT_STATUS  
        (   
            CompanySeq,PlanYM,UMDEBTItem,ActPlusAmt,ActMinusAmt,  
            PlanRestAmt,PlanPlusAmt,PlanMinusAmt,LastUserSeq,LastDateTime  
               
        )   
        SELECT @CompanySeq,A.PlanYM,A.UMDEBTItem,A.ActPlusAmt,A.ActMinusAmt,  
               A.PlanRestAmt,A.PlanPlusAmt,A.PlanMinusAmt,@UserSeq,GETDATE()  
        
            FROM #KPX_TEIS_DEBT_STATUS AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    END 
    
    -- 집계용 값 업데이트 하기 
    SELECT C.ValueSeq AS UMDEBTItemKind, 
           SUM(A.ActPlusAmt) AS SumActPlusAmt, 
           SUM(A.ActMinusAmt) AS SumActMinusAmt, 
           SUM(A.PlanRestAmt) AS SumPlanRestAmt, 
           SUM(A.PlanPlusAmt) AS SumPlanPlusAmt, 
           SUM(A.PlanMinusAmt) AS SumPlanMinusAmt
      INTO #Sum_KPX_TEIS_DEBT_STATUS
      FROM KPX_TEIS_DEBT_STATUS AS A 
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMDEBTItem ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = B.MinorSeq AND E.Serl = 1000002 ) 
                 JOIN (SELECT DISTINCT Q.ValueSeq
                         FROM KPX_TEIS_DEBT_STATUS         AS Z 
                         LEFT OUTER JOIN _TDAUMinorValue   AS X ON ( X.CompanySeq = @CompanySeq AND X.MinorSeq = Z.UMDEBTItem AND X.Serl = 1000002 ) 
                         LEFT OUTER JOIN _TDAUMinorValue   AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.UMDEBTItem AND Q.Serl = 1000001 ) 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND X.ValueText = '1'
                      ) AS F ON ( F.ValueSeq = C.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanYM = @PlanYM 
       AND E.ValueText = '0' 
    GROUP BY C.ValueSeq 
    
    UPDATE A
       SET ActPlusAmt = D.SumActPlusAmt, 
           ActMinusAmt = D.SumActMinusAmt, 
           PlanRestAmt = D.SumPlanRestAmt, 
           PlanPlusAmt = D.SumPlanPlusAmt, 
           PlanMinusAmt = D.SumPlanMinusAmt 
      FROM KPX_TEIS_DEBT_STATUS                 AS A 
      LEFT OUTER JOIN _TDAUMinorValue           AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMDEBTItem AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMDEBTItem AND C.Serl = 1000002 ) 
                 JOIN #Sum_KPX_TEIS_DEBT_STATUS AS D ON ( D.UMDEBTItemKind = B.ValueSeq AND C.ValueText = '1' ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanYM = @PlanYM 
      

    SELECT * FROM #KPX_TEIS_DEBT_STATUS   
      
    RETURN  
GO 
begin tran 
exec KPX_SEIS_DEBT_STATUSSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ActMinusAmt>0.00000</ActMinusAmt>
    <ActPlusAmt>2.00000</ActPlusAmt>
    <PlanMinusAmt>0.00000</PlanMinusAmt>
    <PlanPlusAmt>0.00000</PlanPlusAmt>
    <PlanRestAmt>0.00000</PlanRestAmt>
    <PlanYM>201412</PlanYM>
    <UMDEBTItem>1010326001</UMDEBTItem>
    <UMDEBTItemKind>1010325001</UMDEBTItemKind>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ActMinusAmt>0.00000</ActMinusAmt>
    <ActPlusAmt>2.00000</ActPlusAmt>
    <PlanMinusAmt>0.00000</PlanMinusAmt>
    <PlanPlusAmt>0.00000</PlanPlusAmt>
    <PlanRestAmt>0.00000</PlanRestAmt>
    <PlanYM>201412</PlanYM>
    <UMDEBTItem>1010326005</UMDEBTItem>
    <UMDEBTItemKind>1010325001</UMDEBTItemKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026113,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021903
rollback 