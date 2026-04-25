--< Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--< Modules
local ClientModule = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Client") :: ModuleScript
local Client = require(ClientModule)

local Worked, Result = pcall(Client)
if not Worked then
	warn("🔴 Client Big Error:", Result)
	Players.LocalPlayer:Kick("🔴 Something went wrong while loading the game. Please rejoin.")
end