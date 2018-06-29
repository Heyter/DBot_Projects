
-- Enhanced Visuals for GMod
-- Copyright (C) 2018 DBot

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local DVisuals = DVisuals
local type = type
local table = table
local math = math
local ipairs = ipairs
local Color = Color
local HUDCommons = DLib.HUDCommons
local ScrWL = ScrWL
local ScrHL = ScrHL
local ScreenSize = ScreenSize
local Quintic = Quintic

local slashparticles = {}

for i = 0, 4 do
	table.insert(slashparticles, CreateMaterial('enchancedvisuals/splat/slash/slash' .. i, 'UnlitGeneric', {
		['$basetexture'] = 'enchancedvisuals/splat/slash/slash' .. i,
		['$translucent'] = '1',
		['$alpha'] = '1',
		['$nolod'] = '1',
		['$nofog'] = '1',
		['$color'] = '[1 1 1]',
		['$color2'] = '[1 1 1]',
	}))
end

net.receive('DVisuals.Slash', function()
	if not DVisuals.ENABLE_BLOOD() then return end
	if not DVisuals.ENABLE_BLOOD_SLASH() then return end

	local score = net.ReadUInt(8)
	local yaw = net.ReadInt(8)
	local w, h = ScrWL(), ScrHL()

	local mult = (score / 8):clamp(1, 8)
	local currentX = (yaw + 90) / 180 * w
	local randY = math.random(h * 0.8) + h * 0.1
	local scatterWidth = (ScreenSize(60) + ScreenSize(120):random()) * mult
	local scatterHeight = (ScreenSize(20) + ScreenSize(15):random()) * mult
	local ttl = math.random(score:sqrt()) + 7

	--print(scatterWidth, scatterHeight, currentX, yaw)

	for i = 1, (score * 7):max(4) do
		local scatterX = math.random(scatterWidth)
		local maxScatterY = Quintic(scatterX:progression(0, scatterWidth, scatterWidth / 2))
		--print(scatterX, scatterWidth, maxScatterY)

		DVisuals.CreateParticleOverrided(table.frandom(slashparticles), ttl, (score / 3):random() * ScreenSize(6) + ScreenSize(3), {
			x = currentX + scatterX - scatterWidth / 2,
			y = randY + (math.random(scatterHeight) - scatterHeight / 2) * maxScatterY,
			color = Color(200 + math.random(40), 20, 40)
		})
	end
end)
