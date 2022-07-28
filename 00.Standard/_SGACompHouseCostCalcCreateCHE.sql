
IF OBJECT_ID('_SGACompHouseCostCalcCreateCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcCreateCHE
GO 

/************************************************************  
 ��  �� - ������-���÷����׸�: �Է´�����  
 �ۼ��� - 20110315  
 �ۼ��� - õ���  
************************************************************/  
CREATE PROC dbo._SGACompHouseCostCalcCreateCHE  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT             = 0,  
    @ServiceSeq     INT             = 0,  
    @WorkingTag     NVARCHAR(10)    = '',  
    @CompanySeq     INT             = 1,  
    @LanguageSeq    INT             = 1,  
    @UserSeq        INT             = 0,  
    @PgmSeq         INT             = 0  
AS  
      
    DECLARE @docHandle     INT,  
            @CalcYm        NCHAR(6),  
            @PreYm         NCHAR(6),  
            @HouseClass    INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT @CalcYm     = ISNULL(CalcYm, ''),  
           @HouseClass = ISNULL(HouseClass, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)  
      WITH (CalcYm        NCHAR(6),  
            HouseClass    INT)  
  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1), Status INT, CalcYm NCHAR(6), HouseSeq INT, CostType INT)  
  
  
    IF @WorkingTag <> 'C' -- ���÷��׸񺰰�� ȭ���� �Է´�����  
    BEGIN  
        -- �α� ����� ���� ������ ����  
        INSERT INTO #TGAHouseCostCalcInfo (WorkingTag, Status, CalcYm, HouseSeq)  
        SELECT 'D', 0, @CalcYm, HouseSeq  
          FROM _TGACompHouseMaster  
         WHERE CompanySeq = @CompanySeq  
           AND HouseClass = @HouseClass  
  
  
        -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
        EXEC _SCOMLog  @CompanySeq   ,  
                       @UserSeq      ,    
                       '_TGAHouseCostCalcInfo', -- �����̺��    
                       '#TGAHouseCostCalcInfo', -- �������̺��    
                       'CalcYm,HouseSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.  
                       'CompanySeq,CalcYm,HouseSeq,CheckQty,UseQty,WaterCost,GeneralCost,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
        -- ���� ��ϵ� ������ ����  
        DELETE _TGAHouseCostCalcInfo  
          FROM _TGAHouseCostCalcInfo AS A  
               JOIN #TGAHouseCostCalcInfo AS B ON A.CalcYm   = B.CalcYm  
                                                    AND A.HouseSeq = B.HouseSeq  
  
  
  
        SELECT @PreYm = LEFT(CONVERT(NCHAR(8), DATEADD(mm, -1, @CalcYm + '01'), 112), 6)  
  
  
        SELECT @CalcYm AS CalcYm,  
               A.HouseSeq,  
               (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @COmpanySeq AND MinorSeq = A.HouseClass) AS HouseClassName,  
               A.HouseClass,  
               A.DongName,  
               A.HoName,  
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE NULL END AS EmpName,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpID   ELSE NULL END AS EmpId,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN B.EmpSeq  ELSE NULL END AS EmpSeq,                     
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptName ELSE NULL  END AS DeptName,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptSeq ELSE NULL END AS DeptSeq,   
               --C.EmpName,  
               --C.EmpId,  
               --B.EmpSeq,  
               --C.DeptName,  
               --C.DeptSeq,  
               B.TmpUseYn       AS TmpUseYn,    -- �ӽû��  
               D.CheckQty       AS PreCheckQty, -- ������ħ��  
               A.PrivateSize    AS PrivateSize  -- �������  
          --INTO #RESULT  
          FROM _TGACompHouseMaster AS A WITH(NOLOCK)  
               LEFT OUTER JOIN _TGACompHouseResident AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                           AND A.HouseSeq   = B.HouseSeq  
                             AND B.FinalUseYn = '1' --�������� �ɾ������ 6�����, 6�� �Խ� �� ������ ���� �Ұ��� //2011-11-17 ��������ڷ� ���� - ����ȣ  
               LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS C       ON B.EmpSeq     = C.EmpSeq  
               LEFT OUTER JOIN _TGAHouseCostCalcInfo AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                           AND A.HouseSeq   = D.HouseSeq  
                                                                           AND D.CalcYm     = @PreYm  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND A.UseType <> 1000600003 -- ������ ����(������ ȣ��-�����ڻ��� �������� ����ϱ� ����.)  
           --and (LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm )  
           --and (CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE null END) is not null  
         ORDER BY A.HoName  
           
           
         --SELECT @CalcYm AS CalcYm,  
         --       HouseSeq,  
         --       MAX(HouseClassName) AS HouseClassName,  
         --       MAX(HouseClass) AS HouseClass,  
         --       DongName,  
         --       MAX(HoName) AS HoName,  
         --       MAX(EmpName) AS EmpName,  
         --       MAX(EmpId) AS EmpId,  
         --       MAX(EmpSeq) AS EmpSeq,  
         --       MAX(DeptName) AS DeptName,  
         --       MAX(DeptSeq) AS DeptSeq,  
         --       TmpUseYn,  
         --       PreCheckQty,  
         --       PrivateSize  
         --  FROM #RESULT  
         -- GROUP BY HouseSeq,DongName,TmpUseYn,PreCheckQty,PrivateSize  
         -- ORDER BY HoName  
    END  
  
    ELSE  -- ���÷��� ȭ���� �Է´�����  
    BEGIN  
        -- �α� ����� ���� ������ ����  
        INSERT INTO #TGAHouseCostCalcInfo (WorkingTag, Status, CalcYm, HouseSeq, CostType)  
        SELECT 'D', 0, A.CalcYm, A.HouseSeq, A.CostType  
          FROM _TGAHouseCostChargeItem AS A  
               JOIN _TGACompHouseMaster AS B ON A.CompanySeq = B.CompanySeq  
                                                 AND A.HouseSeq   = B.HouseSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.CalcYm     = @CalcYm  
           AND B.HouseClass = @HouseClass  
  
  
        -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
        EXEC _SCOMLog  @CompanySeq   ,  
                       @UserSeq      ,    
                       '_TGAHouseCostChargeItem', -- �����̺��    
                       '#TGAHouseCostCalcInfo', -- �������̺��  
                       'CalcYm,HouseSeq,CostType' , -- Ű�� �������� ���� , �� �����Ѵ�.  
                       'CompanySeq,CalcYm,HouseSeq,CostType,HouseClass,CfmYn,ChargeAmt,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
        -- ���� ��ϵ� ������ ����  
        DELETE _TGAHouseCostChargeItem  
          FROM _TGAHouseCostChargeItem AS A  
               JOIN #TGAHouseCostCalcInfo AS B ON A.CalcYm   = B.CalcYm  
                                                    AND A.HouseSeq = B.HouseSeq  
  
  
        -- �����÷� �������  
        SELECT IDENTITY(INT, 0, 1) AS ColIDX,  
               B.MinorName AS Title,  
               A.CostType  AS TitleSeq,  
               'enFloat'   AS CellType  
          INTO #Temp_Title  
          FROM _TGACompHouseCostMaster AS A WITH(NOLOCK)  
               LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                           AND A.CostType   = B.MinorSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND A.CalcType <> 1000599001  -- �������� ��������� �ƴ� ��  
         ORDER BY A.OrderNo  
  
  
        -- �����÷� �����ȸ  
        SELECT Title, TitleSeq, CellType  
          FROM #Temp_Title  
         ORDER BY ColIDX  
  
  
        -- �����÷� ����������  
        SELECT IDENTITY(INT, 0, 1) AS RoWIDX,  
               @CalcYm AS CalcYm,  
               A.HouseSeq,  
               E.MinorName AS HouseClassName,  
               A.HouseClass,  
                 A.DongName,  
               A.HoName,  
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE NULL END AS EmpName,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpID   ELSE NULL END AS EmpId,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN B.EmpSeq  ELSE NULL END AS EmpSeq,                     
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptName ELSE NULL  END AS DeptName,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptSeq ELSE NULL END AS DeptSeq,   
               F.EmpName,  
               F.EmpId,  
               D.EmpSeq,  
               G.DeptName,  
               D.DeptSeq,  
               D.GeneralCost,  
               D.WaterCost,  
               CASE WHEN ISNULL(B.LeavingDate, '') <> '99991231' THEN '1' ELSE '0' END AS IsEmpty  
          INTO #Temp_FixData  
          FROM _TGAHouseCostCalcInfo AS D WITH(NOLOCK)  
               LEFT OUTER JOIN _TGACompHouseMaster AS A WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                           AND A.HouseSeq   = D.HouseSeq  
               LEFT OUTER JOIN _TGACompHouseResident AS B WITH(NOLOCK) ON D.CompanySeq = B.CompanySeq  
                                                                           AND D.HouseSeq   = B.HouseSeq  
                                                                           AND D.EmpSeq     = B.EmpSeq  
                                                                           AND B.FinalUseYn = '1'  
               --LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS C       ON B.EmpSeq     = C.EmpSeq  
               LEFT OUTER JOIN _TDAEmp                    AS F WITH(NOLOCK) ON D.CompanySeq = F.CompanySeq  
                                                                           AND D.EmpSeq     = F.EmpSeq  
               LEFT OUTER JOIN _TDADept                   AS G WITH(NOLOCK) ON D.CompanySeq = G.CompanySeq  
                                                                           AND D.DeptSeq    = G.DeptSeq                 
               LEFT OUTER JOIN _TDAUMinor                 AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  
                                                                           AND A.HouseClass = E.MinorSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND D.CalcYm     = @CalcYm  
           AND A.UseType <> 1000600003 -- ������ ����(������ ȣ��-�����ڻ��� �������� ����ϱ� ����.)  
         ORDER BY A.HoName  
          
        -- �����÷� ��ȸ  
         --SELECT IDENTITY(INT, 0, 1) AS RowIDX,  
         --       @CalcYm AS CalcYm,  
         --       HouseSeq,  
         --       MAX(HouseClassName) AS HouseClassName,  
         --       MAX(HouseClass) AS HouseClass,  
         --       DongName,  
         --       MAX(HoName) AS HoName,  
         --       MAX(EmpName) AS EmpName,  
         --       MAX(EmpId) AS EmpId,  
         --       MAX(EmpSeq) AS EmpSeq,  
         --       MAX(DeptName) AS DeptName,  
         --       MAX(DeptSeq) AS DeptSeq,  
         --       GeneralCost,  
         --       WaterCost,  
         --       MAX(IsEmpty) AS IsEmpty  
         --  INTO #Temp_FixData  
         --  FROM #Temp_FixData1  
         -- GROUP BY HouseSeq,DongName,GeneralCost,WaterCost  
         -- ORDER BY HoName          
            
        SELECT * FROM #Temp_FixData ORDER BY RowIDX  
  
  
        -- ���������� ��ȸ  
        SELECT C.RowIDX         AS RowIDX,    
               A.ColIDX         AS ColIDX,    
               B.CalcType,  
               B.FreeApplyYn,  
               CASE WHEN B.CalcType = 1000599002 AND C.IsEmpty = '0'                         THEN B.PackageAmt -- ���Ǿƴϸ� �ϰ��ݾ� ����  
                      WHEN B.CalcType = 1000599002 AND C.IsEmpty = '1'  AND B.FreeApplyYn = '1' THEN B.PackageAmt -- �����̸鼭 �������� üũ�Ǿ� ������ �ϰ��ݾ� ����  
                    ELSE 0 END AS ChargeAmt  
          FROM #Temp_Title AS A  
               JOIN _TGACompHouseCostMaster AS B ON B.CompanySeq = @CompanySeq  
                                                     AND A.TitleSeq   = B.CostType  
               JOIN #Temp_FixData                AS C ON B.HouseClass = C.HouseClass  
                                        
    END  
RETURN  
--GO  
--exec _SGACompHouseCostCalcCreate @xmlDocument=N'<ROOT>  
--  <DataBlock3>  
--    <WorkingTag>A</WorkingTag>  
--    <IDX_NO>1</IDX_NO>  
--    <Status>0</Status>  
--    <DataSeq>1</DataSeq>  
--    <Selected>1</Selected>  
--    <TABLE_NAME>DataBlock3</TABLE_NAME>  
--    <IsChangedMst>0</IsChangedMst>  
--    <HouseClass>1000598001</HouseClass>  
--    <CalcYm>201112</CalcYm>  
--  </DataBlock3>  
  --</ROOT>',@xmlFlags=2,@ServiceSeq=1005473,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1004990