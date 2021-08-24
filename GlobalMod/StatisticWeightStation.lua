--
-- Weight Station with Statistics FS19 Edition
-- by Blacky_BPG
-- 
--
-- Version 1.9.0.3   |	23.08.2021 - fix no player displayed in overview
-- Version 1.9.0.2   |	01.08.2021 - fix wrong display line
-- Version 1.9.0.1   |	17.04.2021 - fix wrong event
-- Version 1.9.0.0   |	16.04.2021 - initial FS19 release
--
-- No script change without my permission
-- 


StatisticWeightStation = {}
StatisticWeightStation.version = "1.9.0.3"
StatisticWeightStation.date = "23.08.2021"
StatisticWeightStation.maxMeasurementTime = 5000
StatisticWeightStation_mt = Class(StatisticWeightStation, Object)
InitObjectClass(StatisticWeightStation, "StatisticWeightStation")

function StatisticWeightStation.onCreate(id)
	local object = StatisticWeightStation:new(g_server ~= nil, g_client ~= nil)
	if object:load(id) then
		g_currentMission:addOnCreateLoadedObject(object)
		g_currentMission:addOnCreateLoadedObjectToSave(object)
		object:register(true)
		table.insert(g_currentMission.updateables, object)
	else
		object:delete()
	end
end

function StatisticWeightStation:new(isServer, isClient, customMt)
	local mt = customMt
	if mt == nil then
		mt = StatisticWeightStation_mt
	end
	local self = Object:new(isServer, isClient, mt)
	return self
end

function StatisticWeightStation:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
		self.triggerId = nil
	end
	if self.nodeId ~= 0 then
		g_currentMission:removeNodeObject(self.nodeId)
	end
	StatisticWeightStation:superClass().delete(self)
end

