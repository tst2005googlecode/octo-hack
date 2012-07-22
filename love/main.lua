Sounds = true
LosSetting = true

function playSound(s)
	love.audio.stop(s)
	love.audio.rewind(s)
	if Sounds then
		love.audio.play(s)
	end
end

function sfx(path)
	print("loading ", sfx)
	return love.audio.newSource(path, "static")
end

function playMusic(path)
	local m = love.audio.newSource(path, "stream")
	m:setLooping(true)
	m:play()
end

function ID(x,y)
	return x.."x"..y
end

Gamestate = require "hump.gamestate"
ATL_Loader = require("AdvTiledLoader.Loader")
Camera = require "hump.camera"
Vector = require 'hump.vector'
Class = require "hump.class"
ATL_Loader.path = "media/"

sgame = Gamestate.new()
smenu = Gamestate.new()
sdone = Gamestate.new()
sfail = Gamestate.new()

Coin = Class{function(self, x, y)
	self.x = x
	self.y = y
end}

function Coin:draw()
	smartDrawTile(self, gfxCoin)
end

Player = Class{function(self, x, y)
	self.x = x
	self.y = y
	self.arms = {}
	for i,id in ipairs(ARMS) do
		self.arms[ID(id.x, id.y)] = true
	end
end}

function Player:clearArms()
	self.arms = {}
end

function Player:addArm()
	for i,id in ipairs(ARMS) do
		if self.arms[ID(id.x, id.y)] then
		else
			self.arms[ID(id.x, id.y)] = true
			return true
		end
	end
	return false
end

function smartDrawTile(self, Img, dx, dy)
	if dx == nil then
		dx = 0
	end
	if dy == nil then
		dy = 0
	end
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(Img, (self.x+dx)*44+22, (dy+self.y)*44+22, 0, 1, 1, Img:getWidth()/2, Img:getHeight()/2)
end

function Player:sdt(a)
	local p = ID(a.x, a.y)
	if self.arms[p] then
		smartDrawTile(self, gfxArms[p], a.x, a.y)
	end
end

function Player:draw()
	smartDrawTile(self, Head)
	for i,a in ipairs(ARMS) do
		self:sdt(a)
	end
	love.graphics.setColor(0,0,0,255)
	love.graphics.print("#" .. self:getArmCount(), self.x*44, self.y*44)
end

function Player:testPosition(dx,dy)
	if true == hasTile(self.x+dx, self.y+dy) then
		return true
	end
	
	for i,a in ipairs(ARMS) do
		if self.arms[ID(a.x, a.y)] ~= nil then
			if true == hasTile(self.x+dx+a.x, self.y+dy+a.y) then
				return true
			end			
		end
	end
	
	return false
end

function Player:move(x, y)
	if false == self:testPosition(x, y) then
		self.x = self.x + x
		self.y = self.y + y
		--playSound(sfxMove)
	else
		playSound(sfxHitWall)
	end
end

function Player:getRenderPos()
	return Vector(self.x*44+22, self.y*44+22)
end

function IDa(x,y)
	return Vector(x,y)
end

ARMS = {IDa(1,0),IDa(1,-1),IDa(1,1),IDa(0,-1), IDa(0,1), IDa(-1, -1), IDa(-1,1), IDa(-1,0)}

function freearm(self)
	for i,id in ipairs(ARMS) do
		if self.arms[ID(id.x, id.y)] then
			return ID(id.x, id.y)
		end
	end
	return nil
end

function Player:spawnSub()
	if self:getArmCount() > 1 then
		local a = freearm(self)
		if a ~= nil then
			self.arms[a] = nil
			local p = addPlayer(self.x, self.y)
			p:clearArms()
			p:addArm()
			playSound(sfxDetach)
		end
	end
end

function Player:rotate()
	self.arms[ID(1,1)],self.arms[ID(0,1)],self.arms[ID(-1,1)],self.arms[ID(-1,0)],self.arms[ID(-1,-1)],self.arms[ID(0,-1)],self.arms[ID(1,-1)],self.arms[ID(1,0)] = self.arms[ID(0,1)],self.arms[ID(-1,1)],self.arms[ID(-1,0)],self.arms[ID(-1,-1)],self.arms[ID(0,-1)],self.arms[ID(1,-1)],self.arms[ID(1,0)],self.arms[ID(1,1)]
