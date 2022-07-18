
IF OBJECT_ID('KPX_SPDItemWCStdCheck') IS NOT NULL   
    DROP PROC KPX_SPDItemWCStdCheck  
GO  
  
-- v2014.09.25  
  
-- 제품별설비기준등록-체크 by 이재천   
CREATE PROC KPX_SPDItemWCStdCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDItemWCStd( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDItemWCStd'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       
      
    UPDATE A
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TPDItemWCStd AS A   
      JOIN (SELECT S.ItemSeq, WorkCenterSeq, ProcSeq 
              FROM (SELECT A1.ItemSeqSub AS ItemSeq, WorkCenterSeq, ProcSeq 
                      FROM #KPX_TPDItemWCStd AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ItemSeq, WorkCenterSeq, ProcSeq   
                      FROM KPX_TPDItemWCStd AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TPDItemWCStd   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ItemSeqSub = A1.ItemSeq  
                                                 AND WorkCenterSeqOld = A1.WorkCenterSeq 
                                                 AND ProcSeqOld = A1.ProcSeq 
                                      )  
                   ) AS S  
             GROUP BY S.ItemSeq, WorkCenterSeq, ProcSeq 
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ItemSeqSub = B.ItemSeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.ProcSeq = B.ProcSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TPDItemWCStd   
      
    RETURN  
GO 
exec KPX_SPDItemWCStdCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WorkCenterSeq>100315</WorkCenterSeq>
    <ProcSeq>8</ProcSeq>
    <StdProdTime>1111</StdProdTime>
    <WCCapacity>100</WCCapacity>
    <Gravity>20</Gravity>
    <IsUse>1</IsUse>
    <WorkCenterSeqOld>0</WorkCenterSeqOld>
    <ProcSeqOld>0</ProcSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <ItemSeqSub>24722</ItemSeqSub>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024754,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020849