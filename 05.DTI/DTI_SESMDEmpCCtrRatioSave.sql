  
IF OBJECT_ID('DTI_SESMDEmpCCtrRatioSave') IS NOT NULL   
    DROP PROC DTI_SESMDEmpCCtrRatioSave  
GO 
    
-- v2013.06.26   
  
-- 사원별 활동센터 배부율 등록(저장)_DTI by 이재천
CREATE PROC DTI_SESMDEmpCCtrRatioSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0
AS   
    
    CREATE TABLE #DTI_TESMDEmpCCtrRatio (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TESMDEmpCCtrRatio'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('DTI_TESMDEmpCCtrRatio')    
    
    EXEC _SCOMLog @CompanySeq,        
                  @UserSeq,        
                  'DTI_TESMDEmpCCtrRatio'    , -- 테이블명        
                  '#DTI_TESMDEmpCCtrRatio'    , -- 임시 테이블명        
                  'CostYM,EmpSeq,CCtrSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'CostYM,EmpSeqOld,CCtrSeqOld', @PgmSeq  -- 테이블 모든 필드명   
    
    CREATE TABLE #TEMP_DTI_TESMDEmpCCtrRatio
        (
          CostYM    NCHAR(6),
          EmpSeq    INT,
          TotPayAmt DECIMAL(19,5)
        )
    INSERT INTO #TEMP_DTI_TESMDEmpCCtrRatio (CostYM, EmpSeq, TotPayAmt)
    SELECT CostYM, EmpSeq, MAX(A.TotPayAmt) 
      FROM #DTI_TESMDEmpCCtrRatio AS A 
     WHERE A.WorkingTag IN ('A', 'U')
     GROUP BY CostYM, EmpSeq    
     
    -- 작업순서 : DELETE -> UPDATE -> INSERT 
	
    -- DELETE 
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TESMDEmpCCtrRatio WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        
        DELETE B
          FROM #DTI_TESMDEmpCCtrRatio AS A 
          JOIN DTI_TESMDEmpCCtrRatio  AS B ON ( B.CompanySeq = @CompanySeq 
                                            AND B.CostYM = A.CostYM 
                                            AND ((@WorkingTag = 'Delete' AND (B.EmpSeq = A.EmpSeq OR A.EmpSeq = 0))
                                              OR (@WorkingTag <> 'Delete' AND B.EmpSeq = A.EmpSeqOld AND B.CCtrSeq = A.CCtrSeqOld)
                                                )
                                              ) 
                                           --AND (B.CostYM = A.CostYM AND B.CCtrSeq = A.CCtrSeqOld AND @WorkingTag = 'Delete' AND B.EMpSeq = A.EmpSeq ) 
                                           --  OR (@WorkingTag <> 'Delete' AND B.CostYM = A.CostYM AND (A.EmpSeq = 0 OR B.EmpSeq = A.EmpSeq))
                                           --   ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0  RETURN
        
	END  

    -- UPDATE    
	IF EXISTS (SELECT 1 FROM #DTI_TESMDEmpCCtrRatio WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
	    
        UPDATE B
           SET B.CostYM       = A.CostYM,
               B.EmpSeq       = A.EmpSeq,
               B.CCtrSeq      = A.CCtrSeq,
               B.DeptSeq      = A.DeptSeq,
               B.PayAmt       = C.TotPayAmt * A.EmpCnt,
               B.EmpCnt       = A.EmpCnt,
               B.Remark       = A.Remark,
               B.LastUserSeq  = @UserSeq,
               B.LastDateTime = GetDate()
          FROM #DTI_TESMDEmpCCtrRatio AS A 
          JOIN DTI_TESMDEmpCCtrRatio AS B ON ( B.CompanySeq = @CompanySeq AND B.CostYM = A.CostYM AND A.EmpSeqOld = B.EmpSeq AND A.CCtrSeqOld = B.CCtrSeq ) 
          JOIN #TEMP_DTI_TESMDEmpCCtrRatio AS C ON ( B.CostYM = A.CostYM AND B.EmpSeq = A.EmpSeq ) 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    

        IF @@ERROR <> 0  RETURN
        
	END  

	-- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TESMDEmpCCtrRatio WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        
        INSERT INTO DTI_TESMDEmpCCtrRatio 
        (
            CompanySeq, CCtrSeq, PayAmt     , TotPayAmt,  CostYM     , 
            EmpSeq    , DeptSeq, EmpCnt     , Remark    , LastUserSeq , LastDateTime
        ) 
        SELECT @CompanySeq, A.CCtrSeq, A.EmpCnt * B.TotPayAmt , B.TotPayAmt, A.CostYM   , 
               A.EmpSeq   , A.DeptSeq,ISNULL(A.EmpCnt, 0), ISNULL(A.Remark, ''), @UserSeq , GetDate() 
          FROM #DTI_TESMDEmpCCtrRatio AS A 
          JOIN #TEMP_DTI_TESMDEmpCCtrRatio AS B ON ( B.CostYM = A.CostYM AND B.EmpSeq = A.EmpSeq )
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
        
    END   
    
    UPDATE A
       SET A.EmpSeqOld = A.EmpSeq,
           A.CCtrSeqOld = A.CCtrSeq,
           A.PayAmt = B.PayAmt,
           A.TotPayAmt = B.TotPayAmt
      FROM #DTI_TESMDEmpCCtrRatio AS A 
      JOIN DTI_TESMDEmpCCtrRatio  AS B WITH(NOLOCK) ON (B.CompanySeq = @CompanySeq AND A.CostYM = B.CostYM AND A.EmpSeq = B.EmpSeq AND A.CCtrSeq = B.CCtrSeq)
     WHERE A.WorkingTag IN ('A', 'U')
       AND A.Status = 0
    
    SELECT * FROM #DTI_TESMDEmpCCtrRatio
    
    RETURN    
GO
exec DTI_SESMDEmpCCtrRatioSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CostYM>201304</CostYM>
    <CCtrSeq>64</CCtrSeq>
    <DeptSeq>1261</DeptSeq>
    <EmpCnt>0.70000</EmpCnt>
    <EmpSeq>2088</EmpSeq>
    <PayAmt>1600000.00000</PayAmt>
    <Remark />
    <EmpSeqOld>2088</EmpSeqOld>
    <CCtrSeqOld>64</CCtrSeqOld>
    <TotPayAmt>1600000.00000</TotPayAmt>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CostYM>201304</CostYM>
    <CCtrSeq>12</CCtrSeq>
    <DeptSeq>1261</DeptSeq>
    <EmpCnt>0.30000</EmpCnt>
    <EmpSeq>2088</EmpSeq>
    <PayAmt>0.00000</PayAmt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <CCtrSeqOld>0</CCtrSeqOld>
    <TotPayAmt>0.00000</TotPayAmt>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016196,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013924