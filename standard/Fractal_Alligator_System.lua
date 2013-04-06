-- Strategy profile initialization routine
-- Defines Strategy profile properties and Strategy parameters
function Init()
    strategy:name(resources:get("R_Name"));
    strategy:description(resources:get("R_Description"));
    strategy:setTag("group", "Bill Williams");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,RecurSound,PlaySound,ShowAlert");
    strategy:type(core.Both);

    strategy.parameters:addGroup(resources:get("R_Price_ParamGroup"));
    strategy.parameters:addString("TF", resources:get("R_TF"), resources:get("R_TimeFrame"), "m30");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);

    strategy.parameters:addGroup(resources:get("R_Alligator_ParamGroup"));
    strategy.parameters:addInteger("JawN", resources:get("R_JawN"), "", 13);
    strategy.parameters:addInteger("JawS", resources:get("R_JawS"), "", 8);

    strategy.parameters:addInteger("TeethN", resources:get("R_TeethN"), "", 8);
    strategy.parameters:addInteger("TeethS", resources:get("R_TeethS"), "", 5);

    strategy.parameters:addInteger("LipsN", resources:get("R_LipsN"), "", 5);
    strategy.parameters:addInteger("LipsS", resources:get("R_LipsS"), "", 3);

    strategy.parameters:addString("MTH", resources:get("R_Smooth"), resources:get("R_MTH_description"), "SMMA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_MVA"), "", "MVA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_EMA"), "", "EMA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_LWMA"), "", "LWMA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_SMMA"), "", "SMMA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_Vidya1995"), "", "VIDYA");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_Vidya1992"), "", "VIDYA92");
    strategy.parameters:addStringAlternative("MTH", resources:get("R_string_alt_MTH_Wilders"), "", "WMA");

    strategy.parameters:addGroup(resources:get("R_Trading_ParamGroup"));
    strategy.parameters:addBoolean("AllowTrade", resources:get("R_AllowTrade"), "", false);
    strategy.parameters:setFlag("AllowTrade", core.FLAG_ALLOW_TRADE);
    strategy.parameters:addString("Account", resources:get("R_Account2Trade"), "", "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("Amount", resources:get("R_TradeAmountLots"), "", 1, 1, 100);
    strategy.parameters:addBoolean("SetLimit", resources:get("R_SetLimitOrders"), "", false);
    strategy.parameters:addInteger("Limit", resources:get("R_LimitOrderPips"), "", 30, 1, 10000);
    strategy.parameters:addBoolean("SetStop", resources:get("R_SetStopOrders"), "", false);
    strategy.parameters:addInteger("Stop", resources:get("R_StopOrderPips"), "", 30, 1, 10000);
    strategy.parameters:addBoolean("TrailingStop", resources:get("R_TrailingStopOrder"), "", false);

    strategy.parameters:addGroup(resources:get("R_SignalGroup"));
    strategy.parameters:addBoolean("ShowAlert", resources:get("R_ShowAlert"), "", true);
    strategy.parameters:addBoolean("PlaySound", resources:get("R_PlaySound"), "", false);
    strategy.parameters:addBoolean("RecurSound", resources:get("R_RecurrentSound"), "", false);
    strategy.parameters:addFile("SoundFile", resources:get("R_SoundFile"), "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("SendEmail", resources:get("R_SENDEMAIL"), "", false);
    strategy.parameters:addString("Email", resources:get("R_EMAILADDRESS"), "", "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end

-- strategy instance initialization routine
-- Processes strategy parameters and creates output streams
-- TODO: Calculate all constants, create instances all necessary indicators and load all required libraries
-- Parameters block
local gSource = nil; -- the source stream
local PlaySound;
local RecurrentSound;
local SoundFile;
local Email;
local SendEmail;
local AllowTrade;
local Account;
local Amount;
local BaseSize;
local SetLimit;
local Limit;
local SetStop;
local Stop;
local TrailingStop;
local Offer;
local CanClose;
local Direction
--TODO: Add variable(s) for your indicator(s) if needed
local ALLIGATOR
local CID = 'Fractal_Alligator_system'
local upFractal, downFractal;

-- Routine
function Prepare(nameOnly)

    local name = profile:id() .. "(" .. instance.bid:instrument() .. ")";
    instance:name(name);

    if nameOnly then
        return ;
    end

    ShowAlert = instance.parameters.ShowAlert;

    PlaySound = instance.parameters.PlaySound;
    if PlaySound then
        RecurrentSound = instance.parameters.RecurSound;
        SoundFile = instance.parameters.SoundFile;
    else
        SoundFile = nil;
    end
    assert(not(PlaySound) or (PlaySound and SoundFile ~= ""), resources:get("R_SoundFileError"));

    SendEmail = instance.parameters.SendEmail;
    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or (SendEmail and Email ~= ""), resources:get("R_EmailAddressError"));

    AllowTrade = instance.parameters.AllowTrade;
    if AllowTrade then
        Account = instance.parameters.Account;
        Amount = instance.parameters.Amount;
        BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account);
        Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
        CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account);
        SetLimit = instance.parameters.SetLimit;
        Limit = instance.parameters.Limit * instance.bid:pipSize();
        SetStop = instance.parameters.SetStop;
        Stop = instance.parameters.Stop * instance.bid:pipSize();
        TrailingStop = instance.parameters.TrailingStop;
    end

    gBidSource = ExtSubscribe(1, nil, instance.parameters.TF, true, "bar");   -- Bid/Sell
    gAskSource = ExtSubscribe(2, nil, instance.parameters.TF, false, "bar");  -- Ask/Buy

    local JawN, JawS = instance.parameters.JawN, instance.parameters.JawS
    local TeethN, TeethS = instance.parameters.TeethN, instance.parameters.TeethS
    local LipsN, LipsS = instance.parameters.LipsN, instance.parameters.LipsS
    local MTH = instance.parameters.MTH

    bALLIGATOR = core.indicators:create("ALLIGATOR", gBidSource, JawN, JawS, TeethN, TeethS,
                                                      LipsN, LipsS, MTH);

    aALLIGATOR = core.indicators:create("ALLIGATOR", gAskSource, JawN, JawS, TeethN, TeethS, LipsN, LipsS, MTH);

    upFractal = core.autoBuffer(gAskSource, 0, 0, UpFractalUpdate, 2);
    downFractal = core.autoBuffer(gBidSource, 0, 0, DownFractalUpdate, 2);

    ExtSetupSignalMail(name);
    ExtSetupSignal(profile:id() .. ":", ShowAlert);
