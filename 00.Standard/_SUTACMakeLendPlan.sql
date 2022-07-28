    
IF OBJECT_ID('_SUTACMakeLendPlan') IS NOT NULL 
    DROP PROC _SUTACMakeLendPlan 
GO

-- v2014.02.24 

-- �뿩�ݳ��԰�ȹ �ڵ� ���� by����õ
/************************************************************  
��  �� - ���Ի�ȯ��ȹ �ڵ� �ۼ�  
�ۼ��� - 2008�� 11�� 28��  
�ۼ��� - ������  
input params  
        - SMRepayType       ��ȯ����  
        - Amt               ���Աݾ�  
        - InterestRate      ������  
        - LendDate          ������  
        - ForAmt            ��ȭ���Աݾ�  
        - CurrSeq           ��ȭ  
        - FrDateRepOfRepay  ��ȯ������  
        - ToDateRepOfRepay  ��ȯ������  
        - FrDateRepOfInt    ���ڰ�������  
        - ToDateRepOfInt    ���ڰ��������  
        - SMCalcMethod      ���ڰ����  
        - InterestTerm      ���ڳ����ֱ�  
        - DeferYear         ��ġ���  
        - DeferMonth        ��ġ������  
        - RepayTerm         ��ȯ�����Ⱓ  
        - RepayCnt          ��ȯȽ��  
        - OddTime           �ܼ���������ȸ��  
        - OddUnitAmt        �������ݾ�  
************************************************************/  
CREATE PROC _SUTACMakeLendPlan    
    @CompanySeq INT,    
    @TempTable  NVARCHAR(100)    
