
IF OBJECT_ID('_SDAUMToolKindTreeSaveCHE') IS NOT Null 
    DROP PROC _SDAUMToolKindTreeSaveCHE
GO 

/************************************************************                  
  ��  �� - ���������з� Ʈ�� ����      
  �ۼ��� - 2011/03/17      
  �ۼ��� - shpark      
  ������ - 2014.09.15 ������ (GongjongSeq �ּ�ó��)   
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
        
      -- ���� ����Ÿ ��� ����            
   CREATE TABLE #TDAUMToolKindTreeCHE (WorkingTag NCHAR(1) NULL)        
   EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMToolKindTreeCHE'           
   IF @@ERROR <> 0 RETURN              
          
         
           
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)            
              
      EXEC _SCOMLog  @CompanySeq,            
                     @UserSeq,            
                     '_TDAUMToolKindTreeCHE',             
                     '#TDAUMToolKindTreeCHE',            
                     'UMToolKind,UpperUMToolKind',            
                     'CompanySeq,UMToolKind,UpperUMToolKind,Sort,Level,NodeImg,LastUserSeq,LastDateTime'            
                 
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT          
         
                
          -- Ʈ�������� ��ŷ�±װ� �Ѿ�� �����Ƿ�       
          -- Ʈ���� ��� �����͸� �����Ͽ� �⺻������ 'A'�� ��ŷ�±׷� �����ش�.      
          -- �׸��� Check SP���� �����̺�� ������ ���̺��� ���Ͽ� ���� �����ϴ� ��쿡�� 'U'�� ������Ʈ���ش�      
          -- �׸��� �Ʒ�����ó�� �����̺��� ������ ������ ���̺��� �����Ͱ� �������� �ʴ°��� �����ְ� Save �۾��� �����Ѵ�.      
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