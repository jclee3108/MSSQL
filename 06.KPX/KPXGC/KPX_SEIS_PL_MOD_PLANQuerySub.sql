  
IF OBJECT_ID('KPX_SEIS_PL_MOD_PLANQuerySub') IS NOT NULL   
    DROP PROC KPX_SEIS_PL_MOD_PLANQuerySub  
GO  
  
-- v2014.11.24  
  
-- (경영정보)손익 수정 계획-데이터가져오기 by 이재천   
CREATE PROC KPX_SEIS_PL_MOD_PLANQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   

      
    CREATE TABLE #KPX_TEIS_PL_MOD_PLAN (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_PL_MOD_PLAN'   
    IF @@ERROR <> 0 RETURN    
    
    
    DECLARE @BizUnit            INT,  
            @PlanYM             NCHAR(6), 
            @ToAccYM            NCHAR(6), 
            @FrSttlYM           NCHAR(6), 
            @ToSttlYM           NCHAR(6), 
            @FormatSeq          INT, 
            @IsUseUMCostType    NCHAR(1), 
            @argLanguageSeq     INT 
    
    SELECT @BizUnit = ( SELECT TOP 1 BizUnit FROM #KPX_TEIS_PL_MOD_PLAN ) 
    SELECT @PlanYM = ( SELECT TOP 1 PlanYM FROM #KPX_TEIS_PL_MOD_PLAN ) 
    
    
    IF LEN(LTRIM(RTRIM(ISNULL(@PlanYM,'')))) = 6  
    BEGIN  
        SELECT @ToAccYM = @PlanYM  
    END  
    ELSE  
    BEGIN  
    
    -- 1월법인이 아닌 경우 전년도의 데이터를 가져오는 경우가 발생하여 수정함 2011.08.18 dykim  
        SELECT @ToAccYM = FrSttlYM   
          FROM _TDAAccFiscal   
         WHERE CompanySeq = @CompanySeq  
           AND FiscalYear = LEFT(@PlanYM,4)   
    END  
    
    EXEC _SACGetAccTerm @CompanySeq     = @CompanySeq       ,  
                        @CurrDate       = @ToAccYM        ,  
                        @FrYM           = @FrSttlYM OUTPUT      ,  
                        @ToYM           = @ToSttlYM OUTPUT        
    
    -- 재무제표구조마스터 선택  
    SELECT TOP 1 @FormatSeq   = A.FormatSeq,           -- 재무제표구조코드  
                 @IsUseUMCostType = B.IsUseUMCostType  -- 비용구분 사용여부  
      FROM _TCOMFSForm AS A WITH (NOLOCK)  
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq    
      JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq    
     WHERE A.CompanySeq   = @CompanySeq  
       AND C.FSKindNo     = 'IS'                  -- 재무제표종류코드  
       AND A.FSDomainSeq  = 11               -- 재무제표구조영역  
       AND A.IsDefault    = '1'   
       AND @ToAccYM BETWEEN A.FrYM AND A.ToYM          -- 기간내에 하나만 존재  
    
    -- 비용구분 사용여부를 읽어온다.    
    SELECT  @IsUseUMCostType = B.IsUseUMCostType    
      FROM _TCOMFSForm AS A WITH (NOLOCK)    
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq    
     WHERE A.CompanySeq   = @CompanySeq    
       AND A.FormatSeq    = @FormatSeq    
    
    CREATE TABLE #Temp  
    (  
        RowNum      INT IDENTITY(0, 1)  
    )  
    
    ALTER TABLE #Temp ADD ThisTermItemAmt       DECIMAL(19, 5)  -- 당기항목금액  
    ALTER TABLE #Temp ADD ThisTermAmt           DECIMAL(19, 5)  -- 당기금액  
    ALTER TABLE #Temp ADD PrevTermItemAmt       DECIMAL(19, 5)  -- 전기항목금액  
    ALTER TABLE #Temp ADD PrevTermAmt           DECIMAL(19, 5)  -- 전기금액  
    ALTER TABLE #Temp ADD PrevChildAmt          DECIMAL(19, 5)  -- 하위금액  
    ALTER TABLE #Temp ADD ThisChildAmt          DECIMAL(19, 5)  -- 하위금액  
    ALTER TABLE #Temp ADD ThisReplaceFormula    NVARCHAR(1000)   -- 당기금액  
    ALTER TABLE #Temp ADD PrevReplaceFormula    NVARCHAR(1000)   -- 전기금액   
    -- 재무제표 기본 초기 형태 생성  
    EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, @argLanguageSeq, '#Temp'  
    IF @@ERROR <> 0  RETURN  
    
    -- 표시양식에서 지워지지 않도록 하기 위해 1로 업데이트한다.  
    UPDATE  #Temp  
       SET  ThisTermAmt  = 1  
    
    -- 표시양식 적용  
    EXEC _SCOMFSFormApplyStyle @CompanySeq, @FormatSeq, '#Temp', '0'--, @IsDisplayZero  
    IF @@ERROR <> 0  RETURN  
    
    UPDATE A 
       SET AccSeq = B.FSItemSeq, 
           AccName = B.FSItemNamePrt
      from #KPX_TEIS_PL_MOD_PLAN AS A 
      JOIN #Temp                 AS B ON ( A.AccName = LTRIM(B.FSItemNamePrt) ) 
    
    SELECT AccName, 
           AccSeq, 
           EstAmt, 
           ModAmt 
      FROM #KPX_TEIS_PL_MOD_PLAN 

    RETURN  
GO 
exec KPX_SEIS_PL_MOD_PLANQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <AccName>  I. 자    산</AccName>
    <ModAmt>123124</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>    (1) 유동자산</AccName>
    <ModAmt>123123</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>      1. 당좌자산</AccName>
    <ModAmt>34234</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        1) 현금및현금성자산</AccName>
    <ModAmt>123123</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               현금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1.</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2.</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 당좌예금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 별단예금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. 기타현금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          6. test계정</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               국고보조금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        2) 단기투자자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 단기투자자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. 단기예금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 단기적금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 단기매매증권(유가증권)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. 외화정기예금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        3) 기타 당좌자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        4) 매출채권</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               외상매출금대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 외화외상매출금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               외화외상매출금대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. 받을어음</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               받을어음 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 부도어음</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 부도어음 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. 외상매출금(매출)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               외상매출금(청구)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          6. 외상매출금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        5) 단기대여금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 단기대여금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. 단기대여금 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 어음대여금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 어음대여금 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          5. 주.임.종 단기대여금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        6) 미수수익</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 미수수익</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               미수수익 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        7) 선급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 선급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               선급금 대손충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               국고보조금(선급금차감)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        8) 기타 당좌자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        9) 선급비용</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 선급비용</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        10) 전도금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 전도금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        11) 가지급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 가지급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               수입가지급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        12) 선급법인세</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 선급법인세/중간예납</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               선급법인세/이자소득</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        13) 선급세금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 선급세금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        14) 부가세대급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 부가세대급금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>             이연법인세자산(유동)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 이연법인세자산(유동)</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        15) 자기사채</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>               자기사채</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        16) 기타유동자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 기타유동자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>      2. 재고자산</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        1) 상품</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 상품</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. 상품 재고자산평가충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 상품에서 타계정으로대체</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 타계정에서 상품으로대체액</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>        2) 제품</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          1. 제품</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          2. 제품 재고자산평가충당금</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          3. 타계정에서 제품으로대체액</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
  <DataBlock1>
    <AccName>          4. 제품에서 타계정으로대체액</AccName>
    <ModAmt>0</ModAmt>
    <BizUnit>1</BizUnit>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021885