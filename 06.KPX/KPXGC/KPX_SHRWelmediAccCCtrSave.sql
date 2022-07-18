
IF OBJECT_ID('KPX_SHRWelmediAccCCtrSave') IS NOT NULL 
    DROP PROC KPX_SHRWelmediAccCCtrSave
GO 

-- v2014.12.08 

-- 의료비계정등록(활동센터)-저장 by이재천
 CREATE PROCEDURE KPX_SHRWelmediAccCCtrSave
     @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML로 전달  
     @xmlFlags    INT = 0         ,    -- 해당 XML의 TYPE  
     @ServiceSeq  INT = 0         ,    -- 서비스 번호  
     @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그  
     @CompanySeq  INT = 1         ,    -- 회사 번호  
     @LanguageSeq INT = 1         ,    -- 언어 번호  
     @UserSeq     INT = 0         ,    -- 사용자 번호  
     @PgmSeq      INT = 0              -- 프로그램 번호  
   
 AS  
   
     -- XML데이터를 담을 임시테이블 생성  
     CREATE TABLE #KPX_THRWelmediAccCCtr (WorkingTag NCHAR(1) NULL)  
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelmediAccCCtr'  
     IF @@ERROR <> 0 RETURN    -- 에러가 발생하면 리턴   
    
    UPDATE A
       SET WorkingTag = 'A' 
      FROM #KPX_THRWelmediAccCCtr AS A 
     WHERE NOT EXISTS (SELECT 1 FROM KPX_THRWelmediAccCCtr WHERE CompanySeq = @CompanySeq AND YM = A.YM AND GroupSeq = A.GroupSeq AND WelCodeSeq = A.WelCodeSeq AND EnvValue = A.EnvValue)
       AND A.WorkingTag IN ( 'A','U' ) 
    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelmediAccCCtr')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelmediAccCCtr'    , -- 테이블명        
                  '#KPX_THRWelmediAccCCtr'    , -- 임시 테이블명        
                  'EnvValue,YM,GroupSeq,WelCodeSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
   
   
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
    
        DELETE B 
          FROM #KPX_THRWelmediAccCCtr AS A 
          JOIN KPX_THRWelmediAccCCtr AS B ON ( B.CompanySeq = @CompanySeq 
                                           AND A.EnvValue   = B.EnvValue  
                                           AND A.YM         = B.YM
                                           AND A.GroupSeq   = B.GroupSeq
                                           AND A.WelCodeSeq     = B.WelCodeSeq
                                             )
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0  
        
        IF @@ERROR <> 0 RETURN  
        
    END  
    
    -- UPDATE 
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
    
        UPDATE B  
           SET AccSeq        = A.AccSeq,
               UMCostType    = A.UMCostType,
               OppAccSeq     = A.OppAccSeq,
               VatAccSeq     = A.VatAccSeq, 
               LastUserSeq   = @UserSeq,
               LastDateTime  = GETDATE() 
          FROM #KPX_THRWelmediAccCCtr AS A 
          JOIN KPX_THRWelmediAccCCtr  AS B ON ( B.CompanySeq    = @CompanySeq 
                                            AND A.EnvValue      = B.EnvValue  
                                            AND A.YM            = B.YM
                                            AND A.GroupSeq      = B.GroupSeq
                                            AND A.WelCodeSeq    = B.WelCodeSeq
                                              )
         WHERE A.WorkingTag = 'U'
           AND A.Status = 0  
        
        IF @@ERROR <> 0 RETURN    
    END 
    
    -- INSERT 
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN 
        
        INSERT INTO KPX_THRWelmediAccCCtr
        (      
            CompanySeq, EnvValue, YM, GroupSeq, WelCodeSeq, 
            AccSeq, UMCostType, OppAccSeq, VatAccSeq, LastUserSeq, 
            LastDateTime
        )  
        SELECT @CompanySeq, A.EnvValue, A.YM, A.GroupSeq, A.WelCodeSeq, 
               A.AccSeq, A.UMCostType, A.OppAccSeq, A.VatAccSeq, @UserSeq, 
               GETDATE()
          FROM #KPX_THRWelmediAccCCtr AS A  
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0
        
        IF @@ERROR <> 0 RETURN   
    
    END  
    
    SELECT * FROM #KPX_THRWelmediAccCCtr 
    
    RETURN