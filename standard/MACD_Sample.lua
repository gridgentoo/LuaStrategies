function Init() --The strategy profile initialization
    strategy:name(resources:get("name"));
    strategy:description(resources:get("description"));
    strategy:setTag("group", "Oscillators");
    strategy:setTag("NonOptimizableParameters", "Email,SendEmail,SoundFile,Recurrent,PlaySound,ShowAlert");
    strategy:type(core.Both);

    strategy.parameters:addGroup(resources:get("param_MACD_ParamGroup"));
    strategy.parameters:addInteger("SN", resources:get("param_SN_name"), resources:get("param_SN_description"), 16, 2, 1000);
    strategy.parameters:addInteger("LN", resources:get("param_LN_name"), resources:get("param_LN_description"), 30, 2, 1000);
    strategy.parameters:addInteger("IN", resources:get("param_IN_name"), resources:get("param_IN_description"), 14, 2, 1000);


    strategy.parameters:addGroup(resources:get("param_Strategy_ParamGroup"));
    strategy.parameters:addInteger("MACDOpenLevel", resources:get("param_MACDOpenLevel_name"), resources:get("param_MACDOpenLevel_description"), 3, 1, 1000)
    strategy.parameters:addInteger("MACDCloseLevel", resources:get("param_MACDCloseLevel_name"), resources:get("param_MACDCloseLevel_description"), 2, 1, 100)
    strategy.parameters:addBoolean("ConfirmTrend", resources:get("param_ConfirmTrend_name"), resources:get("param_ConfirmTrend_description"), false);
    strategy.parameters:addInteger("MN", resources:get("param_MN_name"), resources:get("param_MN_description"), 26, 2, 1000);

    strategy.parameters:addGroup(resources:get("param_Price_ParamGroup"));
    strategy.parameters:addString("TF", resources:get("param_TF_name"), "", "H1");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);

    strategy.parameters:addGroup(resources:get("R_Trading_ParamGroup"));
    strategy.parameters:addBoolean("AllowTrade", resources:get("R_AllowTrade"), "", false);
    strategy.parameters:setFlag("AllowTrade", core.FLAG_ALLOW_TRADE);
    strategy.parameters:addString("Account", resources:get("R_Account2Trade"), "", "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("Amount", resources:get("R_TradeAmountLots"), "", 1, 1, 100);
    strategy.parameters:addBoolean("SetLimit", resources:get("param_SetLimit_name"), "", false);
    strategy.parameters:addInteger("Limit", resources:get("param_Limit_name"), "", 30, 1, 10000);
    strategy.parameters:addBoolean("SetStop", resources:get("param_SetStop_name"), "", false);
    strategy.parameters:addInteger("Stop", resources:get("param_Stop_name"), "", 30, 1, 10000);
    strategy.parameters:addBoolean("TrailingStop", resources:get("param_TrailingStop_name"), "", false);

    strategy.parameters:addGroup(resources:get("R_SignalGroup"));
    strategy.parameters:addBoolean("ShowAlert", resources:get("R_ShowAlert"), "", true);
    strategy.parameters:addBoolean("PlaySound", resources:get("R_PlaySound") , "", false);
    strategy.parameters:addFile("SoundFile", resources:get("R_SoundFile"), "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("Recurrent", resources:get("R_RecurrentSound"), "", false);

    strategy.parameters:addGroup(resources:get("R_Email_ParamGroup"));
    strategy.parameters:addBoolean("SendEmail", resources:get("R_SENDEMAIL"), "", false);
    strategy.parameters:addString("Email", resources:get("R_EMAILADDRESS"), "", "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end

-- Signal Parameters
local ShowAlert;
local SoundFile;
local RecurrentSound;
local SendEmail, Email;

-- Internal indicators
local MACD = nil;
local EMA = nil;

-- Strategy parameters
local openLevel = 0
local closeLevel = 0
local confirmTrend;

-- Trading parameters
local AllowTrade = nil;
local Account = nil;
local Amount = nil;
local BaseSize = nil;
local PipSize;
local SetLimit = nil;
local Limit = nil;
local SetStop = nil;
local Stop = nil;
local TrailingStop = nil;
local CanClose = nil;

--
--
--
function Prepare()
    ShowAlert = instance.parameters.ShowAlert;
    local PlaySound = instance.parameters.PlaySound
    if  PlaySound then
        SoundFile = instance.parameters.SoundFile;
    else
        SoundFile = nil;
    end
    assert(not(PlaySound) or SoundFile ~= "", resources:get("R_SoundFileError"));
    RecurrentSound = instance.parameters.Recurrent;

    local SendEmail = instance.parameters.SendEmail;
    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or Email ~= "", resources:get("R_EmailAddressError"));
    assert(instance.parameters.TF ~= "t1", resources:get("assert_NoTicks"));

    local name;
    name = profile:id() .. "(" .. instance.bid:name() .. "." .. instance.parameters.TF .. "," ..
           "MACD(" .. instance.parameters.SN .. "," .. instance.parameters.LN .. "," .. instance.parameters.IN .. "))";
    instance:name(name);


    openLevel  = instance.parameters.MACDOpenLevel * instance.bid:pipSize()
    closeLevel = instance.parameters.MACDCloseLevel * instance.bid:pipSize()
    confirmTrend = instance.parameters.ConfirmTrend;

    AllowTrade = instance.parameters.AllowTrade;
    if AllowTrade then
        Account = instance.parameters.Account;
        Amount = instance.parameters.Amount;
        BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account);
        Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
        CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account);
        PipSize = instance.bid:pipSize();
        SetLimit = instance.parameters.SetLimit;
        Limit = instance.parameters.Limit * instance.bid:pipSize();
        SetStop = instance.parameters.SetStop;
        Stop = instance.parameters.Stop * instance.bid:pipSize();
        TrailingStop = instance.parameters.TrailingStop;
    end

    CloseSource = ExtSubscribe(2, nil, instance.parameters.TF, true, "close");
    MACD = core.indicators:create("MACD", CloseSource, instance.parameters.SN, instance.parameters.LN, instance.parameters.IN);
    EMA = core.indicators:create("EMA", CloseSource, instance.parameters.MN);

    ExtSetupSignal(profile:id() .. ":", ShowAlert);
    ExtSetupSignalMail(name);
