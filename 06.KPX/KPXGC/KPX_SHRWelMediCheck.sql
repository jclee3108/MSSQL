  
IF OBJECT_ID('KPX_SHRWelMediCheck') IS NOT NULL   
    DROP PROC KPX_SHRWelMediCheck  
GO  
  
-- v2014.12.02  
  
-- 의료비신청-체크 by 이재천   
CREATE PROC KPX_SHRWelMediCheck  
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
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPX_THRWelMedi( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelMedi'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE #KPX_THRWelMedi  
       SET Result       = '이미 동일기간에 등록된 데이터가 있습니다.', 
           MessageType  = 1234,
           Status       = 1234
      FROM #KPX_THRWelMedi AS A   
      JOIN (SELECT S.EmpSeq, S.RegSeq 
              FROM (SELECT A1.EmpSeq, A1.RegSeq 
                      FROM #KPX_THRWelMedi AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.EmpSeq, A1.RegSeq 
                      FROM KPX_THRWelMedi AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_THRWelMedi   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND EmpSeq = A1.EmpSeq 
                                                 AND RegSeq = A1.RegSeq 
                                      )  
                   ) AS S  
             GROUP BY S.EmpSeq, S.RegSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.EmpSeq = B.EmpSeq AND A.RegSeq = B.RegSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_THRWelMedi WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THRWelMedi', 'WelMediSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_THRWelMedi  
           SET WelMediSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    --체크1, 해당 년도의 지원금액을 초과하였습니다. 
    DECLARE @YY         NCHAR(4), 
            @EmpSeq     INT, 
            @WelCodeSeq INT, 
            @RegSeq     INT, 
            @YearLimite DECIMAL(19,5)
    
    IF EXISTS (SELECT 1 FROM #KPX_THRWelMedi WHERE WorkingTag IN ('A','U') AND Status = 0) 
    BEGIN 
        SELECT @YY = A.YY, 
               @EmpSeq = A.EmpSeq, 
               @WelCodeSeq = B.WelCodeSeq, 
               @RegSeq = A.RegSeq 
          FROM #KPX_THRWelMedi          AS A 
          JOIN KPX_THRWelCodeYearItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.RegSeq = A.RegSeq ) 
         WHERE WorkingTag IN ('A','U') 
        
        SELECT @YearLimite = B.YearLimite 
          FROM KPX_THRWelCodeYearItem AS A 
          JOIN KPX_THRWelCode         AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.RegSeq = @RegSeq 
        
        CREATE TABLE #TEMP 
        (
            YearLimite DECIMAL(19,5),  
            ComAmt     DECIMAL(19,5) 
        )
        INSERT INTO #TEMP ( YearLimite, ComAmt ) 
        SELECT MAX(ISNULL(A.YearLimite,0)) AS YearLimite, 
               SUM(ISNULL(ComAmt,0)) AS ComAmt
          FROM ( 
                SELECT @YearLimite AS YearLimite, 
                       SUM(ISNULL(B.ComAmt,0)) AS ComAmt
                  FROM KPX_THRWelCodeYearItem       AS A 
                  LEFT OUTER JOIN KPX_THRWelMedi    AS B ON ( B.CompanySeq = @CompanySeq AND B.YY = A.YY ) 
                 WHERE A.CompanySeq = @CompanySeq
                   AND A.WelCodeSeq = @WelCodeSeq 
                   AND A.RegSeq = @RegSeq 
                   AND A.YY = @YY  
                   AND NOT EXISTS (SELECT 1 FROM #KPX_THRWelMedi WHERE WelMediSeq = B.WelMediSeq)
                
                UNION ALL 
                
                SELECT 0, 
                       A.ComAmt
                  FROM #KPX_THRWelMedi AS A 
              ) AS A 
        
        UPDATE #KPX_THRWelMedi
           SET Result = '해당 년도의 지원금액을 초과하였습니다.', 
               MessageType = 1234, 
               Status = 1234
          FROM #TEMP AS A 
         WHERE A.YearLimite < A.ComAmt 
    END 
    -- 체크1, END 
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A    
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_THRWelMedi AS A 
     WHERE Status = 0  
       AND ( WelMediSeq = 0 OR WelMediSeq IS NULL )  
    
    SELECT * FROM #KPX_THRWelMedi   
    
    RETURN  
GO 
begin tran 

exec KPX_SHRWelMediCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsCfm>0</IsCfm>
    <DeptName />
    <EmpID />
    <SumMediAmt>60000</SumMediAmt>
    <SumNonPayAmt>2</SumNonPayAmt>
    <SumHEmpAmt>59998</SumHEmpAmt>
    <EmpAmt>20000</EmpAmt>
    <ComAmt>49998</ComAmt>
    <WelMediSeq>0</WelMediSeq>
    <YY>2014</YY>
    <RegSeq>3</RegSeq>
    <RegName>2014 3분기 복리후생명</RegName>
    <BaseDate>20141210</BaseDate>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105
rollback 




