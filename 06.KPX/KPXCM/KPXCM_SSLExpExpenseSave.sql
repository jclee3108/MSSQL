IF OBJECT_ID('KPXCM_SSLExpExpenseSave') IS NOT NULL 
    DROP PROC KPXCM_SSLExpExpenseSave
GO 

-- v2015.09.30 

-- 물품대상세 추가 by이재천 
/*********************************************************************************************************************
     화면명 : 수출비용_마스터저장
     SP Name: _SSLExpExpenseSave
     작성일 : 2009. 3 : CREATEd by 김준모
     수정일 : 
 ********************************************************************************************************************/
 CREATE PROCEDURE KPXCM_SSLExpExpenseSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '', 
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
     DECLARE @docHandle  INT, 
             @ExpenseSeq INT, 
             @count      INT, 
             @BizUnit    INT, 
             @CurrDate   NCHAR(8)
      -- 서비스 마스타 등록 생성  
     CREATE TABLE #TSLExpExpense (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLExpExpense' 
    
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLExpExpense', -- 원테이블명
                    '#TSLExpExpense', -- 템프테이블명
                    'ExpenseSeq' , -- 키가 여러개일 경우는 , 로 연결한다. 
                    'CompanySeq,ExpenseSeq,BizUnit,ExpenseDate,SMImpOrExp,SMExpKind,SMSourceType,SourceSeq,CustSeq,DeptSeq,EmpSeq,Remark,LastUserSeq,LastDateTime'
  
     -- DELETE
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLExpExpense  
           FROM _TSLExpExpense AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
  
         DELETE _TSLExpExpenseDesc
           FROM _TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
          
         DELETE KPXCM_TSLExpExpenseDesc
           FROM KPXCM_TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'D' 
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
     END
      -- UPDATE                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLExpExpense   
            SET BizUnit  = B.BizUnit,
                ExpenseDate  = B.ExpenseDate,
                SMExpKind    = B.SMExpKind,
                SMSourceType = B.SMSourceType,
                SourceSeq    = B.SourceSeq,
                CustSeq      = B.CustSeq,
                DeptSeq      = B.DeptSeq,
                EmpSeq       = B.EmpSeq,
                Remark       = B.Remark,
                LastUserSeq  = @UserSeq,
                LastDateTime = GETDATE()
           FROM _TSLExpExpense AS A
                  JOIN #TSLExpExpense AS B ON A.CompanySeq = @CompanySeq 
                                          AND A.ExpenseSeq = B.ExpenseSeq
          WHERE B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0 RETURN 
     END 
      -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpense WHERE WorkingTag = 'A' AND Status = 0 )  
     BEGIN  
          -- 서비스 INSERT  
         INSERT INTO _TSLExpExpense 
                    (CompanySeq,  ExpenseSeq,  BizUnit,     ExpenseDate, SMExpKind,
                     SMSourceType,SourceSeq,   CustSeq,     DeptSeq,     EmpSeq,
                     Remark,      SMImpOrExp,  LastUserSeq, LastDateTime)        
          SELECT  @CompanySeq, ExpenseSeq,  BizUnit,     ExpenseDate, SMExpKind,
                     SMSourceType,SourceSeq,   CustSeq,     DeptSeq,     EmpSeq,
                     Remark,      SMImpOrExp,  @UserSeq,    GETDATE()   
        FROM #TSLExpExpense  
              WHERE WorkingTag = 'A' AND Status = 0  
          IF @@ERROR  <> 0 RETURN 
     END
     
     SELECT * FROM #TSLExpExpense 
   
 RETURN
 go
 begin tran 
 exec KPXCM_SSLExpExpenseSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ExpenseSeq>99</ExpenseSeq>
    <BizUnitName>PPG사업부</BizUnitName>
    <BizUnit>1</BizUnit>
    <ExpenseDate>20150930</ExpenseDate>
    <SMExpKindName>직수입</SMExpKindName>
    <SMExpKind>8008004</SMExpKind>
    <SMSourceTypeName>수입Payment</SMSourceTypeName>
    <SMSourceType>8215002</SMSourceType>
    <SourceSeq>135</SourceSeq>
    <CustName>（관）청솔 울산사무소</CustName>
    <CustSeq>4981</CustSeq>
    <DeptName>J 프로젝트팀</DeptName>
    <DeptSeq>142</DeptSeq>
    <EmpName>영림원</EmpName>
    <EmpSeq>1</EmpSeq>
    <Remark />
    <SMImpOrExp>8212002</SMImpOrExp>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031958,@WorkingTag=N'D',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=5070
rollback 