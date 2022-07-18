IF OBJECT_ID('KPXLS_SCOMClosingYMCheck') IS NOT NULL 
    DROP PROC KPXLS_SCOMClosingYMCheck
GO 

-- v2016.02.16 



/************************************************************  

설  명 - 월마감확인          

작성일 - 2008년 12월 17일   

작성자 - 조성환  

************************************************************/  

CREATE PROC KPXLS_SCOMClosingYMCheck

    @xmlDocument    NVARCHAR(MAX),    

    @xmlFlags       INT = 0,    

    @ServiceSeq     INT = 0,    

    @WorkingTag     NVARCHAR(10)= '',    

    @CompanySeq     INT = 1,    

    @LanguageSeq    INT = 1,    

    @UserSeq        INT = 0,    

    @PgmSeq         INT = 0    

AS      

    DECLARE @Count       INT,  

            @Seq         INT,  

            @MessageType INT,  

            @Status      INT,  

            @Results     NVARCHAR(250)  

	

    -- 서비스 마스타 등록 생성  

    CREATE TABLE #TCOMClosingYM (WorkingTag NCHAR(1) NULL)    

    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TCOMClosingYM'       

    IF @@ERROR <> 0 RETURN   

	

	-- 재고 이월처리 되였으면 마감 취소 못하게 수정함, 2012.01.10 by 김철웅 

	SELECT CONVERT( VARCHAR(6), DATEADD( YEAR, 1, CONVERT( datetime, LEFT( A.ClosingYM, 4 )+'0101' ) ), 112 ) AS StkYM, 

		   A.UnitSeq AS BizUnit

	  INTO #Temp 

	  FROM #TCOMClosingYM AS A 

	  JOIN _TCOMClosingYM AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ClosingSeq = B.ClosingSeq AND A.ClosingYM = B.ClosingYM AND A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq )

	 WHERE A.ClosingSeq = 69 

	   AND A.IsClose = 0 

	   AND B.IsClose = 1

	 GROUP BY LEFT( A.ClosingYM, 4 ), A.UnitSeq 

	

	IF EXISTS (

		SELECT 1  

		  FROM _TLGWHStock		AS A WITH(NOLOCK)

		  JOIN _TDAWH			AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.WHSeq = B.WHSeq ) 

		  JOIN #Temp			AS C ON ( A.StkYM = C.StkYM AND B.BizUnit = C.BizUnit )

		 WHERE A.CompanySeq = @CompanySeq 

		   AND ISNULL( A.PrevQty, 0 ) <> 0  

	)

	BEGIN

		DECLARE @Word1 NVARCHAR(200)

		

		SELECT @Word1 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 62  

		IF @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = '년'  

		   

		-- @ClosingYM + '재고 년이월처리 하였기에 마감취소 할 수 없습니다.'   

		EXEC dbo._SCOMMessage @MessageType OUTPUT,        

							  @Status      OUTPUT,        

							  @Results     OUTPUT,        

							  1339               , -- (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1338)        

							  @LanguageSeq       ,         

							  0, '' -- SELECT * FROM _TCADictionary WHERE Word like '%%'        

		    

		UPDATE #TCOMClosingYM        

		   SET Result       = CONVERT( VARCHAR(4), DATEADD( YEAR, 1, CONVERT( datetime, LEFT( ClosingYM, 4 )+'0101' ) ), 112 ) + @Word1   

							+ ' '  

							+ @Results, 

			   MessageType  = @MessageType,        

			   Status       = @Status        

		  FROM #TCOMClosingYM    

		    

		SELECT * FROM #TCOMClosingYM  

		    

		RETURN  

	END

	

    -------------------------------------------  

    -- 중복여부체크    

    -------------------------------------------  

--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  

--                           @Status      OUTPUT,  

--                           @Results     OUTPUT,  

--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  

--                           @LanguageSeq       ,   

--                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  

--     UPDATE #TCOMClosingYM  

--        SET Result        = REPLACE(@Results,'@2',B.AsstNo),  

--            MessageType   = @MessageType,  

--            Status        = @Status  

--       FROM #TCOMClosingYM AS A JOIN ( SELECT S.AsstNo  

--                                      FROM (  

--                                            SELECT A1.AsstNo  

--                                              FROM #TCOMClosingYM AS A1  

--                                             WHERE A1.WorkingTag IN ('A', 'U')  

--                                               AND A1.Status = 0  

--                                            UNION ALL  

--                                             SELECT A1.AsstNo  

--                                              FROM _TCOMClosingYM AS A1  

--                                             WHERE A1.CompanySeq = @CompanySeq  

--                                               AND A1.AsstSeq NOT IN (SELECT AsstSeq   

--                                                                      FROM #TCOMClosingYM   

--                                                                      WHERE WorkingTag IN ('U','D')   

--                                                                         AND Status = 0)  

--                                           ) AS S  