end

function Player:removeArm()
	local a = freearm(self)
	if a ~= nil then
		self.arms[a] = nil
	end
end

function Player:getArmCount()
	local c = 0
	for i,a in pairs(self.arms) do
		if a ~= nil then
			if a then
				c = c + 1
			end
		end
	end
	return c
end

Enemy = Class{ function(self, x,y)
	self.x = x
	self.y = y
end}
function Enemy:draw()
	smartDrawTile(self, gfxEnemy)
end
function Enemy:move(x, y)
	if false == hasTile(self.x+x, self.y+y) then
		self.x = self.x + x
		self.y = self.y + y
		return true
	else
		return false
	end
end

function Enemy:getRenderPos()
	return Vector(self.x*44+22, self.y*44+22)
end

function Enemy:random_ai()
	local m = 0
	local dx = 0
	local dy = 0
	local c = 0
	repeat
		m = math.random(0,3)
		dx = 0
		y = 0
		if m == 0 then
			dx = 1
		end
		if m == 1 then
			dx = -1
		end
		if m==2 then
			dy = 1
		end
		if m==3 then
			dy = -1
		end
		c = c + 1
	until self:move(dx,dy) or c>8
end

function Enemy:smart_ai()
	local player = players[selected]
	if Bresenham(self.x, player.x, self.y, player.y) then
		print("LOS!")
		local dx = 0
		local dy = 0
		if player.x == self.x then
			if player.y > self.y then
				dy = 1
			else
				dy = -1
			end
		else
			if player.x > self.x then
				dx = 1
			else
				dx = -1
			end
		end
		
		self:move(dx,dy)
	end
end

function Enemy:ai()
	self:smart_ai()
end

function Bresenham(x0, x1, y0, y1)
	local steep = false
	local special = false
	if (math.abs(y1 - y0) > math.abs(x1 - x0)) then
		steep = true
	end
	if steep then
		--swap(x0, y0);
		--swap(x1, y1);
		x0, y0 = y0, x0
		x1, y1 = y1, x1
	end
	if x0 > x1 then
		--swap(x0, x1);
		--swap(y0, y1);
		x0, X1 = x1, x0
		y0, y1 = y1, y0
	end
	local deltax = x1 - x0
	local deltay = math.abs(y1 - y0)
	local error = 0
	local deltaerr = deltay / deltax
	local ystep;
	local y = y0
	if y0 < y1 then
		ystep = 1
	else
		ystep = -1
	end

	for x=x0,x1-1 do
		if(steep) then
			if (hasTile(y,x)) then
				--Do stuff
				return false
			end

		else
			if (hasTile(x,y)) then
				--Do stuff
				return false
			end
		end
		error = error + deltaerr
		if (error >= 0.5) then
			y = y + ystep
			if special then
				if steep then
					--m.push_back(Pos(y,x))
					if hasTile(y,x) then
						--Do stuff
						return false
					end
				else
					--m.push_back(Pos(x,y))
					if hasTile(x,y) then
						--Do stuff
						return false
					end
				end
			end
			error = error - 1.0
		end
	end
	return true
end



function smenu:init()
	self.bg = love.graphics.newImage('media/main.png')
end

function smenu:draw()
	love.graphics.setColor(255,255,255,255)
    love.graphics.draw(self.bg, 0, 0)
	love.graphics.setColor(0,0,0,255)
	love.graphics.print("a game by Christian Costanza, Gustav Jansson, Jacob Michelsen, David Nilsson, Giselle Otero | No More Sweden 2012", 35, 580)
end
function smenu:enter()
	print("entered menu")
	loadWorld()
end
function smenu:keypressed(key)
    if key == "escape" then
		love.event.quit()
	else
		Gamestate.switch(sgame)
	end
end

function sdone:init()
	self.bg = love.graphics.newImage('media/win.png')
end
function sdone:enter()
	print("entered done")
	playSound(sfxWin)
