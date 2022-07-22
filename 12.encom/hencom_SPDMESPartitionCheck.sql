  
IF OBJECT_ID('hencom_SPDMESPartitionCheck') IS NOT NULL   
    DROP PROC hencom_SPDMESPartitionCheck  
GO  
  
-- v2017.03.13
  
-- 출하자료검증-송장체크 by 이재천
CREATE PROC hencom_SPDMESPartitionCheck  
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
    
    ------------------------------------------------------
    -- 체크1, 집계처리가 되어 송장분할을 진행 할 수 없습니다.
    ------------------------------------------------------
    UPDATE A
       SET Result = '집계처리가 되어 송장분할을 진행 할 수 없습니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
      JOIN hencom_TIFProdWorkReportClose    AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
     WHERE A.Status = 0 
       AND (CASE WHEN ISNULL(B.SumMesKey,0) = 0 THEN '0' ELSE '1' END) = '1' 
    ------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------

    ------------------------------------------------------
    -- 체크2, 신규 추가 건은 송장분할을 진행 할 수 없습니다.
    ------------------------------------------------------
    UPDATE A
       SET Result = '신규 추가 건은 송장분할을 진행 할 수 없습니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose   AS A 
     WHERE A.Status = 0 
       AND LEFT(A.MesKey,3) = 'NEW'
    ------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------
    
    ------------------------------------------------------
    -- 체크3, 도급비정산이 확정 처리 되어 진행 할 수 없습니다.
    ------------------------------------------------------
    UPDATE A
       SET Result = '도급비정산이 확정 처리 되어 진행 할 수 없습니다.',
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TIFProdWorkReportClose       AS A 
                 JOIN hencom_TPUSubContrCalc    AS B ON ( B.CompanySeq = @CompanySeq AND B.MesKey = A.MesKey ) 
      LEFT OUTER JOIN hencom_TPUSubContrCalcCfm AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = B.DeptSeq AND C.WorkDate = B.WorkDate ) 
     WHERE A.Status = 0 
       AND C.IsConfirm = '1'      
    ------------------------------------------------------
    -- 체크3, END 
    ------------------------------------------------------


    
    SELECT * FROM #hencom_TIFProdWorkReportClose 
    
    RETURN  
    go
begin tran 
exec hencom_SPDMESPartitionCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <MesKey>0042_20151209_10002</MesKey>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026660
rollback 