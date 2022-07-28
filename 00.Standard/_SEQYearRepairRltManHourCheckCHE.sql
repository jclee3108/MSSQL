
IF OBJECT_ID('_SEQYearRepairRltManHourCheckCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairRltManHourCheckCHE
GO 

-- v2014.12.02 
/************************************************************
  설  명 - 데이터-년차보수 실적 공수 Item : 체크
  작성일 - 20110705
  작성자 - 김수용
 ************************************************************/
 CREATE PROC [dbo].[_SEQYearRepairRltManHourCheckCHE]
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS
     DECLARE @Count          INT,
             @Seq            INT,
             @Date           NCHAR(8),
             @MaxNo          NVARCHAR(20),
             @MessageType    INT,
             @Status         INT,
             @Results        NVARCHAR(250),
             @rtnMessage     NVARCHAR(50)  
             --@RepairToDate   NCHAR(8), 
             --@ReceiptFrDate  NCHAR(8), 
             --@ReceiptToDate  NCHAR(8)  
  
     -- 서비스 마스타 등록 생성
     CREATE TABLE #_TEQYearRepairRltManHourCHE (WorkingTag NCHAR(1) NULL) 
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQYearRepairRltManHourCHE'
     IF @@ERROR <> 0 RETURN 
  
  
  IF @PgmSeq=1006508
 BEGIN
    SELECT @rtnMessage = '년차보수 계획공수'
 END
 ELSE
 BEGIN
    SELECT @rtnMessage = '년차보수 실제공수'
 END   
  --_TEQYearRepairMngCHEManHour   
  
      --SELECT 
      --       @RepairFrDate  = RepairFrDate,
      --       @RepairToDate  = RepairToDate,
      --       @ReceiptFrDate = ReceiptFrDate,
      --       @ReceiptToDate = ReceiptToDate 
      --FROM #_TEQYearRepairPeriodCHE
       
  
       --select * from #_TEQYearRepairPlanManHourCHE
       
 -- 중복체크
       EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0, @rtnMessage   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
         UPDATE #_TEQYearRepairRltManHourCHE
            SET Result        = REPLACE(@Results,'@2',  A.RepairYear + '년 ' + CONVERT(NVARCHAR(2),A.Amd) + '차수_' + (LTRIM(RTRIM(C.MinorName))    ) ),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #_TEQYearRepairRltManHourCHE AS A JOIN ( SELECT  S.WONo, S.RepairYear,S.Amd,S.WorkOperSerl        
                                                        FROM (SELECT  A1.WONo, A1.RepairYear,A1.Amd,A1.WorkOperSerl
                                                                FROM #_TEQYearRepairRltManHourCHE AS A1
                                                               WHERE 1 = 1
                                                                 AND A1.WorkingTag IN ('A', 'U')
                                                                 AND A1.Status = 0                                                             
                                                       --TEMP에 등록인 정보가 원래 테이블에 존재
                                                               UNION ALL
                                                              SELECT  A1.WONo,A1.RepairYear,A1.Amd,A1.WorkOperSerl 
                                                                FROM _TEQYearRepairRltManHourCHE AS A1 WITH(NOLOCK)
                                                                     JOIN #_TEQYearRepairRltManHourCHE AS A2 
                                                                       ON  1 = 1
                                                                      AND A1.WONo          = A2.WONo
                                                                      AND A1.RepairYear      = A2.RepairYear
                                                                      AND A1.Amd             = A2.Amd
                                                  AND A1.WorkOperSerl    = A2.WorkOperSerl 
                                           WHERE 1 = 1
                                                                 AND A1.CompanySeq = @CompanySeq
                                                                 AND A2.WorkingTag = 'A'
                                                                 AND A2.Status = 0
                                                               UNION ALL
                                                               --TEMP에 등록인 정보가 원래 테이블에 존재
                                                              SELECT A2.WONo, A2.RepairYear,A2.Amd,A2.WorkOperSerl 
                                                                FROM _TEQYearRepairRltManHourCHE AS A1 WITH(NOLOCK)
                                                                     JOIN #_TEQYearRepairRltManHourCHE AS A2 
                                                                       ON 1 = 1
                                                                      AND A1.WONo  = A2.WONo
                                                                      AND A1.RltSerl = A2.RltSerl
                                                                      AND ((A1.RepairYear   <> A2.RepairYear)OR
                                                                           (A1.Amd          <> A2.Amd)       OR
                                                                           (A1.WorkOperSerl <> A2.WorkOperSerl))
                                                                     JOIN _TEQYearRepairRltManHourCHE  AS A3 
                                                                       ON 1 = 1
                                                                      AND A3.CompanySeq      = @CompanySeq
                                                                      AND A2.WONo            = A3.WONo
                                                                      AND A2.RepairYear      = A3.RepairYear
                                                                      AND A2.Amd             = A3.Amd     
                                                                      AND A2.WorkOperSerl    = A3.WorkOperSerl 
                                                              WHERE 1 = 1
                                                                AND A1.CompanySeq = @CompanySeq
                                                                AND A2.WorkingTag = 'U'
                                                                AND A2.Status = 0 ) AS S
                                             GROUP BY S.WONo, S.RepairYear,S.Amd,S.WorkOperSerl        
                                            HAVING COUNT(1) > 1) AS B 
                                                ON 1 = 1
                                               AND A.WONo       = B.WONo  
                                               AND A.RepairYear   = B.RepairYear
                                               AND A.Amd          = B.Amd
                                               AND A.WorkOperSerl = B.WorkOperSerl                                  
                                               
                            JOIN _TDAUMinor AS C WITH (NOLOCK)                    
                              ON 1 = 1
                             AND C.CompanySeq    = @CompanySeq
                             AND A.WorkOperSerl  = C.MinorSeq
  
  
  /*
  
  exec capro_SEQYearRepairPlanManHourCheck @xmlDocument=N'<ROOT>
   <DataBlock1>
     <WorkingTag>A</WorkingTag>
     <IDX_NO>1</IDX_NO>
     <DataSeq>1</DataSeq>
     <Status>0</Status>
     <Selected>0</Selected>
     <ReqSeq>4</ReqSeq>
     <ReqSerl>0</ReqSerl>
     <WorkOperSerlName>재생</WorkOperSerlName>
     <WorkOperSerl>1000729002</WorkOperSerl>
     <ManHour>10</ManHour>
     <TABLE_NAME>DataBlock1</TABLE_NAME>
     <RepairYear>2011</RepairYear>
     <Amd>1</Amd>
   </DataBlock1>
   <DataBlock1>
     <WorkingTag>A</WorkingTag>
     <IDX_NO>2</IDX_NO>
     <DataSeq>2</DataSeq>
     <Status>0</Status>
     <Selected>0</Selected>
     <ReqSeq>4</ReqSeq>
     <ReqSerl>0</ReqSerl>
     <WorkOperSerlName>배관</WorkOperSerlName>
     <WorkOperSerl>1000729003</WorkOperSerl>
     <ManHour>50</ManHour>
     <RepairYear>2011</RepairYear>
     <Amd>1</Amd>
   </DataBlock1>
 </ROOT>',@xmlFlags=2,@ServiceSeq=1007029,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1006508
  
  
  
  */
  
  
   
   
     SELECT @Count = COUNT(1) FROM #_TEQYearRepairRltManHourCHE WHERE WorkingTag = 'A' AND Status = 0  
     IF @Count > 0  
     BEGIN    
     
                -- 내부순번  
         DECLARE     @vcWONo       NCHAR(8),
                     @vcPlnOrRlt     NCHAR(1)
         
         SELECT 
                 @vcWONo   = A.WONo 
           FROM #_TEQYearRepairRltManHourCHE AS A  
          WHERE 1 = 1
            AND WorkingTag = 'A'  
            AND Status = 0  
     
     
         -- 키값생성코드부분 시작    
         SELECT @Seq = ISNULL((SELECT MAX(A.RltSerl)  
                                 FROM _TEQYearRepairRltManHourCHE AS A  
                                WHERE A.CompanySeq   = @CompanySeq  
                                  AND A.WONo         = @vcWONo),0)              
      
          --SELECT @Seq = @Seq + MAX(DivGroupStepSeq)
          --   FROM #_TQIDivGroupActDetailCHE
          -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #_TEQYearRepairRltManHourCHE
            SET RltSerl =@Seq +Dataseq
          WHERE WorkingTag = 'A'  
     
     END            
     
     SELECT * FROM #_TEQYearRepairRltManHourCHE
  RETURN
  
  /*
 exec _SEQYearRepairRltManHourCheckCHE @xmlDocument=N'<ROOT>
   <DataBlock1>
     <WorkingTag>A</WorkingTag>
     <IDX_NO>4</IDX_NO>
     <DataSeq>1</DataSeq>
     <Status>0</Status>
     <Selected>0</Selected>
     <WONo />
     <WorkOperSerlName>조공</WorkOperSerlName>
     <WorkOperSerl>1000729008</WorkOperSerl>
     <ManHour>50</ManHour>
     <TABLE_NAME>DataBlock1</TABLE_NAME>
     <RepairYear>2011</RepairYear>
     <Amd>1</Amd>
   </DataBlock1>
 </ROOT>',@xmlFlags=2,@ServiceSeq=1007046,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1006518
  
 */