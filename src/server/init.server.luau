--< Services
local Players = game:GetService("Players")

--< Modules
local Server = game:GetService("ServerStorage").ServerFramework.Server

local Worked, Result = pcall(Server)

if not Worked then
	warn("🔴 Server Big Error:", Result)

	function kickPlayer(player:Player)
		player:Kick("🔴 Something went wrong while loading the game. Please rejoin.")
	end
	
	Players.PlayerAdded:Connect(kickPlayer)
	
	for _,player in pairs(Players:GetPlayers()) do
		task.spawn(kickPlayer, player)
	end

end