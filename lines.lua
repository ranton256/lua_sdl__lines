local SDL = require "SDL"
local image = require "SDL.image" 

local ret, err = SDL.init {
	SDL.flags.Video,
	SDL.flags.Audio
}

if not ret then
	error(err)
	os.exit(27)
end

local running	= true
local graphics	= { }
local numLines = 60
local lines = {}

local margin = 3
local deltaTop = 3
local deltaBottom = 3
local deltaLeft = 3
local deltaRight = 3

-- Show the version
print(string.format("SDL %d.%d.%d",
    SDL.VERSION_MAJOR,
    SDL.VERSION_MINOR,
    SDL.VERSION_PATCH
))

-- Create a window
graphics.screenWidth = 640
graphics.screenHeight = 480

local win, err = SDL.createWindow {
	title   = "Lua SDL Lines",
	width   = graphics.screenWidth, height  = graphics.screenHeight,
	-- flags   = {SDL.window.Resizable},
	-- x       = 200, y       = 100,
}


if not win then
	error(err)
	os.exit(28)
end

function RandomLine()
	local xmin = margin
	local xmax = graphics.screenWidth - margin
	local ymin = margin
	local ymax = graphics.screenHeight - margin
	local l = {}
	l.x1 = math.random(xmin, xmax)
	l.y1 = math.random(ymin, ymax)
	l.x2 =  math.random(xmin, xmax)
	l.y2 = math.random(ymin, ymax)
	print("gen line:", l.x1, l.y1, l.x2, l.y2)	
	return l
end

function RecalcLine(lines, i)
	-- This is all inspired by flying lines from Macintosh C Programming Primer
	lines[i].y1 = lines[i].y1 + deltaTop
	if (lines[i].y1 < 0) or (lines[i].y1 >= graphics.screenHeight) then
		deltaTop = -deltaTop
		lines[i].y1 = lines[i].y1 + 2*deltaTop
	end

	lines[i].y2 = lines[i].y2 + deltaBottom
	if (lines[i].y2) < 0 or (lines[i].y2 >= graphics.screenHeight) then
		deltaBottom = -deltaBottom
		lines[i].y2 = lines[i].y2 + 2*deltaBottom
	end

	lines[i].x1 = lines[i].x1 + deltaLeft
	if (lines[i].x1 < 0) or (lines[i].x1 >= graphics.screenWidth) then
		deltaLeft = -deltaLeft
		lines[i].x1 = lines[i].x1 + 2*deltaLeft
	end

	lines[i].x2 = lines[i].x2 + deltaRight
	if (lines[i].x2 < 0) or (lines[i].x2 >= graphics.screenWidth) then
		deltaRight = -deltaRight
		lines[i].x2 = lines[i].x2 + 2*deltaRight
	end
		
end

function CopyLine(orig)
	local l = {}
	l.x1 = orig.x1
	l.y1 = orig.y1
	l.x2 = orig.x2
	l.y2 = orig.y2
	return l
end

function InitLines(lines)
	-- 
	math.randomseed(os.time())
	lines[0] = RandomLine()
	for idx = 1, numLines do
		lines[idx] = CopyLine(lines[idx - 1])
		RecalcLine(lines, idx) -- lines[idx] = RandomLine()
	end
end

-- init images
local formats, ret, err = image.init { image.flags.PNG }
if not formats[image.flags.PNG] then
	error(err)
end

-- load the background image
-- this is from https://openclipart.org/detail/218813
-- specifically, https://openclipart.org/image/400px/218813
local img, ret = image.load("218813.png")
if not img then
	error(err)
end

local rdr, err = SDL.createRenderer(win, 0, 0)
if not rdr then
	error(err)
end

bg_img = rdr:createTextureFromSurface(img)
print("loaded image")


local img, ret = image.load("Lua-SDL2.png")
if not img then
	error(err)
end

-- Store in global graphics
graphics.win	= win
graphics.rdr	= rdr
graphics.bg_img = bg_img


InitLines(lines)

-- Poll for events
running = true
while running do
	-- examples of catching keyboard and mouse events
	for e in SDL.pollEvent() do
			if e.type == SDL.event.Quit then
					running = false
			elseif e.type == SDL.event.KeyDown then
					print(string.format("key down: %d -> %s", e.keysym.sym, SDL.getKeyName(e.keysym.sym)))
			elseif e.type == SDL.event.MouseWheel then
					print(string.format("mouse wheel: %d, x=%d, y=%d", e.which, e.x, e.y))
			elseif e.type == SDL.event.MouseButtonDown then
					print(string.format("mouse button down: %d, x=%d, y=%d", e.button, e.x, e.y))
			elseif e.type == SDL.event.MouseMotion then
					print(string.format("mouse motion: x=%d, y=%d", e.x, e.y))
			end
	end

	-- update the screen
    rdr:setDrawColor(0xFFFFFF)

    -- SDL.delay(100)

	graphics.rdr:clear()
	-- background image
    graphics.rdr:copy(graphics.bg_img)

	graphics.rdr:setDrawColor(0xFF0088)

	graphics.rdr:drawLine(lines[numLines - 1])

	for ln = numLines, 1, -1 do
		lines[ln] = CopyLine(lines[ln - 1])
	end
	RecalcLine(lines, 0)
	for idx = 1, numLines do
		graphics.rdr:drawLine(lines[idx])
	end

	graphics.rdr:present()

	SDL.delay(20)
end


SDL.quit()

