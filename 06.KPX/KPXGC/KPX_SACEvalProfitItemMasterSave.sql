  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterSave') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterSave  
GO  
  
-- v2014.12.20  
  
-- 평가손익상품마스터-저장 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TACEvalProfitItemMaster (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMaster'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACEvalProfitItemMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACEvalProfitItemMaster'    , -- 테이블명        
                  '#KPX_TACEvalProfitItemMaster'    , -- 임시 테이블명        
                  'EvalProfitSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACEvalProfitItemMaster WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TACEvalProfitItemMaster AS A   
          JOIN KPX_TACEvalProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq AND A.EvalProfitSeq = B.EvalProfitSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACEvalProfitItemMaster WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UMHelpCom      = A.UMHelpCom,
               B.FundSeq        = A.FundSeq,
               B.SrtDate        = A.SrtDate,
               B.DurDate        = A.DurDate,
               B.ActAmt         = A.ActAmt,      
               B.PrevAmt        = A.PrevAmt,     
               B.InvestAmt      = A.InvestAmt,    
               B.TestAmt        = A.TestAmt,   
               B.AddAmt         = A.AddAmt,  
               B.DiffActDate    = A.DiffActDate, 
               B.TagetAdd       = A.TagetAdd,
               B.StdAdd         = A.StdAdd,
               B.Risk           = A.Risk,
               B.TrustLevel     = A.TrustLevel,
               B.Remark1        = A.Remark1,
               B.Remark2        = A.Remark2,
               B.Remark3        = A.Remark3, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE()  
          FROM #KPX_TACEvalProfitItemMaster AS A   
          JOIN KPX_TACEvalProfitItemMaster AS B ON ( B.CompanySeq = @CompanySeq AND A.EvalProfitSeq = B.EvalProfitSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACEvalProfitItemMaster WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TACEvalProfitItemMaster  
        (   
            CompanySeq, EvalProfitSeq, StdDate, UMHelpCom, FundSeq, 
            SrtDate, DurDate, ActAmt ,PrevAmt ,InvestAmt,
            TestAmt ,AddAmt ,DiffActDate, TagetAdd, StdAdd, 
            Risk, TrustLevel, Remark1, Remark2, Remark3, 
            LastUserSeq, LastDateTime, FundNo
        )   
        SELECT @CompanySeq, A.EvalProfitSeq, A.StdDate, A.UMHelpCom, A.FundSeq, 
               A.SrtDate, A.DurDate, A.ActAmt ,A.PrevAmt ,A.InvestAmt,
               A.TestAmt ,A.AddAmt ,A.DiffActDate, A.TagetAdd, A.StdAdd, 
               A.Risk, A.TrustLevel, A.Remark1, A.Remark2, A.Remark3, 
               @UserSeq, GETDATE(), A.FundNo
          FROM #KPX_TACEvalProfitItemMaster AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TACEvalProfitItemMaster   
    
    RETURN  
go
begin tran  

exec KPX_SACEvalProfitItemMasterSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ActAmt>13.00000</ActAmt>
    <AddAmt>123.00000</AddAmt>
    <DiffActDate>123</DiffActDate>
    <DurDate>20141202</DurDate>
    <EvalProfitSeq>7</EvalProfitSeq>
    <FundCode>101042800210104290020006</FundCode>
    <FundKindLName />
    <FundKindMName />
    <FundKindName />
    <FundKindSName />
    <FundName>teset</FundName>
    <FundSeq>8</FundSeq>
    <InvestAmt>12312.00000</InvestAmt>
    <PrevAmt>123.00000</PrevAmt>
    <Remark1>123</Remark1>
    <Remark2>3</Remark2>
    <Remark3>23</Remark3>
    <Risk>123</Risk>
    <SrtDate>20141212</SrtDate>
    <StdAdd>123.00000</StdAdd>
    <StdDate>20141220</StdDate>
    <TagetAdd>123.00000</TagetAdd>
    <TestAmt>123.00000</TestAmt>
    <TitileName />
    <TrustLevel>123</TrustLevel>
    <UMHelpCom>1010494001</UMHelpCom>
    <UMHelpComName>투자회사1</UMHelpComName>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ActAmt>12.00000</ActAmt>
    <AddAmt>123.00000</AddAmt>
    <DiffActDate>123</DiffActDate>
    <DurDate>20141213</DurDate>
    <EvalProfitSeq>8</EvalProfitSeq>
    <FundCode>101042800210104290020007</FundCode>
    <FundKindLName />
    <FundKindMName />
    <FundKindName />
    <FundKindSName />
    <FundName>teset11</FundName>
    <FundSeq>9</FundSeq>
    <InvestAmt>123.00000</InvestAmt>
    <PrevAmt>0.00000</PrevAmt>
    <Remark1>123</Remark1>
    <Remark2>123</Remark2>
    <Remark3>123</Remark3>
    <Risk>123</Risk>
    <SrtDate>20141212</SrtDate>
    <StdAdd>123.00000</StdAdd>
    <StdDate>20141220</StdDate>
    <TagetAdd>12.00000</TagetAdd>
    <TestAmt>12.00000</TestAmt>
    <TitileName />
    <TrustLevel>123</TrustLevel>
    <UMHelpCom>1010494002</UMHelpCom>
    <UMHelpComName>투자회사2</UMHelpComName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026966,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020380
rollback 