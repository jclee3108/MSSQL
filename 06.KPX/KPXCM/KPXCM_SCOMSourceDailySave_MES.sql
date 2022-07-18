IF OBJECT_ID('KPXCM_SCOMSourceDailySave_MES') IS NOT NULL    
    DROP PROC KPXCM_SCOMSourceDailySave_MES
GO 

-- v2015.09.23 KPXCM MES 용

/************************************************************          
 설  명 - 연결키 저장          
 작성일 - 2005년 6월 29일           
 작성자 - 정수환          
 ************************************************************/          
 CREATE PROC dbo.KPXCM_SCOMSourceDailySave_MES 
     @xmlDocument    NVARCHAR(MAX),            
     @xmlFlags       INT = 0,            
     @ServiceSeq     INT = 0,            
     @WorkingTag     NVARCHAR(10)= '',            
     @CompanySeq     INT = 1,            
     @LanguageSeq    INT = 1,            
     @UserSeq        INT = 0,            
     @PgmSeq         INT = 0            
           
 AS        
       
     DECLARE @FromTableSeq INT,  
             @ToTableSeq   INT, @MinusDisplay INT,
             @TableName  NVARCHAR(150),
             @ProgTableName  NVARCHAR(150),
             @ProgTableSeqColumn NVARCHAR(150),
             @ProgTableSerlColumn NVARCHAR(150),
             @ProgTableSubSerlColumn NVARCHAR(150),
             @UPTSql       NVARCHAR(MAX),  
             @IsMinusDisplay    NCHAR(1),  
             @SMProgCheckKind   INT,  
             @IsOverFlow        NCHAR(1),  
             @IsSumNextProg     NCHAR(1),  
             @SQL NVARCHAR(MAX),    
             @MessageType     INT,    
             @Status          INT,    
             @Results         NVARCHAR(250),
             @NextTableSeq    INT,
             @NextTableName  NVARCHAR(150)
              
           
     CREATE TABLE #TMP_PROGRESSTABLE    
     (    
         IDOrder INT,    
         TABLENAME   NVARCHAR(100)    
     )    
     CREATE TABLE #TCOMProgressTracking    
     (       IDX_NO      INT,    
             IDOrder     INT,    
             Seq         INT,    
             Serl        INT,    
             SubSerl     INT,    
             Qty         DECIMAL(19, 5),    
             STDQty         DECIMAL(19, 5),    
             Amt         DECIMAL(19, 5)   ,    
             VAT         DECIMAL(19, 5)    
     )   
     
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromTableSeq=""','FromTableSeq="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromSeq=""'     ,'FromSeq="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromSerl=""'    ,'FromSerl="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromSubSerl=""' ,'FromSubSerl="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromQty=""'     ,'FromQty="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromSTDQty=""'  ,'FromSTDQty="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromAmt=""'     ,'FromAmt="0"')        
     SELECT @xmlDocument = REPLACE(@xmlDocument, 'FromVAT=""'     ,'FromVAT="0"')        
           
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromTableSeq />','<FromTableSeq> 0 </FromTableSeq>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromSeq />'     ,'<FromSeq> 0 </FromSeq>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromSerl />'    ,'<FromSerl> 0 </FromSerl>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromSubSerl />' ,'<FromSubSerl> 0 </FromSubSerl>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromQty />'     ,'<FromQty> 0 </FromQty>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromSTDQty />'  ,'<FromSTDQty> 0 </FromSTDQty>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromAmt />'     ,'<FromAmt> 0 </FromAmt>')          
     SELECT @xmlDocument = REPLACE(@xmlDocument, '<FromVAT />'     ,'<FromVAT> 0 </FromVAT>')          
           
     -- 서비스 마스타 등록 생성          
     CREATE TABLE #TCOMSourceDaily  (WorkingTag NCHAR(1) NULL)              
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TCOMSourceDaily'             
           
     IF @@ERROR <> 0 RETURN              
   
 --    IF EXISTS (SELECT 1 FROM #TCOMSourceDaily)
 --    BEGIN
 --        INSERT INTO _TCOMSourceDailyLogTable
 --        (
 --            LogUserSeq, 
 --            LogDateTime, 
 --            LogType, 
 --            CompanySeq, 
 --            ToTableSeq, 
 --            ToSeq, 
 --            ToSerl, 
 --            ToSubSerl, 
 --            FromTableSeq, 
 --            FromSeq, 
 --            FromSerl, 
 --            FromSubSerl, 
 --            ToQty, 
 --            ToSTDQty, 
 --            ToAmt, 
 --            ToVAT, 
 --            FromQty, 
 --            FromSTDQty, 
 --            FromAmt, 
 --            FromVAT, 
 --            PrevFromTableSeq, 
 --            PServiceSeq,
 --            PWorkingTag,
 --            PCompanySeq,
 --            PLanguageSeq,
 --            PUserSeq,
 --            PPgmSeq
 --        )
 --        SELECT @UserSeq, 
 --               GETDATE(), 
 --               WorkingTag, 
 --               @CompanySeq, 
 --               ToTableSeq, 
 --               ToSeq, 
 --               ToSerl, 
 --               ToSubSerl, 
 --               FromTableSeq, 
 --               FromSeq, 
 --               FromSerl, 
 --               FromSubSerl, 
 --               ToQty, 
 --               ToSTDQty, 
 --               ToAmt, 
 --               ToVAT, 
 --               FromQty, 
 --               FromSTDQty, 
 --               FromAmt, 
 --               FromVAT, 
 --               PrevFromTableSeq, 
 --               @ServiceSeq,
 --               @WorkingTag,
 --               @CompanySeq,
 --               @LanguageSeq,
 --               @UserSeq,
 --               @PgmSeq
 --          FROM #TCOMSourceDaily
 --          
 --        IF @@ERROR <> 0 RETURN    
 --    END
  --    IF NOT EXISTS (SELECT 1 FROM #TCOMSourceDaily) OR (ISNULL(@ToTableSeq,0) = 0 OR ISNULL(@FromTableSeq,0) = 0)  
 --    BEGIN  
 --        INSERT INTO _TCOMSourceDailyLogParam
 --        (
 --            xmlDocument,
 --            xmlFlags,
 --            ServiceSeq,
 --            WorkingTag,
 --            CompanySeq,
 --            LanguageSeq,
 --            UserSeq,
 --            PgmSeq,
 --            LogUserSeq, 
 --            LogDateTime
 --        )
 --        SELECT @xmlDocument,            
 --               @xmlFlags,            
 --               @ServiceSeq,            
 --               @WorkingTag,            
 --               @CompanySeq,            
 --               @LanguageSeq,            
 --               @UserSeq,            
 --               @PgmSeq,
 --               @UserSeq, 
 --               GETDATE()
 --               
 --        IF @@ERROR <> 0 RETURN    
 --    END
   
     
     -- 에러 진행키 삭제(불안정한 진행으로 임시로 작업) JMKIM. 2010-02-01  
     -- Log작업 JMKIM 2011-05-18
 --    INSERT INTO _TCOMSourceDailyLogTable
 --    (
 --        LogUserSeq, 
 --        LogDateTime, 
 --        LogType, 
 --        CompanySeq, 
 --        ToTableSeq, 
 --        ToSeq, 
 --        ToSerl, 
 --        ToSubSerl, 
 --        FromTableSeq, 
 --        FromSeq, 
 --        FromSerl, 
 --        FromSubSerl, 
 --        ToQty, 
 --        ToSTDQty, 
 --        ToAmt, 
 --        ToVAT, 
 --        FromQty, 
 --        FromSTDQty, 
 --        FromAmt, 
 --        FromVAT, 
 --        PrevFromTableSeq, 
 --        PServiceSeq,
 --        PWorkingTag,
 --        PCompanySeq,
 --        PLanguageSeq,
 --        PUserSeq,
 --        PPgmSeq
 --    )
 --    SELECT LastUserSeq, 
 --           LastDateTime, 
 --           'O', 
 --           CompanySeq, 
 --           ToTableSeq, 
 --           ToSeq, 
 --           ToSerl, 
 --           ToSubSerl, 
 --           FromTableSeq, 
 --           FromSeq, 
 --           FromSerl, 
 --           FromSubSerl, 
 --           ToQty, 
 --           ToSTDQty, 
 --           ToAmt, 
 --           ToVAT, 
 --           FromQty, 
 --           FromSTDQty, 
 --           FromAmt, 
 --           FromVAT, 
 --           PrevFromTableSeq, 
 --           @ServiceSeq,
 --           @WorkingTag,
 --           @CompanySeq,
 --           @LanguageSeq,
 --           @UserSeq,
 --           @PgmSeq
 --      FROM _TCOMSourceDaily
 --     WHERE ToSeq = 0 AND ToSerl = 0 AND ToSubSerl = 0   
     -- 진행 관련 해당 데이터가 있을 경우에만 DELETE 하도록 수정 2011. 8. 2 hkim 
 --    IF @@ERROR > 0     
 --    BEGIN         
 --        DELETE FROM _TCOMSourceDaily WHERE CompanySeq = @CompanySeq AND ToSeq = 0 AND ToSerl = 0 AND ToSubSerl = 0   
 --    END        
           
      IF EXISTS (SELECT TOP 1 1 FROM _TCOMSourceDaily WHERE ToSeq = 0 AND ToSerl = 0 AND ToSubSerl = 0)
     BEGIN
         DELETE FROM _TCOMSourceDaily WHERE CompanySeq = @CompanySeq AND ToSeq = 0 AND ToSerl = 0 AND ToSubSerl = 0   
     END
            
 ---- 임시 테이블에 값 넣기          
 /*******************************************************************************************************/          
 /*******************************************************************************************************/          
 /*******************************************************************************************************/          
     ----------------------- Column 추가(OldToQty , OldToAmt) Update & Delete 시 사용함          
     Alter Table #TCOMSourceDaily Add OldToQty DECIMAL(19, 5)           
     Alter Table #TCOMSourceDaily Add OldToSTDQty DECIMAL(19, 5)           
     Alter Table #TCOMSourceDaily Add OldToAmt DECIMAL(19, 5)           
     Alter Table #TCOMSourceDaily Add OldToVAT DECIMAL(19, 5)     
   
     SELECT @FromTableSeq = FromTableSeq, @ToTableSeq = ToTableSeq  
       FROM #TCOMSourceDaily   
      WHERE FromTableSeq <> 0  
        AND ToTableSeq <> 0  
   
     IF NOT EXISTS (SELECT 1 FROM #TCOMSourceDaily) OR (ISNULL(@ToTableSeq,0) = 0 OR ISNULL(@FromTableSeq,0) = 0)  
     BEGIN  
         SELECT * FROM #TCOMSourceDaily             
         RETURN  
     END  
   
     SELECT  @IsMinusDisplay  = ISNULL(IsMinusDisplay, '0'),  
             @SMProgCheckKind = ISNULL(SMProgCheckKind, 0),    
             @IsOverFlow      = ISNULL(IsOverFlow, '0'),    
             @IsSumNextProg   = ISNULL(IsSumNextProg, '0')      
       FROM  _TCOMProgRelativeTables WITH (NOLOCK)          
      WHERE  CompanySeq   = @CompanySeq          
        AND  FromTableSeq = @FromTableSeq          
        AND  ToTableSeq   = @ToTableSeq         
   
     SELECT  @ProgTableName = ProgTableName,
             @ProgTableSeqColumn = ProgTableSeqColumn,
             @ProgTableSerlColumn = ProgTableSerlColumn,
             @ProgTableSubSerlColumn = ProgTableSubSerlColumn    
       FROM  _TCOMProgTable 
      WHERE  ProgTableSeq = @ToTableSeq
      SELECT  @TableName = ProgTableName, @NextTableSeq = NextTableSeq  
       FROM  _TCOMProgTable 
      WHERE  ProgTableSeq = @FromTableSeq
      
     SELECT  @NextTableName = ProgTableName  
       FROM  _TCOMProgTable  
      WHERE  ProgTableSeq = @NextTableSeq  
           
               
     SELECT  @MinusDisplay = 1  
     IF  @IsMinusDisplay = '1'  
         SELECT  @MinusDisplay = -1  
   
         
     ----------------------- ToTableSeq, FromTableSeq의 테이블 키 찾기          
     UPDATE  #TCOMSourceDaily           
        SET  ToTableSeq      =  IsNull(A.ToTableSeq, 0),                
             FromTableSeq    =  IsNull(A.FromTableSeq, 0),            
             ToSeq           =  ISNULL(A.ToSeq, 0),               
             ToSerl          =  ISNULL(A.ToSerl, 0),               
             ToSubSerl       =  ISNULL(A.ToSubSerl, 0),               
             -- 반품의 경우 앞에서 정상적으로 (-)데이터가 넘어오므로 -를 곱하지 않는다.  
             --ToQty           =  ISNULL(A.ToQty, 0) * @MinusDisplay,                
             --ToSTDQty        =  ISNULL(A.ToSTDQty, 0) * @MinusDisplay,               
             --ToAmt           =  ISNULL(A.ToAmt, 0) * @MinusDisplay,               
             --ToVAT           =  ISNULL(A.ToVAT, 0) * @MinusDisplay,               
             ToQty           =  ISNULL(A.ToQty, 0) ,                 
             ToSTDQty        =  ISNULL(A.ToSTDQty, 0) ,                 
             ToAmt =  ISNULL(A.ToAmt, 0) ,                 
             ToVAT           =  ISNULL(A.ToVAT, 0) ,                          
             FromSeq         =  ISNULL(A.FromSeq, 0),               
             FromSerl        =  ISNULL(A.FromSerl, 0),               
             FromSubSerl     =  ISNULL(A.FromSubSerl, 0),                
             FromQty         =  ISNULL(A.FromQty, 0),               
             FromSTDQty      =  ISNULL(A.FromSTDQty, 0),               
             FromAmt         =  ISNULL(A.FromAmt, 0),               
             FromVAT         =  ISNULL(A.FromVAT, 0),               
             PrevFromTableSeq = ISNULL(A.PrevFromTableSeq, 0),               
             OldToQty        =  0,           
             OldToSTDQty     =  0,               
             OldToAmt        =  0,           
             OldToVAT        =  0               
        FROM #TCOMSourceDaily AS A    
 --                JOIN _TCOMProgRelativeTables AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
 --                                                              AND A.FromTableSeq = B.FromTableSeq  
 --                                                              AND A.ToTableSeq   = B.ToTableSeq     
           
     ----------------------- ADD가 아닌 경우, OldToQty & OldToAmt에 대한 값을 정의한다.          
     ----------- _TCOMSource에서 값을 찾기          
     UPDATE  #TCOMSourceDaily           
        SET  OldToQty    = B.ToQty,           
             OldToSTDQty = B.ToSTDQty,           
             OldToAmt    = B.ToAmt,           
             OldToVAT    = B.ToVAT            
       FROM  #TCOMSourceDaily AS A                
         JOIN _TCOMSource AS B WITH(NOLOCK)  On A.ToTableSeq = B.ToTableSeq           
                                            And A.ToSeq = B.ToSeq            
                                            And A.ToSerl = B.ToSerl            
                                            And A.ToSubSerl = B.ToSubSerl            
                                            And B.CompanySeq = @CompanySeq             
      WHERE  A.WorkingTag IN ('U','D')      
        AND  A.Status = 0           
        
        
     -- 삭제시 ADD_DEL -1 이 2번 처리될 경우를 위해 체크처리 2011-05-18 JMKIM
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1053               , -- @1 처리 작업중 오류가 발생하였습니다...(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and Message like '%오류%')    
                           @LanguageSeq       ,  
                           9110,'', 0, '' --건, 진행정보 //// select * from _TCADictionary where WordSeq = 9110  
                               
     UPDATE #TCOMSourceDaily
        SET Result        = @Results     ,   
            MessageType   = @MessageType ,      
            Status        = @Status      
       FROM #TCOMSourceDaily AS A
            JOIN (SELECT ToTableSeq, ToSeq, ToSerl, ToSubSerl, SUM(ADD_DEL) AS ADD_DEL  
                    FROM _TCOMSourceDaily WITH(NOLOCK)           
                   WHERE CompanySeq = @CompanySeq                       
                   GROUP BY ToTableSeq, ToSeq, ToSerl, ToSubSerl
                   HAVING SUM(ADD_DEL) = 0) AS B  ON A.ToTableSeq = B.ToTableSeq           
                                                 AND A.ToSeq      = B.ToSeq            
                                                 AND A.ToSerl     = B.ToSerl            
                                                 AND A.ToSubSerl  = B.ToSubSerl          
      WHERE A.WorkingTag = 'D'      
        AND A.Status = 0
            
     ---------- _TCOMSourceDaily에서 값을 찾기          
     UPDATE  #TCOMSourceDaily           
        SET  OldToQty    = A.OldToQty + B.ToQty,           
             OldToSTDQty = A.OldToSTDQty + B.ToSTDQty,           
             OldToAmt    = A.OldToAmt + B.ToAmt,           
             OldToVAT    = A.OldToVAT + B.ToVAT    
       FROM  #TCOMSourceDaily AS A                
         JOIN (SELECT ToTableSeq, ToSeq, ToSerl, ToSubSerl,           
                      SUM(ToQty * ADD_DEL) AS ToQty, SUM(ToSTDQty * ADD_DEL) AS ToSTDQty  ,           
                      SUM(ToAmt * ADD_DEL) AS ToAmt, SUM(ToVAT * ADD_DEL) AS ToVAT                        
                 FROM _TCOMSourceDaily WITH(NOLOCK)           
              WHERE CompanySeq = @CompanySeq                       
                GROUP BY ToTableSeq, ToSeq, ToSerl, ToSubSerl) AS B  On A.ToTableSeq = B.ToTableSeq           
                                                                   And A.ToSeq = B.ToSeq            
                                                                   And A.ToSerl = B.ToSerl            
                                                                   And A.ToSubSerl = B.ToSubSerl            
      WHERE  A.WorkingTag IN ('U','D')      
        AND  A.Status = 0           
           
 /*******************************************************************************************************/          
 /*******************************************************************************************************/          
 /*******************************************************************************************************/          
           
     -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT          
           
 -- DELETE & UPDATE          
     IF EXISTS (SELECT 1 FROM #TCOMSourceDaily WHERE WorkingTag IN ('U','D') AND Status = 0 )              
     BEGIN              
         INSERT INTO _TCOMSourceDaily (CompanySeq,           
                                       ToTableSeq, ToSeq, ToSerl, ToSubSerl,           
                                       FromTableSeq, FromSeq, FromSerl, FromSubSerl,          
                                       ToQty, ToSTDQty, ToAmt, ToVAT,          
                                       FromQty, FromSTDQty, FromAmt, FromVAT,          
                                       ADD_DEL, PrevFromTableSeq, LastUserSeq, LastDateTime, PgmSeq)            
         SELECT  @CompanySeq,           
                 A.ToTableSeq,    A.ToSeq,    A.ToSerl,    A.ToSubSerl,           
                 A.FromTableSeq,  A.FromSeq,  A.FromSerl,  A.FromSubSerl,           
                 A.OldToQty, A.OldToSTDQty, A.OldToAmt, A.OldToVAT,          
                 A.FromQty, A.FromSTDQty, A.FromAmt, A.FromVAT,          
                 -1, A.PrevFromTableSeq, @UserSeq,    GETDATE(),     @PgmSeq
           FROM  #TCOMSourceDaily  AS A           
          WHERE  WorkingTag IN ('U','D')     
            AND  Status = 0              
            AND  FromSeq > 0          
           
         IF @@ERROR <> 0      RETURN          
     END               
           
 -- UPDATE & ADD          
     IF EXISTS (SELECT 1 FROM #TCOMSourceDaily WHERE WorkingTag IN ('A','U') AND Status = 0 )              
     BEGIN               
        INSERT INTO _TCOMSourceDaily (CompanySeq,           
                                       ToTableSeq, ToSeq, ToSerl, ToSubSerl,           
                                       FromTableSeq, FromSeq, FromSerl, FromSubSerl,          
                                       ToQty, ToSTDQty, ToAmt, ToVAT,          
                                       FromQty, FromSTDQty, FromAmt, FromVAT,          
                                       ADD_DEL, PrevFromTableSeq, LastUserSeq, LastDateTime, PgmSeq)            
         SELECT  @CompanySeq,           
                 A.ToTableSeq,    A.ToSeq,    A.ToSerl,    A.ToSubSerl,           
                 A.FromTableSeq,  A.FromSeq,  A.FromSerl,  A.FromSubSerl,           
                 A.ToQty, A.ToSTDQty, A.ToAmt, A.ToVAT,          
                 A.FromQty, A.FromSTDQty, A.FromAmt, A.FromVAT,          
                 1, A.PrevFromTableSeq, @UserSeq,    GETDATE(),      @PgmSeq
           FROM  #TCOMSourceDaily  AS A           
          WHERE  WorkingTag IN ('A','U')       
            AND  Status = 0              
            AND  FromSeq > 0          
           
         IF @@ERROR <> 0      RETURN  
         /***************** 추가 부분 ToTable의 ProgFromTableSeq, ProgFromSeq, ProgFromSerl, ProgFromSubSerl에 데이터 업데이트*/
         IF EXISTS(SELECT 1 FROM #TCOMSourceDaily WHERE WorkingTag = 'A' AND Status = 0 AND FromSeq > 0)
         BEGIN
             SELECT  @UPTSql = 'UPDATE A ' + CHAR(13)
SELECT  @UPTSql = @UPTSql + 'SET ProgFromTableSeq = B.FromTableSeq, ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + '    ProgFromSeq = B.FromSeq, ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + '    ProgFromSerl = B.FromSerl, ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + '    ProgFromSubSerl = B.FromSubSerl  ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + 'FROM ' + @ProgTableName + ' A ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + '     JOIN #TCOMSourceDaily B ON A.CompanySeq = @CompanySeq ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + '                            AND A.' + @ProgTableSeqColumn + ' = B.ToSeq ' + CHAR(13)
             IF @ProgTableSerlColumn > ''
             SELECT  @UPTSql = @UPTSql + '                            AND A.' + @ProgTableSerlColumn + ' = B.ToSerl ' + CHAR(13)
             IF @ProgTableSubSerlColumn > ''
             SELECT  @UPTSql = @UPTSql + '                            AND A.' + @ProgTableSubSerlColumn + ' = B.ToSubSerl ' + CHAR(13)
             SELECT  @UPTSql = @UPTSql + 'WHERE WorkingTag = ''A'' AND Status = 0 AND FromSeq > 0 ' + CHAR(13)
             
             EXEC SP_EXECUTESQL @UPTSql, N'@CompanySeq INT', @CompanySeq
         END
         /***************** 추가 부분 ToTable의 ProgFromTableSeq, ProgFromSeq, ProgFromSerl, ProgFromSubSerl에 데이터 업데이트*/
     END             
      
     UPDATE  #TCOMSourceDaily           
        SET  ToQty           =  ISNULL(A.ToQty, 0) * @MinusDisplay,               
             ToSTDQty        =  ISNULL(A.ToSTDQty, 0) * @MinusDisplay,               
             ToAmt           =  ISNULL(A.ToAmt, 0) * @MinusDisplay,               
             ToVAT           =  ISNULL(A.ToVAT, 0) * @MinusDisplay   
        FROM #TCOMSourceDaily AS A     
   
   
     -- 진행체크  
     IF ISNULL(@IsOverFlow,'') <> '1' AND ISNULL(@SMProgCheckKind, 0) <> 0 -- 데이터 없이 들어올 경우 에러날 수 있어서 추가  
     BEGIN  
        
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1192               , -- 해당 @1 @2이(가) 초과되었습니다..(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1192)    
                               @LanguageSeq       ,  
                               2529,'', 9110, '' --건, 진행정보 //// select * from _TCADictionary where WordSeq = 2529  
         IF ISNULL(@IsSumNextProg,'') <> '1' 
         BEGIN
             SELECT @SQL = ' UPDATE #TCOMSourceDaily '  + CHAR(13)     
             SELECT @SQL = @SQL + ' SET Result        = ''' + @Results + ''', ' + CHAR(13)            
             SELECT @SQL = @SQL + ' MessageType   = ' + CONVERT(NVARCHAR(10), @MessageType) + ', '  + CHAR(13)         
             SELECT @SQL = @SQL + ' Status        = ' + CONVERT(NVARCHAR(10), @Status) + CHAR(13)        
             SELECT @SQL = @SQL + ' FROM #TCOMSourceDaily AS X ' + CHAR(13)     
             SELECT @SQL = @SQL + ' JOIN (SELECT B.FromTableSeq, B.FromSeq, B.FromSerl, B.FromSubSerl ' + CHAR(13)  
             SELECT @SQL = @SQL + '        FROM (SELECT FromTableSeq, ToTableSeq, FromSeq, FromSerl, FromSubSerl ' + CHAR(13)  
             SELECT @SQL = @SQL + '                FROM #TCOMSourceDaily  ' + CHAR(13)    
             SELECT @SQL = @SQL + '               GROUP BY FromTableSeq, ToTableSeq, FromSeq, FromSerl, FromSubSerl) AS A ' + CHAR(13)    
             SELECT @SQL = @SQL + '              JOIN _TCOMSourceDaily AS B WITH(NOLOCK) ON B.CompanySeq = ' + CAST(@CompanySeq AS NVARCHAR) + CHAR(13)  
             SELECT @SQL = @SQL + '                                                    AND A.FromTableSeq = B.FromTableSeq ' + CHAR(13)  
             SELECT @SQL = @SQL + '                                                    AND A.ToTableSeq   = B.ToTableSeq ' + CHAR(13)  
             SELECT @SQL = @SQL + '                                                    AND A.FromSeq      = B.FromSeq ' + CHAR(13)  
             SELECT @SQL = @SQL + '                                                     AND A.FromSerl     = B.FromSerl ' + CHAR(13)  
             SELECT @SQL = @SQL + '                                                    AND A.FromSubSerl  = B.FromSubSerl ' + CHAR(13)  
             SELECT @SQL = @SQL + '       GROUP BY B.FromTableSeq, B.FromSeq, B.FromSerl, B.FromSubSerl, B.FromQty, B.FromSTDQty, B.FromAmt, B.FromVAT  ' + CHAR(13)  
             IF @SMProgCheckKind = 1045001  
             BEGIN  
                 SELECT @SQL = @SQL + '      HAVING ABS(SUM(B.ToQty * B.ADD_DEL)) > ABS(B.FromQty)) AS Y ON X.FromTableSeq = Y.FromTableSeq ' + CHAR(13)  
             END  
             ELSE IF @SMProgCheckKind = 1045002  
             BEGIN  
                 SELECT @SQL = @SQL + '      HAVING ABS(SUM(B.ToSTDQty * B.ADD_DEL)) > ABS(B.FromSTDQty)) AS Y ON X.FromTableSeq = Y.FromTableSeq ' + CHAR(13)  
             END  
             ELSE IF @SMProgCheckKind = 1045003  
             BEGIN  
                 SELECT @SQL = @SQL + '      HAVING ABS(SUM(B.ToAmt * B.ADD_DEL)) > ABS(B.FromAmt)) AS Y ON X.FromTableSeq = Y.FromTableSeq ' + CHAR(13)  
             END  
             ELSE IF @SMProgCheckKind = 1045004  
             BEGIN  
                 SELECT @SQL = @SQL + '      HAVING SUM(B.ADD_DEL)>1) AS Y ON X.FromTableSeq = Y.FromTableSeq ' + CHAR(13)  
             END  
              -- 2012-01-19 by kskwon 삭제시는 초과check 하지 않음
             SELECT @SQL = @SQL + '  AND X.WorkingTag <> ''D'' AND X.FromSeq  = Y.FromSeq AND X.FromSerl = Y.FromSerl AND X.FromSubSerl  = Y.FromSubSerl ' + CHAR(13)  
       
             EXEC SP_EXECUTESQL @SQL    
         END
         ELSE
         BEGIN
    -------------- 모 SP에서 선언하여 사용하고 있을 수 있기에 데이터를 모두 없앴다.
    TRuncate Table #TMP_PROGRESSTABLE
    TRuncate Table #TCOMProgressTracking
          
    INSERT #TMP_PROGRESSTABLE    
    SELECT 1, @NextTableName
     exec _SCOMProgressTracking @CompanySeq, @TableName, '#TCOMSourceDaily', 'FromSeq', 'FromSerl', 'FromSubSerl'
              SELECT @SQL = ' UPDATE #TCOMSourceDaily '  + CHAR(13)     
             SELECT @SQL = @SQL + ' SET Result        = ''' + @Results + ''', ' + CHAR(13)            
             SELECT @SQL = @SQL + ' MessageType   = ' + CONVERT(NVARCHAR(10), @MessageType) + ', '  + CHAR(13)         
             SELECT @SQL = @SQL + ' Status        = ' + CONVERT(NVARCHAR(10), @Status) + CHAR(13)        
             SELECT @SQL = @SQL + ' FROM #TCOMSourceDaily AS X ' + CHAR(13)     
             SELECT @SQL = @SQL + ' JOIN (SELECT  IDX_NO, SUM(Qty) Qty, SUM(STDQty) STDQty, SUM(Amt) Amt, SUM(VAT) VAT ' + CHAR(13)  
             SELECT @SQL = @SQL + '         FROM  #TCOMProgressTracking ' + CHAR(13)  
             SELECT @SQL = @SQL + '       GROUP BY IDX_NO) Y ' + CHAR(13)  
             SELECT @SQL = @SQL + ' ON X.IDX_NO = Y.IDX_NO  ' + CHAR(13)  
                       
             IF @SMProgCheckKind = 1045001  
             BEGIN  
                 SELECT @SQL = @SQL + '      AND ABS(X.FromQty) < ABS(Y.Qty) ' + CHAR(13)  
             END  
             ELSE IF @SMProgCheckKind = 1045002  
             BEGIN  
                 SELECT @SQL = @SQL + '      AND ABS(X.FromSTDQty) < ABS(Y.STDQty) ' + CHAR(13)  
             END  
             ELSE IF @SMProgCheckKind = 1045003  
             BEGIN  
                 SELECT @SQL = @SQL + '      AND ABS(X.FromAmt) < ABS(Y.Amt) ' + CHAR(13)  
             END  
             --ELSE IF @SMProgCheckKind = 1045004  
             --BEGIN  
             --    SELECT @SQL = @SQL + '      AND ABS(X.FromQty) < ABS(Y.Qty) ' + CHAR(13)  
             --    SELECT @SQL = @SQL + '      HAVING ABS(SUM(B.ToVAT * B.ADD_DEL)) > ABS(B.FromVAT)) AS Y ON X.FromTableSeq = Y.FromTableSeq ' + CHAR(13)  
             --END  
       
             EXEC SP_EXECUTESQL @SQL 
         END
     END  
    
    
    SELECT @Status = (SELECT MAX(Status) FROM #TCOMSourceDaily )  
      
    RETURN @Status  