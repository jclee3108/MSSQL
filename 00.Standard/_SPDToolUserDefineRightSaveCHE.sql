
IF OBJECT_ID('_SPDToolUserDefineRightSaveCHE') IS NOT NULL 
    DROP PROC _SPDToolUserDefineRightSaveCHE
GO 

/************************************************************  
 설  명 - 설비등록 제원 오른쪽 저장
 작성일 - 
 작성자 - 
 ************************************************************/  
 CREATE PROC dbo._SPDToolUserDefineRightSaveCHE
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
   
 AS      
   
   
     DECLARE @ProcSeq    INT,  
             @InputDate  NCHAR(8)  
   
     -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPDToolUserDefine (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TPDToolUserDefine'       
     IF @@ERROR <> 0 RETURN      
  
  -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
  EXEC _SCOMLog  @CompanySeq   ,
           @UserSeq      ,
           '_TPDToolUserDefine', -- 원테이블
           '#TPDToolUserDefine', -- 템프테이블명
           'ToolSeq, MngSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
           'CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime'
   
   
     -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
   
     -- DELETE      
     IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'D' AND Status = 0)    
     BEGIN    
          DELETE _TPDToolUserDefine  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDToolUserDefine AS B ON A.ToolSeq   = B.ToolSeq  
                                         AND A.MngSerl   = B.MngSerl
          WHERE B.WorkingTag = 'D'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
          -- 단위 삭제
         DELETE _TPDToolUserDefine  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDToolUserDefine AS B ON A.ToolSeq   = B.ToolSeq  
                                         AND A.MngSerl   = B.MngSerl
          WHERE B.WorkingTag = 'D'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
   
     END    
   
   
   
     IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'U' AND Status = 0)    
     BEGIN 
  --        -- 마스터 로그남기기
 --        INSERT INTO _TPDToolLog (LogUserSeq,    LogDateTime,    LogType,    CompanySeq,     ToolSeq,        ToolName,   ToolNo,     UMToolKind,
 --                                 Spec,          Capacity,       DeptSeq,    EmpSeq,         BuyDate,        BuyCost,    SMStatus,   CustSeq,
 --                                 Cavity,        DesignShot,     InitialShot,WorkShot,       TotalShot,      AssetSeq,   Remark,     LastUserSeq,    
 --                                 LastDateTime,  Uses,           Forms,      SerialNo,       NationSeq,      ManuCompnay,MoldCount,  OrderCustSeq,
 --                                 CustShareRate, ModifyShot,     ModifyDate, DisuseDate,     DisuseCustSeq,  ProdSrtDate,ASTelNo,    FactUnit)
 --
 --        SELECT TOP 1 @UserSeq,  GETDATE(),  WorkingTag, @CompanySeq,    ToolSeq,    '',     '',     0,
 --                     '',        '',         0,          0,              '',         0,      0,      0,
 --                     0,         0,          0,          0,              0,          0,      '',     0,
 --                     0,         '',         '',         '',             0,          '',     0,      0,
 --                     0,         0,          '',         '',             0,          '',     '',     0
 --          FROM #TPDToolUserDefine
 --         WHERE WorkingTag   = 'U'
          -- 본테이블 업데이트
         UPDATE _TPDToolUserDefine  
            SET  MngValText      = B.MngValText                 ,  
                 LastUserSeq     = @UserSeq                  ,  
                 LastDateTime    = GETDATE()  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDToolUserDefine AS B ON A.ToolSeq = B.ToolSeq  
                                         AND A.MngSerl   = B.MngSerl
 WHERE B.Status = 0      
            AND A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'U'  
         IF @@ERROR <> 0  RETURN  
          -- 단위 업데이트
         UPDATE _TPDToolUserDefine  
            SET  MngValText      = B.DataFieldID                 ,  
                 LastUserSeq     = @UserSeq                  ,  
                 LastDateTime    = GETDATE()  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDToolUserDefine AS B ON A.ToolSeq = B.ToolSeq  
                                         AND A.MngSerl   = B.MngSerl
          WHERE B.Status = 0      
            AND A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'U'  
         IF @@ERROR <> 0  RETURN  
     END
   
    
   
   
     IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'A' AND Status = 0)    
     BEGIN 
         INSERT INTO _TPDToolUserDefine (CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime)  
             SELECT  @CompanySeq,
                     ToolSeq,
                     TitleSerl,
                     MngValSeq,
                     MngValText,
                     @UserSeq,
                     GETDATE()
               FROM #TPDToolUserDefine AS A     
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0      
         IF @@ERROR <> 0 RETURN  
          -- 단위 저장
         INSERT INTO _TPDToolUserDefine (CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime)  
             SELECT  @CompanySeq,
                     ToolSeq,
                     TitleSerl,
                     MngValSeq,
                     DataFieldID,
                     @UserSeq,
                     GETDATE()
               FROM #TPDToolUserDefine AS A     
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0      
         IF @@ERROR <> 0 RETURN  
      END
   
     SELECT * FROM #TPDToolUserDefine     
     RETURN      
 /*******************************************************************************************************************/  
