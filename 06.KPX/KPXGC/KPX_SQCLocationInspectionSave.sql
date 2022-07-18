  
IF OBJECT_ID('KPX_SQCLocationInspectionSave') IS NOT NULL   
    DROP PROC KPX_SQCLocationInspectionSave  
GO  
  
-- v2014.12.04  
  
-- 공정검사위치등록-저장 by 이재천   
CREATE PROC KPX_SQCLocationInspectionSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCPlant (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCPlant'   
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #KPX_TQCPlantLocation( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCPlantLocation'   
    IF @@ERROR <> 0 RETURN     
    
    -- 로그 남기기      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCPlant')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'KPX_TQCPlant'    , -- 테이블명          
                  '#KPX_TQCPlant'    , -- 임시 테이블명          
                  'PlantSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
      
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCPlantLocation')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'KPX_TQCPlantLocation'    , -- 테이블명          
                  '#KPX_TQCPlantLocation'    , -- 임시 테이블명          
                  'PlantSeq,LocationSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
      
    -- Delete (SS1)     
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlant WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN      
            
        DELETE B     
          FROM #KPX_TQCPlant AS A     
          JOIN KPX_TQCPlant AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq )     
         WHERE A.WorkingTag = 'D'     
           AND A.Status = 0     
            
        IF @@ERROR <> 0  RETURN    
          
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCPlantLocation')      
          
        EXEC _SCOMLog @CompanySeq   ,          
              @UserSeq      ,          
              'KPX_TQCPlantLocation'    , -- 테이블명          
              '#KPX_TQCPlant'    , -- 임시 테이블명          
              'PlantSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
          
          
        DELETE B     
          FROM #KPX_TQCPlant AS A     
          JOIN KPX_TQCPlantLocation AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq )     
         WHERE A.WorkingTag = 'D'     
           AND A.Status = 0     
        
        IF @@ERROR <> 0  RETURN    
    END 
    -- Delete (SS2)
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantLocation WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN    
        
        DELETE B
          FROM #KPX_TQCPlantLocation AS A 
          JOIN KPX_TQCPlantLocation  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq AND B.LocationSeq = A.LocationSeq ) 
         WHERE A.WorkingTag = 'D'     
           AND A.Status = 0     
        
        IF @@ERROR <> 0  RETURN    
        
    END      
      
    -- UPDATE(SS1) 
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlant WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
            
        UPDATE B     
           SET B.PlantName = A.PlantName,    
               B.LastUserSeq  = @UserSeq,    
               B.LastDateTime = GETDATE()  
          FROM #KPX_TQCPlant AS A     
          JOIN KPX_TQCPlant AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0  RETURN    
            
    END      
    
    -- UPDATE(SS2)
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantLocation WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
            
        UPDATE B     
           SET B.LocationName = A.LocationName,  
               B.Sort = A.Sort,    
               B.Remark = A.Remark,    
               B.IsUse = A.IsUse,   
               B.LastUserSeq  = @UserSeq,    
               B.LastDateTime = GETDATE()  
          FROM #KPX_TQCPlantLocation AS A     
          JOIN KPX_TQCPlantLocation AS B ON ( B.CompanySeq = @CompanySeq AND B.PlantSeq = A.PlantSeq AND B.LocationSeq = A.LocationSeq )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0  RETURN    
            
    END        
    
    -- INSERT(SS1)
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlant WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
            
        INSERT INTO KPX_TQCPlant    
        (     
            CompanySeq,PlantSeq,PlantName,LastUserSeq,LastDateTime  
        )     
        SELECT @CompanySeq,A.PlantSeq,A.PlantName,@UserSeq,GETDATE()     
          FROM #KPX_TQCPlant AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
          
        IF @@ERROR <> 0 RETURN    
            
    END     
    
    -- INSERT(SS2)
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCPlantLocation WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
            
        INSERT INTO KPX_TQCPlantLocation    
        (     
            CompanySeq,PlantSeq,LocationSeq,LocationName,Sort,
            Remark,IsUse,RegEmpSeq,RegDateTime,LastUserSeq,
            LastDateTime 
        )     
        SELECT @CompanySeq,A.PlantSeq,A.LocationSeq,A.LocationName,A.Sort,    
               A.Remark,A.IsUse,(SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),GETDATE(),@UserSeq,  
               GETDATE()     
          FROM #KPX_TQCPlantLocation AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
          
        IF @@ERROR <> 0 RETURN    
            
    END       
    
    ----------------------------------------------------------------------
    -- 처리결과 반영하기 위한 업데이트(SS2) 
    ----------------------------------------------------------------------
    UPDATE A 
       SET RegDateTime = CONVERT(NCHAR(8),B.RegDateTime,112), 
           RegEmpSeq = B.RegEmpSeq, 
           RegEmpName = C.EmpName, 
           LastDateTime = CASE WHEN B.RegDateTime = B.LastDateTime THEN '' ELSE CONVERT(NCHAR(8),B.LastDateTime,112) END, 
           LastUserSeq = CASE WHEN B.RegDateTime = B.LastDateTime THEN 0 ELSE D.EmpSeq END, 
           LastUserName = CASE WHEN B.RegDateTime = B.LastDateTime THEN '' ELSE E.EmpName END 
      FROM #KPX_TQCPlantLocation AS A 
      JOIN KPX_TQCPlantLocation  AS B ON ( B.CompanySeq = @CompanySeq AND A.PlantSeq = B.PlantSeq AND A.LocationSeq = B.LocationSeq ) 
      LEFT OUTER JOIN _TDAEmp    AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.RegEmpSeq ) 
      LEFT OUTER JOIN _TCAUser   AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = B.LastUserSeq ) 
      LEFT OUTER JOIN _TDAEmp    AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = D.EmpSeq ) 
    
    SELECT * FROM #KPX_TQCPlant   
    
    SELECT * FROM #KPX_TQCPlantLocation 
    
    RETURN  
    GO 
    begin tran 
exec KPX_SQCLocationInspectionSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <IsUse>1</IsUse>
    <LastDateTime>20141204</LastDateTime>
    <LastUserName>이재천</LastUserName>
    <LastUserSeq>2028</LastUserSeq>
    <LocationName>233</LocationName>
    <LocationSeq>6</LocationSeq>
    <PlantSeq>9</PlantSeq>
    <RegDateTime>20141204</RegDateTime>
    <RegEmpName>이재천</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <Remark>24</Remark>
    <Sort>424</Sort>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026462,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022168
--select * From KPX_TQCPlantLocation 
--select * From KPX_TQCPlantLocationLog
rollback 