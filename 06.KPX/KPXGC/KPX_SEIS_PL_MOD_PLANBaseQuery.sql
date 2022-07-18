  
IF OBJECT_ID('KPX_SEIS_PL_MOD_PLANBaseQuery') IS NOT NULL   
    DROP PROC KPX_SEIS_PL_MOD_PLANBaseQuery  
GO  
  
-- v2014.11.24  
  
-- (경영정보)손익 수정 계획-기초데이터 조회 by 이재천   
CREATE PROC KPX_SEIS_PL_MOD_PLANBaseQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle          INT,  
            -- 조회조건   
            @BizUnit            INT,  
            @PlanYM             NCHAR(6), 
            @ToAccYM            NCHAR(6), 
            @FrSttlYM           NCHAR(6), 
            @ToSttlYM           NCHAR(6), 
            @FormatSeq          INT, 
            @IsUseUMCostType    NCHAR(1), 
            @argLanguageSeq     INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit = ISNULL( BizUnit, 0 ), 
           @PlanYM = ISNULL( PlanYM, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit     INT, 
            PlanYM      NCHAR(6)
           )    
    
    
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
    
    SELECT FSItemSeq AS AccSeq, 
           FSItemNamePrt AS AccName 
      FROM #Temp 
    
    RETURN  
GO 
exec KPX_SEIS_PL_MOD_PLANBaseQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201411</PlanYM>
    <BizUnit>1</BizUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021885