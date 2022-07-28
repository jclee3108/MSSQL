
IF OBJECT_ID('_SEQGWorkOrderReqItemCheckCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqItemCheckCHE
GO 

-- v2015.01.21 
/************************************************************
  설  명 - 데이터-작업요청Item : 체크(일반)
  작성일 - 20110429
  작성자 - 신용식
 ************************************************************/
 CREATE PROC  [dbo].[_SEQGWorkOrderReqItemCheckCHE]
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS
     DECLARE @Count       INT,
             @Seq         INT,
             @Date        NCHAR(8),
             @MaxNo       NVARCHAR(20),
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250),
             @ProgType    INT
  
     -- 서비스 마스타 등록 생성
     CREATE TABLE #_TEQWorkOrderReqItemCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqItemCHE'
     IF @@ERROR <> 0 RETURN
    
 
      ---- 진행상태 체크  
      -----------------------------    
     SELECT @ProgType     = A.ProgType  
       FROM _TEQWorkOrderReqItemCHE AS A  
       JOIN #_TEQWorkOrderReqItemCHE AS B ON ( A.WOReqSeq = B.WOReqSeq )                           
      WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0
        AND B.WorkingTag IN ('U','D')
        
     IF @ProgType <>  20109001  
       
     BEGIN  
            
         SELECT @Results ='작업 진행중인 정보입니다. 수정삭제 불가!'  
           
         UPDATE #_TEQWorkOrderReqItemCHE      
            SET Result        = @Results,       
                MessageType   = 99999,       
                Status        = 99999  
           FROM _TEQWorkOrderReqItemCHE AS A  
           JOIN #_TEQWorkOrderReqItemCHE AS B ON (  A.WOReqSeq = B.WOReqSeq )       
     END
    
    --select * from #_TEQWorkOrderReqItemCHE 
    
    --return 

    
     -- 품목 마스터 등록여부 확인 
  --   SELECT @Count = COUNT(1)
  --     FROM #_TEQWorkOrderReqItemCHE AS A
  --          JOIN _TDAItemUserDefine AS B WITH (NOLOCK)ON A.SAnalysisSeq       = B.MngValText 
  --                                                   AND B.MngSerl      = 1000007
  --    WHERE B.CompanySeq = @CompanySeq
  --      AND A.Status = 0
  --      AND A.WorkingTag IN ('D','U')
  
  --IF @Count > 0 
     
  --BEGIN
  --   UPDATE #_TEQWorkOrderReqItemCHE
  --         SET Result        = '품목등록 완료된 정보입니다. 수정/삭제 불가!',
  --          MessageType   = 99999,
  --          Status        = 99999
  --  FROM #_TEQWorkOrderReqItemCHE AS A
  -- WHERE Status = 0
  --      AND WorkingTag IN ('D','U')
  --END
      
  IF @WorkingTag = 'C'
     BEGIN  
     
     SELECT @Results ='중복 된 요청건이 있습니다. 저장하시겠습니까?'
     
     UPDATE #_TEQWorkOrderReqItemCHE      
     SET Result        = @Results,       
        MessageType   = 99999,       
        Status        = 99999  
  FROM _TEQWorkOrderReqMasterCHE AS A
   LEFT OUTER JOIN _TEQWorkOrderReqItemCHE AS B ON A.CompanySeq = B.CompanySeq
              AND A.WOReqSeq = B.WOReqSeq
   JOIN #_TEQWorkOrderReqItemCHE AS C ON B.ToolSeq = C.ToolSeq
            
  WHERE A.CompanySeq = @CompanySeq
   AND A.ReqDate >= CONVERT(CHAR(8), DATEADD(DAY, -7, CONVERT(DATETIME, '20111101')), 112)
   
  END
   
   
  -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
    
     SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqItemCHE WHERE WorkingTag = 'A' AND Status = 0  
     IF @Count > 0  
     BEGIN    
         -- 키값생성코드부분 시작    
         SELECT @Seq = ISNULL((SELECT MAX(A.WOReqSerl)  
                                 FROM _TEQWorkOrderReqItemCHE AS A  
                                WHERE A.CompanySeq = @CompanySeq  
                                  AND A.WOReqSeq  IN (SELECT WOReqSeq
                                                            FROM #_TEQWorkOrderReqItemCHE
                                                           WHERE WOReqSeq = A.WOReqSeq)),0)              
                                                             
          --SELECT @Seq = @Seq + MAX(DivGroupStepSeq)
          --   FROM #_TQIDivGroupActDetailCHE
          -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #_TEQWorkOrderReqItemCHE
            SET WOReqSerl = @Seq +Dataseq,
                ProgType  = 20109001
          WHERE WorkingTag = 'A'  
     
     END            
    
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #_TEQWorkOrderReqItemCHE  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #_TEQWorkOrderReqItemCHE AS A   
      JOIN (SELECT S.ToolSeq, S.WorkOperSeq 
              FROM (SELECT A1.ToolSeq, A1.WorkOperSeq  
                      FROM #_TEQWorkOrderReqItemCHE AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ToolSeq, A1.WorkOperSeq  
                      FROM _TEQWorkOrderReqItemCHE AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND A1.WOReqSeq IN ( SELECT TOP 1 WOReqSeq FROM #_TEQWorkOrderReqItemCHE ) 
                       AND NOT EXISTS (SELECT 1 FROM #_TEQWorkOrderReqItemCHE   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND WOReqSeq = A1.WOReqSeq  
                                                 AND WOReqSerl = A1.WOReqSerl 
                                      )  
                   ) AS S  
             GROUP BY S.ToolSeq, S.WorkOperSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ToolSeq = B.ToolSeq AND A.WorkOperSeq = B.WorkOperSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    
     SELECT * FROM #_TEQWorkOrderReqItemCHE
  RETURN
GO 
exec _SEQGWorkOrderReqItemCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WOReqSeq>13</WOReqSeq>
    <WOReqSerl>0</WOReqSerl>
    <AccUnitSeq>112</AccUnitSeq>
    <AccUnitName />
    <ToolSeq>1014</ToolSeq>
    <ToolNo>test설비임</ToolNo>
    <ToolName>test설비임</ToolName>
    <WorkOperSeq>20106001</WorkOperSeq>
    <ProgType>0</ProgType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <ReqDate>20150127</ReqDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WOReqSeq>13</WOReqSeq>
    <WOReqSerl>0</WOReqSerl>
    <AccUnitSeq>112</AccUnitSeq>
    <AccUnitName />
    <ToolSeq>1032</ToolSeq>
    <ToolNo>test설비임ets</ToolNo>
    <ToolName>test설비임setse</ToolName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <ProgType>0</ProgType>
    <ReqDate>20150127</ReqDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10112,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100146