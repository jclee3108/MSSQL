
IF OBJECT_ID('KPXCM_SPUORDDeletePOSave') IS NOT NULL 
    DROP PROC KPXCM_SPUORDDeletePOSave
GO 

-- v2015.11.17 

-- MES연동 데이터 삭제를 위한 KPX용 by이재천 
/************************************************************  
  설  명 - 데이터-구매발주일괄삭제 : 발주삭제  
  작성일 - 20110210  
  작성자 - 김세호  
 ************************************************************/  
 CREATE PROC KPXCM_SPUORDDeletePOSave
  @xmlDocument    NVARCHAR(MAX),    
  @xmlFlags       INT     = 0,    
  @ServiceSeq     INT     = 0,    
  @WorkingTag     NVARCHAR(10)= '',    
  @CompanySeq     INT     = 1,    
  @LanguageSeq    INT     = 1,    
  @UserSeq        INT     = 0,    
  @PgmSeq         INT     = 0    
   
 AS     
    
    CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2656, 'DataBlock1', '#TPUORDPO'       
    IF @@ERROR <> 0 RETURN    

    CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2656, 'DataBlock2', '#TPUORDPOItem'       
    IF @@ERROR <> 0 RETURN
    
    CREATE TABLE #TPUORDPOItemSub (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2656, 'DataBlock2', '#TPUORDPOItemSub'       
    IF @@ERROR <> 0 RETURN

    ALTER TABLE #TPUORDPOItem ADD PONoOld NVARCHAR(100) NULL 
    ALTER TABLE #TPUORDPOItem ADD PONo NVARCHAR(100) NULL 
    
    ALTER TABLE #TPUORDPOItemSub ADD PONoOld NVARCHAR(100) NULL 
    ALTER TABLE #TPUORDPOItemSub ADD PONo NVARCHAR(100) NULL 
   --select * From #TPUORDPO
    --select * from #TPUORDPOItem 
   --return 
   --select * from #TPUORDPOItem 
   
   
   
   CREATE TABLE #SComSourceDailyBatch 
      (            
          ToTableName   NVARCHAR(100),            
          ToSeq         INT,            
          ToSerl        INT,            
          ToSubSerl     INT,            
          FromTableName NVARCHAR(100),            
          FromSeq       INT,            
          FromSerl      INT,            
          FromSubSerl   INT,            
          ToQty         DECIMAL(19,5),            
          ToStdQty      DECIMAL(19,5),            
          ToAmt         DECIMAL(19,5),            
          ToVAT         DECIMAL(19,5),            
          FromQty       DECIMAL(19,5),            
          FromSTDQty    DECIMAL(19,5),            
          FromAmt       DECIMAL(19,5),            
          FromVAT       DECIMAL(19,5)            
      ) 
    
    UPDATE #TPUORDPO
       SET POAmd = 0
      
    INSERT INTO #TPUORDPOItem (WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, POSeq, POSerl, ItemSeq, PONo, StdUnitQty)
    SELECT A.WorkingTag, A.IDX_NO, A.DataSeq, A.Selected, A.MessageType, A.Status, A.Result, A.ROW_IDX, A.IsChangedMst, A.POSeq, B.POSerl, B.ItemSeq, C.PONo, B.StdUnitQty
      FROM #TPUORDPO AS A 
      JOIN _TPUORDPOItem AS B ON A.POSeq = B.POSeq
      JOIN _TPUORDPO     AS C ON ( C.POSeq = A.POSeq ) 
     WHERE B.CompanySeq = @CompanySeq 
    

    -- 진행대상 발주품목 담기 
      INSERT INTO #SComSourceDailyBatch
         SELECT '_TPUORDPOItem', A.POSeq, A.POSerl, 0,
                '_TPUORDApprovalReqItem', A.ProgFromSeq, A.ProgFromSerl, 0,
                ISNULL(A.Qty, 0), ISNULL(A.StdUnitQty, 0), ISNULL(A.CurAmt, 0), ISNULL(A.CurVAT, 0),
                ISNULL(A.Qty, 0), ISNULL(A.StdUnitQty, 0), ISNULL(A.CurAmt, 0), ISNULL(A.CurVAT, 0)
         FROM   _TPUORDPOItem A 
                    JOIN #TPUORDPOItem B       ON A.POSeq = B.POSeq 
                                              AND A.POSerl = B.POSerl
         WHERE A.CompanySeq = @CompanySeq
         
       -- 구매발주 마스터 
    EXEC KPXCM_SPUORDPOSave @xmlDocument    = N'<ROOT></ROOT>',  
                            @xmlFlags       = @xmlFlags     ,  
                            @ServiceSeq     = 2656   ,  
                            @WorkingTag     = 'DelBatch'  ,  
                            @CompanySeq     = @CompanySeq   ,  
                            @LanguageSeq    = @LanguageSeq  ,  
                            @UserSeq        = @UserSeq      ,  
                            @PgmSeq         = @PgmSeq  
      IF @@ERROR <> 0 RETURN  
    

    DECLARE @MaxSeq INT 
    
    SELECT * 
      INTO #TPUORDPOItemTemp
      FROM #TPUORDPOItem 
      
    SELECT @MaxSeq = MAX(DataSeq) FROM #TPUORDPOItemTemp 
    
    IF EXISTS (SELECT 1 FROM #TPUORDPOItemTemp) 
    BEGIN 
    
        DECLARE @Cnt INT 
        SELECT @Cnt = 1 
        
        WHILE ( 1 = 1 ) 
        BEGIN
            TRUNCATE TABLE #TPUORDPOItem
            
            INSERT INTO #TPUORDPOItem
            SELECT * 
              FROM #TPUORDPOItemTemp
             WHERE DataSeq = @Cnt 
            
            
            
            INSERT INTO #TPUORDPOItemSub
            EXEC KPXCM_SPUORDPOItemSave @xmlDocument    = N'<ROOT></ROOT>'           ,  
                                        @xmlFlags       = @xmlFlags     ,  
                                        @ServiceSeq     = 2656   ,  
                                        @WorkingTag     = 'DelBatch'  ,  
                                        @CompanySeq     = @CompanySeq   ,  
                                        @LanguageSeq    = @LanguageSeq  ,  
                                        @UserSeq        = @UserSeq      ,  
                                        @PgmSeq         = @PgmSeq  
            IF @@ERROR <> 0 RETURN  
            
            IF @Cnt >= (SELECT ISNULL(@MaxSeq,0))
            BEGIN
                BREAK 
            END 
            ELSE 
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END   
    END 
    
    SELECT * FROM #TPUORDPOItemTemp 
    
    -- 진행데이터 처리
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq
    IF @@ERROR <> 0 RETURN   
  
 RETURN