  
IF OBJECT_ID('hencom_SPDMESSumCancelCheck') IS NOT NULL   
    DROP PROC hencom_SPDMESSumCancelCheck  
GO  
  
-- v2017.02.20
  
-- MES집계취소(선택)-체크 by 이재천
CREATE PROC hencom_SPDMESSumCancelCheck  
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
      
    CREATE TABLE #hencom_TIFProdWorkReportClosesum ( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClosesum'   
    IF @@ERROR <> 0 RETURN     
    
    -------------------------------------------------------
    -- 체크1, 확정 된 건은 집계취소 할 수 없습니다.
    -------------------------------------------------------

     IF EXISTS (SELECT 1 
                  FROM #hencom_TIFProdWorkReportClosesum    AS A 
                  JOIN hencom_TIFProdWorkReportClosesum     AS B ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey )
                 WHERE ISNULL(B.CfmCode,'0') = '1'
                   AND A.Status = 0 
               ) 
    BEGIN
        UPDATE A
           SET Result = '확정 된 건은 집계취소 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #hencom_TIFProdWorkReportClosesum AS A 
    END 
    -------------------------------------------------------
    -- 체크1, END 
    -------------------------------------------------------
    
    SELECT * FROM #hencom_TIFProdWorkReportClosesum 

    RETURN  
GO
begin tran 
exec hencom_SPDMESSumCancelCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9421</SumMesKey>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9422</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9423</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9436</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9441</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9430</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9431</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9424</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9438</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9425</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9434</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9440</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9427</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9444</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9433</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9426</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9428</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9429</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9439</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9443</SumMesKey>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SumMesKey>9432</SumMesKey>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027245
rollback 