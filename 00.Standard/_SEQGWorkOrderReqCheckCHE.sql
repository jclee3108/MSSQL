
IF OBJECT_ID('_SEQGWorkOrderReqCheckCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqCheckCHE
GO 

-- v2014.12.08 

/************************************************************
  ��  �� - ������-�۾���ûMaster : üũ(�Ϲ�)
  �ۼ��� - 20110429
  �ۼ��� - �ſ��
 ************************************************************/
 CREATE PROC  dbo._SEQGWorkOrderReqCheckCHE
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
             --@MIWONO      NCHAR(2),
             @WONUM       INT,
             @ProgType    INT,
             @DeptSeq     INT, 
             @AccUnitSeq  INT
             
      -- ���� ����Ÿ ��� ����      
     CREATE TABLE #_TEQWorkOrderReqMasterCHE (WorkingTag NCHAR(1) NULL)       
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqMasterCHE'      
     IF @@ERROR <> 0 RETURN      
    
      -----------------------------        
      ---- ������� üũ        
      -----------------------------          
     SELECT @ProgType     = A.ProgType        
       FROM _TEQWorkOrderReqMasterCHE AS A        
       JOIN #_TEQWorkOrderReqMasterCHE AS B ON ( A.WOReqSeq = B.WOReqSeq )                                 
      WHERE A.CompanySeq = @CompanySeq        
        AND B.Status = 0      
        AND B.WorkingTag IN ('U','D')      
              
     IF @ProgType <>  20109001        
             
     BEGIN        
                  
         SELECT @Results ='�۾� �������� �����Դϴ�. �������� �Ұ�!'        
                 
         UPDATE #_TEQWorkOrderReqMasterCHE            
            SET Result        = @Results,             
                MessageType   = 99999,             
                Status        = 99999        
           FROM _TEQWorkOrderReqMasterCHE AS A        
           JOIN #_TEQWorkOrderReqMasterCHE AS B ON (  A.WOReqSeq = B.WOReqSeq )             
     END      
           
  --   -- ǰ�� ������ ��Ͽ��� Ȯ��       
  --   SELECT @Count = COUNT(1)      
  --     FROM #_TEQWorkOrderReqMasterCHE AS A      
  --          JOIN _TDAItemUserDefine AS B WITH (NOLOCK)ON A.ReqSeq       = B.MngValText       
  --                                                   AND B.MngSerl      = 1000007      
  --    WHERE B.CompanySeq = @CompanySeq      
  --      AND A.Status = 0      
  --      AND A.WorkingTag IN ('D','U')      
        
  --IF @Count > 0       
           
  --BEGIN      
  --   UPDATE #_TEQWorkOrderReqMasterCHE      
  --         SET Result        = 'ǰ���� �Ϸ�� �����Դϴ�. ����/���� �Ұ�!',      
  --          MessageType   = 99999,      
  --          Status        = 99999      
  --  FROM #_TEQWorkOrderReqMasterCHE AS A      
  -- WHERE Status = 0      
  --      AND WorkingTag IN ('D','U')      
  --END      
       
      -----------------------------        
      ---- �۾���û �μ�üũ        
      -----------------------------        
            
  SELECT @Count = COUNT(1)       
    FROM #_TEQWorkOrderReqMasterCHE AS B      
            JOIN ( SELECT S1.ValueSeq      
                    FROM _TDAUMinorValue AS S1      
                         JOIN _TDAUMinor AS S2 ON S1.CompanySeq = S2.CompanySeq      
                                              AND S1.MinorSeq   = S2.MinorSeq      
                                              AND S1.Serl       = 1000001      
                   WHERE S1.MajorSeq = 20105      
                     AND S1.CompanySeq = @Companyseq) AS S ON B.DeptSeq = S.ValueSeq      
       WHERE B.Status = 0      
         AND B.WorkingTag IN ('A')       
               
     IF @Count = 0       
        
  BEGIN        
                
         UPDATE #_TEQWorkOrderReqMasterCHE 
            SET Result        = '�۾����к� �۾���ȣ�� �������� �ʽ��ϴ�.,W/O ���� �Ұ�!',             
                MessageType   = 99999,             
             Status        = 99999        
           FROM #_TEQWorkOrderReqMasterCHE AS B      
           WHERE B.Status = 0      
             AND B.WorkingTag IN ('A')            
     END      
    
    /*
  -----------------------------        
      ---- �μ��� ���� ����� �Է¿��� üũ        
      -----------------------------          
     SELECT @DeptSeq     = A.DeptSeq ,      
            @AccUnitSeq  = ISNULL(A.AccUnitSeq,0)       
       FROM #_TEQWorkOrderReqMasterCHE AS A                                   
      WHERE A.Status = 0      
        AND A.WorkingTag IN ('A')      
              
     IF @DeptSeq IN (631,596,561,610) AND @AccUnitSeq = 0          
             
     BEGIN        
                
         UPDATE #_TEQWorkOrderReqMasterCHE            
            SET Result        = '���������� �����ϼ���!,W/O ���� �Ұ�!',             
                MessageType   = 99999,             
                Status        = 99999        
           FROM #_TEQWorkOrderReqMasterCHE AS B      
           WHERE B.Status = 0      
             AND B.WorkingTag IN ('A')            
     END      
           
     IF @DeptSeq IN (610) AND @AccUnitSeq = 1          
             
     BEGIN        
                
         UPDATE #_TEQWorkOrderReqMasterCHE            
            SET Result        = '��ƿ��Ƽ���� 1���� ���úҰ�! �ٸ� ���������� �����ϼ���.',             
                MessageType   = 99999,             
                Status        = 99999        
           FROM #_TEQWorkOrderReqMasterCHE AS B      
           WHERE B.Status = 0      
             AND B.WorkingTag IN ('A')            
     END      
    
    */
     --WONO  ����      
    SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'A' AND Status = 0        
    IF @Count > 0      
    BEGIN         
    /*
     SELECT @MIWONO = ISNULL(SUBSTRING(MAX(S.MinorName),1,2),'99')      
          FROM #_TEQWorkOrderReqMasterCHE AS A      
               LEFT OUTER JOIN (SELECT MAX(CASE WHEN S1.Serl = 1000001 then S1.ValueSeq else 0 end) ValueSeq1,      
                                    MAX(CASE WHEN S1.Serl = 1000002 then S1.ValueSeq else 0 end) ValueSeq2,      
                                    MAX(CASE WHEN S1.Serl = 1000003 then S1.ValueSeq else 0 end) ValueSeq3,      
                                       S2.MinorName      
                                  FROM _TDAUMinorValue AS S1      
                                       JOIN _TDAUMinor AS S2 ON S1.CompanySeq = S2.CompanySeq      
                                                            AND S1.MinorSeq   = S2.MinorSeq      
                                 WHERE S1.MajorSeq = 20105      
                                   AND S1.CompanySeq = @CompanySeq      
                                  GROUP BY S2.MinorName) AS S ON A.WorkType   = S.ValueSeq2      
                                                             AND A.DeptSeq    = S.ValueSeq1       
                                                             --AND A.AccUnitSeq = S.ValueSeq3      
                                                             AND (S.ValueSeq3 = 0 OR A.AccUnitSeq = S.ValueSeq3) --�������� ������ �������� ����
         WHERE A.WorkingTag = 'A'        
           AND A.Status = 0       
    */
  /***********************************************************************************************************************************/    
  --WO��ȣ '9999' ���ڸ��� ���� 2012-01-01    
      
        --SELECT @WONUM = ISNULL((SELECT CONVERT(INT,(SUBSTRING(MAX(A.WONo),6,3)))    
        --                         FROM _TEQWorkOrderReqMasterCHE AS A      
        --                        WHERE A.CompanySeq = @CompanySeq      
        --                          AND SUBSTRING(A.WONo,1,5) IN (SUBSTRING(CONVERT(CHAR(4),GETDATE(),112),3,2) + '-' + @MIWONO)),'0')    
            
        --UPDATE #_TEQWorkOrderReqMasterCHE     
        --    SET WONO = SUBSTRING(CONVERT(CHAR(4),GETDATE(),112),3,2) + '-' + @MIWONO + CASE WHEN LEN(CONVERT(NCHAR(3),@WONUM+1)) = 1 THEN '00' + CONVERT(NCHAR(3),@WONUM+1)     
        --                                                                                     WHEN LEN(CONVERT(NCHAR(3),@WONUM+1)) = 2 THEN '0' + CONVERT(NCHAR(3),@WONUM+1)     
        --                                                                                    ELSE CONVERT(NCHAR(3),@WONUM+1) END    
             
        --SELECT @WONUM = ISNULL((SELECT CONVERT(INT,(SUBSTRING(MAX(A.WONo),6,4)))      
        --                         FROM _TEQWorkOrderReqMasterCHE AS A        
        --                        WHERE A.CompanySeq = @CompanySeq        
        --                          AND SUBSTRING(A.WONo,1,5) IN (SUBSTRING(CONVERT(CHAR(4),GETDATE(),112),3,2) + '-' + @MIWONO)),'0')      
        
        
        
        --  WO No ���� ���� : �⵵(2�ڸ�) - �۾�����(�Ϲ� G, �������� T, �ܴ� E) - �Ϸù�ȣ(5) --> ����������ڵ�(20104)�� ��� Initial ���
        DECLARE @Initial    NVARCHAR(10), 
                @MaxWoNo    INT 
        
        
        SELECT @Initial = B.Remark
          FROM #_TEQWorkOrderReqMasterCHE AS A 
          LEFT OUTER JOIN _TDAUMinor      AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.WorkType ) 
         WHERE A.WorkingTag = 'A'        
           AND A.Status = 0      
        
        SELECT @MaxWoNo = MAX(CONVERT(INT,RIGHT(WONo,5)))
          FROM _TEQWorkOrderReqMasterCHE AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WONo LIKE SUBSTRING(CONVERT(CHAR(4),GETDATE(),112),3,2) + '-' + @Initial + '%'
        
        --select @Initial 
    --return 
        
        UPDATE #_TEQWorkOrderReqMasterCHE       
           SET WONO = SUBSTRING(CONVERT(CHAR(4),GETDATE(),112),3,2) + '-' + @Initial + '-' + RIGHT('0000' + CONVERT(NVARCHAR(100),ISNULL(@MaxWoNo,0) + 1),5)
         WHERE WorkingTag = 'A'        
           AND Status = 0        
    

  /***********************************************************************************************************************************/                                                                                               
                                                                                                       
          
    --�ӽ�      
            --AND @PgmSeq = 1005782 -- �۾���û���� ��� �Ϲݸ� �ڵ�ä�� ������ ����ä��      
       
     END       

       
     -------------------------------------------        
     -- INSERT ��ȣ�ο�(�� ������ ó��)        
     -------------------------------------------        
     SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)      
     IF @Count > 0        
     BEGIN          
        -- Ű�������ڵ�κ� ����          
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TEQWorkOrderReqMasterCHE', 'WOReqSeq', @Count        
         -- Temp Talbe �� ������ Ű�� UPDATE        
         UPDATE #_TEQWorkOrderReqMasterCHE       
            SET WOReqSeq = @Seq + DataSeq      
          WHERE WorkingTag = 'A'        
            AND Status = 0        
        
     END        
          
       
     SELECT * FROM #_TEQWorkOrderReqMasterCHE      
       
 RETURN
 GO 
 begin tran 
 exec _SEQGWorkOrderReqCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WOReqSeq>0</WOReqSeq>
    <ReqDate>20150121</ReqDate>
    <DeptSeq>0</DeptSeq>
    <EmpSeq>0</EmpSeq>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150121</ReqCloseDate>
    <WorkContents>test</WorkContents>
    <WONo />
    <AccUnitSeq>112</AccUnitSeq>
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10111,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100146
rollback 