end
function sdone:draw()
	love.graphics.setColor(255,255,255,255)
    love.graphics.draw(self.bg, 0, 0)
end
function sdone:keypressed(key)
	if key == "escape" then
		love.event.quit()
    else
		Gamestate.switch(smenu)
	end
end

function sfail:init()
	self.bg = love.graphics.newImage('media/fail.png')
end
function sfail:enter()
	playSound(sfxFail)
	print("entered fail")
end
function sfail:draw()
	love.graphics.setColor(255,255,255,255)
    love.graphics.draw(self.bg, 0, 0)
end
function sfail:keypressed(key)
	if key == "escape" then
		love.event.quit()
    else
		Gamestate.switch(smenu)
	end
end

function love.load()
	love.graphics.setBackgroundColor( 0, 177, 224)
	canplay = 1
	--loadWorld()
	if Sounds then
		playMusic("sfx/Wanderers WIP.ogg")
	end
	Head = love.graphics.newImage( "media/Head.png" )
	gfxEnemy = love.graphics.newImage( "media/Enemy.png" )
	gfxCoin = love.graphics.newImage( "media/Coin.png" )
	gfxArms = {}
	gfxArms[ID(-1,1)] = love.graphics.newImage( "media/Tentacles1.png" )
	gfxArms[ID(0,1)] = love.graphics.newImage( "media/Tentacles2.png" )
	gfxArms[ID(1,1)] = love.graphics.newImage( "media/Tentacles3.png" )
	gfxArms[ID(-1,0)] = love.graphics.newImage( "media/Tentacles4.png" )
	gfxArms[ID(1,0)] = love.graphics.newImage( "media/Tentacles6.png" )
	gfxArms[ID(-1,-1)] = love.graphics.newImage( "media/Tentacles7.png" )
	gfxArms[ID(0,-1)] = love.graphics.newImage( "media/Tentacles8.png" )
	gfxArms[ID(1,-1)] = love.graphics.newImage( "media/Tentacles9.png" )
	
	sfxDetach = sfx("sfx/Amputating.wav")
	sfxMove = sfx("sfx/Swiming.wav")
	sfxHitWall = sfx("sfx/HitWall.wav")
	sfxCoin = sfx("sfx/Coin.wav")
	sfxDmg = sfx("sfx/EnemyHarm.wav")
	sfxKill = sfx("sfx/KillFish.wav")
	sfxWin = sfx("sfx/Win.wav")
	sfxFail = sfx("sfx/Fail.wav")
	sfxMerge = sfx("sfx/Rejoining.wav")
	
	Gamestate.registerEvents()
    Gamestate.switch(smenu)
end

function hasTile(x,y)
	local p = ID(x,y)
	local data = col[p]
	if data == nil then
		return true
	else
		return data
	end
end