AS    
    
    -- �������� �κ�    
    DECLARE @Sql                NVARCHAR(4000),    
            @LendDate           NCHAR(8),    
            @DeferYear          INT,    
            @LendDuration       INT,    
            @SMCalcMethod       INT,    
            @InterestRate       DECIMAL(19,10),   
            @InterestRateCalc   DECIMAL(19,10),  
            @intRate            DECIMAL(19,10),     -- ������ �������� ���� �Ҽ����� �÷��־���. -- numeric��ȯ ������ 19,10���� ����  
            @tmpNum             DECIMAL(19,10),     -- ������ �������� ���� �Ҽ����� �÷��־���. -- numeric��ȯ ������ 19,10���� ����  
            @ForAmt             DECIMAL(19, 5),    
            @Amt                DECIMAL(19, 5),    
            @a                  DECIMAL(19,10),     -- ������ �������� ���� �Ҽ����� �÷��־���.    
            @b                  DECIMAL(19,10),     -- ������ �������� ���� �Ҽ����� �÷��־���.    
            @index              INT,    
            @index2             INT,    
            @tmpLendAmt         DECIMAL(19, 5),    
            @tmpLendForAmt         DECIMAL(19, 5),    
            @ToDateRepOfRepay   NCHAR(8),    
            @DeferMonth         INT,    
            @DeferDuration      INT,    
            @DayCntOfYear       INT,   
            @DayCntOfYearCalc       INT,    
            @duration           INT,    
            @CalcedPayAmt       DECIMAL(19, 5),    
            @CalcedPayForAmt       DECIMAL(19, 5),    
            @PayCnt             INT,    
            @PayCnt2             INT,   --���ݾȿ����� ī��Ʈ �ܼ�����ȸ�� �־��ֱ� ���ؼ�    
            @balance            DECIMAL(19, 5),    
            @prevBalanceForAmt  DECIMAL(19, 5),    
            @prevBalanceAmt     DECIMAL(19, 5),    
            @PayIntAmt          DECIMAL(19, 5),   
            @PayIntSUMAmt       DECIMAL(19, 5),  
            @TotAmt             DECIMAL(19, 5),    
            @PayAmt             DECIMAL(19, 5),    
            @ExRate             DECIMAL(19, 6),    
            @balanceAmt         DECIMAL(19, 5),    
            @PayForIntAmt       DECIMAL(19, 5),    
            @PayForIntSUMAmt    DECIMAL(19, 5),    
            @PayForAmt          DECIMAL(19, 5),    
            @TotForAmt          DECIMAL(19, 5),    
            @BalanceForAmt      DECIMAL(19, 5),    
            @SMRepayType        INT,    
            @CurrSeq            INT,    
            @FrDateRepOfRepay   NCHAR(8),    
            @FrDateRepOfInt     NCHAR(8),    
            @ToDateRepOfInt     NCHAR(8),    
            @InterestTerm       INT,    
            @RepayTerm          INT,    
            @RepayCnt           INT,    
            @OddTime            INT,    
            @OddUnitAmt         DECIMAL(19, 5),    
            @date               NCHAR(8),    
            @FrDate             NCHAR(8),    
            @ToDate             NCHAR(8),    
            @LastToDate             NCHAR(8),    
            @PayDate            NCHAR(8),    
            @TotalLendMonthOpt      INT, --��ȯ���� Ƚ��    
            @TotalLendMonthInt      INT,  --�������� Ƚ��    
            @LendSeq                 INT,    
            @SMInterestPayWay       INT,    
            @DiffDay                INT,  
    
            @PayIntAmt2          DECIMAL(19, 5),    
            @TotAmt2            DECIMAL(19, 5),    
            @PayAmt2            DECIMAL(19, 5),    
            @PayForIntAmt2          DECIMAL(19, 5),    
            @TotForAmt2            DECIMAL(19, 5),    
            @PayForAmt2            DECIMAL(19, 5),  
              
            @IntDayCountType        INT,  
            @BasicAmt    INT  
      
    SELECT  @PayIntAmt2    = ISNULL(@PayIntAmt2, 0),    
            @TotAmt2        = ISNULL(@TotAmt2, 0),    
            @PayAmt2        = ISNULL(@PayAmt2, 0),    
            @PayForIntAmt2    = ISNULL(@PayForIntAmt2, 0),    
            @TotForAmt2        = ISNULL(@TotForAmt2, 0),    
            @PayForAmt2        = ISNULL(@PayForAmt2, 0),   
      
            @IntDayCountType = ISNULL(@IntDayCountType,4554001) -- �⺻�� ����ֱ�   
      
    SELECT @SMRepayType         = SMRepayType,    
           @Amt                 = Amt,    
           @InterestRate        = InterestRate,    
           @LendDate            = LendDate,    
           @ForAmt              = ForAmt,    
           @CurrSeq             = CurrSeq,    
           @ExRate              = ExRate,    
           @FrDateRepOfRepay    = FrDateRepOfRepay,    
           @ToDateRepOfRepay    = ToDateRepOfRepay,    
           @FrDateRepOfInt      = FrDateRepOfInt,    
           @ToDateRepOfInt      = ToDateRepOfInt,    
           @SMCalcMethod        = SMCalcMethod,    
           @InterestTerm        = CASE WHEN ISNULL(InterestTerm, 0) = 0 THEN 1     
                                  ELSE InterestTerm END,    
           @DeferYear           = DeferYear,    
           @DeferMonth          = DeferMonth,    
           @RepayTerm           = RepayTerm,    
           @RepayCnt            = RepayCnt,    
           @OddTime             = OddTime,    
           @OddUnitAmt          = OddUnitAmt,    
           @LendSeq             = LendSeq,   
             
           @IntDayCountType     = ISNULL(IntDayCountType,4554001) -- ������ֱ�   
    
      FROM #tmp   
    
    SELECT @BasicAmt = CASE WHEN ISNULL(BasicAmt, 0) = 0 THEN 1  
          ELSE BasicAmt END  
      FROM _TDACurr WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND CurrSeq = @CurrSeq  
    
    --select @IntDayCountType  
    
    CREATE TABLE #Temp_LendRepayOpt  
    (    
        PayCnt INT, InterestRate DECIMAL(19, 6), PayIntAmt DECIMAL(19, 5), PayAmt DECIMAL(19, 5), TotAmt DECIMAL(19, 5),     
        balanceAmt DECIMAL(19, 5), PayForIntAmt DECIMAL(19, 5), PayForAmt DECIMAL(19, 5), TotForAmt DECIMAL(19, 5), BalanceForAmt DECIMAL(19, 5),    
        FrDate NCHAR(8), ToDate NCHAR(8), PayDate NCHAR(8), SMInterestOrCapital INT, IsOddTime NCHAR(1)  
    )      
    
    --select @DeferYear, @DeferMonth, @RepayTerm, @RepayCnt   
    
    SET @LendDuration = @DeferYear*12 + @DeferMonth + @RepayTerm*@RepayCnt   -- ����Ⱓ    
    SET @DeferDuration = @DeferYear*12 + @DeferMonth                -- ��ġ�Ⱓ    
    SET @duration = @LendDuration - @DeferDuration                  -- (����Ⱓ - ��ġ�Ⱓ)    
    
    IF @duration = 0     
    BEGIN    
        SELECT @duration = 1    
    END    
    
    IF @SMRepayType = 4079003 --�����Ͻû�ȯ    
    BEGIN    
        IF ISNULL(@LendDuration, 0) = 0    
        BEGIN    
            SELECT @LendDuration = 1    
        END    
        
        IF ISNULL(@RepayTerm, 0) = 0    
        BEGIN    
            SELECT @RepayTerm = 1    
        END    
    END    
    
    SELECT @SMInterestpayWay = SMInterestpayWay    
      FROM _TACLendInterestOpt     
     WHERE CompanySeq = @CompanySeq    
       AND LendSeq    = @LendSeq    
       AND Serl = (SELECT MAX(Serl)    
                    FROM _TACLendInterestOpt     
                   WHERE CompanySeq = @CompanySeq    
                     AND LendSeq    = @LendSeq)    
    
    SELECT @TotalLendMonthOpt = @DeferDuration + @RepayCnt              --��ȯ���� Ƚ��    
    SELECT @TotalLendMonthInt =  FLOOR((DATEDIFF(MONTH, @FrDateRepOfInt, @ToDateRepOfInt) + 1 )*1.00/@InterestTerm   )        --��������Ƚ�� �ø�����    
  
    --�Ѵ޿� ��ȯó���Ǵ� ���, ��ȯ��ȹ�� ������ ���� �ʱ� ������ ������ 1���� Ÿ���� �Ѵ�.  
    IF ISNULL(@TotalLendMonthInt,0) = 0 SELECT @TotalLendMonthInt = 1  
      
    -- ���ݱյ��ȯ ��� ����    
    IF @SMRepayType = 4079001    
    BEGIN    
    
        IF @ForAmt > 0    
        BEGIN    
            SET @tmpLendAmt = @ForAmt    
            SET @CalcedPayAmt = @ForAmt/CASE WHEN @RepayCnt = '' THEN 1 ELSE ISNULL(@RepayCnt,1) END   --���ݿ����Ѱ�     
        END    
        ELSE    
        BEGIN    
            SET @tmpLendAmt = @Amt    
            SET @CalcedPayAmt = @Amt/CASE WHEN @RepayCnt = '' THEN 1 ELSE ISNULL(@RepayCnt,1) END    
        END    
    
        SET @CalcedPayAmt = ROUND(@CalcedPayAmt, 0)    
        
        -----------------------------------------------------------------------------------    
        --��ȯ�Ⱓ�� ���ݸ� ���    
        -----------------------------------------------------------------------------------    
        SET @index = 0    
        SET @date = @FrDateRepOfRepay    
        WHILE @index < @RepayCnt    --���� ��ȯ�Ⱓ ��ġ�Ⱓ ����    
        BEGIN    
        
            SET @PayCnt = @index + 1    
              
            IF @ForAmt > 0    
            BEGIN    
                SET @PayForAmt = @PayAmt    
                SET @PayAmt = @PayAmt * @ExRate / @BasicAmt  
            END    
            ELSE    
            BEGIN    
                SET @PayForAmt = 0    
            END    
              
            SET @FrDate = @date       
            SET @date = CONVERT(NCHAR(8), DATEADD(m, @RepayTerm, @date), 112)    
            SET @PayDate = @date    
            SET @ToDate = CONVERT(NCHAR(8), DATEADD(d, -1, @date), 112)    
    
    
            INSERT INTO #Temp_LendRepayOpt(PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                              FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime)    
            SELECT    
                   @PayCnt,    
                   @InterestRate,    
                   0,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN ROUND(@CalcedPayAmt * @ExRate / @BasicAmt,0)  
                   ELSE @CalcedPayAmt END,    
                   0,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN 0    
                   ELSE @balanceAmt END,    
                   0,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @CalcedPayAmt    
                   ELSE 0 END,    
                   0,    
                   0,                                                       -- 2013.08.08 shkim1 @BalanceForAmt ��� 0���� �ʱⰪ  
                   @FrDate,    
                   @ToDate,    
                   @PayDate,    
                   CASE    
                        WHEN @PayAmt = 0 AND @PayIntAmt = 0 THEN    0    
                        WHEN @PayAmt <> 0 AND @PayIntAmt = 0 THEN   4025001    
                        WHEN @PayAmt = 0 AND @PayIntAmt <> 0 THEN   4025002    
                        WHEN @PayAmt <> 0 AND @PayIntAmt <> 0 THEN  4025003    
                   END AS SMInterestOrCapital,    
                   CASE WHEN @PayCnt = @OddTime THEN '1' ELSE '0' END    
                        
    
            SET @index = @index + 1    
    
        END -- end while   
          
        -----------------------------------------------------------------------------------    
        --��ȯ�Ⱓ�� ���ݸ� ��� ��         -- end of loop    
        -----------------------------------------------------------------------------------    
          
        -----------------------------------------------------------------------------------    
        --���ڱⰣ�� ���             
        -----------------------------------------------------------------------------------    
          
        SET @index = 0    
        SET @PayCnt2 = 1     
        SET @date = @FrDateRepOfInt    
          
        WHILE @index < @TotalLendMonthInt    
        BEGIN    
            SET @PayCnt = @index + 1    
    
            IF @index = 0    
            BEGIN    
                SET @balance = @tmpLendAmt    
    
            END    
            ELSE    
            BEGIN    
                IF @ForAmt > 0    
                BEGIN    
                    SET @balance = @prevBalanceForAmt    
                END    
                ELSE    
                BEGIN    
                    SET @balance = @prevBalanceAmt    
                END    
              
            END -- end if   
              
            --SET @PayIntAmt = (@balance*@InterestRate/100)/12     
            --SET @PayIntAmt = ROUND(@PayIntAmt, 0)    
    
            --SET @PayForIntAmt = (@balance*@InterestRate/100)/12     
            --SET @PayForIntAmt = ROUND(@PayForIntAmt, 0)    
    
            --SET @TotAmt = @CalcedPayAmt + @PayIntAmt    
            --SET @balanceAmt = @balance - @CalcedPayAmt    
    
            --SET @TotForAmt = @CalcedPayAmt + @PayForIntAmt    
            --SET @BalanceForAmt = @balance - @CalcedPayAmt    
    
            IF @SMInterestpayWay = 4037001 --����    
            BEGIN    
                SET @FrDate = @date    
                SET @PayDate = @FrDate    
                SET @date = CONVERT(NCHAR(8), DATEADD(m, @InterestTerm, @date), 112)    
                SET @ToDate = @date    
            END    
            ELSE    
            BEGIN    
                SET @FrDate = @date    
                SET @date = CONVERT(NCHAR(8), DATEADD(m, @InterestTerm, @date), 112)    
                SET @PayDate = @date    
                SET @ToDate = CONVERT(NCHAR(8), DATEADD(d, -1, @date), 112)    
              
            END -- end if   
              
            -- @CalcedPayAmt �ʱ�ȭ (���ݻ�ȯ ��ȹ�ۼ��Ҷ� ����� ���� �������)  
            SELECT @CalcedPayAmt= 0  
              
            -- 20130808 shkim1 ��� ��  @CalcedPayAmt ���  
            SELECT @CalcedPayAmt = CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN ISNULL(PayForamt, 0) ELSE ISNULL(PayAmt, 0) END    
              FROM #Temp_LendRepayOpt    
             WHERE PayDate = @PayDate    
  
  
            --�Ϻ������� �߰�  
            IF @SMCalcMethod = 4038001      -- �Ϻ����      
            BEGIN   
                  
                --SELECT @DiffDay = DATEDIFF(dd, @FrDate, @ToDate) + 1  
                SELECT @DiffDay = DATEDIFF(dd, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END) -- ������ֱ�   
                  
                SET @PayIntAmt = @balance * @InterestRate / 100 /365 * @DiffDay     
                --SET @PayIntAmt = ROUND(@PayIntAmt, 0)      
          
                SET @PayForIntAmt = @balance * @InterestRate / 100 /365 * @DiffDay       
                SET @PayForIntAmt = @PayForIntAmt  
              
                SET @TotAmt = @CalcedPayAmt + @PayIntAmt      
                SET @balanceAmt = @balance - @CalcedPayAmt      
          
                SET @TotForAmt = @CalcedPayAmt + @PayForIntAmt      
                SET @BalanceForAmt = @balance - @CalcedPayAmt                 
                  
            END  
            ELSE  
            BEGIN  
                SET @PayIntAmt = (@balance*@InterestRate/100)/12       
                SET @PayIntAmt = ROUND(@PayIntAmt, 0)      
          
                SET @PayForIntAmt = (@balance*@InterestRate/100)/12       
                SET @PayForIntAmt = @PayForIntAmt   
          
                SET @TotAmt = @CalcedPayAmt + @PayIntAmt      
                SET @balanceAmt = @balance - @CalcedPayAmt      
          
                SET @TotForAmt = @CalcedPayAmt + @PayForIntAmt      
                SET @BalanceForAmt = @balance - @CalcedPayAmt              
              
            END -- end if   
              
            --�Ϻ������� �߰� ��  
    
    
            --SELECT @CalcedPayAmt = 0    
            -- 20130808 shkim1 ��� ��  @CalcedPayAmt ���  
            --SELECT @CalcedPayAmt = CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN ISNULL(PayForamt, 0) ELSE ISNULL(PayAmt, 0) END    
              --  FROM #Temp_LendRepayOpt     
            -- WHERE PayDate = @PayDate    
    
    
            IF @ForAmt > 0    
            BEGIN    
                SET @PayIntAmt = ROUND( @PayForIntAmt * @ExRate / @BasicAmt,0)   
                --SET @CalcedPayAmt = 0    
                SET @PayAmt = ROUND( @CalcedPayAmt * @ExRate / @BasicAmt,0)   
                SET @TotAmt = ROUND( @TotForAmt * @ExRate / @BasicAmt,0)   
                SET @balanceAmt = ROUND( @BalanceForAmt * @ExRate / @BasicAmt,0)    
            END    
            ELSE    
            BEGIN    
                SET @PayForIntAmt = 0    
                SET @PayForAmt = 0    
                SET @TotForAmt = 0    
                SET @BalanceForAmt = 0    
              
            END -- end if   
              
            INSERT INTO #tmp (PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                              FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime)    
            SELECT    
                   @PayCnt,    
                   @InterestRate,    
                   @PayIntAmt,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @PayAmt    
                   ELSE @CalcedPayAmt END AS PayAmt,    
  
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @TotAmt    
                   ELSE @CalcedPayAmt + @PayIntAmt END AS TotAmt,    
  
                   @balanceAmt,    
                   @PayForIntAmt,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @CalcedPayAmt    
                   ELSE 0 END,    
                   @TotForAmt,    
                   @BalanceForAmt,    
                   @FrDate,    
                   @ToDate,    
                   @PayDate,    
                   CASE  WHEN @PayAmt = 0 AND @PayIntAmt = 0 THEN    0    
                         WHEN @PayAmt <> 0 AND @PayIntAmt = 0 THEN   4025001    
                         WHEN @PayAmt = 0 AND @PayIntAmt <> 0 THEN   4025002    
                         WHEN @PayAmt <> 0 AND @PayIntAmt <> 0 THEN  4025003 END AS SMInterestOrCapital,    
    
  
                   CASE WHEN @PayCnt2 = @OddTime THEN '1' ELSE '0' END    
                     
              
            SET @prevBalanceForAmt = @BalanceForAmt    
            SET @prevBalanceAmt = @balanceAmt    
            SET @index = @index + 1    
              
            IF @CalcedPayAmt > 0        
            BEGIN      
                SELECT @PayCnt2 = @PayCnt2 + 1      
              
            END -- end if   
    
        END -- end while    
          
        IF @ForAmt > 0    
        BEGIN    
            UPDATE #tmp    
               SET PayForIntAmt = 111    
             WHERE PayForIntAmt = 0    
        END    
        ELSE    
        BEGIN    
            UPDATE #tmp    
               SET PayIntAmt = 111    
             WHERE PayIntAmt = 0    
          
        END -- end if   
          
        -----------------------------------------------------------------------------------    
        --���ڱⰣ�� ���ڸ� ���         -- end of loop    
        -----------------------------------------------------------------------------------    
            
        -----------------------------------------------------------------------------------    
        --���� �ȵ��� �־��ְ� PayCnt �ٽ� ä��    
        -----------------------------------------------------------------------------------    
        INSERT INTO #tmp   
        (  
            PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
            FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime  
        )    
        SELECT A.PayCnt, A.InterestRate, ISNULL(A.PayIntAmt, 0) AS PayIntAmt, A.PayAmt, A.PayAmt + ISNULL(A.PayIntAmt, 0) AS TotAmt,     
               A.balanceAmt, ISNULL(A.PayForIntAmt, 0) AS PayForIntAmt, ISNULL(A.PayForAmt, 0) AS PayForAmt, A.PayForAmt + ISNULL(A.PayForIntAmt, 0) AS TotForAmt, A.BalanceForAmt,    
               A.FrDate, A.ToDate, A.PayDate, 4025001 AS SMInterestOrCapital, --���ݸ�     
               A.IsOddTime                  
         FROM #Temp_LendRepayOpt AS A     
                    LEFT OUTER JOIN #tmp AS B ON A.PayDate = B.PayDate                 
        WHERE B.PayDate IS NULL    
          
        SELECT @Index = 1,    
               @balance = 0    
          
        DECLARE CUR_SlipAmt CURSOR FOR    
        SELECT PayDate, PayAmt, PayForAmt, FrDate, ToDate  
          FROM #tmp     
         WHERE ISNULL(PayDate, '') <> ''    
         ORDER BY PayDate    
          
        OPEN CUR_SlipAmt    
          
        FETCH NEXT FROM CUR_SlipAmt INTO @PayDate, @PayAmt, @PayForAmt, @FrDate, @ToDate  
        WHILE(@@FETCH_status = 0)    
        BEGIN     
              
            IF @SMInterestpayWay = 4037001   --����    
            BEGIN    
                  
                IF @ForAmt > 0    
                BEGIN    
                    SET @balance = @PayForAmt + @balance    
  
                END    
                ELSE    
                BEGIN    
                    SET @balance = @PayAmt + @balance    
  
                END    
          
            END -- end if   
          
            --�Ϻ������� �߰�  
            IF @SMCalcMethod = 4038001      -- �Ϻ����      
            BEGIN   
                      
                --SELECT @DiffDay = DATEDIFF(dd, @FrDate, @ToDate) + 1  
                SELECT @DiffDay = DATEDIFF(dd, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END) -- ������ֱ�   
                  
                SET @PayIntAmt = (@Amt - @balance) * @InterestRate / 100 /365 * @DiffDay     
                SET @PayIntAmt = ROUND(@PayIntAmt, 0)      
                  
                IF @ForAmt > 0    
                BEGIN    
                    SET @PayForIntAmt = (@Amt - @balance) * @InterestRate / 100 /365 * @DiffDay       
                    SET @PayIntAmt = ROUND(@PayForIntAmt * @ExRate / @BasicAmt, 0)      
                END                    
                  
            END  
            ELSE  
            BEGIN  
                  
                SET @PayIntAmt = (((@Amt - @balance)*@InterestRate/100) * @InterestTerm/12)     
                SET @PayIntAmt = ROUND(@PayIntAmt, 0)    
                  
                IF @ForAmt > 0    
                BEGIN    
                    SET @PayForIntAmt = ((@ForAmt - @balance)*@InterestRate/100) * @InterestTerm/12    
                    SET @PayIntAmt = ROUND(@PayForIntAmt * @ExRate / @BasicAmt, 0)      
                END     
                  
            END -- end if   
              
            --�Ϻ������� �߰� ��  
              
            --SET @PayIntAmt = (((@Amt - @balance)*@InterestRate/100) * @InterestTerm/12)     
            --SET @PayIntAmt = ROUND(@PayIntAmt, 0)    
              
            --IF @ForAmt > 0    
            --BEGIN    
            --    SET @PayForIntAmt = ((@ForAmt - @balance)*@InterestRate/100) * @InterestTerm/12    
            --    SET @PayForIntAmt = ROUND(@PayForIntAmt, 0)    
            --END    
              
            UPDATE #tmp    
               SET PayCnt = @Index,    
                   PayIntAmt = CASE WHEN ISNULL(PayIntAmt, 0) > 0 THEN @PayIntAmt    
                               ELSE 0 END,    
                   PayForIntAmt = CASE WHEN ISNULL(PayForIntAmt, 0) > 0 THEN @PayForIntAmt    
                                  ELSE 0 END,    
                   TotAmt = CASE WHEN ISNULL(PayIntAmt, 0) > 0 THEN @PayIntAmt    
                            ELSE 0 END + PayAmt,    
                   TotForAmt = CASE WHEN ISNULL(PayForIntAmt, 0) > 0 THEN @PayForIntAmt    
                               ELSE 0 END + PayForAmt,    
                   SMInterestOrCapital = CASE  WHEN PayAmt = 0 AND PayIntAmt = 0 THEN    0    
                                               WHEN PayAmt <> 0 AND PayIntAmt = 0 THEN   4025001    
                                               WHEN PayAmt = 0 AND PayIntAmt <> 0 THEN   4025002    
                                               WHEN PayAmt <> 0 AND PayIntAmt <> 0 THEN  4025003 END    
               WHERE PayDate = @PayDate    
               AND ISNULL(PayDate, '') <> ''    
              
            IF @SMInterestpayWay = 4037002   --�ĳ�    
            BEGIN    
                IF @ForAmt > 0    
                    BEGIN    
                        SET @balance = @PayForAmt + @balance    
                    END    
                ELSE    
                    BEGIN    
                        SET @balance = @PayAmt + @balance    
                    END    
            END    
              
            SELECT @Index = @Index + 1    
              
            FETCH NEXT FROM CUR_SlipAmt INTO @PayDate, @PayAmt, @PayForAmt, @FrDate, @ToDate    
          
        END -- end fetch   
          
        DEALLOCATE CUR_SlipAmt      
          
        -----------------------------------------------------------------------------------    
        --���� �ȵ��� �־��ְ� PayCnt �ٽ� ä�� -- end of loop    
        -----------------------------------------------------------------------------------    
      
    END -- ���ݱյ��ȯ ��� ��.    
    ELSE IF @SMRepayType = 4079002 -- �����ݱյ��ȯ ��� ����    
    BEGIN    
          
        /*******************************************************************************************    
        -- �����ݱյ��ȯ�� ������    
        ********************************************************************************************    
          
                                                                   (����Ⱓ - ��ġ�Ⱓ)    
            �����*[(����������/100)/12]*[1 + (����������/100)/12]^    
        -----------------------------------------------------------------------------------    
                                      (����Ⱓ - ��ġ�Ⱓ)    
            [1 + (����������/100)/12]^                      - 1    
    
        *******************************************************************************************/    
          
        IF @SMCalcMethod = 4038001      -- �Ϻ����    
        BEGIN    
              
            SET @DayCntOfYear = dbo._FCOMGetDayCount('2008', 'Y')    
            SET @intRate = (@InterestRate/100)/ISNULL(@DayCntOfYear,1)    
    
        END    
        ELSE IF @SMCalcMethod = 4038002 -- �������    
        BEGIN    
    
            SET @intRate = (@InterestRate/100)/12   -- (����������/100)/12    
    
    
        END    
    
    
    
        SET @tmpNum = POWER((1 + @intRate), @duration)  -- [1 + (����������/100)/12]^(����Ⱓ - ��ġ�Ⱓ)    
    
        IF @ForAmt > 0    
        BEGIN    
            SET @tmpLendAmt = @ForAmt    
            SET @a = @ForAmt*@intRate*@tmpNum    
        END    
        ELSE    
        BEGIN    
            SET @tmpLendAmt = @Amt    
            SET @a = @Amt*@intRate*@tmpNum    
        END    
    
        SET @b = @tmpNum - 1    
    
        SET @CalcedPayAmt = ROUND(@a/@b, 0)    
    
        SET @PayCnt = 1    
        SET @PayCnt2 = 1    
        SET @index = 0    
        SET @index2 = 1    
        SET @date = @LendDate    
          
        --select @index, @LendDuration    
        --select @LendDuration = 12   
          
        WHILE @index < @LendDuration    
        BEGIN    
