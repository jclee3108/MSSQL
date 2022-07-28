
IF OBJECT_ID('_SEQYearRepairWorkOrderCreateCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairWorkOrderCreateCHE
GO 

-- v2015.07.01 
/************************************************************        
  설  명 - 데이터-년차보수 WO생성 : 데이터 생성        
  작성일 - 20110705        
  작성자 - 김수용         
         
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
             @WOMM           INT     -- Work Ordder 외부번호체계 : 년도 뒷자리 (2) + '-' + '13' + Seq(3)        
                     
                     
                     
     CREATE TABLE #_TEQYearRepairMngCHE (WorkingTag NCHAR(1) NULL)          
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQYearRepairMngCHE'          
     IF @@ERROR <> 0 RETURN          
    
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)          
     EXEC _SCOMLog  @CompanySeq   ,          
                    @UserSeq      ,          
                    '_TEQYearRepairMngCHE', -- 원테이블명          
                    '#_TEQYearRepairMngCHE', -- 템프테이블명          
                    'ReqSeq'              , -- 키가 여러개일 경우는 , 로 연결한다.          
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
                AND A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- 접수,실적,완료요청,완료 -KPX       
             GROUP BY A.RepairYear, A.FactUnit, A.SectionSeq , B.SectionCode   
             ORDER BY A.RepairYear, A.FactUnit, B.SectionCode      
    
    
    -- -- 데이터 생성       
   SELECT @Count = COUNT(1) FROM #TMP_WorkOrder         
        IF @Count > 0          
      BEGIN         
              
    /*************************************************************************************************************************/              
      -- 해당년도 해당차수 데이터가 존재하면 W/O 번호 초기화후 생성 작업 진행          
      -- 실적공수 데이터 삭제           
  
      IF EXISTS (SELECT  1   
                   FROM _TEQYearRepairMngCHE   
                  WHERE 1 = 1   
                    AND CompanySeq = @CompanySeq   
                    AND RepairYear = @RepairYear   
                    AND ISNULL(WONo,'')<>'')        
         BEGIN        
  -- W/O번호 초기화        
                 UPDATE _TEQYearRepairMngCHE        
                 SET WONo = ''         
                FROM _TEQYearRepairMngCHE         
               WHERE 1 = 1         
                 AND CompanySeq = @CompanySeq          
                 AND RepairYear = @RepairYear     
              
             END    
    
     /*************************************************************************************************************************/              
                 
             -- WO번호 체계 년도(2), '12'+  Seq(3) 체계로 만든다        
             DECLARE @MaxWoNo      NCHAR(10),        
                     @DatMaxNo     NCHAR(5)        
                 
             -- 최초값         
             SELECT @MaxWoNo = '12000'              
                   
             SELECT @DatMaxNo = ISNULL((SELECT RIGHT((MAX(A.WONo)),5)        
                                          FROM _TEQYearRepairMngCHE AS A WITH (NOLOCK)        
                                         WHERE 1 = 1        
                                           AND A.CompanySeq  = @CompanySeq        
                                           AND A.RepairYear  = @RepairYear        
                                        ),0)        
                    
             SELECT @MaxWoNo = CASE WHEN @DatMaxNo <>'' THEN @DatMaxNo ELSE @MaxWoNo END        
             -- W/O 번호 생성                                        
                   UPDATE #TMP_WorkOrder          
              SET WorkOrderNo = CONVERT(NCHAR(2),@WOMM) + '-' + CONVERT(NCHAR(5),(@MaxWoNo + DatSeq))        
    
    
             -- 년차보수 관리 테이블에 업데이트        
             UPDATE _TEQYearRepairMngCHE        
                SET WONo     = B.WorkOrderNo  
                    --20120726 김경일과장님 요청        
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
                AND A.ProgType IN (SELECT MinorSeq FROM _TDAUMinorValue where CompanySeq = @CompanySeq AND MajorSeq = 20109 AND Serl = 1000006 AND ValueText = '1')  -- 접수,실적,완료요청,완료   ----KPX        
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
             SELECT @Results = @RepairYear + '년 W/O번호 자료생성을 완료했습니다..!! '          
                   
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