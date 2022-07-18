 
IF OBJECT_ID('KPX_SHREduRstWithCostSave') IS NOT NULL 
    DROP PROC KPX_SHREduRstWithCostSave
GO 

-- v2014.11.19 

-- 교육결과등록(저장) by이재천 
CREATE PROCEDURE KPX_SHREduRstWithCostSave  
    @xmlDocument    NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달  
    @xmlFlags       INT = 0         ,    -- 해당 XML문서의 Type  
    @ServiceSeq     INT = 0         ,    -- 서비스 번호  
    @WorkingTag     NVARCHAR(10)= '',    -- WorkingTag  
    @CompanySeq     INT = 1         ,    -- 회사 번호  
    @LanguageSeq    INT = 1         ,    -- 언어 번호  
    @UserSeq        INT = 0         ,    -- 사용자 번호  
    @PgmSeq         INT = 0              -- 프로그램 번호  
    
AS  
    
    CREATE TABLE #KPX_THREduRstWithCost (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THREduRstWithCost'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THREduRstWithCost')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THREduRstWithCost'    , -- 테이블명        
                  '#KPX_THREduRstWithCost'    , -- 임시 테이블명        
                  'RstSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        
        DELETE B
          FROM #KPX_THREduRstWithCost AS A 
          JOIN KPX_THREduRstWithCost  AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
    
        IF @@ERROR <> 0  RETURN  
    
    END    -- DELETE 끝  
    
    -- UPDATE  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
        
        UPDATE B   
           SET B.IsEI   = A.IsEI,  
               B.SMComplate = A.SMComplate,  
               B.LastUserSeq = @UserSeq,  
               B.LastDateTime = GETDATE() 
                 
          FROM #KPX_THREduRstWithCost AS A   
          JOIN KPX_THREduRstWithCost AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
    END    -- UPDATE 끝  
    
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #KPX_THREduRstWithCost WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        
        INSERT INTO KPX_THREduRstWithCost  
        (   
            CompanySeq, RstSeq, IsEI, SMComplate, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.RstSeq, A.IsEI, SMComplate, @UserSeq, GETDATE() 
          FROM #KPX_THREduRstWithCost AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
  
    END    -- INSERT 끝  

    SELECT * FROM #KPX_THREduRstWithCost    -- Output  
  
    RETURN  
GO 
exec KPX_SHREduRstWithCostSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsEI>1</IsEI>
    <SMComplate>1000273001</SMComplate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsEI>0</IsEI>
    <SMComplate>1000273002</SMComplate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025956,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021800