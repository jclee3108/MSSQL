  
IF OBJECT_ID('KPX_SEQCheckItemCheck') IS NOT NULL   
    DROP PROC KPX_SEQCheckItemCheck  
GO  
  
-- v2014.10.30  
  
-- 점검설비등록-체크 by 이재천   
CREATE PROC KPX_SEQCheckItemCheck  
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
      
    CREATE TABLE #KPX_TEQCheckItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQCheckItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #KPX_TEQCheckItem  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TEQCheckItem AS A   
      JOIN (SELECT S.ToolSeq, S.UMCheckTerm
              FROM (SELECT A1.ToolSeq, A1.UMCheckTerm  
                      FROM #KPX_TEQCheckItem AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ToolSeq, A1.UMCheckTerm  
                      FROM KPX_TEQCheckItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TEQCheckItem   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ToolSeq = A1.ToolSeq  
                                                 AND UMCheckTermOld = A1.UMCheckTerm
                                      )  
                   ) AS S  
             GROUP BY S.ToolSeq, S.UMCheckTerm
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ToolSeq = B.ToolSeq AND A.UMCheckTerm = B.UMCheckTerm )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_TEQCheckItem   
      
    RETURN  
GO
--exec KPX_SEQCheckItemCheck @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ToolSeq>60</ToolSeq>
--    <BizUnit>0</BizUnit>
--    <UMCheckTerm>1010201006</UMCheckTerm>
--    <CheckKind>etwe</CheckKind>
--    <CheckItem>setset</CheckItem>
--    <SMInputType>1027002</SMInputType>
--    <Remark>rasdf</Remark>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1025469,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021362