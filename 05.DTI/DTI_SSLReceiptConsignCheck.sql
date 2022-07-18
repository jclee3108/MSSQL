
IF OBJECT_ID('DTI_SSLReceiptConsignCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignCheck
GO 

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁입금체크) by이재천
CREATE PROCEDURE DTI_SSLReceiptConsignCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0
AS 
    
    DECLARE @Count       INT,
            @DataSeq     INT,
            @ReceiptSeq  INT, 
            @ReceiptNo   NVARCHAR(20),
            @BaseDate    NVARCHAR(8),
            @MaxNo       NVARCHAR(12),
            @BizUnit     INT, 
            @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250), 
            @MaxDataSeq  INT,
            @CustEmpUse  NVARCHAR(50)
    
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #DTI_TSLReceiptConsign (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLReceiptConsign' 
    
    -------------------------------------------
    -- 전표여부체크                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          15                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = @Results,    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN DTI_TSLReceiptConsign AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
     WHERE A.WorkingTag IN ('U','D')
       AND A.Status = 0
       AND ISNULL(A1.SlipSeq, 0) <> 0
    --------------------------------------------------------------------------------------
    -- 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존해하지 않으면 에러처리
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 
                     FROM #DTI_TSLReceiptConsign AS A 
                     JOIN DTI_TSLReceiptConsign AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
                    WHERE A.WorkingTag IN ('U', 'D')
                  )
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                              @LanguageSeq       , 
                              '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #DTI_TSLReceiptConsign
           SET Result        = @Results,
               MessageType   = @MessageType,
               Status        = @Status
         WHERE WorkingTag IN ('U','D')
    END    
    --------------------------------------------------------------------------------------  
    -- 필수 데이터 (거래처) 체크
    --------------------------------------------------------------------------------------  
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag IN ('A', 'U') AND ISNULL(CustSeq,0) = 0)
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq       ,   
                              6,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
        UPDATE #DTI_TSLReceiptConsign  
           SET Result        = @Results,  
               MessageType   = @MessageType,  
               Status        = @Status  
         WHERE WorkingTag IN ('A','U')  
    END  
    
    /*
    -------------------------------------------
    -- 전표여부체크                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)    
                          @LanguageSeq       ,
                          1562, '', 0, ' '
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = REPLACE(@Results,'@3',A2.PreOffNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign          AS A 
      JOIN _TSLPreReceiptItem   AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
      JOIN _TSLPreReceipt       AS A2 ON ( A2.CompanySeq = @CompanySeq AND A1.PreOffSeq = A2.PreOffSeq ) 
      WHERE A.WorkingTag IN ('A','U','D')
        AND A.Status = 0
    -------------------------------------------  
    -- 진행여부체크  
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1044                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)  
                          @LanguageSeq       ,   
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%미수%'  
    UPDATE #DTI_TSLReceiptConsign  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN _TSLExpDA AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
     WHERE A.WorkingTag IN ('U','D')
       AND A.Status = 0
    -------------------------------------------
    -- 입금미수여부체크                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 8)    
                          @LanguageSeq       ,  
                          2529, '', 11365, ''       -- SELECT * FROM _TCADictionary WHERE Word like '%건%'  
    UPDATE #DTI_TSLReceiptConsign    
       SET Result        = REPLACE(@Results,'@3',A2.ReceiptNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign          AS A 
      JOIN _TSLReceiptCreditDiv AS A1 ON A1.CompanySeq = @CompanySeq AND A.ReceiptSeq  = A1.ReceiptSeq
      JOIN _TSLReceipt          AS A2 ON A2.CompanySeq = @CompanySeq AND A.ReceiptSeq  = A2.ReceiptSeq
     WHERE A.WorkingTag IN ('A','U','D')
       AND A.Status = 0
    
     -- 담당자체크
     EXEC dbo._SCOMEnv @CompanySeq, 8001, @UserSeq, @@PROCID, @CustEmpUse OUTPUT  
   
     IF @CustEmpUse = '1'   
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1102               , -- 중단되어 처리할 수 없습니다...(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1102)    
                               @LanguageSeq        ,     
                               462,''   -- SELECT * FROM _TCADictionary WHERE WordSeq = 462 like '%거래처%'    
         UPDATE #DTI_TSLReceiptConsign  
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status    
           FROM #DTI_TSLReceiptConsign  AS A    
                 JOIN _TSLCustChargeEmp AS B ON B.CompanySeq = @CompanySeq
                                            AND A.CustSeq    = B.CustSeq
                                            AND B.UMChargeKind = 8013001
                                            AND A.ReceiptDate BETWEEN SDate AND EDate
          WHERE B.CompanySeq = @CompanySeq  
            AND A.EmpSeq <> B.EmpSeq 
            AND A.WorkingTag IN ('A', 'U') 
          UPDATE #DTI_TSLReceiptConsign  
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status    
           FROM #DTI_TSLReceiptConsign  AS A    
                 JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                        AND A.CustSeq    = B.CustSeq  
                                                        AND A.ReceiptDate >= B.SDate
                 LEFT OUTER JOIN _TSLCustChargeEmp AS C ON C.CompanySeq = @CompanySeq
                                                       AND A.CustSeq    = C.CustSeq
                                                       AND C.UMChargeKind = 8013001
                                                       AND A.ReceiptDate BETWEEN C.SDate AND C.EDate
          WHERE A.Status = 0
            AND A.EmpSeq <> B.EmpSeq  
            AND C.CustSeq IS NULL
            AND A.WorkingTag IN ('A', 'U') 
     END  
    */
    IF EXISTS ( SELECT 1 FROM #DTI_TSLReceiptConsign WHERE WorkingTag = 'A' AND Status = 0 ) 
    BEGIN 
        -- Create ReceiptSeq, ReceiptNo 20140211 by sdlee
        SELECT @DataSeq = 1
        SELECT @Count = COUNT(1) FROM #DTI_TSLReceiptConsign
        WHILE (@DataSeq <= @Count)
        BEGIN
            -- ReceiptSeq
            EXEC @ReceiptSeq = _SCOMCreateSeq @CompanySeq, 'DTI_TSLReceiptConsign', 'ReceiptSeq', 1, 'A'
            -- ReceiptNo
            SELECT @BaseDate = ReceiptDate FROM #DTI_TSLReceiptConsign WHERE DataSeq = @DataSeq
            EXEC _SCOMCreateNo 'SL', 'DTI_TSLReceiptConsign', @CompanySeq, '', @BaseDate, @ReceiptNo OUTPUT
            -- Update ReceiptSeq, ReceiptNo
            UPDATE #DTI_TSLReceiptConsign
               SET ReceiptSeq = @ReceiptSeq + 1,
                   ReceiptNo = @ReceiptNo
              FROM #DTI_TSLReceiptConsign
             WHERE DataSeq = @DataSeq
               AND WorkingTag = 'A'
               AND Status = 0
             -- @DataSeq ++
            SELECT @DataSeq = @DataSeq + 1
        END --::WHILE (@DataSeq <= @Count)
    END
  
  /*
    -------------------------------------------  
    -- 가상계좌를 수정/삭제 할 수 없도록 체크
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          18               , --@1는(은) 수정/삭제 할수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and Message LIKE '%수정%삭제%')      
                          @LanguageSeq,
                          2676                 -- SELECT * FROM _TCADictionary WHERE Word like '%가상계좌%'         
    
    UPDATE A 
       SET Result        = @Results     ,      
           MessageType   = @MessageType ,      
           Status        = @Status      
      FROM #DTI_TSLReceiptConsign AS A 
      JOIN DTI_TSLReceiptConsign AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq AND B.IsAuto = 1 ) 
     WHERE A.WorkingTag IN ('U', 'D')
       AND A.Status = 0  
       */
    -------------------------------------------  
    -- 내부코드 0값일시 에러 발생
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1055               , -- 처리작업중 에러가 발생했습니다. 다시 처리하십시요!(SELECT  * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsign                               
       SET Result        = @Results     ,    
           MessageType   = @MessageType ,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsign
     WHERE Status = 0
       AND (ReceiptSeq = 0 OR ReceiptSeq IS NULL)        
    
    SELECT * FROM #DTI_TSLReceiptConsign
    
    RETURN
GO
exec DTI_SSLReceiptConsignCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReceiptNo />
    <SMExpKind>8009001</SMExpKind>
    <SMExpKindName>내수</SMExpKindName>
    <SlipID />
    <ReceiptSeq>0</ReceiptSeq>
    <SlipSeq>0</SlipSeq>
    <ReceiptDate>20140521</ReceiptDate>
    <CustSeq>37606</CustSeq>
    <CustName>(명)새한감정평가법인</CustName>
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1</ExRate>
    <EmpSeq>1834</EmpSeq>
    <EmpName>AB2</EmpName>
    <DeptSeq>1511</DeptSeq>
    <DeptName>부서이력</DeptName>
    <OppAccSeq>22</OppAccSeq>
    <OppAccName>외상매출금</OppAccName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019203