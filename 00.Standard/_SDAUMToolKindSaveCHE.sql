IF OBJECT_ID('_SDAUMToolKindSaveCHE') IS NOT NULL 
    DROP PROC _SDAUMToolKindSaveCHE
GO

-- v2015.12.28 

-- SS1 ��Ʈ������ SS2�����͵� ���� �����ϴ� ���� �߰� 
/************************************************************            
 ��  �� - ��������/�����׸��� ����
 �ۼ��� - 2011/03/17
 �ۼ��� - shpark
 ************************************************************/            
 CREATE PROC dbo._SDAUMToolKindSaveCHE    
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
  CREATE TABLE #TDAUMinor (WorkingTag NCHAR(1) NULL)  
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMinor'     
  IF @@ERROR <> 0 RETURN        
   
  
    
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
       
     EXEC _SCOMLog  @CompanySeq,      
                    @UserSeq,      
                    '_TDAUMinor',       
                    '#TDAUMinor',      
                    'MinorSeq',      
                    'CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse'      
          
     -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT    
  
       
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN    
          DELETE _TDAUMinor      
           FROM _TDAUMinor AS A     
                JOIN #TDAUMinor AS B  ON A.MinorSeq  = B.MinorSeq
          WHERE B.WorkingTag = 'D'     
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq
            ANd A.MajorSeq    = 6009     
  
     
         IF @@ERROR <> 0  RETURN      
        
        DELETE A 
          FROM _TCOMUserDefine   AS A 
          JOIN #TDAUMinor       AS B ON ( B.MinorSeq = A.DefineUnitSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.TableName = '_TDAUMajor_6009'
           AND B.WorkingTag = 'D' 
           AND B.Status = 0 
        
        IF @@ERROR <> 0  RETURN 
    
     END        
       
      -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TDAUMinor WHERE WorkingTag = 'U' AND Status = 0)        
     BEGIN
         UPDATE _TDAUMinor    
            SET  MinorName       = B.MinorName,
                 MinorSort       = B.MinorSort,
                 Remark          = B.Remark,
                 IsUse           = B.IsUse,
                 LastUserSeq     = @UserSeq,
                 LastDateTime    = GETDATE()
           FROM _TDAUMinor AS A     
                JOIN #TDAUMinor AS B    ON A.MinorSeq  = B.MinorSeq
          WHERE B.WorkingTag = 'U'     
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq     
            ANd A.MajorSeq    = 6009
     
         IF @@ERROR <> 0  RETURN     
     END 
      
    
     
     -- INSERT      
     IF EXISTS (SELECT 1 FROM #TDAUMinor WHERE WorkingTag = 'A' AND Status = 0)        
     BEGIN        
         INSERT INTO _TDAUMinor (CompanySeq,MinorSeq,MajorSeq,MinorName,MinorSort,Remark,WordSeq,LastUserSeq,LastDateTime,IsUse)
         SELECT  @CompanySeq,
                 MinorSeq,
                 6009,
                 MinorName,
                 MinorSort,
                 Remark,
                 0,              
                 @UserSeq,
                 GETDATE(),
                 IsUse
           FROM #TDAUMinor AS A 
          WHERE A.WorkingTag = 'A'     
            AND A.Status = 0    
        
         IF @@ERROR <> 0 RETURN      
     END         
  
     
     SELECT * FROM #TDAUMinor        
     
 --select * from _TDAUMinor
 --select * from _TPNExrate where PlanYear = '2010'
 RETURN          
 /*******************************************************************************************************************/