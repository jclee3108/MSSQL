
IF OBJECT_ID('_SEQGWorkOrderReqItemCheckCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqItemCheckCHE
GO 

-- v2015.01.21 
/************************************************************
  ��  �� - ������-�۾���ûItem : üũ(�Ϲ�)
  �ۼ��� - 20110429
  �ۼ��� - �ſ��
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
  
     -- ���� ����Ÿ ��� ����
     CREATE TABLE #_TEQWorkOrderReqItemCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqItemCHE'
     IF @@ERROR <> 0 RETURN
    
 
      ---- ������� üũ  
      -----------------------------    
     SELECT @ProgType     = A.ProgType  
       FROM _TEQWorkOrderReqItemCHE AS A  
       JOIN #_TEQWorkOrderReqItemCHE AS B ON ( A.WOReqSeq = B.WOReqSeq )                           
      WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0
        AND B.WorkingTag IN ('U','D')
        
     IF @ProgType <>  20109001  
       
     BEGIN  
            
         SELECT @Results ='�۾� �������� �����Դϴ�. �������� �Ұ�!'  
           
         UPDATE #_TEQWorkOrderReqItemCHE      
            SET Result        = @Results,       
                MessageType   = 99999,       
                Status        = 99999  
           FROM _TEQWorkOrderReqItemCHE AS A  
           JOIN #_TEQWorkOrderReqItemCHE AS B ON (  A.WOReqSeq = B.WOReqSeq )       
     END
    
    --select * from #_TEQWorkOrderReqItemCHE 
    
    --return 

    
     -- ǰ�� ������ ��Ͽ��� Ȯ�� 
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
  --         SET Result        = 'ǰ���� �Ϸ�� �����Դϴ�. ����/���� �Ұ�!',
  --          MessageType   = 99999,
  --          Status        = 99999
  --  FROM #_TEQWorkOrderReqItemCHE AS A
  -- WHERE Status = 0
  --      AND WorkingTag IN ('D','U')
  --END
      
  IF @WorkingTag = 'C'
     BEGIN  
     
     SELECT @Results ='�ߺ� �� ��û���� �ֽ��ϴ�. �����Ͻðڽ��ϱ�?'
     
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
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
    
     SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqItemCHE WHERE WorkingTag = 'A' AND Status = 0  
     IF @Count > 0  
     BEGIN    
         -- Ű�������ڵ�κ� ����    
         SELECT @Seq = ISNULL((SELECT MAX(A.WOReqSerl)  
                                 FROM _TEQWorkOrderReqItemCHE AS A  
                                WHERE A.CompanySeq = @CompanySeq  
                                  AND A.WOReqSeq  IN (SELECT WOReqSeq
                                                            FROM #_TEQWorkOrderReqItemCHE
                                                           WHERE WOReqSeq = A.WOReqSeq)),0)              
                                                             
          --SELECT @Seq = @Seq + MAX(DivGroupStepSeq)
          --   FROM #_TQIDivGroupActDetailCHE
          -- Temp Talbe �� ������ Ű�� UPDATE  
         UPDATE #_TEQWorkOrderReqItemCHE
            SET WOReqSerl = @Seq +Dataseq,
                ProgType  = 20109001
          WHERE WorkingTag = 'A'  
     
     END            
    
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
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
    <ToolNo>test������</ToolNo>
    <ToolName>test������</ToolName>
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
    <ToolNo>test������ets</ToolNo>
    <ToolName>test������setse</ToolName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <ProgType>0</ProgType>
    <ReqDate>20150127</ReqDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10112,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100146