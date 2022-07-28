  
IF OBJECT_ID('_SDAUMToolKindDetailToolListResetCHE') IS NOT NULL   
    DROP PROC _SDAUMToolKindDetailToolListResetCHE  
GO  
  
-- v2015.0605 
  
-- 설비유형/제원항목등록 데이터-설비항목정렬 by 이재천
CREATE PROC _SDAUMToolKindDetailToolListResetCHE  
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
      
    CREATE TABLE #Tool( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Tool'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #Temp 
    (
        Cnt             INT, 
        TitleSerl       INT, 
        DefineUnitSeq    INT, 
        IDX_NO          INT, 
    )
    INSERT INTO #Temp( Cnt, TitleSerl, DefineUnitSeq, IDX_NO )
    SELECT ROW_NUMBER() OVER(ORDER BY A.QrySort) AS Cnt , A.TitleSerl, A.DefineUnitSeq, A.IDX_NO
      FROM #Tool AS A 
    
    UPDATE B 
       SET TitleSerl = A.Cnt 
      FROM #Temp AS A 
      LEFT OUTER JOIN _TCOMUserDefine AS B ON ( B.CompanySeq = @CompanySeq 
                                            AND B.TableName = '_TDAUMajor_6009' 
                                            AND B.DefineUnitSeq = A.DefineUnitSeq 
                                            AND B.TitleSerl = A.TitleSerl 
                                             ) 
                                             
    UPDATE A 
       SET TitleSerl = B.Cnt 
      FROM #Tool AS A 
      LEFT OUTER JOIN #Temp AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    --select * from _TCOMUserDefine where DefineUnitSeq = 6009001 
    SELECT * FROM #Tool    
    
    RETURN  
GO 
begin tran 
EXEC _SDAUMToolKindDetailToolListResetCHE @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QrySort>1</QrySort>
    <Title>test</Title>
    <DataFieldID />
    <IsEss>0</IsEss>
    <SMInputTypeName />
    <CodeHelpConstName />
    <CodeHelpParams />
    <MaskAndCaption />
    <IsCodeHelpTitle>0</IsCodeHelpTitle>
    <SMInputType>0</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <TitleSerl>1</TitleSerl>
    <TableName>_TDAUMajor_6009</TableName>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <DefineUnitSeq>6009001</DefineUnitSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QrySort>2</QrySort>
    <Title>test3</Title>
    <DataFieldID />
    <IsEss>0</IsEss>
    <SMInputTypeName />
    <CodeHelpConstName />
    <CodeHelpParams />
    <MaskAndCaption />
    <IsCodeHelpTitle>0</IsCodeHelpTitle>
    <SMInputType>0</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <TitleSerl>3</TitleSerl>
    <TableName>_TDAUMajor_6009</TableName>
    <DefineUnitSeq>6009001</DefineUnitSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <QrySort>3</QrySort>
    <Title>teest2</Title>
    <DataFieldID />
    <IsEss>0</IsEss>
    <SMInputTypeName />
    <CodeHelpConstName />
    <CodeHelpParams />
    <MaskAndCaption />
    <IsCodeHelpTitle>0</IsCodeHelpTitle>
    <SMInputType>0</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <TitleSerl>4</TitleSerl>
    <TableName>_TDAUMajor_6009</TableName>
    <DefineUnitSeq>6009001</DefineUnitSeq>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 9947, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1000204, @PgmSeq = 100099




rollback 