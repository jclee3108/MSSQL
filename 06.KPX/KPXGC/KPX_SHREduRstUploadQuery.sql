  
IF OBJECT_ID('KPX_SHREduRstUploadQuery') IS NOT NULL   
    DROP PROC KPX_SHREduRstUploadQuery  
GO  
  
-- v2014.11.19  
  
-- 교육결과Upload-조회 by 이재천   
CREATE PROC KPX_SHREduRstUploadQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #THREduPersRst (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREduPersRst'         
    IF @@ERROR <> 0 RETURN     

    SELECT REPLACE(EduBegDate,'-','') AS EduBegDate, 
           REPLACE(EduEndDate,'-','') AS EduEndDate, 
           *
      FROM #THREduPersRst AS A 
    
    RETURN  
    
GO 
exec KPX_SHREduRstUploadQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <No>1</No>
    <EmpName>김승권         </EmpName>
    <DeptName>영업관리팀</DeptName>
    <EduCourseName>마케팅관리 통합</EduCourseName>
    <EduBegDate>2014-11-12</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>9</ComplateTime>
    <ProgRate>100</ProgRate>
    <ProgPoint>0</ProgPoint>
    <HWPoint>0</HWPoint>
    <TestPoint>0</TestPoint>
    <MeetPoint>0</MeetPoint>
    <ComplatePoint>0</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>50</ComplateStdPoint>
    <EduAmt>10000</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>2</No>
    <EmpName>김승철</EmpName>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>마케팅포지셔닝전략</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>5</ComplateTime>
    <ProgRate>71</ProgRate>
    <ProgPoint>1</ProgPoint>
    <HWPoint>1</HWPoint>
    <TestPoint>1</TestPoint>
    <MeetPoint>1</MeetPoint>
    <ComplatePoint>1</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>51</ComplateStdPoint>
    <EduAmt>10001</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>3</No>
    <EmpName>조봉신         </EmpName>
    <DeptName>기술연구소</DeptName>
    <EduCourseName>매출채권관리실무</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>1</ComplateTime>
    <ProgRate>56.25</ProgRate>
    <ProgPoint>2</ProgPoint>
    <HWPoint>2</HWPoint>
    <TestPoint>2</TestPoint>
    <MeetPoint>2</MeetPoint>
    <ComplatePoint>2</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>52</ComplateStdPoint>
    <EduAmt>10002</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>4</No>
    <EmpName>유구매</EmpName>
    <DeptName>생산4팀</DeptName>
    <EduCourseName>매출채권관리업무</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>3</ComplateTime>
    <ProgRate>30</ProgRate>
    <ProgPoint>3</ProgPoint>
    <HWPoint>3</HWPoint>
    <TestPoint>3</TestPoint>
    <MeetPoint>3</MeetPoint>
    <ComplatePoint>3</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>53</ComplateStdPoint>
    <EduAmt>10003</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>5</No>
    <EmpName>조현           </EmpName>
    <DeptName>생산관리팀</DeptName>
    <EduCourseName>문제해결과 의사결정</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>50</ProgRate>
    <ProgPoint>4</ProgPoint>
    <HWPoint>4</HWPoint>
    <TestPoint>4</TestPoint>
    <MeetPoint>4</MeetPoint>
    <ComplatePoint>4</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>54</ComplateStdPoint>
    <EduAmt>10004</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>6</No>
    <EmpName>Kimyoungmi</EmpName>
    <DeptName>솔루션영업1팀(test)</DeptName>
    <EduCourseName>물류 양성자 과정_AB</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>5</ComplateTime>
    <ProgRate>10</ProgRate>
    <ProgPoint>5</ProgPoint>
    <HWPoint>5</HWPoint>
    <TestPoint>5</TestPoint>
    <MeetPoint>5</MeetPoint>
    <ComplatePoint>5</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>55</ComplateStdPoint>
    <EduAmt>10005</EduAmt>
    <ReturnAmt>1112</ReturnAmt>
    <FrtReturnAmt>1112</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>7</No>
    <EmpName>이경옥         </EmpName>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>법인세 신고실무</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>2</ComplateTime>
    <ProgRate>10.5</ProgRate>
    <ProgPoint>6</ProgPoint>
    <HWPoint>6</HWPoint>
    <TestPoint>6</TestPoint>
    <MeetPoint>6</MeetPoint>
    <ComplatePoint>6</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>56</ComplateStdPoint>
    <EduAmt>10006</EduAmt>
    <ReturnAmt>35153</ReturnAmt>
    <FrtReturnAmt>35153</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>8</No>
    <EmpName>유명순         </EmpName>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>비즈니스예절교육</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>3</ComplateTime>
    <ProgRate>93.91</ProgRate>
    <ProgPoint>7</ProgPoint>
    <HWPoint>7</HWPoint>
    <TestPoint>7</TestPoint>
    <MeetPoint>7</MeetPoint>
    <ComplatePoint>7</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>57</ComplateStdPoint>
    <EduAmt>10007</EduAmt>
    <ReturnAmt>513</ReturnAmt>
    <FrtReturnAmt>513</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>9</No>
    <EmpName>천재영         </EmpName>
    <DeptName>국내영업1팀</DeptName>
    <EduCourseName>상담면담기법향상실무</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>210</ComplateTime>
    <ProgRate>100</ProgRate>
    <ProgPoint>8</ProgPoint>
    <HWPoint>8</HWPoint>
    <TestPoint>8</TestPoint>
    <MeetPoint>8</MeetPoint>
    <ComplatePoint>8</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>58</ComplateStdPoint>
    <EduAmt>10008</EduAmt>
    <ReturnAmt>213</ReturnAmt>
    <FrtReturnAmt>213</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>10</No>
    <EmpName>오종환         </EmpName>
    <DeptName>기술연구소</DeptName>
    <EduCourseName>생산 양성자 과정_AB</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>513</ComplateTime>
    <ProgRate>75</ProgRate>
    <ProgPoint>9</ProgPoint>
    <HWPoint>9</HWPoint>
    <TestPoint>9</TestPoint>
    <MeetPoint>9</MeetPoint>
    <ComplatePoint>9</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>59</ComplateStdPoint>
    <EduAmt>10009</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>11</No>
    <EmpName>박강효         </EmpName>
    <DeptName>생산1팀(안산_2)</DeptName>
    <EduCourseName>생산계획 및 통제실무</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>90</ProgRate>
    <ProgPoint>10</ProgPoint>
    <HWPoint>10</HWPoint>
    <TestPoint>10</TestPoint>
    <MeetPoint>10</MeetPoint>
    <ComplatePoint>10</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>60</ComplateStdPoint>
    <EduAmt>10010</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>12</No>
    <EmpName>전인성         </EmpName>
    <DeptName>관리팀</DeptName>
    <EduCourseName>생산원가의 이해와 원가절감</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>51</ComplateTime>
    <ProgRate>83.15</ProgRate>
    <ProgPoint>11</ProgPoint>
    <HWPoint>11</HWPoint>
    <TestPoint>11</TestPoint>
    <MeetPoint>11</MeetPoint>
    <ComplatePoint>11</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>61</ComplateStdPoint>
    <EduAmt>10011</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
    <Remark>test11</Remark>
  </DataBlock1>
  <DataBlock1>
    <No>13</No>
    <EmpName>정명진         </EmpName>
    <DeptName>생산1팀</DeptName>
    <EduCourseName>생산테스트</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>321</ComplateTime>
    <ProgRate>80.23</ProgRate>
    <ProgPoint>12</ProgPoint>
    <HWPoint>12</HWPoint>
    <TestPoint>12</TestPoint>
    <MeetPoint>12</MeetPoint>
    <ComplatePoint>12</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>62</ComplateStdPoint>
    <EduAmt>10012</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
  <DataBlock1>
    <No>14</No>
    <EmpName>이태규         </EmpName>
    <DeptName>생산5팀</DeptName>
    <EduCourseName>설비관리(TPM)종합</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>미적용</EI>
    <ComplateTime>321</ComplateTime>
    <ProgRate>91</ProgRate>
    <ProgPoint>13</ProgPoint>
    <HWPoint>13</HWPoint>
    <TestPoint>13</TestPoint>
    <MeetPoint>13</MeetPoint>
    <ComplatePoint>13</ComplatePoint>
    <ComplateName>미수료</ComplateName>
    <ComplateStdPoint>63</ComplateStdPoint>
    <EduAmt>10013</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
  <DataBlock1>
    <No>15</No>
    <EmpName>남민호         </EmpName>
    <DeptName>생산4팀</DeptName>
    <EduCourseName>설비관리(TPM)종합</EduCourseName>
    <EduBegDate>10/01/2014 00:00:00</EduBegDate>
    <EduEndDate>11/01/2014 00:00:00</EduEndDate>
    <EI>적용</EI>
    <ComplateTime>21</ComplateTime>
    <ProgRate>0</ProgRate>
    <ProgPoint>14</ProgPoint>
    <HWPoint>14</HWPoint>
    <TestPoint>14</TestPoint>
    <MeetPoint>14</MeetPoint>
    <ComplatePoint>14</ComplatePoint>
    <ComplateName>수료</ComplateName>
    <ComplateStdPoint>64</ComplateStdPoint>
    <EduAmt>10014</EduAmt>
    <ReturnAmt>0</ReturnAmt>
    <FrtReturnAmt>0</FrtReturnAmt>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025970,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021807