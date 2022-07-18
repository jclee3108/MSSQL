
IF OBJECT_ID('KPXCM_SEQWorkOrderActRltSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkOrderActRltSaveCHE
GO 

-- v2015.07.22 
/************************************************************
��  �� - ������-�۾�����Master : ����(�Ϲ�)
�ۼ��� - 20110518
�ۼ��� - �ſ��
************************************************************/
CREATE PROC KPXCM_SEQWorkOrderActRltSaveCHE
      @xmlDocument    NVARCHAR(MAX),
      @xmlFlags       INT             = 0,
      @ServiceSeq     INT             = 0,
      @WorkingTag     NVARCHAR(10)    = '',
      @CompanySeq     INT             = 1,
      @LanguageSeq    INT             = 1,
      @UserSeq        INT             = 0,
      @PgmSeq         INT             = 0
  AS
       DECLARE @Count         INT,
              @Count1        INT,
              @WOReqSeq      INT,
              @WOReqSerl     INT
      
      CREATE TABLE #_TEQWorkOrderReceiptMasterCHE (WorkingTag NCHAR(1) NULL)
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReceiptMasterCHE'
      IF @@ERROR <> 0 RETURN
    
       -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
      EXEC _SCOMLog  @CompanySeq   ,
                     @UserSeq      ,
                     '_TEQWorkOrderReceiptMasterCHE', -- �����̺���
                     '#_TEQWorkOrderReceiptMasterCHE', -- �������̺���
                     'ReceiptSeq     ' , -- Ű�� �������� ���� , �� �����Ѵ�.
                     'CompanySeq     ,ReceiptSeq     ,ReceiptDate    ,DeptSeq        ,EmpSeq         ,
                      WorkType       ,ProgType       ,ReceiptReason  ,ReceiptNo      ,WorkContents   ,
                      WorkOwner      ,NormalYn       ,ActRltDate     ,CommSeq        ,WkSubSeq       ,
                      LastDateTime   ,LastUserSeq    ,DeptClassSeq '
       -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
       -- DELETE
      IF EXISTS (SELECT TOP 1 1 FROM #_TEQWorkOrderReceiptMasterCHE WHERE WorkingTag = 'D' AND Status = 0)
      BEGIN
          UPDATE _TEQWorkOrderReceiptMasterCHE
             SET ActRltDate     = ''               ,
                 CommSeq        = 0                ,
                 WkSubSeq       = 0                ,
                 DeptClassSeq   = 0                ,
                 ProgType       = 20109003       ,
                 LastDateTime   = GETDATE()        ,
                 LastUserSeq    = @UserSeq 
            FROM _TEQWorkOrderReceiptMasterCHE AS A
                 JOIN #_TEQWorkOrderReceiptMasterCHE AS B ON ( A.ReceiptSeq     = B.ReceiptSeq ) 
           WHERE A.CompanySeq = @CompanySeq
             AND B.WorkingTag = 'D'
             AND B.Status = 0
          
          IF @@ERROR <> 0  RETURN
             
          DELETE _TEQWorkRealResultCHE
            FROM _TEQWorkRealResultCHE A
                 JOIN #_TEQWorkOrderReceiptMasterCHE B ON ( A.ReceiptSeq    = B.ReceiptSeq ) 
          WHERE A.CompanySeq = @CompanySeq
             AND B.WorkingTag = 'D'
             AND B.Status = 0
             
          IF @@ERROR <> 0  RETURN
          
          DELETE _TEQWorkStandardResultCHE
            FROM _TEQWorkStandardResultCHE A
                 JOIN #_TEQWorkOrderReceiptMasterCHE B ON ( A.ReceiptSeq    = B.ReceiptSeq ) 
          WHERE A.CompanySeq = @CompanySeq
             AND B.WorkingTag = 'D'
             AND B.Status = 0
             
          IF @@ERROR <> 0  RETURN
          
          --------------------------------------
          ------- �۾���û �����ڵ� �ݿ� -------
          --------------------------------------
          
          SELECT @WOReqSeq    = B.WOReqSeq  ,    
                 @WOReqSerl   = B.WOReqSerl    
            FROM #_TEQWorkOrderReceiptMasterCHE AS A
                 JOIN _TEQWorkOrderReceiptItemCHE AS B ON A.ReceiptSeq    = B.ReceiptSeq   
           WHERE B.CompanySeq = @CompanySeq 
                 
          SELECT @Count = COUNT(1)
            FROM _TEQWorkOrderReceiptItemCHE AS A
                 JOIN _TEQWorkOrderReceiptMasterCHE AS B WITH (NOLOCK)ON A.ReceiptSeq    = B.ReceiptSeq   
           WHERE A.CompanySeq = @CompanySeq
             AND A.WOReqSeq = @WOReqSeq
             AND A.WOReqSerl = @WOReqSerl
             AND B.ProgType = 20109006
           
        IF @Count = 0 
           
        BEGIN
              
            UPDATE _TEQWorkOrderReqMasterCHE
               SET ProgType    = 20109003
              FROM _TEQWorkOrderReqMasterCHE AS A
             WHERE A.CompanySeq = @CompanySeq
               AND A.WOReqSeq   = @WOReqSeq
                     
            IF @@ERROR <> 0  RETURN
                 
            UPDATE _TEQWorkOrderReqItemCHE
               SET ProgType    = 20109003
              FROM _TEQWorkOrderReqItemCHE AS A
             WHERE A.CompanySeq = @CompanySeq
               AND A.WOReqSeq  = @WOReqSeq
               AND A.WOReqSerl = @WOReqSerl
                 
            IF @@ERROR <> 0  RETURN
        END
        
        
        
        CREATE TABLE #Log 
        (
            WorkingTag  NCHAR(1), 
            IDX_NO      INT, 
            Status      INT, 
            ReceiptSeq  INT, 
            WOReqSeq    INT,  
            WOReqSerl   INT
        )
        INSERT INTO #Log (WorkingTag, IDX_NO, Status, ReceiptSeq, WOReqSeq, WOReqSerl) 
        SELECT A.WorkingTag, A.IDX_NO, A.Status, B.ReceiptSeq, B.WOReqSeq, B.WOReqSerl 
          FROM #_TEQWorkOrderReceiptMasterCHE   AS A 
          JOIN KPXCM_TEQWorkOrderActRltToolInfo AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq ) 
        
        -- �α� �����    
        DECLARE @TableColumns NVARCHAR(4000)    
          
        -- Master �α�   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQWorkOrderActRltToolInfo')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPXCM_TEQWorkOrderActRltToolInfo'    , -- ���̺���        
                      '#Log'    , -- �ӽ� ���̺���        
                      'ReceiptSeq,WOReqSeq,WOReqSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        DELETE B 
          FROM #_TEQWorkOrderReceiptMasterCHE   AS A 
          JOIN KPXCM_TEQWorkOrderActRltToolInfo AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
        
        
    END
       -- UPDATE
      IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReceiptMasterCHE WHERE WorkingTag = 'U' AND Status = 0)
      BEGIN
          UPDATE _TEQWorkOrderReceiptMasterCHE
             SET WorkContents   = A.WorkContents   ,
                 --WorkOwner      = A.WorkOwner      ,
                 --NormalYn       = A.NormalYn       ,
                 ActRltDate     = A.ActRltDate     ,
                 CommSeq        = A.CommSeq        ,
                 WkSubSeq       = A.WkSubSeq       ,
                 ProgType       = 20109006       ,   --��������
                 DeptClassSeq   = A.DeptClassSeq   ,
                 LastDateTime   = GETDATE()        ,
                 LastUserSeq    = @UserSeq 
            FROM #_TEQWorkOrderReceiptMasterCHE AS A
                 JOIN _TEQWorkOrderReceiptMasterCHE AS B ON ( A.ReceiptSeq     = B.ReceiptSeq ) 
           WHERE B.CompanySeq = @CompanySeq
             AND A.WorkingTag = 'U'
             AND A.Status = 0
          
          -- �۾���û Master ���� ����   
          UPDATE _TEQWorkOrderReqMasterCHE
             SET ProgType = 20109006
            FROM #_TEQWorkOrderReceiptMasterCHE AS A
                 JOIN _TEQWorkOrderReceiptItemCHE AS B ON A.ReceiptSeq     = B.ReceiptSeq 
                 JOIN _TEQWorkOrderReqMasterCHE AS C ON B.WOReqSeq = C.WOReqSeq
           WHERE B.CompanySeq = @CompanySeq
             AND A.WorkingTag = 'U'
             AND A.Status = 0      
          
          -- �۾���û Item ���� ����   
          UPDATE _TEQWorkOrderReqItemCHE
             SET ProgType = 20109006
            FROM #_TEQWorkOrderReceiptMasterCHE AS A
                 JOIN _TEQWorkOrderReceiptItemCHE AS B ON A.ReceiptSeq     = B.ReceiptSeq 
                 JOIN _TEQWorkOrderReqItemCHE AS C ON B.WOReqSeq = C.WOReqSeq
                                                    AND B.WOReqSerl = C.WOReqSerl
           WHERE B.CompanySeq = @CompanySeq
             AND A.WorkingTag = 'U'
             AND A.Status = 0      
           IF @@ERROR <> 0  RETURN
      END
       -- INSERT
      IF EXISTS (SELECT 1 FROM #_TEQWorkOrderReceiptMasterCHE WHERE WorkingTag = 'A' AND Status = 0)
      BEGIN
          --INSERT INTO _TEQWorkOrderReceiptMasterCHE ( ReceiptSeq     ,ReceiptDate    ,DeptSeq        ,EmpSeq         ,
          --                 WorkType       ,ProgType       ,ReceiptReason  ,ReceiptNo      ,WorkContents   ,WorkOwner      ,NormalYn       ,
          --                 ActRltDate     ,CommSeq        ,WkSubSeq       )
          --    SELECT ReceiptSeq     ,ReceiptDate    ,DeptSeq        ,EmpSeq         ,
          --           WorkType       ,ProgType       ,ReceiptReason  ,ReceiptNo      ,WorkContents   ,WorkOwner      ,NormalYn       ,
          --           ActRltDate     ,CommSeq        ,WkSubSeq      
          --      FROM #_TEQWorkOrderReceiptMasterCHE AS A
          --     WHERE A.WorkingTag = 'A'
          --       AND A.Status = 0
           IF @@ERROR <> 0 RETURN
      END
       SELECT * FROM #_TEQWorkOrderReceiptMasterCHE
       RETURN
Go
begin tran

exec KPXCM_SEQWorkOrderActRltSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ReceiptSeq>11</ReceiptSeq>
    <WorkContents>asdgasdg</WorkContents>
    <ActRltDate>20150722</ActRltDate>
    <CommSeq>0</CommSeq>
    <WkSubSeq>0</WkSubSeq>
    <DeptClassSeq>0</DeptClassSeq>
    <DeptClassName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031024,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025850

rollback 