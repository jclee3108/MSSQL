
IF OBJECT_ID('_SGACompHouseCostDeducAmtSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostDeducAmtSaveCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���÷�޻󿩹ݿ� - �ݿ�����  
    �ۼ��� : 2011.05.13 ���游  
********************************************************************************************************************/  
CREATE PROCEDURE _SGACompHouseCostDeducAmtSaveCHE  
    @xmlDocument NVARCHAR(MAX)   ,  
    @xmlFlags    INT = 0         ,  
    @ServiceSeq  INT = 0         ,  
    @WorkingTag  NVARCHAR(10)= '',    
    @CompanySeq  INT = 1         ,  
    @LanguageSeq INT = 1         ,  
    @UserSeq     INT = 0         ,  
    @PgmSeq      INT = 0  
  
AS  
  
    -- ����� ������ �����Ѵ�.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @BegDate  NCHAR(8),  
            @EndDate  NCHAR(8)  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #GAHouseCost (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#GAHouseCost'       
 IF @@ERROR <> 0 RETURN  
   
 --SELECT *  
 --  FROM #GAHouseCost return  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq,  
                   @UserSeq,  
                   '_TPRBasEmpAmt',   
                   '#GAHouseCost',  
                   'EmpSeq, PbSeq   , ItemSeq,Seq',  
                   'CompanySeq, EmpSeq, PbSeq   , ItemSeq,Seq,BegDate,EndDate,Amt,Remark,LastUserSeq,LastDateTime'  
   
 SELECT @BegDate = BegDate FROM #GAHouseCost  
 SELECT @EndDate = EndDate FROM #GAHouseCost  
      
    --DEL  
    IF EXISTS (SELECT 1 FROM #GAHouseCost WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
      
  UPDATE _TGACompHouseCostDeducAmt  
     SET IsPay = '0'  
    FROM _TGACompHouseCostDeducAmt AS A  
      JOIN #GAHouseCost AS B ON B.EmpSeq = A.EmpSeq  
          AND B.HouseSeq = A.HouseSeq  
          AND B.BaseDate = A.CalcYm  
          AND B.PaySeq = A.Seq  
   WHERE B.WorkingTag = 'D'  
     AND B.Status = 0  
     AND A.CompanySeq = @CompanySeq  
        
  DELETE _TPRBasEmpAmt  
    FROM _TPRBasEmpAmt AS A  
      JOIN #GAHouseCost AS B ON A.Seq = B.PaySeq  
          AND A.EmpSeq = B.EmpSeq  
          AND A.PbSeq = B.PbSeq  
          AND A.ItemSeq = B.ItemSeq  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0  
    END  
 /*     
    --SAVE  
    IF EXISTS (SELECT * FROM #GAHouseCost WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
  INSERT INTO _TGACompHouseCostDeducAmt  
    SELECT @CompanySeq, B.EmpSeq, B.HouseSeq, BaseDate, 1,  
     @UserSeq, GETDATE(), B.PaySeq  
      FROM #GAHouseCost AS B   
     WHERE B.WorkingTag = 'A'  
       AND B.Status = 0  
  
  INSERT INTO _TPRBasEmpAmt  
    SELECT @CompanySeq, B.EmpSeq, B.PbSeq, B.ItemSeq, B.PaySeq,  
     B.BegDate, B.EndDate, SUM(B.TotalAmt), '', @UserSeq, GETDATE()  
      FROM #GAHouseCost AS B   
     WHERE B.WorkingTag = 'A'  
       AND B.Status = 0  
     GROUP BY B.EmpSeq, B.PbSeq, B.ItemSeq, B.PaySeq, B.BegDate, B.EndDate  
    END  
    --_TPRBasEmpAmt  
  */    
  
        --���õ� �׸��� ������ �� ���� �� �Է� �������� ���þȵȰ��� ã�Ƽ� üũ Ǯ���ֱ�  
        --UPDATE _TGACompHouseCostDeducAmt  
        DELETE _TGACompHouseCostDeducAmt  
           --SET IsPay = '0', Seq = NULL  
         --select *   
          FROM _TGACompHouseCostDeducAmt AS A  
              JOIN (SELECT C.CompanySeq,C.EmpSeq,C.HouseSeq,C.CalcYm,C.IsPay  
                      FROM _TGACompHouseCostDeducAmt AS C  
                           JOIN #GAHouseCost              AS D ON C.CalcYm = D.BaseDate  
                     GROUP BY C.CompanySeq,C.EmpSeq,C.HouseSeq,C.CalcYm,C.IsPay) AS B on A.CompanySeq = B.CompanySeq  
                                                                                     AND A.EmpSeq     = B.EmpSeq  
                                                                                     AND A.HouseSeq   = B.HouseSeq  
                                 AND A.CalcYm     = B.CalcYm  
         WHERE A.EmpSeq NOT IN (SELECT A.EmpSeq  
                                  FROM _TGACompHouseCostDeducAmt AS A  
                                      JOIN #GAHouseCost              AS B WITH(NOLOCK) ON A.CalcYm     = B.BaseDate  
                                                                                      AND A.HouseSeq   = B.HouseSeq  
                                                                                      AND A.EmpSeq     = B.EmpSeq)  
           
            
  --return   
  INSERT INTO _TGACompHouseCostDeducAmt  
    SELECT @CompanySeq, B.EmpSeq, B.HouseSeq, BaseDate, 1,  
     @UserSeq, GETDATE(), B.Seq  
      FROM #GAHouseCost AS B   
     WHERE B.WorkingTag = 'A'  
       AND B.Status = 0  
         
        --���õ� �׸��� ������ �� ���� �� �Է� ��������.�����Ҷ��� ����� ���������� ������ �ƴ� ������ ����  
        --��� �����ϰ� �������� �¾ƾ���.  
          
        DELETE _TPRBasEmpAmt  
          FROM _TPRBasEmpAmt AS A  
               JOIN #GAHouseCost AS B WITH(NOLOCK) ON @CompanySeq   = A.CompanySeq  
                                                  AND A.PbSeq       = B.PbSeq  
                                                  AND A.ItemSeq     = B.ItemSeq  
                                                  AND A.BegDate     = B.BegDate  
                                                  AND A.EndDate     = B.EndDate  
                                                  --AND A.EmpSeq      = B.EmpSeq  
                                                  --AND A.Seq         = B.PaySeq  
            
  INSERT INTO _TPRBasEmpAmt  
    SELECT @CompanySeq, B.EmpSeq, B.PbSeq, B.ItemSeq, B.Seq,  
     B.BegDate, B.EndDate, SUM(B.TotalAmt), '', @UserSeq, GETDATE()  
      FROM #GAHouseCost AS B   
     WHERE B.WorkingTag IN ('A','U')  
       AND B.Status = 0  
     GROUP BY B.EmpSeq, B.PbSeq, B.ItemSeq, B.Seq, B.BegDate, B.EndDate  
       
    SELECT *  
      FROM #GAHouseCost   
        
RETURN  