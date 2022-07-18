
IF OBJECT_ID('yw_SPDSFCWorkStartListSheetDel') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartListSheetDel
GO 

-- v2014.02.14 

-- 공정개시현황_YW(시트삭제) by이재천
CREATE PROC dbo.yw_SPDSFCWorkStartListSheetDel
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    CREATE TABLE #YW_TPDSFCWorkStart (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDSFCWorkStart')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPDSFCWorkStart'    , -- 테이블명        
                  '#YW_TPDSFCWorkStart'    , -- 임시 테이블명        
                  'WorkOrderSerl,WorkOrderSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'D' AND Status = 0)  
        BEGIN  
            DELETE B
              FROM #YW_TPDSFCWorkStart  AS A 
              JOIN YW_TPDSFCWorkStart AS B ON ( A.WorkOrderSerl = B.WorkOrderSerl AND A.WorkOrderSeq = B.WorkOrderSeq AND A.Serl = B.Serl AND A.EmpSeq = B.EmpSeq ) 
             WHERE B.CompanySeq = @CompanySeq
               AND A.WorkingTag = 'D' 
               AND A.Status = 0    
            
             IF @@ERROR <> 0  RETURN
        END  
    
    SELECT * FROM #YW_TPDSFCWorkStart 
    
    RETURN    
GO
begin tran 
exec yw_SPDSFCWorkStartListSheetDel @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmpName>김세호</EmpName>
    <EmpSeq>1575</EmpSeq>
    <WorkCenterName>워크센터1_이지은</WorkCenterName>
    <WorkCenterSeq>100374</WorkCenterSeq>
    <WorkDate>20140213</WorkDate>
    <WorkEndTime xml:space="preserve">              </WorkEndTime>
    <WorkOrderNo>2013050700090001</WorkOrderNo>
    <WorkStartTime>20140213 17054</WorkStartTime>
    <WorkOrderSeq>134469</WorkOrderSeq>
    <WorkOrderSerl>134469</WorkOrderSerl>
    <Serl>1</Serl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1017737
rollback 