--             SET @PayCnt = @index + 1    
    
            IF @index = 0    
            BEGIN    
                SET @balance = @tmpLendAmt    
            END    
            ELSE    
            BEGIN    
                IF @ForAmt > 0    
                BEGIN    
                    SET @balance = @prevBalanceForAmt    
                END    
                ELSE    
                BEGIN    
                    SET @balance = @prevBalanceAmt    
                END    
            END    
    
    
            SET @PayIntAmt = (@balance*@InterestRate/100) /12  -- ����    
            SET @PayIntAmt = ROUND(@PayIntAmt, 0)    
    
            IF @ForAmt > 0    
            BEGIN     
                SET @PayForIntAmt = (@balance*@InterestRate/100) /12  -- ����    
                SET @PayIntAmt = ROUND(@PayForIntAmt * @ExRate / @BasicAmt, 0)  
            END    
    
            IF @DeferDuration > @index    
            BEGIN    
                SET @TotAmt = @PayIntAmt    
                  SET @TotForAmt = @PayForIntAmt    
            END    
            ELSE    
            BEGIN    
                SET @TotAmt = @CalcedPayAmt    
                SET @TotForAmt = @CalcedPayAmt    
            END    
    
            SET @PayAmt = @TotAmt - @PayIntAmt    
            SET @balanceAmt = @balance - @PayAmt    
    
            SET @PayForAmt = @TotForAmt - @PayForIntAmt    
            SET @balanceForAmt = @balance - @PayForAmt    
    
            IF @ForAmt > 0    
            BEGIN    
