
IF OBJECT_ID('KPX_SEQChangeRequestCHEGWQuery') IS NOT NULL 
    DROP PROC KPX_SEQChangeRequestCHEGWQuery
GO 

-- v2014.12.11 

-- 변경의뢰서 GW 조회SP by이재천 
CREATE PROC KPX_SEQChangeRequestCHEGWQuery
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
    
    SELECT  @ChangeRequestSeq    = ISNULL(ChangeRequestSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH  (ChangeRequestSeq INT)       
    
    SELECT A.ChangeRequestSeq,  
           A.ChangeRequestNo,  -- 요청번호 
           A.BaseDate,  -- 요청일자 
           F.WkDeptSeq    ,  
           F.WkDeptName   ,  -- 요청자의 근무부서    
           A.DeptSeq,  
           A.EmpSeq,  
           E.EmpName, -- 요청자 
           F.UMJdSeq       ,
           F.UMJdName      , -- 직책 
           A.Title,  -- 제목
           A.UMChangeType,  
           H.MinorName          AS UMChageTypeName,  -- 변경구분 
           A.UMChangeReson,  
           R.MinorName          AS UMChangeResonName,  -- 변경사유 
           A.UMPlantType,  
           P.MinorName          AS UMPlantTypeName,  -- PLANT구분 
           A.Purpose,  -- 변경목적
           A.Remark,  -- 변경내용 
           A.Effect,  
           
           -- 첨부자료 
           A.ISPID,  -- P&ID
           A.IsInstrument,  -- InstrumentList
           A.IsField,  -- 현장스케치 도면
           A.IsPlot,  -- Plot Plan
           A.IsDange,  -- 위험성평가서
           A.IsConce,  -- Conceptual DWG
           A.IsISO,  -- ISO DWG
           A.IsEquip,  -- Equipment List
           A.Etc,  -- 기타
           A.FileSeq, 
           G.FileName 
      FROM KPX_TEQChangeRequestCHE  AS A  
      LEFT OUTER JOIN _TDADept      AS D ON ( D.CompanySeq = A.CompanySeq AND D.DeptSeq= A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS E ON ( E.CompanySeq = A.CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS H ON ( H.CompanySeq = A.CompanySeq AND H.MinorSeq = A.UMChangeType ) 
      LEFT OUTER JOIN _TDAUMinor    AS R ON ( R.CompanySeq = A.CompanySeq AND R.MinorSeq = A.UMChangeReson ) 
      LEFT OUTER JOIN _TDAUMinor    AS P ON ( P.CompanySeq = A.CompanySeq AND P.MinorSeq = A.UMPlantType ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS F ON ( F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN KPXDEVCommon.dbo._TCAAttachFileData AS G ON ( G.AttachFileSeq = A.FileSeq ) 
      
      
  WHERE A.CompanySeq = @CompanySeq  
    AND A.ChangeRequestSeq = @ChangeRequestSeq  
    RETURN
    





ISPID : P&ID
IsInstrument : InstrumentList
IsField : 현장스케치 도면
IsPlot : Plot Plan
IsDange : 위험성평가서
IsConce : Conceptual DWG
IsISO : ISO DWG
IsEquip : Equipment List
Etc : 기타
