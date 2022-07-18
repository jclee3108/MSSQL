  
IF OBJECT_ID('KPX_SEQCheckReportSave') IS NOT NULL   
    DROP PROC KPX_SEQCheckReportSave  
GO  
  
-- v2014.10.31  
  
-- 점검내역등록-저장 by 이재천   
CREATE PROC KPX_SEQCheckReportSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TEQCheckReport (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQCheckReport'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQCheckReport')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEQCheckReport'    , -- 테이블명        
                  '#KPX_TEQCheckReport'    , -- 임시 테이블명        
                  'ToolSeq,CheckDate,UMCheckTerm'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'ToolSeq,CheckDateOld,UMCheckTerm', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckReport WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPX_TEQCheckReport AS A   
          JOIN KPX_TEQCheckReport AS B ON ( B.CompanySeq = @CompanySeq AND A.ToolSeq = B.ToolSeq AND B.CheckDate = A.CheckDateOld AND A.UMCheckTerm = B.UMCheckTerm )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckReport WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.CheckDate = A.CheckDate,  
               B.CheckReport = A.CheckReport, 
               B.Remark = A.Remark, 
               B.Files1 = A.Files1, 
               B.Files2 = A.Files2, 
               B.Files3 = A.Files3, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
          FROM #KPX_TEQCheckReport AS A   
          JOIN KPX_TEQCheckReport AS B ON ( B.CompanySeq = @CompanySeq AND A.ToolSeq = B.ToolSeq AND A.CheckDateOld = B.CheckDate AND A.UMCheckTerm = B.UMCheckTerm )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQCheckReport WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TEQCheckReport  
        (   
            CompanySeq,     ToolSeq,    CheckDate,  UMCheckTerm,    CheckReport, 
            Remark,         Files1,     Files2,     Files3,         LastUserSeq, 
            LastDateTime
        )   
        SELECT @CompanySeq, A.ToolSeq, A.CheckDate, A.UMCheckTerm, 
               CASE WHEN A.SMInputType IN (1027003,1027005) THEN CONVERT(NVARCHAR(100),CheckReportSeq) 
                    WHEN A.SMInputType = 1027007 THEN REPLACE(A.CheckReport,'-','') 
                    WHEN A.SMInputType = 1027002 THEN REPLACE(A.CheckReport,',','') 
               ELSE A.CheckReport 
               END, 
               A.Remark, A.Files1, A.Files2, A.Files3, @UserSeq, 
               getdate() 
          FROM #KPX_TEQCheckReport AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    UPDATE #KPX_TEQCheckReport
       SET CheckDateOld = CheckDate 
      FROM #KPX_TEQCheckReport 
    
    SELECT * FROM #KPX_TEQCheckReport   
    
    RETURN  
GO
begin tran 
exec KPX_SEQCheckReportSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>123</CheckItem>
    <CheckKind>1</CheckKind>
    <CheckReport>@품목용bom</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>test-</ToolName>
    <ToolNo>test-001</ToolNo>
    <ToolSeq>36</ToolSeq>
    <UMCheckTerm>1010201001</UMCheckTerm>
    <UMCheckTermName>일</UMCheckTermName>
    <SMInputType>1027003</SMInputType>
    <CodeHelpConst>18011</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>14477</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>14</CheckItem>
    <CheckKind>2</CheckKind>
    <CheckReport>asdgasdg</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>ㄷㄹㄹㄹ</ToolName>
    <ToolNo>ㅁㅁ</ToolNo>
    <ToolSeq>53</ToolSeq>
    <UMCheckTerm>1010201003</UMCheckTerm>
    <UMCheckTermName>월</UMCheckTermName>
    <SMInputType>1027001</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>0</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem />
    <CheckKind>23</CheckKind>
    <CheckReport>1010202002</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>1231234</ToolName>
    <ToolNo>12341234</ToolNo>
    <ToolSeq>61</ToolSeq>
    <UMCheckTerm>1010201003</UMCheckTerm>
    <UMCheckTermName>월</UMCheckTermName>
    <SMInputType>1027005</SMInputType>
    <CodeHelpConst>19999</CodeHelpConst>
    <CodeHelpParams>1010202</CodeHelpParams>
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>1010202002</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>ㄴㅇㄹ</CheckItem>
    <CheckKind>ㅁㄴㅇㄻㄴㅇㅎ</CheckKind>
    <CheckReport>True</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>이재혁복사저장</ToolName>
    <ToolNo>이재혁복사저장</ToolNo>
    <ToolSeq>62</ToolSeq>
    <UMCheckTerm>1010201001</UMCheckTerm>
    <UMCheckTermName>일</UMCheckTermName>
    <SMInputType>1027006</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>0</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>ㅇㄹㄶ</CheckItem>
    <CheckKind>ㅁㄴㅇㄹㅁㄴㄹ</CheckKind>
    <CheckReport>20121024</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>ㅁㅇㄻㄹㄷㅂㄹ</ToolName>
    <ToolNo>ㅂㄷㄼㅈㄷㄹ</ToolNo>
    <ToolSeq>65</ToolSeq>
    <UMCheckTerm>1010201003</UMCheckTerm>
    <UMCheckTermName>월</UMCheckTermName>
    <SMInputType>1027007</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>0</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>ㅁㄴㅇㄹ</CheckItem>
    <CheckKind>ㅁㄴㅇㅎ</CheckKind>
    <CheckReport />
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>asf</ToolName>
    <ToolNo>asf</ToolNo>
    <ToolSeq>67</ToolSeq>
    <UMCheckTerm>1010201005</UMCheckTerm>
    <UMCheckTermName>반기</UMCheckTermName>
    <SMInputType>1027004</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>0</CheckReportSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <CheckDate xml:space="preserve">        </CheckDate>
    <CheckItem>234</CheckItem>
    <CheckKind>3</CheckKind>
    <CheckReport>123</CheckReport>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <Files1>0</Files1>
    <Files2>0</Files2>
    <Files3>0</Files3>
    <Remark />
    <ToolName>KJH설비</ToolName>
    <ToolNo>KJH설비번호</ToolNo>
    <ToolSeq>70</ToolSeq>
    <UMCheckTerm>1010201003</UMCheckTerm>
    <UMCheckTermName>월</UMCheckTermName>
    <SMInputType>1027002</SMInputType>
    <CodeHelpConst>0</CodeHelpConst>
    <CodeHelpParams />
    <CheckDateOld xml:space="preserve">        </CheckDateOld>
    <CheckReportSeq>0</CheckReportSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025499,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021363

rollback 




--select * 
--update KPX_TEQCheckReport
--   set checkreport = '' 
--  from KPX_TEQCheckReport