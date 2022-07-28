
IF OBJECT_ID('_SEQYearRepairPlanManHourSaveCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairPlanManHourSaveCHE
GO 

-- v2014.12.04 

/************************************************************    
  설  명 - 데이터-년차보수 계획  Item : 저장    
  작성일 - 20110704    
  작성자 - 김수용    
 ************************************************************/    
 CREATE PROC [dbo].[_SEQYearRepairPlanManHourSaveCHE]    
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT             = 0,    
     @ServiceSeq     INT             = 0,    
     @WorkingTag     NVARCHAR(10)    = '',    
     @CompanySeq     INT             = 1,    
     @LanguageSeq    INT             = 1,    
     @UserSeq        INT             = 0,    
     @PgmSeq         INT             = 0    
 AS    
         
     CREATE TABLE #_TEQYearRepairPlanManHourCHE (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQYearRepairPlanManHourCHE'    
     IF @@ERROR <> 0 RETURN    
             
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
     EXEC _SCOMLog  @CompanySeq   ,    
                    @UserSeq      ,    
                    '_TEQYearRepairPlanManHourCHE', -- 원테이블명    
                    '#_TEQYearRepairPlanManHourCHE', -- 템프테이블명    
                    'ReqSeq, ReqSerl' , -- 키가 여러개일 경우는 , 로 연결한다.    
                    'CompanySeq,ReqSeq, ReqSerl,RepairYear, Amd, WorkOperSerl,ManHour,OTManHour,LastDateTime,LastUserSeq,DivSeq,EmpSeq'
      
 -- _TEQYearRepairMngCHEManHour    
      
      
     -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT    
      -- DELETE    
     IF EXISTS (SELECT TOP 1 1 FROM #_TEQYearRepairPlanManHourCHE WHERE WorkingTag = 'D' AND Status = 0)    
     BEGIN    
         DELETE _TEQYearRepairPlanManHourCHE    
           FROM _TEQYearRepairPlanManHourCHE A    
                JOIN #_TEQYearRepairPlanManHourCHE B     
                  ON 1 = 1    
                 AND A.ReqSeq    = B.ReqSeq        
                 AND A.ReqSerl   = B.ReqSerl    
          WHERE 1 = 1    
            AND A.CompanySeq  = @CompanySeq    
            AND B.WorkingTag = 'D'    
            AND B.Status = 0    
           IF @@ERROR <> 0  RETURN    
     END    
      -- UPDATE    
     IF EXISTS (SELECT 1 FROM #_TEQYearRepairPlanManHourCHE WHERE WorkingTag = 'U' AND Status = 0)    
     BEGIN    
         UPDATE _TEQYearRepairPlanManHourCHE    
            SET     
                 RepairYear      = B.RepairYear,    
                 Amd             = B.Amd,    
                 WorkOperSerl    = B.WorkOperSerl,    
                 DivSeq          = B.DivSeq, 
                 EmpSeq          = B.EmpSeqSub, 
                 ManHour         = B.ManHour,    
                 OTManHour       = B.OTManHour,    
                 LastDateTime    = GETDATE(),    
                 LastUserSeq     = @UserSeq    
           FROM _TEQYearRepairPlanManHourCHE AS A    
                JOIN #_TEQYearRepairPlanManHourCHE AS B     
                  ON 1 = 1    
                 AND A.ReqSeq    = B.ReqSeq        
                 AND A.ReqSerl   = B.ReqSerl    
          WHERE 1 = 1    
            AND A.CompanySeq = @CompanySeq    
            AND B.WorkingTag = 'U'    
            AND B.Status = 0    
          IF @@ERROR <> 0  RETURN    
     END    
      -- INSERT    
     IF EXISTS (SELECT 1 FROM #_TEQYearRepairPlanManHourCHE WHERE WorkingTag = 'A' AND Status = 0)    
     BEGIN    
         INSERT INTO _TEQYearRepairPlanManHourCHE (    
                                                     CompanySeq      ,ReqSeq         ,ReqSerl        ,RepairYear     ,Amd,    
                                                     WorkOperSerl    ,ManHour        ,OTManHour      ,LastDateTime   ,LastUserSeq, 
                                                     DivSeq          ,EmpSeq
                                                    )    
             SELECT @CompanySeq      ,ReqSeq         ,ReqSerl        ,RepairYear     ,Amd,     
                    WorkOperSerl     ,ManHour        ,OTManHour      ,GETDATE()      ,@UserSeq, 
                    DivSeq           ,EmpSeqSub
               FROM #_TEQYearRepairPlanManHourCHE AS A    
              WHERE 1 = 1    
                AND A.WorkingTag = 'A'    
                AND A.Status = 0    
          IF @@ERROR <> 0 RETURN    
     END    
        SELECT * FROM #_TEQYearRepairPlanManHourCHE     
        RETURN  