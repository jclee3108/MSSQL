IF OBJECT_ID('mnpt_SARUsualCostAmtOppAccUpdate') IS NOT NULL 
    DROP PROC mnpt_SARUsualCostAmtOppAccUpdate
GO 

-- v2018.01.12
  
-- 일반비용신청_mnpt-상대계정수정 by 이재천
/************************************************************
설  명 - 일반비용신청서금액 - 저장
작성일 - 2010년 04월 19일 
작성자 - 송경애
************************************************************/
CREATE PROC dbo.mnpt_SARUsualCostAmtOppAccUpdate
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    DECLARE @UMCostTypeKind     INT,
            @UMCostType         INT,
            @DeptCCtrSeq        INT
    -- 서비스 마스타 등록 생성
    CREATE TABLE #TARUsualCostAmt (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARUsualCostAmt'     
    IF @@ERROR <> 0 RETURN    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog  @CompanySeq   ,
                   @UserSeq      ,
                   '_TARUsualCostAmt', -- 원테이블명
                   '#TARUsualCostAmt', -- 템프테이블명
                   'UsualCostSeq,UsualCostSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                   'CompanySeq,UsualCostSeq,UsualCostSerl,CostSeq,RemValSeq,Amt,IsVat,SupplyAmt,VatAmt,CustSeq,CustText,EvidSeq,Remark,AccSeq,VatAccSeq,OppAccSeq,LastUserSeq,LastDateTime,UMCostType,CostCashDate,CustDate,BgtDeptCCtrSeq'

    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #TARUsualCostAmt WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE _TARUsualCostAmt
           SET  EvidSeq         = B.EvidSeq    
              , CustText        = B.CustText
              , OppAccSeq       = B.OppAccSeq  
              , CustDate        = B.CustDate 
              , LastUserSeq     = @UserSeq
              , LastDateTime    = GETDATE()  
          FROM _TARUsualCostAmt AS A JOIN #TARUsualCostAmt AS B ON (A.UsualCostSeq = B.UsualCostSeq AND A.UsualCostSerl = B.UsualCostSerl)  
         WHERE B.WorkingTag = 'U' AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq 
        IF @@ERROR <> 0  RETURN
    END   
    
    SELECT * FROM #TARUsualCostAmt   
RETURN    
--go
--begin tran 
--EXEC mnpt_SARUsualCostAmtOppAccUpdate @xmlDocument = N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <UsualCostSerl>1</UsualCostSerl>
--    <EvidSeq>20</EvidSeq>
--    <OppAccSeq>5</OppAccSeq>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--  </DataBlock1>
--</ROOT>', @xmlFlags = 2, @ServiceSeq = 13820117, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 167, @PgmSeq = 13820108
--rollback 