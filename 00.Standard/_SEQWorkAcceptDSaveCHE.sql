
IF OBJECT_ID('_SEQWorkAcceptDSaveCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDSaveCHE
GO 

-- v2015.09.02 

/*********************************************************************************************************************    
     ȭ��� : �۾��������(�Ϲ�) - D����  
     �ۼ��� : 2011.05.03 ���游  
     -- �۾���û ������� �κ��� ���⼭ ����  
 ********************************************************************************************************************/   
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDSaveCHE]      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.    
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
   
  -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
     EXEC _SCOMLog  @CompanySeq,  
                    @UserSeq,  
                    '_TEQWorkOrderReceiptItemCHE',   
                    '#WorkOrder',  
                    'ReceiptSeq,WOReqSeq,WOReqSerl',  
                    'CompanySeq,ReceiptSeq,WOReqSeq,WOReqSerl, WorkOperSeq,  
                     WorkOperSerl,LastDateTime,LastUserSeq'  
  /*************************************************************************************************************************************/  
  -- �����ܿ��� �۾�������� �߰��� ��� ó��  
  IF EXISTS (SELECT * FROM  #WorkOrder WHERE WorkingTag ='A' and WOReqSeq =0)  
   BEGIN   
       
     
       
        
        SELECT @WOReqSeq  = MAX(WOReqSeq)  
          FROM #WorkOrder  
         WHERE WorkingTag = 'A'    
       
         -- Ű�������ڵ�κ� ����      
         SELECT @Seq = ISNULL((SELECT MAX(A.WOReqSerl)    
                                 FROM _TEQWorkOrderReqItemCHE AS A    
                                WHERE A.CompanySeq = @CompanySeq    
                                  AND A.WOReqSeq   = @WOReqSeq),0)                
          
        -- �۾���û�� ���� �ڷḦ ��´�.(�����ܿ��� �߰��Ȱ�)   
         SELECT * INTO #TMP_WorkOrderReq  
           FROM #WorkOrder  
          WHERE WorkingTag ='A' and WOReqSeq = 0  
          
    
         -- Temp Talbe �� ������ Ű�� UPDATE  (WOReqSeq, WOReqSerl) ä��  
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
                 
         -- �۾���û�� �߰��׸� ����        
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
            
  -- �۾����� �� �ڻ�ȭ/Ư�� �ϰ��� ���� �۾�������� '��ȹ����' �ƴѰ�� '�۾���û'  
    SELECT @Pre_ProgType = CASE WHEN B.WorkType IN (1000726001,1000726002) THEN 1000732002  
                                ELSE 1000732001   
                           END  
      FROM #WorkOrder  AS A JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  
                              ON 1 = 1  
                             AND A.WOReqSeq = B.WOReqSeq  
     WHERE 1 = 1  
       AND A.WorkingTag ='D'    
      
                       
                       
        
      -- ���� D�� ������� ����   
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
        
        
        
         -- ���� �̵�ϵ� ������ ��û�ǿ� ���ؼ� ����ó��     
         -- ��������ϸ� �ٸ� ������ϵ� ���� ������ �۾���û����(����--> �����κ��� �ǹǷ�) Ÿ�������� �ִ��� üũ.   
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
   
   
     --  �۾���ûD�� ������� ������Ʈ  
     --  �۾��������� Ÿ ����(������ WOReqSeq, WOReqSerl)�� �ְ����� ����  
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
    
      --  �۾���ûM�� ������� ������Ʈ  
     --  �۾��������� Ÿ ����(������ WOReqSeq, WOReqSerl)�� �ְ����� ����  
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
        -- ���������� ���� ��쿡 ��������ڵ� ���� ���μ��� ��....  
     ---- �������� ���� ���°͵鸸 ��´�.  
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
             
       
      
    --   --  �۾���ûD�� ������� ������Ʈ  
    -- UPDATE _TEQWorkOrderReqItemCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- �������·� ����..   
    --FROM @TMP_Order AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
    --                       ON 1 = 1  
    --                      AND B.CompanySeq = @CompanySeq  
    --                      AND A.WOReqSeq = B.WOReqSeq  
    --                      AND A.WOReqSerl = B.WOReqSerl  
                            
    -- --  �۾���ûM�� ������� ������Ʈ  
    -- UPDATE _TEQWorkOrderReqMasterCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- �������·� ����.. @Rcv_ProgType  
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
      
      
     --  �۾���ûD�� ������� ������Ʈ  
     UPDATE _TEQWorkOrderReqItemCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- �������·� ����..   
    FROM #WorkOrder AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
                ON 1 = 1  
                          AND B.CompanySeq = @CompanySeq  
                          AND A.WOReqSeq = B.WOReqSeq  
                          AND A.WOReqSerl = B.WOReqSerl  
                            
     --  �۾���ûM�� ������� ������Ʈ  
     UPDATE _TEQWorkOrderReqMasterCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- �������·� ����.. @Rcv_ProgType  
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
    <DeptName>�����μ�</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>�Ϲ������۾�</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>��������</WorkContents>
    <WONo>15-G-00013</WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <PdAccUnitName>��ȭ�����</PdAccUnitName>
    <ToolSeq>0</ToolSeq>
    <ToolName />
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <ToolNo />
    <NonCodeToolNo>����������</NonCodeToolNo>
    <WorkOperName>�����ȹ</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150rollback 