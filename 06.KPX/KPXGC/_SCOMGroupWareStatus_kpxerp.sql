
IF OBJECT_ID('_SCOMGroupWareStatus_kpxerp') IS NOT NULL 
    DROP PROC _SCOMGroupWareStatus_kpxerp
GO 

-- v2014.11.27 

-- 휴가신청(경조사내역데이터생성) by이재천 
CREATE PROC _SCOMGroupWareStatus_kpxerp
    @pWorkingTag      NCHAR(1),  
    @CompanySeq       INT = 1,      
    @LanguageSeq      INT = 1,      
    @UserSeq          INT = 0,      
    @WorkKind         NVARCHAR(40) = '',   
    @TblKey           NVARCHAR(40) = '', -- 넘겨준 키를 그대로 보낸다.  
    @TopUserName      NVARCHAR(50) = '',  
    @TopUserPosition  NVARCHAR(50) = '',  
    @RevUserName      NVARCHAR(50) = '',  
    @RevUserPosition  NVARCHAR(50) = '',  
    @DocID            NVARCHAR(MAX) = '',    
    @MessageType      INT  OUTPUT,    
    @Status           INT  OUTPUT,    
    @Results          NVARCHAR(250) OUTPUT   
AS   
    
    IF @pWorkingTag = 'E' AND @WorkKind = 'EmpVac'
    BEGIN 
        DECLARE @EmpSeq     INT, 
                @VacSeq     INT, 
                @Seq        INT
        
        SELECT @EmpSeq = (SELECT CONVERT(INT,LEFT(@TblKey,CHARINDEX(',',@TblKey) - 1)))
        SELECT @VacSeq = (SELECT CONVERT(INT,REPLACE(REPLACE(@TblKey,LEFT(@TblKey,CHARINDEX(',',@TblKey)),''),',','')))
        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_THRWelConEmp', 'Seq', 1 
        
        INSERT INTO _THRWelConEmp 
        (
            CompanySeq, EmpSeq, Seq, ConDate, ConSeq, 
            FamilyName, FamilyResidID, UMRelSeq, IsConAmt, IsMutualAmt, 
            ConAmt, LastUserSeq, LastDateTime 
            
        ) 
        SELECT @CompanySeq, A.EmpSeq, @Seq + 1, A.WkFrDate, A.CCSeq,
               B.EmpName, '', C.UMConClass, C.IsConAmt, C.IsMutualAmt, 
               0, @UserSeq, GETDATE()
          FROM _TPRWkEmpVacApp          AS A 
          LEFT OUTER JOIN _TDAEmp       AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _THRWelCon    AS C ON ( C.CompanySeq = @CompanySeq AND C.ConSeq = A.CCSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.EmpSeq = @EmpSeq 
           AND A.VacSeq = @VacSeq 
        
        INSERT INTO KPX_TPRWkEmpVacAppConEmpRelation 
        (
            CompanySeq,VacEmpSeq,VacSeq,ConEmpSeq,ConSeq, 
            LastUserSeq, LastDateTime
        )
        SELECT @CompanySeq, @EmpSeq, @VacSeq, @EmpSeq, @Seq + 1, 
               @UserSeq, GETDATE()
        
        SELECT @Results = '', @Status = 0, @MessageType = 0   
    END 
    
    
    ELSE IF @pWorkingTag = 'E' AND @WorkKind = 'CustPrice' -- 거래처별 납품처별 단가 SP 처리   
    BEGIN  
          
        --DECLARE @key INT   
          
        --SELECT @Key = ( SELECT TblKey FROM _TCOMGroupWare WHERE CompanySeq = @CompanySeq AND WorkKind = 'CustPrice' AND GroupKey = @TblKey )   
          
        CREATE TABLE #TEMP   
        (  
            IDX_NO          INT IDENTITY,   
            DVItemPriceSeq  INT,   
            SDate           NCHAR(8),   
            EDate           NCHAR(8),   
            StdDate         NCHAR(8)   
        )  
        INSERT INTO #TEMP(DVItemPriceSeq, SDate, EDate, StdDate)  
        SELECT A.DVItemPriceSeq, A.SDate, A.EDate, A.StdDate   
          FROM KPX_TSLDelvItemPrice AS A   
         WHERE EXISTS (SELECT 1   
                         FROM KPX_TSLDelvItemPrice AS Z   
                        WHERE Z.CompanySeq = @CompanySeq   
                          AND Z.DVItemPriceSeq = @TblKey  
                          AND Z.CustSeq = A.CustSeq   
                          AND Z.DVPlaceSeq = A.DVPlaceSeq  
                          AND Z.ItemSeq = A.ItemSeq   
                          AND Z.UnitSeq = A.UnitSeq   
                          AND Z.CurrSeq = A.CurrSeq   
                      )   
         ORDER BY StdDate   
          
        UPDATE A   
           SET SDate = StdDate   
          FROM #TEMP AS A   
           
        DECLARE @Cnt INT   
          
        SELECT @Cnt = 1   
          
        WHILE ( 1 = 1 )   
        BEGIN  
              
            UPDATE A   
                 SET A.EDate = ISNULL(B.EDate, '99991231')  
              FROM #TEMP AS A   
              OUTER APPLY (SELECT CONVERT(NCHAR(8),DATEADD(Day, -1, Z.StdDate),112) AS EDate   
                             FROM #TEMP AS Z  
                            WHERE Z.IDX_NO = @Cnt + 1   
                          ) AS B   
             WHERE IDX_NO = @Cnt   
              
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #TEMP)  
            BEGIN  
                BREAK   
            END  
            ELSE   
            BEGIN  
                SELECT @Cnt = @Cnt + 1   
            END    
              
        END   
          
        UPDATE B   
           SET B.SDate = A.SDate,   
               B.EDate = A.EDate   
          FROM #TEMP AS A   
           JOIN KPX_TSLDelvItemPrice AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DVItemPriceSeq = A.DVItemPriceSeq )   
          
        SELECT @Results = '', @Status = 0, @MessageType = 0     
          
    END   
    ELSE  
    BEGIN 
     
        SELECT @Results = '', @Status = 0, @MessageType = 0     
    END   
    
    RETURN
GO 
--begin tran 
--exec _SCOMGroupWareStatus_kpxerp @pWorkingTag=N'E',@CompanySeq=N'1',@LanguageSeq=N'1',@WorkKind=N'CustPrice',@TblKey=N'GROUP000000000000005'
--rollback 