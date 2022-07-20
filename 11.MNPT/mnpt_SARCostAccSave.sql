IF OBJECT_ID('mnpt_SARCostAccSave') IS NOT NULL 
    DROP PROC mnpt_SARCostAccSave
GO 

-- v2018.01.08 
/************************************************************  
설  명 - 전자결재연동계정환경설정 - 저장  
작성일 - 2010년 04월 19일   
작성자 - 송경애  
************************************************************/  
CREATE PROC dbo.mnpt_SARCostAccSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0,  
    @BgtName        NVARCHAR(200) = ''    
  
AS      
--select * from _TDASMinor where minorseq = 4503004 
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #TARCostAcc (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TARCostAcc'       
    IF @@ERROR <> 0 RETURN      
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TARCostAcc', -- 원테이블명  
                   '#TARCostAcc', -- 템프테이블명  
                   'SMKindSeq,CostSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq,SMKindSeq,CostSeq,CostName,AccSeq,RemSeq,RemValSeq,CashDate,Remark,LastUserSeq,LastDateTime, OppAccSeq, EvidSeq, UMCostType, IsNotUse',
                   '',
                   @PgmSeq  

    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'mnpt_TARCostAccSub', -- 원테이블명  
                   '#TARCostAcc', -- 템프테이블명  
                   'SMKindSeq,CostSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq',
                   '',
                   @PgmSeq  
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
    -- DELETE      
    IF EXISTS (SELECT TOP 1 1 FROM #TARCostAcc WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN    
        DELETE _TARCostAcc  
          FROM _TARCostAcc A JOIN #TARCostAcc B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  

        DELETE mnpt_TARCostAccSub  
          FROM mnpt_TARCostAccSub A JOIN #TARCostAcc B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  
  
    END    
  
    -- UPDATE      
    IF EXISTS (SELECT 1 FROM #TARCostAcc WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE _TARCostAcc  
           SET CostName  = B.CostName   
            , AccSeq        = B.AccSeq     
            , RemSeq        = B.RemSeq     
            , RemValSeq     = B.RemValSeq  
            , CashDate      = B.CashDate   
            , Remark        = B.Remark  
            , OppAccSeq     = B.OppAccSeq  
            , EvidSeq       = B.EvidSeq  
            , LastUserSeq   = @UserSeq  
            , LastDateTime  = GETDATE()  
            , UMCostType    = B.UMCostType  
            , Sort          = B.Sort
            , IsNotUse      = B.IsNotUse 
          FROM _TARCostAcc AS A JOIN #TARCostAcc AS B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'U' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq   
        IF @@ERROR <> 0  RETURN 
        
        UPDATE mnpt_TARCostAccSub  
           SET CostSClassSeq  = B.CostSClassSeq
             , LastUserSeq   = @UserSeq  
             , LastDateTime  = GETDATE()  
          FROM mnpt_TARCostAccSub AS A JOIN #TARCostAcc AS B ON (A.SMKindSeq = B.OldSMKindSeq AND A.CostSeq = B.CostSeq)    
         WHERE B.WorkingTag = 'U' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq   
        IF @@ERROR <> 0  RETURN  
    END     
  
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #TARCostAcc WHERE WorkingTag = 'A' AND Status = 0)    
    BEGIN    
        INSERT INTO _TARCostAcc   
                    (CompanySeq ,SMKindSeq  ,CostSeq    ,CostName   ,AccSeq  
                    ,RemSeq     ,RemValSeq  ,CashDate   ,Remark     ,LastUserSeq  
                    ,LastDateTime, OppAccSeq, EvidSeq   ,UMCostType ,Sort
                    ,IsNotUse)  
              SELECT @CompanySeq,4503004    ,A.CostSeq  ,A.CostName ,A.AccSeq  -- 일반비용
                    ,A.RemSeq   ,A.RemValSeq,A.CashDate ,A.Remark   ,@UserSeq         
                    ,GETDATE()  ,A.OppAccSeq,A.EvidSeq  ,A.UMCostType ,A.Sort
                    ,IsNotUse  
              FROM #TARCostAcc AS A     
             WHERE A.WorkingTag = 'A' AND A.Status = 0      
        IF @@ERROR <> 0 RETURN  

        INSERT INTO mnpt_TARCostAccSub   
        (
            CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )  
        SELECT @CompanySeq, SMKindSeq, CostSeq, CostSClassSeq, @UserSeq, -- 일반비용
               GETDATE(), @UserSeq, GETDATE(), @PgmSEq
          FROM #TARCostAcc AS A     
         WHERE A.WorkingTag = 'A' AND A.Status = 0      
        IF @@ERROR <> 0 RETURN  
    END     
    -- 출력화면에 예산과목 함께 출력하기 위안 OUTPUT 추가  
    -- 2011.02.07 김대용  
  
    UPDATE #TARCostAcc   
       SET BgtName = C.BgtName  
      FROM #TARCostAcc AS A JOIN _TACBgtAcc     AS B  
                              ON @CompanySeq    = B.CompanySeq  
                             AND A.AccSeq       = B.AccSeq  
                             AND A.RemSeq       = B.RemSeq  
                             AND A.RemValSeq    = B.RemValSeq  
                            JOIN _TACBgtItem    AS C  
                              ON @CompanySeq    = C.CompanySeq   
                             AND B.BgtSeq       = C.BgtSeq  
  
    SELECT * FROM #TARCostAcc  
RETURN      
  