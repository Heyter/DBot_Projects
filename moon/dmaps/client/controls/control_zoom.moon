
--
-- Copyright (C) 2017 DBot
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 

PANEL = {}

PANEL.BACKGROUND_COLOR = Color(40, 40, 40, 255)
PANEL.CONTROL_LOCKED = Color(230, 230, 230, 255)
PANEL.CONTROL_TOOBIG = Color(80, 80, 170, 255)
PANEL.CONTROL_UNLOCKED = Color(170, 170, 170, 255)
PANEL.WIDTH = 64
PANEL.HEIGHT = 256
PANEL.MIN_ZOOM = 400
PANEL.MAX_ZOOM = 3000
PANEL.DELTA_ZOOM = PANEL.MAX_ZOOM - PANEL.MIN_ZOOM
PANEL.MULT_ADD = PANEL.MIN_ZOOM / PANEL.DELTA_ZOOM

PANEL.Init = =>
	@zoom = 0
	@displayZoom = 0
	@hold = false
	@lock = false
	@holdstart = 0
	@SetSize(@WIDTH, @HEIGHT)

PANEL.OnMousePressed = (code) =>
	if code == MOUSE_RIGHT or code == MOUSE_MIDDLE
		@lock = false
		@mapObject\LockZoom(false)
	elseif code == MOUSE_LEFT
		@hold = true
		@lock = true
		@holdstart = RealTime!

PANEL.OnMouseReleased = (code) =>
	if code == MOUSE_LEFT
		@hold = false
		if @holdstart + 0.1 > RealTime!
			@lock = false
			@mapObject\LockZoom(false)
	
PANEL.SetMap = (map) =>
	@mapObject = map
	@zoom = @mapObject\GetZoom!
	@displayZoom = @zoom
	@lock = @mapObject\GetLockZoom!

PANEL.OnYawChanges = =>
	@mapObject\SetYaw(@yaw)

PANEL.Think = =>
	@lock = @mapObject\GetLockZoom!
	
	holdingEnough = @hold and @holdstart + 0.1 < RealTime!
		
	if not @IsHovered!
		@hold = false
		holdingEnough = false
	
	if holdingEnough
		@lock = true
		@mapObject\LockZoom(true)
	
	if @lock
		if holdingEnough
			w, h = @GetSize!
			hw, hh = w / 2, h / 2
			
			centerX, centerY = @LocalToScreen(hw, h)
			x, y = gui.MousePos()
			
			deltaX = x - centerX
			deltaY = centerY - y
			
			if deltaX < hw and deltaX > -hw and deltaY > 0 and deltaY < h
				@zoom = @DELTA_ZOOM * deltaY / h + @MIN_ZOOM
				@mapObject\SetZoom(Lerp(0.2, @mapObject\GetZoom!, @zoom))
		else
			@zoom = @mapObject\GetZoom!
	else
		@zoom = @mapObject\GetZoom!
	
	@displayZoom = Lerp(0.2, @displayZoom, @zoom)

PANEL.Paint = (w, h) =>
	draw.NoTexture!
	
	-- Background
	surface.SetDrawColor(@BACKGROUND_COLOR)
	surface.DrawRect(3, 0, w - 6, h)
	
	step = h / 14
	
	surface.SetDrawColor(0, 0, 0)
	
	-- Visual step markers
	for i = step, h, step
		surface.DrawRect(5, i, w - 10, 4)
	
	if @lock
		surface.SetDrawColor(@CONTROL_LOCKED)
	else
		surface.SetDrawColor(@CONTROL_UNLOCKED)
	
	mult = (1 - @displayZoom / @DELTA_ZOOM)
	
	if mult >= -0.1
		surface.DrawRect(0, math.min(mult * h + 30, h - 10), w, 10)
	else
		surface.SetDrawColor(@CONTROL_TOOBIG)
		surface.DrawRect(0, 0, w, 10)

DMaps.PANEL_MAP_ZOOM = PANEL
vgui.Register('DMapsMapZoom', DMaps.PANEL_MAP_ZOOM, 'EditablePanel')
return PANEL
