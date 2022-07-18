  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppItemSave') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppItemSave  
GO  
  
-- v2014.12.17  
  
-- OT일괄신청- 품목 저장 by 이재천   
CREATE PROC KPX_SPRWKEmpOTGroupAppItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TPRWKEmpOTGroupAppEmp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPRWKEmpOTGroupAppEmp'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRWKEmpOTGroupAppEmp')    
    
    IF @WorkingTag = 'Del' 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPRWKEmpOTGroupAppEmp'    , -- 테이블명        
                      '#KPX_TPRWKEmpOTGroupAppEmp'    , -- 임시 테이블명        
                      'GroupAppSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    ELSE 
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPRWKEmpOTGroupAppEmp'    , -- 테이블명        
                      '#KPX_TPRWKEmpOTGroupAppEmp'    , -- 임시 테이블명        
                      'GroupAppSeq,EmpSeq,AppSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupAppEmp WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del'
        BEGIN 
            DELETE B   
              FROM #KPX_TPRWKEmpOTGroupAppEmp AS A   
              JOIN KPX_TPRWKEmpOTGroupAppEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
        ELSE 
        BEGIN 
            DELETE B   
              FROM #KPX_TPRWKEmpOTGroupAppEmp AS A   
              JOIN KPX_TPRWKEmpOTGroupAppEmp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq AND B.EmpSeq = A.EmpSeq AND B.AppSeq = A.AppSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 

    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupAppEmp WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPRWKEmpOTGroupAppEmp  
        (   
            CompanySeq, GroupAppSeq, AppSeq, EmpSeq, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.GroupAppSeq, A.AppSeq, A.EmpSeq, @UserSeq, GETDATE() 
          FROM #KPX_TPRWKEmpOTGroupAppEmp AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TPRWKEmpOTGroupAppEmp   
    
    RETURN  
GO 
begin tran 
exec KPX_SPRWKEmpOTGroupAppItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141207</AppDate>
    <AppSeq>1</AppSeq>
    <DeptName>전사</DeptName>
    <DeptSeq>1</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20100111</EmpID>
    <Empname>가나다</Empname>
    <EmpSeq>1883</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>1</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141217</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141217</AppDate>
    <AppSeq>2</AppSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <DTime>0500</DTime>
    <EmpID>jclee1</EmpID>
    <Empname>이재천</Empname>
    <EmpSeq>2028</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason>111</OTReason>
    <Rem>222</Rem>
    <WkDate>20141211</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>1</AppSeq>
    <DeptName>mn부서</DeptName>
    <DeptSeq>1000056</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20108888</EmpID>
    <Empname>강팀장</Empname>
    <EmpSeq>1000077</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141210</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>2</AppSeq>
    <DeptName>HR팀</DeptName>
    <DeptSeq>46</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20091101</EmpID>
    <Empname>강진아</Empname>
    <EmpSeq>1337</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141209</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>2</AppSeq>
    <DeptName>a 개발팀</DeptName>
    <DeptSeq>1000043</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>ipsa</EmpID>
    <Empname>가나다(2014)</Empname>
    <EmpSeq>1000103</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141209</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>2</AppSeq>
    <DeptName>사업개발1팀</DeptName>
    <DeptSeq>1595</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20130409</EmpID>
    <Empname>강희구</Empname>
    <EmpSeq>2047</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141209</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>1</AppSeq>
    <DeptName />
    <DeptSeq>56</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20080126</EmpID>
    <Empname>구내식당</Empname>
    <EmpSeq>305</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141210</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141210</AppDate>
    <AppSeq>3</AppSeq>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <DTime>0000</DTime>
    <EmpID />
    <Empname />
    <EmpSeq>1375</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141216</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>1</AppSeq>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <DTime>0000</DTime>
    <EmpID>20110809</EmpID>
    <Empname>구부영</Empname>
    <EmpSeq>1650</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141209</WkDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AppDate>20141209</AppDate>
    <AppSeq>1</AppSeq>
    <DeptName>인사관리팀</DeptName>
    <DeptSeq>1000077</DeptSeq>
    <DTime>0200</DTime>
    <EmpID>20140601</EmpID>
    <Empname>관리자</Empname>
    <EmpSeq>1000117</EmpSeq>
    <GroupAppSeq>1</GroupAppSeq>
    <IsCfm>0</IsCfm>
    <OTReason />
    <Rem />
    <WkDate>20141216</WkDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026866,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022469
rollback 