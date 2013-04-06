-- This file contains helper method related to the signal alerts (message, sound, mail etc).

local gSignalBase = "";     -- the base part of the signal message
local gShowAlert = false;   -- the flag indicating whether the text alert must be shown
--values related to the email text formatting
local gMailIntroduction = "You have received this message because the following signal alert was received:"; -- the part of the email text formatting, the introduction.
local gMailSignalHeader = "Signal: "; -- the part of the email text formatting, the description of the provided 'Signal' value.
local gMailSignalName = ""; -- the part of the email text formatting, the value of the signal name.
local gMailSymbolHeader = "Symbol: "; -- the part of the email text formatting, the description of the provided 'Symbol' value.
local gMailMessageHeader = "Message: "; -- the part of the email text formatting, the description of the provided 'Message' value.
local gMailTimeHeader = "Time: "; -- the part of the email text formatting, the description of the provided 'Time' value.
local gMailPriceHeader = "Price: "; -- the part of the email text formatting, the description of the provided 'Price' value.

-- ---------------------------------------------------------
-- Sets the base message for the signal
-- @param base      The base message of the signals
-- ---------------------------------------------------------
function ExtSetupSignal(base, showAlert)
    gSignalBase = base;
    gShowAlert = showAlert;
    return ;
end

-- ---------------------------------------------------------
-- Sets the localized values for formatting email text.
-- ---------------------------------------------------------
function ExtSetupSignalMail(mailSignalName, mailIntroduction, mailSignalHeader, mailSymbolHeader, mailMessageHeader, mailTimeHeader, mailPriceHeader)    
    if mailIntroduction ~= nil then
        gMailIntroduction = mailIntroduction;
    end		
	if mailSignalHeader ~= nil then
        gMailSignalHeader = mailSignalHeader;
    end		
	if mailSignalName ~= nil then
        gMailSignalName = mailSignalName;
    end		
	if mailSymbolHeader ~= nil then
        gMailSymbolHeader = mailSymbolHeader;
    end		
	if mailMessageHeader ~= nil then
        gMailMessageHeader = mailMessageHeader;
    end		
	if mailTimeHeader ~= nil then
        gMailTimeHeader = mailTimeHeader;
    end		
	if mailPriceHeader ~= nil then
        gMailPriceHeader = mailPriceHeader;
    end			    
end

-- ---------------------------------------------------------
-- Signals the message
-- @param message   The rest of the message to be added to the signal
-- @param period    The number of the period
-- @param sound     The sound or nil to silent signal
-- @param email     The email address or nil to no send mail on signal
-- @param recurrentSound    Whether the sound should be played recurrently
-- ---------------------------------------------------------
function ExtSignal(source, period, message, soundFile, email, recurrentSound)
    if source:isBar() then
        source = source.close;
    end
    if gShowAlert then
        terminal:alertMessage(source:instrument(), source[period], gSignalBase .. message, math.max(instance.bid:date(instance.bid:size() - 1), instance.ask:date(instance.ask:size() - 1)));
    end
    if soundFile ~= nil then
        if recurrentSound == nil then
            recurrentSound = false;
        end
        terminal:alertSound(soundFile, recurrentSound);
    end	
	if email ~= nil then
        local subject, text = FormatEmail(source, period, message);
        terminal:alertEmail(email, subject, text);
     end
end

-- ---------------------------------------------------------
-- Formats the email subject and text
-- @param source   The signal source
-- @param period    The number of the period
-- @param message   The rest of the message to be added to the signal
-- ---------------------------------------------------------
function FormatEmail(source, period, message)
    --format email subject
	local subject = gSignalBase .. message .. "(" .. source:instrument() .. ")";
	--format email text
	local delim = "\013\010";
	local signalDescr = gMailSignalHeader .. gMailSignalName;
	local symbolDescr = gMailSymbolHeader .. source:instrument();
	local messageDescr = gMailMessageHeader .. gSignalBase .. message;
    local ttime = core.dateToTable(core.host:execute("convertTime", 1, 4, math.max(instance.bid:date(instance.bid:size() - 1), instance.ask:date(instance.ask:size() - 1))));
	local dateDescr = gMailTimeHeader .. string.format("%02i/%02i %02i:%02i", ttime.month, ttime.day, ttime.hour, ttime.min);	
	local priceDescr = gMailPriceHeader .. source[period];
	local text = gMailIntroduction .. delim .. signalDescr .. delim .. symbolDescr .. delim .. messageDescr .. delim .. dateDescr .. delim .. priceDescr;
	return subject, text;
end
