
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

import DMaps, net, player, math, Color, hook, table from _G
import SERVER, CLIENT, Vector from _G
import DMapWaypoint from DMaps

class NetworkedWaypoint
	@NEXT_NETWORK_ID = 0
	@NETWORK_ID_LENGTH = 16
	@NETWORKED_WAYPOINTS = {}
	@NETWORK_STRING = 'DMaps.NetworkedWaypoint'
	@NETWORK_STRING_CHANGED = 'DMaps.NetworkedWaypointChanges'
	@NETWORK_STRING_REMOVE = 'DMaps.NetworkedWaypointRemoved'
	@NETWORK_VAR_LENGTH = 8
	@WAYPOINT_TYPE = DMapWaypoint
	@__type = 'networked_waypoint'
	
	@PLAYER_FILTER = => player.GetAll()
	
	@GetWaypoints = => [point for i, point in pairs @NETWORKED_WAYPOINTS]
	
	@NETWORKED_VALUES = {
		{'x', ((val = 0) -> net.WriteInt(math.floor(val), 32)), (-> net.ReadInt(32)), 'SetX'}
		{'y', ((val = 0) -> net.WriteInt(math.floor(val), 32)), (-> net.ReadInt(32)), 'SetY'}
		{'z', ((val = 0) -> net.WriteInt(math.floor(val), 32)), (-> net.ReadInt(32)), 'SetZ'}
		{'color', ((val = Color(0, 0, 0)) -> net.WriteColor(val)), net.ReadColor, 'SetColor'}
		{'name', ((val = '') -> net.WriteString(val)), net.ReadString, 'SetName'}
	}
	
	@GetNetworkID = (val = '') => @NETWORKED_VALUES_IDS[val]
	-- Call in subclasses
	@RECALC_NETWORK_TABLE = =>
		@NETWORKED_VALUES_IDS = {}
		for i = 1, #@NETWORKED_VALUES
			@NETWORKED_VALUES[i].netid = i
			@NETWORKED_VALUES_IDS[@NETWORKED_VALUES[i][1]] = i
	
	@RECALC_NETWORK_TABLE()
	-- Clientside only
	@NetworkedCreate: =>
		return if SERVER
		id = net.ReadUInt(@NETWORK_ID_LENGTH)
		waypoint = NetworkedWaypoint("%WAYPOINT_NAME_#{id}%")
		
		waypoint.INITIALIZE = true
		waypoint.ID = id
		@NETWORKED_WAYPOINTS[waypoint.ID] = waypoint
		
		waypoint\ReadData()
		waypoint\CreateWaypoint()
		
		hook.Run('NetworkedWaypointCreated', waypoint)
	@NetworkedChange: =>
		return if SERVER
		id = net.ReadUInt(@NETWORK_ID_LENGTH)
		varid = net.ReadUInt(@NETWORK_VAR_LENGTH) + 1
		return if not @NETWORKED_WAYPOINTS[id]
		waypoint = @NETWORKED_WAYPOINTS[id]
		
		data = @NETWORKED_VALUES[varid]
		error("Invalid network variable ID: #{varid}") if not data
		func = waypoint.waypoint[data[4]]
		read = data[3]()
		func(waypoint.waypoint, read)
		func(waypoint, read) for waypoint in *waypoint.clonedWaypoints
		waypoint[data[1]] = read
		
		hook.Run('NetworkedWaypointChanges', waypoint)
	@NetworkedRemove: =>
		return if SERVER
		id = net.ReadUInt(@NETWORK_ID_LENGTH)
		return if not @NETWORKED_WAYPOINTS[id]
		waypoint = @NETWORKED_WAYPOINTS[id]
		waypoint\Remove()
		hook.Run('NetworkedWaypointRemoved', waypoint)
	
	new: (name = "%WAYPOINT_NAME_#{@@NEXT_NETWORK_ID}%", x = 0, y = 0, z = 0, color = DMaps.RandomColor()) =>
		-- Do not create clientside externally
		if SERVER
			@ID = @@NEXT_NETWORK_ID
			@@NEXT_NETWORK_ID += 1
			@@NETWORKED_WAYPOINTS[@ID] = @
		@name = name
		@x = math.floor(x)
		@y = math.floor(y)
		@z = math.floor(z)
		@color = color
		@INITIALIZE = false
		@removed = false
		@clonedWaypoints = {} if CLIENT
	
	-- INTERNAL
	CreateWaypoint: =>
		constructor = @@WAYPOINT_TYPE
		@waypoint = constructor(@name, @x, @y, @z, @color)
		return @waypoint
	GetWaypoint: => @waypoint
	
	-- Feel free to use
	CloneWaypoint: =>
		constructor = @@WAYPOINT_TYPE
		waypoint = constructor(@name, @x, @y, @z, @color)
		table.insert(@clonedWaypoints, waypoint)
		return waypoint
	Waypoint: => @CloneWaypoint()
	
	WriteVal: (id = 1) =>
		return if CLIENT
		error('Initialize point first') if not @INITIALIZE
		data = @@NETWORKED_VALUES[id]
		error("Invalid network variable ID: #{id}") if not data
		net.Start(@@NETWORK_STRING_CHANGED)
		net.WriteUInt(@ID, @@NETWORK_ID_LENGTH)
		net.WriteUInt(id - 1, @@NETWORK_VAR_LENGTH)
		data[2](@[data[1]])
		net.Send(@networkedClients)
	WriteValString: (str = '') => @WriteVal(@@GetNetworkID(str))
	
	NetworkVal: (id = 1) =>
		return if CLIENT
		error('Initialize point first') if not @INITIALIZE
		data = @@NETWORKED_VALUES[id]
		error("Invalid network variable ID: #{id}") if not data
		data[2](@[data[1]])
	ReadVal: (id = 1) =>
		return if SERVER
		error('Initialize point first') if not @INITIALIZE
		data = @@NETWORKED_VALUES[id]
		error("Invalid network variable ID: #{id}") if not data
		@[data[1]] = data[3]()
	
	WriteData: =>
		return if CLIENT
		error('Initialize point first') if not @INITIALIZE
		data[2](@[data[1]]) for data in *@@NETWORKED_VALUES
	ReadData: =>
		return if SERVER
		error('Initialize point first') if not @INITIALIZE
		@[data[1]] = data[3]() for data in *@@NETWORKED_VALUES
	
	SetX: (val = 0, triggerNetwork = @INITIALIZE) =>
		@x = math.floor(val)
		@WriteValString('x') if triggerNetwork
	SetY: (val = 0, triggerNetwork = @INITIALIZE) =>
		@y = math.floor(val)
		@WriteValString('y') if triggerNetwork
	SetZ: (val = 0, triggerNetwork = @INITIALIZE) =>
		@z = math.floor(val)
		@WriteValString('z') if triggerNetwork
	SetColor: (val = RANDOM_COLOR(), triggerNetwork = @INITIALIZE) =>
		@color = color
		@WriteValString('z') if triggerNetwork
	SetPos: (val = Vector(0, 0, 0), triggerNetwork = @INITIALIZE) =>
		@SetX(val.x, triggerNetwork)
		@SetY(val.y, triggerNetwork)
		@SetZ(val.z, triggerNetwork)
	
	GetX: => @x
	GetY: => @y
	GetZ: => @z
	GetColor: => @color
	GetPos: => Vector(@x, @y, @z)
	
	Remove: =>
		@removed = true
		@@NETWORKED_WAYPOINTS[@ID] = nil
		@waypoint\Remove() if @waypoint
		if SERVER and @INITIALIZE
			net.Start(@@NETWORK_STRING_REMOVE)
			net.WriteUInt(@ID, @@NETWORK_ID_LENGTH)
			net.Send(@networkedClients)
	IsValid: => not @removed and @INITIALIZE
	
	Initialize: => @InitPoint()
	Init: => @InitPoint()
	Spawn: => @InitPoint()
	InitPoint: =>
		return if @INITIALIZE or CLIENT
		@INITIALIZE = true
		net.Start(@@NETWORK_STRING)
		net.WriteUInt(@ID, @@NETWORK_ID_LENGTH)
		@WriteData()
		@networkedClients = @@PLAYER_FILTER()
		net.Send(@networkedClients)
	SetName: (val = "%WAYPOINT_NAME_#{@ID}%") =>
		
net.Receive(NetworkedWaypoint.NETWORK_STRING, -> NetworkedWaypoint\NetworkedCreate())
net.Receive(NetworkedWaypoint.NETWORK_STRING_CHANGED, -> NetworkedWaypoint\NetworkedChange())
net.Receive(NetworkedWaypoint.NETWORK_STRING_REMOVE, -> NetworkedWaypoint\NetworkedRemove())
DMaps.NetworkedWaypoint = NetworkedWaypoint
return NetworkedWaypoint