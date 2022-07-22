  
IF OBJECT_ID('hencom_SPDMESPartitionAddCheck') IS NOT NULL   
    DROP PROC hencom_SPDMESPartitionAddCheck  
GO  
  
-- v2017.03.24
  
-- 송장분할및추가-체크 by 이재천
CREATE PROC hencom_SPDMESPartitionAddCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #hencom_TIFProdWorkReportClose( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClose'   
    IF @@ERROR <> 0 RETURN     
    
    

    DECLARE @IsPartition NCHAR(1) 

    SELECT @IsPartition = (SELECT MAX(IsPartition) FROM #hencom_TIFProdWorkReportClose)

    
    IF @IsPartition = '1' 
    BEGIN 
        -- 분할 시 기존MesKey에 추가로 부여
        DECLARE @MaxMesKey  INT 

        SELECT @MaxMesKey = CONVERT(INT,RIGHT(A.MesKey,3))
          FROM hencom_TIFProdWorkReportClose    AS A 
          JOIN #hencom_TIFProdWorkReportClose   AS B ON ( B.MesKey = LEFT(A.MesKey,19) ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND LEN(A.MesKey) > 19 
    
        SELECT @MaxMesKey = ISNULL(@MaxMesKey,0)
    
    

        UPDATE A
           SET NewMesKey = A.MesKey + '_' + RIGHT('00' + CONVERT(NVARCHAR(20),@MaxMesKey + A.DataSeq),3)
          FROM #hencom_TIFProdWorkReportClose AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'A' 
    END 
    ELSE 
    BEGIN
        -- 추가 시 새로운 번호로 추가 
        DECLARE @MaxNewMesKey  INT 

        SELECT @MaxNewMesKey = CONVERT(INT,RIGHT(A.MesKey,3))
          FROM hencom_TIFProdWorkReportClose    AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND LEFT(A.MesKey,12) = 'NEW_' + A.WorkDate 
    
        SELECT @MaxNewMesKey = ISNULL(@MaxNewMesKey,0)
        

        UPDATE A
           SET NewMesKey = 'NEW_' + A.WorkDate + '_' + RIGHT('00' + CONVERT(NVARCHAR(20),@MaxNewMesKey + A.DataSeq),3)
          FROM #hencom_TIFProdWorkReportClose AS A 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'A' 

    END 
    

    -- 체크0, 집계처리되어 수정/삭제 할 수 없습니다.
    IF @IsPartition = '0' 
    BEGIN 
        UPDATE A
           SET Result = '집계처리되어 수정/삭제 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #hencom_TIFProdWorkReportClose AS A 
          JOIN hencom_TIFProdWorkReportClose  AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
         WHERE A.Status = 0 
           AND A.WorkingTag IN ( 'U', 'D' ) 
           AND ISNULL(B.SumMesKey,0) <> 0 
    END 
    ELSE IF @IsPartition = '1' 
    BEGIN 
        SELECT B.MesKey, ISNULL(B.SumMesKey,0) AS SumMesKey
          INTO #SumMesKey
          FROM #hencom_TIFProdWorkReportClose AS A 
          LEFT OUTER JOIN hencom_TIFProdWorkReportClose AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND LEFT(B.MesKey,19) = A.MesKey ) 
         WHERE LEN(B.MesKey) > 19 
        
        IF EXISTS (SELECT 1 FROM #SumMesKey WHERE SumMesKey <> 0)
        BEGIN 
            UPDATE A
               SET Result = '집계처리되어 처리 할 수 없습니다.', 
                   Status = 1234, 
                   MessageType = 1234 
              FROM #hencom_TIFProdWorkReportClose AS A 
             WHERE A.Status = 0 
        END 
    END 
    -- 체크0, END 



    -- 체크1, 도급비정산이 확정 처리 되어 진행 할 수 없습니다.
    UPDATE A
       SET Result = '도급비정산이 확정 처리 되어 진행 할 수 없습니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose       AS A 
                 JOIN hencom_TPUSubContrCalc    AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
      LEFT OUTER JOIN hencom_TPUSubContrCalcCfm AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq AND C.WorkDate = B.WorkDate ) 
     WHERE A.Status = 0 
       AND C.IsConfirm = '1'   
    -- 체크1, END 


    -- 체크2, 기존의 수량과 분할합의 수량이 다릅니다. ( 송장 분할일 경우에만 해당 ) 
    IF EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE Status = 0 AND WorkingTag IN ( 'A', 'U' )) AND @IsPartition = '1' 
    BEGIN 
        
        SELECT ProdQty, OutQty 
          INTO #Qty
          FROM hencom_TIFProdWorkReportClose    AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND NOT EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE NewMesKey = A.MesKey)
           AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = LEFT(A.MesKey,19))
           AND LEN(A.MesKey) > 19 
    
        UNION ALL 
    
        SELECT ProdQty, OutQty 
          FROM #hencom_TIFProdWorkReportClose 
        



        DECLARE @OldProdQty DECIMAL(19,5), 
                @OldOutQty  DECIMAL(19,5)
        
        SELECT @OldProdQty = (
                                SELECT MAX(ProdQty)
                                  FROM hencom_TIFProdWorkReportClose AS A 
                                 WHERE A.CompanySeq = @CompanySeq 
                                   AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = A.MesKey)
                             )

        SELECT @OldOutQty = (
                                SELECT MAX(OutQty)
                                  FROM hencom_TIFProdWorkReportClose AS A 
                                 WHERE A.CompanySeq = @CompanySeq 
                                   AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClose WHERE MesKey = A.MesKey)
                             )

        
        UPDATE #hencom_TIFProdWorkReportClose 
           SET Result = '기존의 수량과 분할합의 수량이 다릅니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM (
                SELECT SUM(ProdQty) AS ProdQty, SUM(OutQty) AS OutQty
                  FROM #Qty
               ) AS A 
         WHERE A.ProdQty <> @OldProdQty 
            OR A.OutQty <> @OldOutQty
    
    END 
    -- 체크2, END 

    -- 체크3, 신규추가는 물차만 가능합니다. 
    UPDATE A
       SET Result = '신규추가는 물차만 가능합니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMOutTypeSeq AND B.Serl = 2015 ) 
     WHERE A.Status = 0 
       AND A.IsPartition = '0'
       AND ISNULL(B.ValueText,'0') = '0' 
       AND A.WorkingTag IN ( 'A', 'U' ) 
    -- 체크3, END 

    -- 체크4, 송장분할은 물차제외한 출하구분을 선택하시기 바랍니다.
    UPDATE A
       SET Result = '송장분할은 물차제외한 출하구분을 선택하시기 바랍니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMOutTypeSeq AND B.Serl = 2015 ) 
     WHERE A.Status = 0 
       AND A.IsPartition = '1'
       AND ISNULL(B.ValueText,'0') = '1' 
    -- 체크4, END 

    SELECT * FROM #hencom_TIFProdWorkReportClose 
    
    
    RETURN  
    go
begin tran 
exec hencom_SPDMESPartitionAddCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ExpShipNo>20170208004</ExpShipNo>
    <MesNo>0001</MesNo>
    <UMOutTypeName>정상판매</UMOutTypeName>
    <PJTName>온산S-OIL RUC area4 건축</PJTName>
    <GoodItemName>25-27-120</GoodItemName>
    <CustName>(주)대우건설</CustName>
    <MesKey>0041_20170208_10001</MesKey>
    <IsPartition>1</IsPartition>
    <DeptSeq>41</DeptSeq>
    <WorkDate>20170208</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511366,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032936
rollback 