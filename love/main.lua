function playSound(s)
	love.audio.stop(s)
	love.audio.rewind(s)
	love.audio.play(s)
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

Gamestate = require "hump.gamestate"
ATL_Loader = require("AdvTiledLoader.Loader")
Camera = require "hump.camera"
Vector = require 'hump.vector'
Class = require "hump.class"
ATL_Loader.path = "media/"

sgame = Gamestate.new()
smenu = Gamestate.new()
sdone = Gamestate.new()

Player = Class{function(self, x, y)
	self.x = x
	self.y = y
end}

function smartDrawTile(self, Img)
	love.graphics.setColor(255,255,255,255)
	love.graphics.draw(Img, self.x*44+22, self.y*44+22, 0, 1, 1, Img:getWidth()/2, Img:getHeight()/2)
end

function Player:draw()
	smartDrawTile(self, Head)
	love.graphics.setColor(0,0,0,255)
	--love.graphics.circle("fill", self.x*44, self.y*44, 50)
end

function Player:move(x, y)
	if false == hasTile(self.x+x, self.y+y) then
		self.x = self.x + x
		self.y = self.y + y
	end
end

function Player:getRenderPos()
	return Vector(self.x*44+22, self.y*44+22)
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
function Enemy:ai()
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

function smenu:init()
	self.bg = love.graphics.newImage('media/start.png')
end
function smenu:draw()
	love.graphics.setColor(255,255,255,255)
    love.graphics.draw(self.bg, 0, 0)
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
	self.bg = love.graphics.newImage('media/done.png')
end
function sdone:enter()
	print("entered done")
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

function love.load()
	love.graphics.setBackgroundColor( 100, 149, 237 )
	canplay = 1
	loadWorld()
	--playMusic("bu-a-banana-and-simplices.it")
	Head = love.graphics.newImage( "media/Head.png" )
	gfxEnemy = love.graphics.newImage( "media/Enemy.png" )
	Gamestate.registerEvents()
    Gamestate.switch(sgame)
end

function hasTile(x,y)
	local p = x .. "x" .. y
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
	camera:detach()
	love.graphics.setColor(0,0,0, 255)
	--love.graphics.print(string.format("%d", fps), 100, 10)
end

function handleTick()
	for i,enemy in ipairs(enemies) do
		enemy:ai()
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
			handleTick()
		end
		if key=="right" then
			player:move(1, 0)
			handleTick()
		end
		if key =="up" then
			player:move(0, -1)
			handleTick()
		end
		if key=="down" then
			player:move(0, 1)
			handleTick()
		end
		if key==" " then
			addPlayer(player.x, player.y)
			handleTick()
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
	players[#players + 1] = Player(x,y)
end

function addEnemey(x,y)
	enemies[#enemies + 1] = Enemy(x,y)
end

function loadWorld()
	map = ATL_Loader.load("map.tmx")
	map.useSpriteBatch = true
	camera = Camera(Vector(1,1))
	players =  {}
	enemies = {}
	addPlayer(2,2)
	addEnemey(5,2)
	addEnemey(10,10)
	addEnemey(6,3)
	addEnemey(4,4)
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
						col[x.."x"..y] = true
					else
						col[x.."x"..y] = false
					end
				end
			end
		end
	end
end