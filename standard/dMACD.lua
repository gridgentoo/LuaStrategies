function Init()
    strategy:name(resources:get("name"));
    strategy:description(resources:get("description"));
    strategy:setTag("group", "Oscillators");
    strategy:setTag("NonOptimizableParameters", "Version,isNeedLogOrders");
    strategy:type(core.Both);

    strategy.parameters:addGroup(resources:get("R_ParamGroup"));

    strategy.parameters:addInteger("SN", resources:get("param_SN_name"), "", 5, 1, 200);
    strategy.parameters:addInteger("LN", resources:get("param_LN_name"), "", 34, 1, 200);
    strategy.parameters:addInteger("IN", resources:get("param_IN_name"), "", 5, 1, 200);

    strategy.parameters:addString("Type", resources:get("R_PriceType"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Bid"), "", "Bid");
    strategy.parameters:addStringAlternative("Type", resources:get("R_Ask"), "", "Ask");

    strategy.parameters:addString("Period", resources:get("R_PeriodType"), "", "m15");
    strategy.parameters:setFlag("Period", core.FLAG_PERIODS);

    strategy.parameters:addGroup(resources:get("param_MACD_ParamGroup"));
    strategy.parameters:addString("MACDStream", resources:get("param_MACDStream_name"), "", "MACD");
    strategy.parameters:addStringAlternative("MACDStream", resources:get("string_alternative_MACDStream_MACD"), "", "MACD");
    strategy.parameters:addStringAlternative("MACDStream", resources:get("string_alternative_MACDStream_SIGNAL"), "", "SIGNAL");
    strategy.parameters:addStringAlternative("MACDStream", resources:get("string_alternative_MACDStream_HISTOGRAM"), "", "HISTOGRAM");

    strategy.parameters:addGroup(resources:get("param_Divergence_ParamGroup"));
    strategy.parameters:addBoolean("isNeedToConfirm", resources:get("param_isNeedToConfirm_name"), "", true);

    strategy.parameters:addGroup(resources:get("R_Trading_ParamGroup"));
    strategy.parameters:addBoolean("isNeedAutoTrading", resources:get("R_AllowTrade"), "", false);
    strategy.parameters:setFlag("isNeedAutoTrading", core.FLAG_ALLOW_TRADE);
    strategy.parameters:addString("Account", resources:get("R_Account2Trade"), resources:get("param_Account_description"), "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("tradeSize", resources:get("param_tradeSize_name"), "", 1, 1, 10000);

    strategy.parameters:addGroup(resources:get("param_Margin_ParamGroup"));
    strategy.parameters:addBoolean("isNeedMarginCare", resources:get("param_isNeedMarginCare_name"), "", false);
    strategy.parameters:addDouble("margin", resources:get("param_margin_name"), resources:get("param_margin_description"), 0);

    strategy.parameters:addGroup(resources:get("param_PL_ParamGroup"));
    strategy.parameters:addBoolean("isNeedPLCare", resources:get("param_isNeedPLCare_name"), resources:get("param_isNeedPLCare_description1") ..
                                                                                                 resources:get("param_isNeedPLCare_description2"), false);

    strategy.parameters:addDouble("profit", resources:get("param_profit_name"), resources:get("param_profit_description"), 0);
    strategy.parameters:addDouble("loss", resources:get("param_loss_name"), resources:get("param_loss_description"), 0);

    strategy.parameters:addGroup(resources:get("param_Risk_ParamGroup"));
    strategy.parameters:addBoolean("isNeedRiskManagement", resources:get("param_isNeedRiskManagement_name"), "", false);
    strategy.parameters:addBoolean("isNeedLimit", resources:get("param_isNeedLimit_name"), "", false);
    strategy.parameters:addDouble("limit", resources:get("param_limit_name"), resources:get("param_limit_description"), 0, 0, 10000);
    strategy.parameters:addBoolean("isNeedStop", resources:get("param_isNeedStop_name"), "", false);
    strategy.parameters:addDouble("stop", resources:get("param_stop_name"), resources:get("param_stop_description"), 0, 0, 10000);
    strategy.parameters:addBoolean("isNeedTrailing", resources:get("param_isNeedTrailing_name"), "", false);
    strategy.parameters:addBoolean("isNeedDynamicTrailing", resources:get("param_isNeedDynamicTrailing_name"), "", false);
    strategy.parameters:addInteger("trailingStop", resources:get("param_trailingStop_name"), resources:get("param_trailingStop_description1") ..
                                                                           resources:get("param_trailingStop_description2") ..
                                                                           resources:get("param_trailingStop_description3"), 1, 0, 10000);

    strategy.parameters:addGroup(resources:get("param_Log_ParamGroup"));
    strategy.parameters:addBoolean("isNeedLogOrders", resources:get("param_isNeedLogOrders_name"), "", false);

    strategy.parameters:addGroup(resources:get("param_Strategy_ParamGroup"));
    strategy.parameters:addString("Version", resources:get("param_Version_name"), "", "");
end

local MACD, MACDDATA;
local gSource = nil;
local lastSerial = -1;
local id = 1;
local idOM = 2;
local idLE = 3;
local idSE = 4;
local first;
local loading = false;
local source;
local idOffer;
local idAccount;
local tradeSize;
local canLimitStop;
local pipSize;
local currentBS = "";
local isTrueHost = true;
local isNeedRiskManagement


function Prepare()
    assert(instance.parameters.Period ~= "t1", resources:get("assert_NoTicks"));

    loading = true;

    source = core.host:execute("getHistory", id, instance.bid:instrument(), instance.parameters.Period, 0, 0, instance.parameters.Type == "Bid");
    gSource = source.close;

    MACD = core.indicators:create("MACD", gSource, instance.parameters.SN, instance.parameters.LN, instance.parameters.IN);

    local idStream;

    if instance.parameters.MACDStream == "MACD" then
        idStream = 0;
    elseif instance.parameters.MACDStream == "SIGNAL" then
        idStream = 1;
    elseif instance.parameters.MACDStream == "HISTOGRAM" then
        idStream = 2;
    end

    MACDDATA = MACD:getStream(idStream);

    first = MACDDATA:first();

    if instance.parameters.isNeedAutoTrading then
        idOffer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
        idAccount = instance.parameters.Account;
        tradeSize = instance.parameters.tradeSize * core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), idAccount);

        canLimitStop = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), idAccount);
        pipSize = instance.bid:pipSize();
        isNeedRiskManagement = instance.parameters.isNeedRiskManagement
    end

    isTrueHost = (string.find(string.lower(core.host:version()), "marketscope") ~= nil and true or false);
