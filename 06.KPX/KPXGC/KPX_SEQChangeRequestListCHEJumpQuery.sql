IF OBJECT_ID('KPX_SEQChangeRequestListCHEJumpQuery') IS NOT NULL 
    DROP PROC KPX_SEQChangeRequestListCHEJumpQuery
GO 

-- v2015.01.21 

-- 변경요구등록 -> 변경요구접수등록 점프조회 by이재천 
CREATE PROC KPX_SEQChangeRequestListCHEJumpQuery
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    DECLARE @docHandle          INT, 
            @ChangeRequestSeq   INT 
              
              
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @ChangeRequestSeq = ISNULL(ChangeRequestSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (ChangeRequestSeq INT)  
    
    SELECT A.CompanySeq  
          ,A.ChangeRequestSeq  
          ,A.ChangeRequestNo  
          ,A.BaseDate  
          ,A.DeptSeq  
          ,C.DeptName  
          ,A.EmpSeq  
          ,D.EmpName  
          ,ISNULL(B.CfmDate  ,'') AS CfmDate  
          --,A.ProgType  
          --,ISNULL(E.MinorName  ,'') AS ProgTypeName  
          ,A.Title  
          ,A.UMChangeType  
          ,ISNULL(F.MinorName  ,'') AS UMChangeTypeName  
          ,A.UMChangeReson  
          ,ISNULL(G.MinorName  ,'') AS UMChangeResonName  
          ,A.UMPlantType  
          ,ISNULL(H.MinorName  ,'') AS UMPlantTypeName  
          ,A.Remark  
          ,A.ISPID
          ,A.IsInstrument
          ,A.IsField
          ,A.IsPlot
          ,A.IsDange
          ,A.IsConce
          ,A.IsISO
          ,A.IsEquip
          ,A.Etc
          ,A.FileSeq
          
          ,CASE WHEN ISNULL(J.ChangeRequestRecvSeq,0) = 0 THEN '0' ELSE '1' END AS IsProg  
          ,CASE WHEN ISNULL(B.CfmCode,0) = 1 THEN '1' ELSE '0' END AS IsCfm
          
          --,A.UMTarget  
          --,I.MinorName     AS UMTargetName  
      FROM KPX_TEQChangeRequestCHE                      AS A WITH(NOLOCK)  
      LEFT OUTER JOIN KPX_TEQChangeRequestCHE_Confirm   AS B WITH(NOLOCK)ON A.CompanySeq = B.CompanySeq AND A.ChangeRequestSeq = B.CfmSeq  
      LEFT OUTER JOIN _TDADept                          AS C WITH(NOLOCK)ON A.CompanySeq = C.CompanySeq AND A.DeptSeq = C.DeptSeq  
      LEFT OUTER JOIN _TDAEmp                           AS D WITH(NOLOCK)ON A.CompanySeq = D.CompanySeq AND A.EmpSeq = D.EmpSeq  
      --LEFT OUTER JOIN _TDAUMinor                        AS E WITH(NOLOCK)ON A.CompanySeq = E.CompanySeq AND A.ProgType = E.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor                        AS F WITH(NOLOCK)ON A.CompanySeq = F.CompanySeq AND A.UMChangeType = F.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor                        AS G WITH(NOLOCK)ON A.CompanySeq = G.CompanySeq AND A.UMChangeReson = G.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor                        AS H WITH(NOLOCK)ON A.CompanySeq = H.CompanySeq AND A.UMPlantType = H.MinorSeq  
        --LEFT OUTER JOIN _TDAUMinor                      AS I WITH(NOLOCK)ON A.CompanySeq = I.CompanySeq AND A.UMTarget = I.MinorSeq  
      LEFT OUTER JOIN KPX_TEQChangeRequestRecv          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.ChangeRequestSeq = A.ChangeRequestSeq ) 
     WHERE A.CompanySeq  = @CompanySeq  
       AND (A.ChangeRequestSeq = @ChangeRequestSeq )  
    
    RETURN  
GO 
exec KPX_SEQChangeRequestListCHEJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ChangeRequestSeq>7</ChangeRequestSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026252,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021383