--                SET @PayForIntAmt = @PayIntAmt    
--                SET @PayForAmt = @PayAmt    
--                SET @TotForAmt = @TotAmt    
--                SET @BalanceForAmt = @balanceForAmt    
    
                SET @PayIntAmt = ROUND(@PayForIntAmt * @ExRate / @BasicAmt, 0)  
                SET @PayAmt = ROUND(@PayForAmt * @ExRate / @BasicAmt, 0)  
                SET @TotAmt = ROUND(@TotForAmt * @ExRate / @BasicAmt, 0)  
                SET @balanceAmt = ROUND(@BalanceForAmt * @ExRate / @BasicAmt, 0)  
            END    
            ELSE    
            BEGIN    
                SET @PayForIntAmt = 0    
                SET @PayForAmt = 0    
                SET @TotForAmt = 0    
                SET @BalanceForAmt = 0    
            END    
    
            SELECT @PayIntAmt2 = @PayIntAmt2 + @PayIntAmt    
            SELECT @PayAmt2    = @PayAmt2    + @PayAmt    
            SELECT @TotAmt2    = @TotAmt2    + @TotAmt    
            SELECT @PayForIntAmt2 = @PayForIntAmt2 + @PayForIntAmt    
            SELECT @PayForAmt2    = @PayForAmt2    + @PayForAmt    
            SELECT @TotForAmt2    = @TotForAmt2    + @TotForAmt    
              
            SET @FrDate = @date    
            SET @date = CONVERT(NCHAR(8), DATEADD(m, 1, @date), 112)    
            SET @PayDate = @date    
            SET @ToDate = CONVERT(NCHAR(8), DATEADD(d, -1, @date), 112)    
    
            IF (ISNULL(@PayAmt, 0) = 0 AND ISNULL(@PayForAmt, 0) = 0) AND (@index+1) % @InterestTerm = '0'  --���� �־��ֱ�    
            BEGIN    
                INSERT INTO #tmp (PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                                  FrDate, ToDate, PayDate, SMInterestOrCapital)    
                SELECT    
                       @PayCnt,    
                       @InterestRate,    
                       @PayIntAmt2,    
                       @PayAmt2,    
                       @TotAmt2,    
                       @balanceAmt,        
                       @PayForIntAmt2,    
                       @PayForAmt2,    
                       @TotForAmt2,    
                       @BalanceForAmt,    
                       CONVERT(NCHAR(8), DATEADD(m, -@InterestTerm, DATEADD(d, 1, @ToDate)), 112),    
                       @ToDate,    
                       @PayDate,    
                       CASE    
                            WHEN @PayAmt = 0 AND @PayIntAmt = 0 THEN    0    
                            WHEN @PayAmt <> 0 AND @PayIntAmt = 0 THEN   4025001    
                            WHEN @PayAmt = 0 AND @PayIntAmt <> 0 THEN   4025002    
                            WHEN @PayAmt <> 0 AND @PayIntAmt <> 0 THEN  4025003    
                       END AS SMInterestOrCapital    
    
                SELECT @PayIntAmt2 = 0    
                SELECT @PayAmt2    = 0    
                SELECT @TotAmt2    = 0    
                SELECT @PayForIntAmt2 = 0    
                SELECT @PayForAmt2    = 0    
                SELECT @TotForAmt2    = 0    
    
                SELECT @PayCnt = @PayCnt + 1    
                  
            END   
              
            IF (ISNULL(@PayAmt, 0) > 0 OR ISNULL(@PayForAmt, 0) > 0) AND (@index+1)%@RepayTerm = '0'    --���ݳ־��ֱ�    
            BEGIN    
                INSERT INTO #tmp (PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                                  FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime)    
                SELECT    
               @PayCnt,    
                       @InterestRate,    
                       @PayIntAmt2,    
                       @PayAmt2,    
                       @TotAmt2,    
                       @balanceAmt,        
                       @PayForIntAmt2,    
                       @PayForAmt2,    
                       @TotForAmt2,    
                       @BalanceForAmt,    
                       CONVERT(NCHAR(8), DATEADD(m, -@RepayTerm, DATEADD(d, 1, @ToDate)), 112),    
                       @ToDate,    
                       @PayDate,    
                       CASE    
                            WHEN @PayAmt = 0 AND @PayIntAmt = 0 THEN    0    
                            WHEN @PayAmt <> 0 AND @PayIntAmt = 0 THEN   4025001    
                            WHEN @PayAmt = 0 AND @PayIntAmt <> 0 THEN   4025002    
                            WHEN @PayAmt <> 0 AND @PayIntAmt <> 0 THEN  4025003    
                       END AS SMInterestOrCapital,    
                       CASE WHEN @PayCnt2 = @OddTime THEN '1' ELSE '0' END    
    
                SELECT @PayIntAmt2 = 0    
                SELECT @PayAmt2    = 0    
                SELECT @TotAmt2    = 0    
                SELECT @PayForIntAmt2 = 0    
                SELECT @PayForAmt2    = 0    
                SELECT @TotForAmt2    = 0    
    
                SELECT @PayCnt = @PayCnt + 1    
                SELECT @PayCnt2 = @PayCnt2 + 1 --    
    
    
            END                   
        
    
                SET @prevBalanceForAmt = @BalanceForAmt    
                SET @prevBalanceAmt = @balanceAmt    
    
    
            SET @index = @index + 1    
        END    
        -- end of loop    
          
    END -- �����ݱյ��ȯ ��� ��.    
    ELSE IF @SMRepayType = 4079003 -- �����Ͻû�ȯ ��� ����    
    BEGIN    
            
        --@TotalLendMonthInt  
        IF @SMCalcMethod = 4038001      -- �Ϻ����    
        BEGIN    
            SET @DayCntOfYear = dbo._FCOMGetDayCount('2011', 'Y')    
            SET @intRate = ROUND(@InterestRate/100./@DayCntOfYear,10,1)  
            SELECT @InterestRateCalc = (@InterestRate * DATEDIFF(D, @FrDateRepOfInt, @ToDateRepOfInt)) / @DayCntOfYear --�Ϻ�����϶� ������  
            SET @DayCntOfYearCalc = DATEDIFF(D, @FrDateRepOfInt, @ToDateRepOfInt)   
             
           
        END    
        ELSE IF @SMCalcMethod = 4038002 -- �������    
        BEGIN    
            SET @intRate = ROUND(@InterestRate/100./12,10,1)   -- (����������/100)/12    
            SELECT @InterestRateCalc = (@InterestRate * DATEDIFF(M, @FrDateRepOfInt, @ToDateRepOfInt) + 1)/ 12 --�Ϻ�����϶� ������  
              
        END    
  
        IF @ForAmt > 0    
        BEGIN    
            SET @tmpLendForAmt = @ForAmt    
            SET @PayForIntAmt = @ForAmt*@intRate    
            SET @tmpLendAmt = @Amt    
            SET @PayIntAmt = @Amt*@intRate    
        END    
        ELSE    
        BEGIN    
            SET @tmpLendAmt = @Amt    
            SET @PayIntAmt = @Amt*@intRate    
        END    
  
        SET @PayIntAmt2 = @PayIntAmt  
        SET @PayForIntAmt = @PayForIntAmt  
        SET @PayForIntAmt2 = @PayForIntAmt    
  
   ------------------------------------------------  
   --���ڳ־��ֱ�  
   ------------------------------------------------  
        SET @index = 0    
        SET @PayCnt2 = 1     
        SET @date = @FrDateRepOfInt    
        SET @PayIntSUMAmt = 0  
        SET @PayForIntSUMAmt = 0  
      
        -- @CalcedPayAmt �ʱ�ȭ (���ݻ�ȯ ��ȹ�ۼ��Ҷ� ����� ���� �������)  
        SELECT @CalcedPayAmt= 0  
  
        WHILE @index < @TotalLendMonthInt    
        BEGIN    
  
            SET @PayCnt = @index + 1    
    
            IF @index = 0    
            BEGIN    
                SET @balance = @tmpLendAmt    
    
            END    
            ELSE    
            BEGIN    
                IF @ForAmt > 0    
                BEGIN    
                    SET @balance = @prevBalanceForAmt    
                END    
                ELSE    
                BEGIN    
                    SET @balance = @prevBalanceAmt    
                END    
         END    
               
            IF @SMInterestpayWay = 4037001 --����    
            BEGIN    
                SET @FrDate = @date    
                SET @PayDate = @FrDate    
                SET @date = CONVERT(NCHAR(8), DATEADD(m, @InterestTerm, @date), 112)    
                SET @ToDate = @date    
            END    
            ELSE    
            BEGIN    
                SET @FrDate = @date    
                SET @date = CONVERT(NCHAR(8), DATEADD(m, @InterestTerm, @date), 112)    
                SET @PayDate = @date    
                SET @ToDate = CONVERT(NCHAR(8), DATEADD(d, -1, @date), 112)    
            END   
  
            SELECT @CalcedPayAmt = 0    
    
            SELECT @CalcedPayAmt = CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN ISNULL(PayForamt, 0) ELSE ISNULL(PayAmt, 0) END    
              FROM #Temp_LendRepayOpt    
             WHERE PayDate = @PayDate    
       
            IF @index = 0  
            BEGIN  
                IF @SMCalcMethod = 4038001      -- �Ϻ����    
                BEGIN  
                    SET @PayIntAmt = ROUND(((@Amt * @InterestRateCalc / 100) / @DayCntOfYearCalc) * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)),0,1)  
  
                     
                    --SET @PayIntAmt = @PayIntAmt2 * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)) -- ������ֱ�  
                    --SET @PayForIntAmt = @PayForIntAmt2 * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)) -- ������ֱ�  
                    SET @PayForIntAmt = ROUND(((@ForAmt * @InterestRateCalc / 100) / @DayCntOfYearCalc) * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)),0,1)  
                  
                END  
                
                SET @TotAmt = @CalcedPayAmt + @PayIntAmt    
                SET @balanceAmt = @balance - @CalcedPayAmt    
        
                SET @TotForAmt = @CalcedPayAmt + @PayForIntAmt    
                SET @BalanceForAmt = @balance - @CalcedPayAmt   
            END   
     
  
            IF @ForAmt > 0    
            BEGIN    
                SET @PayIntAmt = @PayForIntAmt * @ExRate / @BasicAmt  
                SET @PayAmt = @CalcedPayAmt * @ExRate / @BasicAmt  
                SET @CalcedPayAmt = 0    
                SET @TotAmt = @TotForAmt * @ExRate / @BasicAmt  
                SET @balanceAmt = @BalanceForAmt * @ExRate / @BasicAmt  
                 
            END    
            ELSE    
            BEGIN    
                SET @PayForIntAmt = 0    
                SET @PayForAmt = 0    
                SET @TotForAmt = 0    
                SET @BalanceForAmt = 0    
            END    
  
            IF @SMCalcMethod = 4038001      -- �Ϻ����    
            BEGIN  
                SET @PayIntAmt = ROUND(((@Amt * @InterestRateCalc / 100) / @DayCntOfYearCalc) * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)),0,1)  
                --SET @PayIntAmt = @PayIntAmt2 * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)) -- ������ֱ�   
                --SET @PayForIntAmt = @PayForIntAmt2 * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)) -- ������ֱ�   
                SET @PayForIntAmt = ROUND(((@ForAmt * @InterestRateCalc / 100) / @DayCntOfYearCalc) * (DATEDIFF(DAY, @FrDate, @ToDate) + (CASE WHEN @IntDayCountType = 4554001 THEN 1 ELSE 0 END)),0,1)  
              
            END  
  
            IF @PayCnt < @TotalLendMonthInt  
            BEGIN  
                SELECT @PayIntSUMAmt = @PayIntSUMAmt + @PayIntAmt  
                SELECT @PayForIntSUMAmt = @PayForIntSUMAmt + @PayForIntAmt  
            END  
  
            IF @PayCnt = @TotalLendMonthInt  
            BEGIN  
              
                SET @PayIntAmt = ROUND((@Amt * @InterestRateCalc / 100), 0) - @PayIntSUMAmt  
                 
                  SET @PayForIntAmt = (@ForAmt * @InterestRateCalc / 100) - @PayForIntSUMAmt                                   
                          
            END  
              
              
  
            INSERT INTO #tmp (PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                              FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime)    
            SELECT    
                   @PayCnt,    
                   @InterestRate,    
                   @PayIntAmt,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @PayAmt    
                   ELSE @CalcedPayAmt END AS PayAmt,  
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @TotAmt    
                   ELSE @CalcedPayAmt + @PayIntAmt END AS TotAmt,  
                   @balanceAmt,  
                   @PayForIntAmt,    
                   CASE WHEN ISNULL(@ForAmt, 0) > 0 THEN @CalcedPayAmt    
                   ELSE 0 END AS PayForAmt,    
                   @TotForAmt,    
                   @BalanceForAmt,    
                   @FrDate,    
                   @ToDate,    
                   @PayDate,    
                   4025002   AS SMInterestOrCapital,  --����  
                   CASE WHEN @PayCnt2 = @OddTime THEN '1' ELSE '0' END    
                     
                     
            SET @prevBalanceForAmt = @BalanceForAmt    
            SET @prevBalanceAmt = @balanceAmt    
            SET @index = @index + 1    
            IF @CalcedPayAmt > 0        
            BEGIN      
                SELECT @PayCnt2 = @PayCnt2 + 1      
            END     
              
        END -- end while   
         