end

function Update()
    if loading == true then
        return;
    end

    MACD:update(core.UpdateLast);

    local size = gSource:size();
    if size > 1 then
        local serial = gSource:serial(size - 1);

        if serial ~= lastSerial then
            local period = size - 2;
            local hasData = MACDDATA:hasData(period);

            if period >= first and hasData then
                checkTrendDown(period); -- to SELL
                checkTrendUp(period); -- to BUY

                lastSerial = serial;
            end
        end
    end
end

function checkTrendDown(period) -- Check trend down
    if isPeak(period) then
        local curr = period;
        local prev = prevPeak(period);

        local trueDivergence = false;
        local hideDivergence = false;

        if prev ~= nil then
            if source.high[curr] > source.high[prev] and MACDDATA[curr] < MACDDATA[prev] then -- True divergence (turn trend down)
                trueDivergence = true;
            end

            if source.high[curr] < source.high[prev] and MACDDATA[curr] > MACDDATA[prev] then -- Hide divergence (confirmation down trend)
                hideDivergence = true;
            end

            if trueDivergence or (instance.parameters.isNeedToConfirm and hideDivergence) then
                toSELL(period);
            end
        end
    end
end

function checkTrendUp(period) -- Check trend up
    if isTrough(period) then
        local curr = period;
        local prev = prevTrough(period);

        local trueDivergence = false;
        local hideDivergence = false;

        if prev ~= nil then
            if source.low[curr] < source.low[prev] and MACDDATA[curr] > MACDDATA[prev] then -- True divergence (turn trend up)
                trueDivergence = true;
            end

            if source.low[curr] > source.low[prev] and MACDDATA[curr] < MACDDATA[prev] then -- Hide divergence (confirmation up trend)
                hideDivergence = true;
            end

            if trueDivergence or (instance.parameters.isNeedToConfirm and hideDivergence) then
                toBUY(period);
            end
        end
    end
end

function toSELL(period)
    terminal:alertMessage(gSource:instrument(), gSource[period], resources:get("alert_DivergenceMACDSignals2SELL"), gSource:date(period));
    trade("S");
end

function toBUY(period)
    terminal:alertMessage(gSource:instrument(), gSource[period], resources:get("alert_DivergenceMACDSignals2BUY"), gSource:date(period));
    trade("B");
end

function isPeak(period)
    local i;

    if MACDDATA[period] > 0 and MACDDATA[period] > MACDDATA[period - 1] and MACDDATA[period] > MACDDATA[period + 1] then
        for i = period - 1, first, -1 do
            if MACDDATA[i] < 0 then
                return true;
            elseif MACDDATA[period] < MACDDATA[i] then
                return false;
            end
        end
    end

    return false;
end

