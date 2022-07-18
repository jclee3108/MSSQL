  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterAmtUploadSave') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterAmtUploadSave  
GO  
  
-- v2015.04.21  
  
-- 주간 평가손익마스터 업로드-저장 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterAmtUploadSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TACEvalProfitItemMasterAmtUpload (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMasterAmtUpload'   
    IF @@ERROR <> 0 RETURN    

    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACEvalProfitItemMasterAmtUpload WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE D         
          FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A   
          LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorName = A.UMHelpComName AND B.MajorSeq = 1010494 )
          LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
          JOIN KPX_TACEvalProfitItemMasterAmtUpload  AS D ON ( D.CompanySeq = CONVERT(INT,C.ValueText) AND D.Seq = A.Seq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        --DECLARE @Cnt            INT, 
        --        @CompanySeqLog  INT
        
        ---- 로그 남기기    
        --DECLARE @TableColumns NVARCHAR(4000)   
        
        --CREATE TABLE #LogTable 
        --(
        --    WorkingTag  NCHAR(1), 
        --    IDX_NO      INT, 
        --    DataSeq     INT, 
        --    Selected    INT, 
        --    MessageType INT, 
        --    Status      INT, 
        --    Seq         INT,
        --    Result      NVARCHAR(100), 
        --    ROW_IDX     INT 
            
            
        --)
        
        --SELECT @Cnt = 1 
        
        --WHILE( 1 = 1 ) 
        --BEGIN 
        
        --    SELECT @CompanySeqLog = CONVERT(INT,C.ValueText)
        --      FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A 
        --      LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorName = A.UMHelpComName AND B.MajorSeq = 1010494 )
        --      LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
        --     WHERE A.DataSeq = @Cnt 
        --       AND A.WorkingTag = 'D' 
            
        --    TRUNCATE TABLE #LogTable 
        --    INSERT INTO #LogTable ( WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Seq, Result, ROW_IDX )  
        --    SELECT WorkingTag, 1, 1, Selected, MessageType, Status, Seq, A.Result, A.ROW_IDX
        --      FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A 
        --     WHERE DataSeq = @Cnt 
        --       AND WorkingTag = 'D' 

              
        --    -- Master 로그   
        --    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACEvalProfitItemMasterAmtUpload')    
  
        --    EXEC _SCOMLog @CompanySeqLog   ,        
        --                  @UserSeq      ,        
        --                  'KPX_TACEvalProfitItemMasterAmtUpload'    , -- 테이블명        
        --                  '#LogTable'    , -- 임시 테이블명        
        --                  'Seq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
        --                  @TableColumns, '', @PgmSeq  -- 테이블 모든 필드명   
            
        --    IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TACEvalProfitItemMasterAmtUpload) 
        --    BEGIN 
        --        BREAK 
        --    END 
        --    ELSE
        --    BEGIN  
        --        SELECT @Cnt = @Cnt + 1 
        --    END 
        --END 

        
        
    
    END    
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TACEvalProfitItemMasterAmtUpload WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        

        DELETE D 
          FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A 
          LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorName = A.UMHelpComName AND B.MajorSeq = 1010494 )
          LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
                     JOIN KPX_TACEvalProfitItemMasterAmtUpload AS D ON ( D.CompanySeq = CONVERT(INT,C.ValueText)
                                                                    AND D.UMHelpComName = A.UMHelpComName 
                                                                    AND D.StdDate = REPLACE(A.StdDate,'-','')
                                                                    AND D.FundCode = A.FundCode 
                                                                      ) 
                                                   
        
        INSERT INTO KPX_TACEvalProfitItemMasterAmtUpload  
        (   
            CompanySeq,Seq,UMHelpComName,StdDate,FundCode,  
            TestAmt,LastUserSeq,LastDateTime   
        )   
        SELECT CONVERT(INT,C.ValueText),A.Seq,A.UMHelpComName,REPLACE(A.StdDate,'-',''),A.FundCode,  
               A.TestAmt,@UserSeq,GETDATE() 
          FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A   
          LEFT OUTER JOIN _TDAUMinor                AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorName = A.UMHelpComName AND B.MajorSeq = 1010494 )
          LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TACEvalProfitItemMasterAmtUpload   
      
    RETURN  
    
    go
    begin tran
    
    
exec KPX_SACEvalProfitItemMasterAmtUploadSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <FundCode>C03-000001</FundCode>
    <Seq>20</Seq>
    <StdDate>2015-04-24</StdDate>
    <TestAmt>999.00000</TestAmt>
    <UMHelpComName>KPXGC</UMHelpComName>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <FundCode>F02-000001</FundCode>
    <Seq>21</Seq>
    <StdDate>2015-04-24</StdDate>
    <TestAmt>999.00000</TestAmt>
    <UMHelpComName>KPXHD</UMHelpComName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1029235,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1024298


--select *from KPX_TACEvalProfitItemMasterAmtUpload 
--select * from KPX_TACEvalProfitItemMasterAmtUploadLog 
rollback 