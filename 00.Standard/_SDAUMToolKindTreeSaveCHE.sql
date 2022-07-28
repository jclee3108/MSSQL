
IF OBJECT_ID('_SDAUMToolKindTreeSaveCHE') IS NOT Null 
    DROP PROC _SDAUMToolKindTreeSaveCHE
GO 

/************************************************************                  
  설  명 - 설비유형분류 트리 저장      
  작성일 - 2011/03/17      
  작성자 - shpark      
  수정자 - 2014.09.15 임희진 (GongjongSeq 주석처리)   
  ************************************************************/                  
  CREATE PROC dbo._SDAUMToolKindTreeSaveCHE     
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
   CREATE TABLE #TDAUMToolKindTreeCHE (WorkingTag NCHAR(1) NULL)        
   EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMToolKindTreeCHE'           
   IF @@ERROR <> 0 RETURN              
          
         
           
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)            
              
      EXEC _SCOMLog  @CompanySeq,            
                     @UserSeq,            
                     '_TDAUMToolKindTreeCHE',             
                     '#TDAUMToolKindTreeCHE',            
                     'UMToolKind,UpperUMToolKind',            
                     'CompanySeq,UMToolKind,UpperUMToolKind,Sort,Level,NodeImg,LastUserSeq,LastDateTime'            
                 
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT          
         
                
          -- 트리에서는 워킹태그가 넘어가지 않으므로       
          -- 트리의 모든 데이터를 수집하여 기본적으로 'A'의 워킹태그로 보내준다.      
          -- 그리고 Check SP에서 본테이블과 수집한 테이블을 비교하여 서로 존재하는 경우에는 'U'로 업데이트해준다      
          -- 그리고 아래에서처럼 본테이블에는 있지만 수집한 테이블에는 데이터가 존재하지 않는경우는 지워주고 Save 작업을 시작한다.      
          DELETE _TDAUMToolKindTreeCHE           
            FROM _TDAUMToolKindTreeCHE AS A           
                 LEFT OUTER JOIN #TDAUMToolKindTreeCHE AS B  ON A.UMToolKind       = B.UMToolKind      
                                                               AND A.UpperUMToolKind  = B.UpperUMToolKind      
           WHERE A.CompanySeq  = @CompanySeq      
             AND B.Seq IS NULL      
             AND A.UMToolKind <> 1      
            
          IF @@ERROR <> 0  RETURN            
              
              
       -- UPDATE                
      IF EXISTS (SELECT 1 FROM #TDAUMToolKindTreeCHE WHERE WorkingTag = 'U' AND Status = 0)              
      BEGIN      
          UPDATE _TDAUMToolKindTreeCHE          
             SET  UMToolKind      = B.Seq,      
                  UpperUMToolKind = B.ParentSeq,      
                  Sort            = B.Sort,      
                  Level           = B.Level,      
                  NodeImg         = ISNULL(B.NodeImg,''),      
                  --GongjongSeq     = ISNULL(dbo.fnToolParents(@CompanySeq,B.Seq),0),      
                  LastUserSeq     = @UserSeq,      
                  LastDateTime    = GETDATE()      
            FROM _TDAUMToolKindTreeCHE AS A           
                 JOIN #TDAUMToolKindTreeCHE AS B  ON A.UMToolKind       = B.UMToolKind      
                                                    AND A.UpperUMToolKind  = B.UpperUMToolKind      
           WHERE B.WorkingTag = 'U'           
             AND B.Status = 0                
             AND A.CompanySeq  = @CompanySeq           
            
          IF @@ERROR <> 0  RETURN           
      END       
                 
            
      -- INSERT            
      IF EXISTS (SELECT 1 FROM #TDAUMToolKindTreeCHE WHERE WorkingTag = 'A' AND Status = 0)              
      BEGIN              
          INSERT INTO _TDAUMToolKindTreeCHE (CompanySeq,UMToolKind,UpperUMToolKind,Sort,Level,NodeImg,LastUserSeq,LastDateTime)      
          SELECT  @CompanySeq,      
                  Seq,      
                  ParentSeq,      
                  Sort,      
                  Level,      
     ISNULL(NodeImg,''),      
                  --0,      
@UserSeq,      
                  GETDATE()      
            FROM #TDAUMToolKindTreeCHE AS A       
             WHERE A.WorkingTag = 'A'            
             AND A.Status = 0          
               
          IF @@ERROR <> 0 RETURN            
                
          --UPDATE _TDAUMToolKindTreeCHE          
          --   SET GongjongSeq     = ISNULL(dbo.fnToolParents(@CompanySeq,B.Seq),0)      
          --  FROM _TDAUMToolKindTreeCHE AS A           
          --       JOIN #TDAUMToolKindTreeCHE AS B  ON A.UMToolKind       = B.Seq      
          --                                          AND A.UpperUMToolKind  = B.ParentSeq      
          -- WHERE B.WorkingTag = 'A'           
          --   AND B.Status = 0                
          --   AND A.CompanySeq  = @CompanySeq           
            
          --IF @@ERROR <> 0  RETURN                    
      END               
         
            
      SELECT * FROM #TDAUMToolKindTreeCHE              
            
  RETURN    