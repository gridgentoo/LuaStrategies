function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Other");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurrentSound,PlaySound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addString("ORDR", resources:get("R_Order"), "", "");
    strategy.parameters:setFlag("ORDR", core.FLAG_ORDER);

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
local TRD;
local MSG;

function Prepare(onlyName)

    ORDR = instance.parameters.ORDR;

    local name = profile:id() .. "(" .. ORDR .. ")";
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

    ExtSetupSignal(resources:get("R_Name") .. ":", ShowAlert);
    ExtSetupSignalMail(name);

    local table = core.host:findTable("orders");
    if core.host:execute("isTableFilled", "orders") and (table:find("OrderID", ORDR) == nil) then
        signaled = true;
    else
        MSG = resources:get("R_MSG") .. "(" .. ORDR .. ")";
    end
end

-- when tick source is updated
function Update()
    if core.host:execute("isTableFilled", "orders") and core.host:execute("isTableFilled", "trades") and core.host:execute("isTableFilled", "closed trades") and not(signaled) then
        local orders = core.host:findTable("orders");
        local trades = core.host:findTable("trades");
        local history = core.host:findTable("closed trades");
        if (orders:find("OrderID", ORDR) == nil) then
            local trade = trades:find("OpenOrderID", ORDR);
            local closed = history:find("CloseOrderID", ORDR);
            if (trade ~= nil) then
                MSG = MSG .. " " .. resources:get("R_POSITION_OPENED") .. "(" .. trade.TradeID .. ", " ..
                trade.Instrument .. ", " .. trade.Lot .. ", " .. trade.BS ..")";
                ExtSignal(instance.bid, instance.bid:size() - 1, MSG, SoundFile, Email, RecurrentSound);
            elseif (closed ~= nil) then
                MSG = MSG .. " " .. resources:get("R_POSITION_CLOSED") .. "(" .. closed.TradeID .. ", " ..
                closed.Instrument .. ", " .. closed.Lot .. ", " .. closed.BS .. ")";
                ExtSignal(instance.bid, instance.bid:size() - 1, MSG, SoundFile, Email, RecurrentSound);
            else
                MSG = resources:get("R_MSG_REMOVED") .. "(" .. ORDR .. ")";
                ExtSignal(instance.bid, instance.bid:size() - 1, MSG, SoundFile, Email, RecurrentSound);
            end
            signaled = true;
        end
    end
    if signaled then
        core.host:execute("stop");
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helperAlert.lua");
