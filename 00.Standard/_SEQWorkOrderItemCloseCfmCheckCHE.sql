
IF OBJECT_ID('_SEQWorkOrderItemCloseCfmCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkOrderItemCloseCfmCheckCHE
GO 

-- v2015.02.06 

/************************************************************  
  ��  �� - ����Ÿ-�۾�����Item�Ϸ���ε�� : üũ  
  �ۼ��� - 2011.05.19  
  �ۼ��� - �����  
 ************************************************************/  
 CREATE PROC dbo._SEQWorkOrderItemCloseCfmCheckCHE  
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
        @Status   INT,  
    @Results  NVARCHAR(250),  
             @Count INT,  
    @Seq INT   
     
     
       
    
      
    -- ���� ����Ÿ ��� ����  
     CREATE TABLE #capro_TEQWorkOrderItemCloseCfm (WorkingTag NCHAR(1) NULL)   
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#capro_TEQWorkOrderItemCloseCfm'  
     IF @@ERROR <> 0 RETURN   
      --�����ڵ尡 ����,�Ϸ��û�� ������ ���� �Ҽ� ����.
     UPDATE #capro_TEQWorkOrderItemCloseCfm
        SET Result        = '������°� ����Ǿ����ϴ�. ���� �� �� �����ϴ�.',  
            MessageType   = 99999,  
            Status        = 99999  
       FROM #capro_TEQWorkOrderItemCloseCfm AS A  
            JOIN _TEQWorkOrderReqItemCHE  AS B ON ( A.WOReqSeq   = B.WOReqSeq )   
                                                AND ( A.WOReqSerl  = B.WOReqSerl )   
          WHERE B.CompanySeq = @CompanySeq  
            AND B.ProgType NOT IN (20109007,20109008)
            AND A.Status = 0    
       
    
     UPDATE #capro_TEQWorkOrderItemCloseCfm  
       SET ProgType = CASE WHEN CfmYn =1 THEN 20109008 ELSE 20109007 END,  
           ProgTypeName = CASE WHEN CfmYn =1 THEN '�Ϸ�' ELSE '�Ϸ��û' END  
      FROM #capro_TEQWorkOrderItemCloseCfm   
     WHERE 1 = 1  
       AND Status = 0  
         
    
    
  SELECT * FROM #capro_TEQWorkOrderItemCloseCfm  
 RETURN      
 --GO     
 --exec _SEQWorkOrderItemCloseCfmCheckCHE @xmlDocument=N'<ROOT>
 --  <DataBlock1>
 --    <WorkingTag>U</WorkingTag>
 --    <IDX_NO>1</IDX_NO>
 --    <DataSeq>1</DataSeq>
 --    <Status>0</Status>
 --    <Selected>0</Selected>
 --    <CfmYn>1</CfmYn>
 --    <WOReqSeq>49959</WOReqSeq>
 --    <WOReqSerl>1</WOReqSerl>
 --    <ProgType>1000732007</ProgType>
 --    <WorkType>1000726005</WorkType>
 --    <TABLE_NAME>DataBlock1</TABLE_NAME>
 --  </DataBlock1>
 --</ROOT>',@xmlFlags=2,@ServiceSeq=1006460,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1005954