
IF OBJECT_ID('_SPDToolUserDefineInfoSaveCHE') IS NOT NULL 
    DROP PROC _SPDToolUserDefineInfoSaveCHE
GO 

/************************************************************    
��  �� - ������ ��Ÿ���� ����  
�ۼ��� -   
�ۼ��� -   
************************************************************/    
CREATE PROC dbo._SPDToolUserDefineInfoSaveCHE   
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
    
AS        
    
    
    DECLARE @ProcSeq    INT,    
            @InputDate  NCHAR(8)    
    
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #TPDToolUserDefine (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock5', '#TPDToolUserDefine'         
    IF @@ERROR <> 0 RETURN        
  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDToolUserDefine', -- �����̺�  
          '#TPDToolUserDefine', -- �������̺��  
          'ToolSeq, MngSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.   
          'CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime'  
    
    
    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT    
    
    -- DELETE        
    IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'D' AND Status = 0)      
    BEGIN      
  
        DELETE _TPDToolUserDefine    
          FROM _TPDToolUserDefine   AS A     
            JOIN #TPDToolUserDefine AS B ON A.ToolSeq   = B.ToolSeq    
                                        AND A.MngSerl   = B.MngSerl  
         WHERE B.WorkingTag = 'D'     
           AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq    
        IF @@ERROR <> 0  RETURN    
    
    END      
    
  
    IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'U' AND Status = 0)      
    BEGIN   
--        -- ������ �α׳����  
--        INSERT INTO _TPDToolLog (LogUserSeq,    LogDateTime,    LogType,    CompanySeq,     ToolSeq,        ToolName,   ToolNo,     UMToolKind,  
--                                 Spec,          Capacity,       DeptSeq,    EmpSeq,         BuyDate,        BuyCost,    SMStatus,   CustSeq,  
--                                 Cavity,        DesignShot,     InitialShot,WorkShot,       TotalShot,      AssetSeq,   Remark,     LastUserSeq,      
--                                 LastDateTime,  Uses,           Forms,      SerialNo,       NationSeq,      ManuCompnay,MoldCount,  OrderCustSeq,  
--                                 CustShareRate, ModifyShot,     ModifyDate, DisuseDate,     DisuseCustSeq,  ProdSrtDate,ASTelNo,    FactUnit)  
--  
--        SELECT TOP 1 @UserSeq,  GETDATE(),  WorkingTag, @CompanySeq,    ToolSeq,    '',     '',     0,  
--                     '',        '',         0,          0,              '',         0,      0,      0,  
--                     0,         0,          0,          0,              0,          0,      '',     0,  
--                     0,         '',         '',         '',             0,          '',     0,      0,  
--                     0,         0,          '',         '',             0,          '',     '',     0  
--          FROM #TPDToolUserDefine  
--         WHERE WorkingTag   = 'U'  
  
        -- �����̺� ������Ʈ  
        UPDATE _TPDToolUserDefine    
           SET  MngValText      = B.MngValName               ,  
                MngValSeq       = B.MngValSeq               ,    
                LastUserSeq     = @UserSeq                  ,    
                LastDateTime    = GETDATE()    
          FROM _TPDToolUserDefine   AS A     
            JOIN #TPDToolUserDefine AS B ON A.ToolSeq = B.ToolSeq    
                                        AND A.MngSerl   = B.MngSerl  
         WHERE B.Status = 0        
           AND A.CompanySeq  = @CompanySeq  
           AND B.WorkingTag = 'U'    
        IF @@ERROR <> 0  RETURN    
  
    END  
    
  
  
    
      IF EXISTS (SELECT TOP 1 1 FROM #TPDToolUserDefine WHERE WorkingTag = 'A' AND Status = 0)          BEGIN   
        INSERT INTO _TPDToolUserDefine (CompanySeq,ToolSeq,MngSerl,MngValSeq,MngValText,LastUserSeq,LastDateTime)    
            SELECT  @CompanySeq,  
                    ToolSeq,  
                    MngSerl,  
                    MngValSeq,  
                    MngValName,  
                    @UserSeq,  
                    GETDATE()  
              FROM #TPDToolUserDefine AS A       
             WHERE A.WorkingTag = 'A'  
               AND A.Status = 0        
        IF @@ERROR <> 0 RETURN    
  
  
    END  
    
    SELECT * FROM #TPDToolUserDefine       
    RETURN        
/*******************************************************************************************************************/    