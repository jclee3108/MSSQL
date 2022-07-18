  
IF OBJECT_ID('KPX_SQCQAGoodsQualityAssuranceSpecSave') IS NOT NULL   
    DROP PROC KPX_SQCQAGoodsQualityAssuranceSpecSave  
GO  
  
-- v2014.11.20  
  
-- 품목보증규격등록(생산품)-저장 by 이재천   
CREATE PROC KPX_SQCQAGoodsQualityAssuranceSpecSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCQAQualityAssuranceSpec (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCQAQualityAssuranceSpec'   
    IF @@ERROR <> 0 RETURN    
    
    
    DECLARE @IsProd             NCHAR(1), 
            @Cnt                INT, 
            @TableColumns       NVARCHAR(4000), 
            @CustSeq            INT,
            @ItemSeq            INT, 
            @QCType             INT, 
            @TestItemSeq        INT, 
            @QAAnalysisType     INT,
            @SDateMax           NVARCHAR(100), 
            @SMInputType        INT, 
            @LowerLimit         NVARCHAR(100), 
            @UpperLimit         NVARCHAR(100), 
            @QCUnit             INT, 
            @SDate              NCHAR(8), 
            @Remark             NVARCHAR(2000), 
            @TestItemSeqOld     INT, 
            @QAAnalysisTypeOld  INT, 
            @Serl               INT 
    
    
    IF @PgmSeq = 1021430
    BEGIN
        SELECT @IsProd = '1'
    END 
    ELSE 
    BEGIN
        SELECT @IsProd = '0'
    END     
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCQAQualityAssuranceSpec')    
    
    IF @WorkingTag = 'Del' 
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TQCQAQualityAssuranceSpec'    , -- 테이블명        
                      '#KPX_TQCQAQualityAssuranceSpec'    , -- 임시 테이블명        
                      'CustSeq,ItemSeq,QCType'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , 'CustSeqOld,ItemSeqOld,QCTypeOld', @PgmSeq  -- 테이블 모든 필드명   
    
    END 
    ELSE 
    BEGIN
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TQCQAQualityAssuranceSpec'    , -- 테이블명        
                      '#KPX_TQCQAQualityAssuranceSpec'    , -- 임시 테이블명        
                      'Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    END 
    
    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del' -- 삭제 
        BEGIN
            
            DELETE B   
              FROM #KPX_TQCQAQualityAssuranceSpec AS A   
              JOIN KPX_TQCQAQualityAssuranceSpec AS B ON ( B.CompanySeq = @CompanySeq 
                                                       AND B.CustSeq = A.CustSeqOld 
                                                       AND B.ItemSeq = A.ItemSeqOld 
                                                       AND B.QCType = A.QCTypeOld 
                                                       AND B.IsProd = (CASE WHEN @Pgmseq = 1021430 THEN '1' ELSE '0' END) 
                                                         )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 
        ELSE
        BEGIN -- 시트삭제 
            
            SELECT @Cnt = 1 
            
            WHILE( 1 = 1 ) 
            BEGIN 
                SELECT @Serl = Serl
                       
                  FROM #KPX_TQCQAQualityAssuranceSpec
                 WHERE WorkingTag = 'D' 
                   AND DataSeq = @Cnt 
            
                SELECT @CustSeq = CustSeq, 
                       @ItemSeq = ItemSeq, 
                       @QCType = QCType, 
                       @TestItemSeq = TestItemSeq, 
                       @QAAnalysisType = QAAnalysisType, 
                       @SDate = SDate 
                  FROM KPX_TQCQAQualityAssuranceSpec 
                 WHERE Serl = @Serl
                
                --select @ItemSeq , @DVItemPriceSeq
                /** 시작일을 제외한 데이터가 존재하는가? **/  
                IF EXISTS (SELECT 1   
                             FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK)    
                            WHERE A.CompanySeq = @CompanySeq 
                              AND A.CustSeq = @CustSeq 
                              AND A.ItemSeq = @ItemSeq 
                              AND A.QCType = @QCType 
                              AND A.TestItemSeq = @TestItemSeq 
                              AND A.QAAnalysisType = @QAAnalysisType
                              AND A.Serl <> @Serl
                          )  
                BEGIN
                
                    /** 최종 이전데이터의 종료일 수정 **/  
                    SELECT @SDateMax = '' 
                    SELECT @SDateMax = B.SDate   
                      FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK) 
                      OUTER APPLY (SELECT Max(SDate) AS SDate 
                                     FROM KPX_TQCQAQualityAssuranceSpec AS Z 
                                    WHERE Z.CompanySeq = @CompanySeq 
                                      AND Z.CustSeq = A.CustSeq 
                                      AND Z.ItemSeq = A.ItemSeq 
                                      AND Z.QCType = A.QCType
                                      AND Z.TestItemSeq = A.TestItemSeq 
                                      AND Z.QAAnalysisType = A.QAAnalysisType
                                      AND Z.Serl = A.Serl 
                                  ) AS B 
                     WHERE A.CompanySeq = @CompanySeq  
                       AND A.CustSeq = @CustSeq
                       AND A.ItemSeq = @ItemSeq 
                       AND A.QCType = @QCType
                       AND A.TestItemSeq = @TestItemSeq 
                       AND A.QAAnalysisType = @QAAnalysisType
                       AND A.Serl <> @Serl
                    
                    UPDATE A    
                      SET EDate = '99991231'
                    --select * 
                     FROM KPX_TQCQAQualityAssuranceSpec AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.CustSeq = @CustSeq
                           AND A.ItemSeq = @ItemSeq 
                           AND A.QCType = @QCType
                           AND A.TestItemSeq = @TestItemSeq 
                           AND A.QAAnalysisType = @QAAnalysisType
                           AND A.SDate = @SDateMax 
                           AND A.Serl <> @Serl
                    --return 
                    DELETE FROM KPX_TQCQAQualityAssuranceSpec WHERE CompanySeq = @CompanySeq AND Serl = @Serl 
                END 
                ELSE
                BEGIN
                    DELETE FROM KPX_TQCQAQualityAssuranceSpec WHERE CompanySeq = @CompanySeq AND Serl = @Serl 
                END 
                
                IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'D')
                BEGIN 
                    BREAK
                END 
                ELSE
                BEGIN
                    SELECT @Cnt = @Cnt + 1 
                END 
            END 
        END 
    END    
    
    SELECT @Cnt = 1 
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
            
        WHILE( 1 = 1 ) 
        BEGIN 
            SELECT @TestItemSeq = A.TestItemSeq, 
                   @SMInputType = A.SMInputType,  
                   @QAAnalysisType = A.QAAnalysisType, 
                   @LowerLimit = A.LowerLimit,  
                   @UpperLimit = A.UpperLimit,  
                   @QCUnit = A.QCUnit, 
                   @SDate = A.SDate, 
                   @Remark = A.Remark, 
                   @Serl = A.Serl, 
                   @CustSeq = A.CustSeq, 
                   @ItemSeq = A.ItemSeq, 
                   @QCType = QCType
                   
              FROM #KPX_TQCQAQualityAssuranceSpec AS A 
             WHERE WorkingTag = 'U' 
               AND DataSeq = @Cnt 
            
            /** 시작일을 제외한 데이터가 존재하는가? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq 
                          AND A.CustSeq = @CustSeq      
                          AND A.ItemSeq = @ItemSeq      
                          AND A.QCType = @QCType 
                          AND A.TestItemSeq = @TestItemSeq 
                          AND A.QAAnalysistype = @QAAnalysistype
                          AND A.Serl <> @Serl 
                      )
            BEGIN  
                /** 입력된 시작일이 최종이전데이터의 시작일보다 큰가? **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = B.SDate   
                  FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK) 
                  OUTER APPLY (SELECT Max(SDate) AS SDate 
                                 FROM KPX_TQCQAQualityAssuranceSpec AS Z 
                                WHERE Z.CompanySeq = @CompanySeq 
                                  AND Z.CustSeq = A.CustSeq 
                                  AND Z.ItemSeq = A.ItemSeq 
                                  AND Z.QCType = A.QCType
                                  AND Z.TestItemSeq = A.TestItemSeq 
                                  AND Z.QAAnalysistype = A.QAAnalysistype 
                                  AND Z.Serl = A.Serl 
                              ) AS B 
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.CustSeq = @CustSeq      
                   AND A.ItemSeq = @ItemSeq      
                   AND A.QCType = @QCType  
                   AND A.TestItemSeq = @TestItemSeq 
                   AND A.QAAnalysistype = @QAAnalysistype
                   AND A.Serl <> @Serl
                                          

                /** 최종 이전데이터의 종료일 수정 **/  
                UPDATE A    
                  SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112) 
                 FROM KPX_TQCQAQualityAssuranceSpec AS A 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.CustSeq = @CustSeq      
                       AND A.ItemSeq = @ItemSeq      
                       AND A.QCType = @QCType  
                       AND A.TestItemSeq = @TestItemSeq 
                       AND A.QAAnalysistype = @QAAnalysistype
                       AND A.SDate = @SDateMax 
                       AND A.Serl <> @Serl
            END  
            
            UPDATE A 
               SET SMInputType = @SMInputType, 
                   LowerLimit = CASE WHEN @SMInputType = 1018001 THEN REPLACE(@LowerLimit,',','') ELSE @LowerLimit END, 
                   UpperLimit = CASE WHEN @SMInputType = 1018001 THEN REPLACE(@UpperLimit,',','') ELSE @UpperLimit END,  
                   QCUnit = @QCUnit, 
                   SDate = @SDate, 
                   LastUserSeq = @UserSeq, 
                   LastDateTime = GETDATE()
              FROM KPX_TQCQAQualityAssuranceSpec AS A 
              WHERE A.CompanySeq = @CompanySeq 
                AND A.Serl = @Serl 
              
        
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'U')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END 
    END 
    
    
    SELECT @Cnt = 1 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        WHILE( 1 = 1 ) 
        BEGIN 
            
            SELECT @CustSeq         = CustSeq, 
                   @ItemSeq         = ItemSeq, 
                   @QCType          = QCType, 
                   @SDate           = SDate, 
                   @TestItemSeq     = TestItemSeq, 
                   @QAAnalysisType  = QAAnalysisType 
              FROM #KPX_TQCQAQualityAssuranceSpec
             WHERE Status = 0 
               AND WorkingTag = 'A' 
               AND DataSeq = @Cnt 
            
            
            /** 시작일을 제외한 데이터가 존재하는가? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq AND A.CustSeq = @CustSeq AND A.ItemSeq = @ItemSeq AND A.QCType = @QCType AND A.TestItemSeq = @TestItemSeq AND A.QAAnalysisType = @QAAnalysisType
                      )  
            BEGIN  
          
                /** 입력된 시작일이 최종이전데이터의 시작일보다 큰가? **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = A.SDate   
                  FROM KPX_TQCQAQualityAssuranceSpec AS A WITH(NOLOCK)    
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.CustSeq = @CustSeq      
                   AND A.ItemSeq = @ItemSeq      
                   AND A.QCType = @QCType  
                   AND A.TestItemSeq = @TestItemSeq 
                   AND A.QAAnalysistype = @QAAnalysistype
                   AND A.EDate = '99991231'    
                                          
                
                /** 최종 이전데이터의 종료일 수정 **/  
                UPDATE A    
                  SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112)    
                 FROM KPX_TQCQAQualityAssuranceSpec AS A 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.CustSeq = @CustSeq      
                       AND A.ItemSeq = @ItemSeq      
                       AND A.QCType = @QCType  
                       AND A.TestItemSeq = @TestItemSeq 
                       AND A.QAAnalysistype = @QAAnalysistype
                       AND A.SDate = @SDateMax
            END  
            
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQAQualityAssuranceSpec WHERE WorkingTag = 'A')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
            
        END 
        
        
        INSERT INTO KPX_TQCQAQualityAssuranceSpec  
        (   
            CompanySeq,     Serl,           CustSeq,        ItemSeq,        QCType,
            TestItemSeq,    QAAnalysisType, SMInputType,    LowerLimit,     UpperLimit,
            QCUnit,         SDate,          EDate,Remark,   RegEmpSeq,
            RegDateTime,    IsProd,         LastUserSeq,    LastDateTime   
        )   
        SELECT @CompanySeq,     A.Serl,             A.CustSeq,          A.ItemSeq,      CASE WHEN @PgmSeq = 1021430 THEN A.QCType ELSE 0 END,
        
               A.TestItemSeq,   A.QAAnalysisType,   A.SMInputType,      
               CASE WHEN A.SMInputType = 1018001 THEN REPLACE(A.LowerLimit,',','') ELSE A.LowerLimit END,   
               CASE WHEN A.SMInputType = 1018001 THEN REPLACE(A.UpperLimit,',','') ELSE A.UpperLimit END, 
               
               A.QCUnit,        A.SDate,            '99991231',         A.Remark,       
               (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
               
               GETDATE(),       @IsProd,            @UserSeq,           GETDATE()   
          FROM #KPX_TQCQAQualityAssuranceSpec AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    
    UPDATE A
       SET TestItemSeqOld = TestItemSeq, 
           QAAnalysisTypeOld = QAAnalysisType, 
           RegDateTime = CONVERT(NCHAR(8),RegDateTime,112), 
           LastDateTime = CONVERT(NCHAR(8),LastDateTime,112) 
      FROM #KPX_TQCQAQualityAssuranceSpec AS A 
    
    SELECT * FROM #KPX_TQCQAQualityAssuranceSpec   
      
    RETURN  
GO 
begin tran 
exec KPX_SQCQAGoodsQualityAssuranceSpecSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CustSeq>42507</CustSeq>
    <EDate>99991231</EDate>
    <InTestItemName>a</InTestItemName>
    <ItemSeq>27439</ItemSeq>
    <LastDateTime>20141120</LastDateTime>
    <LastUserName>이재천</LastUserName>
    <LastUserSeq>2028</LastUserSeq>
    <LowerLimit />
    <OutTestItemName>a</OutTestItemName>
    <QAAnalysisType>3</QAAnalysisType>
    <QAAnalysisTypeName>test123243</QAAnalysisTypeName>
    <QAAnalysisTypeNo>test123243</QAAnalysisTypeNo>
    <QAAnalysisTypeOld>3</QAAnalysisTypeOld>
    <QCType>3</QCType>
    <QCUnit>2</QCUnit>
    <QCUnitName>검사단위2</QCUnitName>
    <RegDateTime>20141120</RegDateTime>
    <RegEmpName>이재천</RegEmpName>
    <RegEmpSeq>2028</RegEmpSeq>
    <Remark />
    <SDate>20141119        </SDate>
    <SMInputType>0</SMInputType>
    <SMInputTypeName />
    <TestItemName>a</TestItemName>
    <TestItemSeq>2</TestItemSeq>
    <TestItemSeqOld>2</TestItemSeqOld>
    <UpperLimit />
    <Serl>7</Serl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026006,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021430

select * from KPX_TQCQAQualityAssuranceSpec 
rollback 