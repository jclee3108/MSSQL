  
IF OBJECT_ID('yw_SPDSFCWorkLossQuery') IS NOT NULL   
    DROP PROC yw_SPDSFCWorkLossQuery  
GO  
  
-- v2013.08.23 
  
-- 유실공수입력(현장)_YW(조회) by이재천   
CREATE PROC yw_SPDSFCWorkLossQuery  
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
            @WorkDate       NVARCHAR(8), 
            @WorkCenterSeq  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkDate      = ISNULL( WorkDate, '' ),  
           @WorkCenterSeq = ISNULL( WorkCenterSeq, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkDate        NVARCHAR(8),  
            WorkCenterSeq   INT 
           )    
      
    -- 최종조회   
    SELECT A.UMLossSeq, 
           A.Serl, 
           CASE WHEN A.StartTime = '' THEN '' ELSE STUFF(STUFF(STUFF(STUFF(A.StartTime,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') END AS StartTime, 
           CASE WHEN A.EndTime = '' THEN '' ELSE STUFF(STUFF(STUFF(STUFF(A.EndTime,5,0,'-'),8,0,'-'),11,0,' '),14,0,':') END AS EndTime,
           A.Remark, 
           B.MinorName AS UMLossName,
           CASE WHEN 0 < SUM(CASE WHEN A.EndTime = '' 
                                  THEN 0
                                  ELSE ISNULL(DateDiff(Second, STUFF(STUFF(STUFF(STUFF(CASE WHEN A.StartTime > C.StartTime 
                                                                                            THEN A.StartTime 
                                                                                            ELSE C.StartTime 
                                                                                            END,5,0,'-'
                                                                                      ),8,0,'-'
                                                                                ),11,0,' '
                                                                          ),14,0,':'
                                                                    ) + ':00.000',
                                                               STUFF(STUFF(STUFF(STUFF(CASE WHEN A.StartTime > (CASE WHEN A.EndTime > C.EndTime 
                                                                                                                     THEN C.EndTime 
                                                                                                                     ELSE A.EndTime 
                                                                                                                     END
                                                                                                               ) 
                                                                                            THEN A.StartTime 
                                                                                            ELSE (CASE WHEN A.EndTime > C.EndTime 
                                                                                                       THEN C.EndTime 
                                                                                                       ELSE A.EndTime 
                                                                                                       END
                                                                                                 ) 
                                                                                            END,5,0,'-'
                                                                                      ),8,0,'-'
                                                                                ),11,0,' '
                                                                          ),14,0,':'
                                                                    ) + ':00.000'
                                                      ),0
                                             ) 
                                  END 
                            )
           THEN SUM(CASE WHEN A.EndTime = '' 
                         THEN 0
                         ELSE ISNULL(DateDiff(Second, STUFF(STUFF(STUFF(STUFF(CASE WHEN A.StartTime > C.StartTime 
                                                                                   THEN A.StartTime 
                                                                                   ELSE C.StartTime 
                                                                                   END,5,0,'-'
                                                                             ),8,0,'-'
                                                                       ),11,0,' '
                                                                 ),14,0,':'
                                                           ) + ':00.000',
                                                      STUFF(STUFF(STUFF(STUFF(CASE WHEN A.StartTime > (CASE WHEN A.EndTime > C.EndTime 
                                                                                                            THEN C.EndTime 
                                                                                                            ELSE A.EndTime 
                                                                                                            END
                                                                                                      ) 
                                                                                   THEN A.StartTime 
                                                                                   ELSE (CASE WHEN A.EndTime > C.EndTime 
                                                                                              THEN C.EndTime 
                                                                                              ELSE A.EndTime 
                                                                                              END
                                                                                        ) 
                                                                                   END,5,0,'-'
                                                                             ),8,0,'-'
                                                                       ),11,0,' '
                                                                 ),14,0,':'
                                                           ) + ':00.000'
                                             ),0
                                    ) 
                         END 
                   ) 
           ELSE 0 
           END AS LossTime
           
      FROM YW_TPDSFCWorkLoss AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMLossSeq ) 
      LEFT OUTER JOIN YW_TPDSFCWorkStart AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkCenterSeq = A.WorkCenterSeq AND LEFT(C.StartTime,8) = A.WorkDate )
     WHERE A.CompanySeq = @CompanySeq  
       AND @WorkDate = A.WorkDate 
       AND @WorkCenterSeq = A.WorkCenterSeq 

     GROUP BY A.WorkCenterSeq, A.WorkDate, A.UMLossSeq, A.Serl, A.StartTime,
              A.EndTime, A.Remark, B.MinorName

     ORDER BY A.Serl 
    
    RETURN  
GO
exec yw_SPDSFCWorkLossQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkCenterSeq>1000017</WorkCenterSeq>
    <WorkDate>20130823</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017273,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014775