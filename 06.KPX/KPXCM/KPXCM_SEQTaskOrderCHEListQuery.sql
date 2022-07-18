
IF OBJECT_ID('KPXCM_SEQTaskOrderCHEListQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHEListQuery
GO 

-- v2015.06.11 
    
-- 변경기술검토등록조회-조회 by 이재천     
CREATE PROC KPXCM_SEQTaskOrderCHEListQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
    DECLARE @docHandle          INT,    
            -- 조회조건     
            @UMChangeReson2     INT,    
            @BaseDateFr         NCHAR(8),   
            @UMChangeType       INT,   
            @UMTarget           INT,   
            @DeptSeq            INT,   
            @EmpSeq             INT,   
            @BaseDateTo         NCHAR(8),   
            @ChangeRequestNo    NVARCHAR(100),   
            @Title              NVARCHAR(100),   
            @UMChangeReson1     INT,   
            @Plant              INT,   
            @ProgType           INT, 
            @TaskOrderDateFr    NCHAR(8), 
            @TaskOrderDateTo    NCHAR(8), 
            @TaskOrderDeptSeq   INT, 
            @TaskOrderEmpSeq    INT

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @UMChangeReson2     = ISNULL( UMChangeReson2 , 0 ),    
           @BaseDateFr         = ISNULL( BaseDateFr     , '' ),    
           @UMChangeType       = ISNULL( UMChangeType   , 0 ),    
           @UMTarget           = ISNULL( UMTarget       , 0 ),    
           @DeptSeq            = ISNULL( DeptSeq        , 0 ),    
           @EmpSeq             = ISNULL( EmpSeq         , 0 ),    
           @BaseDateTo         = ISNULL( BaseDateTo     , '' ),    
           @ChangeRequestNo    = ISNULL( ChangeRequestNo, '' ),    
           @Title              = ISNULL( Title          , '' ),    
           @UMChangeReson1     = ISNULL( UMChangeReson1 , 0 ),    
           @Plant              = ISNULL( Plant          , 0 ),    
           @ProgType           = ISNULL( ProgType       , 0 ), 
           @TaskOrderDateFr    = ISNULL( TaskOrderDateFr , '' ), 
           @TaskOrderDateTo    = ISNULL( TaskOrderDateTo , '' ),    
           @TaskOrderDeptSeq   = ISNULL( TaskOrderDeptSeq , 0 ), 
           @TaskOrderEmpSeq    = ISNULL( TaskOrderEmpSeq , 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
            UMChangeReson2     INT,    
            BaseDateFr         NCHAR(8),   
            UMChangeType       INT,   
            UMTarget           INT,   
            DeptSeq            INT,   
            EmpSeq             INT,   
            BaseDateTo         NCHAR(8),   
            ChangeRequestNo    NVARCHAR(100),  
            Title              NVARCHAR(100),  
            UMChangeReson1     INT,   
            Plant              INT,   
            ProgType           INT, 
            TaskOrderDateFr    NCHAR(8),
            TaskOrderDateTo    NCHAR(8),            
            TaskOrderDeptSeq   INT,             
            TaskOrderEmpSeq    INT            
           )      
    
    IF @BaseDateTo = '' SELECT @BaseDateTo = '99991231'  
    IF @TaskOrderDateTo = '' SELECT @TaskOrderDateTo = '99991231'  
    
    -- 최종조회     
    SELECT A.ChangeRequestSeq, 
           A.ChangeRequestNo,   
           A.BaseDate,   
           A.DeptSeq,   
           C.DeptName,   
           A.EmpSeq,   
           D.EmpName,   
           B.CfmDate,   
           CASE WHEN ISNULL(B.CfmCode,0) = 0 AND ISNULL(S.IsProg,0) = 0 THEN 1010655001     
                WHEN ISNULL(B.CfmCode,0) = 5 AND ISNULL(S.IsProg,0) = 1 THEN 1010655002     
                WHEN ISNULL(B.CfmCode,0) = 1 THEN 1010655003     
                ELSE 0 END AS TaskOrderProgType,     
           (SELECT TOP 1 MinorName     
              FROM _TDAUMinor     
             WHERE CompanySeq = @CompanySeq     
               AND MinorSeq = (CASE WHEN ISNULL(B.CfmCode,0) = 0 AND ISNULL(S.IsProg,0) = 0 THEN 1010655001     
                                 WHEN ISNULL(B.CfmCode,0) = 5 AND ISNULL(S.IsProg,0) = 1 THEN 1010655002     
                                 WHEN ISNULL(B.CfmCode,0) = 1 THEN 1010655003     
                                 ELSE 0 END    
                              )     
           ) AS TaskOrderProgTypeName,     
           A.Title,   
           A.UMChangeType,   
           E.MinorName AS UMChangeTypeName,   
           A.UMChangeReson1,   
           F.MinorName AS UMChangeResonName1,   
           A.UMChangeReson2,   
           G.MinorName AS UMChangeResonName2,   
           A.UMPlantType AS Plant,   
           H.MinorName AS PlantName,   
           A.Remark,   
           --UMTargetName  
           B.CfmCode AS IsCfm,   
           A.ChangeRequestSeq, 
           Z.TaskOrderDeptSeq, 
           I.DeptName AS TaskOrderDeptName, 
           Z.TaskOrderEmpSeq, 
           J.EmpName AS TaskOrderEmpName, 
           Z.TaskOrderDate, 
           L.CfmDate, 
           Z.TaskOrderSeq 
            
           
   
      FROM KPXCM_TEQTaskOrderCHE AS Z 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE        AS A ON ( A.CompanySeq = @CompanySeq AND A.ChangeRequestSeq = Z.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPXCM_TEQTaskOrderCHE_Confirm     AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = Z.TaskOrderSeq )   
      LEFT OUTER JOIN _TDADept          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq )   
      LEFT OUTER JOIN _TDAEmp           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq )   
      LEFT OUTER JOIN _TCOMGroupWare    AS S ON ( S.CompanySeq = @CompanySeq AND S.WorkKind = 'EQTaskOrder_CM' AND S.TblKey = B.CfmSeq )    
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMChangeType )   
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMChangeReson1 )   
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMChangeReson2 )   
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMPlantType )   
      LEFT OUTER JOIN _TDADept          AS I ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = Z.TaskOrderDeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS J ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = Z.TaskOrderEmpSeq ) 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv        AS K ON ( K.CompanySeq = @CompanySeq AND K.ChangeRequestSeq = A.ChangeRequestSeq ) 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestRecv_Confirm AS L ON ( L.CompanySeq = @CompanySeq AND L.CfmSeq = K.ChangeRequestRecvSeq ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND ( A.BaseDate BETWEEN @BaseDateFr AND @BaseDateTo )   
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq )   
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq )   
       AND ( @UMChangeType = 0 OR A.UMChangeType = @UMChangeType )   
       AND ( @UMChangeReson1 = 0 OR A.UMChangeReson1 = @UMChangeReson1 )   
       AND ( @UMChangeReson2 = 0 OR A.UMChangeReson2 = @UMChangeReson2 )   
       AND ( @Title = '' OR A.Title LIKE @Title + '%' )   
       AND ( @ChangeRequestNo = '' OR A.ChangeRequestNo LIKE @ChangeRequestNo + '%' )   
       AND ( @ProgType = 0 OR CASE WHEN ISNULL(B.CfmCode,0) = 0 AND ISNULL(S.IsProg,0) = 0 THEN 1010655001     
                                   WHEN ISNULL(B.CfmCode,0) = 5 AND ISNULL(S.IsProg,0) = 1 THEN 1010655002     
                                   WHEN ISNULL(B.CfmCode,0) = 1 THEN 1010655003     
                                   ELSE 0 END = @ProgType   
           )  
       AND ( @Plant = 0 OR A.UMPlantType = @Plant ) 
       AND ( Z.TaskOrderDate BETWEEN @TaskOrderDateFr AND @TaskOrderDateTo ) 
       AND ( @TaskOrderDeptSeq = 0 OR Z.TaskOrderDeptSeq = @TaskOrderDeptSeq ) 
       AND ( @TaskOrderEmpSeq = 0 OR Z.TaskOrderEmpSeq = @TaskOrderEmpSeq ) 
    
    RETURN    
GO 

exec KPXCM_SEQTaskOrderCHEListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <Plant>1010356001</Plant>
    <BaseDateFr />
    <TaskOrderDateFr>20150601</TaskOrderDateFr>
    <BaseDateTo />
    <TaskOrderDateTo />
    <ProgType />
    <UMChangeType />
    <ChangeRequestNo />
    <UMChangeReson1 />
    <UMChangeReson2 />
    <DeptSeq />
    <TaskOrderDeptSeq />
    <EmpSeq />
    <TaskOrderEmpSeq />
    <Title />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030235,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025232