
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

ENT.PrintName = 'Cleaver Projectile'
ENT.Author = 'DBot'
ENT.Category = 'TF2'
ENT.Base = 'base_anim'
ENT.Type = 'anim'
ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.BallModel = 'models/weapons/c_models/c_sd_cleaver/c_sd_cleaver.mdl'

ENT.SetupDataTables = =>
	@NetworkVar('Bool', 0, 'IsFlying')
	@NetworkVar('Bool', 1, 'IsCritical')

AccessorFunc(ENT, 'm_Attacker', 'Attacker')
AccessorFunc(ENT, 'm_Inflictor', 'Inflictor')
AccessorFunc(ENT, 'm_dmgtype', 'DamageType')
AccessorFunc(ENT, 'm_dmg', 'Damage')

ENT.DefaultDamage = 50
ENT.RemoveTimer = 10

ENT.Initialize = =>
	@SetModel(@BallModel)
	return if CLIENT
	@removeAt = CurTime() + @RemoveTimer
	@PhysicsInitSphere(8)
	@SetDamageType(DMG_SLASH)
	@SetDamage(@DefaultDamage)
	@SetAttacker(@)
	@SetInflictor(@)
	@SetIsFlying(true)
	@initialPosition = @GetPos()
	phys = @GetPhysicsObject()
	@phys = phys
	with phys
		\EnableMotion(true)
		\EnableDrag(false)
		\SetMass(5)
		\Wake()

ENT.Draw = =>
	@DrawModel()
	if not @particles
		@particles = CreateParticleSystem(@, 'peejar_trail_red', PATTACH_ABSORIGIN_FOLLOW, 0)

ENT.SetDirection = (dir = Vector(0, 0, 0)) =>
	newVel = Vector(dir)
	newVel.z += 0.05
	@phys\SetVelocity(newVel * 4000)
	@SetAngles(dir\Angle())

ENT.Think = =>
	return false if CLIENT
	@Remove() if @removeAt < CurTime()

ENT.OnHit = (ent, data = {}) =>
	dist = @GetPos()\Distance(@initialPosition)
	miniCrit = dist > 1024 or ent\IsMarkedForDeath()

	dmginfo = DamageInfo()
	dmginfo\SetDamageType(@GetDamageType())
	dmginfo\SetDamage(@GetDamage() * (@GetIsCritical() and 3 or miniCrit and 1.3 or 1))
	dmginfo\SetAttacker(@GetAttacker())
	dmginfo\SetInflictor(@GetInflictor())
	ent\TakeDamageInfo(dmginfo)

	if @GetIsCritical()
		effData = EffectData()
		effData\SetOrigin(data.HitPos)
		util.Effect('dtf2_critical_hit', effData)
		@GetAttacker()\EmitSound('DTF2_TFPlayer.CritHit')
		ent\EmitSound('DTF2_TFPlayer.CritHit')
	elseif miniCrit
		effData = EffectData()
		effData\SetOrigin(data.HitPos)
		util.Effect('dtf2_minicrit', effData)
		@GetAttacker()\EmitSound('DTF2_TFPlayer.CritHitMini')
		ent\EmitSound('DTF2_TFPlayer.CritHitMini')
	
	if ent\IsNPC() or ent\IsPlayer()
		bleed = ent\TF2Bleed(math.Clamp(dist / 256, 5, 10))
		bleed\SetAttacker(@GetAttacker())
		bleed\SetInflictor(@GetInflictor())
		ent\EmitSound('DTF2_Cleaver.ImpactFlesh')
		@GetAttacker()\EmitSound('DTF2_Cleaver.ImpactFlesh')
	else
		ent\EmitSound('DTF2_Cleaver.ImpactWorld')
	
	@Remove()

ENT.PhysicsCollide = (data = {}, colldier) =>
	{:HitEntity} = data
	return if not @GetIsFlying()
	return false if HitEntity == @GetAttacker()
	if IsValid(HitEntity)
		@OnHit(HitEntity, data)
	else
		@SetIsFlying(false)
		@EmitSound('DTF2_Cleaver.ImpactWorld')

ENT.IsTF2Cleaver = true

if SERVER
	hook.Add 'EntityTakeDamage', 'DTF2.CleaverProjective', (ent, dmg) ->
		attacker = dmg\GetAttacker()
		return if not IsValid(attacker)
		return if not attacker.IsTF2Cleaver
		return if dmg\GetDamageType() ~= DMG_CRUSH
		dmg\SetDamage(0)
		dmg\SetMaxDamage(0)