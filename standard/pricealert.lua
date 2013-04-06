function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Other");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurrentSound,PlaySound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addGroup(resources:get("R_ParamGroup"));

    strategy.parameters:addString("Type", resources:get("R_PriceType"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Bid"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Ask"), "", "Ask");

    strategy.parameters:addString("Period", resources:get("R_PeriodType"), resources:get("R_PeriodTypeDesc"), "t1");
    strategy.parameters:setFlag("Period", core.FLAG_PERIODS);

    strategy.parameters:addString("Smooth", resources:get("R_Smooth"), resources:get("R_SmoothDesc"), "NO");
    strategy.parameters:addStringAlternative("Smooth", resources:get("R_SmoothNo"), "", "NO");
    strategy.parameters:addStringAlternative("Smooth", "MVA", "", "MVA");
    strategy.parameters:addStringAlternative("Smooth", "EMA", "", "EMA");
    strategy.parameters:addStringAlternative("Smooth", "LWMA", "", "LWMA");
    strategy.parameters:addStringAlternative("Smooth", "TMA", "", "TMA");
    strategy.parameters:addStringAlternative("Smooth", "KAMA", "", "KAMA");
    strategy.parameters:addStringAlternative("Smooth", "SMMA*", "", "SMMA");
    strategy.parameters:addStringAlternative("Smooth", "Vidya (1995)*", "", "VIDYA");
    strategy.parameters:addStringAlternative("Smooth", "Vidya (1992)*", "", "VIDYA92");
    strategy.parameters:addStringAlternative("Smooth", "Wilders*", "", "WMA");
    strategy.parameters:addStringAlternative("Smooth", "TEMA1*", "", "TEMA1");
    strategy.parameters:addInteger("SmoothN", resources:get("R_SmoothN"), "", 7, 1, 300);
    strategy.parameters:addDouble("Price", resources:get("R_Price"), "", 0);
    strategy.parameters:setFlag("Price", core.FLAG_PRICE);
    strategy.parameters:addString("Condition", resources:get("R_Condition"), "", "C");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCross"), "", "C");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCrossOrTouch"), "", "CT");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCrossAbove"), "", "CA");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCrossAboveOrTouches"), "", "CAT");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCrossBelow"), "", "CB");
    strategy.parameters:addStringAlternative("Condition", resources:get("R_ConditionCrossBelowOrTouches"), "", "CBT");

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
local SIGNAL;
local gSource = nil;        -- the source stream
local gSmooth = nil;
local gData = nil;
local SendEmail, Email;
local first;
local CT_CROSS = 1;
local CT_CROSSTOUCH = 2;
local CT_CROSSABOVE = 3;
local CT_CROSSABOVETOUCH = 4;
local CT_CROSSBELOW = 4;
local CT_CROSSBELOWTOUCH = 5;
local gCondition;
local Price;

function Prepare()
    local Type, Period, Smooth, SmoothN, Condition;

    Type = instance.parameters.Type;
    Period = instance.parameters.Period;
    Smooth = instance.parameters.Smooth;
    SmoothN = instance.parameters.SmoothN;
    Price = instance.parameters.Price;
    Condition = instance.parameters.Condition;

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

    gSource = ExtSubscribe(1, nil, Period, Type == "Bid", "close");

    local dn, cn;

    dn = instance.bid:instrument() .. "(" .. Period .. ")";
    if Smooth == "NO" then
        gData = gSource;
    else
        gSmooth = core.indicators:create(Smooth, gSource, SmoothN);
        gData = gSmooth.DATA;
        dn = Smooth .. "(" .. dn .. "," .. SmoothN .. ")";
    end
    first = gData:first() + 1;

    if Condition == "C" then
        cn = resources:get("R_ConditionCross");
        gCondition = CT_CROSS;
    elseif Condition == "CT" then
        cn = resources:get("R_ConditionCrossOrTouch");
        gCondition = CT_CROSSTOUCH;
    elseif Condition == "CA" then
        cn = resources:get("R_ConditionCrossAbove");
        gCondition = CT_CROSSABOVE;
    elseif Condition == "CAT" then
        cn = resources:get("R_ConditionCrossAboveOrTouches");
        gCondition = CT_CROSSABOVETOUCH;
    elseif Condition == "CB" then
        cn = resources:get("R_ConditionCrossBelow");
        gCondition = CT_CROSSBELOW;
    elseif Condition == "CBT" then
        cn = resources:get("R_ConditionCrossBelowOrTouches");
        gCondition = CT_CROSSBELOWTOUCH;
    end

    local name = profile:id() .. "(" .. dn .. " " .. cn .. " " .. Price .. ")";
    instance:name(name);

    --localization
    SIGNAL = resources:get("R_SIGNAL")

    ExtSetupSignal(name .. ":", ShowAlert);
    ExtSetupSignalMail(name);
end

-- when tick source is updated
function ExtUpdate(id, source, period)
    -- update moving average
    if gSmooth ~= nil then
        gSmooth:update(core.UpdateLast);
    end

    if period > first then
        if gCondition == CT_CROSS and core.crosses(gData, Price, period) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        elseif gCondition == CT_CROSSTOUCH and (core.crosses(gData, Price, period) or gData[period] == Price) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        elseif gCondition == CT_CROSSABOVE and core.crossesOver(gData, Price, period) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        elseif gCondition == CT_CROSSABOVETOUCH and (core.crossesOver(gData, Price, period) or gData[period] == Price) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        elseif gCondition == CT_CROSSBELOW and core.crossesUnder(gData, Price, period) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        elseif gCondition == CT_CROSSBELOWTOUCH and (core.crossesUnder(gData, Price, period) or gData[period] == Price) then
            ExtSignal(gSource, period, SIGNAL, SoundFile, Email, RecurrentSound);
        end
    end
end


dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");

