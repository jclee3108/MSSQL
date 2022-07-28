
IF OBJECT_ID('_SACLendRePayOptSave') IS NOT NULL 
    DROP PROC _SACLendRePayOptSave 
GO 

-- v2013.12.19 

-- 대여금등록(상환조건저장) by이재천
CREATE PROC _SACLendRePayOptSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS   
    
	CREATE TABLE #TACLendRePayOpt (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TACLendRePayOpt'     
	IF @@ERROR <> 0 RETURN  
    --select * from #TACLendRePayOpt 
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACLendRePayOpt')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACLendRePayOpt', -- 테이블명        
                  '#TACLendRePayOpt', -- 임시 테이블명        
                  'LendSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 

    -- DELETE 
    IF @WorkingTag <> 'SheetDel' 
    BEGIN
	    IF EXISTS (SELECT TOP 1 1 FROM #TACLendRePayOpt WHERE WorkingTag = 'D' AND Status = 0)  
	    BEGIN  
            DELETE _TACLendRePayOpt
              FROM #TACLendRePayOpt A 
              JOIN _TACLendRePayOpt B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0   
             
            IF @@ERROR <> 0  RETURN
        END  
    END

    -- UPDATE    
	IF EXISTS (SELECT 1 FROM #TACLendRePayOpt WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE B
           SET ToDate       = A.ToDate, 
               RepayCnt     = A.RepayCnt, 
               SMRepayType  = A.SMRepayType, 
               FrDate       = A.FrDate, 
		       RepayTerm    = A.RepayTerm, 
		       DeferYear    = A.DeferYear, 
		       DeferMonth   = A.DeferMonth, 
		       OddTime      = A.OddTime, 
		       OddUnitAmt   = A.OddUnitAmt, 
		       Remark       = A.Remark, 
		       LastUserSeq  = @UserSeq, 
		       LastDateTime = GetDate()
		  FROM #TACLendRePayOpt AS A 
          JOIN _TACLendRePayOpt AS B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
         WHERE B.CompanySeq = @CompanySeq
		   AND A.WorkingTag = 'U' 
		   AND A.Status = 0    
        
		IF @@ERROR <> 0  RETURN
	END  
    
	-- INSERT
    IF EXISTS (SELECT 1 FROM #TACLendRePayOpt WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO _TACLendRePayOpt (CompanySeq, LendSeq, Serl, FrDate, RepayCnt, 
                                      ToDate, SMRepayType, RepayTerm, DeferYear, DeferMonth, 
                                      OddTime, OddUnitAmt, Remark, LastUserSeq, LastDateTime, PgmSeq
                                     ) 
		SELECT @CompanySeq, A.LendSeq, A.Serl, A.FrDate, A.RepayCnt, 
               A.ToDate, A.SMRepayType, A.RepayTerm, A.DeferYear, A.DeferMonth, 
               A.OddTime, A.OddUnitAmt, A.Remark, @UserSeq, GETDATE(), @PgmSeq 
		  FROM #TACLendRePayOpt AS A   
		 WHERE A.WorkingTag = 'A' 
		   AND A.Status = 0    
		IF @@ERROR <> 0 RETURN
	END   

    SELECT * FROM #TACLendRePayOpt 
    
    RETURN    
GO
begin tran 
exec _SACLendRePayOptSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DeferYear>0</DeferYear>
    <DeferMonth>0</DeferMonth>
    <RepayTerm>1</RepayTerm>
    <Remark>teste</Remark>
    <OddTime>0</OddTime>
    <OddUnitAmt>0.00000</OddUnitAmt>
    <LendSeq>31</LendSeq>
    <Serl>1</Serl>
    <FrDate>20131223</FrDate>
    <RepayCnt>1</RepayCnt>
    <ToDate>20140122</ToDate>
    <SMRepayType>4079001</SMRepayType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392
select * from _TACLendRePayOpt
rollback  