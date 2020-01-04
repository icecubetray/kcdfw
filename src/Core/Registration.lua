kcdfw.registerCommand = function (command, expr, description, usage)
	if not kcdfw.runLocal then
		System.AddCCommand(
			command,
			expr,
			kcdfw.trimText(("Usage: %s %s\n\n%s"):format(command, (usage or ""), description))
		);
		kcdfw.logNotice(kcdfw, "Command registered: %q", command);
		return;
	end

	kcdfw.logNotice(kcdfw, "Skipped registering command: %q", command);
end


kcdfw.eventMap.postLoadingScreen = { };
kcdfw.registerPostLoadingScreen = function (id, callback)
	if type(id) ~= "string" or type(callback) ~= "function" then
		kcdfw.logError(kcdfw, "Type error.");
		return false
	end

	kcdfw.eventMap.postLoadingScreen[id] = callback;
end
