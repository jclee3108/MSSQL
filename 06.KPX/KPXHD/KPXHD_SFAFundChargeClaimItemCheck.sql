  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimItemCheck') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimItemCheck  
GO  
  
-- v2016.02.03  
  
-- 자금운용대행수수료청구내역입력-품목체크 by 이재천   
CREATE PROC KPXHD_SFAFundChargeClaimItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @MaxSerl        INT, 
            @MaxFnudCode    INT 
      
    CREATE TABLE #KPXHD_TFAFundChargeClaimItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXHD_TFAFundChargeClaimItem'   
    IF @@ERROR <> 0 RETURN     
    /*
    -- 종목명 중복 체크 
    UPDATE #KPXHD_TFAFundChargeClaimItem  
       SET Result       = '종목명이 중복되었습니다.', 
           MessageType  = 1234,  
           Status       = 1234 
      FROM #KPXHD_TFAFundChargeClaimItem AS A   
      JOIN (SELECT S.FundName  
              FROM (SELECT A1.FundName 
                      FROM #KPXHD_TFAFundChargeClaimItem AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.FundName  
                      FROM KPXHD_TFAFundChargeClaimItem AS A1  
                      JOIN KPXHD_TFAFundChargeClaim     AS A2 ON ( A2.CompanySeq = @CompanySeq AND A2.FundChargeSeq = A1.FundChargeSeq ) 
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND A2.UMHelpCom IN ( SELECT TOP 1 UMHelpCom FROM #KPXHD_TFAFundChargeClaimItem ) 
                       AND NOT EXISTS (SELECT 1 FROM #KPXHD_TFAFundChargeClaimItem   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND FundChargeSeq = A1.FundChargeSeq
                                                 AND FundChargeSerl = A1.FundChargeSerl
                                      )  
                   ) AS S  
             GROUP BY S.FundName  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.FundName = B.FundName )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    */
    
    SELECT @MaxFnudCode = ( SELECT MAX(CONVERT(INT,RIGHT(A.FundCode,3))) 
                              FROM KPXHD_TFAFundChargeClaimItem     AS A 
                              JOIN KPXHD_TFAFundChargeClaim         AS B ON ( B.CompanySeq = @CompanySeq AND B.FundChargeSeq = A.FundChargeSeq ) 
                              JOIN #KPXHD_TFAFundChargeClaimItem    AS C ON ( C.UMHelpCom = B.UMHelpCom AND C.StdYM = B.StdYM ) 
                             WHERE A.CompanySeq = @CompanySeq 
                          )
    
    
    SELECT @MaxSerl = ( SELECT MAX(A.FundChargeSerl) 
                          FROM KPXHD_TFAFundChargeClaimItem AS A 
                         WHERE CompanySeq = @CompanySeq 
                           AND A.FundChargeSeq IN ( SELECT TOP 1 FundChargeSeq FROM #KPXHD_TFAFundChargeClaimItem ) 
                      ) 
                        
    UPDATE A 
       SET FundChargeSerl = ISNULL(@MaxSerl,0) + A.DataSeq, 
           FundCode = ISNULL(B.ValueText,'') + A.StdYM + RIGHT('000' + CONVERT(NVARCHAR(10),ISNULL(@MaxFnudCode,0) + A.DataSeq),3)
      FROM #KPXHD_TFAFundChargeClaimItem    AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMHelpCom AND B.Serl = 1000006 ) 
 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    
    SELECT * FROM #KPXHD_TFAFundChargeClaimItem   
    
    RETURN  
    go
    begin tran
exec KPXHD_SFAFundChargeClaimItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FundCode />
    <FundName>테스트33335</FundName>
    <ActAmt>0</ActAmt>
    <CancelDate />
    <ProfitRate>0</ProfitRate>
    <ProfitAmt>0</ProfitAmt>
    <SrtDate />
    <EndDate />
    <FromToDate>0</FromToDate>
    <StdProfitRate>0</StdProfitRate>
    <ExcessProfitAmt>0</ExcessProfitAmt>
    <AdviceAmt>0</AdviceAmt>
    <FundChargeSeq>11</FundChargeSeq>
    <FundChargeSerl>0</FundChargeSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <UMHelpCom>1010494001</UMHelpCom>
    <StdYM>201602</StdYM>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028674
rollback 