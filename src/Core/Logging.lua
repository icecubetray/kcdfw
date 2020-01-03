kcdfw.__funcs.log = function (level, fmt, ...)
	if kcdfw.distribution and level == "debug" then
		return;
	end

	local strFormatted = (("%s %s"):format("[%s]", fmt)):format(level, ...);
	if kcdfw.distribution then
		System.LogAlways(strFormatted);
	else
		print(strFormatted)
	end
end

kcdfw:logNotice("Logging function overridden.");
