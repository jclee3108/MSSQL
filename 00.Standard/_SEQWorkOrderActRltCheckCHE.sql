
IF OBJECT_ID('_SEQWorkOrderActRltCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkOrderActRltCheckCHE
GO 

-- v2015.02.12 
/************************************************************
  ��  �� - ������-�۾�����Master : üũ
  �ۼ��� - 20110516
  �ۼ��� - �ſ��
 ************************************************************/
 CREATE PROC  [dbo].[_SEQWorkOrderActRltCheckCHE]
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS
     DECLARE @Count         INT,
             @Seq           INT,
             @Date          NCHAR(8),
             @MaxNo         NVARCHAR(20),
             @MessageType   INT,
             @Status        INT,
             @Results       NVARCHAR(250),
             @ReceiptDate   NCHAR(8),
             @WorkContents  NVARCHAR(3000),
             @ActRltDate    NCHAR(8),
             @CommSeq       INT,
             @WkSubSeq      INT,
             @ProgType      INT
  
     -- ���� ����Ÿ ��� ����
     CREATE TABLE #_TEQWorkOrderReceiptMasterCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReceiptMasterCHE'
     IF @@ERROR <> 0 RETURN
     
     -----------------------------  
      ---- ������� üũ  
      -----------------------------    
     SELECT @ProgType     = A.ProgType  
       FROM _TEQWorkOrderReceiptMasterCHE AS A  
       JOIN #_TEQWorkOrderReceiptMasterCHE AS B ON ( A.ReceiptSeq = B.ReceiptSeq )                           
      WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0
        
     IF @ProgType = 20109007 OR @ProgType = 20109008
       
     BEGIN  
            
         SELECT @Results ='�Ϸ��û ó���� �����Դϴ�. �������� �Ұ�!'  
           
         UPDATE #_TEQWorkOrderReceiptMasterCHE      
            SET Result        = @Results,       
                MessageType   = 99999,       
                Status        = 99999  
           FROM _TEQWorkOrderReceiptMasterCHE AS A  
           JOIN #_TEQWorkOrderReceiptMasterCHE AS B ON (  A.ReceiptSeq = B.ReceiptSeq )       
     END
     
      -----------------------------  
      ---- ���濩�� üũ  
      -----------------------------    
     SELECT @ReceiptDate     = A.ReceiptDate,
            @WorkContents    = A.WorkContents,
            @ActRltDate      = A.ActRltDate,
            @CommSeq         = A.CommSeq,
            @WkSubSeq        = A.WkSubSeq  
       FROM _TEQWorkOrderReceiptMasterCHE AS A  
       JOIN #_TEQWorkOrderReceiptMasterCHE AS B ON ( A.ReceiptSeq = B.ReceiptSeq )                           
      WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0
        AND B.WorkingTag IN ('A','U')
   
     SELECT @Count = COUNT(1)
       FROM #_TEQWorkOrderReceiptMasterCHE AS A
            JOIN _TEQWorkOrderReceiptMasterCHE AS B WITH (NOLOCK)ON A.ReceiptSeq       = B.ReceiptSeq 
      WHERE B.CompanySeq = @CompanySeq
        AND A.Status = 0
        AND A.WorkingTag IN ('A','U')
        AND @ReceiptDate     = A.ReceiptDate
        AND @WorkContents    = A.WorkContents
        AND @ActRltDate      = A.ActRltDate
        AND @CommSeq         = A.CommSeq
        AND @WkSubSeq        = A.WkSubSeq 
        
  IF @Count > 0        
                
  BEGIN
     UPDATE #_TEQWorkOrderReceiptMasterCHE
           SET WorkingTag    = 'A'
    FROM #_TEQWorkOrderReceiptMasterCHE AS A
   WHERE Status = 0
     AND A.WorkingTag IN ('A','U')
  END    
  
     IF @Count = 0        
                
  BEGIN
     UPDATE #_TEQWorkOrderReceiptMasterCHE
           SET WorkingTag    = 'U'
    FROM #_TEQWorkOrderReceiptMasterCHE AS A
   WHERE Status = 0
     AND A.WorkingTag IN ('A','U')
  END   
    
      SELECT * FROM #_TEQWorkOrderReceiptMasterCHE
  RETURN