function isTrough(period)
    local i;

    if MACDDATA[period] < 0 and MACDDATA[period] < MACDDATA[period - 1] and MACDDATA[period] < MACDDATA[period + 1] then
        for i = period - 1, first, -1 do
            if MACDDATA[i] > 0 then
                return true;
            elseif MACDDATA[period] > MACDDATA[i] then
                return false;
            end
        end
    end

    return false;
end

function prevPeak(period)
    local i;

    for i = period - 5, first, -1 do
        if MACDDATA[i] >= MACDDATA[i - 1] and MACDDATA[i] > MACDDATA[i - 2] and
           MACDDATA[i] >= MACDDATA[i + 1] and MACDDATA[i] > MACDDATA[i + 2] then
           return i;
        end
    end

    return nil;
end

function prevTrough(period)
    local i;

    for i = period - 5, first, -1 do
        if MACDDATA[i] <= MACDDATA[i - 1] and MACDDATA[i] < MACDDATA[i - 2] and
           MACDDATA[i] <= MACDDATA[i + 1] and MACDDATA[i] < MACDDATA[i + 2] then
           return i;
        end
    end

    return nil;
end

function trade(type)
    if not instance.parameters.isNeedAutoTrading then
        return;
    end

    local account = core.host:findTable("accounts"):find("AccountID", instance.parameters.Account);

    if instance.parameters.isNeedMarginCare then
        local margin = (account.UsableMargin / account.Equity) * 100;
        if margin <= instance.parameters.margin then
            return;
        end
    end

    if instance.parameters.isNeedPLCare then
        local GrossPL = account.GrossPL;
        if GrossPL > instance.parameters.profit or GrossPL < instance.parameters.loss then
            return;
        end
    end

    local valuemap = core.valuemap();

    valuemap.Command = "CreateOrder";
    valuemap.OrderType = "OM"; -- True market order opens a position at any currently available market rate.
    valuemap.OfferID = idOffer;
    valuemap.AcctID = idAccount;
    valuemap.BuySell = type;
    valuemap.Quantity = tradeSize;

    if instance.parameters.isNeedRiskManagement and canLimitStop then
        if instance.parameters.isNeedLimit then
            valuemap.PegTypeLimit = "M";
            valuemap.PegPriceOffsetPipsLimit = (valuemap.BuySell == "B" and instance.parameters.limit or -instance.parameters.limit);
        end

        if instance.parameters.isNeedStop then
            valuemap.PegTypeStop = "M";
            valuemap.PegPriceOffsetPipsStop = (valuemap.BuySell == "B" and -instance.parameters.stop or instance.parameters.stop);
        end

        if instance.parameters.isNeedTrailing then
            if instance.parameters.isNeedDynamicTrailing then
                valuemap.TrailStepStop = 1;
            else
                valuemap.TrailStepStop = instance.parameters.trailingStop;
            end
        end
    end

    if instance.parameters.isNeedRiskManagement and (not canLimitStop) then
        if instance.parameters.isNeedLimit then
            -- set limit order
            if type == "B" then
                valuemap.RateLimit = instance.ask[NOW] + instance.parameters.limit * pipSize;
            else
                valuemap.RateLimit = instance.bid[NOW] - instance.parameters.limit * pipSize;
            end
        end

        if instance.parameters.isNeedStop then
        -- set stop order
            if type == "B" then
                valuemap.RateStop = instance.ask[NOW] - instance.parameters.stop * pipSize;
            else
                valuemap.RateStop = instance.bid[NOW] + instance.parameters.stop * pipSize;
            end
            if instance.parameters.isNeedTrailing then
                if instance.parameters.isNeedDynamicTrailing then
                    valuemap.TrailStepStop = 1;
                else
                    valuemap.TrailStepStop = instance.parameters.trailingStop;
                end
            end
        end

        valuemap.EntryLimitStop = 'Y'
    end

    local success, msg;
    success, msg = terminal:execute(idOM, valuemap);

    if instance.parameters.isNeedLogOrders then
        if success then
            terminal:alertMessage("", 0, resources:get("alert_TrueMarketOrderSent") .. msg, core.now());
        else
            terminal:alertMessage("", 0, resources:get("alert_SendTrueMarketOrderFailed") .. msg .. "'", core.now());
        end
    end
end

function AsyncOperationFinished(cookie, successful, info)
    if cookie == id then
        loading = false;
        lastSerial = gSource:serial(gSource:size() - 1);
    end
end

function isPresentInverseTrades(currentBS)
    local inverseBS = (currentBS == "B" and "S" or "B");
    local isPresentInverseTrades = false;

    local enum, row;

    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();

    while row ~= nil do
        if row.BS == inverseBS and
           row.OfferID == idOffer and
           row.AccountID == idAccount then

           isPresentInverseTrades = true;
           break;
        end

        row = enum:next();
    end

    return isPresentInverseTrades;
end
