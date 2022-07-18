
IF OBJECT_ID('lumim_SPDSFCBINWorkOrderReportCheck') IS NOT NULL
    DROP PROC lumim_SPDSFCBINWorkOrderReportCheck
GO

-- v2013.08.06 

-- BIN비움작업및조회_lumim(체크) by이재천
CREATE PROC lumim_SPDSFCBINWorkOrderReportCheck
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
    
    CREATE TABLE #lumim_TPDSFCBINWorkOrder (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#lumim_TPDSFCBINWorkOrder'

    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리
    IF NOT EXISTS ( SELECT 1   
                      FROM #lumim_TPDSFCBINWorkOrder AS A   
                      JOIN lumim_TPDSFCBINWorkOrder AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.BINWorkOrderSeq = B.BINWorkOrderSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #lumim_TPDSFCBINWorkOrder  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    
    -- 체크1, 생산계획번호가 여러개가 존재하면 저장 할 수 없습니다.
    
    SELECT COUNT(1) AS Count, MAX(A.WorkingTag) AS WorkingTag, MAX(A.Status) AS Status
      INTO #COUNTTEMP
      FROM #lumim_TPDSFCBINWorkOrder AS A
      JOIN _TPDMPSDailyProdPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq ) 
    HAVING COUNT(1) <> 1 
    
    UPDATE #lumim_TPDSFCBINWorkOrder
       SET Result        = '생산계획번호가 여러개가 존재하면 저장 할 수 없습니다.',
           MessageType   = @MessageType,
           Status        = 56413518
      FROM #COUNTTEMP AS A
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0 
       AND A.Count <> 1
     
    -- 체크1, END
    
    
    -- 체크2, 수량을 생산계획의 진행 완료수량(양품수량)을 초과하여 저장 할 수 없습니다.
    
    SELECT MAX(A.WorkingTag) AS WorkingTag, MAX(A.Status) AS Status, MAX(B.ProdPlanNo) AS ProdPlanNo, SUM(D.OKQty) AS OKQty, SUM(A.Qty) AS Qty,
           (
            SELECT SUM(B.Qty)
              FROM #lumim_TPDSFCBINWorkOrder AS A
              JOIN lumim_TPDSFCBINWorkOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq )
             WHERE A.WorkingTag IN ('A','U') 
               AND A.Status = 0 
             GROUP BY A.ProdPlanSeq
           ) AS SaveQty
      INTO #TEMP
      FROM #lumim_TPDSFCBINWorkOrder AS A 
      JOIN _TPDMPSDailyProdPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq AND B.ProdPlanNo = A.ProdPlanNo ) 
      JOIN _TPDSFCWorkOrder     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq )
      JOIN _TPDSFCWorkReport    AS D WITH(NOLOCK) ON ( D.COmpanySeq = @CompanySeq AND D.WorkOrderSeq = C.WorkOrderSeq AND D.WorkOrderserl = C.WorkOrderSerl ) 
     WHERE A.WorkingTag IN ('A','U') 
       AND A.Status = 0 
     GROUP BY B.ProdPlanSeq
     HAVING SUM(D.OKQty) < SUM(A.Qty) + (
                                         SELECT SUM(B.Qty)
                                           FROM #lumim_TPDSFCBINWorkOrder AS A
                                           JOIN lumim_TPDSFCBINWorkOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.ProdPlanSeq = A.ProdPlanSeq )
                                          WHERE A.WorkingTag IN ('A','U') 
                                            AND A.Status = 0 
                                          GROUP BY A.ProdPlanSeq
                                        ) 
    
    
    UPDATE #lumim_TPDSFCBINWorkOrder
       SET Result        = '수량을 생산계획의 진행 완료수량(양품수량)을 초과하여 저장 할 수 없습니다.',
           MessageType   = @MessageType,
           Status        = 56413518
      FROM #TEMP AS A
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0 
       AND A.OKQty < A.Qty + A.SaveQty
    
    -- 체크 2, END

    
    -- 키값 채번하기
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #lumim_TPDSFCBINWorkOrder WHERE WorkingTag = 'A' AND Status = 0
    IF @Count > 0 
    BEGIN
     EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'lumim_TPDSFCBINWorkOrder','BINWorkOrderSeq',@Count --rowcount  
          UPDATE #lumim_TPDSFCBINWorkOrder             
             SET BINWorkOrderSeq  = @MaxSeq + DataSeq   
           WHERE WorkingTag = 'A'            
               AND Status = 0 
        
        
    
    -- 일련번호 채번 시작   
    DECLARE @MaxNo  NVARCHAR(20),    
            @Date   NCHAR(8)    
                    
    SELECT @Date = CONVERT(NVARCHAR(12),GETDATE(),112)   
      FROM #lumim_TPDSFCBINWorkOrder     
     WHERE WorkingTag = 'A'    
       AND Status = 0      
    
    EXEC dbo._SCOMCreateNo 'PD', 'lumim_TPDSFCBINWorkOrder', @CompanySeq, 0, @Date, @MaxNo OUTPUT      
      
    --Temp Table에 생성된 키값 UPDATE  
    UPDATE #lumim_TPDSFCBINWorkOrder  
       SET BINWorkOrderNo = @MaxNo  
     WHERE WorkingTag = 'A'  
       AND Status = 0  
  
    END    
    
    SELECT * FROM #lumim_TPDSFCBINWorkOrder 
    
    RETURN 
