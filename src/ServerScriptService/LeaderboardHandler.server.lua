local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(ReplicatedStorage.FPSSystem.Modules.DataStoreManager)

local LeaderboardHandler = {}

-- Cache leaderboard data
local leaderboardCache = {}
local lastUpdateTime = 0
local CACHE_DURATION = 5 -- Update cache every 5 seconds

function LeaderboardHandler:Initialize()
    DataStoreManager:Initialize()
    
    -- Handle leaderboard requests
    local getLeaderboardFunction = ReplicatedStorage.FPSSystem.RemoteEvents:FindFirstChild("GetLeaderboard")
    if getLeaderboardFunction then
        getLeaderboardFunction.OnServerInvoke = function(player)
            return self:GetLeaderboardData()
        end
    end
    
    -- Update leaderboard cache periodically
    spawn(function()
        while true do
            self:UpdateLeaderboardCache()
            wait(CACHE_DURATION)
        end
    end)
    
    print("LeaderboardHandler initialized")
end

function LeaderboardHandler:GetLeaderboardData()
    -- Return cached data if recent
    if tick() - lastUpdateTime < CACHE_DURATION and #leaderboardCache > 0 then
        return leaderboardCache
    end
    
    -- Update cache and return
    self:UpdateLeaderboardCache()
    return leaderboardCache
end

function LeaderboardHandler:UpdateLeaderboardCache()
    local leaderboardData = {}

    -- Get data for all players (CURRENT MATCH STATS ONLY)
    for _, player in pairs(Players:GetPlayers()) do
        local playerData = DataStoreManager:GetPlayerData(player)
        if playerData and playerData.MatchStats then
            -- Use MATCH STATS for Tab leaderboard (current round only)
            local matchStats = playerData.MatchStats
            local kdr = 0
            if matchStats.Deaths and matchStats.Deaths > 0 then
                kdr = matchStats.Kills / matchStats.Deaths
            elseif matchStats.Kills and matchStats.Kills > 0 then
                kdr = matchStats.Kills
            end

            -- Get player's team
            local team = "Lobby"
            if player.Team then
                team = player.Team.Name
            end

            table.insert(leaderboardData, {
                name = player.Name,
                level = playerData.Level or 0,
                kills = matchStats.Kills or 0,
                deaths = matchStats.Deaths or 0,
                kdr = kdr,
                streak = matchStats.KillStreak or 0,
                score = matchStats.Score or 0,
                team = team
            })
        else
            -- Fallback data for players without data (current match is 0)
            local team = "Lobby"
            if player.Team then
                team = player.Team.Name
            end

            table.insert(leaderboardData, {
                name = player.Name,
                level = 0,
                kills = 0,
                deaths = 0,
                kdr = 0,
                streak = 0,
                score = 0,
                team = team
            })
        end
    end
    
    -- Sort by score (highest first)
    table.sort(leaderboardData, function(a, b)
        return a.score > b.score
    end)
    
    leaderboardCache = leaderboardData
    lastUpdateTime = tick()
end

-- Initialize the handler
LeaderboardHandler:Initialize()

return LeaderboardHandler
