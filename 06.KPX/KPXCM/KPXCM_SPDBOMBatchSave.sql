IF OBJECT_ID('KPXCM_SPDBOMBatchSave') IS NOT NULL    
    DROP PROC KPXCM_SPDBOMBatchSave
GO 

-- v2015.09.16 

/*************************************************************************************************    
 FORM NAME           -       FrmPDBOMBatch   
 DESCRIPTION         -     배합비  
 CREAE DATE          -       2008.05.30      CREATE BY: 김현  
 LAST UPDATE  DATE   -       2008.09.01         UPDATE BY: 김현   
        2009. 09.08 UPDATE BY 송경애  
      :: BOM차수 , 공정흐름유형 추가  
*************************************************************************************************/    
  
CREATE PROCEDURE KPXCM_SPDBOMBatchSave  
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
            @BatchSeq    INT,  
            @ProdUnitSeq INT  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #KPXCM_TPDBOMBatch (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDBOMBatch'  
  
    IF @@ERROR <> 0 RETURN    
       
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq,  
                   @UserSeq,  
                   'KPXCM_TPDBOMBatch',  
                   '#KPXCM_TPDBOMBatch',  
                   'FactUnit, BatchSeq',  
                   'CompanySeq,FactUnit,BatchSeq,BatchNo,BatchName,ItemSeq,BatchSize,ProdUnitSeq,IsUse,DateFr,DateTo,Remark,IsDefault,LastUserSeq,LastDateTime'  
  
  
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TPDBOMBatch WHERE WorkingTag = 'D' AND Status = 0  )  
    BEGIN  
        DELETE KPXCM_TPDBOMBatch  
          FROM KPXCM_TPDBOMBatch AS A JOIN #KPXCM_TPDBOMBatch AS B ON (A.BatchSeq = B.BatchSeq)  
         WHERE B.WorkingTag = 'D' AND B.Status = 0    
           AND A.CompanySeq = @CompanySeq  
  
        IF @@ERROR <> 0 RETURN    
  
        DELETE KPXCM_TPDBOMBatchItem   
          FROM KPXCM_TPDBOMBatchITem AS A JOIN #KPXCM_TPDBOMBatch AS B ON (A.BatchSeq = B.BatchSeq)  
         WHERE B.WorkingTag = 'D' AND B.Status = 0            
           AND A.CompanySeq = @CompanySeq  
  
        IF @@ERROR <> 0 RETURN    
    END  
  
    -- Update    
    IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatch WHERE WorkingTag = 'U' AND Status = 0  )  
    BEGIN   
        IF NOT EXISTS (SELECT 1 FROM KPXCM_TPDBOMBatch AS A JOIN #KPXCM_TPDBOMBatch AS B ON A.BatchSeq = B.BatchSeq WHERE A.CompanySeq = @CompanySeq)  
        BEGIN  
            UPDATE #KPXCM_TPDBOMBatch SET WorkingTag = 'A'   
            WHERE WorkingTag = 'U' AND Status = 0  
        END  
        UPDATE KPXCM_TPDBOMBatch SET  
                BatchNo         = B.BatchNo    ,  
                BatchName       = B.BatchName  ,  
                BatchSize       = B.BatchSize  ,  
                ItemSeq         = B.ItemSeq    ,                  
                FactUnit        = B.FactUnit   ,                  
                IsUse           = B.IsUse      ,  
                ProdUnitSeq     = B.ProdUnitSeq,  
                DateFr          = B.DateFr     ,  
                DateTo          = B.DateTo     ,  
                LastUserSeq  = @UserSeq     ,   
                LastDateTime  = GETDATE()    ,  
                BOMRev          = B.BOMRev     ,  
                ProcTypeSeq     = B.ProcTypeSeq  
          FROM KPXCM_TPDBOMBatch AS A JOIN #KPXCM_TPDBOMBatch AS B ON A.BatchSeq = B.BatchSeq  
         WHERE B.WorkingTag = 'U' AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq  
  
        IF @@ERROR <> 0 RETURN    
    END   
    -- INSERT    
    IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatch WHERE WorkingTag = 'A' AND Status = 0  )  
    BEGIN    
    INSERT INTO KPXCM_TPDBOMBatch (CompanySeq,FactUnit,BatchSeq,BatchNo,BatchName,  
                                ItemSeq,BatchSize,ProdUnitSeq,IsUse,DateFr,  
                                DateTo,Remark,IsDefault,LastUserSeq,LastDateTime,  
                                BOMRev, ProcTypeSeq)  
        SELECT @CompanySeq, B.FactUnit,B.BatchSeq   , B.BatchNo , B.BatchName,   
                 B.ItemSeq  , B.BatchSize, B.ProdUnitSeq, B.IsUse    ,  B.DateFr   ,   
               B.DateTo ,   ISNULL(B.Remark,'')   , B.IsDefault  , @UserSeq   , GETDATE()  ,  
               B.BOMRev, B.ProcTypeSeq  
          FROM #KPXCM_TPDBOMBatch AS B   
         WHERE B.WorkingTag = 'A' AND B.Status = 0   
   
        IF @@ERROR <> 0 RETURN    
    END   
    
    SELECT * FROM #KPXCM_TPDBOMBatch AS KPXCM_TPDBOMBatch    
  
RETURN  
/*************************************************************************************************/    
  