IF OBJECT_ID('KPXLS_SCOMCloseItemNew') IS NOT NULL 
    DROP PROC KPXLS_SCOMCloseItemNew
GO 

-- v2016.02.16 

-- KPXLS용 예약마감 스케쥴링 by이재천 

CREATE Proc KPXLS_SCOMCloseItemNew

		   @CompanySeq INT = 3

  

as

   declare @xmlTemp     NVARCHAR(MAX)

          ,@xmlTemp1    NVARCHAR(MAX)

         ,@ClosingSeq  INT

         ,@ClosingYM   NCHAR(6)

		 ,@ResultMessage NVARCHAR(100)

		 ,@UnitSeq		INT 

		 ,@Cnt			INT

		 ,@MaxCnt		INT

		 ,@ClosingSeq2  INT

		 ,@AccUnit		INT 

		 ,@SeqCnt		INT

		 ,@MaxSeqCnt	INT

		 ,@ResultStatus	INT 

		 ,@WorkingTag2  NCHAR(1)

		 ,@WorkingTag3  NCHAR(1)

   





   CREATE TABLE #KPX_TCOMReservationYMClosing (IDX INT IDENTITY (1,1), ClosingSeq INT)

   INSERT INTO #KPX_TCOMReservationYMClosing       

   select  A.ClosingSeq

     from KPX_TCOMReservationYMClosing AS A

    where A.CompanySeq = @CompanySeq

      and Isnull(A.ProcDate,'') = ''

      and A.ReservationDate <= Convert(NVARCHAR,GetDate(),112)

      and A.ReservationTime <= SubString(Convert(NVARCHAR,GetDAte(),120),12,2) + SubString(Convert(NVARCHAR,GetDAte(),120),15,2)

	  AND A.IsCancel ='0'

	--CREATE TABLE #KPX_TCOMReservationYMClosing (IDX INT IDENTITY (1,1), ClosingSeq INT)

 --  INSERT INTO #KPX_TCOMReservationYMClosing       

 --  select  A.ClosingSeq

 --    from KPX_TCOMReservationYMClosing AS A

 --   where A.CompanySeq = @CompanySeq
	--  AND A.ClosingYM = '201507'
 --     --and Isnull(A.ProcDate,'') = ''

 --    -- and A.ReservationDate <= Convert(NVARCHAR,GetDate(),112)

 --     --and A.ReservationTime <= SubString(Convert(NVARCHAR,GetDAte(),120),12,2) + SubString(Convert(NVARCHAR,GetDAte(),120),15,2)

	--  --AND A.IsCancel ='0'

    




	CREATE TABLE #ClosingSeq (IDX INT IDENTITY (1,1), ClosingSeq INT)

	INSERT INTO #ClosingSeq 

	SELECT (62)

	UNION

	SELECT (69)

	UNION 

	SELECT (1290)

	UNION

	SELECT (1292) 

	

	SELECT @MaxCnt = MAX(IDX), @Cnt=1 FROM #ClosingSeq



	CREATE TABLE #TESMCProdClosingInOutCheck (WorkingTag NCHAR(1) NULL)    

       EXEC dbo._SCAOpenXmlToTemp @xmlTemp, 2,@CompanySeq,6561, 'DataBlock1', '#TESMCProdClosingInOutCheck'  



	CREATE TABLE #TCOMClosingYMCheck (WorkingTag NCHAR(1) NULL)    

	EXEC dbo._SCAOpenXmlToTemp @xmlTemp, 2,@CompanySeq,3436, 'DataBlock3', '#TCOMClosingYMCheck'  

	

	SELECT  @MaxSeqCnt = MAX(IDX),  @SeqCnt = 1 FROM #KPX_TCOMReservationYMClosing 





	WHILE (@SeqCnt <= @MaxSeqCnt)

	BEGIN

		

		



		SELECT @ClosingSeq = ClosingSeq FROM #KPX_TCOMReservationYMClosing WHERE IDX = @SeqCnt

		SELECT @AccUnit = AccUnit, @ClosingYM = ClosingYM FROM KPX_TCOMReservationYMClosing WHERE CompanySeq=@CompanySeq AND ClosingSeq = @ClosingSeq

		SET @ResultStatus = 0 

		SET @Cnt = 1

		SET @ResultStatus = 0 



		



		WHILE (@Cnt <= @MaxCnt)

		BEGIN

		

		

		TRUNCATE TABLE #TESMCProdClosingInOutCheck

		TRUNCATE TABLE #TCOMClosingYMCheck



		SELECT @ClosingSeq2 = ClosingSeq FROM #ClosingSeq WHERE IDX =@Cnt



		

		IF @ClosingSeq2 IN (1290)

		BEGIN

			

			SELECT @UnitSeq = B.FactUnit 

			FROM _TDABizUnit AS A

			LEFT OUTER JOIN _TDAFactUnit AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 

														  AND B.BizUnit	   = A.BizUnit

			WHERE A.CompanySeq = @CompanySeq

			  AND A.AccUnit	   = @AccUnit

    



			END

			ELSE IF @ClosingSeq2 IN (62,1292,69)

			BEGIN

			SELECT @UnitSeq = A.BizUnit

			FROM _TDABizUnit AS A

			WHERE A.CompanySeq = @CompanySeq

			  AND A.AccUnit	   = @AccUnit



		END



		

		--62 69 1290 1292

       set @xmlTemp = N'<ROOT>

        <DataBlock3>

         <WorkingTag>U</WorkingTag>

         <IDX_NO>1</IDX_NO>

         <DataSeq>1</DataSeq>

         <Selected>0</Selected>

         <Status>0</Status>

         <ROW_IDX>1</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

         <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <DtlUnitSeq>1</DtlUnitSeq>

         <IsClose>1</IsClose>

        </DataBlock3>

        <DataBlock3>

         <WorkingTag>U</WorkingTag>

         <IDX_NO>2</IDX_NO>

         <DataSeq>2</DataSeq>

         <Selected>0</Selected>

         <Status>0</Status>

         <ROW_IDX>2</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

          <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <DtlUnitSeq>2</DtlUnitSeq>

         <IsClose>1</IsClose>

        </DataBlock3>

      </ROOT>'

      SET @xmlTemp1 =N'<ROOT>

        <DataBlock1>

         <WorkingTag>U</WorkingTag>

         <IDX_NO>1</IDX_NO>

         <DataSeq>1</DataSeq>

         <Status>0</Status>

         <Selected>0</Selected>


         <ROW_IDX>3</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <IsClose>1</IsClose>

         <DtlUnitSeq>1</DtlUnitSeq>

         <TABLE_NAME>DataBlock1</TABLE_NAME>

         <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

        </DataBlock1>

        <DataBlock1>

         <WorkingTag>U</WorkingTag>

         <IDX_NO>2</IDX_NO>

         <DataSeq>2</DataSeq>

         <Status>0</Status>

         <Selected>0</Selected>

         <ROW_IDX>3</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <IsClose>1</IsClose>

         <DtlUnitSeq>2</DtlUnitSeq>

         <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

        </DataBlock1>

      </ROOT>'

      

	  -----이미 수동마감처리 되어 있으면 마감처리 안함
	  --IF EXISTS (SELECT TOP(1) 1 FROM _TCOMClosingYM WHERE CompanySeq = 1 AND ClosingSeq = @ClosingSeq2 AND ClosingYM = @ClosingYM AND UnitSeq = @UnitSeq AND IsClose='1')
	  --BEGIN
			-- UPDATE KPX_TCOMReservationYMClosing

			--	 SET ProcDate = '실패',		

			--		 ProcResult = '기존에 마감처리 되어 있어 자동마감처리 실패하였습니다.'

			--	FROM KPX_TCOMReservationYMClosing

			--   where CompanySeq = @CompanySeq

			--	  and ClosingSeq = @ClosingSeq

			--	  and ClosingYM  = @ClosingYM

			--SET @ResultStatus = 999
			
	  --END

	 

     

	  INSERT INTO #TESMCProdClosingInOutCheck

        exec KPXLS_SESMCProdClosingInOutCheck @xmlDocument=@xmlTemp1,@xmlFlags=2,@ServiceSeq=6561,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857

       IF @@ERROR <> 0               

        BEGIN     

			 

            RAISERROR('Error during ''EXEC KPXLS_SESMCProdClosingInOutCheck''', 15, 1) 

            RETURN   

        END          

        IF Exists (select 1 from #TESMCProdClosingInOutCheck where Status <> 0 AND @ResultStatus = 0  ) 

        begin

			 SELECT @ResultMessage = CASE WHEN MIN(Status) = 991 THEN '마이너스 재고가 존재하여 예약마감이 실패하였습니다. '

										  WHEN MIN(Status) = 992 THEN '거래처별 미수금 회계/영업 비교 에서 차액이 발생하여 예약마감에 실패하였습니다. '

										  ELSE MAX(Result) END

			   FROM #TESMCProdClosingInOutCheck WHERE Status <>0



			  UPDATE KPX_TCOMReservationYMClosing

				 SET ProcDate = '실패',		

					 ProcResult = @ResultMessage

				FROM KPX_TCOMReservationYMClosing

			   where CompanySeq = @CompanySeq

				  and ClosingSeq = @ClosingSeq

				  and ClosingYM  = @ClosingYM

			SET @ResultStatus = 999

            --RAISERROR('Error during ''EXEC KPXLS_SESMCProdClosingInOutCheck''', 15, 1) 

            --RETURN   

        end

        

      

      

       Insert into #TCOMClosingYMCheck

       exec KPXLS_SCOMClosingYMCheck @xmlDocument=@xmlTemp,@xmlFlags=2,@ServiceSeq=3436,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857



       IF @@ERROR <> 0               

        BEGIN   

            RAISERROR('Error during ''EXEC KPXLS_SCOMClosingYMCheck''', 15, 1) 

            RETURN   

        END          

        IF Exists (select 1 from #TCOMClosingYMCheck where Status <> 0 AND @ResultStatus = 0 ) 

        begin

			 SELECT @ResultMessage = CASE WHEN MIN(Status) = 991 THEN '마이너스 재고가 존재하여 예약마감이 실패하였습니다. '

										  WHEN MIN(Status) = 992 THEN '거래처별 미수금 회계/영업 비교 에서 차액이 발생하여 예약마감에 실패하였습니다. '

										  ELSE MAX(Result) END

			   FROM #TCOMClosingYMCheck WHERE Status <>0



			  UPDATE KPX_TCOMReservationYMClosing

				 SET ProcDate = '실패',		

					 ProcResult = @ResultMessage

				FROM KPX_TCOMReservationYMClosing

			   where CompanySeq = @CompanySeq

				  and ClosingSeq = @ClosingSeq

				  and ClosingYM  = @ClosingYM

				  



			SET @ResultStatus = 999

            --RAISERROR('Error during ''EXEC KPXLS_SCOMClosingYMCheck''', 15, 1) 

            --RETURN   

        end

	 

	





	  SET @Cnt = @Cnt + 1

	  END



	 SET @Cnt = 1

	 WHILE (@Cnt <= @MaxCnt)

	 BEGIN



	



	 IF  @ResultStatus = 0 

	 BEGIN

	 --SELECT 11,@SeqCnt, @Cnt, @ResultStatus

	 SELECT @ClosingSeq2 = ClosingSeq FROM #ClosingSeq WHERE IDX =@Cnt



		

			IF @ClosingSeq2 IN (1290)

			BEGIN

			

			SELECT @UnitSeq = B.FactUnit 

			FROM _TDABizUnit AS A

			LEFT OUTER JOIN _TDAFactUnit AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq 

														  AND B.BizUnit	   = A.BizUnit

			WHERE A.CompanySeq = @CompanySeq

			  AND A.AccUnit	   = @AccUnit

    



			END

			ELSE IF @ClosingSeq2 IN (62,1292,69)

			BEGIN

			SELECT @UnitSeq = A.BizUnit

			FROM _TDABizUnit AS A

			WHERE A.CompanySeq = @CompanySeq

			  AND A.AccUnit	   = @AccUnit



			END

		


		--SELECT @ClosingSeq2,@UnitSeq

		

		IF EXISTS (SELECT TOP(1) 1 FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND UnitSeq= @UnitSeq AND ClosingSeq = @ClosingSeq2 AND DtlUnitSeq = 1 AND ClosingYM = @ClosingYM)

		BEGIN 

			SELECT @WorkingTag2 = 'U'

		END

		ELSE 

		BEGIN

			SELECT @WorkingTag2 = 'A'

		END



		IF EXISTS (SELECT TOP(1) 1 FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND UnitSeq= @UnitSeq AND ClosingSeq = @ClosingSeq2 AND DtlUnitSeq = 2 AND ClosingYM = @ClosingYM)

		BEGIN 

			SELECT @WorkingTag3 = 'U'

		END

		ELSE 

		BEGIN

			SELECT @WorkingTag3 = 'A'

		END



		set @xmlTemp = N'<ROOT>'

		

		IF @ClosingSeq2 NOT IN (1292)

		BEGIN

	    set @xmlTemp = @xmlTemp+

        '<DataBlock3>

         <WorkingTag>'+@WorkingTag2+'</WorkingTag>

         <IDX_NO>1</IDX_NO>

         <DataSeq>1</DataSeq>

         <Selected>0</Selected>

         <Status>0</Status>

         <ROW_IDX>1</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

         <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <DtlUnitSeq>1</DtlUnitSeq>

         <IsClose>1</IsClose>

        </DataBlock3>'

		END



		IF @ClosingSeq2  IN (69,1292)

		BEGIN

        SET @xmlTemp = @xmlTemp+

		'<DataBlock3>

         <WorkingTag>'+@WorkingTag3+'</WorkingTag>

         <IDX_NO>2</IDX_NO>

         <DataSeq>2</DataSeq>

         <Selected>0</Selected>

         <Status>0</Status>

         <ROW_IDX>2</ROW_IDX>

         <ClosingYM>'+@ClosingYM+'</ClosingYM>

         <ClosingSeq>'+Convert(NVARCHAR,@ClosingSeq2)+'</ClosingSeq>

          <UnitSeq>'+Convert(NVARCHAR,@UnitSeq)+'</UnitSeq>

         <DtlUnitSeq>2</DtlUnitSeq>

         <IsClose>1</IsClose>

        </DataBlock3>

      </ROOT>'

	  END

	  ELSE

	  BEGIN

	  SET @xmlTemp = @xmlTemp+'</ROOT>'

	  END



	  



       exec _SCOMClosingYMSave @xmlDocument=@xmlTemp,@xmlFlags=2,@ServiceSeq=3436,@WorkingTag=N'',@CompanySeq=@CompanySeq,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857

	            

      IF @@ERROR <> 0    

      BEGIN

           RAISERROR('Error during ''EXEC _SCOMClosingYMSave''', 15, 1)    

          RETURN    

      END     

	  

	  

	  

      UPDATE KPX_TCOMReservationYMClosing

         SET ProcDate = Convert(NVARCHAR,GetDate(),112)+SubString(Convert(NVARCHAR,GetDAte(),120),12,2) + SubString(Convert(NVARCHAR,GetDAte(),120),15,2)

           --  ,ReservationTime = SubString(Convert(NVARCHAR,GetDAte(),120),12,2) + SubString(Convert(NVARCHAR,GetDAte(),120),15,2)

       where CompanySeq = @CompanySeq

          and ClosingSeq = @ClosingSeq

          and ClosingYM  = @ClosingYM

		  and ISNULL(ProcDate,'') != '실패'

	  END



		

	  SET @Cnt = @Cnt + 1

	  END



	

		

	  SET @SeqCnt = @SeqCnt + 1

	END



RETURN

GO


