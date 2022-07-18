
IF OBJECT_ID('KPX_SEQChangeFinalReportGWQuery') IS NOT NULL 
    DROP PROC KPX_SEQChangeFinalReportGWQuery
GO 

-- v2014.12.11 

-- 변경작업수행결과 GW 조회SP by이재천 
 CREATE PROC KPX_SEQChangeFinalReportGWQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle          INT,
            @ChangeRequestSeq   INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    
    SELECT  @ChangeRequestSeq = ISNULL(ChangeRequestSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (ChangeRequestSeq      INT )
    
    SELECT A.CompanySeq
          ,A.ChangeRequestSeq 
          ,A.ChangeRequestNo -- 요청번호 
          ,A.BaseDate -- 요청일자 
          ,A.DeptSeq 
          ,A.EmpSeq
          ,A.Title -- 변경제목 
          ,A.Purpose -- 변경목적 
          ,A.Effect
          ,A.Remark -- 변경내용 
          ,B.FinalReportSeq 
          ,B.ReportDate -- 공사완료일 
          ,B.FileSeq -- 첨부파일 
          ,G.FileName  
          
          
          ,B.ISPID  -- P&ID
          ,B.IsInstrument  -- InstrumentList 
          ,B.IsField  -- 현장스케치 도면
          ,B.IsPlot  -- Plot Plan
          ,B.IsDange  -- 위험성평가서
          ,B.IsConce  -- Conceptual DWG
          ,B.IsISO  -- ISO DWG
          ,B.IsEquip  -- Equipment List
          ,B.Etc  -- 기타 
          ,B.IsTaskOrder  -- 기술검토서 
          
      FROM KPX_TEQChangeRequestCHE              AS A
      LEFT OUTER JOIN KPX_TEQChangeFinalReport  AS B ON ( B.CompanySeq = @CompanySeq AND A.ChangeRequestSeq = B.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPXDEVCommon.dbo._TCAAttachFileData AS G ON ( G.AttachFileSeq = B.FileSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ChangeRequestSeq = @ChangeRequestSeq
    
    RETURN
    
    
    








