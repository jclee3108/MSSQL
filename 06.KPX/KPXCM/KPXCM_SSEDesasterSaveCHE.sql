IF OBJECT_ID('KPXCM_SSEDesasterSaveCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEDesasterSaveCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천 
/************************************************************
  설  명 - 데이터-상해관리_capro : 저장
  작성일 - 20110325
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC KPXCM_SSEDesasterSaveCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #KPXCM_TSEDesasterCHE (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEDesasterCHE'
     IF @@ERROR <> 0 RETURN
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TSEDesasterCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TSEDesasterCHE'    , -- 테이블명        
                  '#KPXCM_TSEDesasterCHE'    , -- 임시 테이블명        
                  'AccidentSeq,InjurySeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
     -- -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     --EXEC _SCOMLog  @CompanySeq   ,
     --               @UserSeq      ,
     --               '_TSEDesasterCHE', -- 원테이블명
     --               '#_TSEDesasterCHE', -- 템프테이블명
     --               'AccidentSeq    ,InjurySeq        ' , -- 키가 여러개일 경우는 , 로 연결한다.
     --               'CompanySeq     ,AccidentSeq    ,InjurySeq      ,EmpSeq         ,
     --                InjuryDate     ,InjuryName     ,HappenTime     ,DisasterType   ,RelSftool      ,
     --                OperStatus     ,Weather        ,HappenPlace    ,HappenOpnt     ,
     --                HappenType     ,SimWorkMan     ,InjuryCause    ,InjuryHrm      ,
     --                WorkContent    ,RelsEqm        ,InjuryKind     ,InjuryPart     ,
     --                InjuryCnt      ,CloseDay       ,CureDay        ,NotSftyStatus  ,
     --                NotSftyAct     ,ManageCause    ,ReportDate     ,ReprotUserSeq  ,
     --                surveyFromDate ,surveyToDate   ,surveyUserSeq  ,AccidentOutline,
     --                AccidentCause  ,MngRemark      ,AccidentInjury ,PreventMeasure ,
     --                FileSeq        ,IndAcctSubDate ,IndAcctApprDate,ClosePayReqDate,
     --                ClosePayReqAmt ,DisCompBlDate  ,DisCompBlAmt   ,DisCompGrade   ,
     --                HospitalDay    ,RecuLossAmt    ,IndCloseReAmt  ,ComCloseReAmt  ,
     --                GSAmt          ,DisRewardAmt   ,ReplacementAmt ,ProdLossAmt    ,
     --                LastDateTime   ,LastUserSeq'
      -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TSEDesasterCHE WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
         DELETE A
           FROM KPXCM_TSEDesasterCHE A
                JOIN #KPXCM_TSEDesasterCHE B ON ( A.AccidentSeq      = B.AccidentSeq ) 
                         
            WHERE A.CompanySeq  = @CompanySeq
              AND B.WorkingTag = 'D'
              AND B.Status = 0
           IF @@ERROR <> 0  RETURN
     END
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #KPXCM_TSEDesasterCHE WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
         UPDATE KPXCM_TSEDesasterCHE
            SET EmpSeq         =  B.EmpSeq         ,
                InjuryName     =  B.InjuryName     ,
                InjuryDate     =  B.InjuryDate     ,
                HappenTime     =  B.HappenTime     ,
                DisasterType   =  B.DisasterType   ,
                RelSftool      =  B.RelSftool      ,
                OperStatus     =  B.OperStatus     ,
                Weather        =  B.Weather        ,
                HappenPlaceName =  B.HappenPlaceName    ,
                HappenOpnt     =  B.HappenOpnt     ,
                HappenType     =  B.HappenType     ,
                SimWorkMan     =  B.SimWorkMan     ,
                InjuryCauseName =  B.InjuryCauseName    ,
                InjuryHrmName  =  B.InjuryHrmName      ,
                WorkContent    =  B.WorkContent    ,
                RelsEqm        =  B.RelsEqm        ,
                InjuryKind     =  B.InjuryKind     ,
                InjuryPart     =  B.InjuryPart     ,
                InjuryCnt      =  B.InjuryCnt      ,
                CloseDay       =  B.CloseDay       ,
                CureDay        =  B.CureDay        ,
                NotSftyStatus  =  B.NotSftyStatus  ,
                NotSftyAct     =  B.NotSftyAct     ,
                ManageCause    =  B.ManageCause    ,
                ReportDate     =  B.ReportDate     ,
                ReprotUserSeq  =  B.ReprotUserSeq  ,
                surveyFromDate =  B.surveyFromDate ,
                surveyToDate   =  B.surveyToDate   ,
                surveyUserSeq  =  B.surveyUserSeq  ,
                AccidentOutline=  B.AccidentOutline,
                AccidentCause  =  B.AccidentCause  ,
                MngRemark      =  B.MngRemark      ,
                AccidentInjury =  B.AccidentInjury ,
                PreventMeasure =  B.PreventMeasure ,
                FileSeq        =  B.FileSeq        ,
                IndAcctSubDate =  B.IndAcctSubDate ,
                IndAcctApprDate=  B.IndAcctApprDate,
                ClosePayReqDate=  B.ClosePayReqDate,
                ClosePayReqAmt =  B.ClosePayReqAmt ,
                DisCompBlDate  =  B.DisCompBlDate  ,
                DisCompBlAmt   =  B.DisCompBlAmt   ,
                DisCompGrade   =  B.DisCompGrade   ,
                HospitalDay    =  B.HospitalDay    ,
                RecuLossAmt    =  B.RecuLossAmt    ,
                IndCloseReAmt  =  B.IndCloseReAmt  ,
                ComCloseReAmt  =  B.ComCloseReAmt  ,
                GSAmt          =  B.GSAmt          ,
                DisRewardAmt   =  B.DisRewardAmt   ,
                ReplacementAmt =  B.ReplacementAmt ,
                ProdLossAmt    =  B.ProdLossAmt    ,
                LastDateTime   =  GetDate()        ,
                LastUserSeq    =  @UserSeq   
           FROM KPXCM_TSEDesasterCHE AS A
                JOIN #KPXCM_TSEDesasterCHE AS B ON ( A.AccidentSeq      = B.AccidentSeq ) 
                                               AND ( A.InjurySeq        = B.InjurySeq ) 
                         
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'U'
            AND B.Status = 0
          IF @@ERROR <> 0  RETURN
     END
      -- INSERT
     IF EXISTS (SELECT 1 FROM #KPXCM_TSEDesasterCHE WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
         INSERT INTO KPXCM_TSEDesasterCHE ( CompanySeq     ,AccidentSeq    ,InjurySeq      ,EmpSeq         ,
                                            InjuryDate     ,InjuryName     ,HappenTime     ,DisasterType   ,RelSftool      ,
                                            OperStatus     ,Weather        ,HappenPlaceName, HappenOpnt     ,
                                            HappenType     ,SimWorkMan     ,InjuryCauseName    ,InjuryHrmName      ,
                                            WorkContent    ,RelsEqm        ,InjuryKind     ,InjuryPart     ,
                                            InjuryCnt      ,CloseDay       ,CureDay        ,NotSftyStatus  ,
                                            NotSftyAct     ,ManageCause    ,ReportDate     ,ReprotUserSeq  ,
                                            surveyFromDate ,surveyToDate   ,surveyUserSeq  ,AccidentOutline,
                                            AccidentCause  ,MngRemark      ,AccidentInjury ,PreventMeasure ,
                                            FileSeq        ,IndAcctSubDate ,IndAcctApprDate,ClosePayReqDate,
                                            ClosePayReqAmt ,DisCompBlDate  ,DisCompBlAmt   ,DisCompGrade   ,
                                            HospitalDay    ,RecuLossAmt    ,IndCloseReAmt  ,ComCloseReAmt  ,
                                            GSAmt          ,DisRewardAmt   ,ReplacementAmt ,ProdLossAmt    ,
                                            LastDateTime   ,LastUserSeq       )
                                  SELECT @CompanySeq    ,AccidentSeq    ,InjurySeq      ,EmpSeq         ,
                                         InjuryDate     ,InjuryName     ,HappenTime     ,DisasterType   ,RelSftool      ,
                                         OperStatus     ,Weather        ,HappenPlaceName    ,HappenOpnt     ,
                                         HappenType     ,SimWorkMan     ,InjuryCauseName    ,InjuryHrmName      ,
                                         WorkContent    ,RelsEqm        ,InjuryKind     ,InjuryPart     ,
                                         InjuryCnt      ,CloseDay       ,CureDay        ,NotSftyStatus  ,
                                         NotSftyAct     ,ManageCause    ,ReportDate     ,ReprotUserSeq  ,
                                         surveyFromDate ,surveyToDate   ,surveyUserSeq  ,AccidentOutline,
                                         AccidentCause  ,MngRemark      ,AccidentInjury ,PreventMeasure ,
                                         FileSeq        ,IndAcctSubDate ,IndAcctApprDate,ClosePayReqDate,
                                         ClosePayReqAmt ,DisCompBlDate  ,DisCompBlAmt   ,DisCompGrade   ,
                                         HospitalDay    ,RecuLossAmt    ,IndCloseReAmt  ,ComCloseReAmt  ,
                                         GSAmt          ,DisRewardAmt   ,ReplacementAmt ,ProdLossAmt    ,
                                         GETDATE()      ,@UserSeq     
                                    FROM #KPXCM_TSEDesasterCHE AS A
                                   WHERE A.WorkingTag = 'A'
                                     AND A.Status = 0
          IF @@ERROR <> 0 RETURN
     END
      SELECT * FROM #KPXCM_TSEDesasterCHE
      RETURN
      go
      
      
 begin tran 

exec KPXCM_SSEDesasterSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <AccidentSeq>1</AccidentSeq>
    <InjurySeq>1</InjurySeq>
    <EmpSeq>1000068</EmpSeq>
    <EmpName>A5</EmpName>
    <SMSexName>남자</SMSexName>
    <DeptName>WBS ERP팀</DeptName>
    <PtName>월급직_AB</PtName>
    <AcademicName />
    <EntDate>20120101</EntDate>
    <UMJdName />
    <BirthType />
    <BirthDate />
    <InjuryDate>20151112</InjuryDate>
    <InjuryName>dfdg</InjuryName>
    <HappenTime>111111</HappenTime>
    <DisasterType>0</DisasterType>
    <DisasterTypeName />
    <RelSftool>0</RelSftool>
    <RelSftoolName />
    <OperStatus>0</OperStatus>
    <OperStatusName />
    <Weather>0</Weather>
    <WeatherName />
    <HappenPlaceName>test</HappenPlaceName>
    <HappenOpnt>0</HappenOpnt>
    <HappenOpntName />
    <HappenType>0</HappenType>
    <HappenTypeName />
    <SimWorkMan>0</SimWorkMan>
    <InjuryCauseName>setset</InjuryCauseName>
    <InjuryHrmName>sdfdf</InjuryHrmName>
    <WorkContent>0</WorkContent>
    <WorkContentName />
    <RelsEqm />
    <InjuryKind>0</InjuryKind>
    <InjuryKindName />
    <InjuryPart>0</InjuryPart>
    <InjuryPartName />
    <InjuryCnt>0</InjuryCnt>
    <CloseDay>0</CloseDay>
    <CureDay>0</CureDay>
    <NotSftyStatus>0</NotSftyStatus>
    <NotSftyStatusName />
    <NotSftyAct>0</NotSftyAct>
    <NotSftyActName />
    <ManageCause>0</ManageCause>
    <ManageCauseName />
    <ReportDate xml:space="preserve">        </ReportDate>
    <ReprotUserSeq>0</ReprotUserSeq>
    <ReprotUserName />
    <surveyFromDate xml:space="preserve">        </surveyFromDate>
    <surveyToDate xml:space="preserve">        </surveyToDate>
    <AccidentOutline />
    <AccidentCause />
    <MngRemark />
    <AccidentInjury />
    <PreventMeasure />
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030133,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025159

rollback 