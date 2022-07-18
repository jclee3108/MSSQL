IF OBJECT_ID('KPXCM_SLGLotNoMasterSave_MES') IS NOT NULL    
    DROP PROC KPXCM_SLGLotNoMasterSave_MES
GO 

-- v2015.09.23 KPXCM MES 용


-- v2012.11.15
  /*************************************************************************************************
  설  명 - LotNo Master 저장
  작성일 - 2009. 3: CREATED BY 김준모
 *************************************************************************************************/
  -- LotNo Master 등록 - 저장 
 CREATE PROC KPXCM_SLGLotNoMasterSave_MES
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10) = '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
     DECLARE @docHandle      INT,
             @Count          INT,
             @Seq            INT,
             @EnvValue       NCHAR(1)
      -- 서비스 마스타 등록 생성
     CREATE TABLE #TLGLotMaster (WorkingTag NVARCHAR(2) NULL)
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGLotMaster'
  
     IF EXISTS (SELECT * FROM _TLGLotMasterPgm WHERE CompanySeq = @CompanySeq AND PgmSeq = @PgmSeq AND IsUsed = '0')
     BEGIN
         SELECT * FROM #TLGLotMaster
         RETURN
     END
      -- 로그 남기기
     DECLARE @TableColumns NVARCHAR(4000)
     
     SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGLotMaster')
     
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TLGLotMaster', -- 원테이블명
                    '#TLGLotMaster', -- 템프테이블명
                    'LotNo,ItemSeq', -- 키가 여러개일 경우는 , 로 연결한다.
                    --'CompanySeq,LotNo,ItemSeq,SourceLotNo,UnitSeq,Qty,CreateDate,CreateTime,ValiDate,ValidTime,
                    -- RegDate,RegUserSeq,CustSeq,Remark,OriLotNo,OriItemSeq,InNo,SupplyCustSeq,PgmSeqModifying,LastUserSeq,LastDateTime,
                    -- Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy7'
                    @TableColumns, '', @PgmSeq 
     
     SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGLotSeq')
     
     -- _S%Save 와 _S%Delete 두가지 SP에만 한해서 ... 
     EXEC _SCOMDeleteLog @CompanySeq,  
                         @UserSeq,  
                         '_TLGLotSeq', 
                         '#TLGLotMaster', 
                         'LotNo,ItemSeq', -- CompanySeq제외 한 키 
                         @TableColumns, '', @PgmSeq 
     
     IF NOT EXISTS (
         SELECT *
           FROM _TLGLotMasterPgm WITH(NOLOCK)
          WHERE CompanySeq   = @CompanySeq
            AND PgmSeq       = @PgmSeq
            AND (IsDirectSave = '1' OR (IsDirectSave = '0' AND IsUsed = '0'))
     )
     BEGIN
         UPDATE #TLGLotMaster
            SET SourceLotNo = LotNo
          WHERE ISNULL(LotNo, '')        <> ''
            AND ISNULL(SourceLotNo, '')  = ''
            AND WorkingTag               IN ('A', 'U', 'UA')
            AND Status                   = 0
     END
      -- 유효일자 미입력하는 경우 자동으로 설정에 따라 수정하여 넣기
     -- 8004001 : 월
     UPDATE #TLGLotMaster
        SET ValiDate = CONVERT(NCHAR(8), DATEADD(d, -1, DATEADD(mm, B.LimitTerm, A.CreateDate)), 112)
       FROM #TLGLotMaster AS A
            INNER JOIN _TDAItemStock AS B
                    ON B.CompanySeq  = @CompanySeq
                   AND B.ItemSeq     = A.ItemSeq
                   AND B.SMLimitTermKind = 8004001   -- 월
                   AND B.LimitTerm   > 0
      WHERE ISNULL(A.CreateDate, '') > ''
        AND ISNULL(A.ValiDate, '')   = ''
        AND LEN(A.CreateDate)        = 8
        AND A.WorkingTag             IN ('A', 'U', 'UA')
        AND A.Status                 = 0
      -- 8004002 : 일
     UPDATE #TLGLotMaster
        SET ValiDate = CONVERT(NCHAR(8), DATEADD(d, B.LimitTerm, A.CreateDate), 112)
       FROM #TLGLotMaster AS A
            INNER JOIN _TDAItemStock AS B
                    ON B.CompanySeq  = @CompanySeq
                   AND B.ItemSeq     = A.ItemSeq
                   AND B.SMLimitTermKind = 8004002   -- 일
                   AND B.LimitTerm   > 0
      WHERE ISNULL(A.CreateDate, '') > ''
        AND ISNULL(A.ValiDate, '')   = ''
        AND LEN(A.CreateDate)        = 8
        AND A.WorkingTag             IN ('A', 'U', 'UA')
        AND A.Status                  = 0
     -- 유효일자 자동입력 끝.
  
     EXEC dbo._SCOMEnv @CompanySeq, 8038, @UserSeq, 0, @EnvValue OUTPUT  -- Lot No 중복 허용 여부
     
     IF @PgmSeq = 5020 -- LotNo Master등록 화면에서는 환경설정과 관계없이 삭제 될 수 있도록 수정 :: 20140410 박성호
     BEGIN
     
         -- DELETE      
         IF EXISTS (SELECT 1 FROM #TLGLotMaster WHERE WorkingTag IN ('XD', 'D') AND Status = 0)      
         BEGIN      
             DELETE _TLGLotMaster      
               FROM _TLGLotMaster AS A      
                    JOIN #TLGLotMaster AS B ON A.LotNo   = B.LotNoOLD      
                                           AND A.ItemSeq = B.ItemSeqOLD      
              WHERE B.WorkingTag IN ('XD', 'D')      
                AND B.Status     = 0      
                AND A.CompanySeq = @CompanySeq  
                --AND A.PgmSeq = @PgmSeq
             IF @@ERROR <> 0 RETURN
           
             -- LOT Master 삭제      
             DELETE _TLGLotSeq      
               FROM _TLGLotSeq AS A      
                    JOIN #TLGLotMaster AS B ON A.LotNo   = B.LotNoOLD      
                                           AND A.ItemSeq = B.ItemSeqOLD      
              WHERE B.WorkingTag IN ('XD', 'D')      
                AND B.Status     = 0      
                AND A.CompanySeq = @CompanySeq  
                --AND A.PgmSeq = @PgmSeq      
             IF @@ERROR <> 0 RETURN      
         END  
      END
     ELSE IF ( @PgmSeq <> 5020 AND @EnvValue = '0' ) -- LotNo Master등록 화면에서 삭제하는 것이 아니고, 중복 허용일 경우 삭제되지 않도록.. :: 김권우
     BEGIN
          -- DELETE      
         IF EXISTS (SELECT 1 FROM #TLGLotMaster WHERE WorkingTag IN ('XD', 'D') AND Status = 0)      
         BEGIN      
             DELETE _TLGLotMaster      
               FROM _TLGLotMaster AS A      
                    JOIN #TLGLotMaster AS B ON A.LotNo   = B.LotNoOLD      
                                           AND A.ItemSeq = B.ItemSeqOLD      
              WHERE B.WorkingTag IN ('XD', 'D')      
                AND B.Status     = 0      
                AND A.CompanySeq = @CompanySeq  
                --AND A.PgmSeq = @PgmSeq
             IF @@ERROR <> 0 RETURN      
           
             -- LOT Master 삭제      
             DELETE _TLGLotSeq      
               FROM _TLGLotSeq AS A      
                    JOIN #TLGLotMaster AS B ON A.LotNo   = B.LotNoOLD      
                                           AND A.ItemSeq = B.ItemSeqOLD      
              WHERE B.WorkingTag IN ('XD', 'D')      
                AND B.Status     = 0      
                AND A.CompanySeq = @CompanySeq  
                --AND A.PgmSeq = @PgmSeq      
             IF @@ERROR <> 0 RETURN      
         END  
      END
  
     -- Update
     IF EXISTS (SELECT 1 FROM #TLGLotMaster WHERE WorkingTag IN ('U', 'UA') AND Status = 0)
     BEGIN                 
         
   -- 처음엔 LotNo입력하지 않고 저장한 건을 LotNo입력하고 수정시 Lot마스터가 생성되게끔 수정, 2011.11.18 by 김철웅     
   INSERT INTO _TLGLotMaster 
   (
             CompanySeq,                                 LotNo,                                      ItemSeq,
             SourceLotNo,                                UnitSeq,                                    Qty,
             CreateDate,                                 CreateTime,                                 ValiDate,
             ValidTime,                                  RegDate,                                    RegUserSeq,
             CustSeq,                                    Remark,                                     OriLotNo,
             OriItemSeq,                                 InNo,                                       SupplyCustSeq,
             PgmSeqModifying,                            LastUserSeq,                                LastDateTime,
             Dummy1,                                     Dummy2,                                     Dummy3,
             Dummy4,       Dummy5,                                     Dummy6,
             Dummy7,                                     PgmSeq, Dummy8, Dummy9, Dummy10    
         )
   SELECT 
    @CompanySeq,                                 A.LotNo,                                    A.ItemSeq,
             ISNULL(A.SourceLotNo, ''),                  A.UnitSeq,                                  A.Qty,
             ISNULL(A.CreateDate, ''),                   REPLACE(ISNULL(A.CreateTime, ''), ':', ''), ISNULL(A.ValiDate, ''),
             REPLACE(ISNULL(A.ValidTime, ''), ':', ''),  ISNULL(A.RegDate, ''),                      @UserSeq,
             ISNULL(A.CustSeq, 0),                       ISNULL(A.Remark, ''),                       ISNULL(A.OriLotNo, ''),
             ISNULL(A.OriItemSeq, 0),                    A.InNo,                                     A.SupplyCustSeq,
             @PgmSeq,                                    @UserSeq,                                   GETDATE(),
             A.Dummy1,                                   A.Dummy2,                                   A.Dummy3,
             A.Dummy4,                                   A.Dummy5,                                   A.Dummy6,
             A.Dummy7,                                   @PgmSeq, A.Dummy8, A.Dummy9, A.Dummy10    
     FROM #TLGLotMaster AS A 
     JOIN _TDAItemStock AS B ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND B.IsLotMng = '1' )
    WHERE ISNULL(A.LotNoOLD, '')  = '' 
            AND ISNULL(A.LotNo   , '') <> ''
      AND WorkingTag IN ('U')--, 'UA')
      AND Status = 0
   
         IF NOT EXISTS (
             SELECT 1
               FROM _TLGLotMasterPgm WITH(NOLOCK)
              WHERE CompanySeq   = @CompanySeq
                AND PgmSeq       = @PgmSeq
                AND (IsDirectSave = '1' OR (IsDirectSave = '0' AND IsUsed = '0'))
         )
         BEGIN
             UPDATE _TLGLotMaster
                SET LotNo            = CASE WHEN ISNULL(A.LotNo, '')        = '' THEN B.LotNo            ELSE A.LotNo            END,
                    ItemSeq          = CASE WHEN ISNULL(A.ItemSeq, 0)       = 0  THEN B.ItemSeq          ELSE A.ItemSeq          END,
                    SourceLotNo      = CASE WHEN ISNULL(A.SourceLotNo, '')  = '' THEN B.SourceLotNo      ELSE A.SourceLotNo      END,
                    UnitSeq          = CASE WHEN ISNULL(A.UnitSeq, 0)       = 0  THEN B.UnitSeq          ELSE A.UnitSeq          END,
                    Qty              = CASE WHEN ISNULL(A.Qty, 0)           = 0  THEN B.Qty              ELSE A.Qty              END,
                    CreateDate       = CASE WHEN ISNULL(A.CreateDate, '')   = '' THEN B.CreateDate       ELSE A.CreateDate       END,
                    ValiDate         = CASE WHEN ISNULL(A.ValiDate, '')     = '' THEN B.ValiDate         ELSE A.ValiDate         END,
                    RegDate          = CASE WHEN ISNULL(A.RegDate, '')      = '' THEN B.RegDate          ELSE A.RegDate          END,
                    CustSeq          = CASE WHEN ISNULL(A.CustSeq, 0)       = 0  THEN B.CustSeq          ELSE A.CustSeq          END,
                    Remark           = CASE WHEN ISNULL(A.Remark, '')       = '' THEN B.Remark           ELSE A.Remark           END,
                    InNo             = CASE WHEN ISNULL(A.InNo, '')         = '' THEN B.InNo             ELSE A.InNo             END,
                    SupplyCustSeq    = CASE WHEN ISNULL(A.SupplyCustSeq, 0) = 0  THEN B.SupplyCustSeq    ELSE A.SupplyCustSeq    END,
                    PgmSeqModifying  = @PgmSeq,
                    LastUserSeq      = @UserSeq,
                    LastDateTime     = GETDATE(),
                    PgmSeq = @PgmSeq
               FROM #TLGLotMaster AS A
                    JOIN _TLGLotMaster AS B ON B.CompanySeq = @CompanySeq
                                           AND A.LotNoOLD   = B.LotNo
                                           AND A.ItemSeqOLD = B.ItemSeq
                    JOIN _TDAItemStock AS C ON C.CompanySeq = @CompanySeq
                                           AND A.ItemSeqOLD = C.ItemSeq
                                           AND C.IsLotMng   = '1'
              WHERE A.WorkingTag IN ('U', 'UA')
                AND A.Status     = 0
   AND A.LotNo      > ''
             IF @@ERROR <> 0 RETURN
         END
         ELSE
         BEGIN
             
             UPDATE _TLGLotMaster
                SET LotNo            = ISNULL(A.LotNo, ''),
                    ItemSeq          = ISNULL(A.ItemSeq, 0),
                    SourceLotNo      = ISNULL(A.SourceLotNo, ''),
                    UnitSeq          = ISNULL(A.UnitSeq, 0),
                    Qty              = ISNULL(A.Qty, 0),
                    CreateDate       = ISNULL(A.CreateDate, ''),
                    CreateTime       = REPLACE(ISNULL(A.CreateTime,''), ':', ''),
                    ValiDate         = ISNULL(A.ValiDate, ''),
                    ValidTime        = REPLACE(ISNULL(A.ValidTime,''), ':', ''),
                    RegDate          = ISNULL(A.RegDate, ''),
                    CustSeq          = ISNULL(A.CustSeq, 0),
                    Remark           = ISNULL(A.Remark, ''),
                    InNo             = ISNULL(A.InNo, ''),
                    SupplyCustSeq    = ISNULL(A.SupplyCustSeq, 0),
                    PgmSeqModifying  = @PgmSeq,
                    LastUserSeq      = @UserSeq,
                    LastDateTime     = GETDATE(),
                    Dummy1           = A.Dummy1,
                    Dummy2           = A.Dummy2,
                    Dummy3           = A.Dummy3,
                    Dummy4           = A.Dummy4,
                    Dummy5           = A.Dummy5,
                    Dummy6           = A.Dummy6,
                    Dummy7           = A.Dummy7,
                    Dummy8           = A.Dummy8,
                    Dummy9           = A.Dummy9,
                    Dummy10          = A.Dummy10,
                    PgmSeq           = @PgmSeq
               FROM #TLGLotMaster AS A
               JOIN _TLGLotMaster AS B ON ( B.CompanySeq = @CompanySeq AND A.LotNoOLD = B.LotNo AND A.ItemSeqOLD = B.ItemSeq )
               JOIN _TDAItemStock AS C ON ( C.CompanySeq = @CompanySeq AND A.ItemSeqOLD = C.ItemSeq AND C.IsLotMng = '1' )
              WHERE A.WorkingTag = 'U'
                AND A.Status     = 0
                AND A.LotNo      > ''
             
             IF @@ERROR <> 0 RETURN
         END
  
         UPDATE _TLGLotSeq
            SET ItemSeq  = B.ItemSeq,
                LotNo    = B.LotNo,
                PgmSeq = @PgmSeq
           FROM _TLGLotSeq AS A
                INNER JOIN #TLGLotMaster B ON B.LotNoOld = A.LotNo AND B.ItemSeqOld = A.ItemSeq
                      JOIN _TDAItemStock AS C ON C.CompanySeq = @CompanySeq
                                             AND B.ItemSeqOld = C.ItemSeq
                                             AND C.IsLotMng   = '1'
          WHERE B.WorkingTag IN ('U', 'UA')
            AND B.Status     = 0
            AND A.CompanySeq = @CompanySeq
            AND B.LotNo      > ''
         IF @@ERROR <> 0 RETURN
  
         UPDATE #TLGLotMaster
            SET LotNoOLD     = LotNo,
                ItemSeqOLD   = ItemSeq
          WHERE WorkingTag   IN ('U', 'UA')
            AND Status       = 0
            AND LotNo        > ''
         IF @@ERROR <> 0 RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #TLGLotMaster WHERE WorkingTag = 'A' AND Status = 0 )
     BEGIN
         INSERT INTO _TLGLotMaster (
             CompanySeq,                                 LotNo,                                      ItemSeq,
             SourceLotNo,                                UnitSeq,                                    Qty,
             CreateDate,                                 CreateTime,                                 ValiDate,
             ValidTime,                                  RegDate,                                    RegUserSeq,
             CustSeq,                                    Remark,                                     OriLotNo,
             OriItemSeq,                                 InNo,                                       SupplyCustSeq,
             PgmSeqModifying,                            LastUserSeq,                                LastDateTime,
   Dummy1,                                     Dummy2,                                     Dummy3,
             Dummy4,                                     Dummy5,                                     Dummy6,
             Dummy7,                                     PgmSeq, Dummy8, Dummy9, Dummy10 
         )
         SELECT
             @CompanySeq,                                A.LotNo,                                    A.ItemSeq,
             ISNULL(A.SourceLotNo, ''),                  A.UnitSeq,                                  A.Qty,
             ISNULL(A.CreateDate, ''),                   REPLACE(ISNULL(A.CreateTime, ''), ':', ''), ISNULL(A.ValiDate, ''),
             REPLACE(ISNULL(A.ValidTime, ''), ':', ''),  ISNULL(A.RegDate, ''),                      @UserSeq,
             ISNULL(A.CustSeq, 0),                       ISNULL(A.Remark, ''),                       ISNULL(A.OriLotNo, ''),
             ISNULL(A.OriItemSeq, 0),                    A.InNo,                                     A.SupplyCustSeq,
             @PgmSeq,                                    @UserSeq,                                   GETDATE(),
             A.Dummy1,                                   A.Dummy2,                                   A.Dummy3,
             A.Dummy4,                                   A.Dummy5,                                   A.Dummy6,
             A.Dummy7,                                   @PgmSeq, A.Dummy8, A.Dummy9, A.Dummy10    
           FROM #TLGLotMaster A
                  JOIN _TDAItemStock AS B ON B.CompanySeq = @CompanySeq
                                         AND B.ItemSeq    = A.ItemSeq
                                         AND B.IsLotMng   = '1'
          WHERE A.WorkingTag   = 'A'
            AND A.Status       = 0
            AND A.LotNo        > ''
         IF @@ERROR <> 0 RETURN
          -- 아래부분은 교착으로 인하여 주석처리 2011. 8. 2 hkim 
         --SELECT @Count = COUNT(1) FROM #TLGLotMaster WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)
         --IF @Count > 0
         --BEGIN
         --    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGLotSeq', 'LotSeq', @Count
          --    IF EXISTS (SELECT 1 FROM _TLGLotSeq WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND LotSeq >= @Seq)
       BEGIN
        SELECT @Seq = (SELECT MAX(LotSeq) + 1 FROM _TLGLotSeq WITH(NOLOCK) WHERE CompanySeq = @CompanySeq)
         --UPDATE _TCOMCreateSeqMax 
        --   SET MaxSeq = @Seq + @Count
        -- WHERE CompanySeq = @CompanySeq AND TableName = '_TLGLotSeq'
       END
              -- Temp Talbe 에 생성된 키값 UPDATE
             UPDATE #TLGLotMaster
                SET LotSeq = @Seq + DataSeq
              WHERE WorkingTag = 'A'
                AND Status   = 0
                AND LotNo    > ''
         --END
          INSERT INTO _TLGLotSeq (
             CompanySeq,     LotSeq,     ItemSeq,        LotNo, PgmSeq 
         )
         SELECT
             @CompanySeq,    A.LotSeq,     A.ItemSeq,        A.LotNo, @PgmSeq
           FROM #TLGLotMaster AS A
                  JOIN _TDAItemStock AS B ON B.CompanySeq = @CompanySeq
                                         AND A.ItemSeq    = B.ItemSeq
                                         AND B.IsLotMng   = '1'
          WHERE A.WorkingTag   = 'A'
            AND A.Status       = 0
            AND A.LotNo        > ''
            AND A.LotSeq       > 0
         IF @@ERROR <> 0 RETURN
  
         UPDATE #TLGLotMaster
            SET LotNoOLD     = LotNo,
                ItemSeqOLD   = ItemSeq,
                RegUserName  = ISNULL((SELECT UserName FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq), ''),
                RegUserSeq   = @UserSeq
          WHERE WorkingTag   = 'A'
            AND Status       = 0
            AND LotNo        > ''
         IF @@ERROR <> 0 RETURN
     END
  
     UPDATE #TLGLotMaster
        SET WorkingTag = REPLACE(WorkingTag, 'X', '')
      UPDATE #TLGLotMaster
        SET WorkingTag = REPLACE(WorkingTag, 'UA', 'A')
    
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TLGLotMaster )  
      
    RETURN @Status  
