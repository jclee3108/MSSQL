
IF OBJECT_ID('kpx_SDAUMajorCheck') IS NOT NULL 
    DROP PROC kpx_SDAUMajorCheck
GO 

-- v2014.08.27 

-- 사용자정의기타코드 등록_KPX(사용자정의코트대분류체크) by이재천 
CREATE PROC kpx_SDAUMajorCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #KPX_TDAUMajorMaster (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAUMajorMaster'
    
    ---------------------------------------------------------------------------------------------
    -- 체크1, 대분류명을 수정 할 수 없습니다. 
    ---------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1366               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정할%')  
                          @LanguageSeq       , 
                          2357, ''
    
    UPDATE #KPX_TDAUMajorMaster  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TDAUMajorMaster 
     WHERE WorkingTag = 'U' 
       AND Status = 0 
    ---------------------------------------------------------------------------------------------
    -- 체크1, END 
    ---------------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------
    -- 체크2, 중복체크 
    ---------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       
      
    UPDATE #KPX_TDAUMajorMaster  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TDAUMajorMaster AS A   
      JOIN (SELECT S.MajorSeq 
              FROM (SELECT A1.MajorSeq 
                      FROM #KPX_TDAUMajorMaster AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.UMajorSeq  
                      FROM KPX_TDAUMajorMaster AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TDAUMajorMaster   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND MajorSeq = A1.UMajorSeq
                                      )  
                   ) AS S  
             GROUP BY S.MajorSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.MajorSeq = B.MajorSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    ---------------------------------------------------------------------------------------------
    -- 체크2, END  
    ---------------------------------------------------------------------------------------------
    
    SELECT * FROM #KPX_TDAUMajorMaster 
    
    RETURN    
GO 
begin tran 
exec kpx_SDAUMajorCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <MajorSeq>1100</MajorSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024286,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020436
rollback 
