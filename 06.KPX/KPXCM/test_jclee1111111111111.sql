drop proc test_jclee1111111111111

go

create proc test_jclee1111111111111

as 

delete From _TLGInOutDaily where companyseq = 2 and inoutseq = 8922632 and inouttype = 310 
delete From _TLGInOutDailyItem where companyseq = 2 and inoutseq = 8922632 and inouttype = 310 


 declare @Seq int, 
         @companyseq int, 
         @BizUnit int, 
         @Date  nchar(8), 
         @MaxNo nvarchar(100)

select @companyseq = 2 
      , @bizunit = 1
      
      
      
          CREATE TABLE #BaseData       
    (      
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )      
    
    -- 기초 데이터 
    INSERT INTO #BaseData 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq       , ProdQty, 
        RealLotNo, WorkEndDate                                  , HambaDrainQty, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubOutWHSeq              , SubQty, 
        UMProgType 
    )        
    SELECT 
           A.Seq, A.WorkingTag, C.FactUnit, A.IsPacking, A.WorkOrderSeq, 
           A.WorkOrderSerl, ISNULL(E.SourceSeq,0), ISNULL(E.SourceSerl,0), A.GoodItemSeq            , ISNULL(A.ProdQty ,0) - ISNULL(A.HambaQty,0) + ISNULL(A.BeforeHambaQty,0),
           A.RealLotNo, A.WorkEndDate                                                               , ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0), ISNULL(A.ProdQty,0), ISNULL(A.BeforeHambaQty,0),
           ISNULL(F.OutWHSeq,0), ISNULL(F.InWHSeq,0), E.SubItemSeq, ISNULL(F.SubOutWHSeq,0)         , ISNULL(A.SubQty,0)-ISNULL(A.RecycleQty,0), 
           F.UMProgType 
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
      --OUTER APPLY (  
      --              SELECT SUM(UseQty) AS UseQty 
      --                FROM KPX_TPDPackingHanbaInPut_POP AS Z   
      --               WHERE Z.CompanySeq = @CompanySeq   
      --                 AND Z.WorkOrderSeq = A.WorkOrderSeq   
      --                 AND Z.WorkOrderSerl = A.WorkOrderSerl   
      --           ) AS D 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS E ON ( E.CompanySeq = @CompanySeq AND E.PackOrderSeq = A.WorkOrderSeq AND E.PackOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder       AS F ON ( F.CompanySeq = @CompanySeq AND F.PackOrderSeq = E.PackOrderSeq ) 
    where A.CompanySeq  = @CompanySeq
and a.seq in (
1000088753
,1000088756
,1000088923
,1000088973
,1000089216
,1000089436
,1000089694
,1000089366
,1000089367
,1000089742
,1000090056
,1000089955
,1000089982
,1000089997
,1000090239
,1000090247
,1000090469
,1000090497
,1000090503
,1000090256
,1000090257
,1000090278
,1000090288
,1000090586
,1000090543
,1000090544
,1000090551
,1000090852
,1000090864
,1000090877
,1000090878
,1000090908
,1000090929
,1000091794
,1000091024
,1000091046
,1000091047
,1000091359
,1000091379
,1000091099
,1000091100
,1000091119
,1000091121
,1000091402
,1000091536
,1000091715
,1000091723
,1000091728
,1000091730
,1000091742
,1000091786
,1000091787
,1000091788
,1000092026
,1000092041
,1000091930
,1000092271
,1000092275
,1000092300
,1000092082
,1000092092
,1000092463
,1000092494
,1000092330
,1000092547
,1000092549
,1000092581
,1000092592
,1000092602
,1000092783
,1000092648
,1000092649
,1000092651
,1000092688
,1000092767
,1000092769
) 
       
     ORDER BY A.Seq     
    
 
 --select * from #BaseData 




 declare @count int , 
         @Cnt   int 

 select @count = (select count(1) from #BaseData)

      --select * From _TDABizUnit where companyseq = 2 
    ---------------------------------------------------------------------------------
        -- 포장수량 Lot대체 (일반창고 (생산Lot-> 출하Lot) ) 2016.11.14 by이재천 
        ---------------------------------------------------------------------------------
    
        DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = 2 AND TableName = '_TLGInOutDaily'       
        -- 키값생성코드부분 시작                
        EXEC @Seq = dbo._SCOMCreateSeq 2, '_TLGInOutDaily', 'InOutSeq', @count                    
        
                 
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #BaseData AS A 
        

        SELECT @Cnt = 1         
        
        WHILE ( 1 = 1 )          
        BEGIN 
                
            SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                    @Date = WorkEndDate
                FROM #BaseData AS A 
                WHERE IDX_NO = @Cnt 
                
            exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
            UPDATE #BaseData              
                SET InOutNo = @MaxNo         
                WHERE IDX_NO = @Cnt        
                        
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #BaseData)         
            BEGIN         
                BREAK         
            END         
            ELSE         
            BEGIN        
                SELECT @Cnt = @Cnt + 1         
            END         
        END         

--select * from #BaseData 
--return 
        
        
     -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               A.FactUnit, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.InWHSeq, A.InWHSeq, 
               0, '0', '', 0, 0, 
               '', 0, '포장실적 생산수량 출하Lot으로 대체 (탱크)', '', '0', 
               1, GETDATE(), 0, 1025660, 0 
          FROM #BaseData                                 AS A 
          LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PackOrderSeq = A.WorkOrderSeq AND C.PackOrderSerl = A.WorkOrderSerl ) 


        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 생산수량 출하Lot으로 대체 (탱크)', NULL, NULL, A.InWHSeq, A.InWHSeq, 
               B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023042, 0, C.OutLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, A.RealLotNo, NULL, 
               NULL, NULL, NULL, 1025660

          FROM #BaseData                                 AS A 
          LEFT OUTER JOIN _TDAItem                      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
          LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PackOrderSeq = A.WorkOrderSeq AND C.PackOrderSerl = A.WorkOrderSerl ) 
         --WHERE A.WorkingTag IN ( 'U','A' ) 
         --  AND C.OutLotNo <> A.RealLotNo

--return 
--AND ProcYn = '0'
 
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 7, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #BaseData AS A 






return 

go
begin tran 
exec test_jclee1111111111111 
select * From KPX_TPDSFCProdPackReportRelation where datakind = 7
rollback 

