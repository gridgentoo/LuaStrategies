function Init() --The strategy profile initialization

    require("OrderMan2");
    strategy:name("Multi SuperTrend Strategy");
    strategy:description("Multi SuperTrend Strategy");

    strategy.parameters:addGroup("Parameters");
    strategy.parameters:addInteger("Max", "Max trend to follow", "Max trend to follow", 3);

    strategy.parameters:addGroup("Strategy Parameters");
    strategy.parameters:addString("TypeSignal", "Type of signal", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "direct", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "reverse", "", "reverse");

    OrderMan2.init(strategy);
end

-- Signal Parameters
local ShowAlert;
local SoundFile;
local RecurrentSound;
local SendEmail, Email;

-- Internal indicators
local MST = {};

-- Strategy parameters
local openLevel = 0
local closeLevel = 0
local confirmTrend;
local ids;

function Prepare()

    local name;
    name = profile:id() .. "(" .. instance.bid:name() .. "." .. instance.parameters.Max .. "," .. ")";
    instance:name(name);

    require("OrderMan2");

    Source = {};
    ids = { "H4", "H8", "D1" };
    
    for key, value in pairs(ids)
    do
        Source[key] = ExtSubscribe(key, nil, value, true, "bar");
        MST[key] = core.indicators:create("SUPERTRENDOSCILLATOR", Source[key]);
        
        if (value == "H4") then
            OrderMan2.prepare(instance, name, Source[key]);
        end
    end
    
end

local bopen = {};
local sopen = {};

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.

    MST[id]:update(core.UpdateLast);

    -- Check that we have enough data
    if (MST[id].DATA:first() > (period - 1)) then
        return
    end

    local MustOpenB=false;
    local MustOpenS=false;

	if core.crossesOver(MST[id].DATA, 0, period) then
		if instance.parameters.TypeSignal=="direct" then
			bopen[id]=true;
            sopen[id]=false;
		else
			sopen[id]=true;
            bopen[id]=false;
		end
    elseif core.crossesUnder(MST[id].DATA, 0, period) then
		if instance.parameters.TypeSignal=="direct" then
			sopen[id]=true;
            bopen[id]=false;
		else
			bopen[id]=true;
            sopen[id]=false;
		end
    end

    local totalB = 0;
    local totalS = 0;
    
    for key, value in pairs(ids)
    do
        if bopen[key] == true then
            totalB = totalB + 1;
        end
        if sopen[key] == true then
            totalS = totalS + 1;
        end
    end
    
    if (totalB == #ids) then
        MustOpenB = true;
    end
    if (totalS == #ids) then
        MustOpenS = true;
    end
    if (ids[id] == "H4" and (MustOpenB or MustOpenS)) then
        core.host:trace(tostring(period) .. ", MustOpenB: " .. tostring(MustOpenB) .. ", MustOpenS: " .. tostring(MustOpenS));
        OrderMan2.update(source, period, MustOpenB, MustOpenS);
    end
end


-- The strategy instance finalization.
function ReleaseInstance()
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
