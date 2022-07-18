  
IF OBJECT_ID('KPX_SPDMRPDailyItemCheck') IS NOT NULL   
    DROP PROC KPX_SPDMRPDailyItemCheck  
GO  
  
-- v2014.12.15  
  
-- 일별자재소요계산-체크 by 이재천   
CREATE PROC KPX_SPDMRPDailyItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDMRPDailyItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDMRPDailyItem'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET Serl = DataSeq 
      FROM #KPX_TPDMRPDailyItem AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #KPX_TPDMRPDailyItem 
    
    RETURN  
GO 
exec KPX_SPDMRPDailyItemCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-1111</Value>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-11121</Value>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-47721</Value>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-57721</Value>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-65421</Value>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-71501</Value>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-96501</Value>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-136501</Value>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-147101</Value>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-147701</Value>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>0</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName />
    <SMInOutTypePur>0</SMInOutTypePur>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <Spec />
    <ItemSeq>21932</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>-1111.00000</Total>
    <Value>-265701</Value>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-12012</Value>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-56412</Value>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-68412</Value>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-77712</Value>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-85012</Value>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-115012</Value>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-163012</Value>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-175732</Value>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-176452</Value>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>1</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <Spec />
    <ItemSeq>21934</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-318452</Value>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>32</IDX_NO>
    <DataSeq>32</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-2</Value>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>33</IDX_NO>
    <DataSeq>33</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-2802</Value>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>34</IDX_NO>
    <DataSeq>34</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-4802</Value>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>35</IDX_NO>
    <DataSeq>35</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-5802</Value>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>36</IDX_NO>
    <DataSeq>36</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-6422</Value>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>37</IDX_NO>
    <DataSeq>37</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>38</IDX_NO>
    <DataSeq>38</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-11422</Value>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>39</IDX_NO>
    <DataSeq>39</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>40</IDX_NO>
    <DataSeq>40</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>41</IDX_NO>
    <DataSeq>41</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>42</IDX_NO>
    <DataSeq>42</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>43</IDX_NO>
    <DataSeq>43</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>0</Value>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>44</IDX_NO>
    <DataSeq>44</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-13542</Value>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>45</IDX_NO>
    <DataSeq>45</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>2</ROW_IDX>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>0</Serl>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <Spec />
    <ItemSeq>22251</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <CustName />
    <DelvTerm />
    <MinPurQty>0</MinPurQty>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <Total>0.00000</Total>
    <Value>-17542</Value>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414