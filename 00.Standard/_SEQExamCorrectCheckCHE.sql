IF OBJECT_ID('_SEQExamCorrectCheckCHE') IS NOT NULL 
    DROP PROC _SEQExamCorrectCheckCHE
GO 

-- v2015.07.10 
/************************************************************
 ��  �� - ������-����˱������� : üũ
 �ۼ��� - 20110309
 �ۼ��� - �ſ��
************************************************************/
CREATE PROC [dbo].[_SEQExamCorrectCheckCHE]
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   
    DECLARE @MessageType INT,
            @Status    INT,
            @Results   NVARCHAR(250)
        
    CREATE TABLE #_TEQExamCorrectCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQExamCorrectCHE'   
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE #_TEQExamCorrectCHE  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #_TEQExamCorrectCHE AS A   
      JOIN (SELECT S.ToolSeq  
              FROM (SELECT A1.ToolSeq  
                      FROM #_TEQExamCorrectCHE AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ToolSeq  
                      FROM _TEQExamCorrectCHE AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #_TEQExamCorrectCHE   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ToolSeq = A1.ToolSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ToolSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ToolSeq = B.ToolSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    ------------------------------------------------------------------------
    -- üũ1, �˱��������� ��ϵ� ����� ����, ���� �� �� �����ϴ�. 
    ------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '����˱��������� ��ϵ� ����� ����, ���� �� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #_TEQExamCorrectCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND EXISTS (SELECT 1 FROM _TEQExamCorrectEditCHE WHERE CompanySeq = @CompanySeq AND ToolSeq = A.ToolSeq ) 
    
    ------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------
    
    SELECT * FROM #_TEQExamCorrectCHE 
    
    RETURN

GO
exec _SEQExamCorrectCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolSeq>1009</ToolSeq>
    <ManuCompnay />
    <AllowableError>223</AllowableError>
    <RefDate>20150302</RefDate>
    <CorrectCycleName>�б�</CorrectCycleName>
    <Remark />
    <CorrectCycleSeq>20026001</CorrectCycleSeq>
    <CorrectPlaceSeq>0</CorrectPlaceSeq>
    <Remark2>2344</Remark2>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10013,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100100