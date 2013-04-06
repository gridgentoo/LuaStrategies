function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Oscillators");
    strategy:setTag("NonOptimizableParameters", "SendEmail,PlaySound,Email,SoundFile,RecurrentSound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addGroup(resources:get("R_ParamGroup"));

    strategy.parameters:addInteger("CCIN", resources:get("R_CCIN"), "", 14, 2, 200);

    strategy.parameters:addString("Type", resources:get("R_PriceType"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Bid"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Ask"), "", "Ask");

    strategy.parameters:addString("Period", resources:get("R_PeriodType"), "", "m1");
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
local CCI;
local BUY, SELL;
local gSource = nil;        -- the source stream
local SendEmail, Email;

function Prepare(onlyName)
    local CCIN;

    -- collect parameters
    CCIN = instance.parameters.CCIN;

    -- set the name 
    local name = profile:id() .. "(" .. instance.bid:instrument() .. "(" .. instance.parameters.Period  .. ")" .. "," .. CCIN .. ")";
    instance:name(name);    
    if onlyName then
        return;
    end


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
   
    assert(instance.parameters.Period ~= "t1", resources:get("R_SrcErr"));

    gSource = ExtSubscribe(1, nil, instance.parameters.Period, instance.parameters.Type == "Bid", "bar");

    CCI = core.indicators:create("CCI", gSource, CCIN);
    
    --localization
    BUY = resources:get("R_BUY")
    SELL = resources:get("R_SELL")
    ExtSetupSignal(resources:get("R_Name") .. ":", ShowAlert);
    ExtSetupSignalMail(name);   
end

-- when tick source is updated
function ExtUpdate(id, source, period)
    -- update moving average
    CCI:update(core.UpdateLast);

    if not(CCI.DATA:hasData(period - 1)) then
        return ;
    end

   if core.crossesOver(CCI.DATA, 100, period) then
        ExtSignal(gSource, period, BUY, SoundFile, Email, RecurrentSound);
   elseif core.crossesUnder(CCI.DATA, -100, period) then
        ExtSignal(gSource, period, SELL, SoundFile, Email, RecurrentSound);
   end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
