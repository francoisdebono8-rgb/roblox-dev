-- Where Konoha's HUD sits in the window (14/11, the new player's walk, read
-- in the code before a Studio pass): the place-and-kit box sat at y 18 with
-- the HUD ignoring Roblox's inset, so under Roblox's menu and chat buttons;
-- the goal (840 px of a hundred letters) ran under the SHOP box on a laptop
-- (1280 to 1366 px); nothing was sized for a phone, and the master's card
-- (490 x 380) covered the touch jump button. Pure (no service): Client/
-- HubClient applies it, the headless suite checks it at every window size.
--
-- Rectangles are {x, y, w, h} in window pixels (the HUD's ScreenGui ignores
-- the inset, so y 0 is the top of the screen).
local L={}

L.MARGIN=16
L.HUD={w=430,h=74}      -- the place and the kit, top left
L.SHOP={w=424,h=172}    -- the Ryō, DUELS and SHOP, top right; QUESTS and RANKS under them
L.GOAL={w=430,h=58,stackH=96} -- what to do next: under the place box, a head and its places one a line
L.MAP=238               -- the minimap's box (MiniMap.SIZE + its name line)
L.STACK=700             -- narrower (in the goal's own units), one place a line
L.CARD={w=490,h=380}    -- a master's card
L.RUN=14                -- the gap between the touch RUN and jump buttons
L.ROW=600               -- the goal shares the top row when it gets this much
L.WIDE=1100             -- a narrower window centres the master's card

-- Roblox's touch jump button (PlayerModule, TouchJump): 70 px on a small
-- screen (its short side 500 or less), 120 otherwise, anchored bottom right.
function L.jump(viewport)
	local small=math.min(viewport.X,viewport.Y)<=500
	local size=if small then 70 else 120
	local x=viewport.X-(size*1.5-10)
	local y=if small then viewport.Y-size-20 else viewport.Y-size*1.75
	return {x=x,y=y,w=size,h=size}
end

-- The layout for a window of `viewport` pixels, under Roblox's top bar of
-- `insetY` pixels, with or without touch controls.
function L.compute(viewport,insetY,touch)
	local X,Y=viewport.X,viewport.Y
	local m=L.MARGIN
	-- The scale: a laptop's window keeps the full size; a phone (touch) keeps
	-- its text readable (the place box's kit line is 14 px at 1).
	local s=if touch then math.clamp(math.min(X/1060,Y/500),.7,1) else math.clamp(math.min(X/1280,Y/720),.55,1)
	local top=math.max(insetY or 0,0)+8
	local out={scale=s,top=top,touch=touch==true}
	out.hud={x=m,y=top,w=L.HUD.w*s,h=L.HUD.h*s}
	out.shop={x=X-m-L.SHOP.w*s,y=top,w=L.SHOP.w*s,h=L.SHOP.h*s}
	-- A portrait phone: the two boxes do not fit side by side; the shop goes
	-- under the place box, on the right.
	if out.hud.x+out.hud.w+m>out.shop.x then out.shop.y=top+out.hud.h+8 end
	local below=math.max(out.hud.y+out.hud.h,out.shop.y+out.shop.h)+8
	-- (DESIGN 23/11, passe 1: « le bandeau CHOOSE YOUR INSPIRATION reste en
	-- haut au milieu et cache la vue ») The goal: under the place box, its
	-- width, the head then the places one a line; the middle of the screen is
	-- the village's.
	-- (a portrait phone: under the shop box, which sits under the place box)
	out.goal={x=m,y=if out.shop.y==top then out.hud.y+out.hud.h+8 else below,w=math.min(L.GOAL.w*s,X-2*m),h=L.GOAL.stackH*s,stack=true}
	-- The minimap: under the goal on a laptop; with touch, under the shop box
	-- on the right (the thumbstick owns the bottom left).
	if touch then
		-- landscape: in the top row, left of the shop box; portrait: under the goal, right
		local ms=s
		local left=math.max(out.goal.x+out.goal.w,out.hud.x+out.hud.w)+10
		local room=out.shop.x-10-left
		local ts=math.min(s,room/(L.MAP-30))
		if ts>=.45 then ms=ts end
		local mx=out.shop.x-10-(L.MAP-30)*ms
		if out.shop.y==top and mx>=left-.5 then
			out.map={x=mx,y=top,w=(L.MAP-30)*ms,h=L.MAP*ms,scale=ms}
		else
			local y=(if out.shop.y==top then math.max(out.goal.y+out.goal.h,out.shop.y+out.shop.h) else out.goal.y+out.goal.h)+10
			local jump=L.jump(viewport)
			ms=math.min(s,(jump.y-10-y)/L.MAP)
			-- no room on a small phone: no minimap, the goal's MAP button opens the big one
			out.map=if ms>=.45 then {x=X-m-(L.MAP-30)*ms,y=y,w=(L.MAP-30)*ms,h=L.MAP*ms,scale=ms} else nil
		end
	else
		out.map={x=m,y=out.goal.y+out.goal.h+10,w=(L.MAP-30)*s,h=L.MAP*s,scale=s}
	end
	-- The master's card: on the right of a wide window (the village stays in
	-- view), centred on a narrow one or with touch controls (clear of the
	-- thumbstick's corner and the jump button).
	-- Touch: a RUN button left of Roblox's jump button, the same size; the
	-- key line at the bottom only without touch.
	if touch then
		local jump=L.jump(viewport)
		out.jump=jump
		out.run={x=jump.x-L.RUN-jump.w,y=jump.y,w=jump.w,h=jump.h}
	else
		out.keys={x=X/2-360*s,y=Y-34*s,w=720*s,h=22*s}
	end
	if X>=L.WIDE and not touch then
		local cs=math.min(s,(Y-below-m)/L.CARD.h)
		local h=L.CARD.h*cs
		out.card={x=X-30*s-L.CARD.w*cs,y=math.max(below,Y/2-h/2),w=L.CARD.w*cs,h=h,scale=cs}
	else
		-- Centred in what is left: under the top row, left of the RUN and
		-- jump buttons (with touch), above the key line (without).
		-- With touch the card takes the larger of two places: left of the
		-- buttons (a landscape phone) or above them (a portrait one).
		local function fit(right,bottom,from)
			from=from or below
			local cs=math.min(1,(right-m)/L.CARD.w,(bottom-from)/L.CARD.h)
			local w,h=L.CARD.w*cs,L.CARD.h*cs
			return {x=m+(right-m-w)/2,y=from+(bottom-from-h)/2,w=w,h=h,scale=cs}
		end
		if out.run then
			-- (a phone's card takes the top row's place too: the place box
			-- and the shop step aside while he talks, `overTop`)
			local left,above=fit(out.run.x-8,Y-m,top),fit(X-m,math.min(out.run.y,out.jump.y)-8,top)
			out.card=if above.scale>left.scale then above else left
			out.card.overTop=true
		else
			out.card=fit(X-m,out.keys.y-8)
		end
	end
	return out
end

-- Whether two rectangles overlap (the suite's check).
function L.overlap(a,b)
	return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h
end

return L
