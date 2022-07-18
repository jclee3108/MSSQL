  
IF OBJECT_ID('KPX_SHRWelMediEmpSave') IS NOT NULL   
    DROP PROC KPX_SHRWelMediEmpSave  
GO  
  
-- v2014.12.03  
  
-- 의료비내역등록-저장 by 이재천   
CREATE PROC KPX_SHRWelMediEmpSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_THRWelMediEmp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelMediEmp'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelMediEmp')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelMediEmp'    , -- 테이블명        
                  '#KPX_THRWelMediEmp'    , -- 임시 테이블명        
                  'WelMediEmpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediEmp WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_THRWelMediEmp AS A   
          JOIN KPX_THRWelMediEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.WelMediEmpSeq = A.WelMediEmpSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediEmp WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.YY = A.YY,  
               B.BaseDate = A.BaseDate,  
               B.EmpSeq = A.EmpSeq,  
               B.CompanyAmt = A.CompanyAmt,  
               B.ItemSeq = A.ItemSeq,  
               B.PbYM = A.PbYM,  
               B.PbSeq = A.PbSeq,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
                 
          FROM #KPX_THRWelMediEmp AS A   
          JOIN KPX_THRWelMediEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.WelMediEmpSeq = A.WelMediEmpSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediEmp WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THRWelMediEmp  
        (   
            CompanySeq,WelMediEmpSeq,YY,RegSeq,BaseDate,  
            EmpSeq,CompanyAmt,ItemSeq,PbYM,PbSeq,  
            WelMediSeq,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.WelMediEmpSeq,A.YY,0,A.BaseDate,  
               A.EmpSeq,A.CompanyAmt,A.ItemSeq,A.PbYM,A.PbSeq,  
               0,@UserSeq,GETDATE()   
            FROM #KPX_THRWelMediEmp AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END 
    
    SELECT * FROM #KPX_THRWelMediEmp   
    
    RETURN  
    GO 
exec KPX_SHRWelMediEmpSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseDate>20141211</BaseDate>
    <CompanyAmt>123.00000</CompanyAmt>
    <EmpSeq>2028</EmpSeq>
    <ItemSeq>5</ItemSeq>
    <PbSeq>2</PbSeq>
    <PbYM>201411</PbYM>
    <YY>2014</YY>
    <WelMediEmpSeq>1</WelMediEmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BaseDate>20141213</BaseDate>
    <CompanyAmt>1234.00000</CompanyAmt>
    <EmpSeq>2017</EmpSeq>
    <ItemSeq>5</ItemSeq>
    <PbSeq>5</PbSeq>
    <PbYM>201412</PbYM>
    <YY>2014</YY>
    <WelMediEmpSeq>2</WelMediEmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026443,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022141