if _VERSION == 'Lua 5.1' then
	load = loadstring
end

local function clock()
	if kcdfw.runLocal then
		return os.clock();
	end

	return 0;
end

kcdfw.evalString = function (expr)
	kcdfw.logWarning(kcdfw, "Beginning eval of expression: %q", expr);

	local tBegin = clock();
	local f, error = load(expr);
	if not error then
		local tPreExec = clock();
		local result = f();
		local tPostExec = clock();

		local resultPad = "";
		if (type(result) == "string") then
			resultPad = "\"";
		end

		kcdfw.logWarning(
			kcdfw,
			"Eval done: load=%fs, exec=%fs, return=%s%s%s",
			(tPreExec - tBegin),
			(tPostExec - tPreExec),
			resultPad, tostring(result), resultPad
		);
	else
		kcdfw.logError(kcdfw, "Eval failed, dumping error below.");
		kcdfw.log(
			kcdfw,
			kcdfw.bitwiseOr(KCDFW_LEVEL_ERROR, KCDFW_FLAG_NO_PREFIX),
			error
		);
	end
end

kcdfw.registerCommand(
	"kcdfw_eval",
	"kcdfw.evalString(%line)",
	"Evaluates the entire cmdline as a Lua expression.\nTo enable the use of the '=' sign, use command as \"kcdfw_eval= [expr]\".",
	"<expr>"
);




kcdfw.cmdInspect = function(args)
	local dumpFun = (args.functions or args.f);
	local lookGlobal = (args.global or args.g);
	local objectName = (args.object or args.o);


	if not objectName then
		kcdfw.logError(kcdfw, "Missing/invalid object name.");
		return;
	end


	local object = nil;

	if lookGlobal then
		object = _G[objectName];
	end


	kcdfw.logAlways(kcdfw, "%s = %s", objectName, kcdfw.stringRepresentation(object));


	if dumpFun then
		kcdfw.dumpFunctions(object);
	end
end

kcdfw.registerCommand(
	"kcdfw_inspect",
	"kcdfw.cmdInspect(cmdtab(%line))",
	"Uses introspection to display properties of the specified object.",
	{
		f = "Dump function listing.",
		g = "Use the global table to look up the object.",
		o = { value = "object_name", description = "Specify the object to inspect." }
	}
)




kcdfw.cmdLogLevel = function(args)
	kcdfw.setLogLevel(args.level or args.l);
end

kcdfw.registerCommand(
	"kcdfw_loglevel",
	"kcdfw.cmdLogLevel(cmdtab(%line))",
	"Sets the log level for the loggers shipped with KCDFW.",
	{
		l = { value = "level", description = "The level to use. Can be numeric or named." }
	}
);
