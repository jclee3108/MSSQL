IF OBJECT_ID('KPXLS_SQCCOAPrintSave') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintSave
GO 

-- v2015.12.08 
  
-- 시험성적서발행(COA)-저장 by 이재천   
CREATE PROC KPXLS_SQCCOAPrintSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXLS_TQCCOAPrint (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXLS_TQCCOAPrint'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXLS_TQCCOAPrint')    

--ALTER TABLE KPXLS_TQCCOAPrint ADD CustEngName NVARCHAR(100)
--ALTER TABLE KPXLS_TQCCOAPrintLog ADD CustEngName NVARCHAR(100)
   
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXLS_TQCCOAPrint'    , -- 테이블명        
                  '#KPXLS_TQCCOAPrint'    , -- 임시 테이블명        
                  'COASeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
                                               -- 
     
    
    /* 
    
   
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCCOAPrint WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXLS_TQCCOAPrint AS A   
          JOIN KPXLS_TQCCOAPrint AS B ON ( B.CompanySeq = @CompanySeq AND B.COASeq = A.COASeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    */
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCCOAPrint WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET CustSeq = A.CustSeq,  
               ItemSeq = A.ItemSeq,  
               DVPlaceSeq = A.DVPlaceSeq,
               LotNo = A.LotNo,  
               QCType = A.QCType,  
               ShipDate = A.ShipDate,  
               COACount = A.COACount,  
               LastUserSeq  = @UserSeq,  
               LastDateTime = GETDATE(),
               Remark	  = A.MasterRemark,
               QCDate = A.QCDate,
               CustEngName  = A.CustEngName,
               LifeCycle    = A.LifeCycle, 
               CasNo        = CasNo        ,
               TestEmpName  = TestEmpName  ,
               OriWeight    = OriWeight    ,
               TotWeight    = TotWeight    ,
               CreateDate   = CreateDate   ,
               ReTestDate   = ReTestDate   ,
               TestResultDate = TestResultDate 
               
          FROM #KPXLS_TQCCOAPrint AS A   
          JOIN KPXLS_TQCCOAPrint AS B ON ( B.CompanySeq = @CompanySeq AND B.COASeq = A.COASeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXLS_TQCCOAPrint WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXLS_TQCCOAPrint  
        (   
            CompanySeq,COASeq,CustSeq,ItemSeq,LotNo,  
            QCType,ShipDate,COADate,COANo,COACount,  
            IsPrint,QCSeq, KindSeq, LastUserSeq,LastDateTime,
            Remark, QCDate, CustEngName, LifeCycle, DVPlaceSeq, 
            CasNo,TestEmpName,OriWeight,TotWeight,CreateDate,
            ReTestDate,TestResultDate,FromPgmSeq,SourceSeq, SourceSerl
        )   
        SELECT @CompanySeq,A.COASeq,A.CustSeq,A.ItemSeq,A.LotNo,  
               A.QCType,A.ShipDate,CONVERT(NCHAR(8), GETDATE(), 112) , A.COANo, A.COACount,  
               '0',A.QCSeq, KindSeq, @UserSeq,GETDATE(),
               MasterRemark, QCDate, CustEngName, LifeCycle, DVPlaceSeq, 
               CasNo,TestEmpName,OriWeight,TotWeight,CreateDate,
               ReTestDate,TestResultDate,FromPgmSeq,SourceSeq,SourceSerl
          FROM #KPXLS_TQCCOAPrint AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
        
        UPDATE A 
           SET COADate = CONVERT(NCHAR(8), GETDATE(), 112)
          FROM #KPXLS_TQCCOAPrint AS A 
    END     
    
    
    
    SELECT * FROM #KPXLS_TQCCOAPrint   
      
    RETURN  

GO