function sgame:draw()
	fps = 1/deltat
	love.graphics.setColor(255,255,255, 255)
	camera:attach()
	map:draw()
	love.graphics.setColor(255,255,255, 255)
	for i,player in ipairs(players) do
		player:draw()
	end
	for i,enemy in ipairs(enemies) do
		enemy:draw()
	end
	for i,coin in ipairs(coins) do
		coin:draw()
	end
	camera:detach()
	love.graphics.setColor(0,0,0, 255)
	--love.graphics.print(string.format("%d", fps), 100, 10)
	love.graphics.print(string.format("Players: " .. #players .. " | Coins: " .. #coins .. " | Enemies: " .. #enemies, fps), 100, 10)
end

function remove_if(list, func)
	local toremove = {}
	for i,item in ipairs(list) do
		if func(item) then
			table.insert(toremove, i)
		end
	end
	local i = 0
	while #toremove ~= 0 do
		i = table.remove(toremove)
		table.remove(list,i)
	end
end

function handleTick(domerge)
	for i,enemy in ipairs(enemies) do
		enemy:ai()
	end
	
	-- check for enemy-player collisions
	for i,player in ipairs(players) do
		for j,enemy in ipairs(enemies) do
			if player.x == enemy.x and player.y == enemy.y then
				if player:getArmCount() == 1 then
					playSound(sfxDmg)
					player.killme = true
				else
					playSound(sfxKill)
					player:removeArm()
					enemy.killme = true
				end
			end
		end
	end
	
	remove_if(players, isKillmeSet)
	remove_if(enemies, isKillmeSet)
	
	if selected > #players then
		selected = 1
	end
	
	-- check for player-coin collisions
	for i,player in ipairs(players) do
		for j,coin in ipairs(coins) do
			if player.x == coin.x and player.y == coin.y then
				coin.killme = true
				playSound(sfxCoin)
			end
		end
	end
	
	-- check for player-player collisions
	if domerge then
		for i,p1 in ipairs(players) do
			for j,p2 in ipairs(players) do
				if i~=j and p1.killme ~= true and p1.x == p2.x and p1.y == p2.y then
					p2.killme = true
					playSound(sfxMerge)
					print("Merging")
					for i=1,p2:getArmCount() do
						p1:addArm()
					end
				end
			end
		end
	end
	
	remove_if(coins, isKillmeSet)
	
	if #players == 0 then
		Gamestate.switch(sfail)
	end
	
	if #coins == 0 then
		Gamestate.switch(sdone)
	end
end

function isKillmeSet(self)
	if self.killme then
		return true
	else
		return false
	end
end

function sgame:update(dt)
	deltat=dt
	local player = players[selected]
	camera.pos = player:getRenderPos()
end

function sgame:keypressed(key, unicode)
	if key == "escape" then
		love.event.quit()
	end
	
	if canplay==1 then
		--world:onkey(true, key, unicode)
	end
end

function sgame:keyreleased(key)
	local player = players[selected]
	if canplay==1 then
		if key=="left" then
			player:move(-1, 0)
			handleTick(true)
		end
		if key=="right" then
			player:move(1, 0)
			handleTick(true)
		end
		if key =="up" then
			player:move(0, -1)
			handleTick(true)
		end
		if key=="down" then
			player:move(0, 1)
			handleTick(true)
		end
		if key==" " then
			player:spawnSub()
			handleTick(false)
		end
		if key=="r" then
			player:rotate()
			handleTick(false)
		end
		if key=="tab" then
			selected = (selected % #players) + 1
		end
	end
	--world:onkey(false, key, nil)
end

function sgame:mousepressed(x, y, button)
	--world:onkey(true, "_"..button, nil)
end

function sgame:mousereleased(x, y, button)
	--world:onkey(false, "_"..button, nil)
	--local loc = camera:worldCoords(love.mouse.getPosition())
end

function addPlayer(x,y)
	local p = Player(x,y)
	players[#players + 1] = p
	selected = #players
	return p
end

function addEnemy(x,y)
	enemies[#enemies + 1] = Enemy(x,y)
end

function addCoin(x,y)
	coins[#coins + 1] = Coin(x,y)
end

function T(x)
	return math.floor(x/44)
end

function loadWorld()
	map = ATL_Loader.load("map2.tmx")
	map.useSpriteBatch = true
	map.drawObjects = false
	camera = Camera(Vector(1,1))
	players =  {}
	enemies = {}
	coins = {}
	selected = 1
	col = {}
	for tilename, tilelayer in pairs(map.tileLayers) do
		print("Working on ", tilename, map.height, map.width, tilelayer)
		for y=1,map.height do
			for x=1,map.width do
				local tile = tilelayer.tileData(x,y)
				if tile and tile ~= nil then
					if tile.properties.solid~=nil then
						--print("found solid")
						col[ID(x,y)] = true
					else
						col[ID(x,y)] = false
					end
				end
			end
		end
	end
	
	for layername, layer in pairs(map.objectLayers) do
		print("Working on objectlayer ", layername)
		for i,o in pairs(layer.objects) do
			print("Object: #", i, ", name: ", o.name, ", type: ", o.type, ", pos: ", o.x, o.y)
			if layername == "fish" then
				addEnemy(T(o.x),T(o.y))
			end
			if layername == "player" then
				addPlayer(T(o.x),T(o.y))
			end
			if layername == "coins" then
				addCoin(T(o.x),T(o.y))
			end
		end
	end
end