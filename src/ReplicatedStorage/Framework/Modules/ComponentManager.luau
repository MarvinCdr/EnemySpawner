--[[


░░░░░██╗░█████╗░░██████╗  ██████╗░███████╗██╗░░░██╗
░░░░░██║██╔══██╗██╔════╝  ██╔══██╗██╔════╝██║░░░██║
░░░░░██║██║░░██║╚█████╗░  ██║░░██║█████╗░░╚██╗░██╔╝
██╗░░██║██║░░██║░╚═══██╗  ██║░░██║██╔══╝░░░╚████╔╝░
╚█████╔╝╚█████╔╝██████╔╝  ██████╔╝███████╗░░╚██╔╝░░
░╚════╝░░╚════╝░╚═════╝░  ╚═════╝░╚══════╝░░░╚═╝░░░

]]

local STATUS_ATTRIBUTE = "_status"

--[[
	Checks whether a component (ModuleScript) has been successfully executed.
	
	@param ModuleScript The ModuleScript instance representing the component to check
	@return boolean True if the component has been executed, false otherwise
]]
function ComponentIsExecuted(ModuleScript: ModuleScript)
	return ModuleScript:GetAttribute(STATUS_ATTRIBUTE) == "executed"
end

--[[
	Waits for a component (ModuleScript) to finish executing, then calls the appropriate callback.
	
	This function will wait until the component's status attribute changes, then checks if it
	was successfully executed. If the component executed successfully, OnSuccess is called.
	Otherwise, OnError is called.
	
	@param ModuleScript The ModuleScript instance representing the component to wait for
	@param OnSuccess Optional callback function to execute if the component executed successfully
	@param OnError Optional callback function to execute if the component failed or hasn't executed
	@return boolean True if the component executed successfully, false otherwise
]]
function WaitForComponent(ModuleScript: ModuleScript, OnSuccess: () -> ()?, OnError: () -> ()?): boolean
	local moduleStatus = ModuleScript:GetAttribute(STATUS_ATTRIBUTE)

	if not moduleStatus then
		ModuleScript:GetAttributeChangedSignal(STATUS_ATTRIBUTE):Wait()
		moduleStatus = ModuleScript:GetAttribute(STATUS_ATTRIBUTE)
	end

	if moduleStatus == "executed" then
		if OnSuccess then
			OnSuccess()
		end
		return true
	end

	if OnError then
		OnError()
	end
	return false
end

--[[
	Initializes a component (ModuleScript) by requiring it and running its initialization code.
	
	This function handles two types of component returns:
	- If the component returns a function, it spawns that function
	- If the component returns a table with an Init method, it calls that method
	
	The component's status is tracked via attributes: "executed" on success,
	"require-error" if requiring failed, or "init-error" if initialization failed.
	
	@param ModuleScript The ModuleScript instance representing the component to initialize
]]
function InitComponent(ModuleScript: ModuleScript)
	if not ModuleScript or not ModuleScript:IsA("ModuleScript") then
		return
	end

	if ModuleScript:GetAttribute(STATUS_ATTRIBUTE) then
		return
	end

	-- Attempt to require the module
	local success, requiredModule = pcall(require, ModuleScript)
	if not success then
		ModuleScript:SetAttribute(STATUS_ATTRIBUTE, "require-error")
		warn(`🟠 [{ModuleScript:GetFullName()} Error]: Failed to require module =>`, requiredModule)
		return
	end

	local requiredModuleType = typeof(requiredModule)
	if requiredModuleType == "function" then
		task.spawn(requiredModule)
	elseif requiredModuleType == "table" and requiredModule.Init then
		task.spawn(requiredModule.Init, requiredModule)
	else
		ModuleScript:SetAttribute(STATUS_ATTRIBUTE, "init-error")
		warn(
			`🟠 [{ModuleScript:GetFullName()} Error]: Init Error => Only 'function' or 'table:Init()' expected, got {requiredModuleType}`
		)
	end

	-- Check the module as initialized if was loaded properly
	ModuleScript:SetAttribute(STATUS_ATTRIBUTE, "executed")
end

--[[
	Recursively initializes all components (ModuleScripts) found within a Folder and its subfolders.
	
	This function traverses the folder hierarchy and spawns initialization for each
	ModuleScript found. Initialization happens in parallel for all components.
	
	@param Folder The Folder instance to search for components
]]
function InitFolderComponents(Folder: Folder)
	for _, v in pairs(Folder:GetChildren()) do
		if v:IsA("Folder") then
			InitFolderComponents(v)
		end
		InitComponent(v)
	end
end

return {

	ComponentIsExecuted = ComponentIsExecuted,
	WaitForComponent = WaitForComponent,
	InitComponent = InitComponent,
	InitFolderComponents = InitFolderComponents,
}
