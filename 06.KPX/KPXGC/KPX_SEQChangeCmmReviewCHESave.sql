  
IF OBJECT_ID('KPX_SEQChangeCmmReviewCHESave') IS NOT NULL   
    DROP PROC KPX_SEQChangeCmmReviewCHESave  
GO  
  
-- v2014.12.12  
  
-- 변경위원회회의록등록-저장 by 이재천   
CREATE PROC KPX_SEQChangeCmmReviewCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TEQChangeCmmReviewCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQChangeCmmReviewCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQChangeCmmReviewCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEQChangeCmmReviewCHE'    , -- 테이블명        
                  '#KPX_TEQChangeCmmReviewCHE'    , -- 임시 테이블명        
                  'ReviewSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TEQChangeCmmReviewCHE AS A   
          JOIN KPX_TEQChangeCmmReviewCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReviewSeq = A.ReviewSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
    
        UPDATE B   
           SET B.ReviewDate = A.ReviewDate,  
               B.DeptSeq = A.DeptSeq,  
               B.UMResult = A.UMResult,  
               B.Contents1 = A.Contents1,  
               B.DeptName1 = A.DeptName1,  
               B.Date1 = A.Date1,  
               B.Contents2 = A.Contents2,  
               B.DeptName2 = A.DeptName2,  
               B.Date2 = A.Date2,  
               B.Contents3 = A.Contents3,  
               B.DeptName3 = A.DeptName3,  
               B.Date3 = A.Date3,  
               B.Contents4 = A.Contents4,  
               B.DeptName4 = A.DeptName4,  
               B.Date4 = A.Date4,  
               B.Contents6 = A.Contents6,  
               B.DeptName6 = A.DeptName6,  
               B.Date6 = A.Date6,  
               B.Contents7 = A.Contents7,  
               B.DeptName7 = A.DeptName7,  
               B.Date7 = A.Date7,  
               B.Contents8 = A.Contents8,  
               B.DeptName8 = A.DeptName8,  
               B.Date8 = A.Date8,  
               B.IsProcDept = A.IsProcDept,  
               B.IsProdDept = A.IsProdDept,  
               B.IsStdDept = A.IsStdDept,  
               B.IsSafeDept = A.IsSafeDept,  
               B.DeptEtc = A.DeptEtc,  
               B.IsAct = A.IsAct,  
               B.IsAdd = A.IsAdd,  
               B.IsNot = A.IsNot,  
               B.TotEtc = A.TotEtc, 
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_TEQChangeCmmReviewCHE AS A   
          JOIN KPX_TEQChangeCmmReviewCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.ReviewSeq = A.ReviewSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeCmmReviewCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEQChangeCmmReviewCHE  
        (   
            CompanySeq,ReviewSeq,ReviewDate,DeptSeq,UMResult,  
            Contents1,DeptName1,Date1,Contents2,DeptName2,  
            Date2,Contents3,DeptName3,Date3,Contents4,  
            DeptName4,Date4,Contents6,DeptName6,Date6,  
            Contents7,DeptName7,Date7,Contents8,DeptName8,  
            Date8,IsProcDept,IsProdDept,IsStdDept,IsSafeDept,  
            DeptEtc,IsAct,IsAdd,IsNot,TotEtc,  
            ChangeRequestSeq,LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.ReviewSeq,A.ReviewDate,A.DeptSeq,A.UMResult,  
               A.Contents1,A.DeptName1,A.Date1,A.Contents2,A.DeptName2,  
               A.Date2,A.Contents3,A.DeptName3,A.Date3,A.Contents4,  
               A.DeptName4,A.Date4,A.Contents6,A.DeptName6,A.Date6,  
               A.Contents7,A.DeptName7,A.Date7,A.Contents8,A.DeptName8,  
               A.Date8,A.IsProcDept,A.IsProdDept,A.IsStdDept,A.IsSafeDept,  
               A.DeptEtc,A.IsAct,A.IsAdd,A.IsNot,A.TotEtc,  
               A.ChangeRequestSeq,@UserSeq,GETDATE()   
          FROM #KPX_TEQChangeCmmReviewCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TEQChangeCmmReviewCHE   
      
    RETURN  