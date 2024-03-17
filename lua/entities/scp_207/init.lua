AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SCP207_WalkBoost = 77.96
local SCP207_RunBoost = 94.98
local SCP207_CrouchBoost = 0.02667
local SCP207_Healing = 30

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl") -- Ändere das Model zu einer Cola wenn verfügbar
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

-- Funktion zum Aufheben des Effekts
function RemoveEffect(ply)
    if IsValid(ply) and ply:IsPlayer() then
        timer.Remove("SCP207_HealthLoss" .. ply:SteamID()) -- Entferne den HealthLoss Timer
        print("SCP-207 effect has been removed for player " .. ply:Nick()) -- Debug
    end
end

local function HealthLoss(ply)
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    if not ply:Alive() then return end

    ply:SetHealth(math.max(ply:Health() - 1, 0))
    print("Player " .. ply:Nick() .. " lost 1 health due to SCP-207 effect.") -- Debug

    -- Die Funktion HealthLoss wird rekursiv aufgerufen, um alle 2 Sekunden den HealthLoss des Spielers zu überprüfen und zu aktualisieren,
    -- solange der Spieler noch lebt und SCP-207 den Effekt hat. Das stellt sicher, dass der HealthLoss regelmäßig überprüft wird, während
    -- der Effekt aktiv ist, und stoppt, sobald der Spieler stirbt oder SCP-207 entfernt wird.
    if ply:Health() <= 0 then
        print("Player " .. ply:Nick() .. " died due to SCP-207 effect.") -- Debug
        ply:Kill() -- Töte den Spieler, wenn er keine Gesundheit mehr hat (TODO-Frage: Sollte Tod durch SCP-207 als Selbstmord gewertet werden?)
    else
        timer.Create("SCP207_HealthLoss" .. ply:SteamID(), 2, 0, function() -- Erstelle einen Timer, der alle 2 Sekunden HealthLoss() ausführt
            HealthLoss(ply)
        end)
    end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        local maxHealth = activator:GetMaxHealth()
        local currentHealth = activator:Health()
        local actualHealing = math.min(maxHealth - currentHealth, SCP207_Healing)

        activator:SetHealth(math.min(currentHealth + SCP207_Healing, maxHealth)) -- Erhöhe die Gesundheit des Spielers um 30, begrenzt auf das Maximum der Gesundheit des Spielers
        print("Player " .. activator:Nick() .. " picked up SCP-207 and gained " .. actualHealing .. " (" .. SCP207_Healing .. ") health.") -- Debug

        local walkSpeed = activator:GetWalkSpeed() // Default ist 200
        local runSpeed = activator:GetRunSpeed() // Default ist 400
        local crouchSpeed = activator:GetCrouchedWalkSpeed() // Default ist 0.30000001192093

        // In SCP:SL der Default Laufwert ist 5m/s, und der Rennwert ist 7m/s, crouching ist bei 2,7m/s
        // Die Werte für den SCP-207 Boost sind auf der offiziellen Wiki Seite zu finden
        // Die Differenz zwischen den Defalt und den Boost werten wurden genommen und in Unit/s umgerechnet, und an die Default Werte addiert
        // Formel für die Umrechnung von Units in m/s: 1 Unit/s * 0,01905 m/Einheit = 0,01905 m/s
        // Crouching in SCP:SL mit SCP-207 ist generved für Fairness um den Faktoor 0.0889
        // Das bedeuted, dass für das selbe Verhalten wie in SCP:SL, die Werte für das Ducken um 0.0889 multipliziert werden müssen
        // Boost für 1x SCP-207: Laufen: 77,96 Units/s, Rennen: 94,98 Units/s, Crouching (normal): 12,60 Units/s, Crouching(faktorisiert): 0,02667 Units/s
        activator:SetWalkSpeed(walkSpeed + SCP207_WalkBoost) -- Erhöhe die Laufgeschwindigkeit des Spielers
        activator:SetRunSpeed(runSpeed + SCP207_RunBoost) -- Erhöhe die Renngeschwindigkeit des Spielers
        activator:SetCrouchedWalkSpeed(SCP207_CrouchBoost) -- Verringere die Geschwindigkeit des Spielers beim Ducken (0.30000001192093 * 0.0889 = 0.02667)

        timer.Create("SCP207_HealthLoss" .. activator:SteamID(), 2, 0, function() -- Erstelle einen Timer, der alle 2 Sekunden HealthLoss() aufruft
            HealthLoss(activator)
        end)
    end

    self:Remove()
    print("SCP-207 has been removed.") -- Debug
end