end

-- strategy calculation routine
function ExtUpdate(id, source, period)
    if (id == 1) then
        downFractal:update();
        bALLIGATOR:update(core.UpdateLast)
        -- Set 'Sell' entry order if we do not have
        -- any opened Short positions
        local down, dperiod;
        down = downFractal.DATA[downFractal.DATA:size() - 1];
        dperiod = downFractal.DATA2[downFractal.DATA2:size() - 1];
        if down > 0 then
            if (down < bALLIGATOR.Teeth[dperiod] and down < instance.bid[NOW]) then
                if not haveTrades('S') then
                    if AllowTrade then setEntry('SE', 'S', down) end
                    if ShowAlert and prevDown ~= down then
                        local msg = string.format(resources:get("R_SetSellLevelAt"), tostring(down) .. "," .. core.formatDate(downFractal.DATA:date(dperiod)));
                        ExtSignal(source, period, msg, SoundFile, Email, RecurrentSound)
                        prevDown = down
                    end
                end
            end
        end
    end

    if (id == 2) then
        upFractal:update();
        aALLIGATOR:update(core.UpdateLast)
        if (aALLIGATOR.Teeth:hasData(period)) then
            -- Set 'Buy' entry order if we do not have
            -- any opened Long positions
            local up, uperiod;
            up = upFractal.DATA[upFractal.DATA:size() - 1];
            uperiod = upFractal.DATA2[upFractal.DATA2:size() - 1];
            if up > 0 then
                if (up > aALLIGATOR.Teeth[uperiod] and up > instance.ask[NOW]) then
                    if not haveTrades('B') then
                        if AllowTrade then setEntry('SE', 'B', up) end
                        if ShowAlert and up ~= prevUp then
                            local msg = string.format(resources:get("R_SetBuyLevelAt"), tostring(up) .. "," .. core.formatDate(upFractal.DATA:date(uperiod)));
                            ExtSignal(source, period, msg, SoundFile, Email, RecurrentSound)
                            prevUp = up
                        end
                    end
                end
            end
        end
    end
end



function UpFractalUpdate(period)
    local data, data2, src, i, level, levep, curr;
    src = gAskSource.high;
    data = upFractal.DATA;
    data2 = upFractal.DATA2;
    if period < 6 then
        data[period] = -1;
        data2[period] = -1;
    else
        curr = src[period - 3];
        if (src[period - 5] < curr and src[period - 4] < curr and src[period - 2] < curr and src[period - 1] < curr) then
                level = curr;
                levelp = period - 3;
        else
            level = data[period - 4];
            levelp = data2[period - 4];
        end
        if (data2[period - 2] == levelp) then
            return ;
        end
        for i = period - 3, period, 1 do
            data[i] = level;
            data2[i] = levelp;
        end
    end
