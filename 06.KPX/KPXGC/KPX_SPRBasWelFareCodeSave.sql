  
IF OBJECT_ID('KPX_SPRBasWelFareCodeSave') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeSave  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-저장 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_THRWelCode (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelCode'   
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #KPX_THRWelCodeYearItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelCodeYearItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelCode')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelCode'    , -- 테이블명        
                  '#KPX_THRWelCode'    , -- 임시 테이블명        
                  'WelCodeSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelCodeYearItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelCodeYearItem'    , -- 테이블명        
                  '#KPX_THRWelCodeYearItem'    , -- 임시 테이블명        
                  'WelCodeSeq,WelCodeSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCode WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_THRWelCode AS A   
          JOIN KPX_THRWelCode AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelCodeYearItem')    
        
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_THRWelCodeYearItem'    , -- 테이블명        
              '#KPX_THRWelCode'    , -- 임시 테이블명        
              'WelCodeSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        
        DELETE B   
          FROM #KPX_THRWelCode AS A   
          JOIN KPX_THRWelCodeYearItem AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCodeYearItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_THRWelCodeYearItem AS A   
          JOIN KPX_THRWelCodeYearItem AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq AND B.WelCodeSerl = A.WelCodeSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCode WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.WelCodeName = A.WelCodeName,  
               B.SMRegType = A.SMRegType,  
               B.YearLimite = A.YearLimite,  
               B.WelFareKind = A.WelFareKind,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_THRWelCode AS A   
          JOIN KPX_THRWelCode AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCodeYearItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.YY = A.YY,
               B.RegName = A.RegName,  
               B.DateFr = A.DateFr,  
               B.DateTo = A.DateTo, 
               B.EmpAmt = A.EmpAmt,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_THRWelCodeYearItem AS A   
          JOIN KPX_THRWelCodeYearItem AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq AND B.WelCodeSerl = A.WelCodeSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCode WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THRWelCode  
        (   
            CompanySeq,WelCodeSeq,WelCodeName,SMRegType,YearLimite,  
            WelFareKind,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.WelCodeSeq,A.WelCodeName,A.SMRegType,A.YearLimite,  
               A.WelFareKind,@UserSeq,GETDATE()   
          FROM #KPX_THRWelCode AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END   
    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelCodeYearItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THRWelCodeYearItem  
        (   
            CompanySeq,WelCodeSeq,WelCodeSerl,YY,RegName,
            RegSeq,DateFr,DateTo,EmpAmt,LastUserSeq,
            LastDateTime  
        )   
        SELECT @CompanySeq,A.WelCodeSeq,A.WelCodeSerl,A.YY,A.RegName,  
               A.RegSeq,A.DateFr,A.DateTo,A.EmpAmt,@UserSeq,
               GETDATE()   
          FROM #KPX_THRWelCodeYearItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_THRWelCode
    
    SELECT * FROM #KPX_THRWelCodeYearItem   
      
    RETURN  
GO 
begin tran 
exec KPX_SPRBasWelFareCodeSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DateFrom>20141211</DateFrom>
    <DateTo>20141214</DateTo>
    <EmpAmt>10000.00000</EmpAmt>
    <RegName>1111</RegName>
    <WelCodeSeq>2</WelCodeSeq>
    <WelCodeSerl>1</WelCodeSerl>
    <YY>2014</YY>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DateFrom>20141215</DateFrom>
    <DateTo>20141231</DateTo>
    <EmpAmt>2000.00000</EmpAmt>
    <RegName>123124</RegName>
    <WelCodeSeq>2</WelCodeSeq>
    <WelCodeSerl>2</WelCodeSerl>
    <YY>2014</YY>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026356,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021406


rollback 