GO
exec lumim_SPDSFCBINWorkOrderReportCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BINWorkOrderSeq>115</BINWorkOrderSeq>
    <ProdPlanSeq>1000033</ProdPlanSeq>
    <ProdPlanNo>201307260012</ProdPlanNo>
    <ItemName>test_이재천(제품)</ItemName>
    <ProgramName>test5</ProgramName>
    <THTool>AAA002</THTool>
    <BINNo>002</BINNo>
    <Rank>CIE-IC-VF</Rank>
    <PrintRank>CIE-IC-VF</PrintRank>
    <EmpId>20020102            </EmpId>
    <EmpName>백봉욱         </EmpName>
    <Position>생산조장</Position>
    <Qty>40</Qty>
    <LastDateTime>2013-08-06 21:36:25</LastDateTime>
    <BINWorkOrderNo>201308060077</BINWorkOrderNo>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BINWorkOrderSeq>116</BINWorkOrderSeq>
    <ProdPlanSeq>1000035</ProdPlanSeq>
    <ProdPlanNo>201308090001</ProdPlanNo>
    <ItemName>제품_이지은</ItemName>
    <ProgramName>제품</ProgramName>
    <THTool>AAA007</THTool>
    <BINNo>007</BINNo>
    <Rank />
    <PrintRank />
    <EmpId>20030205            </EmpId>
    <EmpName>남민호         </EmpName>
    <Position>자재담당</Position>
    <Qty>10000</Qty>
    <LastDateTime>2013-08-06 21:41:23</LastDateTime>
    <BINWorkOrderNo>201308060078</BINWorkOrderNo>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BINWorkOrderSeq>117</BINWorkOrderSeq>
    <ProdPlanSeq>1000035</ProdPlanSeq>
    <ProdPlanNo>201308090001</ProdPlanNo>
    <ItemName>제품_이지은</ItemName>
    <ProgramName>제품</ProgramName>
    <THTool>AAA008</THTool>
    <BINNo>008</BINNo>
    <Rank />
    <PrintRank />
    <EmpId>20041103            </EmpId>
    <EmpName>황구현         </EmpName>
    <Position>생산조장</Position>
    <Qty>1000</Qty>
    <LastDateTime>2013-08-06 21:43:02</LastDateTime>
    <BINWorkOrderNo>201308060079</BINWorkOrderNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016984,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014493