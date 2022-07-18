
IF OBJECT_ID('yw_SPDSFCWorkStartJumpQuery') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartJumpQuery 
GO 

-- v2013.08.01 
  
-- 공정개시입력(현장)_YW (점프조회) by이재천 
CREATE PROC yw_SPDSFCWorkStartJumpQuery 
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
            -- 조회조건 
            @WorkOrderSeq  INT, 
            @WorkOrderSerl INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
    
    SELECT @WorkOrderSeq  = ISNULL( WorkOrderSeq , 0 ), 
           @WorkOrderSerl = ISNULL( WorkOrderSerl, 0 ) 
          
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
    
      WITH ( 
            WorkOrderSeq   INT, 
            WorkOrderSerl  INT 
           ) 
    
    -- 최종조회 
    SELECT A.WorkCenterSeq, 
           A.WorkOrderSerl, 
           B.WorkCenterName, 
           A.WorkOrderSeq, 
           A.WorkOrderNo
      FROM _TPDSFCWorkOrder              AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkOrderSeq = @WorkOrderSeq 
       AND A.WorkOrderSerl = @WorkOrderSerl 
    
    RETURN  
GO 
    