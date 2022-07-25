
IF OBJECT_ID('amoerp_SDACustSubCheck')IS NOT NULL 
    DROP PROC amoerp_SDACustSubCheck 
GO

-- v2013.10.21 

-- �ŷ�ó���(üũ)_amoerp by����õ
CREATE PROC amoerp_SDACustSubCheck
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
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #TDACust (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDACust'

    IF (SELECT SMDomFor FROM #TDACust) = 1013002 
    BEGIN
        UPDATE A
           SET Result = N'�ؿܰŷ�ó���� �ߺ��Ǿ����ϴ�.', 
               Status = 513 
          FROM #TDACust AS A 
         WHERE A.CustName IN (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq)
    END

    SELECT * FROM #TDACust   
     
    RETURN        
GO