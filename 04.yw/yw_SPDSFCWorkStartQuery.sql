
IF OBJECT_ID('yw_SPDSFCWorkStartQuery') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartQuery 
GO 

-- v2013.08.01 
  
-- 공정개시입력(현장)_YW (조회) by이재천 
CREATE PROC yw_SPDSFCWorkStartQuery 
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
            @WorkCenterSeq INT,
            @WorkOrderSeq  INT, 
            @WorkOrderSerl INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
            
    SELECT @WorkCenterSeq = ISNULL( WorkCenterSeq, 0 ), 
           @WorkOrderSeq  = ISNULL( WorkOrderSeq, 0 ), 
           @WorkOrderSerl = ISNULL( WorkOrderSerl, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
    
      WITH ( 
            WorkCenterSeq INT,
            WorkOrderSeq  INT, 
            WorkOrderSerl INT
           )

    -- 최종조회 
    SELECT A.EmpSeq, 
           B.EmpName,
           STUFF(STUFF(STUFF(STUFF(A.StartTime,5,0,'-'
                                  ),8,0,'-'
                            ),11,0,' '
                      ),14,0,':'
                ) AS StartTime,
           CASE WHEN A.EndTime = '' THEN '' 
                                    ELSE STUFF(STUFF(STUFF(STUFF(A.EndTime,5,0,'-'
                                                                ),8,0,'-'
                                                          ),11,0,' '
                                                    ),14,0,':'
                                              ) END AS EndTime,
           A.Serl,
           A.EmpSeq AS EmpSeqOld
           
      FROM YW_TPDSFCWorkStart   AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq )
     
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkCenterSeq = @WorkCenterSeq 
       AND A.WorkOrderSeq = @WorkOrderSeq 

UNION ALL

        SELECT A.EmpSeq, 
               D.EmpName,
               '' AS StartTime,
               '' AS EndTime,
               '' AS Serl,
               '' AS EmpSeqOld
          FROM YW_TPDWorkCenterEmp AS A WITH(NOLOCK) 
          JOIN _TPDSFCWorkOrder    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq 
                                                      AND C.WorkCenterSeq = A.WorkCenterSeq 
                                                      AND C.WorkOrderSeq = @WorkOrderSeq 
                                                      AND C.WorkOrderSerl = @WorkOrderSerl 
                                                        )
          LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
          LEFT OUTER JOIN _TDAEmp            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND A.EmpSeq = D.EmpSeq ) 
         
         WHERE A.CompanySeq = @CompanySeq 
           AND NOT EXISTS (SELECT WorkOrderSeq FROM YW_TPDSFCWorkStart WHERE WorkCenterSeq = @WorkCenterSeq)
           AND A.WorkCenterSeq = @WorkCenterSeq 
    
     ORDER BY A.Serl, EmpName 
    
    RETURN  
GO