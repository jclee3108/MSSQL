
IF OBJECT_ID('_SEQWorkAcceptDSaveCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDSaveCHE
GO 

-- v2015.09.02 

/*********************************************************************************************************************    
     화면명 : 작업접수등록(일반) - D저장  
     작성일 : 2011.05.03 전경만  
     -- 작업요청 진행관리 부분을 여기서 통제  
 ********************************************************************************************************************/   
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDSaveCHE]      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE @docHandle      INT,  
             @Count          INT,  
             @Seq            INT,  
             @WOReqSeq       INT  
     CREATE TABLE #WorkOrder (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#WorkOrder'  
     IF @@ERROR <> 0 RETURN  
   
  -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
     EXEC _SCOMLog  @CompanySeq,  
                    @UserSeq,  
                    '_TEQWorkOrderReceiptItemCHE',   
                    '#WorkOrder',  
                    'ReceiptSeq,WOReqSeq,WOReqSerl',  
                    'CompanySeq,ReceiptSeq,WOReqSeq,WOReqSerl, WorkOperSeq,  
                     WorkOperSerl,LastDateTime,LastUserSeq'  
  /*************************************************************************************************************************************/  
  -- 접수단에서 작업수행과가 추가된 경우 처리  
  IF EXISTS (SELECT * FROM  #WorkOrder WHERE WorkingTag ='A' and WOReqSeq =0)  
   BEGIN   
       
     
       
        
        SELECT @WOReqSeq  = MAX(WOReqSeq)  
          FROM #WorkOrder  
         WHERE WorkingTag = 'A'    
       
         -- 키값생성코드부분 시작      
         SELECT @Seq = ISNULL((SELECT MAX(A.WOReqSerl)    
                                 FROM _TEQWorkOrderReqItemCHE AS A    
                                WHERE A.CompanySeq = @CompanySeq    
                                  AND A.WOReqSeq   = @WOReqSeq),0)                
          
        -- 작업요청에 넣을 자료를 담는다.(접수단에서 추가된건)   
         SELECT * INTO #TMP_WorkOrderReq  
           FROM #WorkOrder  
          WHERE WorkingTag ='A' and WOReqSeq = 0  
          
    
         -- Temp Talbe 에 생성된 키값 UPDATE  (WOReqSeq, WOReqSerl) 채번  
         UPDATE #WorkOrder  
            SET  WOReqSeq = @WOReqSeq ,  
                 WOReqSerl = @Seq + Dataseq,  
                 AddType   = 1  
          WHERE 1 = 1  
            AND WorkingTag = 'A'    
            AND WOReqSerl =0  
              
         UPDATE #TMP_WorkOrderReq  
            SET WOReqSeq  = B.WOReqSeq,  
                WOReqSerl = B.WOReqSerl  
           FROM #TMP_WorkOrderReq AS A JOIN  #WorkOrder AS B  
                                        ON A.Dataseq = B.Dataseq  
                 
         -- 작업요청에 추가항목 삽입        
         INSERT INTO _TEQWorkOrderReqItemCHE (  
                                                 CompanySeq,     WOReqSeq,     WOReqSerl,  PdAccUnitSeq,  ToolSeq,  
                                                 WorkOperSeq,    SectionSeq,   ToolNo,     ProgType,      AddType,  
                                                 ModWorkOperSeq, CfmReqEmpseq, CfmReqDate, CfmEmpseq,     CfmDate,  
                                                 LastDateTime,   LastUserSeq  
                                                )  
              SELECT   
                     @CompanySeq, WOReqSeq,   WOReqSerl,     PdAccUnitSeq, ToolSeq,   
                     WorkOperSeq, SectionSeq, NonCodeToolNo, 1000732003,             1,  
                     WorkOperSeq, 0,          '',            0,             '',  
                     GETDATE(),   @UserSeq  
                FROM #TMP_WorkOrderReq         
    
              
              
  END              
    
  /**************************************************************************************************************************************/                     
           
                       
       
     DECLARE @Pre_ProgType INT   
     DECLARE @TMP_Order TABLE (   
                                 WOReqSeq    INT,  
                                 WOReqSerl   INT    
                                )      
            
  -- 작업구분 이 자산화/특수 일경우는 이전 작업진행상태 '기획접수' 아닌경우 '작업요청'  
    SELECT @Pre_ProgType = CASE WHEN B.WorkType IN (1000726001,1000726002) THEN 1000732002  
                                ELSE 1000732001   
                           END  
      FROM #WorkOrder  AS A JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  
                              ON 1 = 1  
                             AND A.WOReqSeq = B.WOReqSeq  
     WHERE 1 = 1  
       AND A.WorkingTag ='D'    
      
                       
                       
        
      -- 접수 D에 진행상태 변경   
      UPDATE #WorkOrder  
         SET ProgType = B.ProgType  
     FROM #WorkOrder AS A JOIN _TEQWorkOrderReceiptMasterCHE AS B WITH (NOLOCK)  
                           ON 1 =1   
                          AND A.ReceiptSeq = B.ReceiptSeq  
                          AND B.CompanySeq = @CompanySeq  
   WHERE 1 = 1  
     AND WorkingTag IN('U','A')                   
   
  --DEL  
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'D' AND Status = 0)  
  BEGIN  
     
   DELETE _TEQWorkOrderReceiptItemCHE  
     FROM #WorkOrder AS A  
       JOIN _TEQWorkOrderReceiptItemCHE AS B ON B.CompanySeq = @CompanySeq  
                AND B.ReceiptSeq = A.ReceiptSeq  
                AND B.WOReqSeq   = A.WOReqSeq  
                AND B.WOReqSerl = A.WOReqSerl  
    WHERE A.WorkingTag = 'D'  
      AND A.Status = 0  
      AND B.CompanySeq = @CompanySeq
        
        
        
         -- 실적 미등록된 상태의 요청건에 대해서 삭제처리     
         -- 접수등록하면 다른 실적등록된 건이 있으면 작업요청쪽은(실적--> 접수로변경 되므로) 타접수건이 있는지 체크.   
   DELETE _TEQWorkOrderReqItemCHE  
     FROM #WorkOrder AS A  
       JOIN _TEQWorkOrderReqItemCHE AS B ON B.CompanySeq = @CompanySeq  
                     AND A.WOReqSeq   = B.WOReqSeq  
                     AND A.WOReqSerl  = B.WOReqSerl  
                     AND A.AddType    = B.AddType  
    WHERE A.WorkingTag = 'D'  
      AND A.Status = 0  
      AND B.CompanySeq = @CompanySeq  
      AND A.AddType    = 1      
      --AND B.ProgType   < 1000732006  
      AND A.WOReqSerl NOT IN (SELECT WOReqSerl  
                                FROM _TEQWorkOrderReceiptItemCHE AS C   
                               WHERE 1 = 1  
                                 AND C.CompanySeq = @CompanySeq  
                                 AND A.WOReqSeq   = C.WOReqSeq  
                                 AND A.WOReqSerl  = C.WOReqSerl  
                                 AND A.ReceiptSeq <> C.ReceiptSeq)     
   
   
     --  작업요청D에 진행상태 업데이트  
     --  작업접수단의 타 접수(동일한 WOReqSeq, WOReqSerl)의 최고값으로 변경  
        UPDATE _TEQWorkOrderReqItemCHE  
           SET ProgType = CASE WHEN C.ProgType >= 1000732006 THEN C.ProgType   
                            --   ELSE @Pre_ProgType  
                               ELSE CASE WHEN ISNULL(D.ProgType,0) = 0 THEN @Pre_ProgType  
                                         ELSE  D.ProgType   
                                    END  
                          END  
          FROM _TEQWorkOrderReqItemCHE AS A WITH (NOLOCK) 
               JOIN ( SELECT  A1.WOReqSeq AS WOReqSeq ,  
                              A1.WOReqSerl AS WOReqSerl,   
                              MAX(B.ProgType) AS  ProgType  
                         FROM #WorkOrder AS A1 
                              JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                               AND A1.WOReqSeq = B.WOReqSeq  
                                                                               AND A1.WOReqSerl = B.WOReqSerl  
                     WHERE 1 = 1  
                           AND A1.WorkingTag = 'D'  
                         GROUP BY A1.WOReqSeq ,A1.WOReqSerl )AS C  ON 1 = 1  
                      AND A.WOReqSeq = C.WOReqSeq       
                                                                  AND A.WOReqSerl = C.WOReqSerl    
               LEFT OUTER JOIN ( SELECT  A2.WOReqSeq AS WOReqSeq ,  
                                         A2.WOReqSerl AS WOReqSerl,   
                                         MAX(C.ProgType) AS  ProgType  
                                   FROM  #WorkOrder AS A2 
                                         JOIN _TEQWorkOrderReceiptItemCHE AS B WITH (NOLOCK)ON B.CompanySeq = @CompanySeq  
                                                                                             AND A2.WOReqSeq = B.WOReqSeq  
                                                                                             AND A2.WOReqSerl = B.WOReqSerl  
                                                                                             AND A2.ReceiptSeq <> B.ReceiptSeq 
                                         JOIN _TEQWorkOrderReceiptMasterCHE AS C WITH (NOLOCK)ON B.CompanySeq = C.CommSeq   
                                                                                             AND B.ReceiptSeq <> C.ReceiptSeq                                                          
                                  WHERE 1 = 1  
                                    AND A2.WorkingTag = 'D'  
                                  GROUP BY A2.WOReqSeq ,A2.WOReqSerl )AS D ON 1 = 1  
                                                                          AND A.WOReqSeq = D.WOReqSeq       
                                                                          AND A.WOReqSerl = D.WOReqSerl   
          WHERE 1 = 1  
            AND A.CompanySeq = @CompanySeq  
    
      --  작업요청M에 진행상태 업데이트  
     --  작업접수단의 타 접수(동일한 WOReqSeq, WOReqSerl)의 최고값으로 변경  
        UPDATE _TEQWorkOrderReqMasterCHE  
           SET ProgType = CASE WHEN C.ProgType >= 1000732006 THEN C.ProgType   
                             --  ELSE @Pre_ProgType  
                               ELSE CASE WHEN ISNULL(D.ProgType,0) = 0 THEN @Pre_ProgType  
                                         ELSE  D.ProgType   
                                    END  
                          END  
       FROM _TEQWorkOrderReqMasterCHE AS A 
            JOIN ( SELECT  A1.WOReqSeq AS WOReqSeq ,  
                           MAX(B.ProgType) AS  ProgType  
                    FROM #WorkOrder AS A1 
                         JOIN _TEQWorkOrderReqItemCHE AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A1.WOReqSeq = B.WOReqSeq  
                                                            AND A1.WOReqSerl = B.WOReqSerl  
                   WHERE 1 = 1  
                     AND A1.WorkingTag = 'D'  
                   GROUP BY A1.WOReqSeq  )AS C ON 1 = 1  
                                              AND A.WOReqSeq = C.WOReqSeq           
            LEFT OUTER JOIN ( SELECT  A2.WOReqSeq AS WOReqSeq ,  
                                      MAX(Isnull(C.ActRltDate,'')) AS   ActRltDate,  
                                      MAX(C.ProgType) AS ProgType  
                                FROM #WorkOrder AS A2 
                                     JOIN _TEQWorkOrderReceiptItemCHE AS B WITH (NOLOCK)ON B.CompanySeq = @CompanySeq  
                                                                                         AND A2.WOReqSeq = B.WOReqSeq  
                                                                                         AND A2.WOReqSerl = B.WOReqSerl  
                                                                                         AND A2.ReceiptSeq <> B.ReceiptSeq      
                                     JOIN _TEQWorkOrderReceiptMasterCHE AS C  WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq  
                                                                                             AND B.ReceiptSeq = C.ReceiptSeq                                              
                               WHERE 1 = 1  
   AND A2.WorkingTag = 'D'  
                               GROUP BY A2.WOReqSeq  )AS D ON 1 = 1  
                                                          AND A.WOReqSeq = D.WOReqSeq    
         WHERE 1 = 1  
           AND A.CompanySeq = @CompanySeq  
  END  
     
    
    
    
  --UPDATE  
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'U' AND Status = 0)  
  BEGIN  
       UPDATE _TEQWorkOrderReceiptItemCHE  
          SET        
              WorkOperSeq = A.WorkOperSeq,  
                    WorkOperSerl =A.WorkOperSerl,  
           LastUserSeq = @UserSeq,  
           LastDateTime = GETDATE()  
         FROM #WorkOrder AS A  
           JOIN _TEQWorkOrderReceiptItemCHE AS B ON B.CompanySeq = @CompanySeq  
                    AND B.ReceiptSeq = A.ReceiptSeq  
                    AND B.WOReqSeq = A.WOReqSeq  
                    AND B.WOReqSerl = A.WOReqSerl  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.WorkingTag = 'U'  
          AND A.Status = 0  
    
        UPDATE B
           SET ToolSeq = A.ToolSeq, 
               ToolNo = A.NonCodeToolNo
          FROM #WorkOrder AS A 
          JOIN _TEQWorkOrderReqItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.WOReqSeq = A.WOReqSeq AND B.WOReqSerl = A.WOReqSerl ) 
    
    END  
    
    
    
  --SAVE  
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'A' AND Status = 0)  
  BEGIN  
    
  /******************************************************************************************************************************************/  
  /******************************************************************************************************************************************/  
        -- 기접수건이 없는 경우에 진행상태코드 변경 프로세스 시....  
     ---- 기접수된 건이 없는것들만 담는다.  
     --INSERT INTO @TMP_Order  
     --     SELECT A.WOReqSeq, WOReqSerl  
     --       FROM #WorkOrder AS A  
     --      WHERE A.WorkingTag = 'A'  
     --        AND A.WOReqSerl NOT IN (SELECT WOReqSerl   
     --                                FROM _TEQWorkOrderReceiptItemCHE AS B WITH (NOLOCK)  
     --                               WHERE 1 = 1  
     --                                 AND B.CompanySeq = @CompanySeq  
     --                                 AND A.WOReqSeq = B.WOReqSeq  
     --                                 AND A.WOReqSerl = B.WOReqSerl )  
             
       
      
    --   --  작업요청D에 진행상태 업데이트  
    -- UPDATE _TEQWorkOrderReqItemCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- 접수상태로 본다..   
    --FROM @TMP_Order AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
    --                       ON 1 = 1  
    --                      AND B.CompanySeq = @CompanySeq  
    --                      AND A.WOReqSeq = B.WOReqSeq  
    --                      AND A.WOReqSerl = B.WOReqSerl  
                            
    -- --  작업요청M에 진행상태 업데이트  
    -- UPDATE _TEQWorkOrderReqMasterCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- 접수상태로 본다.. @Rcv_ProgType  
    --FROM @TMP_Order AS A JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  
    --                       ON 1 = 1  
    --                      AND B.CompanySeq = @CompanySeq  
    --                      AND A.WOReqSeq = B.WOReqSeq  
   
  /******************************************************************************************************************************************/  
  /******************************************************************************************************************************************/  
    
    
   INSERT INTO _TEQWorkOrderReceiptItemCHE  
     SELECT @CompanySeq, ReceiptSeq, WOReqSeq, WOReqSerl, WorkOperSeq,  
                     WorkOperSerl, GETDATE(),  @UserSeq     
       FROM #WorkOrder  
      WHERE WorkingTag = 'A'  
        AND Status = 0  
      
      
     --  작업요청D에 진행상태 업데이트  
     UPDATE _TEQWorkOrderReqItemCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- 접수상태로 본다..   
    FROM #WorkOrder AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
                ON 1 = 1  
                          AND B.CompanySeq = @CompanySeq  
                          AND A.WOReqSeq = B.WOReqSeq  
                          AND A.WOReqSerl = B.WOReqSerl  
                            
     --  작업요청M에 진행상태 업데이트  
     UPDATE _TEQWorkOrderReqMasterCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- 접수상태로 본다.. @Rcv_ProgType  
    FROM #WorkOrder AS A JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  
                           ON 1 = 1  
                          AND B.CompanySeq = @CompanySeq  
                          AND A.WOReqSeq = B.WOReqSeq  
        
      
      
   
     
          
           
  END  
   
  SELECT * FROM #WorkOrder  
 RETURN
 
 go
 begin tran 
exec _SEQWorkAcceptDSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ReceiptSeq>22</ReceiptSeq>
    <WOReqSeq>26</WOReqSeq>
    <WOReqSerl>1</WOReqSerl>
    <ReqDate>20150629</ReqDate>
    <DeptName>마음부서</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>일반정비작업</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>ㅁㄶㅁㄶ</WorkContents>
    <WONo>15-G-00013</WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <PdAccUnitName>고도화사업부</PdAccUnitName>
    <ToolSeq>0</ToolSeq>
    <ToolName />
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <ToolNo />
    <NonCodeToolNo>ㄴㅇㅎㄴㅇ</NonCodeToolNo>
    <WorkOperName>정비기획</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150rollback 