--                                     GROUP BY S.AsstNo  

--                                     HAVING COUNT(1) > 1  

--                                   ) AS B ON (A.AsstNo = B.AsstNo)  

--   

--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  

--                           @Status      OUTPUT,  

--                           @Results     OUTPUT,  

--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  

--                           @LanguageSeq       ,   

--                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  

--     UPDATE #TDABankAccSub  

--        SET Result        = @Results,  

--            MessageType   = @MessageType,  

--            Status        = @Status  

--       FROM #TDABankAccSub AS A JOIN ( SELECT S.BankAccSeq, S.AccSeq  

--                                           FROM (  

--                                            SELECT A1.BankAccSeq, A1.AccSeq  

--                                              FROM #TDABankAccSub AS A1  

--                                             WHERE A1.WorkingTag IN ('A', 'U')  

--                                               AND A1.Status = 0  

--                                            UNION ALL  

--                                            SELECT A1.BankAccSeq, A1.AccSeq  

--                                              FROM _TDABankAccSub AS A1  

--                                             WHERE A1.CompanySeq = @CompanySeq  

--                                               AND NOT EXISTS (SELECT *  

--                                                                FROM #TDABankAccSub   

--                                                               WHERE WorkingTag IN ('U','D')   

--                                                                 AND Status = 0  

--                                                                 AND BankAccSeq = A1.BankAccSeq  

--                                                                 AND AccSeq = A1.AccSeq)  

--                                           ) AS S  

--                                     GROUP BY S.BankAccSeq, S.AccSeq  

--                                     HAVING COUNT(1) > 1  

--                                   ) AS B ON (A.BankAccSeq = B.BankAccSeq AND A.AccSeq = B.AccSeq)    

  

  

    -------------------------------------------  

    -- NOT EXISTS   

    -------------------------------------------  

      

       

    UPDATE #TCOMClosingYM  

       SET WorkingTag = 'A'   

      FROM #TCOMClosingYM AS A  

                LEFT OUTER JOIN _TCOMClosingYM AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq   

                                                                AND A.ClosingSeq = B.ClosingSeq   

                                                                AND A.ClosingYM = B.ClosingYM   

                                                                AND ISNULL(A.UnitSeq, 0) = B.UnitSeq   

                                                                AND ISNULL(A.DtlUnitSeq, 0) = B.DtlUnitSeq   

     WHERE Status = 0  

       AND WorkingTag IN ('U', 'A')  

       AND ISNULL(B.ClosingSeq, '') = ''   

  

 

      

  

  

    

  

    -------------------------------------------  

    -- INSERT 번호부여(맨 마지막 처리)  

    -------------------------------------------  

--     SELECT @Count = COUNT(1) FROM #TCOMClosingYM WHERE WorkingTag = 'A' AND Status = 0  

--     IF @Count > 0  

--     BEGIN    

--         -- 키값생성코드부분 시작    

--         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TCOMClosingYM', 'AsstSeq', @Count  

--         -- Temp Talbe 에 생성된 키값 UPDATE  

--         UPDATE #TCOMClosingYM  

--            SET AsstSeq = @Seq + DataSeq  

--          WHERE WorkingTag = 'A'  

--            AND Status = 0  

--     END     

