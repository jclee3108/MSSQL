  
IF OBJECT_ID('KPX_SPDMRPDailyItemSave') IS NOT NULL   
    DROP PROC KPX_SPDMRPDailyItemSave  
GO  
  
-- v2014.12.15  
  
-- 일별자재소요계산-품목 저장 by 이재천   
CREATE PROC KPX_SPDMRPDailyItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDMRPDailyItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDMRPDailyItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDMRPDailyItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDMRPDailyItem  
        (   
            CompanySeq, MRPDailySeq, Serl, MRPDate, ItemSeq, 
            CalcType, UnitSeq, Qty, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.MRPDailySeq, A.Serl, A.TITLE_IDX0_SEQ, A.ItemSeq, 
               A.KindSeq, A.UnitSeq, A.Value, @UserSeq, GETDATE() 
          FROM #KPX_TPDMRPDailyItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END     
    
    SELECT * FROM #KPX_TPDMRPDailyItem   
    
    RETURN  
GO 
begin tran 
exec KPX_SPDMRPDailyItemSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>1</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
    <Value>-1111.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>2</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
    <Value>-11121.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>3</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
    <Value>-47721.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>4</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
    <Value>-57721.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>5</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
    <Value>-65421.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>6</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
    <Value>-71501.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>7</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
    <Value>-96501.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>8</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
    <Value>-136501.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>9</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
    <Value>-147101.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>10</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>11</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>12</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>13</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>14</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
    <Value>-147701.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <AssetName>반제품</AssetName>
    <AssetSeq>4</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>계획생산테스트1</ItemClassName>
    <ItemClassSeq>2001004</ItemClassSeq>
    <ItemName>김경희_반제품_LOT2</ItemName>
    <ItemNo>김경희_반제품_LOT2</ItemNo>
    <ItemSeq>21932</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>15</Serl>
    <SMInOutTypePur>0</SMInOutTypePur>
    <SMInOutTypePurName />
    <Spec />
    <Total>-1111.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
    <Value>-265701.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>16</IDX_NO>
    <DataSeq>16</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>16</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>17</IDX_NO>
    <DataSeq>17</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>17</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
    <Value>-12012.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>18</IDX_NO>
    <DataSeq>18</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>18</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
    <Value>-56412.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>19</IDX_NO>
    <DataSeq>19</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>19</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
    <Value>-68412.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>20</IDX_NO>
    <DataSeq>20</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>20</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
    <Value>-77712.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>21</IDX_NO>
    <DataSeq>21</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>21</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
    <Value>-85012.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>22</IDX_NO>
    <DataSeq>22</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>22</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
    <Value>-115012.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>23</IDX_NO>
    <DataSeq>23</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>23</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
    <Value>-163012.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>24</IDX_NO>
    <DataSeq>24</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>24</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
    <Value>-175732.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>25</IDX_NO>
    <DataSeq>25</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>25</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>26</IDX_NO>
    <DataSeq>26</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>26</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>27</IDX_NO>
    <DataSeq>27</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>27</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>28</IDX_NO>
    <DataSeq>28</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>28</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>29</IDX_NO>
    <DataSeq>29</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>29</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
    <Value>-176452.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>30</IDX_NO>
    <DataSeq>30</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <AssetName>원자재</AssetName>
    <AssetSeq>6</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>Ver1</ItemClassName>
    <ItemClassSeq>2004009</ItemClassSeq>
    <ItemName>김경희_원자재_LOT4</ItemName>
    <ItemNo>김경희_원자재_LOT4</ItemNo>
    <ItemSeq>21934</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>30</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
    <Value>-318452.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>31</IDX_NO>
    <DataSeq>31</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>31</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141201</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>32</IDX_NO>
    <DataSeq>32</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>32</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141202</TITLE_IDX0_SEQ>
    <Value>-2.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>33</IDX_NO>
    <DataSeq>33</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>33</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141203</TITLE_IDX0_SEQ>
    <Value>-2802.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>34</IDX_NO>
    <DataSeq>34</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>34</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141204</TITLE_IDX0_SEQ>
    <Value>-4802.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>35</IDX_NO>
    <DataSeq>35</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>35</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141205</TITLE_IDX0_SEQ>
    <Value>-5802.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>36</IDX_NO>
    <DataSeq>36</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>36</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141206</TITLE_IDX0_SEQ>
    <Value>-6422.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>37</IDX_NO>
    <DataSeq>37</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>37</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141207</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>38</IDX_NO>
    <DataSeq>38</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>38</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141208</TITLE_IDX0_SEQ>
    <Value>-11422.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>39</IDX_NO>
    <DataSeq>39</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>39</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141209</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>40</IDX_NO>
    <DataSeq>40</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>40</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141210</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>41</IDX_NO>
    <DataSeq>41</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>41</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141211</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>42</IDX_NO>
    <DataSeq>42</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>42</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141212</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>43</IDX_NO>
    <DataSeq>43</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>43</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141213</TITLE_IDX0_SEQ>
    <Value>0.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>44</IDX_NO>
    <DataSeq>44</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>44</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141214</TITLE_IDX0_SEQ>
    <Value>-13542.00000</Value>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>45</IDX_NO>
    <DataSeq>45</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>2</ROW_IDX>
    <AssetName>재공품</AssetName>
    <AssetSeq>5</AssetSeq>
    <CustName />
    <DelvTerm />
    <ItemClassName>앰플</ItemClassName>
    <ItemClassSeq>2004034</ItemClassSeq>
    <ItemName>김경희_BOM테스트재공품1</ItemName>
    <ItemNo>김경희_BOM테스트재공품1</ItemNo>
    <ItemSeq>22251</ItemSeq>
    <KindName>현재고</KindName>
    <KindSeq>1</KindSeq>
    <MinPurQty>0.00000</MinPurQty>
    <MRPDailySeq>1</MRPDailySeq>
    <Serl>45</Serl>
    <SMInOutTypePur>8047001</SMInOutTypePur>
    <SMInOutTypePurName>장기</SMInOutTypePurName>
    <Spec />
    <Total>0.00000</Total>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <TITLE_IDX0_SEQ>20141215</TITLE_IDX0_SEQ>
    <Value>-17542.00000</Value>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414

rollback 