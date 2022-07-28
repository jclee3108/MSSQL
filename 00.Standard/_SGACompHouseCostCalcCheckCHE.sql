
IF OBJECT_ID('_SGACompHouseCostCalcCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcCheckCHE
GO 

/************************************************************  
 ��  �� - ������-���÷��׸񺰰�� : üũ  
 �ۼ��� - 20110315  
 �ۼ��� - õ���  
************************************************************/  
CREATE PROC _SGACompHouseCostCalcCheckCHE  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
  
AS  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250)  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostCalcInfo'  
    IF @@ERROR <> 0 RETURN   
  
  
    -------------------------------------------  
    -- Ȯ������üũ    
    -------------------------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1083                  , -- Ȯ��(����)�� �ڷ�� ����/������ �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%Ȯ��%')    
                          @LanguageSeq       ,     
                          0,''  
  
    UPDATE #TGAHouseCostCalcInfo    
       SET Result        = @Results,  
           MessageType   = @MessageType,    
           Status        = @Status  
      FROM #TGAHouseCostCalcInfo AS A  
           JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq  
                                                 AND A.CalcYm     = B.CalcYm  
                                                 AND A.HouseClass = B.HouseClass  
                                                 AND B.CfmYn      = '1'  
     WHERE A.Status = 0  
  
  
    SELECT * FROM #TGAHouseCostCalcInfo  
  
RETURN  