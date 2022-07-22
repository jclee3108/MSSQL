  
IF OBJECT_ID('hncom_SPRAdjWithHoldListSS2Del') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListSS2Del  
GO  
  
-- v2017.02.08
      
-- 원천세신고목록-SS2삭제체크 by 이재천    
CREATE PROC hncom_SPRAdjWithHoldListSS2Del  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hncom_TAdjWithHoldList (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hncom_TAdjWithHoldList')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hncom_TAdjWithHoldList'    , -- 테이블명        
                  '#hncom_TAdjWithHoldList'    , -- 임시 테이블명        
                  'AdjSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
      
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hncom_TAdjWithHoldList WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hncom_TAdjWithHoldList  AS A   
          JOIN hncom_TAdjWithHoldList   AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
                    
    END    
      
      
    SELECT * FROM #hncom_TAdjWithHoldList   
      
    RETURN  
