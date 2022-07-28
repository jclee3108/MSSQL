
IF OBJECT_ID('_SPDToolSaveCHE') IS NOT NULL 
    DROP PROC _SPDToolSaveCHE 
GO 

/************************************************************  
 설  명 - 설비등록 마스터 저장
 작성일 - 
 작성자 - 
 ************************************************************/  
 CREATE PROC dbo._SPDToolSaveCHE
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
   
 AS      
   
     
     -- 서비스 마스타 등록 생성  
     CREATE TABLE #TPDTool (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTool'       
     IF @@ERROR <> 0 RETURN      
    
     -- 마스터 로그남기기
     INSERT INTO _TPDToolLog (LogUserSeq,    LogDateTime,    LogType,    CompanySeq,     ToolSeq,        ToolName,   ToolNo,     UMToolKind,
                              Spec,          Capacity,       DeptSeq,    EmpSeq,         BuyDate,        BuyCost,    SMStatus,   CustSeq,
                              Cavity,        DesignShot,     InitialShot,WorkShot,       TotalShot,      AssetSeq,   Remark,     LastUserSeq,    
                              LastDateTime,  Uses,           Forms,      SerialNo,       NationSeq,      ManuCompnay,MoldCount,  OrderCustSeq,
                              CustShareRate, ModifyShot,     ModifyDate, DisuseDate,     DisuseCustSeq,  ProdSrtDate,ASTelNo,    FactUnit)
      SELECT TOP 1 @UserSeq,  GETDATE(),  WorkingTag, @CompanySeq,    ToolSeq,    ToolName,   ToolNo, UMToolKind,
                  '',        '',         0,          0,              '',         0,          0,      0,
                  0,         0,          0,          0,              0,          0,          '',     0,
                  0,         '',         '',         '',             0,          '',         0,      0,
                  0,         0,          '',         '',             0,          '',         '',     FactUnit
       FROM #TPDTool
 --     WHERE WorkingTag   = 'U'
    
     -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
     
     IF @WorkingTag = 'C'     -- 설비복사
     BEGIN
          UPDATE #TPDTool
            SET WorkingTag = @WorkingTag
          DECLARE @ToolSeq    INT
          
          -- 설비내부코드 따기
         --SELECT @ToolSeq = ISNULL(MAX(ToolSeq),0) + 1
         --  FROM _TPDTool AS A
         -- WHERE A.CompanySeq = @CompanySeq
        EXEC @ToolSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTool', 'ToolSeq', 1
        
        
          -- 설비번호 중복체크
         IF EXISTS (SELECT 1 FROM _TPDTool AS A JOIN #TPDTool AS B ON A.ToolNo = B.ToolNo
                    WHERE A.CompanySeq = @CompanySeq
                      AND B.WorkingTag = 'C'
                      AND B.Status     = 0 ) -- 본테이블에 같은 설비번호가 존재하면..
         BEGIN
             UPDATE #TPDTool      
                SET Result        = N'설비번호가 중복됩니다.',      
                    MessageType   = -1,      
                    Status        = 9999
              SELECT * FROM    #TPDTool
             RETURN
         END
    
    
    
        
          -- 제원 및 기타정보 복사
         INSERT INTO _TPDToolUserDefine(CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime)
         SELECT  @CompanySeq,
                 @ToolSeq,
                 A.MngSerl,
                 A.MngValSeq,
                 A.MngValText,
                 @UserSeq,
                 GETDATE() 
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'C'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
    
          -- 제원의 단위 복사
         INSERT INTO _TPDToolUserDefineCHE(CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime)
         SELECT  @CompanySeq,
                 @ToolSeq,
                 A.MngSerl,
                 A.MngValSeq,
                 A.MngValText,
                 @UserSeq,
                 GETDATE() 
           FROM _TPDToolUserDefineCHE   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'C'   
            AND B.Status =  0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
          -- 마스터 복사
         INSERT INTO _TPDTool (  CompanySeq,ToolSeq,ToolName,ToolNo,UMToolKind,Spec,Capacity,DeptSeq,EmpSeq,BuyDate,BuyCost,SMStatus,
                                 CustSeq,Cavity,DesignShot,InitialShot,WorkShot,TotalShot,AssetSeq,Remark,LastUserSeq,LastDateTime,
                                 Uses,Forms,SerialNo,NationSeq,ManuCompnay,MoldCount,OrderCustSeq,CustShareRate,ModifyShot,ModifyDate,
                                 DisuseDate,DisuseCustSeq,ProdSrtDate,ASTelNo,FactUnit )
         SELECT  @CompanySeq,
                 @ToolSeq,
                 B.ToolName,
                 B.ToolNo,
                 B.UMToolKind,
                 A.Spec,
                 A.Capacity,
                 A.DeptSeq,
                 A.EmpSeq,
                 A.BuyDate,
                 A.BuyCost,
                 A.SMStatus,
                 A.CustSeq,
                 A.Cavity,
                 A.DesignShot,
                 A.InitialShot,
                 A.WorkShot,
                 A.TotalShot,
                 A.AssetSeq,
                 A.Remark,
                 @UserSeq,
                 GETDATE(),
                 A.Uses,
                 A.Forms,
                 A.SerialNo,
                 A.NationSeq,
                 A.ManuCompnay,
                 A.MoldCount,
                 A.OrderCustSeq,
                 A.CustShareRate,
                 A.ModifyShot,
                 A.ModifyDate,
                 A.DisuseDate,
                 A.DisuseCustSeq,
                 A.ProdSrtDate,
                 A.ASTelNo,
                 B.FactUnit
           FROM _TPDTool   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'C'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
 END
     
   
     -- DELETE      
     IF @WorkingTag = 'P'    -- 설비삭제일 경우만 마스터 지움
     BEGIN    
          UPDATE #TPDTool
            SET WorkingTag = @WorkingTag
          -- 제원 및 기타정보 삭제
         DELETE A  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'P'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
          -- 제원의 단위삭제
         DELETE A  
           FROM _TPDToolUserDefine   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'P'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
          -- 마스터 삭제
         DELETE A  
           FROM _TPDTool   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'P'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
          -- 마스터로그 삭제
         DELETE A  
           FROM _TPDToolLog   AS A   
             JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
          WHERE B.WorkingTag = 'P'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
  --        DELETE _TPDToolDetailMat
 --          FROM _TPDToolDetailMat   AS A   
 --            JOIN #TPDTool AS B ON A.ToolSeq   = B.ToolSeq  
 --         WHERE B.WorkingTag = 'P'   
 --           AND B.Status = 0  
 --           AND A.CompanySeq = @CompanySeq 
 --           AND A.TermSerl   = 1     -- 이 화면에서 다루는 TermSerl 은 1로 고정
 --        IF @@ERROR <> 0  RETURN  
   
     END    
   
   
   
     IF EXISTS (SELECT TOP 1 1 FROM #TPDTool WHERE WorkingTag = 'U' AND Status = 0)    
     BEGIN 
         UPDATE _TPDTool  
            SET  ToolName        = B.ToolName,
                 ToolNo          = B.ToolNo,
                UMToolKind      = B.UMToolKind,
                 FactUnit        = B.FactUnit,
                 LastUserSeq     = @UserSeq,
                 LastDateTime    = GETDATE()
           FROM _TPDTool   AS A   
         JOIN #TPDTool AS B ON A.ToolSeq = B.ToolSeq  
          WHERE B.Status = 0      
            AND A.CompanySeq  = @CompanySeq
            AND B.WorkingTag = 'U'  
         IF @@ERROR <> 0  RETURN  
     END
   
   
   
   
   
     IF EXISTS (SELECT TOP 1 1 FROM #TPDTool WHERE WorkingTag = 'A' AND Status = 0)    
     BEGIN 
         INSERT INTO _TPDTool (  CompanySeq,     ToolSeq,        ToolName,   ToolNo,         UMToolKind, Spec,           Capacity,       DeptSeq,    EmpSeq,
                                 BuyDate,        BuyCost,        SMStatus,   CustSeq,        Cavity,     DesignShot,     InitialShot,    WorkShot,   TotalShot,
                                 AssetSeq,       Remark,         LastUserSeq,LastDateTime,   Uses,       Forms,          SerialNo,       NationSeq,  ManuCompnay,    MoldCount,
                                 OrderCustSeq,   CustShareRate,  ModifyShot, ModifyDate,     DisuseDate, DisuseCustSeq,  ProdSrtDate,    ASTelNo,    FactUnit) 
  
             SELECT  @CompanySeq,     ToolSeq,        ToolName,   ToolNo,         UMToolKind, '',             '',             0,          0,
                     '',             0,              0,          0,              0,          0,              0,              0,          0,
                     0,              '',             @UserSeq,   GETDATE(),      '',         '',             '',             0,          '',         0,
                     0,              0,              0,          '',             '',         0,              '',             '',     FactUnit
               FROM #TPDTool AS A     
              WHERE A.WorkingTag = 'A'
                AND A.Status = 0      
         IF @@ERROR <> 0 RETURN  
     END
   
     SELECT * FROM #TPDTool     
     RETURN      
go
begin tran 
exec _SPDToolSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ToolNo>test설비임ets</ToolNo>
    <ToolName>test설비임setse</ToolName>
    <UMToolKind>6009028</UMToolKind>
    <ToolSeq>1014</ToolSeq>
    <FactUnit>112</FactUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10455,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100520
rollback 