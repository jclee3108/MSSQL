  
IF OBJECT_ID('hencom_SPDMESPartitionAddSave') IS NOT NULL   
    DROP PROC hencom_SPDMESPartitionAddSave  
GO  
  
-- v2017.03.02
  
-- 송장분할및추가-저장 by 이재천 
CREATE PROC hencom_SPDMESPartitionAddSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TIFProdWorkReportClose (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClose'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @IsPartition NCHAR(1) 

    SELECT @IsPartition = (SELECT MAX(IsPartition) FROM #hencom_TIFProdWorkReportClose)
    
    UPDATE A
       SET Rotation = CASE WHEN @IsPartition = '1' THEN A.Rotation ELSE 1 END 
      FROM #hencom_TIFProdWorkReportClose AS A 


    IF @IsPartition = '1' 
    BEGIN 
        ---------------------------------------------------------------
        -- 투입자재도 분할 삭제 
        ---------------------------------------------------------------
        DELETE A 
            FROM hencom_TIFProdMatInputClose        AS A 
            JOIN #hencom_TIFProdWorkReportClose     AS B ON ( B.MesKey = LEFT(A.MesKey,19) ) 
            WHERE A.CompanySeq = @CompanySeq 
            AND LEN(A.MesKey) > 19 
            AND B.Status = 0 
        ---------------------------------------------------------------
        -- 투입자재도 분할 삭제, END  
        ---------------------------------------------------------------
    END 

    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TIFProdWorkReportClose')    
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TIFProdWorkReportClose WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @IsPartition = '1' 
        BEGIN 
            SELECT B.WorkingTag, B.IDX_NO, B.DataSeq, B.Selected, B.Status, 
                   A.MesKey
              INTO #DeleteLog
              FROM hencom_TIFProdWorkReportClose    AS A 
              JOIN #hencom_TIFProdWorkReportClose   AS B ON ( B.MesKey = LEFT(A.MesKey,19) ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND LEN(A.MesKey) > 19 
               AND B.Status = 0 
               AND B.WorkingTag = 'D' 
        
        
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'hencom_TIFProdWorkReportClose'    , -- 테이블명        
                          '#DeleteLog'    , -- 임시 테이블명        
                          'MesKey'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                          @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
            DELETE B   
              FROM #DeleteLog                    AS A   
              JOIN hencom_TIFProdWorkReportClose AS B ON ( B.CompanySeq = @CompanySeq AND A.MesKey = B.MesKey )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
        
            IF @@ERROR <> 0  RETURN  

        END 
        ELSE 
        BEGIN
            
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'hencom_TIFProdWorkReportClose'    , -- 테이블명        
                          '#hencom_TIFProdWorkReportClose'    , -- 임시 테이블명        
                          'MesKey'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                          @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
            
            DELETE B   
              FROM #hencom_TIFProdWorkReportClose   AS A   
              JOIN hencom_TIFProdWorkReportClose    AS B ON ( B.CompanySeq = @CompanySeq AND A.MesKey = B.MesKey )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   

        END 
        

          
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TIFProdWorkReportClose WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  

        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'hencom_TIFProdWorkReportClose'    , -- 테이블명        
                      '#hencom_TIFProdWorkReportClose'    , -- 임시 테이블명        
                      'MesKey'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

        UPDATE B   
           SET B.GoodItemSeq     = A.GoodItemSeq    , 
               B.ProdQty         = A.ProdQty        , 
               B.OutQty          = A.OutQty         , 
               B.CustSeq         = A.CustSeq        , 
               B.PJTSeq          = A.PJTSeq         , 
               B.UMOutType       = A.UMOutTypeSeq   , 
               B.ExpShipSeq      = A.ExpShipSeq     , 
               B.SubContrCarSeq  = A.SubContrCarSeq , 
               B.UMCarClass      = A.UMCarClass     , 
               B.CarCode         = A.CarCode        , 
               B.CarNo           = A.CarNo          , 
               B.BPNo            = CASE WHEN @IsPartition = '1' THEN B.BPNo ELSE A.BPNo END,
               B.Driver          = A.Driver         , 
               B.Rotation        = A.Rotation       , 
               B.LastUserSeq     = @UserSeq         ,  
               B.LastDateTime    = GETDATE()  
                 
          FROM #hencom_TIFProdWorkReportClose   AS A   
          JOIN hencom_TIFProdWorkReportClose    AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.NewMesKey )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
        
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TIFProdWorkReportClose WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TIFProdWorkReportClose  
        (   
            MesKey, CompanySeq, InputDateTime, WorkDate, GoodItemSeq, 
            ProdQty, OutQty, DeptSeq, CustSeq, PJTSeq, 
            CurAmt, CurVAT, UMOutType, ExpShipSeq, SubContrCarSeq, 
            UMCarClass, CarCode, CarNo, Driver, InvCreDateTime, 
            InvPrnTime, DepartTime, ArriveTime, GPSDepartTime, GPSArriveTime, 
            Rotation, RealDistance, Remark, MesNo, IsNew, 
            WorkOrderSeq, WorkReportSeq, InvoiceSeq, ProdIsErpApply, ProdResults, 
            ProdStatus, InvIsErpApply, InvResults, InvStatus, Price, 
            RealItemSeq, GoodItemName, RealItemName, PJTName, DeptName, 
            CustName, BPNo, LastUserSeq, LastDateTime, SumMesKey, 
            IsErpApply, TStartTime, TEndTime, RotationNo
        )   
        SELECT A.NewMesKey, @CompanySeq, GETDATE(), A.WorkDate, A.GoodItemSeq, 
               A.ProdQty, A.OutQty, A.DeptSeq, A.CustSeq, A.PJTSeq, 
               0, 0, A.UMOutTypeSeq, A.ExpShipSeq, A.SubContrCarSeq, 
               A.UMCarClass, A.CarCode, A.CarNo, A.Driver, B.InvCreDateTime, 
               B.InvPrnTime, NULL, NULL, NULL, NULL, 
               A.Rotation, NULL, CASE WHEN @IsPartition = '1' THEN '송장분할' ELSE '신규추가' END, B.MesNo, 'Y', 
               NULL, NULL, NULL, NULL, NULL, 
               NULL, NULL, NULL, NULL, NULL, 
               NULL, NULL, NULL, NULL, NULL, 
               NULL, CASE WHEN @IsPartition = '1' THEN B.BPNo ELSE A.BPNo END, @UserSeq, GETDATE(), NULL, 
               NULL, NULL, NULL, 1
          FROM #hencom_TIFProdWorkReportClose           AS A   
          LEFT OUTER JOIN hencom_TIFProdWorkReportClose AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END   

    --select * from hencom_TIFProdWorkReportClose where left(meskey,19) = '0036_20151209_10002'
    --return 

    IF @IsPartition = '1' 
    BEGIN 
        ---------------------------------------------------------------
        -- 투입자재 분할생성
        ---------------------------------------------------------------

        DECLARE @ProdQty    DECIMAL(19,5), 
                @MaxSeq     INT 

        SELECT @ProdQty = ProdQty
            FROM hencom_TIFProdWorkReportClose AS A 
            WHERE A.CompanySeq = @CompanySeq 
            AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = A.MesKey)
        

        SELECT MesKey 
            INTO #RealData
            FROM hencom_TIFProdWorkReportClose AS A 
            WHERE A.CompanySeq = @CompanySeq 
            AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = LEFT(A.MesKey,19))
            AND LEN(A.MesKey) > 19 
            AND NOT EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE NewMesKey = A.MesKey)

        -- Temp테이블 데이터 
        SELECT A.NewMesKey, B.MesSerl, @CompanySeq AS CompanySeq, B.MatItemName, 
                ROUND((A.ProdQty / @ProdQty) * B.Qty,0) AS Qty, B.Remark, B.MatUnitSeq, B.MatItemSeq, B.StdUnitQty, 
                B.Status, B.Results, B.WorkDate, B.DeptSeq
            INTO #MatInPut
            FROM #hencom_TIFProdWorkReportClose   AS A 
            JOIN hencom_TIFProdMatInputClose      AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
           WHERE A.WorkingTag IN ( 'A', 'U' ) 
        
        UNION ALL 
            --실제 테이블 데이터 
        SELECT A.MesKey, C.MesSerl, @CompanySeq AS CompanySeq, C.MatItemName, 
                ROUND((A.ProdQty / @ProdQty) * C.Qty,0) AS Qty, C.Remark, C.MatUnitSeq, C.MatItemSeq, C.StdUnitQty, 
                C.Status, C.Results, C.WorkDate, C.DeptSeq
            FROM hencom_TIFProdWorkReportClose    AS A 
            JOIN #RealData                        AS B ON ( B.MesKey = A.MesKey ) 
            JOIN hencom_TIFProdMatInputClose      AS C ON ( C.CompanySeq = @CompanySeq AND C.MesKey = LEFT(B.MesKey,19) ) 
            WHERE A.CompanySeq = @CompanySeq 
            AND EXISTS (SELECT 1 FROM #RealData WHERE MesKey = A.MesKey)
    
        -- 최종데이터에 단수보정 
        SELECT @MaxSeq = ( 
                            SELECT MAX(CONVERT(INT,RIGHT(NewMesKey,3)))
                                FROM #MatInPut
                            )

        SELECT A.MesKey, A.MesSerl, B.Qty - A.Qty AS DiffQty 
            INTO #DiffQty 
            FROM (
                SELECT LEFT(NewMesKey,19) AS MesKey, MesSerl, SUM(Qty) AS Qty 
                    FROM #MatInPut 
                    GROUP BY LEFT(NewMesKey,19), MesSerl
                ) AS A 
            JOIN hencom_TIFProdMatInputClose AS B ON ( B.CompanySeq = @CompanySeq aND B.MesKey = A.MesKey AND B.MesSerl = A.MesSerl ) 
            WHERE A.Qty <> B.Qty 
        
        -- 단수보정 적용
        UPDATE A 
            SET A.Qty = ISNULL(A.Qty,0) + ISNULL(B.DiffQty,0)
            FROM #MatInPut AS A 
            LEFT OUTER JOIN #DiffQty                    AS B ON ( B.MesKey = LEFT(NewMesKey,19) AND B.MesSerl = A.MesSerl )
            WHERE CONVERT(INT,RIGHT(A.NewMesKey,3)) = @MaxSeq 
    
        INSERT INTO hencom_TIFProdMatInputClose 
        ( 
            MesKey, MesSerl, CompanySeq, InputDateTime, MatItemName, 
            Qty, Remark, MatUnitSeq, MatItemSeq, StdUnitQty, 
            WorkReportSeq, Status, Results, IsErpApply, 
            WorkDate, DeptSeq, LastUserSeq, LastDateTime, SumMesKey, 
            SumMesSerl
        ) 
        SELECT NewMesKey, MesSerl, CompanySeq, GETDATE(), MatItemName, 
                Qty, Remark, MatUnitSeq, MatItemSeq, StdUnitQty, 
                NULL, Status, Results, NULL, 
                WorkDate, DeptSeq, @UserSeq, GETDATE(), NULL, 
                NULL
            FROM #MatInPut 

        ---------------------------------------------------------------
        -- 투입자재 분할생성, END 
        ---------------------------------------------------------------
    END 

    SELECT * FROM #hencom_TIFProdWorkReportClose   
    
    
    RETURN  
    GO

begin tran 
exec hencom_SPDMESPartitionAddSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ExpShipNo>20151221143</ExpShipNo>
    <UMExpShipTypeName />
    <UMOutTypeName>물차</UMOutTypeName>
    <PJTName>남내지구</PJTName>
    <GoodItemName>13-18-100</GoodItemName>
    <ProdQty>0.00000</ProdQty>
    <OutQty>0.00000</OutQty>
    <CustName>대산레미콘</CustName>
    <ToolName>B/P 1호기</ToolName>
    <BPNo>1</BPNo>
    <UMCarClassName>자차</UMCarClassName>
    <CarNo>105-6969</CarNo>
    <CarCode>0105</CarCode>
    <Driver>김영근</Driver>
    <Rotation>0</Rotation>
    <MesKey />
    <ExpShipSeq>10082</ExpShipSeq>
    <UMOutTypeSeq>8020106</UMOutTypeSeq>
    <PJTSeq>14219</PJTSeq>
    <CustSeq>4949</CustSeq>
    <GoodItemSeq>2149</GoodItemSeq>
    <SubContrCarSeq>453</SubContrCarSeq>
    <UMCarClass>8030001</UMCarClass>
    <IsPartition>0</IsPartition>
    <NewMesKey>NEW_ADD_006</NewMesKey>
    <DeptSeq>42</DeptSeq>
    <WorkDate>20151209</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511366,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032936
rollback 