
IF OBJECT_ID('_SGACompHouseCostMasterCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostMasterCheckCHE
GO 

/************************************************************    
 ��  �� - ������-���÷��׸��������� : üũ    
 �ۼ��� - 2011.03.15    
 �ۼ��� - �����    
************************************************************/    
CREATE PROC _SGACompHouseCostMasterCheckCHE 
 @xmlDocument    NVARCHAR(MAX),      
 @xmlFlags       INT     = 0,      
 @ServiceSeq     INT     = 0,      
 @WorkingTag     NVARCHAR(10)= '',      
 @CompanySeq     INT     = 1,      
 @LanguageSeq    INT     = 1,      
 @UserSeq        INT     = 0,      
 @PgmSeq         INT     = 0      
    
AS       
    
    DECLARE @MessageType INT,    
            @Status   INT,    
            @Results  NVARCHAR(250),    
            @Count          INT,    
            @Seq            INT,    
            @GWStatus       INT    
         
    CREATE TABLE #TGACompHouseCostMaster (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TGACompHouseCostMaster'    
      
    -----------------------------    
    ---- ������,������ üũ    
    -----------------------------      
    UPDATE #TGACompHouseCostMaster    
       SET ApplyToDate = '999912'    
     WHERE ISNULL(ApplyToDate,'') = ''    
     
    
    SELECT @Results ='�����ӽ��������� ��û�ڿ� �α����ڰ� Ʋ���ϴ�.'    
        
    UPDATE #TGACompHouseCostMaster          
       SET Result        = '����������� ������ۿ����� �Ⱓ���� �Է��Ͻʽÿ�.',           
           MessageType   = 99999,           
           Status        = 99999    
     WHERE ApplyFrDate   > ApplyToDate    
       AND Status        = 0    
       AND WorkingTag IN ('A','U')            
    
    -------------------------------    
    ------ �ߺ����� üũ    
    -------------------------------      
    ---- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.    
    
    EXEC dbo._SCOMMessage  @MessageType OUTPUT,      
                           @Status      OUTPUT,      
                           @Results     OUTPUT,      
                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)      
                           @LanguageSeq       ,       
                           0,'�����׸��'        
     UPDATE #TGACompHouseCostMaster      
        SET Result        = REPLACE(@Results,'@2',RTRIM(C.MinorName)+'�� '+RTRIM(D.MinorName)),    
            MessageType   = @MessageType,      
            Status        = @Status    
       FROM #TGACompHouseCostMaster AS A     
            JOIN ( SELECT S.HouseClass, S.CostType    
                     FROM (--TEMP�� ���,������ ����     
                           SELECT A1.HouseClass, A1.CostType    
                             FROM #TGACompHouseCostMaster AS A1      
                            WHERE A1.WorkingTag IN ('A','U')      
                              AND A1.Status = 0    
                           UNION ALL    
                           --TEMP�� ����� ������ ���� ���̺� ����    
                           SELECT A1.HouseClass, A1.CostType    
                             FROM _TGACompHouseCostMaster AS A1 WITH(NOLOCK)    
                                  JOIN #TGACompHouseCostMaster AS A2 ON A1.HouseClass = A2.HouseClass    
                                                                          AND A1.CostType   = A2.CostType    
                            WHERE A1.CompanySeq = @CompanySeq    
                              AND A2.WorkingTag = 'A'    
                              AND A2.Status = 0    
                           UNION ALL    
                           --TEMP�� ����� ������ ���� ���̺� ����    
                           SELECT A2.HouseClass, A2.CostType    
                             FROM _TGACompHouseCostMaster AS A1 WITH(NOLOCK)    
                                  JOIN #TGACompHouseCostMaster AS A2 ON A1.CostSeq    = A2.CostSeq    
                                                                          AND ((A1.HouseClass <> A2.HouseClass)    
        OR (A1.CostType   <> A2.CostType))    
                                  JOIN _TGACompHouseCostMaster AS A3 ON A2.HouseClass = A3.HouseClass    
                                                                         AND A2.CostType   = A3.CostType    
                            WHERE A1.CompanySeq = @CompanySeq    
                              AND A2.WorkingTag = 'U'    
                              AND A2.Status = 0    
                          ) AS S    
                    GROUP BY S.HouseClass, S.CostType    
                    HAVING COUNT(1) > 1    
                 ) AS B ON A.HouseClass = B.HouseClass    
                       AND A.CostType   = B.CostType     
             LEFT OUTER JOIN _TDAUMinor AS C WITH(NOLOCK) ON @CompanySeq   = C.CompanySeq    
                                                         AND A.HouseClass    = C.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON @CompanySeq     = D.CompanySeq    
                                                         AND A.CostType      = D.MinorSeq    
  
  
    -------------------------------------------    
    -- INSERT ��ȣ�ο�(�� ������ ó��)    
    -------------------------------------------    
    SELECT @Count = COUNT(1) FROM #TGACompHouseCostMaster WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
    IF @Count > 0        
    BEGIN        
        -- Ű�������ڵ�κ� ����        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TGACompHouseCostMaster', 'CostSeq', @Count      
        -- Temp Talbe �� ������ Ű�� UPDATE      
        UPDATE #TGACompHouseCostMaster    
           SET CostSeq    = @Seq + DataSeq    
         WHERE WorkingTag = 'A'      
           AND Status = 0    
    END    
        
 SELECT * FROM #TGACompHouseCostMaster    
RETURN        