end

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.
    MACD:update(core.UpdateLast)
    EMA:update(core.UpdateLast)

    -- Check that we have enough data
    if (MACD.SIGNAL:first() > (period - 1) or EMA.EMA:first() > (period - 1)) then
        return
    end

    local macd, signal = MACD.MACD, MACD.SIGNAL
    local ma = EMA.EMA
    local pipSize = instance.bid:pipSize()

    local trades = core.host:findTable("trades");
    if (not haveTrades()) then
        -- Open BUY (Long) position if MACD line crosses over SIGNAL line
        -- in negative area below openLevel. Also check MA trend if
        -- confirmTrend flag is 'true'
        if (macd[period] < 0 and core.crossesOver(macd, signal, period) and math.abs(macd[period]) > openLevel and
            (not confirmTrend or ma[period] > ma[period - 1])) then

            if ShowAlert then
                ExtSignal(source, period, "BUY", SoundFile, Email, RecurrentSound)
            end

            if AllowTrade then
                enter("B")
            end
        end

        -- Open SELL (Short) position if MACD line crosses under SIGNAL line
        -- in positive area above openLevel. Also check MA trend if
        -- confirmTrend flag is 'true'
        if (macd[period] > 0 and core.crossesUnder(macd, signal, period) and macd[period] > openLevel and
           (not confirmTrend or ma[period] < ma[period - 1])) then
            if ShowAlert then
                ExtSignal(source, period, "SELL", SoundFile, Email, RecurrentSound)
             end

            if AllowTrade then
                enter("S")
            end
        end
    else
        local enum = trades:enumerator();
        while true do
            local row = enum:next();
            if row == nil then break end

            if row.AccountID == Account and row.OfferID == Offer then
                    -- Close position if we have corresponding closing conditions.
                if row.BS == 'B' then
                    if (macd[period] > 0 and core.crossesUnder(macd, signal, period) and macd[period] > closeLevel) then
                        if ShowAlert then
                            ExtSignal(source, period, "SELL", SoundFile, Email, RecurrentSound);
                        end

                        if AllowTrade then
                            exit(row.BS);
                        end
                    end
                elseif row.BS == 'S' then
                    if (macd[period] < 0 and core.crossesOver(macd, signal, period) and math.abs(macd[period]) > closeLevel) then
                        if ShowAlert then
                            ExtSignal(source, period, "BUY", SoundFile, Email, RecurrentSound);
                        end

                        if AllowTrade then
                            exit(row.BS);
                        end
                    end
                end

            end
        end
    end
end

function ExtAsyncOperationFinished(cookie, successful, message)
    if not successful then
        assert(successful, message);
        return;
    end
end

--===========================================================================--
--                    TRADING UTILITY FUNCTIONS                              --
--============================================================================--

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

-- enter into the specified direction
function enter(BuySell)
    if not(AllowTrade) then
        return true;
    end

    local valuemap, success, msg;

    -- do not enter if position in the
    -- specified direction already exists
    if haveTrades(BuySell) then
        return true;
    end

    valuemap = core.valuemap();

    valuemap.OrderType = "OM";
    valuemap.OfferID = Offer;
    valuemap.AcctID = Account;
    valuemap.Quantity = Amount * BaseSize;
    valuemap.BuySell = BuySell;
    valuemap.PegTypeStop = "M";

    if SetLimit then
        -- set limit order
        if BuySell == "B" then
            valuemap.RateLimit = instance.ask[NOW] + Limit;
        else
            valuemap.RateLimit = instance.bid[NOW] - Limit;
        end
    end

    if SetStop then
        -- set limit order
        if BuySell == "B" then
            valuemap.RateStop = instance.ask[NOW] - Stop;
        else
            valuemap.RateStop = instance.bid[NOW] + Stop;
        end
        if TrailingStop then
            valuemap.TrailStepStop = 1;
        end
    end

    if (not CanClose) and (SetStop or SetLimit) then
        valuemap.EntryLimitStop = 'Y'
    end
    
    success, msg = terminal:execute(100, valuemap);

    if not(success) then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], resources:get("alert_OpenOrderFailed") .. msg, instance.bid:date(instance.bid:size() - 1));
        return false;
    end

    return true;
end

-- exit from the specified direction
function exit(BuySell)
    if not(AllowTrade) then
        return ;
    end

    local valuemap, success, msg;
    if haveTrades(BuySell) then
        valuemap = core.valuemap();

        -- switch the direction since the order must be in oppsite direction
        if BuySell == "B" then
            BuySell = "S";
        else
            BuySell = "B";
        end
        valuemap.OrderType = "CM";
        valuemap.OfferID = Offer;
        valuemap.AcctID = Account;
        valuemap.NetQtyFlag = "Y";
        valuemap.BuySell = BuySell;
        success, msg = terminal:execute(101, valuemap);

        if not(success) then
            terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], resources:get("alert_OpenOrderFailed") .. msg, instance.bid:date(instance.bid:size() - 1));
        end
    end
end

--===========================================================================--
--                      END OF TRADING UTILITY FUNCTIONS                     --
--===========================================================================--
dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