---------------------------------------------------------               
--���ڳ־��ֱ� ��  
---------------------------------------------------------   
  
        SET @PayCnt = 1    
        SET @PayCnt2 = 1    
        SET @index = 0    
        SET @date = @LendDate  
          
        WHILE @index < @LendDuration    
        BEGIN    
    
--             SET @PayCnt = @index + 1    
            SET @FrDate = @date    
            SET @date = CONVERT(NCHAR(8), DATEADD(m, 1, @date), 112)    
            SET @PayDate = @date    
            SET @ToDate = CONVERT(NCHAR(8), DATEADD(d, -1, @date), 112)    
              
            IF @SMCalcMethod = 4038001      -- �Ϻ����    
            BEGIN    
                SET @DayCntOfYear = dbo._FCOMGetDayCount(SUBSTRING(@FrDate, 1, 4), 'Y')    
                SET @intRate = (DATEDIFF(D, CONVERT(NCHAR(8), DATEADD(m, -@InterestTerm, DATEADD(d, 1, @ToDate)), 112), @ToDate)) * ((@InterestRate/100.)/@DayCntOfYear)      
    
                IF @ForAmt > 0    
                BEGIN    
                    SET @tmpLendForAmt = @ForAmt    
                    SET @PayForIntAmt = @ForAmt*@intRate    
                END    
                ELSE    
                BEGIN    
                    SET @tmpLendAmt = @Amt    
                    SET @PayIntAmt = @Amt*@intRate    
                END    
  
                SET @PayForIntAmt = @PayForIntAmt   
            END    
    
    
    
            IF @index = @LendDuration - 1    
            BEGIN    
                SET @PayAmt = @tmpLendAmt    
                SET @PayForAmt = @tmpLendForAmt    
                SET @balanceAmt = 0    
                SET @balanceForAmt = 0    
    
            END    
            ELSE    
            BEGIN    
                SET @PayAmt = 0    
                SET @PayForAmt = 0    
                SET @balanceAmt = @tmpLendAmt    
                SET @balanceForAmt = @tmpLendForAmt    
    
            END    
            SET @TotAmt = @PayAmt + @PayIntAmt    
            SET @TotForAmt = @PayForAmt + @PayForIntAmt    
    
            IF ISNULL(@ForAmt, 0) = 0    
            BEGIN    
                SET @PayForIntAmt = 0    
                SET @PayForAmt = 0    
                SET @TotForAmt = 0    
                SET @BalanceForAmt = 0    
            END    
    
            SELECT @PayIntAmt2 = @PayIntAmt2 + @PayIntAmt    
              SELECT @PayAmt2    = @PayAmt2     + @PayAmt    
            SELECT @TotAmt2    = @TotAmt2    + @TotAmt    
            SELECT @PayForIntAmt2 = @PayForIntAmt2 + @PayForIntAmt    
            SELECT @PayForAmt2    = @PayForAmt2    + @PayForAmt    
            SELECT @TotForAmt2    = @TotForAmt2    + @TotForAmt    
                
            IF (ISNULL(@PayAmt, 0) > 0 OR ISNULL(@PayForAmt, 0) > 0) AND (@index+1)%@RepayTerm = '0'    --���ݳ־��ֱ�    
            BEGIN    
    
                SELECT @FrDate = CONVERT(NCHAR(8), DATEADD(m, -@InterestTerm, DATEADD(d, 1, @ToDate)), 112)    
                SELECT @PayIntAmt2 = @PayIntAmt * DATEDIFF(M, @FrDate, @ToDate)   
  
                SELECT @PayCnt = MAX(PayCnt) + 1 FROM  #tmp  
  
                INSERT INTO #tmp (PayCnt, InterestRate, PayIntAmt, PayAmt, TotAmt, balanceAmt, PayForIntAmt, PayForAmt, TotForAmt, BalanceForAmt,    
                                  FrDate, ToDate, PayDate, SMInterestOrCapital, IsOddTime, ExRate)  
                SELECT    
                       @PayCnt,    
                       @InterestRate,    
                       0,--@PayIntAmt2,    
                       @PayAmt,    
                       @PayAmt ,--+ @PayIntAmt2,    
                       @balanceAmt,    
                       0,    
                       @PayForAmt,    
                       @PayForAmt,    
                       @BalanceForAmt,    
                       CONVERT(NCHAR(8), DATEADD(dd, 1, @ToDateRepOfRepay), 112),--@FrDate,    
                       CONVERT(NCHAR(8), DATEADD(dd, 1, @ToDateRepOfRepay), 112),--@ToDate,    
                       CONVERT(NCHAR(8), DATEADD(dd, 1, @ToDateRepOfRepay), 112),--@PayDate,    
                       4025001 AS SMInterestOrCapital,    
                       CASE WHEN @PayCnt2 = @OddTime THEN '1' ELSE '0' END,    
                       @ExRate    
    
                    SELECT @PayCnt = @PayCnt + 1    
                    SELECT @PayCnt2 = @PayCnt2 + 1    
    
            END    
    
    
            SET @prevBalanceForAmt = @BalanceForAmt    
            SET @prevBalanceAmt = @balanceAmt    
    
            SET @index = @index + 1    
        END    
        -- end of loop    
          
  
             
    END    
    -- �����Ͻû�ȯ ��� ��.    
    UPDATE #tmp    
       SET ExRate = @ExRate,  
           CurrSeq = @CurrSeq    
    
    UPDATE #tmp    
       SET PayAmt       = PayAmt + @Amt - (SELECT SUM(PayAmt) FROM #tmp),    
           PayForAmt    = PayForAmt + @ForAmt - (SELECT SUM(PayForAmt) FROM #tmp)    
     WHERE IsOddTime   = '1'    
    
    UPDATE #tmp    
       SET TotAmt       = PayAmt + PayIntAmt,    
           TotForAmt    = PayForAmt + PayForIntAmt,    
           IsOddTime    = '1'    
     WHERE IsOddTime   = '1'    
    
    UPDATE #tmp    
       SET balanceAmt       = @Amt - (SELECT SUM(PayAmt) FROM #tmp WHERE PayCnt <= A.PayCnt),    
           BalanceForAmt    = @ForAmt - (SELECT SUM(PayForAmt) FROM #tmp WHERE PayCnt <= A.PayCnt)    
      FROM #tmp AS A    
    
    UPDATE #tmp    
       SET LendSeq = (SELECT TOP 1 LendSeq FROM #tmp WHERE LendSeq IS NOT NULL)    
     WHERE LendSeq IS NULL    
    
    UPDATE #tmp    
       SET IsOddTime = ''    
     WHERE IsOddTime IS NULL    
    
    --��ȯ�����Ϻ��� ū ���� ��ȯ ��ȹ�� ���������Ϻ��� ū ���ڻ�ȯ��ȹ�� �������ڷ� �����Ų��.  
    UPDATE #tmp  
       SET PayDate = @ToDateRepOfInt  
     WHERE SMInterestOrCapital = 4025002   --����  
       AND PayDate > @ToDateRepOfInt  
  
    UPDATE #tmp  
       SET FrDate = @ToDateRepOfInt  
     WHERE SMInterestOrCapital = 4025002   --����  
       AND FrDate > @ToDateRepOfInt  
  
    UPDATE #tmp  
       SET ToDate = @ToDateRepOfInt  
     WHERE SMInterestOrCapital = 4025002   --����  
       AND ToDate > @ToDateRepOfInt         
         
    UPDATE #tmp  
       SET PayDate = @ToDateRepOfRepay  
     WHERE SMInterestOrCapital = 4025001   --����  
       AND PayDate > @ToDateRepOfRepay  
  
    UPDATE #tmp  
       SET FrDate = @ToDateRepOfRepay  
     WHERE SMInterestOrCapital = 4025001   --����  
       AND FrDate > @ToDateRepOfRepay  
  
    UPDATE #tmp  
         SET ToDate = @ToDateRepOfRepay  
     WHERE SMInterestOrCapital = 4025001   --����  
       AND ToDate > @ToDateRepOfRepay                
  
  
    RETURN   