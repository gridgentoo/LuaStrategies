local NUM_LEVELS = 5;

-- strategy profile initialization routine
-- Defines strategy profile properties and strategy parameters
function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Other");
    strategy:setTag("NoPromptOnStart", "Yes");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurrentSound,PlaySound,ShowAlert");
    strategy:type(core.Signal);

    strategy.parameters:addGroup(resources:get("R_ParamGroup"));

    strategy.parameters:addBoolean("ACCTALL", resources:get("R_AllAccountsParam"), resources:get("R_AllAccountsDesc"), true);

    strategy.parameters:addString("ACCT", resources:get("R_AcctParam"), resources:get("R_AcctDesc"), "");
    strategy.parameters:setFlag("ACCT", core.FLAG_ACCOUNT);

    strategy.parameters:addInteger("UPDATEINTERVAL", resources:get("R_UpdateInterval"), resources:get("R_UpdateIntervalDesc"), 3);
    strategy.parameters:addInteger("HOLDOFF", resources:get("R_AlertHoldoffTimer"), resources:get("R_AlertHoldoffTimerDesc"), 5);

    createLevelsParams(NUM_LEVELS);

    strategy.parameters:addGroup(resources:get("R_SignalGroup"));

    strategy.parameters:addBoolean("ShowAlert", resources:get("R_ShowAlert"), "", true);
    strategy.parameters:addBoolean("PlaySound", resources:get("R_PlaySound"), "", false);
    strategy.parameters:addFile("SoundFile", resources:get("R_SoundFile"), "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("RecurrentSound", resources:get("R_RecurrentSound"), "", false);
    strategy.parameters:addBoolean("SendEmail", resources:get("R_SENDEMAIL"), "", false);
    strategy.parameters:addString("Email", resources:get("R_EMAILADDRESS"), resources:get("R_EMAILADDRESSDESCR"), "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end
local ACCT;
local ACCTALL;

local Email;

local ShowAlert;
local SoundFile;
local RecurrentSound;

local host;


local timerId;
local TIMERCOOKIE = 123;
local timerInterval;
local holdoffTimer;

local usedMargin = {};

local levels = {};

-- preparation
function Prepare(onlyName)
    ACCT = instance.parameters.ACCT;
    ACCTALL = instance.parameters.ACCTALL;
    timerInterval = instance.parameters.UPDATEINTERVAL;
    holdoffTimer = instance.parameters.HOLDOFF * 60/ 86400.0;-- in minutes

    fillLevels(NUM_LEVELS);

    local sAccountString;
    if ACCTALL == true then
        sAccountString = resources:get("R_AllAccounts");
    else
        sAccountString = "" .. ACCT;
    end

    host = core.host;

    local name = profile:id() .. "(" .. sAccountString .. ")";
    instance:name(name);

    if onlyName then
        return ;
    end

    usedMargin.count = 0;

    InitMargin();

    local SendEmail = instance.parameters.SendEmail;
    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or (SendEmail and Email ~= ""), resources:get("R_EmailAddressError"));
    assert(not(instance.parameters.PlaySound) or (instance.parameters.PlaySound and instance.parameters.SoundFile ~= ""), resources:get("R_SoundFileError"));
    ShowAlert = instance.parameters.ShowAlert;

    if instance.parameters.PlaySound then
        SoundFile = instance.parameters.SoundFile;
        RecurrentSound = instance.parameters.RecurrentSound;
    else
        SoundFile = nil;
        RecurrentSound = false;
    end

    timerId = host:execute ("setTimer", TIMERCOOKIE, timerInterval);
    core.host:execute("addCommand", 200001, resources:get("R_StopAlert"), resources:get("R_StopAlertDescr"));
end

function InitMargin()
    if not(core.host:execute("isTableFilled", "accounts")) then
        -- relogin??
        return false;
    end
    if ACCTALL == true then
        local acctEnum = host:findTable("accounts"):enumerator();
        local acctRow;
        local idx = 1;
        acctRow = acctEnum:next();
        while acctRow ~= nil do
            usedMargin[acctRow:cell("AccountName")] = getMargin(acctRow);
            usedMargin.count = usedMargin.count + 1;
            idx = idx + 1;
            acctRow = acctEnum:next();
        end;
    else
        local acctRow = host:findTable("accounts"):find("AccountID", ACCT);
        if acctRow ~= nil then
            usedMargin[acctRow:cell("AccountName")] = getMargin(acctRow);
            usedMargin.count = 1;
        end
    end
    
    return true;
end

function ReleaseInstance()
    host:execute("killTimer", timerId);
end


--------------------------------------------
-- Recalculate margin level and recheck all levels on timer
--------------------------------------------
function AsyncOperationFinished(cookie, successful, message)

    if cookie == 200001 then
        core.host:execute("stop");
        return;
    end

    if (instance.bid:size() <= 0
            or instance.ask:size() <= 0) then
        -- no recalc if there is no data.
        return;
    end
    if usedMargin.count == 0 then
        if not(InitMargin()) then
            return;
        end
    end
    if not(core.host:execute("isTableFilled", "accounts")) then
        return false;
    end

    if ACCTALL == true then
        local acctEnum = host:findTable("accounts"):enumerator();
        local acctRow;
        acctRow = acctEnum:next();
        while acctRow ~= nil do
            checkAcct(acctRow);
            acctRow = acctEnum:next();
        end;
    else
        local acctRow = host:findTable("accounts"):find("AccountID", ACCT);
        checkAcct(acctRow);
    end
end

--------------------------------------------
-- Creates level settings for signal parameters
-- @param numLevels number of possible levels
--------------------------------------------
function createLevelsParams(numLevels)
    for idx = 1, numLevels do
        strategy.parameters:addGroup(resources:get("R_LevelGroup").." "..idx);
        strategy.parameters:addBoolean("LEVEL"..idx.."USE", resources:get("R_UseLevel"), resources:get("R_UseLevelDesc"), ((idx == 1) or (idx == 3)));
        strategy.parameters:addDouble("LEVEL"..idx, resources:get("R_LevelValue"), resources:get("R_LevelValueDesc"), 10*idx);
        strategy.parameters:addString("LEVEL"..idx.."PRCT", resources:get("R_CheckType"), resources:get("R_CheckTypeDesc"), "P");
        strategy.parameters:addStringAlternative("LEVEL"..idx.."PRCT", resources:get("R_CheckTypePercents"), "", "P");
        strategy.parameters:addStringAlternative("LEVEL"..idx.."PRCT", resources:get("R_CheckTypeAmount"), "", "A");
    end
end


--------------------------------------------
-- Read level settings from signal parameters
-- @param numLevels number of possible levels
--------------------------------------------
function fillLevels(numLevels)
    local level;
    for idx = 1, numLevels do
        level = {};
        level.Check = instance.parameters:getBoolean("LEVEL"..idx.."USE");
        level.Level = instance.parameters:getDouble("LEVEL"..idx);
        level.Percentage = instance.parameters:getString("LEVEL"..idx.."PRCT") == "P";
        -- no alert
        level.LastAlert = 0;
        levels[idx] = level;
    end
end

-- strategy calculation routine
function Update()
end


--------------------------------------------
-- Checks margin on account and send alert if one of levels is broken
-- @param acctRow row from accounts table
--------------------------------------------
function checkAcct(acctRow)
    local currentMargin = getMargin(acctRow);
    local acctName = acctRow:cell("AccountName");
    local previousMargin = usedMargin[acctName];

    for idx = 1, #levels do
        if checkMargin(currentMargin, previousMargin, levels[idx]) then
            doAlert(acctName, currentMargin, levels[idx]);
        end
    end

    usedMargin[acctName] = currentMargin;
end

--------------------------------------------
-- Gets margin level for specified account
-- @param acctRow row from accounts table
-- @return table with usable margin and eqity
--------------------------------------------
function getMargin(acctRow)
    local acct = {};
    acct.UsableMargin = acctRow:cell("UsableMargin");
    acct.Equity = acctRow:cell("Equity");
    return acct;
end

--------------------------------------------
-- Checks whether margin level is broken by current margin.
-- @param currentMargin current margin level
-- @param previousMargin previous margin level
-- @param condition margin level condition
-- @return true if level is broken, false otherwise
--------------------------------------------
function checkMargin(currentMargin, previousMargin, condition)
    if condition.Check then
        local currTime = math.max(instance.bid:date(NOW), instance.ask:date(NOW));
        if (currTime - condition.LastAlert < holdoffTimer) then
            return false;
        end
        local curr, prev;

        if condition.Percentage then
            curr = 100 * currentMargin.UsableMargin/currentMargin.Equity;
            prev = 100 * previousMargin.UsableMargin/previousMargin.Equity;
        else
            curr = currentMargin.UsableMargin;
            prev = previousMargin.UsableMargin;
        end

        if (curr < condition.Level) and (prev > condition.Level) then
            condition.LastAlert = currTime;
            return true;
        end
    end
    return false;
end


--------------------------------------------
-- This function alerts trader about the achieved margin level.
-- @param acctName name of account
-- @param currentMargin achieved level of marign
-- @param level crossed margin level
--------------------------------------------
function doAlert(acctName, currentMargin, level)
    local bid = instance.bid;
    local sLevelString, sMarginString;
    local curr;

    if level.Percentage then
        curr = 100 * currentMargin.UsableMargin/currentMargin.Equity;
        sLevelString = string.format("%.2f%%", level.Level);
        sMarginString = string.format("%.2f%%", curr);
    else
        curr = currentMargin.UsableMargin;
        sLevelString = string.format("%.2f", level.Level);
        sMarginString = string.format("%.2f", curr);
    end

    local message = string.format(resources:get("R_AlertMessage"), acctName, sLevelString);

    if ShowAlert then
        terminal:alertMessage(bid:instrument(), bid:tick(NOW), message, bid:date(NOW));
    end
    if SoundFile ~= nil then
        terminal:alertSound(SoundFile, RecurrentSound);
    end
    if Email ~= nil then
        local subject, text = FormatEmail(source, message);
        terminal:alertEmail(Email, subject, text);
    end
end


--------------------------------------------
-- Use this function to format alert email
-- @param source Source stream
-- @param message Signal defined message
--------------------------------------------
function FormatEmail(source, message)
    --format email subject
    local subject = resources:get("R_EmailSubject");
    --format email text
    local delim = "\013\010";
    local messageDescr = message;
    local ttime = core.dateToTable(core.host:execute("convertTime", 1, 4, math.max(instance.bid:date(instance.bid:size() - 1), instance.ask:date(instance.ask:size() - 1))));
    local dateDescr = resources:get("R_MailTimeHeader") .. " " .. string.format("%02i/%02i %02i:%02i", ttime.month, ttime.day, ttime.hour, ttime.min);
    local text = messageDescr .. delim .. dateDescr;
    return subject, text;
end

