IF OBJECT_ID('hencom_SSLDeptAddInfoSave') IS NOT NULL 
    DROP PROC hencom_SSLDeptAddInfoSave
GO 

-- v2017.05.22 

/************************************************************
  설  명 - 데이터-사업소관리(추가정보)_hencom : 저장
  작성일 - 20151020
  작성자 - 박수영
         - 2016.03.17  kth 매핑용 생산사업소 추가
 ************************************************************/
 CREATE PROC hencom_SSLDeptAddInfoSave
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 1,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0  
  AS   
  
  CREATE TABLE #hencom_TDADeptAdd (WorkingTag NCHAR(1) NULL)  
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TDADeptAdd'     
  IF @@ERROR <> 0 RETURN  
      
     DECLARE @TableColumns NVARCHAR(4000)
      
      SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TDADeptAdd') 
  -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog  @CompanySeq   ,
        @UserSeq      ,
        'hencom_TDADeptAdd', -- 원테이블명
        '#hencom_TDADeptAdd', -- 템프테이블명
        'DeptSeq ' , -- 키가 여러개일 경우는 , 로 연결한다. 
        @TableColumns,
        '', 
        @PgmSeq 
  -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
   -- DELETE    
  IF EXISTS (SELECT TOP 1 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'D' AND Status = 0)  
  BEGIN  
    DELETE hencom_TDADeptAdd
      FROM #hencom_TDADeptAdd A 
     JOIN hencom_TDADeptAdd B ON ( A.DeptSeq = B.DeptSeq ) 
                          
     WHERE B.CompanySeq  = @CompanySeq
       AND A.WorkingTag = 'D' 
       AND A.Status = 0    
     IF @@ERROR <> 0  RETURN
  END  
  
  -- UPDATE    
    IF EXISTS (SELECT 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE hencom_TDADeptAdd
           SET  UmAreaLClass      = A.UMAreaLClass      ,
                UMTotalDiv        = A.UMTotalDiv        ,
                DispSeq           = A.DispSeq           ,
                IsLentCarPrice    = A.IsLentCarPrice    ,
                MinRotation       = A.MinRotation       ,
                OracleKey         = A.OracleKey         ,
                Remark            = A.Remark            ,
                LastUserSeq       = @UserSeq            ,
                LastDateTime      = GETDATE()           ,
                ProdDeptSeq       = A.ProdDeptSeq       , -- 2016.03.17  kth 매핑용 생산사업소 추가
                DispQC            = A.DispQC            , 
                IsUseReport       = A.IsUseReport
          FROM #hencom_TDADeptAdd AS A 
               JOIN hencom_TDADeptAdd AS B ON (A.DeptSeq = B.DeptSeq ) 
                              
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
       
    IF @@ERROR <> 0  RETURN
    END  
   -- INSERT
  IF EXISTS (SELECT 1 FROM #hencom_TDADeptAdd WHERE WorkingTag = 'A' AND Status = 0)  
  BEGIN  
             -- 2016.03.17  kth 매핑용 생산사업소 추가
    INSERT INTO hencom_TDADeptAdd ( CompanySeq,DeptSeq,UmAreaLClass,UMTotalDiv,DispSeq,IsLentCarPrice
                                             ,MinRotation,OracleKey,Remark,LastUserSeq,LastDateTime,ProdDeptSeq,DispQC,IsUseReport) 
    SELECT @CompanySeq,DeptSeq,UMAreaLClass,UMTotalDiv,DispSeq,IsLentCarPrice
                     ,MinRotation,OracleKey,Remark,@UserSeq,GETDATE(),ProdDeptSeq ,DispQC,IsUseReport
      FROM #hencom_TDADeptAdd AS A   
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0    
    IF @@ERROR <> 0 RETURN
  END   
  
  SELECT * FROM #hencom_TDADeptAdd 
 RETURN
