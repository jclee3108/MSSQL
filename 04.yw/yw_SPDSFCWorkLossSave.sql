  
IF OBJECT_ID('yw_SPDSFCWorkLossSave') IS NOT NULL   
    DROP PROC yw_SPDSFCWorkLossSave  
GO  
  
-- v2013.08.23 
  
-- 유실공수입력(현장)_YW(저장) by이재천   
CREATE PROC yw_SPDSFCWorkLossSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #YW_TPDSFCWorkLoss (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkLoss'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TPDSFCWorkLoss')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TPDSFCWorkLoss'    , -- 테이블명        
                  '#YW_TPDSFCWorkLoss'    , -- 임시 테이블명        
                  'WorkCenterSeq,WorkDate,UMLossSeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkLoss WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #YW_TPDSFCWorkLoss AS A   
          JOIN YW_TPDSFCWorkLoss AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.WorkDate = B.WorkDate AND A.Serl = B.Serl ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
          
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- EndTime 저장 
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkLoss WHERE WorkingTag = '' AND Status = 0 ) 
    BEGIN  
        IF @WorkingTag = 'EndTime'
        BEGIN
            UPDATE B   
               SET B.EndTime   = CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),  
                   B.LastUserSeq  = @UserSeq,  
                   B.LastDateTime = GETDATE() 
              FROM #YW_TPDSFCWorkLoss AS A   
              JOIN YW_TPDSFCWorkLoss AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.WorkDate = B.WorkDate AND A.Serl = B.Serl ) 
             WHERE A.WorkingTag = '' 
               AND A.Status = 0 
               AND B.EndTime = '' 
            
            IF @@ERROR <> 0  RETURN  
               
            UPDATE A
               SET EndTime = CASE WHEN A.EndTime = '' 
                                  THEN STUFF(STUFF(STUFF(STUFF(CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),5,0,'-'
                                                               ),8,0,'-'
                                                        ),11,0,' '
                                                  ),14,0,':'
                                            ) 
                                  ELSE STUFF(STUFF(STUFF(STUFF(B.EndTime,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') END, 
                   LossTime = CASE WHEN A.LossTime = ''
                                   THEN (SELECT CASE WHEN 0 < SUM(CASE WHEN B.EndTime = '' 
                                                                       THEN 0
                                                                       ELSE ISNULL(DateDiff(Second, STUFF(STUFF(STUFF(STUFF(CASE WHEN B.StartTime > C.StartTime 
                                                                                                                                 THEN B.StartTime 
                                                                                                                                 ELSE C.StartTime 
                                                                                                                                 END,5,0,'-'
                                                                                                                          ),8,0,'-'
                                                                                                                    ),11,0,' '
                                                                                                              ),14,0,':'
                                                                                                        ) + ':00.000',
                                                                                                   STUFF(STUFF(STUFF(STUFF(CASE WHEN B.StartTime > (CASE WHEN B.EndTime > C.EndTime 
                                                                                                                                                         THEN C.EndTime 
                                                                                                                                                         ELSE B.EndTime 
                                                                                                                                                         END
                                                                                                                                                   ) 
                                                                                                                                THEN B.StartTime 
                                                                                                                                ELSE (CASE WHEN B.EndTime > C.EndTime 
                                                                                                                                           THEN C.EndTime 
                                                                                                                                           ELSE B.EndTime 
                                                                                                                                           END
                                                                                                                                     ) 
                                                                                                                                END,5,0,'-'
                                                                                                                          ),8,0,'-'
                                                                                                                    ),11,0,' '
                                                                                                              ),14,0,':'
                                                                                                        ) + ':00.000'
                                                                                          ),0
                                                                                  ) 
                                                                       END 
                                                                 )
                                                     THEN SUM(CASE WHEN B.EndTime = '' 
                                                                   THEN 0
                                                                   ELSE ISNULL(DateDiff(Second, STUFF(STUFF(STUFF(STUFF(CASE WHEN B.StartTime > C.StartTime 
                                                                                                                             THEN B.StartTime 
                                                                                                                             ELSE C.StartTime 
                                                                                                                             END,5,0,'-'
                                                                                                                      ),8,0,'-'
                                                                                                                ),11,0,' '
                                                                                                          ),14,0,':'
                                                                                                    ) + ':00.000',
                                                                                               STUFF(STUFF(STUFF(STUFF(CASE WHEN B.StartTime > (CASE WHEN B.EndTime > C.EndTime 
                                                                                                                                                     THEN C.EndTime 
                                                                                                                                                     ELSE B.EndTime 
                                                                                                                                                     END
                                                                                                                                               ) 
                                                                                                                            THEN B.StartTime 
                                                                                                                            ELSE (CASE WHEN B.EndTime > C.EndTime 
                                                                                                                                       THEN C.EndTime 
                                                                                                                                       ELSE B.EndTime 
                                                                                                                                       END
                                                                                                                                 ) 
                                                                                                                            END,5,0,'-'
                                                                                                                      ),8,0,'-'
                                                                                                                ),11,0,' '
                                                                                                          ),14,0,':'
                                                                                                    ) + ':00.000'
                                                                                       ),0
                                                                              ) 
                                                                   END 
                                                             )
                                                     ELSE 0 
                                                     END
                               FROM #YW_TPDSFCWorkLoss AS A WITH(NOLOCK)   
                               JOIN YW_TPDSFCWorkLoss AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                         AND B.WorkCenterSeq = A.WorkCenterSeq 
                                                                         AND B.WorkDate = A.WorkDate 
                                                                         AND B.Serl = A.Serl 
                                                                           ) 
                               LEFT OUTER JOIN YW_TPDSFCWorkStart AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq 
                                                                                     AND C.WorkCenterSeq = A.WorkCenterSeq 
                                                                                     AND LEFT(C.StartTime,8) = A.WorkDate 
                                                                                       )
                              WHERE A.WorkingTag = '' 
                                AND A.Status = 0 
                                AND A.LossTime = ''
                              GROUP BY A.WorkCenterSeq, A.WorkDate, A.Serl
                                        )
                              ELSE A.LossTime END
    
              FROM #YW_TPDSFCWorkLoss AS A
              JOIN YW_TPDSFCWorkLoss AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.WorkDate = B.WorkDate AND A.Serl = B.Serl )
             WHERE A.WorkingTag = '' 
               AND A.Status = 0 
        END
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #YW_TPDSFCWorkLoss WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO YW_TPDSFCWorkLoss  
        (   
            CompanySeq , WorkCenterSeq , WorkDate    , UMLossSeq    , Serl, 
            StartTime  , EndTime       , Remark      , LastUserSeq  , LastDateTime
        )   
        SELECT @CompanySeq, A.WorkCenterSeq, A.WorkDate, A.UMLossSeq, A.Serl, 
               CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),'', A.Remark, @UserSeq, GETDATE() 
          FROM #YW_TPDSFCWorkLoss AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
        
        IF @WorkingTag <> 'EndTime'
        BEGIN
            UPDATE #YW_TPDSFCWorkLoss 
               SET StartTime = STUFF(STUFF(STUFF(STUFF(CONVERT(NVARCHAR(10),GETDATE(),112) + LEFT(STUFF(CONVERT(NVARCHAR(5),GETDATE(),108),3,1,''),4),5,0,'-'
                                                               ),8,0,'-'
                                                        ),11,0,' '
                                                  ),14,0,':'
                                            ) 
              FROM #YW_TPDSFCWorkLoss
             WHERE WorkingTag = 'A'   
               AND Status = 0  
        END
    END     
    
    SELECT * FROM #YW_TPDSFCWorkLoss   
      
    RETURN  
