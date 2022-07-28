
IF OBJECT_ID('_SACLendInterestOptSave') IS NOT NULL 
    DROP PROC _SACLendInterestOptSave 
GO 

-- v2013.12.19 

-- 대여금등록(이자납입조건저장) by이재천
CREATE PROC _SACLendInterestOptSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS   
    
	CREATE TABLE #TACLendInterestOpt (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TACLendInterestOpt'     
	IF @@ERROR <> 0 RETURN  
    --select * from #TACLendInterestOpt
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACLendInterestOpt')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACLendInterestOpt', -- 테이블명        
                  '#TACLendInterestOpt', -- 임시 테이블명        
                  'LendSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 
    
	-- DELETE    
	IF @WorkingTag <> 'SheetDel' 
	BEGIN
	    IF EXISTS (SELECT TOP 1 1 FROM #TACLendInterestOpt WHERE WorkingTag = 'D' AND Status = 0)  
	    BEGIN  
	        DELETE _TACLendInterestOpt
	          FROM #TACLendInterestOpt A 
              JOIN _TACLendInterestOpt B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
	         WHERE B.CompanySeq  = @CompanySeq
	           AND A.WorkingTag = 'D' 
	           AND A.Status = 0    
	         IF @@ERROR <> 0  RETURN
	    END  
    END


	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #TACLendInterestOpt WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE _TACLendInterestOpt
           SET FrDate           = A.FrDate, 
               DayQty           = A.DayQty, 
               PayCnt           = A.PayCnt, 
               ToDate           = A.ToDate, 
               InterestRate     = A.InterestRate, 
               SMCalcMethod     = A.SMCalcMethod, 
               InterestTerm     = A.SMInterestTerm, 
               SMInterestPayWay = A.SMInterestPayWay, 
               SMRateType       = A.SMRateType, 
               Spread           = A.Spread, 
               IntDayCountType  = A.IntDayCountType, 
               LastUserSeq      = @UserSeq,
               LastDateTime     = GetDate()
          FROM #TACLendInterestOpt AS A 
          JOIN _TACLendInterestOpt AS B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    

        IF @@ERROR <> 0  RETURN
	END  
    
	-- INSERT
	IF EXISTS (SELECT 1 FROM #TACLendInterestOpt WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
        INSERT INTO _TACLendInterestOpt (CompanySeq, LendSeq, Serl, SMCalcMethod, SMInterestPayWay, 
                                         FrDate, ToDate, InterestRate, InterestTerm, DayQty, 
                                         PayCnt, SMRateType, Spread, IntDayCountType, LastUserSeq, 
                                         LastDateTime, PgmSeq 
                                        )
        SELECT @CompanySeq, A.LendSeq, A.Serl, A.SMCalcMethod, A.SMInterestPayWay, 
               A.FrDate, A.ToDate, A.InterestRate, A.SMInterestTerm, A.DayQty, 
               A.PayCnt, A.SMRateType, A.Spread, A.IntDayCountType, @UserSeq , 
               GETDATE(), @PgmSeq 
          FROM #TACLendInterestOpt AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0 
        
        IF @@ERROR <> 0 RETURN
	END   

    SELECT * FROM #TACLendInterestOpt 
    
    RETURN    
GO
begin tran
exec _SACLendInterestOptSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <LendSeq>37</LendSeq>
    <Serl>1</Serl>
    <SMCalcMethod>4038001</SMCalcMethod>
    <FrDate>20131223</FrDate>
    <ToDate>20140122</ToDate>
    <InterestRate>1.00000</InterestRate>
    <SMInterestTerm>0</SMInterestTerm>
    <DayQty>30</DayQty>
    <PayCnt>1</PayCnt>
    <SMCalcMethodName>일보계산</SMCalcMethodName>
    <SMInterestPayWay>4037001</SMInterestPayWay>
    <SMRateType>0</SMRateType>
    <Spread>0.00000</Spread>
    <IntDayCountType>4554001</IntDayCountType>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392
select * from _TACLendInterestOpt
rollback