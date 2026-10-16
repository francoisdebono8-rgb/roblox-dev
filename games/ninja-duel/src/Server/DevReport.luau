-- Profiler report export (Codex 33028b2, ported). Roblox truncates long Output
-- lines: one bounded JSON row per metric/event, framed by begin/end rows that
-- carry the exact build fingerprint (tools/dev.py report checks both).
-- Debug/QA places only (build.py DEBUG_SOURCES).
local Report={}
function Report.print(report)
	local http=game:GetService("HttpService")
	local id=report.server.build:sub(1,12).."-"..tostring(math.floor(os.clock()*1000));local rows=0
	local function emit(row)
		row.id=id;row.build=report.server.build
		print("[NinjaDuelPerf] "..http:JSONEncode(row))
	end
	emit({kind="begin",clientPresent=report.client~=nil})
	for _,side in {"server","client"} do
		local data=report[side]
		if data then
			emit({kind="meta",side=side,enabled=data.enabled,seconds=data.seconds});rows+=1
			for name,value in data.stats do emit({kind="metric",side=side,name=name,value=value});rows+=1 end
			for name,value in data.counters do emit({kind="counter",side=side,name=name,value=value});rows+=1 end
			for _,value in data.events do
				local event=table.clone(value)
				if event.context and event.context.error then event.context=table.clone(event.context);event.context.error=tostring(event.context.error):sub(1,300) end
				emit({kind="event",side=side,value=event});rows+=1
			end
		end
	end
	emit({kind="end",rows=rows})
end
return Report