-----------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------KPX용 마감 체크로직 추가----------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
	DECLARE @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT,   @AccUnit INT, @UnitSeq INT, @BizUnit INT          
	DECLARE @Cnt INT, @MaxCnt INT, @DateFr NCHAR(8), @DateTo NCHAR(8), @ClosingSeq INT 

	SELECT @ClosingSeq = MAX(ClosingSeq) FROM #TCOMClosingYM WHERE Status = 0 
	
	

	IF @ClosingSeq IN (1290,1292)	--생산, 구매 마감일 경우 마이너스 재고 체크 
	BEGIN


	
    

    /*

    select * from _TComEnv where CompanySeq = 1 and EnvSeq  = 5521 

    */

    -- 환경설정-활동기준원가 

    SELECT @ItemPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --자재단가계산단위                       

    SELECT @GoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --상품단가계산단위                       

    SELECT @FGoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --제품단가계산단위                       

    

	

    -- 구매/자재수량소수점자리수구하기

    --SELECT @EnvMatQty = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 5

    

   
	SELECT @UnitSeq = MAX(UnitSeq)		 FROM #TCOMClosingYM  

	IF @ClosingSeq IN (1290)
	BEGIN

    SELECT @AccUnit = ISNULL(B.AccUnit, 0),
		   @BizUnit = ISNULL(A.BizUnit, 0) 
	  FROM _TDAFactUnit AS A WITH(NOLOCK)
	  LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
												   AND B.BizUnit	= A.BizUnit
	 WHERE A.CompanySeq = @CompanySeq AND FactUnit = @UnitSeq

    END
	ELSE IF @ClosingSeq IN (62,1292 )
	BEGIN
		SELECT  @AccUnit = ISNULL(A.AccUnit	,0)
			   ,@BizUnit = ISNULL(A.BizUnit	,0)
			   
		FROM _TDABizUnit AS A 
		WHERE A.CompanySeq	=	@CompanySeq
		  AND A.BizUnit		=	@UnitSeq

	END
	

    -- 대상품목 

    CREATE TABLE #GetInOutItem

    ( 

        ItemSeq INT, 

        ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- 품목소분류

        ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- 품목중분류

        ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- 품목대분류

    )

    
	
    

    -- 입출고

    CREATE TABLE #GetInOutStock

    (

        WHSeq           INT,

        FunctionWHSeq   INT,

        ItemSeq         INT,

        UnitSeq         INT,

        PrevQty         DECIMAL(19,5),

        InQty           DECIMAL(19,5),

        OutQty          DECIMAL(19,5),

        StockQty        DECIMAL(19,5),

        STDPrevQty      DECIMAL(19,5),

        STDInQty        DECIMAL(19,5),

        STDOutQty       DECIMAL(19,5),

        STDStockQty     DECIMAL(19,5)

    )

    

    -- 상세입출고내역 

    CREATE TABLE #TLGInOutStock  

    (  

        InOutType INT,  

        InOutSeq  INT,  

        InOutSerl INT,  

        DataKind  INT,  

        InOutSubSerl  INT,  

        

        InOut INT,  

        InOutDate NCHAR(8),  

        WHSeq INT,  

        FunctionWHSeq INT,  

        ItemSeq INT,  

        

        UnitSeq INT,  

        Qty DECIMAL(19,5),  

        StdQty DECIMAL(19,5),

        InOutKind INT,

        InOutDetailKind INT 

    )  

    

    -- 대상품목 담기 

    INSERT INTO #GetInOutItem

    ( 

        ItemSeq, 

        ItemClassSSeq, ItemClassSName, -- 품목소분류

        ItemClassMSeq, ItemClassMName, -- 품목중분류

        ItemClassLSeq, ItemClassLName  -- 품목대분류

    )

    SELECT DISTINCT A.ItemSeq,

           C.MinorSeq AS ItemClassSSeq, C.MinorName AS ItemClassSName, -- '품목소분류' 

	       E.MinorSeq AS ItemClassMSeq, E.MinorName AS ItemClassMName, -- '품목중분류' 

	       G.MinorSeq AS ItemClassLSeq, G.MinorName AS ItemClassLName  -- '품목대분류' 

      FROM _TDAItem                     AS A WITH (NOLOCK)

      JOIN _TDAItemSales                AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.ItemSeq = H.ItemSeq 

      JOIN _TDAItemAsset                AS I WITH (NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.AssetSeq = I.AssetSeq -- 품목자산분류 

      

      -- 소분류 

      LEFT OUTER JOIN _TDAItemClass	    AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) AND A.CompanySeq = B.CompanySeq )

      LEFT OUTER JOIN _TDAUMinor		AS C WITH(NOLOCK) ON ( B.UMItemClass = C.MinorSeq AND B.CompanySeq = C.CompanySeq AND C.IsUse = '1' )

      LEFT OUTER JOIN _TDAUMinorValue	AS D WITH(NOLOCK) ON ( C.MinorSeq = D.MinorSeq AND D.Serl in (1001,2001) AND C.MajorSeq = D.MajorSeq AND C.CompanySeq = D.CompanySeq )

      -- 중분류 

      LEFT OUTER JOIN _TDAUMinor		AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq AND E.IsUse = '1' )

      LEFT OUTER JOIN _TDAUMinorValue	AS F WITH(NOLOCK) ON ( E.MinorSeq = F.MinorSeq AND F.Serl = 2001 AND E.MajorSeq = F.MajorSeq AND E.CompanySeq = F.CompanySeq )

      -- 대분류 

      LEFT OUTER JOIN _TDAUMinor		AS G WITH(NOLOCK) ON ( F.ValueSeq = G.MinorSeq AND F.CompanySeq = G.CompanySeq AND G.IsUse = '1' )



     WHERE A.CompanySeq = @CompanySeq

       AND I.IsQty <> '1' -- 재고수량 관리 

     
	 

	 

	 SELECT @MaxCnt = MAX(IDX_NO),
			@Cnt	= 1 
	 FROM #TCOMClosingYM 
	 WHERE IsClose='1'
    
	WHILE (@Cnt <= @MaxCnt)
	BEGIN
	

	SELECT	  @DateFr = CONVERT(NCHAR(6),MAX(ClosingYM))+'01' 
			, @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,DATEADD(MM,1,CONVERT(NCHAR(6),MAX(ClosingYM))+'01' )),112)
	FROM #TCOMClosingYM
	WHERE IDX_NO = @Cnt
	  AND IsClose = '1'

	TRUNCATE TABLE #GetInOutStock
	TRUNCATE TABLE #TLGInOutStock

	

    -- 창고재고 가져오기
	 
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드

                           @BizUnit      = @BizUnit,	  -- 사업부문

						   @FactUnit     = 0,     -- 생산사업장

                           @DateFr       = @DateFr,       -- 조회기간Fr

                           @DateTo       = @DateTo,       -- 조회기간To

                           @WHSeq        = 0,			  -- 창고지정

                           @SMWHKind     = 0,			  -- 창고구분 

                           @CustSeq      = 0,			  -- 수탁거래처

                           @IsTrustCust  = '',			  -- 수탁여부

                           @IsSubDisplay = 0,			 -- 기능창고 조회

                           @IsUnitQry    = 0,    -- 단위별 조회

                           @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고

                           @MngDeptSeq   =  0,

                           @IsUseDetail  = '1'

    
	IF EXISTS (SELECT TOP(1) 1 FROM #GetInOutStock WHERE STDStockQty < 0 ) 
	BEGIN 
		
		UPDATE A
		SET  Status = 991
			,Result = ' 마이너스 재고가 존재하여 예약마감이 실패하였습니다. '
		FROM #TCOMClosingYM AS A
		WHERE A.IDX_NO = @Cnt

		BREAK 
	END
		
		
	 	
		SELECT @Cnt = @Cnt+1
	END
		
	END

	ELSE IF @ClosingSeq IN (62) --영업 마감 일 경우
	BEGIN 
		 SELECT @MaxCnt = MAX(IDX_NO),
			@Cnt	= 1 
		 FROM #TCOMClosingYM 
		 WHERE IsClose='1'

		 -- 사업부문등록 : 사업부문 & 회계단위 
		 SELECT @UnitSeq = MAX(UnitSeq)		 FROM #TCOMClosingYM  

		 SELECT @AccUnit = ISNULL(B.AccUnit, 0),
				@BizUnit = ISNULL(A.BizUnit, 0) 
	     FROM _TDAFactUnit AS A WITH(NOLOCK)
	     LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
	   												  AND B.BizUnit	= A.BizUnit
	    WHERE A.CompanySeq = @CompanySeq 
		  AND A.FactUnit = @UnitSeq


		DECLARE @CheckResult INT,  @xml NVARCHAR(MAX)
        
        
        /*
		WHILE (@Cnt <= @MaxCnt)
		BEGIN

			SELECT	  @DateFr = CONVERT(NCHAR(6),MAX(ClosingYM))+'01' 
					, @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,DATEADD(MM,1,CONVERT(NCHAR(6),MAX(ClosingYM))+'01' )),112)
			FROM #TCOMClosingYM
			WHERE IDX_NO = @Cnt
			  AND IsClose = '1'

			
		SELECT @xml=
			  N'<ROOT>
			  <DataBlock1>
				<WorkingTag>A</WorkingTag>
				<IDX_NO>1</IDX_NO>
				<Status>0</Status>
				<DataSeq>1</DataSeq>
				<Selected>1</Selected>
				<TABLE_NAME>DataBlock1</TABLE_NAME>
				<IsChangedMst>1</IsChangedMst>
				<IsDiff>1</IsDiff>
				<AccUnit>'+CONVERT(NVARCHAR(10),@AccUnit)+'</AccUnit>
				<QryDateFr>'+@DateFr+'</QryDateFr>
				<QryDateTo>'+@DateTo+'</QryDateTo>
			  </DataBlock1>
			</ROOT>'

		
	
		exec @CheckResult= KPX_SSLCustCreditCompareCheckSub @xmlDocument=@xml,@xmlFlags=2,@ServiceSeq=1031121,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025932 

		
        IF @CheckResult = 1
		BEGIN 
		
			UPDATE A
			SET  Status = 992
				,Result = '거래처별 미수금차액이 있어 마감 할 수 없습니다.'
			FROM #TCOMClosingYM AS A
			WHERE A.IDX_NO = @Cnt

			BREAK 
		END
        
		
	 	
		SELECT @Cnt = @Cnt+1
	END

        */
	END
	

   

    SELECT * FROM #TCOMClosingYM     


    RETURN


GO


