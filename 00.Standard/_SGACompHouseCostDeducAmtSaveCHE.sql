
IF OBJECT_ID('_SGACompHouseCostDeducAmtSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostDeducAmtSaveCHE
GO 

/*********************************************************************************************************************    
    화면명 : 사택료급상여반영 - 반영저장  
    작성일 : 2011.05.13 전경만  
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
  
    -- 사용할 변수를 선언한다.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @BegDate  NCHAR(8),  
            @EndDate  NCHAR(8)  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #GAHouseCost (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#GAHouseCost'       
 IF @@ERROR <> 0 RETURN  
   
 --SELECT *  
 --  FROM #GAHouseCost return  
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
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
  
        --선택된 항목은 무조건 선 삭제 후 입력 로직으로 선택안된건을 찾아서 체크 풀어주기  
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
         
        --선택된 항목은 무조건 선 삭제 후 입력 로직으로.삭제할때는 사원별 개인적으로 삭제가 아닌 통으로 삭제  
        --대신 시작일과 종료일이 맞아야함.  
          
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