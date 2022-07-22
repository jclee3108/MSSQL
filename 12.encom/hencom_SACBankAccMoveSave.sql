  
IF OBJECT_ID('hencom_SACBankAccMoveSave') IS NOT NULL   
    DROP PROC hencom_SACBankAccMoveSave  
GO  
  
-- v2017.05.15
  
-- 계좌간이동입력-저장 by 이재천
CREATE PROC hencom_SACBankAccMoveSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACBankAccMove (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACBankAccMove'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACBankAccMove')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TACBankAccMove'    , -- 테이블명        
                  '#hencom_TACBankAccMove'    , -- 임시 테이블명        
                  'MoveSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_TACBankAccMove   AS A   
          JOIN hencom_TACBankAccMove    AS B ON ( B.CompanySeq = @CompanySeq AND A.MoveSeq = B.MoveSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.StdDate        = A.StdDate       ,  
               B.OutBankAccSeq  = A.OutBankAccSeq ,  
               B.OutAmt         = A.OutAmt        ,  
               B.InBankAccSeq   = A.InBankAccSeq  ,  
               B.InAmt          = A.InAmt         ,  
               B.AddAmt         = A.AddAmt        ,  
               B.DrAccSeq       = A.DrAccSeq      ,  
               B.CrAccSeq       = A.CrAccSeq      ,  
               B.AddAccSeq      = A.AddAccSeq     ,  
               B.Remark         = A.Remark        ,
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #hencom_TACBankAccMove   AS A   
          JOIN hencom_TACBankAccMove    AS B ON ( B.CompanySeq = @CompanySeq AND A.MoveSeq = B.MoveSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACBankAccMove  
        (   
            CompanySeq, MoveSeq, StdDate, OutBankAccSeq, OutAmt, 
            InBankAccSeq, InAmt, AddAmt, DrAccSeq, CrAccSeq, 
            AddAccSeq, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.MoveSeq, A.StdDate, A.OutBankAccSeq, A.OutAmt, 
               A.InBankAccSeq, A.InAmt, A.AddAmt, A.DrAccSeq, A.CrAccSeq, 
               A.AddAccSeq, A.Remark, @UserSeq, GETDATE(), @PgmSeq 
          FROM #hencom_TACBankAccMove AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #hencom_TACBankAccMove   
    
    RETURN  
GO
begin tran 
exec hencom_SACBankAccMoveSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <StdDate>20170501</StdDate>
    <OutBankAccName>계좌2</OutBankAccName>
    <OutAmt>200000.00000</OutAmt>
    <InBankAccName>테스트계좌</InBankAccName>
    <InAmt>90000.00000</InAmt>
    <AddAmt>110000.00000</AddAmt>
    <OutBankAccNo>140-008-670759</OutBankAccNo>
    <OutBankName>신한은행</OutBankName>
    <InBankAccNo>123123123</InBankAccNo>
    <InBankName>테스트금융기관지점</InBankName>
    <DrAccName>제예금</DrAccName>
    <CrAccName>대손충당금_기타회원권</CrAccName>
    <AddAccName>매도가능금융자산_기업발행채무증권</AddAccName>
    <MoveSeq>8</MoveSeq>
    <DrAccSeq>7</DrAccSeq>
    <CrAccSeq>401</CrAccSeq>
    <AddAccSeq>412</AddAccSeq>
    <OutBankAccSeq>5</OutBankAccSeq>
    <InBankAccSeq>1</InBankAccSeq>
    <Remark>2</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512197,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033591
rollback 