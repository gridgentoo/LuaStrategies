function Init() --The strategy profile initialization

    require("OrderMan2");
    strategy:name("SuperTrend Strategy");
    strategy:description("SuperTrend Strategy");

    strategy.parameters:addGroup("Parameters");
    strategy.parameters:addString("TF", "Time Frame", "", "D1");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);
    strategy.parameters:addInteger("N", "Number of periods", "No description", 10);
    strategy.parameters:addDouble("M", "Multiplier", "No description", 1.5);

    strategy.parameters:addGroup("Strategy Parameters");
    strategy.parameters:addString("TypeSignal", "Type of signal", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "direct", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "reverse", "", "reverse");

    OrderMan2.init(strategy);
end

-- Internal indicators
local MST;


function Prepare()

    local name;
    name = profile:id() .. "(" .. instance.bid:name() .. "." .. instance.parameters.TF .. "," .. ")";
    instance:name(name);

    require("OrderMan2");

    Source = ExtSubscribe(24, nil, instance.parameters.TF, true, "bar");
    MST = core.indicators:create("SUPERTRENDOSCILLATOR", Source, instance.parameters.N, instance.parameters.M);
    OrderMan2.prepare(instance, name, Source);
   
end

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.

    MST:update(core.UpdateLast);

    -- Check that we have enough data
    if (MST.DATA:first() > (period - 1)) then
        return
    end

    local MustOpenB=false;
    local MustOpenS=false;

	if core.crossesOver(MST.DATA, 0, period) then
		if instance.parameters.TypeSignal=="direct" then
			MustOpenB=true;
            MustOpenS=false;
		else
			MustOpenS=true;
            MustOpenB=false;
		end
    elseif core.crossesUnder(MST.DATA, 0, period) then
		if instance.parameters.TypeSignal=="direct" then
			MustOpenS=true;
            MustOpenB=false;
		else
			MustOpenB=true;
            MustOpenS=false;
		end
    end

    OrderMan2.update(source, period, MustOpenB, MustOpenS);
end


-- The strategy instance finalization.
function ReleaseInstance()
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
