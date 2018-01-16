
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local DLib = DLib
local math = math
local WOverlord = WOverlord
local hook = hook
local CurTime = CurTime
local RealTime = RealTime
local surface = surface
local ipairs = ipairs
local table = table
local FrameTime = FrameTime
local LocalPlayer = LocalPlayer
local meta = WOverlord.GetWeatherMeta('rain')
local isSnowing = false
local isWorking = false
local ScrW, ScrH = ScrW, ScrH

local snowParticle = 'particle/snow'
local rainParticle = 'particle/water_drop'
local waterDrop = 'particle/warp_ripple3'
local snowID = surface.GetTextureID(snowParticle)
local rainID = surface.GetTextureID(rainParticle)
local waterDropID = surface.GetTextureID(waterDrop)

local snowParticles = {}
local rainParticles = {}

local windSpeed = 0

local function HUDSnow()
	local ply = LocalPlayer()
	if not ply:IsValid() then return end

	if not ply:Alive() then
		if #snowParticles ~= 0 then
			snowParticles = {}
		end

		return
	end

	if #snowParticles == 0 then return end

	local time = RealTime()
	local toRemove

	surface.SetTexture(snowID)
	surface.SetDrawColor(255, 255, 255)

	for i, drop in ipairs(snowParticles) do
		if drop.lifetime < time then
			toRemove = toRemove or {}
			table.insert(toRemove, i)
		else
			surface.SetDrawColor(255, 255, 255, 255 - time:progression(drop.start, drop.lifetime) * 255)
			surface.DrawTexturedRect(drop.x, drop.y, drop.size, drop.size)
		end
	end

	if toRemove then
		table.removeValues(snowParticles, toRemove)
	end
end

local rainFadeStep = ScrH() * 0.09

local function HUDRain()
	local ply = LocalPlayer()
	if not ply:IsValid() then return end

	if not ply:Alive() then
		if #rainParticles ~= 0 then
			rainParticles = {}
		end

		return
	end

	local time = RealTime()
	local toRemove

	surface.SetTexture(waterDropID)
	surface.SetDrawColor(255, 255, 255)

	for i, drop in ipairs(rainParticles) do
		if drop.lifetime < time then
			toRemove = toRemove or {}
			table.insert(toRemove, i)
		else
			surface.SetDrawColor(255, 255, 255, 255 - time:progression(drop.start, drop.lifetime) * 255)
			surface.DrawTexturedRect(drop.x, drop.y + time:progression(drop.start, drop.lifetime) * rainFadeStep * (windSpeed * 3 + 1) * drop.fadeSpeed, drop.size, drop.size)
		end
	end

	if toRemove then
		table.removeValues(rainParticles, toRemove)
	end
end

local snowScore = 0
local minSize = math.floor(math.max(ScrW(), ScrH()) * 0.003)
local maxSize = math.floor(math.max(ScrW(), ScrH()) * 0.02)

local function ThinkSnow(state, date, delta)
	local ply = LocalPlayer()
	if not ply:IsValid() then return end
	if not ply:Alive() then return end
	local angles = ply:EyeAngles()

	local mult = (angles.p - 16) / 40

	if mult >= 0 then return end

	local pos = ply:GetPos()
	if not WOverlord.CheckOutdoorPoint(pos) then return end

	snowScore = snowScore - FrameTime() * mult * 6 * (windSpeed + 1)

	if snowScore < 1 then return end
	local score = math.floor(snowScore)
	snowScore = snowScore % 1

	local time = RealTime()

	for i = 1, score do
		local drop = {
			lifetime = time + math.random() * 2 + 1,
			x = math.random(0, ScrW()),
			y = math.random(0, ScrH()),
			size = math.random(minSize, maxSize),
			start = time,
		}

		table.insert(snowParticles, drop)
	end
end

local rainScore = 0

local function ThinkRain(state, date, delta)
	local ply = LocalPlayer()
	if not ply:IsValid() then return end
	if not ply:Alive() then return end
	local angles = ply:EyeAngles()

	local mult = (angles.p - 16) / 20

	if mult >= 0 then return end

	local pos = ply:GetPos()
	if not WOverlord.CheckOutdoorPoint(pos) then return end

	rainScore = rainScore - FrameTime() * mult * 12 * (windSpeed + 1)
	if rainScore < 1 then return end
	local score = math.floor(rainScore)
	rainScore = rainScore % 1

	local time = RealTime()

	for i = 1, score do
		local drop = {
			lifetime = time + math.random() * 3 + 1,
			x = math.random(0, ScrW()),
			y = math.random(0, ScrH()),
			size = math.random(minSize, maxSize * 2),
			start = time,
			fadeSpeed = math.random() * 4
		}

		table.insert(rainParticles, drop)
	end
end

function meta:ThinkClient(date, delta)
	if self:IsDryRun() then return end
	isWorking = true
	isSnowing = date:GetTemperature() < 0.1
	windSpeed = date:GetWindSpeedCI():GetMetres()

	if isSnowing then
		ThinkSnow(self, date, delta)
	else
		ThinkRain(self, date, delta)
	end

	hook.Run(meta.UpdateClientHookID, self, date, delta)
	return true
end

function meta:Stop()
	if self:IsDryRun() then return end
	isWorking = false
end

hook.Add('HUDPaint', 'WeatherOverlord_RainOverlay', function()
	if isSnowing then
		HUDSnow()
	else
		HUDRain()
	end
end)
