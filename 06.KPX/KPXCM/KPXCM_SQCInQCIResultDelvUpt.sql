IF OBJECT_ID('KPXCM_SQCInQCIResultDelvUpt') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCIResultDelvUpt
GO 

-- v2016.06.30 

CREATE PROC KPXCM_SQCInQCIResultDelvUpt
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT     = 0,    
     @ServiceSeq     INT     = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT     = 1,    
     @LanguageSeq    INT     = 1,    
     @UserSeq        INT     = 0,    
     @PgmSeq         INT     = 0  
 AS     
     
     CREATE TABLE #KPX_TQCTestResult (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'       
     IF @@ERROR <> 0 RETURN    
     
     -- DELETE      
     IF EXISTS (SELECT TOP 1 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'D' AND Status = 0)    
     BEGIN    
        
         IF EXISTS(SELECT * FROM #KPX_TQCTestResult WHERE SMSourceType = 1000522008) -- 내수일경우만 구매입고 테이블 UPDATE
         BEGIN
             -- 구매입고테이블에 QC관련 컬럼 업뎃  
             UPDATE _TPUDelvItem  
                SET SMQCType = 6035002,  
                    QcEmpSeq = 0,  
                    QcDate   = '',  
                    QcQty    = 0,  
                    BadQty   = 0,  
                    QcCurAmt = 0  
               FROM #KPX_TQCTestResult       AS M JOIN KPX_TQCTestRequestItem    AS S ON S.CompanySeq    = @CompanySeq
                                                                                     AND S.ReqSeq        = M.ReqSeq
                                                                                     AND S.ReqSerl       = M.ReqSerl
                                                  JOIN _TPUDelvItem              AS A ON A.CompanySeq    = S.CompanySeq
                                                                                     AND A.DelvSeq       = S.SourceSeq  
                                                                                     AND A.DelvSerl      = S.SourceSerl  
              WHERE 1=1
                AND M.WorkingTag = 'D'  
             IF @@ERROR <> 0 RETURN    
         END
      
     END    
     
     -- UPDATE  
     IF EXISTS (SELECT 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'U' AND Status = 0)    
     BEGIN    
         -- 구매입고테이블에 QC관련 컬럼 업뎃  
         UPDATE _TPUDelvItem  
            SET SMQCType = CASE WHEN M.SMTestResult = 1010418002 THEN 6035004
                                WHEN M.SMTestResult = 1010418001 AND ISNULL(A.BadQty, 0) = 0 THEN 6035003 
                                WHEN M.SMTestResult = 1010418001 AND ISNULL(A.BadQty, 0) <> 0 THEN 6035004
                                WHEN M.SMTestResult = 1010418003 THEN 6035005
                             END, -- 6035003:적합, 6035004:부적합(합격이면서 불량수량이 존재할 경우 부적합)
                QcEmpSeq = @UserSeq,  
                QcDate   = CONVERT( NCHAR(8), GETDATE(), 112),  
                QcQty    = ISNULL(M.OKQty, 0),  
                BadQty   = ISNULL(M.BadQty, 0),  
                QcCurAmt = CASE M.SMTestResult WHEN 6035003 THEN A.CurAmt    ELSE 0 END  
           FROM #KPX_TQCTestResult       AS M JOIN KPX_TQCTestRequestItem    AS S ON S.CompanySeq    = @CompanySeq
                                                                                 AND S.ReqSeq        = M.ReqSeq
                                                                                 AND S.ReqSerl       = M.ReqSerl
                                              JOIN _TPUDelvItem              AS A ON A.CompanySeq    = S.CompanySeq
                                                                                 AND A.DelvSeq       = S.SourceSeq  
                                                                                 AND A.DelvSerl      = S.SourceSerl  
          WHERE 1=1
            AND M.WorkingTag = 'U'  
         IF @@ERROR <> 0 RETURN    
     END
      -- INSERT  
     IF EXISTS (SELECT 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'A' AND Status = 0)    
     BEGIN    
       
          IF EXISTS(SELECT * FROM #KPX_TQCTestResult WHERE SMSourceType = 1000522008) -- 내수일경우만 구매입고 테이블 UPDATE
         BEGIN
             -- 구매입고테이블에 QC관련 컬럼 업뎃  
             UPDATE _TPUDelvItem  
                SET SMQCType = CASE WHEN M.SMTestResult = 1010418002 THEN 6035004
                                    WHEN M.SMTestResult = 1010418001 AND ISNULL(M.BadQty, 0) = 0 THEN 6035003 
                                    WHEN M.SMTestResult = 1010418001 AND ISNULL(M.BadQty, 0) <> 0 THEN 6035006 
                                    WHEN M.SMTestResult = 1010418003 THEN 6035005 
                                 END, -- 6035003:적합, 6035004:부적합(합격이면서 불량수량이 존재할 경우 부적합)
                    QcEmpSeq = @UserSeq,  
                    QcDate   = CONVERT( NCHAR(8), GETDATE(), 112),  
                    QcQty    = ISNULL(A.QCQty , 0) + ISNULL(M.OKQty, 0),  
                    BadQty   = ISNULL(A.BadQty, 0) + ISNULL(M.BadQty, 0),  
                    QcCurAmt = CASE M.SMTestResult WHEN 6035003 THEN A.CurAmt    ELSE 0 END  
               FROM #KPX_TQCTestResult       AS M JOIN KPX_TQCTestRequestItem    AS S ON S.CompanySeq    = @CompanySeq
                                                                                     AND S.ReqSeq        = M.ReqSeq
                                                                                     AND S.ReqSerl       = M.ReqSerl
                                                  JOIN _TPUDelvItem              AS A ON A.CompanySeq    = S.CompanySeq
                                                                                     AND A.DelvSeq       = S.SourceSeq  
                                                                                     AND A.DelvSerl      = S.SourceSerl  
              WHERE 1=1
                AND M.WorkingTag = 'A'  
             IF @@ERROR <> 0 RETURN    
         END
     
     END     
     
     SELECT * FROM #KPX_TQCTestResult   
     
 RETURN

GO


