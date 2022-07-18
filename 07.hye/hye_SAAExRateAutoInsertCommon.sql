IF OBJECT_ID('hye_SAAExRateAutoInsertCommon') IS NOT NULL 
    DROP PROC hye_SAAExRateAutoInsertCommon
GO 

CREATE PROC hye_SAAExRateAutoInsertCommon
    @CompanySeq INT 
AS
    DECLARE @ExRateDate NCHAR(8)
    
    SELECT @ExRateDate = CONVERT(NCHAR(8), GETDATE(), 112)
    

    /**************************************************************************************************************************************
    =======================================================================================================================================
     연계테이블 Layout
    =======================================================================================================================================
    STD_DD              nchar       8       기준일자         
    CUR_NM_C10          nvarchar    10      통화명C10        
    CUR_NM_C8           nvarchar    8       통화명C8		    
    CASH_BUYING         nvarchar    8       현찰사실때		
    CASH_SELLING        nvarchar    8       현찰파실때		
    SENDAMT_SENDHH      nvarchar    8       송금보낼때		
    SENDAMT_RCVHH       nvarchar    8       송금받을때		
    TC_BUYING           nvarchar    8       TC사실때		    
    TC_SELL             nvarchar    8       TC파실때		    
    FORECURCHK_SELLHH   nvarchar    8       외화수표파실때	
    BUYSEL_BASE_RATE    nvarchar    8       매매기준율		
    COMMISSION_RATE     nvarchar    8       환가료율		    
    USD_CVTRATE_N7      nvarchar    8       대미환산율N7		
    QUOT_SEQ            nvarchar    10      고시회차		    
    QUOT_HH             nvarchar    20      고시시간		    
    ERP_SENDYN          nvarchar    1       ERP연계여부플래그임  ERP전송여부		
    TRANSF_DDHH         nvarchar    14      ERP연계일시필드임  전송일시		    
    =======================================================================================================================================
     연계테이블 Layout
    =======================================================================================================================================
    **************************************************************************************************************************************/
     
    -- 오늘일자 삭제 
    IF NOT EXISTS (SELECT 1 FROM HIST_INITQUOT_EXCHRATE WHERE STD_DD = @ExRateDate AND ISNULL(ERP_SENDYN, '') = 'Y')
    BEGIN
        DELETE _TDAExRate WHERE CompanySeq = @CompanySeq AND ExRateDate = @ExRateDate
    END
    
    -- 오늘일자 ERP에 적용
    INSERT INTO _TDAExRate (CompanySeq      , -- 법인코드 
                            ExRateDate      , -- 환율일자
                            CurrSeq         , -- 통화
                            SMFirstOrLast   , -- 환율받기조건  4149001:최초고시환율, 4149002:최종고시환율
                            TTM             , -- 매매기준율
                            TTB             , -- 송금보낼때
                            TTS             , -- 송금받을때
                            CASHB           , -- 현찰살때
                            CASHS           , -- 현찰팔때
                            USAExrate       , -- 대미환산
                            ChangeRate      , -- 환가료율
                            LastUserSeq     , 
                            LastDateTime    )
        SELECT @CompanySeq                                              AS CompanySeq       , -- 법인코드
               A.STD_DD                                                 AS ExRateDate       , -- 환율일자
               ISNULL(B.CurrSeq, 0)                                     AS CurrSeq          , -- 화폐코드
               4149001                                                  AS SMFirstOrLast    , -- 환율받기조건 (최초고시환율)
               CONVERT(DECIMAL(19,5), A.BUYSEL_BASE_RATE            )   AS TTM              , -- 매매기준율
               CONVERT(DECIMAL(19,5), A.SENDAMT_SENDHH              )   AS TTB              , -- 송금보낼때
               CONVERT(DECIMAL(19,5), A.SENDAMT_RCVHH               )   AS TTS              , -- 송금받을때
               CONVERT(DECIMAL(19,5), A.CASH_BUYING                 )   AS CASHB            , -- 현찰살때
               CONVERT(DECIMAL(19,5), A.CASH_SELLING                )   AS CASHS            , -- 현찰팔때
               CONVERT(DECIMAL(19,5), A.USD_CVTRATE_N7              )   AS USAExrate        , -- 대미환산
               ISNULL(CONVERT(DECIMAL(19,5), A.COMMISSION_RATE), 0  )   AS ChangeRate       , -- 환가료율
               1                                                        AS LastUserSeq      , -- 최종작업자
               GETDATE()                                                AS LastDateTime       -- 최종작업일시
          FROM HIST_INITQUOT_EXCHRATE AS A JOIN _TDACurr AS B WITH(NOLOCK)
                                      ON B.CompanySeq    = @CompanySeq
                                     AND B.CurrName      = LEFT(A.CUR_NM_C8, 3)
         WHERE A.STD_DD                 = @ExRateDate
           AND ISNULL(A.ERP_SENDYN, '') <> 'Y'
    
    UPDATE A
       SET ERP_SENDYN = 'Y'
      FROM HIST_INITQUOT_EXCHRATE AS A
     WHERE STD_DD = @ExRateDate

RETURN

GO
begin tran
exec hye_SAAExRateAutoInsertCommon 1 
rollback 
