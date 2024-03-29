
IF OBJECT_ID('_SEQWorkAcceptDSaveCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDSaveCHE
GO 

-- v2015.09.02 

/*********************************************************************************************************************    
     鉢檎誤 : 拙穣羨呪去系(析鋼) - D煽舌  
     拙失析 : 2011.05.03 穿井幻  
     -- 拙穣推短 遭楳淫軒 採歳聖 食奄辞 搭薦  
 ********************************************************************************************************************/   
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDSaveCHE]      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- 辞搾什去系廃依 Seq亜 角嬢紳陥.    
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
   
  -- 稽益砺戚鷺 害奄奄(原走厳 督虞五斗澗 鋼球獣 廃匝稽 左鎧奄)    
     EXEC _SCOMLog  @CompanySeq,  
                    @UserSeq,  
                    '_TEQWorkOrderReceiptItemCHE',   
                    '#WorkOrder',  
                    'ReceiptSeq,WOReqSeq,WOReqSerl',  
                    'CompanySeq,ReceiptSeq,WOReqSeq,WOReqSerl, WorkOperSeq,  
                     WorkOperSerl,LastDateTime,LastUserSeq'  
  /*************************************************************************************************************************************/  
  -- 羨呪舘拭辞 拙穣呪楳引亜 蓄亜吉 井酔 坦軒  
  IF EXISTS (SELECT * FROM  #WorkOrder WHERE WorkingTag ='A' and WOReqSeq =0)  
   BEGIN   
       
     
       
        
        SELECT @WOReqSeq  = MAX(WOReqSeq)  
          FROM #WorkOrder  
         WHERE WorkingTag = 'A'    
       
         -- 徹葵持失坪球採歳 獣拙      
         SELECT @Seq = ISNULL((SELECT MAX(A.WOReqSerl)    
                                 FROM _TEQWorkOrderReqItemCHE AS A    
                                WHERE A.CompanySeq = @CompanySeq    
                                  AND A.WOReqSeq   = @WOReqSeq),0)                
          
        -- 拙穣推短拭 隔聖 切戟研 眼澗陥.(羨呪舘拭辞 蓄亜吉闇)   
         SELECT * INTO #TMP_WorkOrderReq  
           FROM #WorkOrder  
          WHERE WorkingTag ='A' and WOReqSeq = 0  
          
    
         -- Temp Talbe 拭 持失吉 徹葵 UPDATE  (WOReqSeq, WOReqSerl) 辰腰  
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
                 
         -- 拙穣推短拭 蓄亜牌鯉 諮脊        
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
            
  -- 拙穣姥歳 戚 切至鉢/働呪 析井酔澗 戚穿 拙穣遭楳雌殿 '奄塙羨呪' 焼観井酔 '拙穣推短'  
    SELECT @Pre_ProgType = CASE WHEN B.WorkType IN (1000726001,1000726002) THEN 1000732002  
                                ELSE 1000732001   
                           END  
      FROM #WorkOrder  AS A JOIN _TEQWorkOrderReqMasterCHE AS B WITH (NOLOCK)  
                              ON 1 = 1  
                             AND A.WOReqSeq = B.WOReqSeq  
     WHERE 1 = 1  
       AND A.WorkingTag ='D'    
      
                       
                       
        
      -- 羨呪 D拭 遭楳雌殿 痕井   
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
        
        
        
         -- 叔旋 耕去系吉 雌殿税 推短闇拭 企背辞 肢薦坦軒     
         -- 羨呪去系馬檎 陥献 叔旋去系吉 闇戚 赤生檎 拙穣推短楕精(叔旋--> 羨呪稽痕井 鞠糠稽) 展羨呪闇戚 赤澗走 端滴.   
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
   
   
     --  拙穣推短D拭 遭楳雌殿 穣汽戚闘  
     --  拙穣羨呪舘税 展 羨呪(疑析廃 WOReqSeq, WOReqSerl)税 置壱葵生稽 痕井  
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
    
      --  拙穣推短M拭 遭楳雌殿 穣汽戚闘  
     --  拙穣羨呪舘税 展 羨呪(疑析廃 WOReqSeq, WOReqSerl)税 置壱葵生稽 痕井  
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
        -- 奄羨呪闇戚 蒸澗 井酔拭 遭楳雌殿坪球 痕井 覗稽室什 獣....  
     ---- 奄羨呪吉 闇戚 蒸澗依級幻 眼澗陥.  
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
             
       
      
    --   --  拙穣推短D拭 遭楳雌殿 穣汽戚闘  
    -- UPDATE _TEQWorkOrderReqItemCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- 羨呪雌殿稽 沙陥..   
    --FROM @TMP_Order AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
    --                       ON 1 = 1  
    --                      AND B.CompanySeq = @CompanySeq  
    --                      AND A.WOReqSeq = B.WOReqSeq  
    --                      AND A.WOReqSerl = B.WOReqSerl  
                            
    -- --  拙穣推短M拭 遭楳雌殿 穣汽戚闘  
    -- UPDATE _TEQWorkOrderReqMasterCHE  
    --    SET ProgType = 1000732003 --@Rcv_ProgType   -- 羨呪雌殿稽 沙陥.. @Rcv_ProgType  
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
      
      
     --  拙穣推短D拭 遭楳雌殿 穣汽戚闘  
     UPDATE _TEQWorkOrderReqItemCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- 羨呪雌殿稽 沙陥..   
    FROM #WorkOrder AS A JOIN _TEQWorkOrderReqItemCHE AS B WITH (NOLOCK)  
                ON 1 = 1  
                          AND B.CompanySeq = @CompanySeq  
                          AND A.WOReqSeq = B.WOReqSeq  
                          AND A.WOReqSerl = B.WOReqSerl  
                            
     --  拙穣推短M拭 遭楳雌殿 穣汽戚闘  
     UPDATE _TEQWorkOrderReqMasterCHE  
        SET ProgType = A.ProgType --@Rcv_ProgType   -- 羨呪雌殿稽 沙陥.. @Rcv_ProgType  
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
    <DeptName>原製採辞</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>析鋼舛搾拙穣</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>けうけう</WorkContents>
    <WONo>15-G-00013</WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <PdAccUnitName>壱亀鉢紫穣採</PdAccUnitName>
    <ToolSeq>0</ToolSeq>
    <ToolName />
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <ToolNo />
    <NonCodeToolNo>いしぞいし</NonCodeToolNo>
    <WorkOperName>舛搾奄塙</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150rollback 