
IF OBJECT_ID('_SEQWorkAcceptMSaveCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptMSaveCHE
GO 

/*********************************************************************************************************************  
     화면명 : 작업접수등록(일반) - M저장
     작성일 : 2011.05.03 전경만
 ********************************************************************************************************************/ 
 CREATE PROCEDURE dbo._SEQWorkAcceptMSaveCHE
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS         
     DECLARE @docHandle      INT
     
     CREATE TABLE #WorkOrder (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#WorkOrder'
     IF @@ERROR <> 0 RETURN 
    
   -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq,
                    @UserSeq,
                    '_TEQWorkOrderReceiptMasterCHE', 
                    '#WorkOrder',
                    'ReceiptSeq',
                    'CompanySeq,ReceiptSeq,ReceiptDate,DeptSeq,EmpSeq,
                     WorkType,ProgType,ReceiptReason,ReceiptNo, WorkContents,
                     WorkOwner,NormalYn,ActRltDate,CommSeq,WkSubSeq,
                     LastDateTime, LastUserSeq'
   --DEL
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'D' AND Status = 0)
  BEGIN
   DELETE _TEQWorkOrderReceiptMasterCHE
     FROM #WorkOrder AS A
       JOIN _TEQWorkOrderReceiptMasterCHE AS B ON B.CompanySeq = @CompanySeq
               AND B.ReceiptSeq = A.ReceiptSeq
    WHERE A.WorkingTag = 'D'
      AND A.Status = 0
      AND B.CompanySeq = @CompanySeq
  END
  
  --UPDATE
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'U' AND Status = 0)
  BEGIN
   UPDATE _TEQWorkOrderReceiptMasterCHE
      SET ReceiptDate     = A.ReceiptDate,
       DeptSeq      = A.DeptSeq,
       EmpSeq      = A.EmpSeq,
       WorkType      = A.WorkType,
       ProgType      = A.ProgType,
       ReceiptReason = A.ReceiptReason,
 --      WorkSubSeq  = A.WorkSubSeq,
       WorkContents  = A.WorkContents,
       WorkOwner  = A.WorkOwner,
       NormalYn   = A.NormalYn,
       LastUserSeq = @UserSeq,
       LastDateTime = GETDATE(), 
       FileSeq = A.FileSeqSub
     FROM #WorkOrder AS A
       JOIN _TEQWorkOrderReceiptMasterCHE AS B ON B.CompanySeq = @CompanySeq
               AND B.ReceiptSeq = A.ReceiptSeq
    WHERE B.CompanySeq = @CompanySeq
      AND A.WorkingTag = 'U'
      AND A.Status = 0
  END
  
  --SAVE
  IF EXISTS (SELECT 1 FROM #WorkOrder WHERE WorkingTag = 'A' AND Status = 0)
  BEGIN
   INSERT INTO _TEQWorkOrderReceiptMasterCHE 
   (
       CompanySeq      ,
             ReceiptSeq      ,
             ReceiptDate     ,
             DeptSeq         ,
             EmpSeq          ,
             WorkType        ,
             ProgType        ,
             ReceiptReason   ,
             ReceiptNo       ,
             WorkContents    ,
             WorkOwner       ,
             NormalYn        ,
             ActRltDate      ,
             CommSeq         ,
             WkSubSeq        ,
             LastDateTime    ,
             LastUserSeq     , 
             FileSeq
         )                                       
     SELECT @CompanySeq, ReceiptSeq, ReceiptDate, DeptSeq, EmpSeq,
      WorkType,  ProgType, ReceiptReason, ReceiptNo, WorkContents,
      WorkOwner,     NormalYn,    '',             0,          0,
      GETDATE(),  @UserSeq, FileSeqSub
       FROM #WorkOrder
      WHERE WorkingTag = 'A'
        AND Status = 0
  END
   SELECT * FROM #WorkOrder
 RETURN
GO

begin tran 
exec _SEQWorkAcceptMSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ReceiptSeq>16</ReceiptSeq>
    <ReceiptDate>20150303</ReceiptDate>
    <DeptName>HYW_서비스팀3</DeptName>
    <DeptSeq>96</DeptSeq>
    <EmpName>parkey</EmpName>
    <EmpSeq>2334</EmpSeq>
    <WorkTypeName>일반정비작업</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ProgTypeName>접수</ProgTypeName>
    <ProgType>20109003</ProgType>
    <ReceiptReason />
    <ReceiptNo>201503030001</ReceiptNo>
    <WorkContents>ㅅㄷㄴㅅ</WorkContents>
    <WONo>15-G-00005</WONo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150
rollback 