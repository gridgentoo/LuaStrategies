function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Support/Resistance");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurrentSound,PlaySound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addGroup(resources:get("R_ParamGroup"));

    strategy.parameters:addString("Type", resources:get("R_PriceType"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Bid"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Ask"), "", "Ask");

    strategy.parameters:addString("Period", resources:get("R_PeriodType"), "", "t1");
    strategy.parameters:setFlag("Period", core.FLAG_PERIODS);

    strategy.parameters:addGroup(resources:get("R_SignalGroup"));

    strategy.parameters:addBoolean("ShowAlert", resources:get("R_ShowAlert"), "", true);
    strategy.parameters:addBoolean("PlaySound", resources:get("R_PlaySound"), "", false);
    strategy.parameters:addBoolean("RecurrentSound", resources:get("R_RecurrentSound"), "", false);
    strategy.parameters:addFile("SoundFile", resources:get("R_SoundFile"), "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("SendEmail", resources:get("R_SENDEMAIL"), "", false);
    strategy.parameters:addString("Email", resources:get("R_EMAILADDRESS"), resources:get("R_EMAILADDRESSDESCR"), "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end

local SoundFile;
local RecurrentSound;
local SendEmail, Email;
local FastMA, SlowMA;
local PA, PB, PS, PR;
local gSource = nil;        -- the source stream
local gDays = nil;
local offset;
local gLoadingDays = false; -- the flag indicating whether the days are loading

function Prepare(onlyName)

    local name = profile:id() .. "(" .. instance.bid:instrument()  .. "(" .. instance.parameters.Period  .. ")" .. ")";
    instance:name(name);
    if onlyName then
        return;
    end
    
    offset = core.host:execute("getTradingDayOffset");

    ShowAlert = instance.parameters.ShowAlert;

    local PlaySound = instance.parameters.PlaySound;
    if PlaySound then
        SoundFile = instance.parameters.SoundFile;
        RecurrentSound = instance.parameters.RecurrentSound;
    else
        SoundFile = nil;
        RecurrentSound = false;
    end
    assert(not(PlaySound) or (PlaySound and SoundFile ~= ""), resources:get("R_SoundFileError"));

    SendEmail = instance.parameters.SendEmail;
    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or (SendEmail and Email ~= ""), resources:get("R_EmailAddressError"));

    PA = resources:get("R_PA")
    PB = resources:get("R_PB")
    PS = resources:get("R_PS")
    PR = resources:get("R_PR")

    SetSource(instance.parameters.Period, instance.parameters.Type == "Bid");

    -- get last 7 day history
    local dfrom;
    gLoadingDays = true;
    local date;
    if instance.bid:size() == 0 then
        date = core.now();
    else
        date = instance.bid:date(0);
    end
    dfrom = core.getcandle("D1", date, offset) - 7;
    gDays = core.host:execute("getHistory", 2, instance.bid:instrument(), "D1", dfrom, 0, instance.parameters.Type == "Bid");   

    ExtSetupSignal(resources:get("R_Name") .. ":", ShowAlert);
    ExtSetupSignalMail(name);
end

local gCurrDay = nil;
local P, R, S;          -- pivot data

-- when tick source is updated
function Update()
    local period;

    period = GetCandle();
    if period == nil then
        return ;
    end

    if gLoadingDays then
        return ;
    end

    if period == 0 then
        return ;
    end


    -- find the date of the base pivot day for the current period
    local pivotDay, nontrading, temp;
    pivotDay = core.getcandle("D1", gSource:date(period), offset);
    if gCurrDay == nil or pivotDay ~= gCurrDay then
        gCurrDay = pivotDay;
        pivotDay = pivotDay - 1;
        nontrading, temp = core.isnontrading(pivotDay, offset);
        if nontrading then
            pivotDay = temp - 1;
        end
        local dayp = nil;
        -- find the day for pivots
        for i = 0, gDays:size() - 1, 1 do
            if gDays:date(i) <= pivotDay then
                dayp = i;
            else
                break;
            end
        end
        if dayp == nil then
            --local pivotDayTable;
            --pivotDayTable = core.dateToTable(pivotDay);
            --assert (dayp ~= nil, "Historical data is broken, cannot find the pivot day " .. pivotDayTable.year .. "/" .. pivotDayTable.month .. "/" .. pivotDayTable.day);
            return ;
        end
        local r;
        r = gDays.high[dayp] - gDays.low[dayp];
        -- calculate the pivot data
        P = (gDays.high[dayp] + gDays.low[dayp] + gDays.close[dayp]) / 3;
        R = P * 2 - gDays.low[dayp];
        S = P * 2 - gDays.high[dayp];
    end

    if P == nil then
        return ;
    end

    local price = gSource[period];

    -- check conditions
    if core.crossesOver(gSource, P, period) then
        ExtSignal(gSource, period, PA, SoundFile, Email, RecurrentSound)
    elseif core.crossesUnder(gSource, P, period) then
        ExtSignal(gSource, period, PB, SoundFile, Email, RecurrentSound)
    elseif core.crossesOver(gSource, R, period) then
        ExtSignal(gSource, period, PR, SoundFile, Email, RecurrentSound)
    elseif core.crossesUnder(gSource, S, period) then
        ExtSignal(gSource, period, PS, SoundFile, Email, RecurrentSound)
    end
end

--
-- The helper file for the strategies
--
local gExtSource = nil;     -- the reference to the bar stream of the extended source
local gPeriod = nil;        -- the period code
local gLoading = false;     -- the flag indicating whether the data are loading

-- ------------------------------------------------------------------------
-- Sets the source to gSource variable
-- @param period    The period code
-- @param sound     The flag indicating whether bid or ask must be used
-- ------------------------------------------------------------------------
function SetSource(period, bid)
    gPeriod = period;
    if period == "t1" then
        if bid then
            gSource = instance.bid;
        else
            gSource = instance.ask;
        end
    else
        gLoading = true;
        gExtSource = core.host:execute("getHistory", 1, instance.bid:instrument(), period, 0, 0, bid);
        gSource = gExtSource.close;
    end
end

function AsyncOperationFinished(cookie)
    if cookie == 1 then
        gLoading = false;
    elseif cookie == 2 then
        gLoadingDays = false;
    end

end

local gPreviousCandle = nil;
-- -----------------------------------------------------------------------
-- The function returns the period number to be processed or
-- nil in case the candle is not closed yet
-- -----------------------------------------------------------------------
function GetCandle()
    local period;

    if gExtSource ~= nil then
        if gLoading then
            return nil;
        end

        -- for the external source the correct candle is
        -- the previous to the latest candle
        period = gSource:size() - 2;
        if period < gSource:first() then
            return nil;
        end
        -- if we called again to the same previous candle
        -- just return
        local date = gSource:date(period);
        if gPreviousCandle ~= nil and gPreviousCandle >= date then
            return nil;
        end
        gPreviousCandle = date;
        return period;
    else
        return gSource:size() - 1;
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helperAlert.lua");
