
IF OBJECT_ID('_SGACompHouseCostChargeCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeCheckCHE
GO 

/************************************************************    
 ��  �� - ������-���÷��� : üũ    
 �ۼ��� - 20110315    
 �ۼ��� - õ���    
************************************************************/    
CREATE PROC _SGACompHouseCostChargeCheckCHE    
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
    CREATE TABLE #TGAHouseCostChargeItem (WorkingTag NCHAR(1) NULL)     
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostChargeItem'    
    IF @@ERROR <> 0 RETURN     
    
    
    ----------------------------------------------------    
    -- Ȯ������üũ      
    ----------------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1083                  , -- Ȯ��(����)�� �ڷ�� ����/������ �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%Ȯ��%')      
                          @LanguageSeq       ,       
                          0,''    
    
    UPDATE #TGAHouseCostChargeItem      
       SET Result        = @Results,    
           MessageType   = @MessageType,      
           Status        = @Status    
      FROM #TGAHouseCostChargeItem AS A    
           JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq    
                                                 AND A.CalcYm     = B.CalcYm    
                                                 AND A.HouseClass = B.HouseClass    
                                                 AND B.CfmYn      = '1'    
     WHERE A.Status = 0    
    
    
    ----------------------------------------------------    
    -- ���÷��׸���(���ϼ�����, �Ϲݰ�����) ���� üũ    
    ----------------------------------------------------    
    UPDATE #TGAHouseCostChargeItem    
       SET Result        = LEFT(A.CalcYm, 4) + '�� ' + RIGHT(A.CalcYm, 2) + '�� ���÷��׸��� �����Ͱ� �����ϴ�.',    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #TGAHouseCostChargeItem AS A    
     WHERE NOT EXISTS (SELECT * FROM _TGACompHouseMaster AS S1    
                                     JOIN _TGAHouseCostCalcInfo AS S2 ON S1.CompanySeq = S2.CompanySeq    
                                                                          AND S1.HouseSeq   = S2.HouseSeq    
                               WHERE S1.CompanySeq = @CompanySeq    
                                 AND S1.HouseClass = A.HouseClass    
                                 AND S2.CalcYm     = A.CalcYm)    
       AND A.Status = 0    
    
    
    ----------------------------------------------------    
    -- �հ� ������Ʈ    
    ----------------------------------------------------    
    UPDATE A    
       SET TotalAmt = A.WaterCost + A.GeneralCost + (SELECT SUM(ChargeAmt) FROM #TGAHouseCostChargeItem WHERE CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq)    
      FROM #TGAHouseCostChargeItem AS A    
     WHERE A.Status = 0    
    
    
    SELECT * FROM #TGAHouseCostChargeItem    
    
RETURN    
  