  
IF OBJECT_ID('yw_SPDSFCWorkLossCheck') IS NOT NULL   
    DROP PROC yw_SPDSFCWorkLossCheck  
GO  
  
-- v2013.08.23 
  
-- 유실공수입력(현장)_YW(체크) by이재천   
CREATE PROC yw_SPDSFCWorkLossCheck  
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
      
    CREATE TABLE #YW_TPDSFCWorkLoss( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkLoss'   
    IF @@ERROR <> 0 RETURN     
        
    -- 체크1, 정지종료가 되지 않은 데이터가 존재합니다.   

     UPDATE #YW_TPDSFCWorkLoss
        SET Result       = '정지종료가 되지 않은 데이터가 존재합니다. ', 
            MessageType  = @MessageType, 
            Status       = 465131 
      FROM #YW_TPDSFCWorkLoss AS A
      JOIN YW_TPDSFCWorkLoss AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq AND B.WorkDate = A.WorkDate AND B.EndTime = '' ) 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0 
    
    -- 체크1, END
    
    -- 체크2, 데이터를 2개 이상 저장 할 수 없습니다.
    
     IF ( SELECT COUNT (1) FROM #YW_TPDSFCWorkLoss WHERE WorkingTag = 'A' AND Status = 0 ) > 1
     BEGIN 
         UPDATE #YW_TPDSFCWorkLoss
            SET Result       = '데이터를 2개 이상 저장 할 수 없습니다.', 
                MessageType  = @MessageType, 
                Status       = 454578 
    END
     
    -- 체크2, END

    -- 체크3, 정지시작이 입력 된 후로는 유실공수를 수정 할 수 없습니다.
    
    UPDATE #YW_TPDSFCWorkLoss 
       SET Result       = '데이터를 수정 할 수 없습니다.', 
           MessageType  = @MessageType, 
           Status       = 51513 
      FROM #YW_TPDSFCWorkLoss AS A 
     WHERE WorkingTag = 'U' 
       AND Status = 0 
    
    -- 체크3, END
    
    -- 체크4, 정지시작을 하지 않았습니다. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkLoss 
           SET Result       = '정지시작을 하지 않았습니다.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkLoss AS A 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
           AND A.StartTime = '' 
    END 
    
    -- 체크4, END 
    
    -- Serl 채번
    
    DECLARE @MaxSerl INT
    SELECT @MaxSerl = ISNULL(MAX(B.Serl),0)
      FROM #YW_TPDSFCWorkLoss AS A
      LEFT OUTER JOIN YW_TPDSFCWorkLoss AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
     GROUP BY A.WorkCenterSeq
    
    UPDATE A
       SET A.Serl = @MaxSerl + A.DataSeq
      FROM #YW_TPDSFCWorkLoss AS A 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0
    
    -- Serl 채번, END
    
    SELECT * FROM #YW_TPDSFCWorkLoss   
      
    RETURN  
      
GO
exec yw_SPDSFCWorkLossCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 09:00</StartTime>
    <EndTime>2013-08-23 10:50</EndTime>
    <LossTime>7800</LossTime>
    <Remark />
    <Serl>1</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유2</UMLossName>
    <UMLossSeq>1008429002</UMLossSeq>
    <StartTime>2013-08-23 10:00</StartTime>
    <EndTime>2013-08-23 12:00</EndTime>
    <LossTime>6600</LossTime>
    <Remark />
    <Serl>2</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 10:20</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>4200</LossTime>
    <Remark />
    <Serl>3</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <StartTime>2013-08-23 10:31</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>6420</LossTime>
    <Remark />
    <Serl>4</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 10:48</StartTime>
    <EndTime>2013-08-23 10:48</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>5</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <StartTime>2013-08-23 10:49</StartTime>
    <EndTime>2013-08-23 10:49</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>6</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 11:14</StartTime>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>7</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 11:14</StartTime>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>8</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <StartTime>2013-08-23 11:17</StartTime>
    <EndTime>2013-08-23 11:18</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <Serl>9</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <StartTime>2013-08-23 11:19</StartTime>
    <EndTime>2013-08-23 11:22</EndTime>
    <LossTime>540</LossTime>
    <Remark />
    <Serl>10</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <StartTime>2013-08-23 11:23</StartTime>
    <EndTime>2013-08-23 11:23</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>11</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <StartTime>2013-08-23 11:40</StartTime>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <Serl>12</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017273,@WorkingTag=N'EndTime',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014775