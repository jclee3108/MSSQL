
IF OBJECT_ID('_SEQWorkRealResultCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkRealResultCheckCHE
GO 

-- v2015.02.12 
/************************************************************
  설  명 - 데이터-작업실적Item : 실제작업공수체크
  작성일 - 20110516
  작성자 - 신용식
 ************************************************************/
 CREATE PROC dbo._SEQWorkRealResultCheckCHE
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
             @ReqEmpSeq   INT,
             @ProgType    INT
  
     -- 서비스 마스타 등록 생성
     CREATE TABLE #_TEQWorkRealResultCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#_TEQWorkRealResultCHE'
     IF @@ERROR <> 0 RETURN
     
      -----------------------------  
      ---- 진행상태 체크  
      -----------------------------    
     SELECT @ProgType     = A.ProgType  
       FROM _TEQWorkOrderReceiptMasterCHE AS A  
       JOIN #_TEQWorkRealResultCHE AS B ON ( A.ReceiptSeq = B.ReceiptSeq )                           
      WHERE A.CompanySeq = @CompanySeq  
        AND B.Status = 0
        
     IF @ProgType = 20109007 OR @ProgType = 20109008
       
     BEGIN  
            
         SELECT @Results ='완료요청 처리된 정보입니다. 수정삭제 불가!'  
           
         UPDATE #_TEQWorkRealResultCHE      
            SET Result        = @Results,       
                MessageType   = 99999,       
                Status        = 99999  
           FROM _TEQWorkOrderReceiptMasterCHE AS A  
           JOIN #_TEQWorkRealResultCHE AS B ON (  A.ReceiptSeq = B.ReceiptSeq )       
     END
     
  --   -- 품목 마스터 등록여부 확인 
  --   SELECT @Count = COUNT(1)
  --     FROM #_TEQWorkRealResultCHE AS A
  --          JOIN _TDAItemUserDefine AS B WITH (NOLOCK)ON A.ReqSeq       = B.MngValText 
  --                                                   AND B.MngSerl      = 1000007
  --    WHERE B.CompanySeq = @CompanySeq
  --      AND A.Status = 0
  --      AND A.WorkingTag IN ('D','U')
  
  --IF @Count > 0 
     
  --BEGIN
  --   UPDATE #_TEQWorkRealResultCHE
  --         SET Result        = '품목등록 완료된 정보입니다. 수정/삭제 불가!',
  --          MessageType   = 99999,
  --          Status        = 99999
  --  FROM #_TEQWorkRealResultCHE AS A
  -- WHERE Status = 0
  --      AND WorkingTag IN ('D','U')
  --END
  
     -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
    
     SELECT @Count = COUNT(1) FROM #_TEQWorkRealResultCHE WHERE WorkingTag = 'A' AND Status = 0  
     IF @Count > 0  
     BEGIN    
         -- 키값생성코드부분 시작    
         SELECT @Seq = ISNULL((SELECT MAX(A.RelResultSeq)  
                                 FROM _TEQWorkRealResultCHE AS A  
                                WHERE A.CompanySeq = @CompanySeq  
                                  AND A.ReceiptSeq  IN (SELECT ReceiptSeq
                                                            FROM #_TEQWorkRealResultCHE
                                                           WHERE ReceiptSeq = A.ReceiptSeq)
                                  AND A.WOReqSeq  IN (SELECT WOReqSeq
                                                            FROM #_TEQWorkRealResultCHE
                                                           WHERE WOReqSeq = A.WOReqSeq)
                                  AND A.WOReqSerl  IN (SELECT WOReqSerl
                                                            FROM #_TEQWorkRealResultCHE
                                                           WHERE WOReqSerl = A.WOReqSerl)),0)               
                                                             
          --SELECT @Seq = @Seq + MAX(DivGroupStepSeq)
          --   FROM #_TQIDivGroupActDetailCHE
          -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #_TEQWorkRealResultCHE
            SET RelResultSeq =@Seq +Dataseq
          WHERE WorkingTag = 'A'  
     
     END    
      SELECT * FROM #_TEQWorkRealResultCHE
  RETURN