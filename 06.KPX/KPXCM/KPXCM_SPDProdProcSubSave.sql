IF OBJECT_ID('KPXCM_SPDProdProcSubSave') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcSubSave
GO 

-- v2016.03.07 

-- 제품별생산소요등록-상세저장 by 전경만
CREATE PROC KPXCM_SPDProdProcSubSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT
  
    CREATE TABLE #ProdProcRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#ProdProcRev'
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDProdProcItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDProdProcItem'    , -- 테이블명        
                  '#ProdProcRev'    , -- 임시 테이블명        
                  'ItemSeq,PatternRev, SubItemSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    --DEL
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        DELETE KPX_TPDProdProcItem
          FROM KPX_TPDProdProcItem AS A
               JOIN #ProdProcRev AS B ON B.ItemSeq = A.ItemSeq 
                                     ANd B.PatternRev = A.PatternRev
                                     AND B.SubItemSeq = A.SubItemSeq
									 AND B.Serl = A.Serl
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'D'
           AND B.Status = 0
    END 

    --UPDATE
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'U' AND Status = 0)
    BEGIN
        UPDATE A
           SET PatternQty = B.PatternQty,
			   SortNum     = B.SortNum,
			   BOMSerl     = B.BOMSerl,
			   RowNum      = B.RowNum,
			   ProdQty     = B.ProdQty, 
			   LastUserSeq = @UserSeq,
               LastDateTime = GETDATE()
          FROM KPX_TPDProdProcItem AS A
               JOIN #ProdProcRev AS B ON B.ItemSeq = A.ItemSeq 
                                     ANd B.PatternRev = A.PatternRev
                                     AND B.SubItemSeq = A.SubItemSeq
									 and B.Serl = A.Serl
         WHERE A.CompanySeq = @CompanySeq
           AND B.WorkingTag = 'U'
           AND B.Status = 0
    
    END 
    
    --INSERT 
    IF EXISTS (SELECT 1 FROM #ProdProcRev WHERE WorkingTag = 'A' AND Status = 0)
    BEGIN
        INSERT INTO KPX_TPDProdProcItem(CompanySeq, ItemSeq, PatternRev, SubItemSeq,
                                        PatternQty, LastUserSeq ,LastDateTime,SortNum,Serl,BomSerl,RowNum, ProdQty)
             SELECT @CompanySeq, ItemSeq, PatternRev, SubItemSeq,
                    PatternQty, @UserSeq, GETDATE(),SortNum,Serl,BomSerl,RowNum, ProdQty
               FROM #ProdProcRev
              WHERE WorkingTag = 'A'
                AND Status = 0
    
    END 
    --KPX_TPDProdProcItem
    
    SELECT * FROM #ProdProcRev
    
    RETURN
    
GO


