IF OBJECT_ID('KPXCM_SPDBOMBatchItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchItemCheck
GO 

-- v2015.09.16 

/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatch  
  DESCRIPTION         -     배합비  
  CREAE DATE          -       2008.05.30      CREATE BY: 김현  
  LAST UPDATE  DATE   -       2008.06.11         UPDATE BY: 김현  
                              2009.09.09         UPDATE BY 송경애  
                            :: 공정, Overage, 평균함량, 조달구분 추가  
                              2011.04.30         UPDATE BY 김일주  
                            :: 정렬순서, 적용시작일, 적용종료일 추가  
         2014.04.09         UPDATE BY 문학문
         신규 중복자재 등록 시 KPXCM_TPDBOMBatchItem 테이블에 데이터가 없어서 체크 못하게 되어,Companyseq를 조인절로 이동
         중복자재 관련 하여 Check 로직 추가 -- 김용현 2014.05.22
 *************************************************************************************************/  
   
 CREATE PROCEDURE KPXCM_SPDBOMBatchItemCheck  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     DECLARE @docHandle   INT,  
             @Serl        INT,  
             @MessageSeq  INT,  
             @MessageType INT,  
             @Status      INT,  
             @Results     NVARCHAR(250),  
             @Results2    NVARCHAR(250) ,
             @EnvValue    NCHAR(1) 
   
     -- BatchItem에 넣을 값을 가져오기 위함  
     CREATE TABLE #KPXCM_TPDBOMBatchItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDBOMBatchItem'  
   
     IF @@ERROR <> 0 RETURN  
     
     --- BOM 자재중복 허용 환경설정 ---
     EXEC dbo._SCOMEnv @CompanySeq,6206,0,@@PROCID,@EnvValue OUTPUT      
       
       
     IF @EnvValue = '0'
     BEGIN  
     -------------------------------------------  
     -- 일자 체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           31                 , -- @1이 @2 보다 커야 합니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%합니%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           232, '종료일'      , -- SELECT * FROM _TCADictionary WHERE Word like '%시작일%'  
                           191, '시작일'  
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem   
      WHERE DateFr     >= DateTo  
        AND Status     = 0  
        AND WorkingTag IN ('A', 'U')   
       
     -- 적용일은 Master의 시작/종료일 사이에 있어야 한다.      
     -------------------------------------------  
     -- 일자 체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results2    OUTPUT,  
                           1293               , -- @1의 @2을(를) 확인하세요.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%확인%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           5477, '반제품'     , -- SELECT * FROM _TCADictionary WHERE Word like '%적용일%'  
                           222, '적용일'  
       
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1106               , -- @1가 잘못되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%습니%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           222, '적용일'        -- SELECT * FROM _TCADictionary WHERE Word like '%시작일%'  
                           
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = @Results + ' ' + @Results2,  
            MessageType   = @MessageType,  
            Status        = @Status  
     FROM #KPXCM_TPDBOMBatchItem  AS A  
            JOIN KPXCM_TPDBOMBatch AS B ON A.BatchSeq = B.BatchSeq  
      WHERE B.CompanySeq = @CompanySeq  
        AND (A.DateFr    < B.DateFr OR A.DateTo > B.DateTo)  
        AND A.Status     = 0  
        AND A.WorkingTag IN ('A', 'U')  
       
     -- 같은 BatchSeq에서 동일자재로 시작일과 종료일이 중복되면 안된다.  
     -------------------------------------------  
     -- 중복된 일자 체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1107               , -- 해당 @1가(이) 기존에 등록된 @2와(과) 중복됩니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%중복%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           222, '적용일'      , -- SELECT * FROM _TCADictionary WHERE Word like '%적용일%'  
                           222, '적용일'  
     UPDATE A  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem                 AS A  
            LEFT OUTER JOIN #KPXCM_TPDBOMBatchItem AS B ON A.BatchSeq   = B.BatchSeq  
                                                 AND A.ItemSeq    = B.ItemSeq  
                                                 AND A.IDX_NO     <> B.IDX_NO  
                                                 AND B.WorkingTag IN ('A', 'U')  
                                                 AND A.ProcSeq    = B.ProcSeq  
            LEFT OUTER JOIN KPXCM_TPDBOMBatchItem AS C ON A.BatchSeq   = C.BatchSeq  
                                                 AND A.ItemSeq    = C.ItemSeq  
                                                 AND A.Serl       <> C.Serl  
                                                 AND A.ProcSeq    = C.ProcSeq  
                                                 AND C.CompanySeq = @CompanySeq
      WHERE A.Status = 0  
        AND A.WorkingTag IN ('A', 'U')  
        --AND C.CompanySeq = @CompanySeq  문학문20140409: 신규 중복자재 등록 시 KPXCM_TPDBOMBatchItem 테이블에 데이터가 없어서 체크 못하게 되어,조인절로 이동
        AND (A.DateFr BETWEEN B.DateFr AND B.DateTo OR A.DateTo BETWEEN B.DateFr AND B.DateTo   
             OR A.DateFr BETWEEN C.DateFr AND C.DateTo OR A.DateTo BETWEEN C.DateFr AND C.DateTo)  
     END  
     -- 동일 반제품으로 동일자재로 시작일과 종료일이 중복되면 안된다.  
     -------------------------------------------  
     -- 중복된 일자 체크  
     -------------------------------------------  
     /*반제품의 적용일도 중복체크를 하고 자재도 반제품의 적용일 안에서만 저장이 되기 때문에 체크를 하지 않아도 될것 같다.*/ -- sypark 20120516  
       
     -- 생산계획으로 진행된 데이터가 존재하면 삭제 불가  
     -------------------------------------------  
     -- 중복된 일자 체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%없습%' AND LanguageSeq = 1)  
                           @LanguageSeq         
                             
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = REPLACE(@Results, '변경,', ''),  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem      AS A  
            JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq    = B.BatchSeq  
      WHERE A.Status     = 0  
        AND A.WorkingTag = 'D'  
        AND B.CompanySeq = @CompanySeq  
        AND NOT EXISTS (SELECT 1 FROM KPXCM_TPDBOMBatchItem WHERE CompanySeq = B.CompanySeq AND BatchSeq = A.BatchSeq AND Serl <> A.Serl)  
           
     -- 내부순번  
     SELECT @Serl = ISNULL((SELECT MAX(A.Serl) FROM KPXCM_TPDBOMBatchItem AS A WITH(NOLOCK)  
                                                    JOIN #KPXCM_TPDBOMBatchItem AS B WITH(NOLOCK) ON A.BatchSeq = B.BatchSeq  
                                              WHERE A.CompanySeq = @CompanySeq), 0)  
   
     UPDATE #KPXCM_TPDBOMBatchItem SET Serl = @Serl+DataSeq  
      WHERE WorkingTag = 'A' AND Status = 0  
          
     SELECT * FROM #KPXCM_TPDBOMBatchItem AS KPXCM_TPDBOMBatchItem  
   
 RETURN  
 /*************************************************************************************************/