function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Other");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurrentSound,PlaySound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addString("TRD", resources:get("R_Trade"), "", "");
    strategy.parameters:setFlag("TRD", core.FLAG_TRADE);

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
local signaled = false;
local MSG;

function Prepare(onlyName)

    TRD = instance.parameters.TRD;

    local name = profile:id() .. "(" .. TRD .. ")";
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

    local table = core.host:findTable("trades");
    if table:find("TradeID", TRD) == nil then
        signaled = true;
    else
        MSG = resources:get("R_MSG") .. "(" .. TRD .. ")";
    end
end

-- when tick source is updated
function Update()    
    if not(signaled) then
        local table = core.host:findTable("closed trades");
        if (table:find("TradeID", TRD) ~= nil) then
            ExtSignal(instance.bid, instance.bid:size() - 1, MSG, SoundFile, Email, RecurrentSound);
            signaled = true;
        end
    end
    if signaled then
        core.host:execute("stop");
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helperAlert.lua");
