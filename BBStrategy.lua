function Init() --The strategy profile initialization

    require("OrderMan2");
    strategy:name("BB Strategy");
    strategy:description("Bollinger Band Strategy");

    strategy.parameters:addGroup("Parameters");
    strategy.parameters:addString("TF", "Time Frame", "", "H1");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);
    strategy.parameters:addInteger("BBperiod", "BB periods", "BB periods", 20);
    strategy.parameters:addInteger("ATRMultiple", "ATR Multiple", "Multiple of ATR for tolerance", 1);

    strategy.parameters:addGroup("Strategy Parameters");
    strategy.parameters:addString("TypeSignal", "Type of signal", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "direct", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "reverse", "", "reverse");

    OrderMan2.init(strategy);
end

-- Internal indicators
local BB;
local ATR;

function Prepare()

    local name;
    name = profile:id() .. "(" .. instance.bid:name() .. "." .. instance.parameters.TF .. "," .. ")";
    instance:name(name);

    require("OrderMan2");

    Source = ExtSubscribe(25, nil, instance.parameters.TF, true, "bar");
    BB = core.indicators:create("BB", Source.close, instance.parameters.BBperiod);
    ATR = core.indicators:create("ATR", Source);
    OrderMan2.prepare(instance, name, Source);
   
end

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.

    BB:update(core.UpdateLast);
    ATR:update(core.UpdateLast);

    -- Check that we have enough data
    if (BB.DATA:first() > (period - 1)) then
        return
    end

    local MustOpenB=false;
    local MustOpenS=false;
    local BBhi =  BB:getStream(0);
    local BBlo =  BB:getStream(1);
    local BBavg = BB:getStream(2);
    
	if core.crossesOver(source.close, BBhi, period) then
		if instance.parameters.TypeSignal=="direct" then
            MustOpenB=true;
            MustOpenS=false;
        else
            MustOpenS=true;
            MustOpenB=false;
        end
    elseif core.crossesUnder(source.close, BBlo, period) then
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
