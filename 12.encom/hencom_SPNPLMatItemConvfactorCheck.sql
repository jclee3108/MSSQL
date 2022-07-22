  
IF OBJECT_ID('hencom_SPNPLMatItemConvfactorCheck') IS NOT NULL   
    DROP PROC hencom_SPNPLMatItemConvfactorCheck  
GO  
  
-- v2017.06.01
  
-- 사업계획자재단중등록-체크 by 이재천   
CREATE PROC hencom_SPNPLMatItemConvfactorCheck  
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
    
    CREATE TABLE #hencom_TPNPLMatItemConvfactor( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLMatItemConvfactor'   
    IF @@ERROR <> 0 RETURN 
    
    --중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #hencom_TPNPLMatItemConvfactor  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #hencom_TPNPLMatItemConvfactor AS A   
      JOIN (SELECT S.StdYear, DeptSeq, ItemSeq   
              FROM (SELECT A1.StdYear, A1.DeptSeq, A1.ItemSeq   
                      FROM #hencom_TPNPLMatItemConvfactor  AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.StdYear, A1.DeptSeq, A1.ItemSeq   
                      FROM hencom_TPNPLMatItemConvfactor AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #hencom_TPNPLMatItemConvfactor   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND StdYear = A1.StdYear
                                                 AND DeptSeq = A1.DeptSeq 
                                                 AND ItemSeq = A1.ItemSeq
                                      )  
                   ) AS S  
             GROUP BY S.StdYear, DeptSeq, ItemSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.StdYear = B.StdYear AND A.DeptSeq = B.DeptSeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  


    -- 번호+코드 따기 : 
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_TPNPLMatItemConvfactor WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TPNPLMatItemConvfactor', 'CFSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #hencom_TPNPLMatItemConvfactor  
           SET CFSeq = @Seq + DataSeq    
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_TPNPLMatItemConvfactor   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_TPNPLMatItemConvfactor  
     WHERE Status = 0  
       AND ( CFSeq = 0 OR CFSeq IS NULL )  
      
    SELECT * FROM #hencom_TPNPLMatItemConvfactor   
      
    RETURN  
