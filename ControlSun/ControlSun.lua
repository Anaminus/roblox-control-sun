local Plugin = PluginManager():CreatePlugin()
local Toolbar = Plugin:CreateToolbar("Plugins")
local Button = Toolbar:CreateButton("","Activate Control Sun","weather_sun.png")

-- convert number (in hours) to TimeOfDay string
-- because TimeOfDay doesn't cast numbers as expected (3.7 -> 03:07:00 instead of 3:42:00)
local function ToTimeOfDay(n)
	n = n % 24
	local i,f = math.modf(n)
	local m = f*60
	local mi,mf = math.modf(m)
	m = tostring(math.abs(math.floor(m)))
	local s = tostring(math.abs(math.floor(mf*60)))
	return i..":"..string.rep("0",2-#m)..m..":"..string.rep("0",2-#s)..s
end

-- convert TimeOfDay string to number (in hours)
local function FromTimeOfDay(t)
	local signed,h,m,s = t:match("^(%-?)(%d+):(%d+):(%d+)$")
	s = tonumber(s)/60
	m = tonumber(m + s)/60
	h = tonumber(h) + m
	return h * (#signed > 0 and -1 or 1)
end

local function rad_sc(n)
	return n/(math.pi*2)
end

local function sc_rad(n)
	return n*(math.pi*2)
end

-- convert direction to latitude (as GeographicLatitude) and longitude (as TimeOfDay)
local function ToLatLon(d)
	d = Vector3.new(-d.x,-d.y,d.z) -- derp derp derp derp derp
	local lat = math.atan2(d.z,math.sqrt(d.x^2 + d.y^2))
	local lon = math.atan2(d.y,d.x)

	lat = rad_sc(lat)*360 + 23.5
	lon = ToTimeOfDay(rad_sc(lon)*24 - 6)

	return lat,lon
end

--[[
-- convert lat and lon to direction (doesn't work)
local function to_dir(lat,lon)
	lat = sc_rad((lat - 23.5)/360)
	lon = sc_rad((FromTimeOfDay(lon) + 6)/24)

	return Vector3.new(
		(math.cos(lat)*math.cos(lon)),
		(math.cos(lat)*math.sin(lon)),
		math.sin(lat)
	)
end
]]

local Event = {}
local function Disconnect(...)
	for _,name in pairs{...} do
		if Event[name] then
			Event[name]:disconnect()
			Event[name] = nil
		end
	end
end

local Lighting = Game:GetService("Lighting")
local down = false
local function Activate()
	Button:SetActive(true)
	local Mouse = Plugin:GetMouse()
	Event.Down = Mouse.Button1Down:connect(function()
		down = true
	end)

	Event.Up = Mouse.Button1Up:connect(function()
		down = false
	end)

	Event.Move = Mouse.Move:connect(function()
		if down then
			local lat,lon = ToLatLon(Mouse.UnitRay.Direction)
			Lighting.GeographicLatitude = lat
			Lighting.TimeOfDay = lon
		end
	end)
end

local function Deactivate()
	Button:SetActive(false)
	down = false
	Disconnect("Down","Up","Move")
end

local active = false
Button.Click:connect(function()
	active = not active
	if active then
		Plugin:Activate(true)
		Activate()
	else
		Deactivate()
	end
end)

Plugin.Deactivation:connect(Deactivate)
