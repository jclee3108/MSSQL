IF OBJECT_ID('KPXCM_SLGInOutDailyBatch_MES') IS NOT NULL    
    DROP PROC KPXCM_SLGInOutDailyBatch_MES
GO 

-- v2015.09.23 KPXCM MES 용


-- v2012.09.20   
   
 /*    
 CREATE TABLE _TLGInOutDaily    
 (    
     CompanySeq  INT   NOT NULL,     
     InOutSeq  INT   NOT NULL,     
     BizUnit  INT   NOT NULL,     
     InOutNo  NCHAR(12)   NOT NULL,     
     FactUnit  INT   NOT NULL,     
     ReqBizUnit  INT   NOT NULL,     
     DeptSeq  INT   NOT NULL,     
     EmpSeq  INT   NOT NULL,     
     InOutDate  NCHAR(8)   NOT NULL,     
     WCSeq  INT   NOT NULL,     
     ProcSeq  INT   NOT NULL,     
     CustSeq  INT   NOT NULL,     
     OutWHSeq  INT   NOT NULL,     
     InWHSeq  INT   NOT NULL,     
     DVPlaceSeq  INT   NOT NULL,     
     IsTrans  NCHAR(1)   NOT NULL,     
     IsCompleted  NCHAR(1)   NOT NULL,     
     CompleteDeptSeq  INT   NOT NULL,     
     CompleteEmpSeq  INT   NOT NULL,     
     CompleteDate  NCHAR(8)   NOT NULL,     
     InOutType  INT   NOT NULL,     
     InOutDetailType  INT   NOT NULL,     
     Remark  NVARCHAR(200)   NOT NULL,     
     Memo  NVARCHAR(200)   NOT NULL,     
     LastUserSeq  INT   NULL,     
     LastDateTime  DATETIME   NULL    
 )    
     
 */    
 /*************************************************************************************************        
  설  명 - 입출고Master 저장        
  작성일 - 2008.10 : CREATED BY 정수환        
     
 exec _SLGInOutDailyBatch @xmlDocument=N'<ROOT><DataBlock1 WorkingTag="A" IDX_NO="1" Status="0" DataSeq="1" Selected="1" TABLE_NAME="DataBlock1" Result="" InOutSeq="122992" InOutNo="200811110004" BizUnit="1" InOutType="121"     
 InOutDate="20081111" DeptSeq="54" EmpSeq="245"> </DataBlock1></ROOT>',@xmlFlags=0,@ServiceSeq=2619,@WorkingTag=N'U',@CompanySeq=8,@LanguageSeq=1,@UserSeq=674,@PgmSeq=1378    
 *************************************************************************************************/        
 CREATE PROC KPXCM_SLGInOutDailyBatch_MES
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
         
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
 AS        
     DECLARE @docHandle        INT      
       
     -- 서비스 마스타 등록 생성        
     CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)        
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDailyBatch'        
      CREATE TABLE #TLGInOutMonth    
     (      
         InOut           INT,    
         InOutYM         NCHAR(6),    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT,    
         UnitSeq         INT,    
         Qty             DECIMAL(19, 5),    
         StdQty          DECIMAL(19, 5),    
         ADD_DEL         INT    
     )    
   
     CREATE TABLE #TLGInOutMinusCheck    
     (      
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT  
     )    
   
     CREATE TABLE #TLGInOutMonthLot  
     (      
         InOut           INT,    
         InOutYM         NCHAR(6),    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         LotNo           NVARCHAR(30),  
         ItemSeq         INT,    
         UnitSeq         INT,    
         Qty             DECIMAL(19, 5),    
         StdQty          DECIMAL(19, 5),    
         ADD_DEL         INT    
     )    
   
     SELECT @WorkingTag = WorkingTag FROM #TLGInOutDailyBatch    
         
     IF  @WorkingTag In ('D', 'U')    
     BEGIN    
         EXEC _SLGInOutDailyDELETE @CompanySeq    
     END    
   
     IF  @WorkingTag In ('U', 'A')    
     BEGIN    
         -- 여기서 LotNo관리 품목인데 아닌면 오류 호출해줌   
         -- _TLGInOutLotSub 테이블에 Lot분할이 이루어졌으면 위에서 말한 체크사항을 하지 않음   
         -- 여기서 #TLGInOutDailyItem 테이블에 오류체크를 다 하고 마지막에 해당 상태,메시지를 #TLGInOutDailyBatch테이블에 이전하고 있음   
         EXEC _SLGInOutDailyINSERT @CompanySeq -- _TLGInOutStock, _TLGInOutLotStock  
     END        
       
     -- 위에서 '-'재고 체크를 하여 오류가 발생 했으면 직접 return   
     -- 구지 다음 단계까지 탈 이유가 없음, 속도 위하여   
     IF EXISTS ( SELECT TOP 1 1 FROM #TLGInOutDailyBatch WHERE Status <> 0 )   
     BEGIN   
      SELECT * FROM #TLGInOutDailyBatch  
         RETURN  
     END   
       
     -- Lot월집계   
     EXEC _SLGWHStockUPDATE @CompanySeq -- _TLGWHStock   
     EXEC _SLGLOTStockUPDATE @CompanySeq -- _TLGLotStock   
   
     IF @PgmSeq <> 5376 -- 수입원가계산은 (-)재고체크 제외  
        AND NOT(@PgmSeq = 2038 AND @WorkingTag = 'D') -- 프로젝트자재출고등록 '삭제'시 (-)재고체크 제외  
     AND @PgmSeq <> 7022        -- 프로젝트자재반품등록 에도 - 재고체크 제외 20110216 이재혁  
     BEGIN  
         EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch', @LanguageSeq  
           
         -- 위에서 '-'재고 체크를 하여 오류가 발생 했으면 직접 return   
         -- 구지 다음 단계까지 탈 이유가 없음, 속도 위하여   
         IF EXISTS ( SELECT TOP 1 1 FROM #TLGInOutDailyBatch WHERE Status <> 0 )   
         BEGIN   
             SELECT * FROM #TLGInOutDailyBatch  
             RETURN  
         END   
           
         EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch', @LanguageSeq  
     END  
   
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TLGInOutDailyBatch )  
      
    RETURN @Status  