end

function DownFractalUpdate(period)
    local data, data2, src, i, level, levelp, curr;
    src = gAskSource.low;
    data = downFractal.DATA;
    data2 = downFractal.DATA2;
    if period < 6 then
        data[period] = -1;
        data2[period] = -1;
    else
        curr = src[period - 3];
        if (src[period - 5] > curr and src[period - 4] > curr and src[period - 2] > curr and src[period - 1] > curr) then
                level = curr;
                levelp = period - 3;
        else
            level = data[period - 4];
            levelp = data2[period - 4];
        end
        if (data2[period - 2] == levelp) then
            return ;
        end
        for i = period - 3, period, 1 do
            data[i] = level;
            data2[i] = levelp;
        end
    end
end

function setEntry(orderType, BuySell, rate)
    -- try to find order in specified direction
    local enum, row;
    enum = core.host:findTable("orders"):enumerator();
    row = enum:next();
    while (row ~= nil) do
        if row.OfferID == Offer and
           row.AccountID == Account and
           row.BS == BuySell  and
           row.Type == orderType and
           row.ContingencyType == 0 then -- nonOCO order,
              break;
        end
        row = enum:next();
    end

    if (row ~= nil) then
        -- exit if Order exist with the same rate
        if (row.Rate == rate) then
            return
        end;

        -- Or delete order in other case
        local valuemap = core.valuemap();

        valuemap.Command = "DeleteOrder"
        valuemap.OrderID = row.OrderID
        local success, msg = terminal:execute(101, valuemap);
        if not(success) then
            terminal:alertMessage(instance.bid:instrument(), instance.bid[NOW], resources:get("R_FailedCreateLimitOrStop") .. ": " .. msg, instance.bid:date(NOW));
        end
    end

    -- Create new order (or to replace deleted)
    local valuemap = core.valuemap();
    valuemap.Command = "CreateOrder";
    valuemap.OrderType = orderType;
    valuemap.OfferID = Offer;
    valuemap.AcctID = Account;
    valuemap.Rate = rate;
    valuemap.BuySell = BuySell;
    valuemap.Quantity = Amount * BaseSize;
    valuemap.CustomID = CID

    if SetLimit then
        -- set limit order
        if BuySell == "B" then
            valuemap.RateLimit = rate + Limit;
        else
            valuemap.RateLimit = rate - Limit;
        end
    end

    if SetStop then
        -- set stop order
        if BuySell == "B" then
            valuemap.RateStop = rate - Stop;
        else
            valuemap.RateStop = rate + Stop;
        end
        if TrailingStop then
            valuemap.TrailStepStop = 1;
        end
    end

    if (not CanClose) and (SetStop or SetLimit) then
        valuemap.EntryLimitStop = 'Y'
    end

    local success, msg;
    success, msg = terminal:execute(102, valuemap);

    if not(success) then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[NOW], resources:get("R_FailedCreateLimitOrStop") .. ": " .. msg, instance.bid:date(NOW));
    end
end

--===========================================================================--
--                    TRADING UTILITY FUNCTIONS                              --
--============================================================================--
function revertBS(BuySell)
    if BuySell == 'B' then
        return 'S'
    else
        return 'B'
    end
end
-- -----------------------------------------------------------------------
-- Function checks that specified table is ready (filled) for processing
-- or that we running under debugger/simulation conditions.
-- -----------------------------------------------------------------------
function checkReady(table)
    local rc;
    if Account == "TESTACC_ID" then
        -- run under debugger/simulator
        rc = true;
    else
        rc = core.host:execute("isTableFilled", table);
    end
    return rc;
end

-- -----------------------------------------------------------------------
-- Return count of opened trades for spicific direction
-- (both directions if BuySell parameters is 'nil')
-- -----------------------------------------------------------------------
function haveTrades(BuySell)
    local enum, row;
    local found = false;

    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();
    while (not found) and (row ~= nil) do
        if row.AccountID == Account and
           row.OfferID == Offer and
           (row.BS == BuySell or BuySell == nil) then
           found = true;
        end
        row = enum:next();
    end
    return found
end

--===========================================================================--
--                      END OF TRADING UTILITY FUNCTIONS                     --
--===========================================================================--

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