GO
begin tran
exec yw_SPDSFCWorkLossSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 10:50</EndTime>
    <LossTime>7800</LossTime>
    <Remark />
    <StartTime>2013-08-23 09:00</StartTime>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <Serl>1</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 12:00</EndTime>
    <LossTime>6600</LossTime>
    <Remark />
    <StartTime>2013-08-23 10:00</StartTime>
    <UMLossName>유실사유2</UMLossName>
    <UMLossSeq>1008429002</UMLossSeq>
    <Serl>2</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>4200</LossTime>
    <Remark />
    <StartTime>2013-08-23 10:20</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>3</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>6420</LossTime>
    <Remark />
    <StartTime>2013-08-23 10:31</StartTime>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <Serl>4</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 10:48</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 10:48</StartTime>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <Serl>5</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 10:49</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 10:49</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>6</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:14</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>7</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:14</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:14</StartTime>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <Serl>8</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:18</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:17</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>9</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:22</EndTime>
    <LossTime>540</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:19</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>10</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:23</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:23</StartTime>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <Serl>11</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:40</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:40</StartTime>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <Serl>12</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:44</EndTime>
    <LossTime>540</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:41</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>13</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:47</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:47</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>14</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:48</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:47</StartTime>
    <UMLossName>유실사유1</UMLossName>
    <UMLossSeq>1008429001</UMLossSeq>
    <Serl>15</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:50</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:50</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>16</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:51</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:50</StartTime>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <Serl>17</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:53</EndTime>
    <LossTime>180</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:52</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>18</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 11:58</EndTime>
    <LossTime>360</LossTime>
    <Remark />
    <StartTime>2013-08-23 11:56</StartTime>
    <UMLossName>유실사유3</UMLossName>
    <UMLossSeq>1008429003</UMLossSeq>
    <Serl>19</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 12:03</EndTime>
    <LossTime>0</LossTime>
    <Remark />
    <StartTime>2013-08-23 12:03</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>20</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 12:09</EndTime>
    <LossTime>1080</LossTime>
    <Remark />
    <StartTime>2013-08-23 12:03</StartTime>
    <UMLossName>유실사유2</UMLossName>
    <UMLossSeq>1008429002</UMLossSeq>
    <Serl>21</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime>2013-08-23 12:40</EndTime>
    <LossTime>5580</LossTime>
    <Remark />
    <StartTime>2013-08-23 12:09</StartTime>
    <UMLossName>유실사유4</UMLossName>
    <UMLossSeq>1008429004</UMLossSeq>
    <Serl>22</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EndTime />
    <LossTime />
    <Remark />
    <StartTime>2013-08-23 12:40</StartTime>
    <UMLossName>유실사유5</UMLossName>
    <UMLossSeq>1008429005</UMLossSeq>
    <Serl>23</Serl>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017273,@WorkingTag=N'EndTime',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014775
rollback tran