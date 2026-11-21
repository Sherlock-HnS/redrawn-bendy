
EFFECT = {}

function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local emitter = ParticleEmitter(pos, false) 

    for i = 1, 20 do
        local particle = emitter:Add("effects/splash4", pos)
        if particle then
            particle:SetVelocity(VectorRand() * math.Rand(150, 400)) 
            particle:SetDieTime(math.Rand(0.4, 9)) 
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)

            particle:SetStartSize(math.random(25, 40))
            particle:SetEndSize(math.random(5, 15))

            particle:SetColor(0, 0, 0)
            particle:SetRoll(math.Rand(-180, 180))
            particle:SetRollDelta(math.Rand(-1, 1))
            particle:SetAirResistance(100) 
            particle:SetGravity(Vector(0, 0, -800)) 
            particle:SetCollide(true)
            particle:SetBounce(0.05) 
        end
    end

    emitter:Finish()
end


function EFFECT:Think()
    return false
end

function EFFECT:Render()
end

effects.Register(EFFECT, "redrawn_black_liquid")


EFFECT = {}

function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local emitter = ParticleEmitter(pos, false)

    for i = 1, 60 do
        local particle = emitter:Add("effects/splash4", pos)
        if particle then
            particle:SetVelocity(VectorRand() * math.Rand(200, 600))
            particle:SetDieTime(math.Rand(0.8, 5.8))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)

            particle:SetStartSize(math.random(90, 150))
            particle:SetEndSize(math.random(20, 40))

            particle:SetColor(0, 0, 0)
            particle:SetRoll(math.Rand(-180, 180))
            particle:SetRollDelta(math.Rand(-2, 2))
            particle:SetAirResistance(120)
            particle:SetGravity(Vector(0, 0, -700))
            particle:SetCollide(true)
            particle:SetBounce(0.1)
        end
    end

    for i = 1, 20 do
        local particle = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
        if particle then
            particle:SetVelocity(VectorRand() * math.Rand(40, 100) + Vector(0, 0, math.Rand(100, 200)))
            particle:SetDieTime(math.Rand(1.2, 2.2))
            particle:SetStartAlpha(150)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.random(120, 200))
            particle:SetEndSize(math.random(250, 350))
            particle:SetColor(10, 10, 10)
            particle:SetAirResistance(150)
        end
    end

    local flash = emitter:Add("sprites/light_glow02_add", pos)
    if flash then
        flash:SetDieTime(0.2)
        flash:SetStartAlpha(200)
        flash:SetEndAlpha(0)
        flash:SetStartSize(250)
        flash:SetEndSize(50)
        flash:SetColor(20, 20, 20)
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end

effects.Register(EFFECT, "redrawn_black_liquid_spawnportal")
