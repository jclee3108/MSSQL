
IF OBJECT_ID('_SACLendPlanSave') IS NOT NULL 
    DROP PROC _SACLendPlanSave 
GO 

-- v2013.12.19 

-- �뿩�ݵ��(���԰�ȹ����) by����õ
CREATE PROC _SACLendPlanSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS   
    
	CREATE TABLE #TACLendPlan (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#TACLendPlan'     
	IF @@ERROR <> 0 RETURN  
    --select * from #TACLendPlan
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACLendPlan')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACLendPlan', -- ���̺��        
                  '#TACLendPlan', -- �ӽ� ���̺��        
                  'LendSeq,Serl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
    
	-- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #TACLendPlan WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        IF @WorkingTag = 'SheetDel' 
        BEGIN 
            DELETE B
              FROM #TACLendPlan A 
              JOIN _TACLendPlan B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0 
        END
        ELSE
        BEGIN
            DELETE B
              FROM #TACLendPlan A 
              JOIN _TACLendPlan B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq ) 
             WHERE B.CompanySeq  = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0    
            END
        
        IF @@ERROR <> 0  RETURN
        
    END  
    

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #TACLendPlan WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
        UPDATE _TACLendPlan
           SET PayIntAmt   = A.PayIntAmt  ,
               PayDate     = A.PayDate    ,
               Remark      = A.Remark  ,
               PayCnt      = A.PayCnt     ,
               TotAmt      = A.TotAmt     ,
               FrDate      = A.FrDate     ,
               ToDate      = A.ToDate     ,
               PayAmt      = A.PayAmt    ,
               LastUserSeq = @UserSeq,
               LastDateTime = GetDate()
          FROM #TACLendPlan AS A 
          JOIN _TACLendPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.LendSeq = A.LendSeq AND B.Serl = A.Serl ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0  RETURN
	END  
    
	-- INSERT
	IF EXISTS (SELECT 1 FROM #TACLendPlan WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
        INSERT INTO _TACLendPlan (
                                    CompanySeq, LendSeq, Serl, PayCnt, PayDate, 
                                    FrDate, ToDate, TotAmt, PayAmt, PayIntAmt, 
                                    Remark, LastUserSeq, LastDateTime, PgmSeq
                                 ) 
        SELECT @CompanySeq, A.LendSeq, A.Serl, A.PayCnt, A.PayDate, 
               A.FrDate, A.ToDate, A.TotAmt, A.PayAmt, A.PayIntAmt, 
               A.Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #TACLendPlan AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        IF @@ERROR <> 0 RETURN
	END   

    SELECT * FROM #TACLendPlan 
    
    RETURN    
GO
begin tran

exec _SACLendPlanSave @xmlDocument=N'<ROOT>
  <DataBlock4>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <LendSeq>40</LendSeq>
    <Serl>5</Serl>
    <PayCnt>5</PayCnt>
    <PayDate>20140419</PayDate>
    <FrDate>20140320</FrDate>
    <ToDate>20140419</ToDate>
    <TotAmt>250.00000</TotAmt>
    <PayAmt>250.00000</PayAmt>
    <PayIntAmt>0.00000</PayIntAmt>
    <Remark />
  </DataBlock4>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'SheetDel',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392
select * from _TACLendPlan where CompanySeq = 1 and lendseq = 40
rollback 