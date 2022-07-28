
IF OBJECT_ID('_SEQYearRepairWorkOrderCreateCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairWorkOrderCreateCHE
GO 

-- v2015.07.01 
/************************************************************        
  ��  �� - ������-�������� WO���� : ������ ����        
  �ۼ��� - 20110705        
  �ۼ��� - �����         
         
 ************************************************************/        
 CREATE PROC [dbo].[_SEQYearRepairWorkOrderCreateCHE]        
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT             = 0,        
     @ServiceSeq     INT             = 0,        
     @WorkingTag     NVARCHAR(10)    = '',        
     @CompanySeq     INT             = 1,        
     @LanguageSeq    INT             = 1,        
     @UserSeq        INT             = 0,        
     @PgmSeq         INT             = 0        
 AS        
             
     DECLARE @docHandle      INT,        
             @Results        NVARCHAR(500),        
             @RepairYear     NCHAR(4) ,                  
             @Amd            INT,                      
             @Count          INT,        
             @RltCount       INT,        
             @Seq            INT,        
             @WOMM           INT     -- Work Ordder �ܺι�ȣü�� : �⵵ ���ڸ� (2) + '-' + '13' + Seq(3)        
                     
                     
                     
     CREATE TABLE #_TEQYearRepairMngCHE (WorkingTag NCHAR(1) NULL)          
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQYearRepairMngCHE'          
     IF @@ERROR <> 0 RETURN          
    
     -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)          
     EXEC _SCOMLog  @CompanySeq   ,          
                    @UserSeq      ,          
                    '_TEQYearRepairMngCHE', -- �����̺��          
                    '#_TEQYearRepairMngCHE', -- �������̺��          
                    'ReqSeq'              , -- Ű�� �������� ���� , �� �����Ѵ�.          
                    'CompanySeq,ReqSeq,RepairYear,Amd,ReqDate,FactUnit,SectionSeq,ToolSeq,WorkOperSeq,WorkGubn,WorkContents,ProgType,WONo,        
                     DeptSeq,EmpSeq,LastDateTime,LastUserSeq'        
              
      SELECT @RepairYear  = RepairYear,        
             @Amd         = Amd         
        FROM #_TEQYearRepairMngCHE        
              
      SELECT @WOMM   = RIGHT(@RepairYear,2)         
              
      CREATE TABLE #TMP_WorkOrder (        
                          DatSeq             INT IDENTITY,        
                          RepairYear         INT,        
                          FactUnit           INT,        
                          SectionSeq         INT,        
                          WorkOrderNo        NVARCHAR(8),         
                          )        
                                  
        INSERT INTO #TMP_WorkOrder                  
             SELECT A.RepairYear,     
                    A.FactUnit,        
                    A.SectionSeq,      
                     ''        
               FROM _TEQYearRepairMngCHE    AS A WITH (NOLOCK)    
               LEFT OUTER JOIN _TPDSectionCodeCHE AS b WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                AND A.SectionSeq = B.SectionSeq      
              WHERE 1 = 1        
                AND A.CompanySeq = @CompanySeq           -- KPX  
                AND A.RepairYear = @RepairYear           -- KPX  
                AND A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- ����,����,�Ϸ��û,�Ϸ� -KPX       
             GROUP BY A.RepairYear, A.FactUnit, A.SectionSeq , B.SectionCode   
             ORDER BY A.RepairYear, A.FactUnit, B.SectionCode      
    
    
    -- -- ������ ����       
   SELECT @Count = COUNT(1) FROM #TMP_WorkOrder         
        IF @Count > 0          
      BEGIN         
              
    /*************************************************************************************************************************/              
      -- �ش�⵵ �ش����� �����Ͱ� �����ϸ� W/O ��ȣ �ʱ�ȭ�� ���� �۾� ����          
      -- �������� ������ ����           
  
      IF EXISTS (SELECT  1   
                   FROM _TEQYearRepairMngCHE   
                  WHERE 1 = 1   
                    AND CompanySeq = @CompanySeq   
                    AND RepairYear = @RepairYear   
                    AND ISNULL(WONo,'')<>'')        
         BEGIN        
  -- W/O��ȣ �ʱ�ȭ        
                 UPDATE _TEQYearRepairMngCHE        
                 SET WONo = ''         
                FROM _TEQYearRepairMngCHE         
               WHERE 1 = 1         
                 AND CompanySeq = @CompanySeq          
                 AND RepairYear = @RepairYear     
              
             END    
    
     /*************************************************************************************************************************/              
                 
             -- WO��ȣ ü�� �⵵(2), '12'+  Seq(3) ü��� �����        
             DECLARE @MaxWoNo      NCHAR(10),        
                     @DatMaxNo     NCHAR(5)        
                 
             -- ���ʰ�         
             SELECT @MaxWoNo = '12000'              
                   
             SELECT @DatMaxNo = ISNULL((SELECT RIGHT((MAX(A.WONo)),5)        
                                          FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)        
                                         WHERE 1 = 1        
                                           AND A.CompanySeq  = @CompanySeq        
                                           AND A.RepairYear  = @RepairYear        
                                        ),0)        
                    
             SELECT @MaxWoNo = CASE WHEN @DatMaxNo <>'' THEN @DatMaxNo ELSE @MaxWoNo END        
             -- W/O ��ȣ ����                                        
                   UPDATE #TMP_WorkOrder          
              SET WorkOrderNo = CONVERT(NCHAR(2),@WOMM) + '-' + CONVERT(NCHAR(5),(@MaxWoNo + DatSeq))        
    
    
             -- �������� ���� ���̺� ������Ʈ        
             UPDATE _TEQYearRepairMngCHE        
                SET WONo     = B.WorkOrderNo  
                    --20120726 ����ϰ���� ��û        
                    --ProgType = 1000732006      
               FROM _TEQYearRepairMngCHE AS A JOIN #TMP_WorkOrder AS B        
                                                  ON 1 = 1        
                                                 AND A.CompanySeq = @CompanySeq        
                                                 AND A.RepairYear = B.RepairYear     
                                                 AND A.FactUnit   = B.FactUnit        
                                                 AND A.SectionSeq = B.SectionSeq        
              WHERE 1 = 1         
                AND A.CompanySeq = @CompanySeq        
                AND A.RepairYear = @RepairYear      
                AND A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- ����,����,�Ϸ��û,�Ϸ�   ----KPX        
                                  IF @@ERROR <> 0         
             BEGIN         
                 RETURN          
             END              
                  
             IF @@ERROR <> 0         
             BEGIN         
                 RETURN          
             END              
              
         END           
              
        IF @@ERROR = 0         
        BEGIN          
             SELECT @Results = @RepairYear + '�� W/O��ȣ �ڷ������ �Ϸ��߽��ϴ�..!! '          
                   
             UPDATE #_TEQYearRepairMngCHE              
                SET Result = @Results               
        END                  
           
               
               
    SELECT * FROM #_TEQYearRepairMngCHE        
      
   RETURN        
go
begin tran 
exec _SEQYearRepairWorkOrderCreateCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10362,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=100200
rollback 