function StatisticWeightStation:readStream(streamId, connection)
	StatisticWeightStation:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() and self.isEnabled then
		local playerCount = streamReadInt32(streamId)
		if playerCount > 0 then
			for i=1,playerCount do
				self.measurementPlayer[i] = {}
				self.measurementPlayer[i].name = streamReadString(streamId)
				self.measurementPlayer[i].uniqueId = streamReadString(streamId)
				self.measurementPlayer[i].mass = streamReadFloat32(streamId)
				self.measurementPlayer[i].trunksMass = streamReadFloat32(streamId)
				self.measurementPlayer[i].trunksCount = streamReadInt32(streamId)
				self.measurementPlayer[i].fillType = {}
				self.measurementTrunks.mass = self.measurementTrunks.mass + self.measurementPlayer[i].trunksMass
				self.measurementTrunks.count = self.measurementTrunks.count + self.measurementPlayer[i].trunksCount
				if self.measurementPlayer[i].trunksMass > 0 or self.measurementPlayer[i].trunksCount > 0 then
					self.measurementTrunks.player[#self.measurementTrunks.player+1] = {}
					self.measurementTrunks.player[#self.measurementTrunks.player].name = self.measurementPlayer[i].name
					self.measurementTrunks.player[#self.measurementTrunks.player].uniqueId = self.measurementPlayer[i].uniqueId
					self.measurementTrunks.player[#self.measurementTrunks.player].mass = self.measurementPlayer[i].trunksMass
					self.measurementTrunks.player[#self.measurementTrunks.player].count = self.measurementPlayer[i].trunksCount
				end
				for f,g in pairs(g_currentMission.fillTypeManager.fillTypes) do
					self.measurementPlayer[i].fillType[f] = {}
					self.measurementPlayer[i].fillType[f].mass = streamReadFloat32(streamId)
					self.measurementPlayer[i].fillType[f].baleMass = streamReadFloat32(streamId)
					self.measurementPlayer[i].fillType[f].baleCount = streamReadInt32(streamId)
					if self.measurementFillTypes[f] == nil then
						self.measurementFillTypes[f] = {}
						self.measurementFillTypes[f].mass = 0
						self.measurementFillTypes[f].baleMass = 0
						self.measurementFillTypes[f].baleCount = 0
						self.measurementFillTypes[f].player = {}
					end
					self.measurementFillTypes[f].mass = self.measurementFillTypes[f].mass + self.measurementPlayer[i].fillType[f].mass
					self.measurementFillTypes[f].baleMass = self.measurementFillTypes[f].baleMass + self.measurementPlayer[i].fillType[f].baleMass
					self.measurementFillTypes[f].baleCount = self.measurementFillTypes[f].baleCount + self.measurementPlayer[i].fillType[f].baleCount
					if self.measurementPlayer[i].fillType[f].mass > 0 then
						self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player+1] = {}
						self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].name = self.measurementPlayer[i].name
						self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].uniqueId = self.measurementPlayer[i].uniqueId
						self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].mass = self.measurementPlayer[i].fillType[f].mass
					end
					if self.measurementBales[f] == nil then
						self.measurementBales[f] = {}
						self.measurementBales[f].mass = 0
						self.measurementBales[f].count = 0
						self.measurementBales[f].player = {}
					end
					self.measurementBales[f].mass = self.measurementBales[f].mass + self.measurementPlayer[i].fillType[f].baleMass
					self.measurementBales[f].count = self.measurementBales[f].count + self.measurementPlayer[i].fillType[f].baleCount
					if self.measurementPlayer[i].fillType[f].baleMass > 0 or self.measurementPlayer[i].fillType[f].baleCount > 0 then
						self.measurementBales[f].player[#self.measurementBales[f].player+1] = {}
						self.measurementBales[f].player[#self.measurementBales[f].player].name = self.measurementPlayer[i].name
						self.measurementBales[f].player[#self.measurementBales[f].player].uniqueId = self.measurementPlayer[i].uniqueId
						self.measurementBales[f].player[#self.measurementBales[f].player].mass = self.measurementPlayer[i].fillType[f].baleMass
						self.measurementBales[f].player[#self.measurementBales[f].player].count = self.measurementPlayer[i].fillType[f].baleCount
					end
				end
			end
		end
	end
end

function StatisticWeightStation:writeStream(streamId, connection)
	StatisticWeightStation:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() and self.isEnabled then
		streamWriteInt32(streamId, #self.measurementPlayer)
		if #self.measurementPlayer > 0 then
			for i=1,#self.measurementPlayer do
				streamWriteString(streamId, self.measurementPlayer[i].name)
				streamWriteString(streamId, self.measurementPlayer[i].uniqueId)
				streamWriteFloat32(streamId, self.measurementPlayer[i].mass)
				streamWriteFloat32(streamId, self.measurementPlayer[i].trunksMass)
				streamWriteInt32(streamId, self.measurementPlayer[i].trunksCount)
				for f,g in pairs(g_currentMission.fillTypeManager.fillTypes) do
					streamWriteFloat32(streamId, self.measurementPlayer[i].fillType[f].mass)
					streamWriteFloat32(streamId, self.measurementPlayer[i].fillType[f].baleMass)
					streamWriteInt32(streamId, self.measurementPlayer[i].fillType[f].baleCount)
				end
			end
		end
	end
end

function StatisticWeightStation:readUpdateStream(streamId, timestamp, connection)
	StatisticWeightStation:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local access = streamReadBool(streamId)
		if access == false then
			return
		end
		self.currentPlayer = streamReadString(streamId)
		self.currentPlayerId = streamReadString(streamId)
		self.currentMass = streamReadFloat32(streamId)

		self.currentBales = streamReadInt32(streamId)
		self.currentBalesMass = streamReadFloat32(streamId)
		self.currentBaleTypes = streamReadInt32(streamId)
		for i=1,self.currentBaleTypes do
			local baleType = streamReadInt32(streamId)
			self.currentBale[baleType] = {}
			self.currentBale[baleType] = streamReadFloat32(streamId)
			self.currentBaleCount[baleType] = streamReadInt32(streamId)
		end

		self.currentWood = streamReadInt32(streamId)
		self.currentWoodMass = streamReadFloat32(streamId)

		self.currentFillMass = streamReadFloat32(streamId)
		self.currentFillTypes = streamReadInt32(streamId)
		for i=1,self.currentFillTypes do
			local fillType = streamReadInt32(streamId)
			self.currentFill[fillType] = {}
			self.currentFill[fillType] = streamReadFloat32(streamId)
		end

		self.currentVehicleMass = streamReadFloat32(streamId)
	end
end

function StatisticWeightStation:writeUpdateStream(streamId, connection, dirtyMask)
	StatisticWeightStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		if self.currentPlayer == nil then
			streamWriteBool(streamId, false)
			return
		end
		streamWriteBool(streamId, true)
		streamWriteString(streamId, self.currentPlayer)
		streamWriteString(streamId, self.currentPlayerId)
		streamWriteFloat32(streamId, self.currentMass)

		streamWriteInt32(streamId, self.currentBales)
		streamWriteFloat32(streamId, self.currentBalesMass)
		streamWriteInt32(streamId, self.currentBaleTypes)
		for k,v in pairs(self.currentBale) do
			streamWriteInt32(streamId, k)
			streamWriteFloat32(streamId, v)
			streamWriteInt32(streamId, self.currentBaleCount[k])
		end

		streamWriteInt32(streamId, self.currentWood)
		streamWriteFloat32(streamId, self.currentWoodMass)

		streamWriteFloat32(streamId, self.currentFillMass)
		streamWriteInt32(streamId, self.currentFillTypes)
		for k,v in pairs(self.currentFill) do
			streamWriteInt32(streamId, k)
			streamWriteFloat32(streamId, v)
		end

		streamWriteFloat32(streamId, self.currentVehicleMass)
	end
end

function StatisticWeightStation:load(nodeId)
	self.nodeId = nodeId

	local StatisticWeightStationId = getUserAttribute(nodeId, "stationId")
	if StatisticWeightStationId ~= nil then
		self.StatisticWeightStationId = StatisticWeightStationId
	else
		print(" Error: StatisticWeightStation.lua: No stationID assigned for object "..tostring(getName(nodeId))..", weight station can't be saved, we can't create weight station")
		return false
	end
	self.triggerId = nil
	local triggerId = getUserAttribute(nodeId, "triggerIndex")
	if triggerId ~= nil and triggerId ~= "" then
		self.triggerId = I3DUtil.indexToObject(nodeId,triggerId)
	else
		self.triggerId = nodeId
	end
	if self.triggerId ~= nil and getRigidBodyType(self.triggerId) ~= "NoRigidBody" then
		addTrigger(self.triggerId, "triggerCallback", self)
	end
	self.farmLandRestricted = Utils.getNoNil(getUserAttribute(nodeId, "farmLandRestricted"), false)
	self.stationName = getUserAttribute(nodeId, "stationL10N")
	if self.stationName == nil then
        self.stationName = "WeightStation "..tostring(self.StatisticWeightStationId)
	else
        self.stationName = g_i18n:getText(self.stationName)
	end

	self.massDisplays = {}
	local massDisplays = getUserAttribute(nodeId, "massDisplays")
	self.classicDisplays = Utils.getNoNil(getUserAttribute(nodeId, "classicDisplays"), false)
	if massDisplays ~= nil then
		massDisplays = I3DUtil.indexToObject(nodeId, massDisplays)
		local numMassDisplays = getNumOfChildren(massDisplays)
		if numMassDisplays > 0 then
			for id = 0, numMassDisplays - 1 do
				local index = getChildAt(massDisplays, id)
				local factor = Utils.getNoNil(getUserAttribute(index, "weightFactor"), 1)
				if self.classicDisplays then
					local defaultOff = Utils.getNoNil(getUserAttribute(index, "defaultOff"),11)
					local defaultK = Utils.getNoNil(getUserAttribute(index, "defaultK"),15)
					local defaultG = Utils.getNoNil(getUserAttribute(index, "defaultG"),14)
					local defaultMinus = Utils.getNoNil(getUserAttribute(index, "defaultMinus"),13)
					local defaultE = Utils.getNoNil(getUserAttribute(index, "defaultE"),12)
					local maxDigits = Utils.getNoNil(getUserAttribute(index, "maxDigits"),5)
					table.insert(self.massDisplays, {index = index, classic = self.classicDisplays, maxDigits = maxDigits, factor = factor, posMinus = defaultMinus, posE = defaultE, posG = defaultG, posK = defaultK, posOff = defaultOff})
					self.massDisplays[#self.massDisplays].digits = {}
					local digits = {}
					for i=0, maxDigits-1 do
						digits[i] = getChild(index,"digit"..tostring(i))
						self.massDisplays[#self.massDisplays].digits[i+1] = digits[i]
					end
					self.massDisplays[#self.massDisplays].digitK = getChild(index,"digitK")
					self.massDisplays[#self.massDisplays].digitG = getChild(index,"digitG")
					self.massDisplays[#self.massDisplays].digitOff = getChild(index,"digitOff")
				else
					local withZeros = Utils.getNoNil(getUserAttribute(index, "withZeros"), false)
					table.insert(self.massDisplays, {index = index, classic = self.classicDisplays, withZeros = withZeros, factor = factor})
				end
			end
		end
	end
	self.lastDisplayWeight = -1
	self:updateMassDisplays(0,nil)

	local weightLights = getUserAttribute(nodeId, "weightLights")
	if weightLights ~= nil then
		weightLights = I3DUtil.indexToObject(nodeId, weightLights)
		local numLights = getNumOfChildren(weightLights)
		if numLights > 0 then
			self.weightLights = {}
			for id = 0, numLights - 1 do
				local index = getChildAt(weightLights, id)
				local redLight = Utils.getNoNil(getUserAttribute(index, "redLight"), true)
				local intensity = getUserAttribute(index, "intensity")
				if intensity ~= nil and getHasShaderParameter(index, "lightControl") then
					local _, y, z, w = getShaderParameter(index, "lightControl")
					if redLight then
						setShaderParameter(index, "lightControl", 0, y, z, w, false)
					else
						setShaderParameter(index, "lightControl", intensity, y, z, w, false)
					end
				else
					setVisibility(index, not redLight)
				end
				table.insert(self.weightLights, {index = index, redLight = redLight, intensity = intensity})
			end
		end
	end
	self.lastLightState = 0

	self.massUpper = 0
	self.massLower = 0
	self.measurementTime = 0
	self.triggerObjectFarmId = 0
	self.triggerObjects = {}

	-- current Measurement
	self.currentMass = 0
	self.currentPlayer = nil
	self.currentPlayerId = nil
	self.currentBale = {}
	self.currentBaleTypes = 0
	self.currentBaleCount = {}
	self.currentBales = 0
	self.currentBalesMass = 0
	self.currentWood = 0
	self.currentWoodMass = 0
	self.currentFill = {}
	self.currentFillTypes = 0
	self.currentFillMass = 0
	self.currentVehicleMass = 0
	self.massSaved = false
	self.lastUpdatedWeight = 0

	-- all saved Measurement
	self.measurementPlayer = {}
	self.measurementFillTypes = {}
	self.measurementBales = {}
	for k,v in pairs(g_currentMission.fillTypeManager.fillTypes) do
		self.measurementFillTypes[k] = {}
		self.measurementFillTypes[k].mass = 0
		self.measurementFillTypes[k].baleMass = 0
		self.measurementFillTypes[k].baleCount = 0
		self.measurementFillTypes[k].player = {}
		self.measurementBales[k] = {}
		self.measurementBales[k].mass = 0
		self.measurementBales[k].count = 0
		self.measurementBales[k].player = {}
	end
	self.measurementTrunks = {}
	self.measurementTrunks.mass = 0
	self.measurementTrunks.count = 0
	self.measurementTrunks.player = {}

	self.saveId = "StatisticWeightStation_"..tostring(self.StatisticWeightStationId)

	self.numTriggerobjects = 0
	self.triggerIsAdded = false
	self.isEnabled = true
	self.localPlayer = nil

	self.StatisticWeightStationDirtyFlag = self:getNextDirtyFlag()

	return true
end

function StatisticWeightStation:update(dt)
	StatisticWeightStation:superClass().update(self, dt)
	if not self.isEnabled then
		return
	end
	if g_currentMission == nil then
		return
	end
	if not self.triggerIsAdded then
		if g_currentMission.StatisticWeightStations == nil then
			g_currentMission.StatisticWeightStations = {}
		end
		if #g_currentMission.StatisticWeightStations > 0 then
			for i=1, #g_currentMission.StatisticWeightStations do
				if g_currentMission.StatisticWeightStations[i] ~= nil and g_currentMission.StatisticWeightStations[i].saveId == self.saveId then
					print(" Error: StatisticWeightStation ID-"..tostring(self.StatisticWeightStationId).."(current object name: "..tostring(getName(self.nodeId))..") already registered on object: "..tostring(getName(g_currentMission.StatisticWeightStations[self.StatisticWeightStationId].nodeId)).."! Old entry will be overwriten")
					g_currentMission.StatisticWeightStations[self.StatisticWeightStationId].isEnabled = false
					return
				end
			end
		end
		g_currentMission.StatisticWeightStations[#g_currentMission.StatisticWeightStations+1] = self
		self.triggerIsAdded = true
	end
	if self.localPlayer == nil and g_currentMission.player ~= nil and g_currentMission.player.visualInformation ~= nil then
		self.localPlayer = g_currentMission.player.visualInformation.playerName
	end

	self:updateWeightLights()

	if self.numTriggerobjects > 0 then
		if self.isServer or g_server ~= nil then
			self:updateWeight()
		end
		if self.currentMass > 0 then
			local lastSpeed = nil
			for object, entrys in pairs (self.triggerObjects) do
				if entrys.isVehicle and object.components ~= nil then
					lastSpeed = self:getLastSpeed(object, true)
					if self.isServer or g_server ~= nil then
						if self.currentPlayerId == nil then
							local playerName = self:getControllerName(object,true)
							for i=1, #g_currentMission.userManager.users do
								if playerName == g_currentMission.userManager.users[i].nickname then
									self.currentPlayer = playerName
									self.currentPlayerId = g_currentMission.userManager.users[i].uniqueUserId
								end
							end
						end
					end
				end
			end
			if self.currentPlayerId ~= nil then
				if lastSpeed ~= nil then
					if lastSpeed < 1 then
						lastSpeed = math.max(0,math.floor(lastSpeed))
					end
					self.massUpper = self.currentMass * math.min(1.5,(1+(lastSpeed/10)))
					self.massLower = self.currentFillMass * math.max(0.5,(1-(lastSpeed/10)))
					local weight = math.random(self.massLower, self.massUpper)
					local maxTime = StatisticWeightStation.maxMeasurementTime
					if not self.isServer and self.isClient then
						maxTime = maxTime * 1.5
					end
					if self.measurementTime < maxTime then
						self.measurementTime = self.measurementTime + dt
					end
					if lastSpeed > 0 then
						if self.measurementTime >= 200 then
							self.measurementTime = 0
							self:updateMassDisplays(weight,nil)
						end
					else
						local timer = (1/maxTime*self.measurementTime)
						if self.measurementTime < maxTime then
							-- self.massUpper = self.currentMass * (1.25-(timer/4))
							self.massUpper = math.max(self.currentFillMass,self.currentMass - ((self.currentMass-self.currentFillMass)/maxTime*self.measurementTime))
							-- self.massLower = self.currentMass * (0.75+(timer/4))
							self.massLower = self.currentFillMass
							weight = math.random(self.massLower, self.massUpper)
							self:updateMassDisplays(weight,nil)
							if self.localPlayer == self.currentPlayer then
								local timerString = tostring(math.floor((maxTime-self.measurementTime)/1000))
								g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_measurement"),timerString), 750)
							end
						else
							if self.measurementTime > maxTime then
								if self.localPlayer == self.currentPlayer then
									g_currentMission:showBlinkingWarning(g_i18n:getText("warning_measurementReady"), 3000)
								end
								self.measurementTime = maxTime
							end
							if self.classicDisplays then
								self:updateMassDisplays(self.currentMass,1)
								self:updateMassDisplays(self.currentFillMass,2)
							else
								self:updateMassDisplays(self.currentFillMass,nil)
							end
							self:saveWeights()
						end
					end
				end
			end
		end
	else
		self.measurementTime = 0
		self.currentMass = 0
		self.currentPlayer = nil
		self.currentPlayerId = nil
		self.currentBale = {}
		self.currentBaleCount = {}
		self.currentBaleTypes = 0
		self.currentBales = 0
		self.currentBalesMass = 0
		self.currentWood = 0
		self.currentWoodMass = 0
		self.currentFill = {}
		self.currentFillTypes = 0
		self.currentFillMass = 0
		self.currentVehicleMass = 0
		self.massSaved = false
		self:updateMassDisplays(0,nil)
	end
end

function StatisticWeightStation:updateTick(dt) end

function StatisticWeightStation:updateWeightLights()
	if self.lastLightState == self.numTriggerobjects then
		return
	end 
    if self.weightLights ~= nil then
		self.lastLightState = self.numTriggerobjects
        for i = 1, #self.weightLights do
            local light = self.weightLights[i]
            if self.numTriggerobjects > 0 then
                if light.intensity == nil then
                    setVisibility(light.index, light.redLight)
                else
                    local _, y, z, w = getShaderParameter(light.index, "lightControl")
                    if light.redLight then
                        setShaderParameter(light.index, "lightControl", light.intensity, y, z, w, false)
                    else
                        setShaderParameter(light.index, "lightControl", 0, y, z, w, false)
                    end
                end
            else
                if light.intensity == nil then
                    setVisibility(light.index, not light.redLight)
                else
                    local _, y, z, w = getShaderParameter(light.index, "lightControl")
                    if light.redLight then
                        setShaderParameter(light.index, "lightControl", 0, y, z, w, false)
                    else
                        setShaderParameter(light.index, "lightControl", light.intensity, y, z, w, false)
                    end
                end
            end
        end
    end
end

function StatisticWeightStation:updateMassDisplays(totalWeight, display)
	if self.lastDisplayWeight == totalWeight then
		return
	end
	self.lastDisplayWeight = totalWeight
	if display ~= nil and type(display) == "number" and #self.massDisplays > 0 and self.massDisplays[display] ~= nil then
		local weightDisplay = self.massDisplays[display]
		if not weightDisplay.classic then
			I3DUtil.setNumberShaderByValue(weightDisplay.index, totalWeight * weightDisplay.factor, 0, weightDisplay.withZeros)
		else
			local maxWeight = weightDisplay.maxDigits ^ 10
			setShaderParameter(weightDisplay.digitOff, "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
			if totalWeight >= maxWeight then
				setShaderParameter(weightDisplay.digitG, "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
				setShaderParameter(weightDisplay.digitK, "number", tonumber(weightDisplay.posE), 0, 0, 0, false)
				for i=1, weightDisplay.maxDigits do
					setShaderParameter(weightDisplay.digits[i], "number", tonumber(weightDisplay.posMinus), 0, 0, 0, false)
				end
			else
				setShaderParameter(weightDisplay.digitG, "number", tonumber(weightDisplay.posG), 0, 0, 0, false)
				setShaderParameter(weightDisplay.digitK, "number", tonumber(weightDisplay.posK), 0, 0, 0, false)
				local shaderNum = ""
				for i=1, weightDisplay.maxDigits do
					local number = math.floor(totalWeight - (math.floor(totalWeight / 10) * 10))
					totalWeight = math.floor(totalWeight / 10)
					if number <= 0 and totalWeight <= 0 then
						setShaderParameter(weightDisplay.digits[i], "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
					else
						setShaderParameter(weightDisplay.digits[i], "number", number, 0, 0, 0, false)
					end
				end
			end
		end
	elseif #self.massDisplays > 0 then
		for i=1, #self.massDisplays do
			local weightDisplay = self.massDisplays[i]
			if not weightDisplay.classic then
				I3DUtil.setNumberShaderByValue(weightDisplay.index, totalWeight * weightDisplay.factor, 0, weightDisplay.withZeros)
			else
				local maxWeight = weightDisplay.maxDigits ^ 10
				setShaderParameter(weightDisplay.digitOff, "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
				if totalWeight >= maxWeight then
					setShaderParameter(weightDisplay.digitG, "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
					setShaderParameter(weightDisplay.digitK, "number", tonumber(weightDisplay.posE), 0, 0, 0, false)
					for i=1, weightDisplay.maxDigits do
						setShaderParameter(weightDisplay.digits[i], "number", tonumber(weightDisplay.posMinus), 0, 0, 0, false)
					end
				else
					setShaderParameter(weightDisplay.digitG, "number", tonumber(weightDisplay.posG), 0, 0, 0, false)
					setShaderParameter(weightDisplay.digitK, "number", tonumber(weightDisplay.posK), 0, 0, 0, false)
					for i=1, weightDisplay.maxDigits do
						local number = math.floor(totalWeight - (math.floor(totalWeight / 10) * 10))
						totalWeight = math.floor(totalWeight / 10)
						if number <= 0 and totalWeight <= 0 then
							setShaderParameter(weightDisplay.digits[i], "number", tonumber(weightDisplay.posOff), 0, 0, 0, false)
						else
							setShaderParameter(weightDisplay.digits[i], "number", number, 0, 0, 0, false)
						end
					end
				end
			end
		end
	end
end

function StatisticWeightStation:saveToXMLFile(xmlFile, key, usedModNames)
	if self.isEnabled then
		setXMLInt(xmlFile, key.."#numPlayers", #self.measurementPlayer)
		for i=1, #self.measurementPlayer do
			setXMLString(xmlFile, key..".player"..tostring(i).."#name", tostring(self.measurementPlayer[i].name))
			setXMLString(xmlFile, key..".player"..tostring(i).."#uniqueId", tostring(self.measurementPlayer[i].uniqueId))
			setXMLFloat(xmlFile, key..".player"..tostring(i).."#mass", self.measurementPlayer[i].mass)
			setXMLFloat(xmlFile, key..".player"..tostring(i).."#trunksMass", self.measurementPlayer[i].trunksMass)
			setXMLInt(xmlFile, key..".player"..tostring(i).."#trunksCount", self.measurementPlayer[i].trunksCount)
			for f,g in pairs(g_currentMission.fillTypeManager.fillTypes) do
				if self.measurementPlayer[i].fillType[f].mass > 0 or self.measurementPlayer[i].fillType[f].baleMass > 0 or self.measurementPlayer[i].fillType[f].baleCount > 0 then
					setXMLFloat(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#mass", self.measurementPlayer[i].fillType[f].mass)
					setXMLFloat(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#baleMass", self.measurementPlayer[i].fillType[f].baleMass)
					setXMLInt(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#baleCount", self.measurementPlayer[i].fillType[f].baleCount)
				end
			end
		end
	end
end

function StatisticWeightStation:loadFromXMLFile(xmlFile, key)
	if not self.isEnabled then
		return true
	end
	local playerCount = Utils.getNoNil(getXMLInt(xmlFile, key .. "#numPlayers"),0)
	if playerCount > 0 then
		for i=1,playerCount do
			self.measurementPlayer[i] = {}
			self.measurementPlayer[i].fillType = {}
			self.measurementPlayer[i].name = getXMLString(xmlFile, key..".player"..tostring(i).."#name")
			self.measurementPlayer[i].uniqueId = getXMLString(xmlFile, key..".player"..tostring(i).."#uniqueId")
			self.measurementPlayer[i].mass = getXMLFloat(xmlFile, key..".player"..tostring(i).."#mass")
			self.measurementPlayer[i].trunksMass = getXMLFloat(xmlFile, key..".player"..tostring(i).."#trunksMass")
			self.measurementPlayer[i].trunksCount = getXMLFloat(xmlFile, key..".player"..tostring(i).."#trunksCount")
			self.measurementTrunks.mass = self.measurementTrunks.mass + self.measurementPlayer[i].trunksMass
			self.measurementTrunks.count = self.measurementTrunks.count + self.measurementPlayer[i].trunksCount
			if self.measurementPlayer[i].trunksMass > 0 or self.measurementPlayer[i].trunksCount > 0 then
				self.measurementTrunks.player[#self.measurementTrunks.player+1] = {}
				self.measurementTrunks.player[#self.measurementTrunks.player].name = self.measurementPlayer[i].name
				self.measurementTrunks.player[#self.measurementTrunks.player].uniqueId = self.measurementPlayer[i].uniqueId
				self.measurementTrunks.player[#self.measurementTrunks.player].mass = self.measurementPlayer[i].mass
				self.measurementTrunks.player[#self.measurementTrunks.player].count = self.measurementPlayer[i].trunksCount
			end
			for f,g in pairs(g_currentMission.fillTypeManager.fillTypes) do
				self.measurementPlayer[i].fillType[f] = {}
				self.measurementPlayer[i].fillType[f].mass = 0
				self.measurementPlayer[i].fillType[f].baleMass = 0
				self.measurementPlayer[i].fillType[f].baleCount = 0
				if hasXMLProperty(xmlFile,key..".player"..tostring(i)..".fillTypes."..tostring(g.name)) then
					self.measurementPlayer[i].fillType[f].mass = getXMLFloat(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#mass")
					self.measurementPlayer[i].fillType[f].baleMass = getXMLFloat(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#baleMass")
					self.measurementPlayer[i].fillType[f].baleCount = getXMLInt(xmlFile, key..".player"..tostring(i)..".fillTypes."..tostring(g.name).."#baleCount")
				end
				if self.measurementFillTypes[f] == nil then
					self.measurementFillTypes[f] = {}
					self.measurementFillTypes[f].mass = 0
					self.measurementFillTypes[f].baleMass = 0
					self.measurementFillTypes[f].baleCount = 0
					self.measurementFillTypes[f].player = {}
				end
				self.measurementFillTypes[f].mass = self.measurementFillTypes[f].mass + self.measurementPlayer[i].fillType[f].mass
				self.measurementFillTypes[f].baleMass = self.measurementFillTypes[f].baleMass + self.measurementPlayer[i].fillType[f].baleMass
				self.measurementFillTypes[f].baleCount = self.measurementFillTypes[f].baleCount + self.measurementPlayer[i].fillType[f].baleCount
				if self.measurementPlayer[i].fillType[f].mass > 0 then
					self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player+1] = {}
					self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].name = self.measurementPlayer[i].name
					self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].uniqueId = self.measurementPlayer[i].uniqueId
					self.measurementFillTypes[f].player[#self.measurementFillTypes[f].player].mass = self.measurementPlayer[i].fillType[f].mass
				end
				if self.measurementBales[f] == nil then
					self.measurementBales[f] = {}
					self.measurementBales[f].mass = 0
					self.measurementBales[f].count = 0
					self.measurementBales[f].player = {}
				end
				self.measurementBales[f].mass = self.measurementBales[f].mass + self.measurementPlayer[i].fillType[f].baleMass
				self.measurementBales[f].count = self.measurementBales[f].count + self.measurementPlayer[i].fillType[f].baleCount
				if self.measurementPlayer[i].fillType[f].baleMass > 0 or self.measurementPlayer[i].fillType[f].baleCount > 0 then
					self.measurementBales[f].player[#self.measurementBales[f].player+1] = {}
					self.measurementBales[f].player[#self.measurementBales[f].player].name = self.measurementPlayer[i].name
					self.measurementBales[f].player[#self.measurementBales[f].player].uniqueId = self.measurementPlayer[i].uniqueId
					self.measurementBales[f].player[#self.measurementBales[f].player].mass = self.measurementPlayer[i].fillType[f].baleMass
					self.measurementBales[f].player[#self.measurementBales[f].player].count = self.measurementPlayer[i].fillType[f].baleCount
				end
			end
		end
	end
	return true
end

function StatisticWeightStation:getControllerName(vehicle, checkAttacherVehicle)
	if vehicle ~= nil then
		if vehicle.spec_enterable ~= nil then
			return vehicle:getControllerName()
		elseif checkAttacherVehicle ~= nil and checkAttacherVehicle == true then
			if vehicle.attacherVehicle ~= nil then
				return self:getControllenName(vehicle.attacherVehicle, true)
			end
		end
	end
	return nil
end

function StatisticWeightStation:getLastSpeed(vehicle, checkAttacherVehicle)
	if vehicle ~= nil then
		if vehicle.getLastSpeed ~= nil then
			return vehicle:getLastSpeed(true)
		elseif checkAttacherVehicle ~= nil and checkAttacherVehicle == true then
			if vehicle.attacherVehicle ~= nil then
				return self:getLastSpeed(vehicle.attacherVehicle, true)
			end
		end
	end
	return nil
end

function StatisticWeightStation:getFieldOwnership(triggerObjectFarmId)
	if self.farmLandRestricted then
		local x,_,z = getWorldTranslation(self.nodeId)
		local ownerFarmId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
		local farmId = 0
		if ownerFarmId ~= nil then
			farmId = g_farmlandManager:getFarmlandOwner(ownerFarmId)
		end
		if ownerFarmId == nil or g_currentMission.accessHandler:canFarmAccessOtherId(farmId, triggerObjectFarmId) then
			return true
		end
	else
		return true
	end
	return false
end

function StatisticWeightStation:keyEvent(unicode, sym, modifier, isDown) end

function StatisticWeightStation:mouseEvent(posX, posY, isDown, isUp, button) end

function StatisticWeightStation:saveWeights()
	if self.massSaved then
		return
	end
	local playerFound = false
	if #self.measurementPlayer > 0 then
		for i=1, #self.measurementPlayer do
			if self.measurementPlayer[i].uniqueId == self.currentPlayerId and playerFound == false then
				playerFound = true
				self.measurementPlayer[i].mass = self.measurementPlayer[i].mass + self.currentWoodMass
				self.measurementPlayer[i].trunksMass = self.measurementPlayer[i].trunksMass + self.currentWoodMass
				self.measurementPlayer[i].trunksCount = self.measurementPlayer[i].trunksCount + self.currentWood
				if self.measurementTrunks.player[i] == nil then
					self.measurementTrunks.player[i] = {}
					self.measurementTrunks.player[i].mass = 0
					self.measurementTrunks.player[i].count = 0
				end
				self.measurementTrunks.player[i].mass = self.measurementTrunks.player[i].mass + self.currentWoodMass
				self.measurementTrunks.player[i].count = self.measurementTrunks.player[i].count + self.currentWood
				self.measurementTrunks.mass = self.measurementTrunks.mass + self.currentWoodMass
				self.measurementTrunks.count = self.measurementTrunks.count + self.currentWood
				for f, mass in pairs(self.currentFill) do
					if mass > 0 then
						self.measurementPlayer[i].fillType[f].mass = self.measurementPlayer[i].fillType[f].mass + mass
						self.measurementPlayer[i].mass = self.measurementPlayer[i].mass + mass
						self.measurementFillTypes[f].mass = self.measurementFillTypes[f].mass + mass
						if self.measurementFillTypes[f].player[i] == nil then
							self.measurementFillTypes[f].player[i] = {}
							self.measurementFillTypes[f].player[i].name = self.currentPlayer
							self.measurementFillTypes[f].player[i].uniqueId = self.currentPlayerId
							self.measurementFillTypes[f].player[i].mass = 0
						end
						self.measurementFillTypes[f].player[i].mass = self.measurementFillTypes[f].player[i].mass + mass
						if self.currentBale[fillType] ~= nil then
							self.measurementPlayer[i].fillType[f].baleMass = self.measurementPlayer[i].fillType[f].baleMass + self.currentBale[fillType]
							self.measurementPlayer[i].fillType[f].baleCount = self.measurementPlayer[i].fillType[f].baleCount + self.currentBaleCount[fillType]
							self.measurementBales[f].mass = self.measurementBales[f].mass + self.currentBale[fillType]
							self.measurementBales[f].count = self.measurementBales[f].count + self.currentBaleCount[fillType]
							if self.measurementBales[f].player[i] == nil then
								self.measurementBales[f].player[i] = {}
								self.measurementBales[f].player[i].name = self.currentPlayer
								self.measurementBales[f].player[i].uniqueId = self.currentPlayerId
								self.measurementBales[f].player[i].mass = 0
								self.measurementBales[f].player[i].count = 0
							end
							self.measurementBales[f].player[i].mass = self.measurementBales[f].player[i].mass + self.currentBale[fillType]
							self.measurementBales[f].player[i].count = self.measurementBales[f].player[i].count + self.currentBaleCount[fillType]
							self.measurementFillTypes[f].baleMass = self.measurementFillTypes[f].baleMass + self.currentBale[fillType]
							self.measurementFillTypes[f].baleCount = self.measurementFillTypes[f].baleCount + self.currentBaleCount[fillType]
						end
					end
				end
			end
		end
	end
	if playerFound == false then
		local i = #self.measurementPlayer + 1
		if self.measurementPlayer[i] == nil then
			self.measurementPlayer[i] = {}
			self.measurementPlayer[i].name = self.currentPlayer
			self.measurementPlayer[i].uniqueId = self.currentPlayerId
			self.measurementPlayer[i].mass = 0
			self.measurementPlayer[i].trunksMass = self.currentWoodMass
			self.measurementPlayer[i].trunksCount = self.currentWood
			self.measurementPlayer[i].fillType = {}
			self.measurementTrunks.player[i] = {}
			self.measurementTrunks.player[i].name = self.currentPlayer
			self.measurementTrunks.player[i].uniqueId = self.currentPlayerId
			self.measurementTrunks.player[i].mass = self.currentWoodMass
			self.measurementTrunks.player[i].count = self.currentWood
			self.measurementTrunks.mass = self.measurementTrunks.mass + self.currentWoodMass
			self.measurementTrunks.count = self.measurementTrunks.count + self.currentWood
			for k,v in pairs(g_currentMission.fillTypeManager.fillTypes) do
				self.measurementPlayer[i].fillType[k] = {}
				self.measurementPlayer[i].fillType[k].mass = 0
				self.measurementPlayer[i].fillType[k].baleMass = 0
				self.measurementPlayer[i].fillType[k].baleCount = 0
			end
			for f, mass in pairs(self.currentFill) do
				if mass > 0 then
					self.measurementPlayer[i].fillType[f].mass = self.measurementPlayer[i].fillType[f].mass + mass
					self.measurementPlayer[i].mass = self.measurementPlayer[i].mass + mass
					self.measurementFillTypes[f].mass = self.measurementFillTypes[f].mass + mass
					if self.measurementFillTypes[f].player[i] == nil then
						self.measurementFillTypes[f].player[i] = {}
						self.measurementFillTypes[f].player[i].name = self.currentPlayer
						self.measurementFillTypes[f].player[i].uniqueId = self.currentPlayerId
						self.measurementFillTypes[f].player[i].mass = 0
					end
					self.measurementFillTypes[f].player[i].mass = self.measurementFillTypes[f].player[i].mass + mass
					if self.currentBale[fillType] ~= nil then
						self.measurementPlayer[i].fillType[f].baleMass = self.measurementPlayer[i].fillType[f].baleMass + self.currentBale[fillType]
						self.measurementPlayer[i].fillType[f].baleCount = self.measurementPlayer[i].fillType[f].baleCount + self.currentBaleCount[fillType]
						self.measurementBales[f].mass = self.measurementBales[f].mass + self.currentBale[fillType]
						self.measurementBales[f].count = self.measurementBales[f].count + self.currentBaleCount[fillType]
						if self.measurementBales[f].player[i] == nil then
							self.measurementBales[f].player[i] = {}
							self.measurementBales[f].player[i].name = self.currentPlayer
							self.measurementBales[f].player[i].uniqueId = self.currentPlayerId
							self.measurementBales[f].player[i].mass = 0
							self.measurementBales[f].player[i].count = 0
						end
						self.measurementBales[f].player[i].mass = self.measurementBales[f].player[i].mass + self.currentBale[fillType]
						self.measurementBales[f].player[i].count = self.measurementBales[f].player[i].count + self.currentBaleCount[fillType]
						self.measurementFillTypes[f].baleMass = self.measurementFillTypes[f].baleMass + self.currentBale[fillType]
						self.measurementFillTypes[f].baleCount = self.measurementFillTypes[f].baleCount + self.currentBaleCount[fillType]
					end
				end
			end
		end
	end
	self.massSaved = true
end

function StatisticWeightStation:updateWeight()
	self.currentMass = 0
	-- self.currentPlayer = nil
	-- self.currentPlayerId = nil
	self.currentBale = {}
	self.currentBaleTypes = 0
	self.currentBaleCount = {}
	self.currentBales = 0
	self.currentBalesMass = 0
	self.currentWood = 0
	self.currentWoodMass = 0
	self.currentFill = {}
	self.currentFillTypes = 0
	self.currentFillMass = 0
	self.currentVehicleMass = 0
	for object, entrys in pairs (self.triggerObjects) do
		if entrys.isVehicle and object.components ~= nil then
			for _, component in pairs(object.components) do
				self.currentMass = self.currentMass + (component.mass*1000)
				self.currentVehicleMass = self.currentVehicleMass + (component.mass*1000)
			end
			if object.spec_wheels ~= nil then
				for _, wheel in pairs(object.spec_wheels.wheels) do
					self.currentMass = self.currentMass + (wheel.mass*1000)
					self.currentVehicleMass = self.currentVehicleMass + (wheel.mass*1000)
				end
			end
			if object.getFillUnits ~= nil then 
				for k, _ in ipairs(object:getFillUnits()) do
					local fillLevel = object:getFillUnitFillLevel(k)
					if fillLevel > 0 then
						local fillTypeIndex = object:getFillUnitFillType(k)
						if fillTypeIndex ~= nil then
							local fillType = g_currentMission.fillTypeManager:getFillTypeByIndex(fillTypeIndex)
							if fillType ~= nil and fillType.name ~= "ELECTRICCHARGE" and fillType.name ~= "UNKNOWN" and fillType.name ~= "AIR" and fillType.name ~= "DEF" and fillType.name ~= "DIESEL" then
								if self.currentFill[fillTypeIndex] == nil then
									self.currentFill[fillTypeIndex] = ((fillLevel * fillType.massPerLiter)*1000)
									self.currentFillTypes = self.currentFillTypes + 1
								else
									self.currentFill[fillTypeIndex] = self.currentFill[fillTypeIndex] + ((fillLevel * fillType.massPerLiter)*1000)
								end
								self.currentFillMass = self.currentFillMass + ((fillLevel * fillType.massPerLiter)*1000)
							end
						end
					end
				end
			end
		else
			local mass = (getMass(object)*1000)
			self.currentMass = self.currentMass + mass
			if entrys.isWood then
				self.currentWood = self.currentWood + 1
				self.currentWoodMass = self.currentWoodMass + mass
			elseif entrys.isBale then
				self.currentBales = self.currentBales + 1
				if object.getFillType ~= nil and object:getFillType() ~= FillType.UNKNOWN then
					local fillType = object:getFillType()
					if self.currentBale[fillType] == nil then
						self.currentBale[fillType] = mass
						self.currentBaleCount[fillType] = 1
						self.currentBaleTypes = self.currentBaleTypes + 1
					else
						self.currentBale[fillType] = self.currentBale[fillType] + mass
						self.currentBaleCount[fillType] = self.currentBaleCount[fillType] + 1
					end
					if self.currentFill[fillType] == nil then
						self.currentFill[fillType] = mass
						self.currentFillTypes = self.currentFillTypes + 1
					else
						self.currentFill[fillType] = self.currentFill[fillType] + mass
					end
				end
				self.currentBalesMass = self.currentBalesMass + mass
			elseif object.getFillUnits ~= nil then 
				for k, _ in ipairs(object:getFillUnits()) do
					local fillLevel = object:getFillUnitFillLevel(k)
					if fillLevel > 0 then
						local fillTypeIndex = object:getFillUnitFillType(k)
						if fillTypeIndex ~= nil then
							local fillType = g_currentMission.fillTypeManager:getFillTypeByIndex(fillTypeIndex)
							if fillType ~= nil then
								if self.currentFill[fillTypeIndex] == nil then
									self.currentFill[fillTypeIndex] = ((fillLevel * fillType.massPerLiter)*1000)
									self.currentFillTypes = self.currentFillTypes + 1
								else
									self.currentFill[fillTypeIndex] = self.currentFill[fillTypeIndex] + ((fillLevel * fillType.massPerLiter)*1000)
								end
							end
						end
					end
				end
			end
		end
	end

	if self.lastUpdatedWeight ~= self.currentMass then
		if self.isServer or g_server ~= nil then
			self:raiseDirtyFlags(self.StatisticWeightStationDirtyFlag)
		end
	end

	self.lastUpdatedWeight = self.currentMass
end

function StatisticWeightStation:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, valOpt)
	if g_currentMission ~= nil and self.isEnabled and (onEnter or onLeave) then
		if self.numTriggerobjects > 0 then
			for i, object in pairs (self.triggerObjects) do
				if not entityExists(object.otherId) then
					self.triggerObjects[i] = nil
					self.numTriggerobjects = math.max(0, self.numTriggerobjects-1)
				end
			end
		end
		local object = nil
		local isVehicle = false
		local isWood = false
		local isBale = false
		local objectId = g_currentMission.nodeToObject[otherId]

		if objectId ~= nil then
			if objectId.components ~= nil then
				isVehicle = true
				object = objectId
			else
				if objectId.isa ~= nil and objectId:isa(Bale) then
					isBale = true
					object = objectId
				end
			end
		elseif getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
			isWood = true
			object = otherId
		end

		if object ~= nil then
			if onEnter then
				if self.triggerObjects[object] == nil then
					self.triggerObjects[object] = {otherId = otherId, isVehicle = isVehicle, isBale = isBale, isWood = isWood, numEnter = 1}
					self.numTriggerobjects = self.numTriggerobjects + 1
				else
					self.triggerObjects[object].numEnter = self.triggerObjects[object].numEnter + 1
				end
			else
				if self.triggerObjects[object] ~= nil then
					self.triggerObjects[object].numEnter = self.triggerObjects[object].numEnter - 1
					if self.triggerObjects[object].numEnter <= 0 then
						self.triggerObjects[object] = nil
						self.numTriggerobjects = math.max(self.numTriggerobjects - 1, 0)
					end
				end
			end
		end
	end
end

g_onCreateUtil.addOnCreateFunction("StatisticWeightStation", StatisticWeightStation.onCreate)

print(" ++ loading StatisticWeightStation V "..tostring(StatisticWeightStation.version).." - "..tostring(StatisticWeightStation.date).." (by Blacky_BPG)")


--
-- Weight Station with Statistics FS19 Edition
-- by Blacky_BPG
-- 
--
-- Version 1.9.0.3   |	23.08.2021 - fix no player displayed in overview
-- Version 1.9.0.2   |	01.08.2021 - fix wrong display line
-- Version 1.9.0.1   |	17.04.2021 - fix wrong event
-- Version 1.9.0.0   |	16.04.2021 - 
--
-- No script change without my permission
-- 


StatisticWeightStationOverview = {}
StatisticWeightStationOverview.version = "1.9.0.3"
StatisticWeightStationOverview.date = "23.08.2021"
StatisticWeightStationOverview.keyId = nil
StatisticWeightStationOverview.directory = g_currentModDirectory

function StatisticWeightStationOverview:deleteMap() end

function StatisticWeightStationOverview:loadMap(name)

	self.overlayFile = createImageOverlay(Utils.getFilename("textures/overlayBack.dds", self.directory))
	self.overlaySmallFile = Utils.getFilename("textures/overlayBackSmall.dds", self.directory)
	self.buttonBlackFile = Utils.getFilename("textures/overlayButton.dds", self.directory)
	self.buttonBlueFile = Utils.getFilename("textures/overlayButtonBlue.dds", self.directory)
	self.buttonGreenFile = Utils.getFilename("textures/overlayButtonGreen.dds", self.directory)
	self.buttonRedFile = Utils.getFilename("textures/overlayButtonRed.dds", self.directory)
	self.buttonYellowFile = Utils.getFilename("textures/overlayButtonYellow.dds", self.directory)
	self.lineBlackFile = Utils.getFilename("textures/overlayLineBlack.dds", self.directory)
	self.lineGreyFile = Utils.getFilename("textures/overlayLineGrey.dds", self.directory)
	self.lineTurquisFile = Utils.getFilename("textures/overlayLineTurquis.dds", self.directory)

	self.xPos = 0
	self.yPos = 0
	self.xPosOld = 0
	self.yPosOld = 0
	
	self.buttonsWidth, self.buttonsHeight = getNormalizedScreenValues(275, 35)
	self.buttonTextSize = 0.008443*g_screenAspectRatio
	self.buttonColorUse = {r=0,g=0,b=0,a=1}
	self.buttonColorStd = {r=1,g=1,b=1,a=1}
	self.buttonColorLine = {r=1,g=0.9,b=0.5,a=1}
	self.buttonColorA = {r=1,g=0.7,b=0.4,a=1}
	self.buttonColorB = {r=0.6,g=0.85,b=1,a=1}
	self.buttonColorC = {r=0.25,g=1,b=0.25,a=1}
	self.buttonColorD = {r=0.6,g=1,b=0.3,a=1}
	self.buttonsStartY = 0.898
	self.buttonsLeftX = 0.07
	self.buttonsLeft = {}
	self.buttonsLeftState = 0
	self.buttonsTopX = 0.1
	self.buttonsTop = {}
	self.buttonsTopState = 0

	self.lineWidth, self.lineHeight = getNormalizedScreenValues(1370, 25)
	self.lineTextSize = 0.0067544*g_screenAspectRatio
	self.lineX = 0.23
	self.lineStartY = 0.87
	self.lines = {}
	self.lineHoverActive = false
	self.currentLines = 0

	self.stationCount = 0
	self.oldHudVisibility = true
	self.oldBlurState = false
	self.oldPlayerFrozen = false
	self.oldMouseState = false

	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, StatisticWeightStationOverview.registerActionEvents)
	BaseMission.unregisterActionEvents = Utils.appendedFunction(BaseMission.unregisterActionEvents, StatisticWeightStationOverview.unregisterActionEvents)

	self.overviewOpen = false
	self.lastState = 0
	self.isEnabled = true

	return true
end

function StatisticWeightStationOverview:update(dt)
	if g_gui.currentGuiName == "InGameMenu" and self.overviewOpen == true and self.lastState ~= 2 then
		self:openOverview("STATISTICWEIGHTSTATION", nil, true)
		g_currentMission.hud:setIsVisible(false)
		g_depthOfFieldManager:setBlurState(true)
		g_inputBinding:setShowMouseCursor(true)
		g_currentMission.isPlayerFrozen = true
		self.lastState = 2
	elseif g_gui.currentGuiName ~= "InGameMenu" and self.overviewOpen == true and self.lastState ~= 1 then
		g_currentMission.hud:setIsVisible(not self.overviewOpen)
		g_depthOfFieldManager:setBlurState(self.overviewOpen)
		g_inputBinding:setShowMouseCursor(self.overviewOpen)
		g_currentMission.isPlayerFrozen = self.overviewOpen
		self.lastState = 1
	elseif g_gui.currentGuiName ~= "InGameMenu" and self.overviewOpen == false and self.lastState ~= 0 then
		g_currentMission.hud:setIsVisible(true)
		if g_currentMission.bosiActive ~= nil and g_currentMission.bosiActive then
			-- currently nothing
		else
			g_depthOfFieldManager:setBlurState(false)
			g_inputBinding:setShowMouseCursor(false)
			g_currentMission.isPlayerFrozen = false
		end
		self.lastState = 0
	end

	if g_currentMission.bosiActive ~= nil and g_currentMission.bosiActive and self.overviewOpen then
		self.overviewOpen = false
		self.lastState = 0
		g_currentMission.hud:setIsVisible(true)
	elseif g_currentMission.swsoActive ~= nil and g_currentMission.swsoActive == true and self.overviewOpen == false then
		g_currentMission.swsoActive = false
		if g_gui.currentGuiName ~= "InGameMenu" then
			g_depthOfFieldManager:setBlurState(false)
			g_inputBinding:setShowMouseCursor(false)
			g_currentMission.isPlayerFrozen = false
		end
	end

	if g_currentMission.StatisticWeightStations ~= nil then
		self.stationCount = #g_currentMission.StatisticWeightStations
		if self.stationCount > 0 and self.stationCount ~= #self.buttonsLeft then
			self.buttonsLeft = {}
			for i=1,self.stationCount do
				self.buttonsLeft[i] = {}
				self.buttonsLeft[i].back = createImageOverlay(self.buttonBlackFile)
				self.buttonsLeft[i].hover = createImageOverlay(self.buttonBlueFile)
				self.buttonsLeft[i].click = createImageOverlay(self.buttonGreenFile)
				self.buttonsLeft[i].use = createImageOverlay(self.buttonYellowFile)
				self.buttonsLeft[i].error = createImageOverlay(self.buttonRedFile)
				self.buttonsLeft[i].x = self.buttonsLeftX
				self.buttonsLeft[i].y = self.buttonsStartY - (self.buttonsHeight * 1.25 * i)
				self.buttonsLeft[i].textX = self.buttonsLeft[i].x + (self.buttonsWidth / 2)
				self.buttonsLeft[i].textY = self.buttonsLeft[i].y + (self.buttonsHeight / 3)
				self.buttonsLeft[i].hoverState = false
				self.buttonsLeft[i].clickState = false
				self.buttonsLeft[i].useState = false
			end
			self.buttonsTop = {}
			for i=1, 4 do
				self.buttonsTop[i] = {}
				self.buttonsTop[i].back = createImageOverlay(self.buttonBlackFile)
				self.buttonsTop[i].hover = createImageOverlay(self.buttonBlueFile)
				self.buttonsTop[i].click = createImageOverlay(self.buttonGreenFile)
				self.buttonsTop[i].use = createImageOverlay(self.buttonYellowFile)
				self.buttonsTop[i].error = createImageOverlay(self.buttonRedFile)
				self.buttonsTop[i].x = self.buttonsTopX + (self.buttonsWidth * 1.1 * i)
				self.buttonsTop[i].y = self.buttonsStartY
				self.buttonsTop[i].textX = self.buttonsTop[i].x + (self.buttonsWidth / 2)
				self.buttonsTop[i].textY = self.buttonsTop[i].y + (self.buttonsHeight / 3)
				self.buttonsTop[i].hoverState = false
				self.buttonsTop[i].clickState = false
				self.buttonsTop[i].useState = false
			end
			self.lines = {}
			local lastLine = 0
			for i=1, 30 do
				self.lines[i] = {}
				if lastLine == 0 then
					self.lines[i].back = createImageOverlay(self.lineBlackFile)
					lastLine = 1
				else
					self.lines[i].back = createImageOverlay(self.lineGreyFile)
					lastLine = 0
				end
				self.lines[i].hover = createImageOverlay(self.lineTurquisFile)
				self.lines[i].x = self.lineX
				self.lines[i].y = self.lineStartY - (self.lineHeight * ((i - 1) * 1.2))
				self.lines[i].textX = self.lines[i].x + self.lineTextSize
				self.lines[i].textY = self.lines[i].y + (self.lineHeight / 4)
				self.lines[i].hoverState = false
			end
		end
	end
	if self.buttonsLeftState > 0 and self.buttonsTopState == 0 then
		self.buttonsTopState = 1
	end
end

function StatisticWeightStationOverview:keyEvent(unicode, sym, modifier, isDown) end

function StatisticWeightStationOverview:mouseEvent(posX, posY, isDown, isUp, button)
	self.xPos = posX
	self.yPos = posY

	if self.overviewOpen then
		for i=1, #self.buttonsLeft do
			if self.buttonsLeftState == i then
				self.buttonsLeft[i].useState = true
			end
			if self.xPos >= self.buttonsLeft[i].x and self.xPos <= (self.buttonsLeft[i].x + self.buttonsWidth) then
				if self.yPos >= self.buttonsLeft[i].y and self.yPos <= (self.buttonsLeft[i].y + self.buttonsHeight) then
					if isDown then
						self.buttonsLeft[i].clickState = true
						self.buttonsLeft[i].hoverState = false
						if self.buttonsLeftState ~= i then
							self.buttonsLeft[i].useState = false
						end
					elseif isUp then
						if self.buttonsLeftState > 0 and self.buttonsLeftState ~= i then
							self.buttonsLeft[self.buttonsLeftState].useState = false
						end
						self.buttonsLeftState = i
						self.buttonsLeft[i].clickState = false
						self.buttonsLeft[i].hoverState = false
						self.buttonsLeft[i].useState = true
					else
						self.buttonsLeft[i].hoverState = true
						self.buttonsLeft[i].clickState = false
						if self.buttonsLeftState ~= i then
							self.buttonsLeft[i].useState = false
						end
					end
				else
					self.buttonsLeft[i].hoverState = false
					self.buttonsLeft[i].clickState = false
					if self.buttonsLeftState ~= i then
						self.buttonsLeft[i].useState = false
					end
				end
			else
				self.buttonsLeft[i].hoverState = false
				self.buttonsLeft[i].clickState = false
				if self.buttonsLeftState ~= i then
					self.buttonsLeft[i].useState = false
				end
			end
		end

		for i=1, 4 do
			if self.buttonsTopState == i then
				self.buttonsTop[i].useState = true
			end
			if self.xPos >= self.buttonsTop[i].x and self.xPos <= (self.buttonsTop[i].x + self.buttonsWidth) then
				if self.yPos >= self.buttonsTop[i].y and self.yPos <= (self.buttonsTop[i].y + self.buttonsHeight) then
					if isDown then
						self.buttonsTop[i].clickState = true
						self.buttonsTop[i].hoverState = false
						if self.buttonsTopState ~= i then
							self.buttonsTop[i].useState = false
						end
					elseif isUp then
						if self.buttonsTopState > 0 and self.buttonsTopState ~= i then
							self.buttonsTop[self.buttonsTopState].useState = false
						end
						self.buttonsTopState = i
						self.buttonsTop[i].clickState = false
						self.buttonsTop[i].hoverState = false
						self.buttonsTop[i].useState = true
					else
						self.buttonsTop[i].hoverState = true
						self.buttonsTop[i].clickState = false
						if self.buttonsTopState ~= i then
							self.buttonsTop[i].useState = false
						end
					end
				else
					self.buttonsTop[i].hoverState = false
					self.buttonsTop[i].clickState = false
					if self.buttonsTopState ~= i then
						self.buttonsTop[i].useState = false
					end
				end
			else
				self.buttonsTop[i].hoverState = false
				self.buttonsTop[i].clickState = false
				if self.buttonsTopState ~= i then
					self.buttonsTop[i].useState = false
				end
			end
		end

		local hoverActive = false
		if self.currentLines > 0 then
			for i=1, math.min(30,self.currentLines) do
				if self.xPos >= self.lines[i].x and self.xPos <= (self.lines[i].x + self.lineWidth) then
					if self.yPos >= self.lines[i].y and self.yPos <= (self.lines[i].y + self.lineHeight) then
						self.lines[i].hoverState = true
						hoverActive = true
					else
						self.lines[i].hoverState = false
					end
				else
					self.lines[i].hoverState = false
				end
			end
			self.lineHoverActive = hoverActive
		end
	end
end

function StatisticWeightStationOverview:openOverview(actionName, keyStatus, forceClose)
	if forceClose == nil then
		forceClose = false
	end
	if actionName == "STATISTICWEIGHTSTATION" then
		if not forceClose then
			self.overviewOpen = not self.overviewOpen
		else
			self.overviewOpen = false
		end
	end
	if self.overviewOpen then
		self.oldHudVisibility = g_currentMission.hud:getIsVisible()
		self.oldBlurState = g_depthOfFieldManager.blurIsActive
		self.oldPlayerFrozen = g_currentMission.isPlayerFrozen
		if g_inputBinding.mousePosYLast == 0.5 and g_inputBinding.mousePosXLast == 0.5 then
			self.oldMouseState = false
		else
			self.oldMouseState = true
		end
		g_inputBinding.mousePosYLast = 0.1
		g_inputBinding.mousePosXLast = 0.1
		g_currentMission.swsoActive = true
	else
		self.buttonsLeftState = 0
		self.buttonsTopState = 0
		self.currentPOStart = nil
		self.currentPOHeigth = nil
	end
end

function StatisticWeightStationOverview:draw()
	if self.isClient or g_client ~= nil or g_currentMission.player.isClient then
		if self.overviewOpen ~= nil and self.overviewOpen then
			renderOverlay(self.overlayFile, 0.05, 0.05, 0.9, 0.9)

			setTextColor(self.buttonColorStd.r,self.buttonColorStd.g,self.buttonColorStd.b,self.buttonColorStd.a)
			setTextAlignment(RenderText.ALIGN_CENTER)
			self.defaultPOStart = 0.2
			self.defaultPOHeight = ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX)*1.75)
			if self.currentPOStart == nil then
				self.currentPOStart = self.defaultPOStart
			end
			if self.currentPOHeigth == nil then
				self.currentPOHeigth = self.defaultPOHeight
			end

			for i=1, #g_currentMission.StatisticWeightStations do
				if self.buttonsLeft[i].clickState then
					renderOverlay(self.buttonsLeft[i].click, self.buttonsLeft[i].x, self.buttonsLeft[i].y, self.buttonsWidth, self.buttonsHeight)
				elseif self.buttonsLeft[i].hoverState then
					renderOverlay(self.buttonsLeft[i].hover, self.buttonsLeft[i].x, self.buttonsLeft[i].y, self.buttonsWidth, self.buttonsHeight)
				elseif self.buttonsLeft[i].useState then
					renderOverlay(self.buttonsLeft[i].use, self.buttonsLeft[i].x, self.buttonsLeft[i].y, self.buttonsWidth, self.buttonsHeight)
				else
					renderOverlay(self.buttonsLeft[i].back, self.buttonsLeft[i].x, self.buttonsLeft[i].y, self.buttonsWidth, self.buttonsHeight)
				end

				if self.buttonsLeftState == i then
					if not self.buttonsLeft[i].hoverState and not self.buttonsLeft[i].clickState then
						setTextColor(self.buttonColorUse.r,self.buttonColorUse.g,self.buttonColorUse.b,self.buttonColorUse.a)
					end
					setTextBold(true)
				else
					setTextColor(self.buttonColorStd.r,self.buttonColorStd.g,self.buttonColorStd.b,self.buttonColorStd.a)
					setTextBold(false)
				end
				if g_currentMission.StatisticWeightStations[i] ~= nil and g_currentMission.StatisticWeightStations[i].stationName ~= nil then
					renderText(self.buttonsLeft[i].textX, self.buttonsLeft[i].textY, self.buttonTextSize, g_currentMission.StatisticWeightStations[i].stationName)
				end
			end

			setTextColor(self.buttonColorStd.r,self.buttonColorStd.g,self.buttonColorStd.b,self.buttonColorStd.a)
			setTextBold(false)

			for i=1,4 do
				if self.buttonsTop[i].clickState then
					renderOverlay(self.buttonsTop[i].click, self.buttonsTop[i].x, self.buttonsTop[i].y, self.buttonsWidth, self.buttonsHeight)
				elseif self.buttonsTop[i].hoverState then
					renderOverlay(self.buttonsTop[i].hover, self.buttonsTop[i].x, self.buttonsTop[i].y, self.buttonsWidth, self.buttonsHeight)
				elseif self.buttonsTop[i].useState then
					renderOverlay(self.buttonsTop[i].use, self.buttonsTop[i].x, self.buttonsTop[i].y, self.buttonsWidth, self.buttonsHeight)
				else
					renderOverlay(self.buttonsTop[i].back, self.buttonsTop[i].x, self.buttonsTop[i].y, self.buttonsWidth, self.buttonsHeight)
				end

				local textString = g_i18n:getText("weightType"..tostring(i))
				if self.buttonsTopState == i then
					if not self.buttonsTop[i].hoverState and not self.buttonsTop[i].clickState then
						setTextColor(self.buttonColorUse.r,self.buttonColorUse.g,self.buttonColorUse.b,self.buttonColorUse.a)
					end
					setTextBold(true)
				else
					setTextColor(self.buttonColorStd.r,self.buttonColorStd.g,self.buttonColorStd.b,self.buttonColorStd.a)
					setTextBold(false)
				end
				renderText(self.buttonsTop[i].textX, self.buttonsTop[i].textY, self.buttonTextSize, textString)
			end

			setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_LEFT)

			local lineCounter = 0
			local colorChanger = 0
			local hoverFillType = 0
			if self.buttonsLeftState > 0 and self.buttonsTopState > 0 then
 				local wStation = g_currentMission.StatisticWeightStations[self.buttonsLeftState]
				if wStation ~= nil then
					if self.buttonsTopState == 1 and wStation.measurementFillTypes ~= nil then
						setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
						for i=1, #g_fillTypeManager.fillTypes do
							if wStation.measurementFillTypes[i] ~= nil and wStation.measurementFillTypes[i].mass ~= nil and wStation.measurementFillTypes[i].mass > 0 then
								lineCounter = lineCounter + 1
								if self.lines[lineCounter].hoverState then
									renderOverlay(self.lines[lineCounter].hover, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
									hoverFillType = i
								else
									renderOverlay(self.lines[lineCounter].back, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
								end
								setTextAlignment(RenderText.ALIGN_LEFT)
								renderText(self.lines[lineCounter].textX, self.lines[lineCounter].textY, self.lineTextSize, g_fillTypeManager.fillTypes[i].title)
								setTextAlignment(RenderText.ALIGN_RIGHT)
								renderText(self.buttonsTop[1].x + self.buttonsWidth, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementFillTypes[i].mass,3)))
								renderText(self.buttonsTop[2].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("numPlayers"),#wStation.measurementFillTypes[i].player))
								if not self.lineHoverActive or lineCounter < 2 or self.currentPOStart > (self.lines[lineCounter].y + self.lineHeight) then
									setTextAlignment(RenderText.ALIGN_LEFT)
									renderText(self.buttonsTop[3].x, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("numBales"),self:formatNumbers(wStation.measurementFillTypes[i].baleCount,0)))
									setTextAlignment(RenderText.ALIGN_RIGHT)
									renderText(self.buttonsTop[3].x+self.buttonsWidth, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementFillTypes[i].baleMass,3)))
								end
							end
						end
						if hoverFillType > 0 then
							local playerOverlay = createImageOverlay(self.overlaySmallFile)
							renderOverlay(playerOverlay, self.buttonsTop[2].textX, self.currentPOStart, self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX, self.currentPOHeigth)
							local yStart = 0.2 + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX)*1.75) - (self.buttonTextSize * 4)
							local xStart = self.buttonsTop[2].textX + self.buttonTextSize
							local xMid = self.buttonsTop[2].textX + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX) / 2)
							local xRight = self.buttonsTop[2].textX + self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX - self.buttonTextSize
							setTextAlignment(RenderText.ALIGN_CENTER)
							setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
							renderText(xMid, yStart, self.lineTextSize * 3, g_fillTypeManager.fillTypes[hoverFillType].title)
							setTextColor(self.buttonColorC.r,self.buttonColorC.g,self.buttonColorC.b,self.buttonColorC.a)
							renderText(xMid, yStart - (self.lineTextSize * 2), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementFillTypes[hoverFillType].mass,3)))
							yStart = yStart - (self.lineTextSize * 5)
							local lineACounter = 0
							for j=1, #wStation.measurementFillTypes[hoverFillType].player do
								if wStation.measurementFillTypes[hoverFillType].player[j].mass > 0 then
									lineACounter = lineACounter + 1
									if colorChanger == 0 then
										colorChanger = 1
										setTextColor(self.buttonColorA.r,self.buttonColorA.g,self.buttonColorA.b,self.buttonColorA.a)
									elseif colorChanger == 1 then
										colorChanger = 2
										setTextColor(self.buttonColorB.r,self.buttonColorB.g,self.buttonColorB.b,self.buttonColorB.a)
									elseif colorChanger == 2 then
										colorChanger = 0
										setTextColor(self.buttonColorD.r,self.buttonColorD.g,self.buttonColorD.b,self.buttonColorD.a)
									end
									setTextAlignment(RenderText.ALIGN_LEFT)
									renderText(xStart, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, Utils.getNoNil(wStation.measurementFillTypes[hoverFillType].player[j].name," "))
									setTextAlignment(RenderText.ALIGN_RIGHT)
									renderText(xRight, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementFillTypes[hoverFillType].player[j].mass,3)))
									self.currentPOStart = yStart - ((lineACounter) * (self.lineTextSize * 1.75))
									self.currentPOHeigth = self.lines[1].y - self.currentPOStart
								end
							end
						end
					elseif self.buttonsTopState == 2 and wStation.measurementPlayer ~= nil then
						setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
						for i=1, #wStation.measurementPlayer do
							if wStation.measurementPlayer[i] ~= nil and ((wStation.measurementPlayer[i].mass ~= nil and wStation.measurementPlayer[i].mass > 0) or (wStation.measurementPlayer[i].trunksMass ~= nil and wStation.measurementPlayer[i].trunksMass > 0)) then
								lineCounter = lineCounter + 1
								if self.lines[lineCounter].hoverState then
									renderOverlay(self.lines[lineCounter].hover, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
									hoverFillType = i
								else
									renderOverlay(self.lines[lineCounter].back, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
								end
								setTextAlignment(RenderText.ALIGN_LEFT)
								renderText(self.lines[lineCounter].textX, self.lines[lineCounter].textY, self.lineTextSize, wStation.measurementPlayer[i].name)
								setTextAlignment(RenderText.ALIGN_RIGHT)
								renderText(self.buttonsTop[1].x + self.buttonsWidth, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementPlayer[i].mass,3)))
								local numFilltypes = 0
								local numBales = 0
								local massBales = 0
								for j=1, #g_fillTypeManager.fillTypes do
									if wStation.measurementPlayer[i].fillType[j].baleMass > 0 then
										numBales = numBales + wStation.measurementPlayer[i].fillType[j].baleCount
										massBales = massBales + wStation.measurementPlayer[i].fillType[j].baleMass
									end
									if wStation.measurementPlayer[i].fillType[j].mass > 0 then
										numFilltypes = numFilltypes + 1
									end
								end
								renderText(self.buttonsTop[2].textX, self.lines[lineCounter].textY, self.lineTextSize, g_i18n:getText("weightType1")..": "..string.format(g_i18n:getText("weightPiece"),self:formatNumbers(numFilltypes,0)))
								if not self.lineHoverActive or lineCounter < 2 or self.currentPOStart > (self.lines[lineCounter].y + self.lineHeight) then
									setTextAlignment(RenderText.ALIGN_LEFT)
									renderText(self.buttonsTop[3].x, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightBales"),self:formatNumbers(massBales,3)).." ("..string.format(g_i18n:getText("weightPiece"),self:formatNumbers(numBales,0))..")")
									setTextAlignment(RenderText.ALIGN_RIGHT)
									renderText(self.buttonsTop[4].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightWood"),self:formatNumbers(wStation.measurementPlayer[i].trunksMass,3)))
									renderText(self.buttonsTop[4].x+self.buttonsWidth, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementPlayer[i].trunksCount,0)))
								end
							end
						end
						if hoverFillType > 0 then
							local playerOverlay = createImageOverlay(self.overlaySmallFile)
							renderOverlay(playerOverlay, self.buttonsTop[2].textX, self.currentPOStart, self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX, self.currentPOHeigth)
							local yStart = 0.2 + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX)*1.75) - (self.buttonTextSize * 4)
							local xStart = self.buttonsTop[2].textX + self.buttonTextSize
							local xMid = self.buttonsTop[2].textX + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX) / 2)
							local xRight = self.buttonsTop[2].textX + self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX - self.buttonTextSize
							setTextAlignment(RenderText.ALIGN_CENTER)
							setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
							renderText(xMid, yStart, self.lineTextSize * 3, wStation.measurementPlayer[hoverFillType].name)
							setTextColor(self.buttonColorC.r,self.buttonColorC.g,self.buttonColorC.b,self.buttonColorC.a)
							renderText(xMid, yStart - (self.lineTextSize * 2), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementPlayer[hoverFillType].mass,3)))
							yStart = yStart - (self.lineTextSize * 5)
							local lineACounter = 0
							for j=1, #g_fillTypeManager.fillTypes do
								if wStation.measurementPlayer[hoverFillType].fillType[j].mass > 0 then
									lineACounter = lineACounter + 1
									if colorChanger == 0 then
										colorChanger = 1
										setTextColor(self.buttonColorA.r,self.buttonColorA.g,self.buttonColorA.b,self.buttonColorA.a)
									elseif colorChanger == 1 then
										colorChanger = 2
										setTextColor(self.buttonColorB.r,self.buttonColorB.g,self.buttonColorB.b,self.buttonColorB.a)
									elseif colorChanger == 2 then
										colorChanger = 0
										setTextColor(self.buttonColorD.r,self.buttonColorD.g,self.buttonColorD.b,self.buttonColorD.a)
									end
									setTextAlignment(RenderText.ALIGN_LEFT)
									renderText(xStart, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, g_fillTypeManager.fillTypes[j].title)
									setTextAlignment(RenderText.ALIGN_RIGHT)
									renderText(xMid, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementPlayer[hoverFillType].fillType[j].mass,3)))
									if wStation.measurementPlayer[hoverFillType].fillType[j].baleMass > 0 then
										renderText(xRight, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightBales"),self:formatNumbers(wStation.measurementPlayer[hoverFillType].fillType[j].baleMass,3)).." ("..string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementPlayer[hoverFillType].fillType[j].baleCount,0))..")")
									end
									self.currentPOStart = yStart - ((lineACounter) * (self.lineTextSize * 1.75))
									self.currentPOHeigth = self.lines[1].y - self.currentPOStart
								end
							end
						end
					elseif self.buttonsTopState == 3 and wStation.measurementBales ~= nil then
						setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
						for i=1, #g_fillTypeManager.fillTypes do
							if wStation.measurementBales[i] ~= nil and wStation.measurementBales[i].mass ~= nil and wStation.measurementBales[i].mass > 0 then
								lineCounter = lineCounter + 1
								if self.lines[lineCounter].hoverState then
									renderOverlay(self.lines[lineCounter].hover, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
									hoverFillType = i
								else
									renderOverlay(self.lines[lineCounter].back, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
								end
								setTextAlignment(RenderText.ALIGN_LEFT)
								renderText(self.lines[lineCounter].textX, self.lines[lineCounter].textY, self.lineTextSize, g_fillTypeManager.fillTypes[i].title.." "..g_i18n:getText("weightType3"))
								setTextAlignment(RenderText.ALIGN_RIGHT)
								renderText(self.buttonsTop[1].x + self.buttonsWidth, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementBales[i].mass,3)))
								renderText(self.buttonsTop[2].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("numPlayers"),#wStation.measurementBales[i].player))
								if not self.lineHoverActive or lineCounter < 2 or self.currentPOStart > (self.lines[lineCounter].y + self.lineHeight) then
									renderText(self.buttonsTop[3].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementBales[i].count,0)))
								end
							end
						end
						if hoverFillType > 0 then
							local playerOverlay = createImageOverlay(self.overlaySmallFile)
							renderOverlay(playerOverlay, self.buttonsTop[2].textX, self.currentPOStart, self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX, self.currentPOHeigth)
							local yStart = 0.2 + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX)*1.75) - (self.buttonTextSize * 4)
							local xStart = self.buttonsTop[2].textX + self.buttonTextSize
							local xMid = self.buttonsTop[2].textX + ((self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX) / 2)
							local xRight = self.buttonsTop[2].textX + self.buttonsTop[4].x+self.buttonsWidth-self.buttonsTop[2].textX - self.buttonTextSize
							setTextAlignment(RenderText.ALIGN_CENTER)
							setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
							renderText(xMid, yStart, self.lineTextSize * 3, g_fillTypeManager.fillTypes[hoverFillType].title.." "..g_i18n:getText("weightType3"))
							setTextColor(self.buttonColorC.r,self.buttonColorC.g,self.buttonColorC.b,self.buttonColorC.a)
							renderText(xMid, yStart - (self.lineTextSize * 2), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementBales[hoverFillType].mass,3)).." ("..string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementBales[hoverFillType].count,0))..")")
							yStart = yStart - (self.lineTextSize * 5)
							local lineACounter = 0
							for j=1, #wStation.measurementBales[hoverFillType].player do
								if wStation.measurementBales[hoverFillType].player[j].mass > 0 then
									lineACounter = lineACounter + 1
									if colorChanger == 0 then
										colorChanger = 1
										setTextColor(self.buttonColorA.r,self.buttonColorA.g,self.buttonColorA.b,self.buttonColorA.a)
									elseif colorChanger == 1 then
										colorChanger = 2
										setTextColor(self.buttonColorB.r,self.buttonColorB.g,self.buttonColorB.b,self.buttonColorB.a)
									elseif colorChanger == 2 then
										colorChanger = 0
										setTextColor(self.buttonColorD.r,self.buttonColorD.g,self.buttonColorD.b,self.buttonColorD.a)
									end
									setTextAlignment(RenderText.ALIGN_LEFT)
									local plName = " "
									if wStation.measurementTrunks ~= nil and wStation.measurementTrunks.player ~= nil and wStation.measurementTrunks.player[i] ~= nil then
										plName = wStation.measurementTrunks.player[i].name
									end
									renderText(xStart, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, plName)
									setTextAlignment(RenderText.ALIGN_RIGHT)
									renderText(xMid, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementBales[hoverFillType].player[j].count,0)))
									renderText(xRight, yStart - ((lineACounter - 1) * (self.lineTextSize * 1.75)), self.lineTextSize * 1.5, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementBales[hoverFillType].player[j].mass,3)))
									self.currentPOStart = yStart - ((lineACounter) * (self.lineTextSize * 1.75))
									self.currentPOHeigth = self.lines[1].y - self.currentPOStart
								end
							end
						end
					elseif self.buttonsTopState == 4 and wStation.measurementTrunks ~= nil then
						setTextColor(self.buttonColorLine.r,self.buttonColorLine.g,self.buttonColorLine.b,self.buttonColorLine.a)
						if wStation.measurementTrunks ~= nil and wStation.measurementTrunks.mass ~= nil and wStation.measurementTrunks.mass > 0 and #wStation.measurementTrunks.player > 0 then
							for j=1, #wStation.measurementTrunks.player do
								lineCounter = lineCounter + 1
								if self.lines[lineCounter].hoverState then
									renderOverlay(self.lines[lineCounter].hover, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
								else
									renderOverlay(self.lines[lineCounter].back, self.lines[lineCounter].x, self.lines[lineCounter].y, self.lineWidth, self.lineHeight)
								end
								setTextAlignment(RenderText.ALIGN_LEFT)
								renderText(self.lines[lineCounter].textX, self.lines[lineCounter].textY, self.lineTextSize, Utils.getNoNil(wStation.measurementTrunks.player[j].name," "))
								setTextAlignment(RenderText.ALIGN_RIGHT)
								renderText(self.buttonsTop[2].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightMass"),self:formatNumbers(wStation.measurementTrunks.player[j].mass,3)))
								renderText(self.buttonsTop[3].textX, self.lines[lineCounter].textY, self.lineTextSize, string.format(g_i18n:getText("weightPiece"),self:formatNumbers(wStation.measurementTrunks.player[j].count,0)))
							end
						end
					end
				end
			else
			end
			self.currentLines = lineCounter
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1,1,1,1)
		setTextBold(false)
	end
end

function StatisticWeightStationOverview:comma_value(amount)
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if (k==0) then
			break
		end
	end
	return formatted
end
function StatisticWeightStationOverview:round(val, decimal)
	if (decimal) then
		return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
	else
		return math.floor(val+0.5)
	end
end
function StatisticWeightStationOverview:formatNumbers(amount, decimal, prefix, neg_prefix)
	local str_amount,  formatted, famount, remain
	decimal = decimal or 2
	neg_prefix = neg_prefix or "-"
	famount = math.abs(self:round(amount,decimal))
	famount = math.floor(famount)
	remain = self:round(math.abs(amount) - famount, decimal)
	formatted = self:comma_value(famount)
	if (decimal > 0) then
		remain = string.sub(tostring(remain),3)
		formatted = formatted .. "," .. remain ..
		string.rep("0", decimal - string.len(remain))
	end
	formatted = (prefix or "") .. formatted 
	if (amount<0) then
		if (neg_prefix=="()") then
			formatted = "("..formatted ..")"
		else
			formatted = neg_prefix .. formatted 
		end
	end
	return formatted
end

function StatisticWeightStationOverview:registerActionEvents()
    local arg1, eventName1 = g_inputBinding:registerActionEvent(InputAction.STATISTICWEIGHTSTATION, StatisticWeightStationOverview, StatisticWeightStationOverview.openOverview, false, true, false, true)
    if arg1 then
		g_inputBinding:setActionEventActive(eventName1, true)
		g_inputBinding.events[eventName1].displayPriority = 1
		g_inputBinding:setActionEventTextVisibility(eventName1, true)
		StatisticWeightStationOverview.keyId = eventName1
	end
end

function StatisticWeightStationOverview:unregisterActionEvents()
    g_inputBinding:removeActionEventsByTarget(StatisticWeightStationOverview)
end

addModEventListener(StatisticWeightStationOverview)

print(" ++ loading StatisticWeightStationOverview V "..tostring(StatisticWeightStationOverview.version).." - "..tostring(StatisticWeightStationOverview.date).." (by Blacky_BPG)")
