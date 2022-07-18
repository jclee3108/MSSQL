IF OBJECT_ID('KPXCM_SACBizTripCostRegCheck') IS NOT NULL 
    DROP PROC KPXCM_SACBizTripCostRegCheck
GO 

-- v2015.09.24 

-- 출장상신(체크) by이재천   Save As
/************************************************************  
 설  명 - 데이터-일반증빙상신_kpx : 확인  
 작성일 - 20150811  
 작성자 - 민형준  
************************************************************/  
CREATE PROC KPXCM_SACBizTripCostRegCheck  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
    
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)  
    
    CREATE TABLE #KPXCM_TACBizTripCostReg (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TACBizTripCostReg'  
    
    ---------------------------  
    -- 전표처리 데이터는 수정삭제 불가  
    ---------------------------     
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          5                  , -- 이미 @1가(이) 완료된 @2입니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%이미%')      
                          @LanguageSeq       ,       
                          12,'분개전표처리',   -- SELECT * FROM _TCADictionary WHERE Word like '건'      
                          2529, '건'  
        
    -- 중복여부 Check  
    UPDATE #KPXCM_TACBizTripCostReg   
       SET Status = @Status,      -- 중복된 @1 @2가(이) 입력되었습니다.        
           result = @Results,  
           MessageType = @MessageType       
      FROM #KPXCM_TACBizTripCostReg AS A  
      JOIN KPXCM_TACBizTripCostReg  AS A2 ON A2.CompanySeq = @CompanySeq AND A.Seq = A2.Seq  
      JOIN _TACSlipRow              AS B ON B.CompanySeq = @CompanySeq AND A2.SlipSeq = B.SlipSeq  
     WHERE A.WorkingTag IN ('D', 'U')  
       AND A.Status = 0  
       AND B.SlipSeq <> 0  
    
  
    DECLARE @MaxSeq INT,  
            @Count  INT   
    
    SELECT @Count = Count(1) FROM #KPXCM_TACBizTripCostReg WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count >0   
    BEGIN  
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPXCM_TACBizTripCostReg','Seq',@Count --rowcount    
          
       UPDATE #KPXCM_TACBizTripCostReg               
          SET Seq  = @MaxSeq + DataSeq     
        WHERE WorkingTag = 'A'              
          AND Status = 0   
    END    
    
    SELECT * FROM #KPXCM_TACBizTripCostReg   
    
    RETURN      