"""Run the real purchase callback with a failing durable save adapter."""
from pathlib import Path
import os, subprocess
root=Path(__file__).resolve().parent.parent
source=(root/'src/Server/MonetizationService.luau').read_text().replace('require(Shared.Config)',"require('../src/Shared/Config')").replace('require(Shared.Actions)',"require('../src/Shared/Actions')").replace('require(script.Parent.Analytics)','{event=function() end}')
harness='''
local C=require('../src/Shared/Config')
local P=require('../src/Shared/Profile')
local callback
local player={UserId=1}
local marketplace={PromptGamePassPurchaseFinished={Connect=function() end}}
local players={GetPlayerByUserId=function(_,id) return id==1 and player or nil end}
local game={ReplicatedStorage={WFT={}},GetService=function(_,key) return key=='Players' and players or marketplace end}
local Enum={ProductPurchaseDecision={NotProcessedYet='retry',PurchaseGranted='granted'}}
local M=(function()
'''+source+'''
end)()
local d=P.new(os.time())
local successful=false; local durable
local Data={Sessions={[player]={Data=d,Busy=false,Memory=false,Closing=false}},save=function() if successful then durable=d.Coins; return true end return false end}
M.init(Data,function() end)
C.Monetization.Small.Id=101
local r={PlayerId=1,ProductId=101,PurchaseId='receipt-a'}
assert(marketplace.ProcessReceipt(r)=='retry','acknowledged before durable save')
local granted=d.Coins; assert(granted>0 and durable==nil)
successful=true
assert(marketplace.ProcessReceipt(r)=='granted'); assert(d.Coins==granted and durable==granted)
assert(marketplace.ProcessReceipt(r)=='granted' and d.Coins==granted,'duplicate grant')
assert(marketplace.ProcessReceipt({PlayerId=2,ProductId=101,PurchaseId='b'})=='retry')
assert(marketplace.ProcessReceipt({PlayerId=1,ProductId=999,PurchaseId='c'})=='retry')
Data.Sessions[player].Busy=true; assert(marketplace.ProcessReceipt(r)=='retry'); Data.Sessions[player].Busy=false
Data.Sessions[player].Memory=true; assert(marketplace.ProcessReceipt(r)=='retry')
print('PASS receipts: durable-before-ACK, failed save retry, duplicate delivery, unknown product, missing player, busy and memory sessions')
'''
path=root/'tests/.receipts.generated.luau'
try:
 path.write_text(harness)
 subprocess.run([os.environ.get('LUAU','luau'),str(path)],check=True)
finally: path.unlink(missing_ok=True)
