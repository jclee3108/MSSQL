  
IF OBJECT_ID('KPX_SQCQAGoodsSpecSave') IS NOT NULL   
    DROP PROC KPX_SQCQAGoodsSpecSave  
GO  
  
-- v2014.11.20  
  
-- 품목검사규격등록(생산품)-저장 by 이재천   
CREATE PROC KPX_SQCQAGoodsSpecSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TQCQASpec (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCQASpec'   
    IF @@ERROR <> 0 RETURN    
    
    --select *from #KPX_TQCQASpec 
    
    --return 
    
    DECLARE @IsProd             NCHAR(1), 
            @Cnt                INT, 
            @TableColumns       NVARCHAR(4000), 
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
    
    
    IF @PgmSeq = 1021431
    BEGIN
        SELECT @IsProd = '1'
    END 
    ELSE 
    BEGIN
        SELECT @IsProd = '0'
    END     
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCQASpec')    
    
    IF @WorkingTag = 'Del' 
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TQCQASpec'    , -- 테이블명        
                      '#KPX_TQCQASpec'    , -- 임시 테이블명        
                      'ItemSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , 'ItemSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    END 
    ELSE 
    BEGIN
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TQCQASpec'    , -- 테이블명        
                      '#KPX_TQCQASpec'    , -- 임시 테이블명        
                      'Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    END 
    
    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQASpec WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del' -- 삭제 
        BEGIN
            
            DELETE B   
              FROM #KPX_TQCQASpec AS A   
              JOIN KPX_TQCQASpec AS B ON ( B.CompanySeq = @CompanySeq 
                                       AND B.ItemSeq = A.ItemSeqOld 
                                       AND B.IsProd = (CASE WHEN @Pgmseq = 1021431 THEN '1' ELSE '0' END) 
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
                       
                  FROM #KPX_TQCQASpec
                 WHERE WorkingTag = 'D' 
                   AND DataSeq = @Cnt 
            
                SELECT @ItemSeq = ItemSeq, 
                       @QCType = QCType, 
                       @TestItemSeq = TestItemSeq, 
                       @QAAnalysisType = QAAnalysisType, 
                       @SDate = SDate 
                  FROM KPX_TQCQASpec 
                 WHERE Serl = @Serl
                
                --select @ItemSeq , @DVItemPriceSeq
                /** 시작일을 제외한 데이터가 존재하는가? **/  
                IF EXISTS (SELECT 1   
                             FROM KPX_TQCQASpec AS A WITH(NOLOCK)    
                            WHERE A.CompanySeq = @CompanySeq 
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
                      FROM KPX_TQCQASpec AS A WITH(NOLOCK) 
                      OUTER APPLY (SELECT Max(SDate) AS SDate 
                                     FROM KPX_TQCQASpec AS Z 
                                    WHERE Z.CompanySeq = @CompanySeq 
                                      AND Z.ItemSeq = A.ItemSeq 
                                      AND Z.QCType = A.QCType
                                      AND Z.TestItemSeq = A.TestItemSeq 
                                      AND Z.QAAnalysisType = A.QAAnalysisType
                                      AND Z.Serl = A.Serl 
                                  ) AS B 
                     WHERE A.CompanySeq = @CompanySeq  
                       AND A.ItemSeq = @ItemSeq 
                       AND A.QCType = @QCType
                       AND A.TestItemSeq = @TestItemSeq 
                       AND A.QAAnalysisType = @QAAnalysisType
                       AND A.Serl <> @Serl
                    
                    UPDATE A    
                      SET EDate = '99991231'
                    --select * 
                     FROM KPX_TQCQASpec AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.ItemSeq = @ItemSeq 
                           AND A.QCType = @QCType
                           AND A.TestItemSeq = @TestItemSeq 
                           AND A.QAAnalysisType = @QAAnalysisType
                           AND A.SDate = @SDateMax 
                           AND A.Serl <> @Serl
                    --return 
                    DELETE FROM KPX_TQCQASpec WHERE CompanySeq = @CompanySeq AND Serl = @Serl 
                END 
                ELSE
                BEGIN
                    DELETE FROM KPX_TQCQASpec WHERE CompanySeq = @CompanySeq AND Serl = @Serl 
                END 
                
                IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQASpec WHERE WorkingTag = 'D')
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
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQASpec WHERE WorkingTag = 'U' AND Status = 0 )    
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
                   @ItemSeq = A.ItemSeq, 
                   @QCType = QCType
                   
              FROM #KPX_TQCQASpec AS A 
             WHERE WorkingTag = 'U' 
               AND DataSeq = @Cnt 
            
            /** 시작일을 제외한 데이터가 존재하는가? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TQCQASpec AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq 
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
                  FROM KPX_TQCQASpec AS A WITH(NOLOCK) 
                  OUTER APPLY (SELECT Max(SDate) AS SDate 
                                 FROM KPX_TQCQASpec AS Z 
                                WHERE Z.CompanySeq = @CompanySeq 
                                  AND Z.ItemSeq = A.ItemSeq 
                                  AND Z.QCType = A.QCType
                                  AND Z.TestItemSeq = A.TestItemSeq 
                                  AND Z.QAAnalysistype = A.QAAnalysistype 
                                  AND Z.Serl = A.Serl 
                              ) AS B 
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.ItemSeq = @ItemSeq      
                   AND A.QCType = @QCType  
                   AND A.TestItemSeq = @TestItemSeq 
                   AND A.QAAnalysistype = @QAAnalysistype
                   AND A.Serl <> @Serl
                                          

                /** 최종 이전데이터의 종료일 수정 **/  
                UPDATE A    
                  SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112) 
                 FROM KPX_TQCQASpec AS A 
                     WHERE A.CompanySeq = @CompanySeq 
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
                   QCType = @QCType, 
                   LastUserSeq = @UserSeq, 
                   LastDateTime = GETDATE()
              FROM KPX_TQCQASpec AS A 
              WHERE A.CompanySeq = @CompanySeq 
                AND A.Serl = @Serl 
              
        
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQASpec WHERE WorkingTag = 'U')
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
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TQCQASpec WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        WHILE( 1 = 1 ) 
        BEGIN 
            
            SELECT @ItemSeq         = ItemSeq, 
                   @QCType          = QCType, 
                   @SDate           = SDate, 
                   @TestItemSeq     = TestItemSeq, 
                   @QAAnalysisType  = QAAnalysisType 
              FROM #KPX_TQCQASpec
             WHERE Status = 0 
               AND WorkingTag = 'A' 
               AND DataSeq = @Cnt 
            
            
            /** 시작일을 제외한 데이터가 존재하는가? **/  
            IF EXISTS (SELECT 1   
                         FROM KPX_TQCQASpec AS A WITH(NOLOCK)    
                        WHERE A.CompanySeq = @CompanySeq AND A.ItemSeq = @ItemSeq AND A.QCType = @QCType AND A.TestItemSeq = @TestItemSeq AND A.QAAnalysisType = @QAAnalysisType
                      )  
            BEGIN  
          
                /** 입력된 시작일이 최종이전데이터의 시작일보다 큰가? **/  
                SELECT @SDateMax = '' 
                SELECT @SDateMax = A.SDate   
                  FROM KPX_TQCQASpec AS A WITH(NOLOCK)    
                 WHERE A.CompanySeq = @CompanySeq  
                   AND A.ItemSeq = @ItemSeq      
                   AND A.QCType = @QCType  
                   AND A.TestItemSeq = @TestItemSeq 
                   AND A.QAAnalysistype = @QAAnalysistype
                   AND A.EDate = '99991231'    
                                          
                
                /** 최종 이전데이터의 종료일 수정 **/  
                UPDATE A    
                  SET EDate = CONVERT(CHAR(8), DATEADD(Day, -1, @SDate), 112)    
                 FROM KPX_TQCQASpec AS A 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.ItemSeq = @ItemSeq      
                       AND A.QCType = @QCType  
                       AND A.TestItemSeq = @TestItemSeq 
                       AND A.QAAnalysistype = @QAAnalysistype
                       AND A.SDate = @SDateMax
            END  
            
            IF @Cnt = (SELECT MAX(DataSeq) FROM #KPX_TQCQASpec WHERE WorkingTag = 'A')
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
            
        END 
        
        
        INSERT INTO KPX_TQCQASpec  
        (   
            CompanySeq,     Serl,           ItemSeq,        QCType,
            TestItemSeq,    QAAnalysisType, SMInputType,    LowerLimit,     UpperLimit,
            QCUnit,         SDate,          EDate,Remark,   RegEmpSeq,
            RegDateTime,    IsProd,         LastUserSeq,    LastDateTime   
        )   
        SELECT @CompanySeq,     A.Serl,             A.ItemSeq,      CASE WHEN @PgmSeq = 1021431 THEN A.QCType ELSE 0 END,
        
               A.TestItemSeq,   A.QAAnalysisType,   A.SMInputType,  
               CASE WHEN A.SMInputType = 1018001 THEN REPLACE(A.LowerLimit,',','') ELSE A.LowerLimit END,   
               CASE WHEN A.SMInputType = 1018001 THEN REPLACE(A.UpperLimit,',','') ELSE A.UpperLimit END, 
               
               A.QCUnit,        A.SDate,            '99991231',         A.Remark,       
               (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
               
               GETDATE(),       @IsProd,            @UserSeq,           GETDATE()   
          FROM #KPX_TQCQASpec AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    
    UPDATE A
       SET TestItemSeqOld = TestItemSeq, 
           QAAnalysisTypeOld = QAAnalysisType, 
           QCTypeOld = QCType, 
           RegDateTime = CONVERT(NCHAR(8),RegDateTime,112), 
           LastDateTime = CONVERT(NCHAR(8),LastDateTime,112) 
      FROM #KPX_TQCQASpec AS A 
    
    SELECT * FROM #KPX_TQCQASpec   
      
    RETURN  
GO 
begin tran
exec KPX_SQCQAGoodsSpecSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EDate xml:space="preserve">        </EDate>
    <InTestItemName>1r1</InTestItemName>
    <ItemSeq>27255</ItemSeq>
    <LastDateTime xml:space="preserve">        </LastDateTime>
    <LastUserName />
    <LastUserSeq>0</LastUserSeq>
    <LowerLimit>123</LowerLimit>
    <OutTestItemName>1</OutTestItemName>
    <QAAnalysisType>3</QAAnalysisType>
    <QAAnalysisTypeName>test123243</QAAnalysisTypeName>
    <QAAnalysisTypeNo>test123243</QAAnalysisTypeNo>
    <QAAnalysisTypeOld>0</QAAnalysisTypeOld>
    <QCType>3</QCType>
    <QCTypeName>1</QCTypeName>
    <QCUnit>2</QCUnit>
    <QCUnitName>검사단위2</QCUnitName>
    <RegDateTime xml:space="preserve">        </RegDateTime>
    <RegEmpName />
    <RegEmpSeq>0</RegEmpSeq>
    <Remark />
    <SDate>20141111        </SDate>
    <SMInputType>1018002</SMInputType>
    <SMInputTypeName>문자</SMInputTypeName>
    <TestItemName>as</TestItemName>
    <TestItemSeq>3</TestItemSeq>
    <TestItemSeqOld>0</TestItemSeqOld>
    <UpperLimit>123</UpperLimit>
    <Serl>3</Serl>
    <ItemSeqOld>0</ItemSeqOld>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021431

select * from KPX_TQCQASpec 

rollback 