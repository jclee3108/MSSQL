
IF OBJECT_ID('KPX_SPDSFCProdPackReportSave_POP') IS NOT NULL 
    DROP PROC KPX_SPDSFCProdPackReportSave_POP
GO 
      
-- v2015.05.04 
      
-- POP 연동 생산실적입력(Lot대체, 이동처리) by이재천     
      
/*********************************************************************************************************  
  
-- Relation Table의 DataKind   
  
1 - 전함바 Lot 대체처리   
2 - 전함바 이동처리   
3 - 전함바 X Lot 대체처리 (공정)  
4 - 전함바 X 이동처리 (창고 : 일반 -> 제품) (공정)   
5 - 전함바 X 이동처리 (창고 : 일반 -> 함바) (공정)   
6 - 전함바 X 이동처리 (창고 : 일반 -> 드레인) (공정)   
7 - 전함바 X Lot 대체처리 (탱크)   
8 - 전함바 X 이동처리 (탱크)   
9 - 용기 기타출고   
*********************************************************************************************************/  
CREATE PROC KPX_SPDSFCProdPackReportSave_POP       
          
    @CompanySeq INT       
          
AS       
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
        
    DECLARE @TableColumns NVARCHAR(4000),   
            @BaseDate     NCHAR(8),   
            @ReportNo     NVARCHAR(100)   
        
    CREATE TABLE #BaseData       
    (      
        IDX_NO          INT IDENTITY,       
        Seq             INT,       
        FactUnit        INT,       
        IsPacking       NCHAR(1),       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT,       
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100),       
        HambaQty        DECIMAL(19,5),       
        DrainQty        DECIMAL(19,5),     
        WorkingTag      NCHAR(1),   
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5) 
    )      
        
    CREATE TABLE #BaseData_Sub       
    (      
        IDX_NO          INT IDENTITY,       
        Seq             INT,       
        FactUnit        INT,       
        IsPacking       NCHAR(1),       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT,       
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100),       
        HambaQty        DECIMAL(19,5),       
        DrainQty        DECIMAL(19,5),     
        WorkingTag      NCHAR(1),   
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5) 
    )      
        
    CREATE TABLE #SubTable     
    (    
        IDX_NO          INT,     
        BizUnit         INT,     
        InOutSeq        INT,     
        InOutNo         NVARCHAR(100),     
        InOutDate       NCHAR(8),     
        InOutType       INT,     
        OutWHSeq        INT,     
        ItemSeq         INT,     
        UnitSeq         INT,     
        Qty             DECIMAL(19,5),     
        WorkingTag      NCHAR(1),     
        WorkOrderSeq    INT,     
        WorkOrderSerl   INT     
    )    
        
    CREATE TABLE #SubTable_Sub     
    (    
        IDX_NO          INT IDENTITY,     
        BizUnit         INT,     
        InOutSeq        INT,     
        InOutNo         NVARCHAR(100),     
        InOutDate       NCHAR(8),     
        InOutType       INT,     
        OutWHSeq        INT,     
        ItemSeq         INT,     
        UnitSeq         INT,     
        Qty             DECIMAL(19,5),     
        WorkingTag      NCHAR(1),     
        WorkOrderSeq    INT,     
        WorkOrderSerl   INT     
    )    
        
    CREATE TABLE #KPX_TPDSFCProdPackReportLog     
    (    
        IDX_NO          INT IDENTITY,     
        WorkingTag      NCHAR(1),     
        Status          INT,     
        PackReportSeq   INT    
    )    
        
    CREATE TABLE #KPX_TPDSFCProdPackReportItemLog     
    (    
        IDX_NO          INT IDENTITY,     
        WorkingTag      NCHAR(1),     
        Status          INT,     
        PackReportSeq   INT,    
        PackReportSerl   INT    
    )    
         --select * from KPX_TPDSFCProdPackOrder    
         --select * from KPX_TPDSFCProdPackOrderItem    
        
    INSERT INTO #BaseData_Sub         
    (        
        Seq,            FactUnit,   IsPacking,    WorkOrderSeq,     WorkOrderSerl,         
        GoodItemSeq,    ProdQty,    RealLotNo,    HambaQty,         DrainQty,       
        WorkingTag,     WorkEndDate,RealProdQty   
    )        
      SELECT TOP 10 A.Seq,            C.FactUnit,   A.IsPacking,    A.WorkOrderSeq,              A.WorkOrderSerl,         
           A.GoodItemSeq,    ISNULL(A.ProdQty,0) - (ISNULL(A.HambaQty,ISNULL(A.DrainQty,0)) - ISNULL(D.UseQty,0) ),    A.RealLotNo,    ISNULL(A.HambaQty,0),        ISNULL(A.DrainQty,0),       
           A.WorkingTag,     A.WorkEndDate, ISNULL(A.ProdQty,0)   
      FROM KPX_TPDSFCWorkReport_POP AS A       
      OUTER APPLY( SELECT Z.FactUnit    
                     FROM KPX_TPDSFCWorkOrder_POP AS Z     
                    WHERE Z.CompanySeq = @CompanySeq     
                      AND Z.WorkOrderSeq = A.WorkOrderSeq     
                      AND Z.WorkorderSerl = A.WorkOrderSerl     
                      AND Z.IsPacking = A.IsPacking     
                      AND Z.Serl = (     
                                    SELECT MAX(Serl) AS Serl     
                                      FROM KPX_TPDSFCWorkOrder_POP AS Y    
                                     WHERE Y.companyseq = @CompanySeq      
                                       AND Y.WorkOrderSeq = Z.WorkOrderSeq    
                                       AND Y.WorkOrderSerl = Z.WorkOrderSerl    
                                   )    
                 ) AS C   
      OUTER APPLY (  
                    SELECT SUM(UseQty) AS UseQty   
                      FROM KPX_TPDPackingHanbaInPut_POP AS Z   
                     WHERE Z.CompanySeq = @CompanySeq   
                       AND Z.WorkOrderSeq = A.WorkOrderSeq   
                       AND Z.WorkOrderSerl = A.WorkOrderSerl   
                 ) AS D   
     WHERE A.ProcYn = '0'         
       AND A.IsPacking = '1'         
       AND ISNULL(C.FactUnit,0) <> 0       
       AND ISNULL(A.WorkEndDate,'') <> ''    
     ORDER BY A.Seq       
          
    --select * from #BaseData_Sub       
    --return       
          
    INSERT INTO #SubTable_Sub       
    (       
        BizUnit, InOutSeq, InOutNo, InOutDate, InOutType,       
        OutWHSeq, ItemSeq, UnitSeq, Qty, WorkingTag,       
        WorkOrderSeq, WorkOrderSerl       
    )       
    SELECT TOP 10 F.BizUnit, 0, '', A.WorkEndDate, 31,       
           D.SubOutWHSeq, E.SubItemSeq, ISNULL(E.SubUnitSeq,0), ISNULL(ISNULL(A.SubQty,E.SubQty),0), A.WorkingTag,       
           A.WorkOrderSeq, A.WorkOrderSerl       
      FROM KPX_TPDSFCWorkReport_POP AS A       
      OUTER APPLY( SELECT Z.FactUnit    
                     FROM KPX_TPDSFCWorkOrder_POP AS Z     
                    WHERE Z.CompanySeq = @CompanySeq     
                      AND Z.WorkOrderSeq = A.WorkOrderSeq     
                      AND Z.WorkorderSerl = A.WorkOrderSerl     
                      AND Z.IsPacking = A.IsPacking     
                      AND Z.Serl = (     
                                    SELECT MAX(Serl) AS Serl     
                                      FROM KPX_TPDSFCWorkOrder_POP AS Y    
                                     WHERE Y.companyseq = @CompanySeq      
                                       AND Y.WorkOrderSeq = Z.WorkOrderSeq    
                                       AND Y.WorkOrderSerl = Z.WorkOrderSerl    
                                   )    
                 ) AS C     
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.PackOrderSeq = A.WorkOrderSeq )       
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.PackOrderSeq = A.WorkOrderSeq AND E.PackOrderSerl = A.WorkOrderSerl )       
      LEFT OUTER JOIN _TDAFactUnit          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.FactUnit = C.FactUnit )       
     WHERE A.ProcYn = '0'         
         AND A.IsPacking = '1'          
       AND ISNULL(C.FactUnit,0) <> 0       
       AND ISNULL(A.WorkEndDate,'') <> ''    
     ORDER BY A.Seq       
    
    --select * from #BaseData_Sub
    --select * from #SubTable_Sub
    
    --return 
    --select * From #SubTable_Sub       
    --return       
          
    IF @@ROWCOUNT = 0        
    BEGIN      
        SELECT * FROM #BaseData_Sub       
        RETURN       
    END       
      
    DECLARE @Count          INT,         
            @BizUnit        INT,         
            @Date           NCHAR(8),         
            @Seq            INT,         
            @MaxNo          NVARCHAR(100),         
            @Cnt            INT,          
            @Qty            DECIMAL(19,5),         
            @UMProgType     INT,         
            @FactUnit       INT,         
            @RealLotNo      NVARCHAR(100),         
            @ItemSeq        INT,         
            @WHSeq          INT,         
            @HambaQty       DECIMAL(19,5),         
            @DrainQty        DECIMAL(19,5),       
            @HambaWH        INT,         
            @DrainWH        INT,       
            @NormalWH       INT,       
            @NormalOutWH    INT,
            @StockQty       DECIMAL(19,5),         
            @LotNo          NVARCHAR(100),         
            @InOutType      INT,         
            @InOutType2     INT,         
            @InWHSeq2       INT,      
            @OriQty         DECIMAL(19,5),       
            @WorkingTag_Sub NCHAR(1),       
            @WorkOrderSeq   INT,       
            @WorkOrderSerl  INT,     
            @WorkEndDate    NCHAR(8)     
          
    CREATE TABLE #LotReplace        
    (        
        WorkingTag      NCHAR(1),         
        IDX_NO          INT IDENTITY,         
        RealLotNo       NVARCHAR(100),         
        LotNo           NVARCHAR(100),         
        ItemSeq         INT,         
        InOutType       INT,         
        InOutType2      INT,         
        InOutSeq        INT,         
        InOutNo         NVARCHAR(100),         
        OutWHSeq        INT,         
        InWHSeq         INT,         
        InOutDate       NCHAR(8),         
        BizUnit         INT,         
        Qty             DECIMAL(19,5),         
        InWHSeq2        INT,       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT      
    )        
                  
    CREATE TABLE #LotReplace2        
    (        
        WorkingTag      NCHAR(1),         
        IDX_NO          INT IDENTITY,         
        RealLotNo       NVARCHAR(100),         
        LotNo           NVARCHAR(100),         
        ItemSeq         INT,         
        InOutType       INT,         
        InOutType2      INT,         
        InOutSeq        INT,         
        InOutNo         NVARCHAR(100),         
        OutWHSeq        INT,         
        InWHSeq         INT,         
        InOutDate       NCHAR(8),         
        BizUnit         INT,         
        Qty             DECIMAL(19,5),         
          InWHSeq2         INT,       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT       
    )        
                    
                    
    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 4422, 'DataBlock1', '#Temp'           
          
    CREATE TABLE #Temp2 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp2'          
              
    CREATE TABLE #Temp3 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp3'          
            
    ALTER TABLE #Temp3 ADD IsStockQty DECIMAL(19,5)         
    ALTER TABLE #Temp3 ADD IsStockAmt DECIMAL(19,5)         
    ALTER TABLE #Temp3 ADD IsLot NCHAR(1)        
    ALTER TABLE #Temp3 ADD IsSerial NCHAR(1)        
    ALTER TABLE #Temp3 ADD IsItemStockCheck NCHAR(1)        
    ALTER TABLE #Temp3 ADD InOutDate NCHAR(8)        
    ALTER TABLE #Temp3 ADD CustSeq  INT        
      ALTER TABLE #Temp3 ADD SalesCustSeq INT        
    ALTER TABLE #Temp3 ADD IsTrans NCHAR(1)        
          
    CREATE TABLE #Temp11 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp11'          
          
    CREATE TABLE #Temp12 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp12'          
          
    ALTER TABLE #Temp12 ADD IsStockQty DECIMAL(19,5)         
    ALTER TABLE #Temp12 ADD IsStockAmt DECIMAL(19,5)         
    ALTER TABLE #Temp12 ADD IsLot NCHAR(1)        
    ALTER TABLE #Temp12 ADD IsSerial NCHAR(1)        
    ALTER TABLE #Temp12 ADD IsItemStockCheck NCHAR(1)        
    ALTER TABLE #Temp12 ADD InOutDate NCHAR(8)        
    ALTER TABLE #Temp12 ADD CustSeq  INT        
    ALTER TABLE #Temp12 ADD SalesCustSeq INT        
    ALTER TABLE #Temp12 ADD IsTrans NCHAR(1)        
      
    CREATE TABLE #Temp21 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp21'         
          
    CREATE TABLE #Temp22 (WorkingTag NCHAR(1) NULL)                   
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp22'        
          
    ALTER TABLE #Temp22 ADD IsStockQty DECIMAL(19,5)         
    ALTER TABLE #Temp22 ADD IsStockAmt DECIMAL(19,5)         
    ALTER TABLE #Temp22 ADD IsLot NCHAR(1)        
    ALTER TABLE #Temp22 ADD IsSerial NCHAR(1)        
    ALTER TABLE #Temp22 ADD IsItemStockCheck NCHAR(1)        
    ALTER TABLE #Temp22 ADD InOutDate NCHAR(8)        
    ALTER TABLE #Temp22 ADD CustSeq  INT        
    ALTER TABLE #Temp22 ADD SalesCustSeq INT        
    ALTER TABLE #Temp22 ADD IsTrans NCHAR(1)        
                  
                  
    CREATE TABLE #GetInOutLot            
     (              
         LotNo         NVARCHAR(30),            
         ItemSeq       INT        
     )              
                   
     CREATE TABLE #GetInOutLotStock              
     (              
         WHSeq           INT,              
         FunctionWHSeq   INT,              
         LotNo           NVARCHAR(30),            
         ItemSeq         INT,              
         UnitSeq         INT,              
         PrevQty         DECIMAL(19,5),              
         InQty           DECIMAL(19,5),              
         OutQty          DECIMAL(19,5),              
         StockQty        DECIMAL(19,5),              
         STDPrevQty      DECIMAL(19,5),              
         STDInQty        DECIMAL(19,5),              
         STDOutQty       DECIMAL(19,5),              
         STDStockQty     DECIMAL(19,5)              
     )         
           
     CREATE TABLE #GetInOutLotStock_Sub      
     (         
        IDX_NO          INT IDENTITY,       
        RegDate         NCHAR(8),       
        WHSeq           INT,              
        FunctionWHSeq   INT,              
        LotNo           NVARCHAR(30),            
        ItemSeq         INT,              
        UnitSeq         INT,              
        PrevQty         DECIMAL(19,5),              
        InQty           DECIMAL(19,5),              
        OutQty          DECIMAL(19,5),              
          StockQty        DECIMAL(19,5),              
        STDPrevQty      DECIMAL(19,5),              
        STDInQty        DECIMAL(19,5),              
        STDOutQty       DECIMAL(19,5),              
        STDStockQty     DECIMAL(19,5)              
     )            
      
    CREATE TABLE #LotReplace3        
    (        
        WorkingTag      NCHAR(1),         
        IDX_NO          INT IDENTITY,         
        RealLotNo       NVARCHAR(100),         
        LotNo           NVARCHAR(100),         
        ItemSeq         INT,         
        InOutType       INT,         
        InOutSeq        INT,         
        InOutNo         NVARCHAR(100),         
        OutWHSeq        INT,         
        InWHSeq          INT,         
        InOutDate       NCHAR(8),         
        BizUnit         INT,         
        Qty             DECIMAL(19,5),         
        InOutType2      INT,         
        InWHSeq2        INT,       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT       
    )         
          
    CREATE TABLE #LotReplace3_Sub      
    (        
        WorkingTag      NCHAR(1),         
        IDX_NO          INT IDENTITY,         
        RealLotNo       NVARCHAR(100),         
        LotNo           NVARCHAR(100),         
        ItemSeq         INT,         
        InOutType       INT,         
        InOutSeq        INT,         
        InOutNo         NVARCHAR(100),         
        OutWHSeq        INT,         
        InWHSeq         INT,         
        InOutDate       NCHAR(8),         
        BizUnit         INT,         
        Qty             DECIMAL(19,5),         
        InOutType2      INT,         
        InWHSeq2        INT,       
        Kind            INT,       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT       
    )         
          
    CREATE TABLE #LotReplace3_Sub_Sub      
    (        
        WorkingTag      NCHAR(1),         
        IDX_NO          INT IDENTITY,         
        RealLotNo       NVARCHAR(100),         
        LotNo           NVARCHAR(100),          
        ItemSeq         INT,         
        InOutType       INT,         
        InOutSeq        INT,         
        InOutNo         NVARCHAR(100),         
        OutWHSeq        INT,         
        InWHSeq         INT,         
        InOutDate       NCHAR(8),         
        BizUnit         INT,         
        Qty             DECIMAL(19,5),         
        InOutType2      INT,         
        InWHSeq2        INT,       
        Kind            INT,       
        WorkOrderSeq    INT,       
        WorkOrderSerl   INT       
    )         
          
          
    CREATE TABLE #HambaDrainMove       
    (      
        IDX_NO      INT IDENTITY,       
        Qty         DECIMAL(19,5),       
        Kind        INT, -- 1 함바 2드레인 3일반      
    )      
          
    CREATE TABLE #HambaDrainMove_Sub      
    (      
        IDX_NO      INT IDENTITY,       
        Qty         DECIMAL(19,5),       
        Kind        INT, -- 1 함바 2드레인 3일반      
    )      
          
    CREATE TABLE #KPX_TPDSFCProdPackReport       
    (      
        IDX_NO              INT IDENTITY,       
        CompanySeq          INT,       
        PackReportSeq       INT,       
        FactUnit            INT,       
        PackDate            NCHAR(8),       
        ReportNo            NVARCHAR(100),       
        OutWHSeq            INT,       
        InWHSeq             INT,       
        UMProgType          INT,       
        DrumOutWHSeq        INT,       
        Remark              NVARCHAR(100),       
        LastUserSeq         INT      
    )       
          
    CREATE TABLE #KPX_TPDSFCProdPackReportItem       
    (      
        IDX_NO              INT IDENTITY,       
        CompanySeq          INT,       
        PackReportSeq       INT,       
        PackReportSerl      INT,       
        ItemSeq             INT,       
        UnitSeq             INT,       
        Qty                 DECIMAL(19,5),       
        LotNo               NVARCHAR(100),       
        OutLotNo            NVARCHAR(100),       
        Remark              NVARCHAR(100),       
        SubItemSeq          INT,       
        SubUnitSeq          INT,       
        SubQty              DECIMAL(19,5),       
        HambaQty            DECIMAL(19,5),       
        PackOrderSeq        INT,       
        PackOrderSerl       INT,       
        LastUserSeq         INT       
    )       
          
    DECLARE @MainCount  INT       
          
    SELECT @MainCount = 1       
          
    WHILE ( 1 = 1 )       
    BEGIN       
              
        TRUNCATE TABLE #BaseData       
        INSERT INTO #BaseData      
        (        
            Seq,            FactUnit,   IsPacking,     WorkOrderSeq,     WorkOrderSerl,         
            GoodItemSeq,    ProdQty,    RealLotNo,    HambaQty,         DrainQty,       
            WorkingTag,     WorkEndDate,RealProdQty  
        )        
        SELECT Seq,            FactUnit,   IsPacking,    WorkOrderSeq,     WorkOrderSerl,         
               GoodItemSeq,    ProdQty,    RealLotNo,    HambaQty,         DrainQty,       
               WorkingTag,     WorkEndDate,RealProdQty  
          FROM #BaseData_Sub       
         WHERE IDX_NO = @MainCount      
              
              
        TRUNCATE TABLE #SubTable      
        INSERT INTO #SubTable       
        (       
            IDX_NO, BizUnit, InOutSeq, InOutNo, InOutDate,       
            InOutType, OutWHSeq, ItemSeq, UnitSeq, Qty,       
            WorkingTag, WorkOrderSeq, WorkOrderSerl       
        )       
        SELECT IDX_NO, BizUnit, InOutSeq, InOutNo, InOutDate,       
               InOutType, OutWHSeq, ItemSeq, UnitSeq, Qty,       
               WorkingTag, WorkOrderSeq, WorkOrderSerl       
          FROM #SubTable_Sub       
         WHERE IDX_NO = @MainCount      
        
        
        --------------------------------------------------------------------------------------------------------------------------------        
        -- Lot마스터 생성         
        --------------------------------------------------------------------------------------------------------------------------------        
              
        DECLARE @XmlData NVARCHAR(MAX)        
        
        BEGIN TRAN 
        
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag AS WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.RealLotNo AS LotNo,         
                                                          A.GoodItemSeq AS ItemSeq,         
                                                          B.UnitSeq,         
                                                          0 AS Qty,         
                                                          A.GoodItemSeq AS ItemSeqOLD        
                                                     FROM #BaseData AS A         
                                                     LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq )        
                                                    WHERE ISNULL(A.RealLotNo,'') <> ''         
                                                      AND NOT EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = @CompanySeq AND ItemSeq = A.GoodItemSeq AND LotNo = A.RealLotNo)        
                                                    FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                     ))         
                
        TRUNCATE TABLE #Temp       
        INSERT INTO #Temp         
        EXEC _SLGLotNoMasterSave         
             @xmlDocument  = @XmlData,           
             @xmlFlags     = 2,           
             @ServiceSeq   = 4422,           
             @WorkingTag   = '',           
             @CompanySeq   = @CompanySeq,           
             @LanguageSeq  = 1,           
             @UserSeq      = 1,           
             @PgmSeq       = 1021351    
        
        
        
        IF (SELECT TOP 1 WorkingTag FROM #BaseData) = 'U' AND NOT EXISTS (SELECT 1 
                                                                            FROM #BaseData AS A 
                                                                            JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq 
                                                                                                                        AND B.WorkOrderSeq = A.WorkOrderSeq 
                                                                                                                        AND B.WorkOrderSerl = A.WorkOrderSerl 
                                                                                                                           )
                                                                         ) 
        BEGIN  
            ROLLBACK 
            
            UPDATE B        
               SET B.ProcYn = '2', 
                   B.ErrorMessage = '데이터가 존재하지 않아 수정 할 수 없습니다.'  
              FROM #BaseData AS A         
              JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
            
            GOTO GOEND;
        END 
        
        
        
        IF  NOT EXISTS (SELECT 1 
                          FROM #BaseData AS A 
                          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq 
                                                                 AND B.PackOrderSeq = A.WorkOrderSeq 
                                                                 AND B.PackOrderSerl = A.WorkOrderSerl 
                                                                    )
                       )
        BEGIN  
            ROLLBACK 
            
            UPDATE B        
               SET B.ProcYn = '2', 
                   B.ErrorMessage = '포장작업지시 데이터가 존재하지 않습니다.'  
              FROM #BaseData AS A         
              JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
            
            GOTO GOEND;
        END 
        
        
        IF EXISTS (SELECT 1 FROM #Temp WHERE Status <> 0)
        BEGIN
            ROLLBACK 
            
        UPDATE B        
           SET B.ProcYn = '2', 
               B.ErrorMessage = 'Lot마스터 생성 오류'  
          FROM #BaseData AS A         
          JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
        
        GOTO GOEND;
        
        END 
        
        --------------------------------------------------------------------------------------------------------------------------------        
        -- Lot마스터 생성, END         
        --------------------------------------------------------------------------------------------------------------------------------        
        
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 전함바 데이터 Lot 대체 , 이동처리         
        --------------------------------------------------------------------------------------------------------------------------------        
        
        TRUNCATE TABLE #LotReplace       
        INSERT INTO #LotReplace         
        (        
            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
            BizUnit,        Qty,            InOutType2, InWHSeq2,   WorkOrderSeq,       
            WorkOrderSerl         
        )        
        SELECT A.WorkingTag, A.RealLotNo, B.LotNo, A.GoodItemSeq, 310,         
               0, '', CASE WHEN B.WHSeq = 1 THEN 395 ELSE 439 END, CASE WHEN B.WHSeq = 1 THEN 395 ELSE 439 END, A.WorkEndDate,         
               C.BizUnit, ISNULL(B.UseQty,0), 80, D.InWHSeq, A.WorkOrderSeq,       
               A.WorkOrderSerl        
          FROM #BaseData AS A         
          LEFT OUTER JOIN (SELECT Z.WhSeq, Z.WorkOrderSeq, Z.WorkOrderSerl, Z.LotNo, Z.IsPacking, SUM(UseQty) AS UseQty 
                             FROM KPX_TPDPackingHanbaInPut_POP AS Z 
                            WHERE Z.CompanySeq = @CompanySeq 
                            GROUP BY Z.WhSeq, Z.WorkOrderSeq, Z.WorkOrderSerl, Z.LotNo, Z.IsPacking
                          ) AS B ON ( B.WorkOrderSeq = A.WorkOrderSeq           
                                  AND B.WorkOrderSerl = A.WorkOrderSerl           
                                  AND B.IsPacking = A.IsPacking          
                                    )           
            LEFT OUTER JOIN _TDAWH                       AS C ON ( C.CompanySeq = @CompanySeq AND C.WHSeq = B.WHSeq )         
            LEFT OUTER JOIN KPX_TPDSFCProdPackOrder      AS D ON ( D.CompanySeq = @CompanySeq AND D.PackOrderSeq = A.WorkOrderSeq ) 
          --OUTER APPLY (SELECT TOP 1 WHSeq         
          --               FROM _TDAWH AS Z         
          --              WHERE Z.CompanySeq = @CompanySeq         
          --                AND Z.WMSCode = 2       
          --                AND Z.FactUnit = A.FactUnit         
          --            ) AS D         
                      
        
        -- Seq, No 채번 ( Lot 대체 )         
              
        SELECT @BizUnit = MAX(BizUnit),              
               @Date    = MAX(InOutDate)        
          FROM #LotReplace         
                
        SELECT @Count = (SELECT COUNT(1) FROM #LotReplace)         
              
        IF EXISTS (SELECT 1 FROM #LotReplace WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
              
             
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE #LotReplace              
           SET InOutSeq = @Seq + IDX_NO         
          FROM #LotReplace       
         WHERE WorkingTag = 'A'       
              
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #LotReplace AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                   AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                   AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                   AND B.DataKind = 1       
                                                                     )      
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
                   
              
        SELECT @Cnt = 1         
              
        IF EXISTS (SELECT 1 FROM #LotReplace WHERE WorkingTag = 'A')       
        BEGIN       
              WHILE ( 1 = 1 )          
            BEGIN         
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #LotReplace              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
                
        -- Seq, No 채번,END         

        
        -- 전함 LOT 대체처리         
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq AS InWHSeq,         
                                                          A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정       
                                                          InOutType AS InOutType         
                                                      FROM #LotReplace AS A         
                                                     WHERE A.Qty <> 0       
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      ))         
              
        TRUNCATE TABLE #Temp2       
        INSERT INTO #Temp2         
         EXEC _SLGInOutDailySave         
              @xmlDocument  = @XmlData,           
              @xmlFlags     = 2,           
              @ServiceSeq   = 2619,           
              @WorkingTag   = '',           
              @CompanySeq   = @CompanySeq,           
              @LanguageSeq  = 1,           
              @UserSeq      = 1,           
              @PgmSeq       = 1021351    
              
              
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          1 AS InOutSerl,         
                                                          A.InOutType,         
                                                          A.ItemSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq AS InWHSeq,         
                                                          A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정      
                                                          B.UnitSeq,          
                                                          A.Qty,         
                                                          A.Qty AS STDQty,         
                                                          8023042 AS InOutKind,         
                                                          A.LotNo AS OriLotNo,         
                                                          A.RealLotNo AS LotNo,         
                                                          0 AS InOutDetailKind,         
                                                          0 AS Amt         
                                                      FROM #LotReplace AS A         
                                                      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                     WHERE A.Qty <> 0       
                                                     FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                      ))         
                
      
                
        TRUNCATE TABLE #Temp3       
        INSERT INTO #Temp3        
        EXEC _SLGInOutDailyItemSave         
               @xmlDocument  = @XmlData,           
             @xmlFlags     = 2,           
             @ServiceSeq   = 2619,           
             @WorkingTag   = '',           
             @CompanySeq   = @CompanySeq,           
             @LanguageSeq  = 1,           
             @UserSeq      = 1,           
             @PgmSeq       = 1021351    
                   
        IF EXISTS (SELECT 1 FROM #Temp3 WHERE Status <> 0)
        BEGIN
            ROLLBACK 
            
        UPDATE B        
           SET B.ProcYn = '2', 
               B.ErrorMessage = '전함 LOT 대체처리 오류'    
          FROM #BaseData AS A         
          JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
        
        GOTO GOEND;
        
        END 
        
        -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
        INSERT INTO KPX_TPDSFCProdPackReportRelation       
        (      
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
        )      
        SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 1, InOutType,       
               InOutSeq, 1, 1, GETDATE()       
          FROM #LotReplace       
         WHERE WorkingTag = 'A'       
              
              
        -- Seq, No 채번 ( 이동처리 )         
                
        SELECT @BizUnit = MAX(BizUnit),              
               @Date    = MAX(InOutDate)        
          FROM #LotReplace         
                
        SELECT @Count = (SELECT COUNT(1) FROM #LotReplace)         
              
        IF EXISTS (SELECT 1 FROM #LotReplace WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END       
              
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE #LotReplace              
           SET InOutSeq = @Seq + IDX_NO         
          FROM #LotReplace       
         WHERE WorkingTag = 'A'       
              
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq      
          FROM #LotReplace AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                   AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                   AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                   AND B.DataKind = 2       
                                                                     )      
         WHERE A.WorkingTag IN ( 'U', 'D' )       
                   
              
        IF EXISTS (SELECT 1 FROM #LotReplace WHERE WorkingTag = 'A')       
        BEGIN       
            SELECT @Cnt = 1         
                 
            WHILE ( 1 = 1 )         
            BEGIN         
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #LotReplace              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
              
        -- Seq, No 채번,END         
        --select * From #LotReplace         
        --select * from _TDAWH where WHSeq = 5         
        --return         
      
        -- 전함 이동처리         
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                               A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq,         
                                                          A.InWHSeq2 AS InWHSeq,         
                                                          A.InOutType2 AS InOutType         
                                                      FROM #LotReplace AS A       
                                                       WHERE A.Qty  <> 0       
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      ))         
        TRUNCATE TABLE #Temp2       
        INSERT INTO #Temp2         
        EXEC _SLGInOutDailySave         
              @xmlDocument  = @XmlData,           
              @xmlFlags     = 2,           
              @ServiceSeq   = 2619,           
              @WorkingTag   = '',           
              @CompanySeq   = @CompanySeq,           
              @LanguageSeq  = 1,           
              @UserSeq      = 1,           
              @PgmSeq       = 1021351    
                
                
        --전함 이동처리         
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          1 AS InOutSerl,         
                                                          A.InOutType2 AS InOutType,         
                                                          A.ItemSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq,         
                                                          A.InWHSeq2 AS InWHSeq,         
                                                          B.UnitSeq,          
                                                          A.Qty,         
                                                          A.Qty AS STDQty,         
                                                          8023008 AS InOutKind,         
                                                          A.RealLotNo AS OriLotNo,         
                                                          A.RealLotNo AS LotNo,         
                                                          0 AS InOutDetailKind,         
                                                          0 AS Amt         
                                                      FROM #LotReplace AS A         
                                                      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                     WHERE A.Qty <> 0       
                                                     FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                     ))         
        TRUNCATE TABLE #Temp3       
        INSERT INTO #Temp3        
        EXEC _SLGInOutDailyItemSave         
             @xmlDocument  = @XmlData,           
             @xmlFlags     = 2,           
             @ServiceSeq   = 2619,           
             @WorkingTag   = '',           
             @CompanySeq   = @CompanySeq,           
             @LanguageSeq  = 1,           
             @UserSeq      = 1,           
             @PgmSeq       = 1021351    
        
        IF EXISTS (SELECT 1 FROM #Temp3 WHERE Status <> 0)
        BEGIN
            ROLLBACK 
            
            UPDATE B        
               SET B.ProcYn = '2', 
                   B.ErrorMessage = '전함 이동처리 오류'
              FROM #BaseData AS A         
              JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
            
            GOTO GOEND;
        
        END 
        
        -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
        INSERT INTO KPX_TPDSFCProdPackReportRelation       
        (      
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
        )      
        SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 2, InOutType2,       
               InOutSeq, 1, 1, GETDATE()       
          FROM #LotReplace       
         WHERE WorkingTag = 'A'       
              
          --select * from KPX_TPDSFCProdPackReportRelation       
              
        --return       
        --select * from _TLGInOutDailyItem where CompanySeq = 1 and InOutType = 310         
        --select * from _TLGInOutDailyItem where CompanySeq = 1 and InOutType = 80         
        --return         
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 전함바 데이터 Lot 대체 , 이동처리, END         
        --------------------------------------------------------------------------------------------------------------------------------         
              
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 전함바가 아닌 데이터 Lot 대체, 이동처리         
        --------------------------------------------------------------------------------------------------------------------------------         
              
        SELECT @Qty = ISNULL(A.ProdQty,0) + (ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0)) - ISNULL(B.UseQty,0),         
               @UMProgType = ISNULL(C.UMProgType,0),         
               @FactUnit = A.FactUnit,         
               @RealLotNo = A.RealLotNo,         
               @ItemSeq = A.GoodItemSeq,         
               @HambaQty = A.HambaQty,         
               @DrainQty = A.DrainQty,       
               @WorkingTag_Sub = A.WorkingTag,       
               @WorkOrderSeq = A.WorkOrderSeq,       
               @WorkOrderSerl = A.WorkOrderSerl,     
               @WorkEndDate = A.WorkEndDate, 
               @NormalWH = D.InWHSeq , 
               @NormalOutWH = D.OutWHSeq 
          FROM #BaseData AS A         
          OUTER APPLY (SELECT SUM(Z.UseQty) AS UseQty         
                         FROM KPX_TPDPackingHanbaInPut_POP AS Z         
                        WHERE Z.CompanySeq = @CompanySeq         
                          AND Z.WorkOrderSeq = A.WorkOrderSeq         
                          AND Z.WorkOrderSerl = A.WorkOrderSerl         
                          AND Z.IsPacking = A.IsPacking         
                      ) AS B         
          LEFT OUTER JOIN KPX_TPDSFCWorkOrder_POP AS C ON ( C.CompanySeq = @CompanySeq         
                                                        AND C.WorkOrderSeq = A.WorkOrderSeq         
                                                        AND C.WorkOrderSerl = A.WorkOrderSerl         
                                                        AND C.IsPacking = A.IsPacking         
                                                          )         
          LEFT OUTER JOIN KPX_TPDSFCProdPackOrder AS D ON ( D.CompanySeq = @CompanySeq AND D.PackOrderSeq = A.WorkOrderSeq ) 
        
        SELECT @HambaWH = (SELECT TOP 1 WHSeq         
                                  FROM _TDAWH AS Z         
                                 WHERE Z.CompanySeq = @CompanySeq         
                                   AND Z.FactUnit = @FactUnit         
                                   AND Z.WMSCode = 4       
                               ) -- 함바창고 
        
        SELECT @DrainWH = (SELECT TOP 1 WHSeq         
                                  FROM _TDAWH AS Z         
                                 WHERE Z.CompanySeq = @CompanySeq         
                                AND Z.FactUnit = @FactUnit         
                                   AND Z.WMSCode = 5       
                               ) -- 드레인 창고 
        
        
        --return 
        IF @UMProgType = 1010345001 -- 공정 
        BEGIN         
            TRUNCATE TABLE #LotReplace2       
            INSERT INTO #LotReplace2         
            (        
                WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                BizUnit,        Qty,            InOutType2, InWHSeq2,   WorkOrderSeq,       
                WorkOrderSerl       
                      
            )        
            SELECT @WorkingTag_Sub, @RealLotNo, B.LotNo, @ItemSeq, 310,         
                     0, '', @NormalOutWH, @NormalOutWH, @WorkEndDate,         
                   A.BizUnit, @Qty, 80, @NormalWH, @WorkOrderSeq,       
                   @WorkOrderSerl       
              FROM _TDAWH AS A         
              OUTER APPLY (SELECT TOP 1 LotNo         
                             FROM _TLGInoutLotStock AS Z         
                            WHERE Z.CompanySeq = @CompanySeq         
                              AND Z.WHSeq = A.WHSeq         
                          ) AS B                
             WHERE A.CompanySeq = @CompanySeq         
               AND A.WHSeq = @NormalOutWH 
            
            -- Seq, No 채번             
                  
            SELECT @BizUnit = MAX(BizUnit),              
                   @Date    = MAX(InOutDate)        
              FROM #LotReplace2         
                    
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace2)         
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'      
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                    
                  
            -- Temp Talbe 에 생성된 키값 UPDATE       
            UPDATE #LotReplace2              
               SET InOutSeq = @Seq + IDX_NO         
              FROM #LotReplace2       
             WHERE WorkingTag = 'A'       
                  
            -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
            UPDATE A       
               SET InOutSeq = B.InOutSeq      
              FROM #LotReplace2 AS A       
              JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                       AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                       AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                       AND B.DataKind = 3       
                                                                         )      
             WHERE A.WorkingTag IN ( 'U', 'D' )       
                  
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
            BEGIN       
                SELECT @Cnt = 1         
                     
                WHILE ( 1 = 1 )         
                BEGIN         
                    exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                            
                    UPDATE #LotReplace2              
                       SET InOutNo = @MaxNo         
                      WHERE IDX_NO = @Cnt        
                            
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace2)         
                      BEGIN                             BREAK         
                    END         
                    ELSE         
                    BEGIN        
                        SELECT @Cnt = @Cnt + 1         
                    END         
                END         
            END       
              
            -- Seq, No 채번,END         
                    

            -- 전함바가 아닌 데이터 Lot 대체         
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq AS InWHSeq,         
                                                              A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정       
                                                              A.InOutType         
                                                          FROM #LotReplace2 AS A       
                                                         WHERE A.Qty <> 0       
                                                         FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
                  
            TRUNCATE TABLE #Temp11       
            INSERT INTO #Temp11         
             EXEC _SLGInOutDailySave         
                  @xmlDocument  = @XmlData,           
                  @xmlFlags     = 2,           
                  @ServiceSeq   = 2619,           
                  @WorkingTag   = '',           
                  @CompanySeq   = @CompanySeq,           
                  @LanguageSeq  = 1,           
                  @UserSeq      = 1,           
                  @PgmSeq       = 1021351    
                    
            --select * from _TLGInOutDaily where InOutType = 310         
                    
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              1 AS InOutSerl,         
                                                              A.InOutType,         
                                                              A.ItemSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq AS InWHSeq,         
                                                              A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정       
                                                              B.UnitSeq,          
                                                              A.Qty,         
                                                              A.Qty AS STDQty,         
                                                              8023042 AS InOutKind,         
                                                              A.LotNo AS OriLotNo,         
                                                              A.RealLotNo AS LotNo,         
                                                              0 AS InOutDetailKind        
                                                          FROM #LotReplace2 AS A         
                                                            LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                         WHERE A.Qty <> 0       
                                                           FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
            TRUNCATE TABLE #Temp12       
            INSERT INTO #Temp12        
            EXEC _SLGInOutDailyItemSave         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
            
            IF EXISTS (SELECT 1 FROM #Temp12 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '전함바가 아닌 데이터 Lot 대체 오류'     
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END 
            
            -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
            INSERT INTO KPX_TPDSFCProdPackReportRelation       
            (      
                CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
                InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
            )      
            SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 3, InOutType,       
                   InOutSeq, 1, 1, GETDATE()       
              FROM #LotReplace2       
             WHERE WorkingTag = 'A'       
          
      
            -- Seq, No 채번             
                    
            SELECT @BizUnit = MAX(BizUnit),              
                   @Date    = MAX(InOutDate)        
              FROM #LotReplace2         
                    
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace2)         
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                    
                 
            -- Temp Talbe 에 생성된 키값 UPDATE       
            UPDATE #LotReplace2              
               SET InOutSeq = @Seq + IDX_NO         
              FROM #LotReplace2       
             WHERE WorkingTag = 'A'       
                  
            -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
            UPDATE A       
               SET InOutSeq = B.InOutSeq      
              FROM #LotReplace2 AS A       
              JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                       AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                       AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                       AND B.DataKind = 4       
                                                                         )      
             WHERE A.WorkingTag IN ( 'U', 'D' )       
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
            BEGIN       
                SELECT @Cnt = 1         
                     
                WHILE ( 1 = 1 )         
                BEGIN         
                    exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                            
                    UPDATE #LotReplace2              
                       SET InOutNo = @MaxNo         
                      WHERE IDX_NO = @Cnt        
                            
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace2)         
                    BEGIN         
                        BREAK         
                    END         
                    ELSE         
                    BEGIN        
                        SELECT @Cnt = @Cnt + 1         
                    END         
                END         
            END       
                
            -- Seq, No 채번,END         
                    
                    
    
            --select * from #LotReplace2         
                    
            --select * from _TDAWH where WHSeq = 5         
                    
            --return         
            -- 전함바가 아닌 데이터 이동 처리         
            -- 일반창고 -> 제품창고         
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate, 
                                                              A.OutWHSeq, 
                                                              @NormalWH AS InWHSeq,         
                                                              A.InOutType2 AS InOutType         
                                                          FROM #LotReplace2 AS A         
                                                         WHERE A.Qty - @HambaQty - @DrainQty <> 0       
                                                         FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
                    
            TRUNCATE TABLE #Temp11       
            INSERT INTO #Temp11         
             EXEC _SLGInOutDailySave         
                  @xmlDocument  = @XmlData,           
                  @xmlFlags     = 2,           
                  @ServiceSeq   = 2619,           
                  @WorkingTag   = '',           
                  @CompanySeq   = @CompanySeq,           
                  @LanguageSeq  = 1,           
                  @UserSeq      = 1,           
                  @PgmSeq       = 1021351    
                
            
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              1 AS InOutSerl,         
                                                              A.InOutType2 AS InOutType,         
                                                              A.ItemSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq,         
                                                              @NormalWH AS InWHSeq,         
                                                              B.UnitSeq,          
                                                              A.Qty - @HambaQty - @DrainQty AS Qty,         
                                                              A.Qty - @HambaQty - @DrainQty AS STDQty,         
                                                              8023008 AS InOutKind,         
                                                              A.RealLotNo AS OriLotNo,         
                                                              A.RealLotNo AS LotNo,         
                                                              0 AS InOutDetailKind,         
                                                              0 AS Amt        
                                                          FROM #LotReplace2 AS A         
                                                          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                         WHERE A.Qty - @HambaQty - @DrainQty <> 0       
                                                         FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
                
                  
            TRUNCATE TABLE #Temp12       
            INSERT INTO #Temp12        
            EXEC _SLGInOutDailyItemSave         
                   @xmlDocument  = @XmlData,            
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
            
            IF EXISTS (SELECT 1 FROM #Temp12 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '전함바가 아닌 데이터 이동 처리 오류(일반창고 -> 제품창고)'     
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END 
                  
            -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
            INSERT INTO KPX_TPDSFCProdPackReportRelation       
            (      
                CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
                InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
            )      
            SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 4, InOutType2,       
                   InOutSeq, 1, 1, GETDATE()       
              FROM #LotReplace2       
             WHERE WorkingTag = 'A'       
                  
            -- Seq, No 채번             
                    
            SELECT @BizUnit = MAX(BizUnit),              
                   @Date    = MAX(InOutDate)        
              FROM #LotReplace2         
                    
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace2)      
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A') AND @HambaQty <> 0       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                  
            IF @HambaQty <> 0       
            BEGIN       
                 
                -- Temp Talbe 에 생성된 키값 UPDATE       
                UPDATE #LotReplace2              
                   SET InOutSeq = @Seq + IDX_NO         
                  FROM #LotReplace2       
                 WHERE WorkingTag = 'A'       
                      
                -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
                UPDATE A       
                   SET InOutSeq = B.InOutSeq      
                  FROM #LotReplace2 AS A       
                  JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                           AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                           AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                           AND B.DataKind = 5       
                                                                             )      
                 WHERE A.WorkingTag IN ( 'U', 'D' )       
                           
                      
                IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
                BEGIN       
                  SELECT @Cnt = 1         
                         
                    WHILE ( 1 = 1 )         
                      BEGIN          
                        exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                                
                        UPDATE #LotReplace2              
                           SET InOutNo = @MaxNo         
                          WHERE IDX_NO = @Cnt        
                                
                        IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace2)         
                        BEGIN         
                            BREAK         
                        END         
                        ELSE         
                        BEGIN        
                            SELECT @Cnt = @Cnt + 1         
                        END         
                    END         
                END       
                    
                -- Seq, No 채번,END         
                        
                -- 일반창고 -> 함바창고      
                SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                                  A.IDX_NO,         
                                                                  A.IDX_NO AS DataSeq,         
                                                                  1 AS Selected,         
                                                                  0 AS Status,         
                                                                  A.InOutSeq,         
                                                                  A.BizUnit,         
                                                                  A.InOutNo,         
                                                                  0 AS DeptSeq,         
                                                                  1 AS EmpSeq,         
                                                                  A.InOutDate,         
                                                                  A.OutWHSeq,         
                                                                  @HambaWH AS InWHSeq,         
                                                                  A.InOutType2 AS InOutType         
                                                              FROM #LotReplace2 AS A       
                                                             WHERE @HambaQty <> 0       
                                                             FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                              ))         
                        
                TRUNCATE TABLE #Temp11       
                INSERT INTO #Temp11         
                 EXEC _SLGInOutDailySave         
                      @xmlDocument  = @XmlData,           
                      @xmlFlags     = 2,           
                      @ServiceSeq   = 2619,           
                      @WorkingTag   = '',           
                      @CompanySeq   = @CompanySeq,           
                      @LanguageSeq  = 1,           
                      @UserSeq      = 1,           
                      @PgmSeq       = 1021351    
                    
                SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                                  A.IDX_NO,         
                                                                  A.IDX_NO AS DataSeq,         
                                                                  1 AS Selected,         
                                                                  0 AS Status,         
                                                                  A.InOutSeq,         
                                                                  1 AS InOutSerl,         
                                                                  A.InOutType2 AS InOutType,         
                                                                  A.ItemSeq,         
                                                                  A.BizUnit,         
                                                                  A.InOutNo,         
                                                                  0 AS DeptSeq,         
                                                                  1 AS EmpSeq,         
                                                                  A.InOutDate,         
                                                                  A.OutWHSeq,         
                                                                  @HambaWH AS InWHSeq,         
                                                                  B.UnitSeq,          
                                                                  @HambaQty AS Qty,         
                                                                  @HambaQty AS STDQty,         
                                                                  8023008 AS InOutKind,         
                                                                  A.RealLotNo AS OriLotNo,         
                                                                  A.RealLotNo AS LotNo,         
                                                                  0 AS InOutDetailKind,         
                                                                  0 AS Amt        
                                                              FROM #LotReplace2 AS A       
                                                             LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                            WHERE @HambaQty <> 0       
                                                             FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                              ))         
                
                TRUNCATE TABLE #Temp12       
                INSERT INTO #Temp12        
                EXEC _SLGInOutDailyItemSave         
                     @xmlDocument  = @XmlData,           
                     @xmlFlags     = 2,           
                     @ServiceSeq   = 2619,           
                     @WorkingTag   = '',           
                     @CompanySeq   = @CompanySeq,           
                     @LanguageSeq  = 1,           
                     @UserSeq      = 1,           
                     @PgmSeq       = 1021351    
                
                IF EXISTS (SELECT 1 FROM #Temp12 WHERE Status <> 0)
                BEGIN
                    ROLLBACK 
                    
                    UPDATE B        
                       SET B.ProcYn = '2', 
                           B.ErrorMessage = '전함바가 아닌 데이터 이동 처리 오류(일반창고 -> 함바창고)'     
                      FROM #BaseData AS A         
                      JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                    
                    GOTO GOEND;
                
                END 
                
                -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
                INSERT INTO KPX_TPDSFCProdPackReportRelation       
                (      
                    CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
                    InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
                )      
                SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 5, InOutType2,       
                       InOutSeq, 1, 1, GETDATE()       
                  FROM #LotReplace2       
                 WHERE WorkingTag = 'A'       
            END       
                  
                  
            -- Seq, No 채번             
                  
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace2)         
                  
            IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A') AND @DrainQty <> 0       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                    
            IF @DrainQty <> 0       
            BEGIN       
                -- Temp Talbe 에 생성된 키값 UPDATE       
                UPDATE #LotReplace2              
                   SET InOutSeq = @Seq + IDX_NO         
                  FROM #LotReplace2       
                 WHERE WorkingTag = 'A'       
                      
                -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
                UPDATE A       
                   SET InOutSeq = B.InOutSeq      
                  FROM #LotReplace2 AS A       
                  JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                  AND B.WorkOrderSeq = A.WorkOrderSeq       
                                 AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                           AND B.DataKind = 6       
                                                                             )      
                 WHERE A.WorkingTag IN ( 'U', 'D' )       
                           
                      
                IF EXISTS (SELECT 1 FROM #LotReplace2 WHERE WorkingTag = 'A')       
                BEGIN       
                    SELECT @Cnt = 1         
                         
                    WHILE ( 1 = 1 )         
                    BEGIN         
                          exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                                
                        UPDATE #LotReplace2              
                           SET InOutNo = @MaxNo         
                          WHERE IDX_NO = @Cnt        
                                
                        IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace2)         
                        BEGIN         
                            BREAK         
                        END         
                        ELSE         
                        BEGIN        
                            SELECT @Cnt = @Cnt + 1         
                        END         
                    END         
                END       
                      
                -- 일반창고 -> 드레인창고      
                SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                                  A.IDX_NO,         
                                                                  A.IDX_NO AS DataSeq,         
                                                                  1 AS Selected,         
                                                                  0 AS Status,         
                                                                  A.InOutSeq,         
                                                                  A.BizUnit,         
                                                                  A.InOutNo,         
                                                                  0 AS DeptSeq,         
                                                                  1 AS EmpSeq,         
                                                                  A.InOutDate,         
                                                                  A.OutWHSeq,         
                                                                  @DrainWH AS InWHSeq,         
                                                                  A.InOutType2 AS InOutType         
                                                              FROM #LotReplace2 AS A       
                                                             WHERE @DrainQty <> 0       
                                                             FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                              ))         
                        
                TRUNCATE TABLE #Temp11       
                INSERT INTO #Temp11         
                EXEC _SLGInOutDailySave         
                      @xmlDocument  = @XmlData,           
                      @xmlFlags     = 2,           
                      @ServiceSeq   = 2619,           
                      @WorkingTag   = '',           
                      @CompanySeq   = @CompanySeq,           
                      @LanguageSeq  = 1,           
                      @UserSeq      = 1,           
                      @PgmSeq       = 1021351    
                    
                SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                                  A.IDX_NO,         
                                                                  A.IDX_NO AS DataSeq,         
                                                                  1 AS Selected,         
                                                                  0 AS Status,         
                                                                  A.InOutSeq,         
                                                                  1 AS InOutSerl,         
                                                                  A.InOutType2 AS InOutType,         
                                                                  A.ItemSeq,         
                                                                  A.BizUnit,         
                                                                  A.InOutNo,         
                                                                    0 AS DeptSeq,          
                                                                  1 AS EmpSeq,         
                                                                  A.InOutDate,         
                                                                  A.OutWHSeq,         
                                                                  @DrainWH AS InWHSeq,         
                                                                  B.UnitSeq,          
                                                                  @DrainQty AS Qty,         
                                                                  @DrainQty AS STDQty,         
                                                                  8023008 AS InOutKind,         
                                                                  A.RealLotNo AS OriLotNo,         
                                                                  A.RealLotNo AS LotNo,         
                                                                  0 AS InOutDetailKind,         
                                                                  0 AS Amt        
                                                              FROM #LotReplace2 AS A       
                                                             LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                            WHERE @DrainQty <> 0       
                                                             FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                              ))         
                
                TRUNCATE TABLE #Temp12       
                INSERT INTO #Temp12        
                EXEC _SLGInOutDailyItemSave         
                     @xmlDocument  = @XmlData,           
                     @xmlFlags     = 2,           
                     @ServiceSeq   = 2619,           
                     @WorkingTag   = '',           
                     @CompanySeq   = @CompanySeq,           
                     @LanguageSeq  = 1,           
                     @UserSeq      = 1,           
                     @PgmSeq       = 1021351    
                      
                -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
                INSERT INTO KPX_TPDSFCProdPackReportRelation       
                (      
                    CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
                    InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
                )      
                SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 6, InOutType2,       
                       InOutSeq, 1, 1, GETDATE()       
                  FROM #LotReplace2       
                 WHERE WorkingTag = 'A'       
            END       
            --select * From _TLGInOutDailyItem where InOutType = 80         
            --select * From _TLGInOutDailyItem where InOutType = 310        
      
          
            IF EXISTS (SELECT 1 FROM #Temp12 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '전함바가 아닌 데이터 이동 처리 오류(일반창고 -> 드레인창고)'     
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END 
                
        END         
        ELSE IF @UMProgType = 1010345002      
        BEGIN        
                  
            TRUNCATE TABLE #GetInOutLot      
            INSERT INTO #GetInOutLot ( LotNo, ItemSeq )         
            SELECT DISTINCT B.LotNo, A.GoodItemSeq        
              FROM #BaseData    AS A         
              JOIN _TLGLotStock AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq )         
            
            
            SELECT @BizUnit = C.BizUnit, 
                   @WHSeq = B.OutWHSeq 
              FROM #BaseData AS A 
              LEFT OUTER JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq ) 
              LEFT OUTER JOIN _TDAWH AS C ON ( C.CompanySeq = @CompanySeq AND C.WHSeq = B.OutWHSeq ) 
            
             -- SELECT @BizUnit = MAX(BizUnit),          
             --      @WHSeq = MAX(Z.WHSeq)         
             -- FROM _TDAWH AS Z         
             --WHERE Z.CompanySeq = @CompanySeq         
             --  AND Z.WMSCode = 1         
             --  AND Z.FactUnit = @FactUnit         
            
            
            --select 'test2', @BizUnit, @WHSeq 
            
            
            --return 
            
            DECLARE @DateFr NCHAR(8)         
                 
            SELECT @DateFr = CONVERT(NCHAR(8),GETDATE(),112)         
            
            TRUNCATE TABLE #GetInOutLotStock 
            -- 창고재고 가져오기              
            EXEC _SLGGetInOutLotStock @CompanySeq   = @CompanySeq,   -- 법인코드              
                                      @BizUnit      = @BizUnit,      -- 사업부문              
                                      @FactUnit     = @FactUnit,     -- 생산사업장              
                                      @DateFr       = @DateFr,       -- 조회기간Fr              
                                      @DateTo       = @DateFr,       -- 조회기간To              
                                      @WHSeq        = @WHSeq,        -- 창고지정              
                                      @SMWHKind     = 0,     -- 창고구분별 조회              
                                      @CustSeq      = 0,      -- 수탁거래처              
                                      @IsTrustCust  = '0',  -- 수탁여부              
                                      @IsSubDisplay = '0', -- 기능창고 조회              
                                      @IsUnitQry    = '0',    -- 단위별 조회              
                                      @QryType      = 'S'       -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고           
            
            TRUNCATE TABLE #GetInOutLotStock_Sub      
            INSERT INTO #GetInOutLotStock_Sub       
            SELECT B.RegDate, A.*       
              FROM #GetInOutLotStock AS A         
              LEFT OUTER JOIN _TLGLotMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.LotNo = A.LotNo )         
             WHERE A.StockQty > 0       
             ORDER BY B.RegDate DESC        
                    
            SELECT @OriQty = @Qty       
                   
            SELECT @Cnt = 1         
                  
            TRUNCATE TABLE #LotReplace3      
            
            
            IF (SELECT @Qty) > (SELECT ISNULL(SUM(StockQty),0) FROM #GetInOutLotStock_Sub)
            BEGIN 
                ROLLBACK    
                  
                UPDATE B          
                   SET B.ProcYn = '2',   
                       B.ErrorMessage = '전함바가 아닌 데이터 Lot 대체 오류'      
                  FROM #BaseData AS A           
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )        
                
                GOTO GOEND;  
            END 
            
            --select * from _TDAWH where companyseq = 1 and wmscode =2 and factunit = 1 
            
            --select * from #BaseData 
            --select * from KPX_TPDSFCProdPackOrder where companyseq = 1 and packorderseq = 533 
            --select * from #GetInOutLotStock_Sub 
            
            
            --return 
            
            IF EXISTS (SELECT 1 FROM #GetInOutLotStock_Sub)
            BEGIN
                WHILE ( 1 = 1 )         
                BEGIN        
                            
                    SELECT @StockQty = StockQty,         
                           @LotNo = LotNo,         
                           @WHSeq = WHSeq,         
                           @InOutType = 310,         
                           @InOutType2 = 80,         
                           @InWHSeq2 = (SELECT TOP 1 B.InWHSeq 
                                          FROM #BaseData AS A 
                                          LEFT OUTER JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq ) 
                                       )         
                                   
                      FROM #GetInOutLotStock_Sub         
                     WHERE IDX_NO = @Cnt         
                    
                    INSERT INTO #LotReplace3         
                    (        
                        WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                        InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                        BizUnit,        Qty,            InOutType2, InWHSeq2,   WorkOrderSeq,       
                        WorkOrderSerl      
                    )        
                    SELECT @WorkingTag_Sub, @RealLotNo, @LotNo, @ItemSeq, @InOutType,         
                           0, '', @WHSeq, @WHSeq, @WorkEndDate,         
                           @BizUnit, CASE WHEN @Qty >= @StockQty THEN (CASE WHEN @StockQty < 0 THEN 0 ELSE @StockQty END) ELSE @Qty END, @InOutType2, @InWHSeq2, @WorkOrderSeq,       
                           @WorkOrderSerl       
                          
                    SELECT @Qty = @Qty - @StockQty         
                            
                    IF @Qty <= 0 OR @Cnt = (SELECT MAX(IDX_NO) FROM #GetInOutLotStock_Sub)         
                    BEGIN         
                        BREAK         
                    END         
                    ELSE         
                    BEGIN        
                        SELECT @Cnt = @Cnt + 1         
                    END         
                END         
            END 
            --select * from #LotReplace3       
                  
            -- Seq, No 채번             
                  
            SELECT @BizUnit = MAX(BizUnit),              
                   @Date    = MAX(InOutDate)        
              FROM #LotReplace3         
                    
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace3)         
                  
            IF EXISTS (SELECT 1 FROM #LotReplace3 WHERE WorkingTag = 'A')       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                    
                  
            -- Temp Talbe 에 생성된 키값 UPDATE       
            UPDATE #LotReplace3              
               SET InOutSeq = @Seq + IDX_NO         
              FROM #LotReplace3       
             WHERE WorkingTag = 'A'       
                  
            -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
            UPDATE A       
               SET InOutSeq = B.InOutSeq      
              FROM #LotReplace3 AS A       
              JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                       AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                       AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                       AND B.DataKind = 7       
                                                                         )      
             WHERE A.WorkingTag IN ( 'U', 'D' )       
                  
            IF EXISTS (SELECT 1 FROM #LotReplace3 WHERE WorkingTag = 'A')        
            BEGIN       
                SELECT @Cnt = 1         
                      
                WHILE ( 1 = 1 )         
                BEGIN         
                    exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                            
                    UPDATE #LotReplace3              
                       SET InOutNo = @MaxNo         
                      WHERE IDX_NO = @Cnt        
                            
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace3)         
                    BEGIN         
                        SELECT @Qty = @OriQty      
                        BREAK         
                    END         
                    ELSE         
                    BEGIN        
                        SELECT @Cnt = @Cnt + 1         
                    END         
                END         
            END       
                    
            -- Seq, No 채번,END        
        
    
        
        --return 
            -- Lot 대체         
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,                                                                   
                                                              A.InOutDate,         
                                                              A.OutWHSeq AS InWHSeq,         
                                                              A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정       
                                                              A.InOutType         
                                                         FROM #LotReplace3 AS A         
                                                         WHERE A.Qty <> 0       
                                                         FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
            TRUNCATE TABLE #Temp21       
            INSERT INTO #Temp21         
            EXEC _SLGInOutDailySave         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
    
    

            --select * from _TLGInOutDaily where InOutType = 310         
    
        --select *from #LotReplace3 
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              1 AS InOutSerl,         
                                                              A.InOutType,         
                                                              A.ItemSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq AS InWHSeq,         
                                                              A.InWHSeq AS OutWHSeq,   -- Lot 대체 창고 바뀌어 적용되어 있어서 수정       
                                                              B.UnitSeq,          
                                                              A.Qty,         
                                                              A.Qty AS STDQty,         
                                                              8023042 AS InOutKind,         
                                                              A.LotNo AS OriLotNo,         
                                                              A.RealLotNo AS LotNo,         
                                                              0 AS InOutDetailKind        
                                                          FROM #LotReplace3 AS A         
                                                          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                         WHERE A.Qty <> 0       
                                                         FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
                    
            TRUNCATE TABLE #Temp22       
            INSERT INTO #Temp22        
            EXEC _SLGInOutDailyItemSave         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
            
            IF EXISTS (SELECT 1 FROM #Temp22 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '전함바가 아닌 데이터 Lot 대체 오류'    
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END 
            
    --select * from _TLGInOutDaily where InoutSeq = 1307269
    --select * from _TLGInOutDailyItem where InoutSeq = 1307269
    
    --return 
            -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
            INSERT INTO KPX_TPDSFCProdPackReportRelation       
            (      
                CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
                InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
            )      
            SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 7, InOutType,       
                   InOutSeq, 1, 1, GETDATE()       
              FROM #LotReplace3       
             WHERE WorkingTag = 'A'       
                       
                  
            TRUNCATE TABLE #LotReplace3_Sub       
            TRUNCATE TABLE #LotReplace3_Sub_Sub     
            IF @HambaQty >= 0       
            BEGIN       
                SELECT @Cnt = 1       
                      
                WHILE ( 1 = 1 )         
                        
                BEGIN        
                          
                    IF @HambaQty >= (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt)       
                    BEGIN       
                              
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind ,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        Qty,            InOutType2, @HambaWH,   1 ,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3       
                         WHERE IDX_NO = @Cnt       
                              
                    END       
                    
                    IF @HambaQty < (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt)        
                    BEGIN       
      
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        @HambaQty,      InOutType2, @HambaWH,   1,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3       
                         WHERE IDX_NO = @Cnt       
                           AND @HambaQty > 0       
                              
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        Qty - @HambaQty,            InOutType2, @InWHSeq2,   3,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3       
                         WHERE IDX_NO = @Cnt       
                               
                    END        
                    
    
                    INSERT INTO #LotReplace3_Sub_Sub       
                    (        
                        WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                        InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                        BizUnit,        Qty,             InOutType2, InWHSeq2,   Kind,       
                        WorkOrderSeq,   WorkOrderSerl       
                    )        
                    SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                           InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                           BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                           WorkOrderSeq,   WorkOrderSerl       
                      FROM #LotReplace3_Sub AS A       
                     WHERE A.Kind = 3       
                       AND A.IDX_NO = @Cnt    
                      
                    DELETE FROM #LotReplace3_Sub WHERE Kind = 3       
                    
                    
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace3)       
                    BEGIN       
                        BREAK       
                    END       
                    ELSE      
                    BEGIN        
                        IF @HambaQty - (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt) > 0       
                        BEGIN       
                            SELECT @HambaQty = @HambaQty - (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt)        
                        END       
                        ELSE       
                        BEGIN       
                            SELECT @HambaQty = 0       
                        END       
                              
                        SELECT @Cnt = @Cnt + 1       
                    END       
                        
                END         
            END -- if       
              
        --select * From #LotReplace3_Sub_Sub    
            
        --return     
                  
                  
            IF @DrainQty >= 0 AND EXISTS (SELECT 1 FROM #LotReplace3_Sub_Sub)      
            BEGIN       
                SELECT @Cnt = 1       
                      
                WHILE ( 1 = 1 )         
                        
                BEGIN        
                          
                    IF @DrainQty >= (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt)       
                    BEGIN       
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        Qty,            InOutType2, @DrainWH,   2,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3_Sub_Sub       
                           WHERE IDX_NO = @Cnt       
                    END       
                          
      
                    IF @DrainQty < (SELECT Qty FROM #LotReplace3 WHERE IDX_NO = @Cnt)        
                    BEGIN       
      
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        @DrainQty,      InOutType2, @DrainWH,   1,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3_Sub_Sub       
                         WHERE IDX_NO = @Cnt       
                           AND @DrainQty > 0       
                              
                        INSERT INTO #LotReplace3_Sub       
                        (        
                            WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                            InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                            BizUnit,        Qty,            InOutType2, InWHSeq2,   Kind,       
                            WorkOrderSeq,   WorkOrderSerl       
                        )        
                        SELECT WorkingTag,     RealLotNo,      LotNo,      ItemSeq,    InOutType,              
                               InOutSeq,       InOutNo,        OutWHSeq,   InWHSeq,    InOutDate,          
                               BizUnit,        Qty - @DrainQty,            InOutType2, @InWHSeq2,   3,       
                               WorkOrderSeq,   WorkOrderSerl       
                          FROM #LotReplace3_Sub_Sub       
                         WHERE IDX_NO = @Cnt       
                               
                    END       
                          
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace3_Sub_Sub)       
                    BEGIN       
                        BREAK       
                    END       
                    ELSE      
                    BEGIN        
                        IF @DrainQty - (SELECT Qty FROM #LotReplace3_Sub_Sub WHERE IDX_NO = @Cnt) > 0       
                        BEGIN       
                            SELECT @DrainQty = @DrainQty - (SELECT Qty FROM #LotReplace3_Sub_Sub WHERE IDX_NO = @Cnt)        
                        END       
                        ELSE       
                        BEGIN       
                            SELECT @DrainQty = 0       
                        END       
                              
                        SELECT @Cnt = @Cnt + 1       
                    END       
                        
                END       
            END -- if       
                
            --select * From #LotReplace3_Sub     
                
            TRUNCATE TABLE #LotReplace3_Sub_Sub      
            INSERT INTO #LotReplace3_Sub_Sub       
            SELECT WorkingTag, RealLotNo, LotNo, ItemSeq, InOutType,       
                   InOutSeq, InOutNo, OutWHSeq, InWHSeq, InOutDate,       
                   BizUnit, Qty, InOutType2, InWHSeq2, Kind,       
                   WorkOrderSeq, WorkOrderSerl       
             FROM #LotReplace3_Sub        
              
          --select * from #LotReplace3_Sub_Sub        
            --return       
            -- Seq, No 채번             
                            
            SELECT @BizUnit = MAX(BizUnit),              
                   @Date    = MAX(InOutDate)        
              FROM #LotReplace3         
                    
            SELECT @Count = (SELECT COUNT(1) FROM #LotReplace3)         
                  
            IF EXISTS (SELECT 1 FROM #LotReplace3_Sub_Sub WHERE WorkingTag = 'A')       
            BEGIN       
                DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
                -- 키값생성코드부분 시작                
                EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
            END       
                    
        --select * from #LotReplace3_Sub       
                  
            -- Temp Talbe 에 생성된 키값 UPDATE       
            UPDATE #LotReplace3_Sub_Sub              
               SET InOutSeq = @Seq + IDX_NO         
              FROM #LotReplace3_Sub_Sub       
             WHERE WorkingTag = 'A'       
                  
            -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
            UPDATE A       
               SET InOutSeq = B.InOutSeq      
              FROM #LotReplace3_Sub_Sub AS A       
              JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                       AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                       AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                       AND B.DataKind = 8      
                                                                  )      
             WHERE A.WorkingTag IN ( 'U', 'D' )       
          
            IF EXISTS (SELECT 1 FROM #LotReplace3_Sub_Sub WHERE WorkingTag = 'A')       
            BEGIN       
                SELECT @Cnt = 1         
                     
                WHILE ( 1 = 1 )         
                BEGIN         
                    exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                            
                    UPDATE #LotReplace3_Sub_Sub              
                       SET InOutNo = @MaxNo         
                      WHERE IDX_NO = @Cnt        
                            
                    IF @Cnt = (SELECT MAX(IDX_NO) FROM #LotReplace3_Sub_Sub)         
                    BEGIN         
                        BREAK         
                    END         
                    ELSE         
                    BEGIN        
                        SELECT @Cnt = @Cnt + 1         
                    END         
                END         
            END       
            -- Seq, No 채번,END         
    
    
--select * from #LotReplace3_Sub_Sub     
    
--return     
            -- 이동처리         
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq,         
                                                              A.InWHSeq2 AS InWHSeq,         
                                                              A.InOutType2 AS InOutType        
                                                          FROM #LotReplace3_Sub_Sub AS A         
                                                         WHERE A.Qty <> 0       
                                                         FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
               
            TRUNCATE TABLE #Temp21       
            INSERT INTO #Temp21         
            EXEC _SLGInOutDailySave         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
                  
                  
            --select * from _TLGInOutDaily where InOutType = 310         
            --return       
                  
            SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT WorkingTag,         
                                                              A.IDX_NO,         
                                                              A.IDX_NO AS DataSeq,         
                                                              1 AS Selected,         
                                                              0 AS Status,         
                                                              A.InOutSeq,         
                                                              1 AS InOutSerl,         
                                                              A.InOutType2 AS InOutType,         
                                                              A.ItemSeq,         
                                                              A.BizUnit,         
                                                              A.InOutNo,         
                                                              0 AS DeptSeq,         
                                                              1 AS EmpSeq,         
                                                              A.InOutDate,         
                                                              A.OutWHSeq,         
                                                              A.InWHSeq2 AS InWHSeq,         
                                                              B.UnitSeq,          
                                                              A.Qty,         
                                                              A.Qty AS STDQty,         
                                                              8023008 AS InOutKind,         
                                                              A.RealLotNo AS OriLotNo,         
                                                              A.RealLotNo AS LotNo,         
                                                              0 AS InOutDetailKind,       
                                                              0 AS Amt       
                                                          FROM #LotReplace3_Sub_Sub AS A         
                                                          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )         
                                                         WHERE A.Qty <> 0       
                                                         FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS           
                                                          ))         
                    
            INSERT INTO #Temp22        
            EXEC _SLGInOutDailyItemSave         
                 @xmlDocument  = @XmlData,           
                 @xmlFlags     = 2,           
                 @ServiceSeq   = 2619,           
                 @WorkingTag   = '',           
                 @CompanySeq   = @CompanySeq,           
                 @LanguageSeq  = 1,           
                 @UserSeq      = 1,           
                 @PgmSeq       = 1021351    
              
            IF EXISTS (SELECT 1 FROM #Temp22 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '전함바가 아닌 데이터 이동 처리 오류'    
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END   
          
            -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
            INSERT INTO KPX_TPDSFCProdPackReportRelation       
            (      
                  CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,        
                InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
            )      
            SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 8, InOutType2,       
                   InOutSeq, 1, 1, GETDATE()       
              FROM #LotReplace3_Sub_Sub      
             WHERE WorkingTag = 'A'       
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 전함바가 아닌 데이터 Lot 대체, END         
        --------------------------------------------------------------------------------------------------------------------------------         
        END       
          
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 용기 출고      
        --------------------------------------------------------------------------------------------------------------------------------         
        SELECT @Count = 0       
        SELECT @Count = (SELECT COUNT(1) FROM #SubTable)         
              
        IF EXISTS (SELECT 1 FROM #SubTable WHERE WorkingTag = 'A')       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            --키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END       
              
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE #SubTable              
           SET InOutSeq = @Seq + IDX_NO         
          FROM #SubTable       
         WHERE WorkingTag = 'A'       
              
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq            
          FROM #SubTable AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq       
                                                                   AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                                   AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                                   AND B.DataKind = 9       
                                                                     )      
        IF EXISTS (SELECT 1 FROM #SubTable WHERE WorkingTag = 'A')       
        BEGIN       
            SELECT @Cnt = 1         
                 
            WHILE ( 1 = 1 )         
            BEGIN         
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #SubTable              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #SubTable)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
              
              --update #SubTable
              --   set qty = 100 
              --  from  #SubTable 
        --select * From _TLGInOutDaily where  InoUtSeq = 1307276    
        --select * From _TLGInOutDailyItem where InoUtSeq = 1307276
              --return 
        -- 이동처리         
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag AS WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq,         
                                                          0 AS InWHSeq,         
                                                          A.InOutType      
                                                      FROM #SubTable AS A         
                                                     WHERE A.Qty <> 0       
                                                     FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                      ))         
              
        TRUNCATE TABLE #Temp21       
        INSERT INTO #Temp21         
        EXEC _SLGInOutDailySave         
             @xmlDocument  = @XmlData,           
             @xmlFlags     = 2,           
             @ServiceSeq   = 2619,           
             @WorkingTag   = '',           
             @CompanySeq   = @CompanySeq,           
             @LanguageSeq  = 1,           
             @UserSeq      = 1,           
             @PgmSeq       = 1021351    
          
        --select * from #SubTable       
              
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag AS WorkingTag,         
                                                          A.IDX_NO,         
                                                          A.IDX_NO AS DataSeq,         
                                                          1 AS Selected,         
                                                          0 AS Status,         
                                                          A.InOutSeq,         
                                                          1 AS InOutSerl,         
                                                          A.InOutType AS InOutType,         
                                                          A.ItemSeq,         
                                                          A.BizUnit,         
                                                          A.InOutNo,         
                                                          0 AS DeptSeq,         
                                                          1 AS EmpSeq,         
                                                          A.InOutDate,         
                                                          A.OutWHSeq,         
                                                          0 AS InWHSeq,         
                                                          A.UnitSeq,          
                                                          A.Qty,         
                                                          A.Qty AS STDQty,         
                                                          8023003 AS InOutKind,         
                                                          '' AS OriLotNo,         
                                                          '' AS LotNo,         
                                                          8025007 AS InOutDetailKind,       
                                                          0 AS Amt       
                                                      FROM #SubTable AS A         
                                                     WHERE A.Qty <> 0       
                                                       FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS            
                                                      ))        
              
        TRUNCATE TABLE #Temp22      
        INSERT INTO #Temp22        
        EXEC _SLGInOutDailyItemSave         
             @xmlDocument  = @XmlData,           
             @xmlFlags     = 2,           
             @ServiceSeq   = 2619,           
             @WorkingTag   = '',           
             @CompanySeq   = @CompanySeq,           
             @LanguageSeq  = 1,           
             @UserSeq      = 1,           
             @PgmSeq       = 1021351    
        --select *from #SubTable       
              
            IF EXISTS (SELECT 1 FROM #Temp22 WHERE Status <> 0)
            BEGIN
                ROLLBACK 
                
                UPDATE B        
                   SET B.ProcYn = '2', 
                       B.ErrorMessage = '용기 출고 오류'    
                  FROM #BaseData AS A         
                  JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )      
                
                GOTO GOEND;
            
            END   
        -- 삭제, 수정 를 위한 연결고리 테이블에 데이터 넣어주기       
        INSERT INTO KPX_TPDSFCProdPackReportRelation       
        (      
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType,       
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime       
        )   
        SELECT @CompanySeq, WorkOrderSeq, WorkorderSerl, 9, InOutType,       
               InOutSeq, 1, 1, GETDATE()       
          FROM #SubTable      
         WHERE WorkingTag = 'A'       
        --------------------------------------------------------------------------------------------------------------------------------        
        -- 용기 출고, END       
        --------------------------------------------------------------------------------------------------------------------------------         
        
        -- 포장 실적 삭제시 로그       
        TRUNCATE TABLE #KPX_TPDSFCProdPackReportLog       
              
        INSERT INTO #KPX_TPDSFCProdPackReportLog ( WorkingTag, Status, PackReportSeq )       
        SELECT A.WorkingTag, 0, C.PackReportSeq      
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )       
          JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )       
          
        -- 마스터 로그         
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReport')          
                
        EXEC _SCOMLog @CompanySeq   ,              
                      1      ,              
                      'KPX_TPDSFCProdPackReport'    , -- 테이블명              
                      '#KPX_TPDSFCProdPackReportLog'    , -- 임시 테이블명              
                      'PackReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )              
                      @TableColumns , '', 1  -- 테이블 모든 필드명         
                            
        TRUNCATE TABLE #KPX_TPDSFCProdPackReportItemLog       
              
        INSERT INTO #KPX_TPDSFCProdPackReportItemLog ( WorkingTag, Status, PackReportSeq, PackReportSerl )       
        SELECT A.WorkingTag, 0, B.PackReportSeq, B.PackReportSerl      
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )       
              
        -- 디테일 로그         
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReportItem')          
                
        EXEC _SCOMLog @CompanySeq   ,              
                      1      ,              
                      'KPX_TPDSFCProdPackReportItem'    , -- 테이블명              
                      '#KPX_TPDSFCProdPackReportItemLog'    , -- 임시 테이블명              
                      'PackReportSeq,PackReportSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )              
                      @TableColumns , '', 1  -- 테이블 모든 필드명         
        
        DELETE C       
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )       
          JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )       
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
               
              
        DELETE B      
          FROM #BaseData AS A       
         JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )       
         WHERE A.WorkingTag IN ( 'U', 'D' ) 
        
        
        TRUNCATE TABLE #KPX_TPDSFCProdPackReport      
        INSERT INTO #KPX_TPDSFCProdPackReport       
        (      
            CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,       
            OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,       
            LastUserSeq       
        )      
        SELECT @CompanySeq, 0, A.FactUnit, WorkEndDate, '',       
               B.OutWHSeq, B.InWHSeq, B.UMProgType, B.SubOutWHSeq, B.Remark,       
               B.LastUserSeq      
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq )       
         WHERE A.WorkingTag IN ( 'U', 'A' ) 
              
        TRUNCATE TABLE #KPX_TPDSFCProdPackReportItem      
        INSERT INTO #KPX_TPDSFCProdPackReportItem       
        (      
            CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,       
            Qty, LotNo, OutLotNo, Remark, SubItemSeq,       
            SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,       
            LastUserSeq       
        )      
        SELECT @CompanySeq, 0, 0, A.GoodItemSeq, B.UnitSeq,       
               A.RealProdQty, B.LotNo, B.OutLotNo, B.Remark, B.SubItemSeq,       
               B.SubUnitSeq, ISNULL(C.Qty,0), A.HambaQty, A.WorkOrderSeq, A.WorkOrderSerl,       
               B.LastUserSeq      
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )       
          LEFT OUTER JOIN #SubTable         AS C ON ( C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.WorkingTag IN ( 'U', 'A' ) 
              
              
        SELECT @Seq = 0       
        -- 키값생성코드부분 시작      
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDSFCProdPackReport', 'PackReportSeq', 1      
              
              
        UPDATE A       
           SET PackReportSeq = @Seq + 1       
          FROM #KPX_TPDSFCProdPackReport AS A       
              
        UPDATE A       
           SET PackReportSeq = @Seq + 1,       
               PackReportSerl = IDX_NO      
          FROM #KPX_TPDSFCProdPackReportItem AS A        
            
            
        -- 번호 생성     
        IF EXISTS (SELECT 1 FROM #KPX_TPDSFCProdPackReport)    
        BEGIN     
            SELECT @BaseDate = PackDate     
              FROM #KPX_TPDSFCProdPackReport     
                
            EXEC dbo._SCOMCreateNo 'PD', 'KPX_TPDSFCProdPackReport', @CompanySeq, 0, @BaseDate, @ReportNo OUTPUT          
                
            UPDATE A     
               SET ReportNo = @ReportNo    
        FROM #KPX_TPDSFCProdPackReport AS A     
        END     
              
        INSERT INTO KPX_TPDSFCProdPackReport       
        (      
            CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,       
            OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,       
            LastUserSeq, LastDateTime       
        )      
        SELECT CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,       
               OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,       
               LastUserSeq, GETDATE()       
          FROM #KPX_TPDSFCProdPackReport       
                
        INSERT INTO KPX_TPDSFCProdPackReportItem       
        (      
            CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,       
            Qty, LotNo, OutLotNo, Remark, SubItemSeq,       
            SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,       
            LastUserSeq, LastDateTime      
        )      
        SELECT CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,       
                 Qty, LotNo, OutLotNo, Remark, SubItemSeq,       
               SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,       
               LastUserSeq, GETDATE()      
          FROM #KPX_TPDSFCProdPackReportItem      
    
        
        UPDATE B      
           SET B.ProcYn = '1'       
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCWorkReport_POP AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq )       
         --WHERE A.IDX_NO = @MainCount      
          
              
        -- Relation 테이블 삭제       
        DELETE B        
          FROM #BaseData AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WOrkOrderSerl       
                                                        )       
         WHERE A.WorkingTag = 'D'       
        
        COMMIT TRAN 
        
        GOEND: 
        
        IF @MainCount = (SELECT MAX(IDX_NO) FROM #BaseData_Sub)      
        BEGIN       
            BREAK       
        END       
        ELSE      
        BEGIN       
            SELECT @MainCount = @MainCount + 1       
        END       
              
    END       
          
    SELECT * FROM #BaseData_Sub      
        
RETURN        
go 
--begin tran 
--EXEC KPX_SPDSFCProdPackReportSave_POP @CompanySeq = 1 
--------select * from 

------select * From _TLGInOutDaily where companyseq = 1 and pgmseq= 1021351 
------select * From _TLGInOutDailyItem where companyseq = 1 and pgmseq= 1021351 
------select * from KPX_TPDSFCProdPackReportRelation 
------select * from KPX_TPDSFCProdPackReport 
------select * from KPX_TPDSFCProdPackReportItem

----------select * from _TLGInOutLotStock where companyseq = 1 and inoutseq = 7038

--rollback 

