
AddCSLuaFile()
hook.Add("OnEntityCreated", "Redrawn_gentoi_noodles_pill_initialize", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() == "pill_ent_costume" then
            if ent.formTable then
                local PuppetEntity = ent:GetPuppet()
                local entityply = ent:GetPillUser()

                if ent.formTable.noodles_redrawn_gentoi_initialize then
                    entityply:SetNWFloat("Redrawn_Damage_Reduction",1)

                    local tablevarable = {["player"] = entityply, ["entity"] = ent, ["puppet"] = PuppetEntity}
                    timer.Simple(0.01, function()
                        if !IsValid(ent) then return end
                        ent.formTable:noodles_redrawn_gentoi_initialize(tablevarable,tablevarable,tablevarable)
                    end)

                    hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex(), function(ply) if entityply == ply then return true end end)
                    hook.Add("EntityTakeDamage", "OM_npc_damage_reduction_".. entityply:EntIndex(), function(target, dmg) -- made by AVI
                        if target == entityply then
                            local attacker = dmg:GetAttacker()
                            if IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot()) then
                                dmg:ScaleDamage(entityply:GetNWFloat("Redrawn_Damage_Reduction",0))
                            end
                        end
                    end)

                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())
                        hook.Remove("EntityTakeDamage", "OM_npc_damage_reduction_".. entityply:EntIndex())
                        ent.formTable:noodles_redrawn_gentoi_OnRemove(tablevarable,tablevarable,tablevarable)
                        if IsValid(entityply) then
                            entityply:SetNWFloat("Redrawn_Damage_Reduction",1)
                        end
                    end)


                    local self = ent
                    ent.Think = function()
                        local currentanim = 'idle'
                        local ply = self:GetPillUser()
                        local puppet = self:GetPuppet()
                        if not IsValid(puppet) or not IsValid(ply) then return end
                        local vel = ply:GetVelocity():Length()

                        if SERVER then
                            --Anims
                            local anims = table.Copy(self.formTable.anims.default or {})
                            table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                            local anim
                            --local useSeqVel=true
                            local overrideRate

                            if (not self.anim or not anims[self.anim]) then
                                self.animFreeze = nil
                                self.animStart = nil
                            end


                            if self.animFreeze and not self.plyFrozen then
                                ply:SetWalkSpeed(ply:GetWalkSpeed() / 2)
                                ply:SetRunSpeed(ply:GetWalkSpeed() / 2)
                                self.plyFrozen = true
                            elseif not self.animFreeze and self.plyFrozen then
                                local speed = self.formTable.moveSpeed or {}
                                ply:SetWalkSpeed(speed.walk or 200)
                                ply:SetRunSpeed(speed.run or speed.walk or 500)
                                self.plyFrozen = nil
                            end

                            if self.anim and anims[self.anim] then
                                anim = anims[self.anim]
                                overrideRate = anims[self.anim .. "_rate"] or 1
                                local cycle = puppet:GetCycle()

                                if not self.animStart then
                                    if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                        self.anim = nil
                                        self.animCycle = nil

                                        if self.animFreeze then
                                            self.animFreeze = nil
                                        end
                                    elseif self.animCycle then
                                        self.animCycle = cycle
                                    end
                                end
                            elseif self.tickAnim and anims[self.tickAnim] then
                                anim = anims[self.tickAnim]
                                overrideRate = anims[self.tickAnim .. "_rate"] or 1
                                self.tickAnim = nil
                            elseif self.burrowed then
                                anim = anims["burrow_loop"]
                            elseif ply:WaterLevel() > 2 then
                                anim = anims["swim"] or anims["glide"] or anims["idle"]
                            elseif ply:IsOnGround() then
                                if ply:Crouching() then
                                    if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                        anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["crouch"] or anims["idle"]
                                    end
                                else
                                    if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                        anim = anims["run"] or anims["walk"] or anims["idle"]
                                    elseif vel > ply:GetWalkSpeed() / 4 then
                                        anim = anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["idle"]
                                    end
                                end
                            else
                                anim = anims["glide"] or anims["idle"]
                            end

                            if anim == anims["idle"] or anim == anims["crouch"] then
                                overrideRate = 1
                            end
                            self:SetNWString("Animlastplayed", anim)

                            local ShouldAlternate = table.Copy(self.formTable.anims.ShouldAlternate or {})
                            if type(ShouldAlternate[anim]) == "function" and ShouldAlternate[anim](self) then
                                if ShouldAlternate[anim](self) ~= nil and isstring(ShouldAlternate[anim](self)) then
                                    
                                    anim = ShouldAlternate[anim](self)
                                end
                            end

                            if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then


                                puppet:ResetSequence(puppet:LookupSequence(anim))
                                puppet:SetCycle(0)
                                self.animCycle = 0
                            end

                            self.animStart = nil
                            local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                            --if true then
                            if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                                local rate = overrideRate or vel / seq_vel

                                --goofy limitation (floods console with errors if above 12!)
                                if rate > 12 then
                                    rate = 12
                                end

                                puppet:SetPlaybackRate(rate)
                            else
                                --puppet:SetPlaybackRate(1)
                            end

                            --print(puppet:GetCycle())
                            if self.formTable.movePoseMode then
                                --
                                if self.formTable.movePoseMode == "yaw" then
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                elseif self.formTable.movePoseMode == "xy" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                    end
                                elseif self.formTable.movePoseMode == "xy-bot" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        puppet:SetPoseParameter("move_yaw", move_dir.y)
                                        puppet:SetPoseParameter("move_scale", 1)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                        puppet:SetPoseParameter("move_yaw", 0)
                                        puppet:SetPoseParameter("move_scale", 0)
                                    end
                                end
                            end

                            --Aimage
                            if self.formTable.aim then
                                if self.formTable.aim.xPose then
                                    local yaw = math.AngleDifference(ply:EyeAngles().y, puppet:GetAngles().y)

                                    if self.formTable.aim.xInvert then
                                        yaw = -yaw
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                                end

                                if self.formTable.aim.yPose then
                                    local pitch = math.AngleDifference(ply:EyeAngles().p, puppet:GetAngles().p)

                                    if self.formTable.aim.yInvert then
                                        pitch = -pitch
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                                end
                            end

                            --gliding and landing
                            if not ply:IsOnGround() and ply:WaterLevel() == 0 and self.formTable.glideThink then
                                self.formTable.glideThink(ply, self)
                            end

                            if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                                self.formTable.land(ply, self)
                            end

                            --water death
                            self.touchingWater = ply:WaterLevel() > 1

                            if (self.formTable.damageFromWater and self.touchingWater) then
                                if self.formTable.damageFromWater == -1 then
                                    --self:PillDie()
                                    ply:Kill()
                                else
                                    ply:TakeDamage(self.formTable.damageFromWater)
                                    --TODO APPLY DAMAGE
                                end
                            end

                            --tick attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                            end

                            --auto attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack")
                                else
                                    self:PillLoopStop("attack")
                                end

                                if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                    self.formTable.attack.func(ply, self, self.formTable.attack)
                                    self.lastAttack = CurTime()
                                end
                            else
                                self:PillLoopStop("attack")
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack2")
                                else
                                    self:PillLoopStop("attack2")
                                end

                                if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                    self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                    self.lastAttack2 = CurTime()
                                end
                            else
                                self:PillLoopStop("attack2")
                            end

                            --charge
                            if self:GetChargeTime() ~= 0 then
                                if ply:OnGround() then
                                    local charge = self.formTable.charge
                                    local angs = ply:EyeAngles()
                                    self:PillAnimTick("charge_loop")
                                    ------ Changed -------
                                    local hit_ent = ply:TraceHullAttack(ply:EyePos(), ply:EyePos() + angs:Forward() * 100, Vector(-20, -20, -20), Vector(20, 20, 20), charge.dmg, DMG_GENERIC, 1, true)

                                    if IsValid(hit_ent) then
                                        self:PillAnim("charge_hit", true)
                                        --self:PillGesture("charge_hit")
                                        self:PillSound("charge_hit")
                                        self:SetChargeTime(0)
                                        self:PillLoopStop("charge")
                                    end
                                else
                                    self:SetChargeTime(0)
                                    self:PillLoopStop("charge")
                                end
                            end

                            --Cloak
                            if self.formTable.cloak then
                                local cloak = self.formTable.cloak

                                if self.iscloaked then
                                    local cloakamt = self:GetCloakLeft()

                                    if cloakamt ~= -1 then
                                        cloakamt = cloakamt - FrameTime()

                                        if cloakamt < 0 then
                                            cloakamt = 0
                                            self:ToggleCloak()
                                        end

                                        self:SetCloakLeft(cloakamt)
                                    end
                                else
                                    local cloakamt = self:GetCloakLeft()

                                    if cloakmt ~= -1 and cloakamt < cloak.max then
                                        cloakamt = cloakamt + FrameTime() * cloak.rechargeRate

                                        if cloakamt > cloak.max then
                                            cloakamt = cloak.max
                                        end

                                        self:SetCloakLeft(cloakamt)
                                    end
                                end

                                local color = self:GetPuppet():GetColor()

                                if self.iscloaked then
                                    if color.a > 0 then
                                        color.a = color.a - 5
                                        self:GetPuppet():SetColor(color)
                                    end
                                else
                                    if color.a < 255 then
                                        color.a = color.a + 5
                                        self:GetPuppet():SetColor(color)
                                    end
                                end

                                --PrintTable(color)
                                if IsValid(self.wepmdl) and self.wepmdl:GetColor().a ~= color.a then
                                    self.wepmdl:SetColor(color)
                                end
                            end

                            --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                            --wepon-no longer SO hackey
                            if not self.formTable.hideWeapons then
                                local realWep = self:GetPillUser():GetActiveWeapon()

                                --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                                if IsValid(realWep) and realWep:GetModel() ~= "" then
                                    --hiding the real thing [BROKEN]
                                    --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                        realWep:SetRenderMode(RENDERMODE_NONE)
                                    end]]
                                    if realWep.pill_attachment then
                                        if IsValid(self.wepmdl) then
                                            self.wepmdl:Remove()
                                        end

                                        self.wepmdl = ents.Create("pill_attachment_wep")
                                        self.wepmdl:SetParent(self:GetPuppet())
                                        self.wepmdl:SetModel(realWep:GetModel())
                                        self.wepmdl.attachment = realWep.pill_attachment
                                        self.wepmdl:Spawn()

                                        if realWep.pill_offset then
                                            self.wepmdl:SetWepOffset(realWep.pill_offset)
                                        end

                                        if realWep.pill_angle then
                                            self.wepmdl:SetWepAng(realWep.pill_angle)
                                        end

                                        realWep.pill_proxy = self.wepmdl
                                    elseif not IsValid(self.wepmdl) then
                                        self.wepmdl = ents.Create("pill_attachment_wep")
                                        self.wepmdl:SetParent(self:GetPuppet())
                                        self.wepmdl:SetModel(realWep:GetModel())
                                        self.wepmdl:Spawn()
                                        realWep.pill_proxy = self.wepmdl
                                    elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                        self.wepmdl:SetModel(realWep:GetModel())
                                    end
                                elseif IsValid(self.wepmdl) then
                                    self.wepmdl:Remove()
                                end
                            end
                        else

                            local realWep = self:GetPillUser():GetActiveWeapon()

                            if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                realWep:SetNoDraw(true)
                            end
                        end

                        --Align pos and angles with player
                        if SERVER then
                            puppet:SetPos(ply:GetPos())
                        else
                            puppet:SetRenderOrigin(ply:GetPos())
                            if self:GetNWBool('EnterPortal_redrawn') then
                                --puppet:SetNoDraw(true)
                            else
                                puppet:SetNoDraw(false)
                            end
                        end
                        
                        currentanim = self:GetNWString("Animlastplayed")

                        --if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 then

                        local animsshouldspn = table.Copy(self.formTable.anims.ShouldMoveRotate or {})
                        if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
                                                        
                            local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]

                            local function SetTargetAngle(ang)
                                ang.p = 0
                                puppet:SetNW2Vector("SyncAng", ang:Forward())
                            end

                            local function GetTargetAngle()
                                local dir = puppet:GetNW2Vector("SyncAng")
                                if not dir or dir == vector_origin then return nil end
                                local ang = dir:Angle()
                                if not ang then return nil end
                                ang.p = 0
                                return ang
                            end

                            if typeofitem == "notshftlock" then
                                local dir = ply:GetVelocity():GetNormalized()
                                local aheadPos = ply:GetPos() + dir * 5
                                local ang = (aheadPos - ply:GetPos()):Angle()
                                ang.p = 0

                                if SERVER then
                                    SetTargetAngle(ang)
                                    puppet:SetAngles(ang)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end
                            elseif typeofitem == "assignedagnles_instant" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        puppet:SetRenderAngles(targetAng)
                                    end
                                end

                            elseif typeofitem == "shiftlock" then
                                local angs = ply:EyeAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "Playerangles" then
                                local angs = ply:GetAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "assignedagnles" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "notanything" then
                            end



                        end

                        self:NextThink(CurTime())

                        return true
                    end
                end
                if ent.formTable.HandleAnimEvent_Noodles_redrawn_Gentoi_pill then
                    local PuppetEntity = ent:GetPuppet()
                    local entityply = ent:GetPillUser()

                    if IsValid(PuppetEntity) then
                        function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                            ent.formTable.HandleAnimEvent_Noodles_redrawn_Gentoi_pill(entityply, ent, inputName)
                            return true
                        end
                    end
                end
            end
        end
    end)
end)

hook.Add("Think", "TrackPillCostumes_pill_Noodles_redrawn_gentoi", function()
    for _, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        if !IsValid(ent) then continue end
        local ply = ent:GetPillUser()
        local puppet = ent:GetPuppet()
        if !IsValid(puppet) or !IsValid(ply) then continue end

        if ent.formTable.think_noodles_redrawn_gentoi_pill then ent.formTable.think_noodles_redrawn_gentoi_pill(ply, ent) end
    end
end)


hook.Add("PlayerButtonDown", "ActivateKeybind_redrawn_gentoi_pills_noodles", function(ply, button)
    local pillentity = ply.pk_pill_ent
    if IsValid(pillentity) then
        if pillentity.formTable.noodles_redrawn_gentoi_keybinds then
            pillentity.formTable.noodles_redrawn_gentoi_keybinds(ply, pillentity, button)
        end
    end
end)

local function AdvancedPillSound(SoundData, ent)
    if SERVER then
        if IsValid(ent) then
            SoundData = SoundData or {}
            SoundData.stringe = SoundData.stringe or {}
            SoundData.soundLevel = SoundData.soundLevel or 75
            SoundData.pitchPercent = SoundData.pitchPercent or 100
            SoundData.volume = SoundData.volume or 1
            SoundData.channel = SoundData.channel or CHAN_AUTO
            SoundData.soundFlags = SoundData.soundFlags or 0
            SoundData.dsp = SoundData.dsp or 0
            SoundData.filter = SoundData.filter or nil

            local chosenSound = SoundData.stringe

            if istable(SoundData.stringe) then
                local index = math.random(1, #SoundData.stringe)
                chosenSound = SoundData.stringe[index]
            end

            ent:EmitSound(
                chosenSound,
                SoundData.soundLevel,
                SoundData.pitchPercent,
                SoundData.volume,
                SoundData.channel,
                SoundData.soundFlags,
                SoundData.dsp,
                SoundData.filter
            )
        end
        return true
    end
end

hook.Add("SetupMove", "DisablePlayerMovement_gentoi_redrawn", function(ply, mv, cmd)
    local var = false

    if IsValid(pk_pills.getMappedEnt(ply)) then
        if pk_pills.getMappedEnt(ply):GetNWBool('EnterPortal_redrawn') then
            var = true
        end
    end

    if ply:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") >= CurTime() or var then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end

    if ply:GetNWBool("CardPuddleSlowed") then
        mv:SetMaxClientSpeed(130) 
        mv:SetMaxSpeed(130)
    end
end)


if SERVER then
    AddCSLuaFile()
    util.AddNetworkString('gentoi_Redrawn_cam')
    util.AddNetworkString('redrawndomainpopup_ui')


    util.AddNetworkString("redrawnbendy_teleport")

    net.Receive("redrawnbendy_teleport", function()
        local Player = net.ReadEntity()
        local vector2go2 = net.ReadVector()
        local AngleSet2 = net.ReadAngle()

        pk_pills.getMappedEnt(Player):SetNWBool('EnterPortal_redrawn', false)

        Player.pk_pill_ent:GetPuppet():SetColor(Color(255,255,255, 255))

        local dur = Player.pk_pill_ent:GetPuppet():SequenceDuration(Player.pk_pill_ent:GetPuppet():LookupSequence("inkportalexit"))

        pk_pills.getMappedEnt(Player):SetNWInt("exitportal_redrawn", 1+CurTime())
        Player:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", dur+CurTime())
        Player.pk_pill_ent:PillAnim('inkportalexit')

        Player:SetAngles(AngleSet2)
        Player:SetPos(vector2go2+Vector(0,0,2))
        
        pk_pills.getMappedEnt(Player):SetNWVector("exitportalvector_redrawn", vector2go2 )
        pk_pills.getMappedEnt(Player):SetNWInt("move_redrawn", dur+CurTime())
        pk_pills.getMappedEnt(Player):SetNWAngle("Angle_redrawn", AngleSet2)
        pk_pills.getMappedEnt(Player):SetNWAngle("pill_assignedangle", AngleSet2 + Angle(0,180,0))
        
        Player.pk_pill_ent.locked = false

        Player:RemoveFlags(FL_NOTARGET)
        Player:SetMoveType(MOVETYPE_WALK)

        timer.Simple(0.1,function()
        if !IsValid(pk_pills.getMappedEnt(Player)) then return end
            AdvancedPillSound({
                stringe = "redrawn/bendy/Redrawn_inkportalexit.wav",
                soundLevel = 79
            }, pk_pills.getMappedEnt(Player))
            AdvancedPillSound({
                stringe = "redrawn/bendy/Redrawn_idleloop.wav",
                soundLevel = 67
            }, pk_pills.getMappedEnt(Player))
        end)

    end)


    hook.Add("EntityTakeDamage", "locust_disable_EntityTakeDamage", function(target, dmginfo)
        if target:IsPlayer() then
            local pillentity = target.pk_pill_ent
            if IsValid(pillentity) then
                if pillentity:GetNWBool('EnterPortal_redrawn') then
                    return false
                end
            end
        end
    end)

    hook.Add("PlayerShouldTakeDamage", "locst_disable_PlayerShouldTakeDamage", function(ply, attacker)
        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if pillentity:GetNWBool('EnterPortal_redrawn') then
                return false
            end
        end
    end)
    
else

    hook.Add("StartCommand", "stopkeyJump", function(ply, cmd)
        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent
        local screenW, screenH = ScrW(), ScrH()
        
        if IsValid(pillentity) then
            if pillentity:GetNWBool('gentoi_redrawn') then
                if pillentity:GetNWInt("NoJumping_redrawn") >= CurTime() then
                    cmd:RemoveKey(IN_JUMP)
                end
            end
        end
    end)


    net.Receive('gentoi_Redrawn_cam', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "gentoi_Redrawn_cam_" .. LocalPlayer():SteamID()

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 80 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)

    local preservedmats = {
        [0] = Material("icons/redrawn/inkbuttonicon.png"),
        [1] = Material("icons/redrawn/Inkoverlay.png"),
        [2] = Material("icons/redrawn/imag2icon.png"),
        [3] = Material("icons/redrawn/imag1icon.png"),
        [4] = Material("icons/redrawn/imag3icon.png")
    }
    hook.Add("HUDPaint", "redrawnbendy_hudpaint", function()

        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent
        local screenW, screenH = ScrW(), ScrH()
        
        if IsValid(pillentity) then
            if pillentity:GetNWBool('gentoi_redrawn') then
                --[[
                surface.SetDrawColor(255, 255, 255, 200)
                surface.SetMaterial(preservedmats[1])
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                ]]
                if pillentity:GetNWBool('EnterPortal_redrawn') or pillentity:GetNWInt("exitportal_redrawn") >= CurTime() or pillentity:GetNWInt("FadingIn_redrawn_gen") >= CurTime() then

                    local alpha = 0
                    if pillentity:GetNWBool("EnterPortal_redrawn") then
                        alpha = 255
                    end

                    if pillentity:GetNWInt("FadingIn_redrawn_gen") >= CurTime() then 
                        local lerpFactor = math.Clamp( (pillentity:GetNWInt("FadingIn_redrawn_gen")-CurTime() ) / 1, 0, 1)
                        alpha = Lerp(math.Clamp( lerpFactor*1.3, 0, 1 ), 255, 0)
                    else                
                        if pillentity:GetNWInt("exitportal_redrawn") >= CurTime() then 
                            local lerpFactor = math.Clamp( (pillentity:GetNWInt("exitportal_redrawn")-CurTime() ) / 1, 0, 1)
                            alpha = Lerp(math.Clamp( lerpFactor*1.3, 0, 1 ), 0, 255)
                        end
                    end

                    if alpha > 0 then
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.SetMaterial(preservedmats[1])
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    end

                    local alpha = 0

                    if pillentity:GetNWInt("FadingIn_redrawn_gen") >= CurTime() then 
                        local lerpFactor = math.Clamp( (pillentity:GetNWInt("FadingIn_redrawn_gen")-CurTime() ) / 1.4, 0, 1)
                        alpha = Lerp(math.Clamp( lerpFactor*1, 0, 1 ), 255, 0)
                    else
                        if pillentity:GetNWInt("FadingIn_redrawn_gen") + 1 >= CurTime() then 
                            local lerpFactor = math.Clamp( (pillentity:GetNWInt("FadingIn_redrawn_gen")+ 1-CurTime() ) / 0.5, 0, 1)
                            alpha = Lerp(math.Clamp( lerpFactor*1, 0, 1 ), 0, 255)
                        end
                    end
                    if alpha > 0 then
                        surface.SetDrawColor(0, 0, 0, alpha)
                        surface.DrawRect(0, 0, ScrW(), ScrH())
                    end
                else



                    
                    local screenW, screenH = ScrW(), ScrH()
                    local iconSize = ScreenScale(48)
                    local totalHeight = ScreenScale(64)
                    local spacing = ScreenScale(50)
                    local centerX = screenW / 2 + screenW / 3
                    local startY = screenH - totalHeight

                    local button1X = (centerX - spacing) - (iconSize / 2)
                    local button2X = (centerX) - (iconSize / 2)
                    local button3X = (centerX + spacing) - (iconSize / 2)

                    surface.SetMaterial(preservedmats[2])
                    if pillentity:GetNWInt("Ability1_cooldown") > CurTime() or not pillentity:GetNWBool("EnableCreatePortal") or pillentity:GetNWInt("PortalCount") >= 7 then
                        surface.SetDrawColor(75, 75, 75, 255)
                    else
                        surface.SetDrawColor(255, 255, 255, 255)
                    end
                    surface.DrawTexturedRect(button1X, startY, iconSize, iconSize)
                    -- PortalCount
                    draw.SimpleText("1", "CloseCaption_BoldItalic", button1X, startY, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    if pillentity:GetNWInt("PortalCount") < 7 then
                        if pillentity:GetNWBool("EnableCreatePortal") then
                            
                        else    
                            if pillentity:GetNWInt("Ability1_cooldown") > CurTime() then
                            else
                                draw.SimpleText("Cursor must be on wall", "Trebuchet18", button1X + iconSize*0.5, startY + iconSize*0.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                            end
                        end
                    end
                    draw.SimpleText(pillentity:GetNWInt("PortalCount").. " / 7", "CloseCaption_BoldItalic", button1X , startY + iconSize, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    if pillentity:GetNWInt("Ability1_cooldown") > CurTime() then
                        draw.SimpleText(math.Round( pillentity:GetNWInt("Ability1_cooldown")- CurTime(), 1), "CloseCaption_BoldItalic", button1X + iconSize*0.5, startY + iconSize*0.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    surface.SetMaterial(preservedmats[3])
                    if pillentity:GetNWInt("Ability2_cooldown") > CurTime() or pillentity:GetNWInt("CardboardCount") >= 5 then
                        surface.SetDrawColor(75, 75, 75, 255)
                    else
                        surface.SetDrawColor(255, 255, 255, 255)
                    end
                    surface.DrawTexturedRect(button2X, startY, iconSize, iconSize)

                    draw.SimpleText("2", "CloseCaption_BoldItalic", button2X, startY, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(pillentity:GetNWInt("CardboardCount").. " / 5", "CloseCaption_BoldItalic", button2X , startY + iconSize, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    if pillentity:GetNWInt("Ability2_cooldown") > CurTime() then
                        draw.SimpleText(math.Round( pillentity:GetNWInt("Ability2_cooldown")- CurTime(), 1), "CloseCaption_BoldItalic", button2X + iconSize*0.5, startY + iconSize*0.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    surface.SetMaterial(preservedmats[4])
                    if pillentity:GetNWInt("Ability3_cooldown") > CurTime() then
                        surface.SetDrawColor(75, 75, 75, 255)
                    else
                        surface.SetDrawColor(255, 255, 255, 255)
                    end
                    surface.DrawTexturedRect(button3X, startY, iconSize, iconSize)

                    draw.SimpleText("3", "CloseCaption_BoldItalic", button3X, startY, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    if pillentity:GetNWInt("Ability3_cooldown") > CurTime() then
                        draw.SimpleText( math.Round( pillentity:GetNWInt("Ability3_cooldown")- CurTime(), 1), "CloseCaption_BoldItalic", button3X + iconSize*0.5, startY + iconSize*0.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    
                end
            end
        end
    end)

    net.Receive("redrawndomainpopup_ui", function()
        local entity = net.ReadEntity()
        local tvstable = net.ReadTable()
        local player = LocalPlayer()
        if not IsValid(entity) then return end

        local locustframe = vgui.Create("DFrame")
        locustframe:SetTitle("")
        locustframe:SetSize(900*2, 200)
        locustframe:Center()
        locustframe:MakePopup()
        locustframe:ShowCloseButton(false)
        locustframe.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
        end
        locustframe:SetPos(ScrW() / 2 - 450*2, ScrH() - 300)


        local currentTV = tvstable[1]
        local selectedIndex = 1

        local hookID = "locust_cameraview_" .. LocalPlayer():SteamID()
        local savedCalcViewHooks = {}

        local calcViewHooks = hook.GetTable().CalcView or {}
        for k, v in pairs(calcViewHooks) do
            if k ~= hookID then
                savedCalcViewHooks[k] = v
                hook.Remove("CalcView", k)
            end
        end

        hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
            if ply == player then
                if not IsValid(currentTV) then
                    hook.Remove('CalcView', hookID)
                    for savedID, func in pairs(savedCalcViewHooks) do
                        hook.Add("CalcView", savedID, func)
                    end
                    savedCalcViewHooks = {}
                    return
                end

                local view = {
                    origin = currentTV:GetPos() + currentTV:GetForward() * -25 + Vector(0,0,45),
                    angles = currentTV:GetAngles()+Angle(0,180,0),
                    fov = 60,
                    drawviewer = false
                }
                return view
            end
        end)

        local loopSound = CreateSound(LocalPlayer(), "redrawn/bendy/Redrawn_inkportalloop.wav")

        if loopSound then
            loopSound:Play()
            loopSound:ChangeVolume(1, 1)
            loopSound:SetSoundLevel(75)
        end

        for i, tv in ipairs(tvstable) do
            local buttonSize = 100
            local spacing = 15
            local centerX = locustframe:GetWide() / 2 - buttonSize / 2
            local yPos = locustframe:GetTall() / 2 - buttonSize / 2

            local button = vgui.Create("DButton", locustframe)
            button:SetSize(buttonSize, buttonSize)
            button:SetText("")

            if i == 1 then
                button:SetPos(centerX, yPos)
            else
                local step = math.floor((i - 2) / 2) + 1
                local dir = (i % 2 == 0) and 1 or -1
                local xPos = centerX + dir * (step * (buttonSize + spacing))
                button:SetPos(xPos, yPos)
            end

            button.Paint = function(self, w, h)
                if selectedIndex == i then
                    surface.SetDrawColor(0, 255, 0) 
                else
                    surface.SetDrawColor(255, 255, 255) 
                end
                surface.SetMaterial(preservedmats[0])
                surface.DrawTexturedRect(0, 0, buttonSize*1.2, buttonSize*1.2)

                draw.SimpleText(i, "DermaLarge", 58, h / 2 + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            button.DoClick = function()
                surface.PlaySound("gentoi/anologhorror/locust/camerachance.wav")
                if currentTV ~= tv then
                    currentTV = tv
                    selectedIndex = i
                    pk_pills.getMappedEnt(LocalPlayer()):SetNWInt("CurrentSpectatingCamera",selectedIndex)
                else

                    hook.Remove('CalcView', hookID)
                    
                    net.Start("redrawnbendy_teleport")
                    net.WriteEntity(LocalPlayer())
                    net.WriteVector(tv:GetPos() + tv:GetForward()*-8)
                    net.WriteAngle(tv:GetAngles() + Angle(0,0,0))
                    net.SendToServer()
                    locustframe:Close()
                    loopSound:Stop()

                    for savedID, func in pairs(savedCalcViewHooks) do
                        hook.Add("CalcView", savedID, func)
                    end
                    
                end
            end
        end
    end)

end


local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff)
    if SERVER then
        if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
        if ent.IsInJumpscare >= CurTime() then return end
        if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
        if ent.IsInJumpscareCooldown >= CurTime() then return end

        local jumpscare_entity = nil

        for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
            if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
                if ent2 == ply then continue end
                if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

                if IsValid(ent2) then
                    jumpscare_entity = ent2
                    break
                end
            end
        end

        if jumpscare_entity ~= nil then
            
            ent.JuumpscareStart = CurTime()

            ent.jumpscare_entity = jumpscare_entity
            ent.entitylastpos = jumpscare_entity:GetPos()
            ent.entitylastang = jumpscare_entity:GetAngles()

            local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

            targetAngle.p = 0
            targetAngle.r = 0

            ply:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", duration+CurTime())
            jumpscare_entity:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", duration+CurTime())

            ent.IsInJumpscare = CurTime() + duration

            local puppet = ent:GetPuppet()

            if jumpscare_entity:IsPlayer() then
                net.Start('gentoi_Redrawn_cam')
                net.WriteEntity(puppet)
                net.WriteBool(true)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(duration+0.1+CurTime())
            end
            
            jumpscare_entity:AddFlags(FL_NOTARGET)
            ent:StopSound("redrawn/bendy/Redrawn_idleloop.wav")
            ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
                if !IsValid(jumpscare_entity) then return end

                jumpscare_entity:RemoveFlags(FL_NOTARGET)
                ent.jumpscare_entity = nil

                if jumpscare_entity:IsPlayer() then
                    net.Start('gentoi_Redrawn_cam')
                    net.WriteEntity(puppet)
                    net.WriteBool(false)
                    net.Send(jumpscare_entity)
                else
                    jumpscare_entity:NextThink(CurTime())
                end
                jumpscare_entity:SetPos(ent.entitylastpos)
                jumpscare_entity:SetAngles(ent.entitylastang)
                jumpscare_entity:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", CurTime())
            end)

            customanimstuff()
        end
    end
end

pk_pills.packStart("Redrawn Bend-O-Tron", "AnalogHorrorPills_gentio_rachel", "pills/PIll_rachel_ah.png")

pk_pills.register('PIll_redrawnBendy_ah', {

    printName='Redrawn Bend-O-Tron',
        
    model="models/gentoi/anologhorror/Redrawn_bendy.mdl",
    
    modelScale='1',

    noragdoll = true,
    muteSteps = true,
    noragdoll=true,
    health=9000,
    type='ply',
        

    FirstPersonBone = {
        'Head',
        9,
        0,
        21,
    },
    ThirdPersonBone = {
        'Head',
        0,
        30,
        -20,
    },
        
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            kill="Bendy_Kill Animation 232",
            inkportalenter="inkportalenter",
            inkportalexit="inkportalexit",
            deploycutout="deploycutout",
            crouch = "crawlidle",
            crouch_walk = "crawlwalk",
            grasp2 = "grasp2",
        },

        ShouldMoveRotate={
            idle= function(ent) 
                if not ent:GetPillUser():IsOnGround() then return 'notshftlock' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notanything'
            end,
            run= function(ent) 
                if ent:GetPillUser():GetVelocity():Length() < 418 then return 'shiftlock' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'

            end,
            walk= function(ent) 
                if ent:GetPillUser():GetVelocity():Length() < 88 then return 'shiftlock' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            fall= function(ent) 
                return 'notshftlock'
            end,
            inkportalenter = function(ent)
                return 'assignedagnles'
            end,
            inkportalexit = function(ent)
                return 'assignedagnles_instant'
            end,
            crawlwalk = function(ent) 
                if ent:GetPillUser():GetVelocity():Length() < 118 then return 'shiftlock' end
                if ent:GetPillUser():GetVelocity():Length() > 122 then return 'shiftlock' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end

                return 'notshftlock'
            end
        },

        ShouldAlternate={
        },
    },
    

    moveSpeed = {
        walk = 90,
        run = 470,
        ducked= 120,
    },
    camera={
        offset = Vector(0, 0, 50),
        dist=130,
    },
        
    jumpPower=0,
        
    
    movePoseMode="xy",

    aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
    --canAim=function(ply,ent) return ent.active end,     

    HandleAnimEvent_Noodles_redrawn_Gentoi_pill = function(ply, ent, event)
        if event == 'ragdoll' then

            if !IsValid(ent) then return end
            local jumpscare_entity = ent.jumpscare_entity
            if !(IsValid(jumpscare_entity)) then return end

            local ragdoll = ents.Create("prop_ragdoll")
            ragdoll:SetModel(jumpscare_entity:GetModel())
            ragdoll:SetPos(jumpscare_entity:GetPos())
            ragdoll:SetAngles(jumpscare_entity:GetAngles())
            ragdoll:SetSkin(jumpscare_entity:GetSkin() or 0)
            ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            ragdoll:Spawn()


            local physCount = ragdoll:GetPhysicsObjectCount()
            if physCount <= 0 then
                ragdoll:Remove()
                return end

            if not jumpscare_entity:IsPlayer() then
                local wep = jumpscare_entity:GetActiveWeapon()
                if IsValid(wep) then
                    jumpscare_entity.OldWeapon = wep
                    wep:SetNoDraw(true)
                end
            end

            if jumpscare_entity.GetBodyGroups then
                for _, bg in ipairs(jumpscare_entity:GetBodyGroups()) do
                    ragdoll:SetBodygroup(bg.id, jumpscare_entity:GetBodygroup(bg.id))
                end
            end

            if jumpscare_entity.GetPlayerColor and ragdoll.SetPlayerColor then
                ragdoll:SetPlayerColor(jumpscare_entity:GetPlayerColor())
            end

            if jumpscare_entity.GetColor then
                ragdoll:SetColor(jumpscare_entity:GetColor())
            end

            if jumpscare_entity.GetMaterial then
                ragdoll:SetMaterial(jumpscare_entity:GetMaterial())
            end

            if ragdoll.GetNumSubMaterials and ragdoll.SetSubMaterial and jumpscare_entity.GetSubMaterial then
                for i = 0, ragdoll:GetNumSubMaterials() - 1 do
                    local sub = jumpscare_entity:GetSubMaterial(i)
                    if sub then
                        ragdoll:SetSubMaterial(i, sub)
                    end
                end
            end

            jumpscare_entity:SetNoDraw(true)
            jumpscare_entity:SetNotSolid(true)

            ent.CurrentJumpscareRagdoll = ragdoll
            ent:DeleteOnRemove(ragdoll)

            hook.Add("Think", "ragdoll_nosey".. ent:EntIndex(), function()
                if !IsValid(ragdoll) then return end
                if SERVER then
                    local headPhys = nil

                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                        local phys = ragdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                            local boneName = ragdoll:GetBoneName(boneIndex) or ""
                            if string.find(string.lower(boneName), "head") then
                                headPhys = phys
                                break
                            end
                        end
                    end

                    if !IsValid(headPhys) then
                        headPhys = ragdoll:GetPhysicsObject()
                    end

                    if IsValid(headPhys) then
                        local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))
                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos)
                        headPhys:SetPos(NewVector)
                        headPhys:SetAngles(newAngle)

                        headPhys:Wake()
                    end
                end
            end)
        end

        if event == "throw" then
            if ent.CurrentJumpscareRagdoll then
                if IsValid(ent.CurrentJumpscareRagdoll) then
                    ent:DontDeleteOnRemove(ent.CurrentJumpscareRagdoll)

                    local ragdoll = ent.CurrentJumpscareRagdoll
                    local headPhys = nil

                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                        local phys = ragdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                            local boneName = ragdoll:GetBoneName(boneIndex) or ""
                            if string.find(string.lower(boneName), "head") then
                                headPhys = phys
                                break
                            end
                        end
                    end

                    if !IsValid(headPhys) then
                        headPhys = ragdoll:GetPhysicsObject()
                    end

                    if IsValid(headPhys) then
                        headPhys:SetVelocity(ent:GetPuppet():GetForward()*300000)
                        headPhys:Wake()
                    end


                end
            end
            hook.Remove('Think', "ragdoll_nosey".. ent:EntIndex())
        end
        
        if event == "CreateFakeCardboard" then
            if SERVER then
                local puppet = ent:GetPuppet()
                -- create prop thing, idk
                local fakecardpaord = ents.Create("prop_dynamic")
                local cam = puppet:GetAttachment(puppet:LookupAttachment('normalcam'))
                fakecardpaord:SetModel("models/Gentoi/anologhorror/FakeCardboard_redrawn.mdl")
                fakecardpaord:SetPos(cam.Pos)
                fakecardpaord:SetAngles(cam.Ang)

                local effectdata = EffectData()
                effectdata:SetOrigin(cam.Pos)
                util.Effect("redrawn_black_liquid", effectdata)

                fakecardpaord:Spawn()
                ent:DeleteOnRemove(fakecardpaord)
                ent:SetNWEntity('deleteFake_redrawn', fakecardpaord)

                local name = "Setposfor_"..fakecardpaord:EntIndex()
                hook.Add("Think", name, function()
                    if !IsValid(ent) or !IsValid(puppet) or !IsValid(fakecardpaord) then
                        hook.Remove("Think", name)
                        return
                    end
                    local cam = puppet:GetAttachment(puppet:LookupAttachment('normalcam'))
                    fakecardpaord:SetPos(cam.Pos)
                    local ang = cam.Ang
                    ang:RotateAroundAxis(ang:Up(),-90)
                    fakecardpaord:SetAngles(ang)  
                end)
            end
        end

        if event == "Deploycardboard" then
            if SERVER then
                local puppet = ent:GetPuppet()
                ent:GetNWEntity("deleteFake_redrawn"):Remove()
                local cardpaord = ents.Create("prop_physics")
                if IsValid(cardpaord) then

                    cardpaord:SetModel("models/Gentoi/anologhorror/Cardboard_redrawn.mdl")
                    cardpaord:SetPos(puppet:GetForward() * 60 + puppet:GetPos())
                    cardpaord:SetAngles(puppet:GetAngles())
                    cardpaord:Spawn()
                    table.insert(ent.InkTable_cardboard, cardpaord)
                    ent:SetNWInt("CardboardCount", #ent.InkTable_cardboard)

                    local cardPuddle = ents.Create("prop_dynamic")
                    if IsValid(cardPuddle) then
                        cardPuddle:SetModel("models/gentoi/anologhorror/inkplane_redrawn.mdl")
                        cardPuddle:SetPos(cardpaord:GetPos() + Vector(0, 0, 1))
                        cardPuddle:SetAngles(cardpaord:GetAngles())
                        cardPuddle:SetModelScale(0, 0)
                        cardPuddle:Spawn()

                        local effectdata = EffectData()
                        effectdata:SetOrigin(cardpaord:GetPos() + Vector(0, 0, 1))
                        util.Effect("redrawn_black_liquid", effectdata)

                        local effectdata = EffectData()
                        effectdata:SetOrigin(cardpaord:GetPos() + Vector(0, 0, 1))
                        util.Effect("redrawn_black_liquid", effectdata)
                        
                        local startTime = CurTime()
                        local Growing = true
                        local basePos = cardPuddle:GetPos()
                        local baseAng = cardPuddle:GetAngles()
                        local activeMinis = {}

                        hook.Add("Think", cardPuddle, function()
                            if not IsValid(cardPuddle) then
                                hook.Remove("Think", cardPuddle)
                                return
                            end

                            if Growing then
                                local frac = math.Clamp((CurTime() - startTime) / 3, 0, 1)
                                cardPuddle:SetModelScale(frac * 1.3, 0)
                                if frac >= 1 then Growing = false end
                            end

                            local t = CurTime() * 2
                            local upDown = math.sin(t) * 2
                            local rotOffset = math.sin(t * 0.6) * 10
                            cardPuddle:SetPos(basePos + Vector(0, 0, upDown))
                            cardPuddle:SetAngles(Angle(baseAng.p, baseAng.y + rotOffset, baseAng.r))

                            for _, ent in ipairs(ents.FindInSphere(cardPuddle:GetPos(), 190)) do
                                if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
                                    if ent.pk_pill_ent and IsValid(ent.pk_pill_ent) then continue end
                                    if ent:GetClass() == "pill_puppet" then continue end
                                    if not IsValid(activeMinis[ent]) then
                                        local mini = ents.Create("prop_dynamic")
                                        if IsValid(mini) then
                                            activeMinis[ent] = mini
                                            mini:SetModel("models/gentoi/anologhorror/inkplane_redrawn.mdl")
                                            mini:SetPos(cardPuddle:GetPos() + Vector(0, 0, 1))
                                            mini:SetAngles(cardPuddle:GetAngles())
                                            mini:SetModelScale(0.6, 0)
                                            mini:Spawn()

                                            local spawnTime = CurTime()
                                            local lifeTime = 10
                                            local returning = false
                                            local latched = false
                                            local latchOffset = Vector(0, 0, 0)
                                            local shrinkStart = nil

                                            mini:CallOnRemove("dynamic", function()
                                                ent:SetNWBool("CardPuddleSlowed", false)
                                            end)

                                            hook.Add("Think", mini, function()
                                                if not IsValid(mini) then hook.Remove("Think", mini) return end

                                                if not IsValid(cardPuddle) or (IsValid(ent) and ent:IsPlayer() and not ent:Alive()) or not IsValid(ent) then
                                                    if not shrinkStart then shrinkStart = CurTime() end
                                                    local frac = 1 - math.Clamp((CurTime() - shrinkStart) / 1, 0, 1)
                                                    mini:SetModelScale(frac * 0.6, 0)
                                                    if frac <= 0 then
                                                        if IsValid(ent) and ent:IsPlayer() then ent:SetNWBool("CardPuddleSlowed", false) end
                                                        mini:Remove()
                                                        hook.Remove("Think", mini)
                                                        activeMinis[ent] = nil
                                                    end
                                                    return
                                                end

                                                if latched and IsValid(ent) then
                                                    mini:SetPos(ent:GetPos() + latchOffset)
                                                    local ang = mini:GetAngles()
                                                    ang:RotateAroundAxis(ang:Up(), FrameTime() * 180)
                                                    mini:SetAngles(ang)
                                                    return
                                                end

                                                local distSqr = IsValid(ent) and ent:GetPos():DistToSqr(cardPuddle:GetPos()) or 0
                                                if distSqr < 200*200 then
                                                    returning = false
                                                else
                                                    returning = true
                                                end

                                                local destPos
                                                if not returning then
                                                    destPos = ent:GetPos() + Vector(0,0,1)
                                                else
                                                    destPos = cardPuddle:GetPos() + Vector(0,0,1)
                                                end
                                                destPos.z = cardPuddle:GetPos().z

                                                local dir = (destPos - mini:GetPos()):GetNormalized()
                                                local speed = returning and 60 or 200
                                                mini:SetPos(mini:GetPos() + dir * FrameTime() * speed)

                                                local ang = mini:GetAngles()
                                                ang:RotateAroundAxis(ang:Up(), FrameTime() * 180)
                                                mini:SetAngles(ang)

                                                if not returning and mini:GetPos():DistToSqr(ent:GetPos()) < 40*40 then
                                                    latched = true
                                                    latchOffset = mini:GetPos() - ent:GetPos()
                                                    if IsValid(ent) and ent:IsPlayer() then
                                                        ent:SetNWBool("CardPuddleSlowed", true)
                                                    end
                                                end

                                                if returning and mini:GetPos():DistToSqr(cardPuddle:GetPos()) < 17*17 then
                                                    if not shrinkStart then shrinkStart = CurTime() end
                                                    local frac = 1 - math.Clamp((CurTime() - shrinkStart) / 1, 0, 1)
                                                    mini:SetModelScale(frac * 0.6, 0)
                                                    if frac <= 0 then
                                                        if IsValid(ent) and ent:IsPlayer() then ent:SetNWBool("CardPuddleSlowed", false) end
                                                        mini:Remove()
                                                        hook.Remove("Think", mini)
                                                        activeMinis[ent] = nil
                                                    end
                                                elseif CurTime() - spawnTime > lifeTime then
                                                    if not shrinkStart then shrinkStart = CurTime() end
                                                    local frac = 1 - math.Clamp((CurTime() - shrinkStart) / 1, 0, 1)
                                                    mini:SetModelScale(frac * 0.6, 0)
                                                    if frac <= 0 then
                                                        if IsValid(ent) and ent:IsPlayer() then ent:SetNWBool("CardPuddleSlowed", false) end
                                                        mini:Remove()
                                                        hook.Remove("Think", mini)
                                                        activeMinis[ent] = nil
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end)

                        cardpaord:CallOnRemove("ShrinkPuddle_" .. cardPuddle:EntIndex(), function(_, puddle)
                            if IsValid(ent) then

                                table.RemoveByValue(ent.InkTable_cardboard, cardpaord)
                                ent:SetNWInt("CardboardCount", #ent.InkTable_cardboard)
                            end
                            if !IsValid(puddle) then
                                for _, mini in pairs(activeMinis) do
                                    for e, m in pairs(activeMinis) do
                                        if m == mini and IsValid(e) and e:IsPlayer() then
                                            e:SetNWBool("CardPuddleSlowed", false)
                                            break
                                        end
                                    end
                                    mini:Remove()
                                    hook.Remove("Think", mini)
                                end
                                return
                            end
                            local startShrink = CurTime()
                            local basePos = puddle:GetPos()
                            local baseAng = puddle:GetAngles()
                            hook.Add("Think", puddle, function()
                                if not IsValid(puddle) then
                                    hook.Remove("Think", puddle)
                                    return
                                end
                                local frac = 1 - math.Clamp((CurTime() - startShrink) / 1, 0, 1)
                                puddle:SetModelScale(frac, 0)
                                local t = CurTime() * 2
                                local upDown = math.sin(t) * 2 * frac
                                local rotOffset = math.sin(t * 0.6) * 10 * frac
                                puddle:SetPos(basePos + Vector(0, 0, upDown))
                                puddle:SetAngles(Angle(baseAng.p, baseAng.y + rotOffset, baseAng.r))
                                if frac <= 0 then
                                    for _, mini in pairs(activeMinis) do
                                        if IsValid(mini) then
                                            local shrink = CurTime()
                                            hook.Add("Think", mini, function()
                                                if not IsValid(mini) then
                                                    hook.Remove("Think", mini)
                                                    return
                                                end
                                                local f = 1 - math.Clamp((CurTime() - shrink) / 1, 0, 1)
                                                mini:SetModelScale(f * 0.6, 0)
                                                if f <= 0 then
                                                    for e, m in pairs(activeMinis) do
                                                        if m == mini and IsValid(e) and e:IsPlayer() then
                                                            e:SetNWBool("CardPuddleSlowed", false)
                                                            break
                                                        end
                                                    end
                                                    mini:Remove()
                                                    hook.Remove("Think", mini)
                                                end
                                            end)
                                        end
                                    end
                                    puddle:Remove()
                                    hook.Remove("Think", puddle)
                                end
                            end)
                        end, cardPuddle)
                    end

                    cardpaord:SetMoveType(MOVETYPE_NONE)
                    cardpaord:SetSolid(SOLID_VPHYSICS)
                    cardpaord:SetCollisionGroup(COLLISION_GROUP_NONE)

                    cardpaord.PhysgunDisabled = true
                    cardpaord.CanTool = function() return false end
                    cardpaord.CanPhysgun = function() return false end
                    cardpaord.CanDrive = function() return false end
                    cardpaord.CanProperty = function() return false end

                    ent:DeleteOnRemove(cardpaord)

                    local HoldStart = {}
                    local NextShake = 0

                    cardpaord.Use = function(self, activator)
                        if not activator then return end
                        if not HoldStart[activator] then HoldStart[activator] = CurTime() end
                    end

                    local hookname = "Gentoi_CardpaordHoldDestroy" .. cardpaord:EntIndex()
                    hook.Add("Think", hookname, function()
                        for _, ply in ipairs(player.GetAll()) do
                            if not IsValid(cardpaord) then
                                hook.Remove("Think", hookname)
                                break
                            end
                            if ply:GetPos():Distance(cardpaord:GetPos()) > 90 then
                                HoldStart[ply] = nil
                                continue
                            end
                            local tr = ply:GetEyeTrace()
                            local trent = tr.Entity

                            if IsValid(trent) and trent == cardpaord then
                                if ply:KeyDown(IN_USE) then
                                    if not HoldStart[ply] then
                                        HoldStart[ply] = CurTime()
                                    end

                                    if NextShake < CurTime() then
                                        NextShake = CurTime() + 0.05
                                        local originalPos = trent:GetPos()
                                        local offset = VectorRand() * 0.5
                                        trent:SetPos(originalPos + offset)
                                        local e = trent
                                        timer.Simple(0.05, function()
                                            if IsValid(e) then
                                                e:SetPos(originalPos)
                                            end
                                        end)
                                    end

                                    if CurTime() - HoldStart[ply] >= 5 then
                                        trent:EmitSound("physics/cardboard/cardboard_box_break1.wav", 75, 100)

                                        local effectdata = EffectData()
                                        effectdata:SetOrigin(trent:GetPos())
                                        util.Effect("redrawn_black_liquid", effectdata)
                                        local effectdata = EffectData()
                                        effectdata:SetOrigin(trent:GetPos())
                                        util.Effect("redrawn_black_liquid", effectdata)
                                        local effectdata = EffectData()
                                        effectdata:SetOrigin(trent:GetPos())
                                        util.Effect("redrawn_black_liquid", effectdata)
                                        
                                        trent:Remove()

                                        HoldStart[ply] = nil
                                    end
                                else
                                    HoldStart[ply] = nil
                                end
                            end
                        end
                    end)
                end
            end
        end

        if event == "StopVelocityBi" then
            ent:SetNWInt("move_redrawn", 0)
        end

        if event == "Step" then
            if ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "run" then
                AdvancedPillSound({
                    stringe = {
                        "redrawn/bendy/Redrawn_steprunning1.wav",
                        "redrawn/bendy/Redrawn_steprunning2.wav",
                        "redrawn/bendy/Redrawn_steprunning3.wav",
                        "redrawn/bendy/Redrawn_steprunning4.wav"
                    },
                    soundLevel = 79
                }, ent)
            else
                AdvancedPillSound({
                    stringe = {
                        "redrawn/bendy/Redrawn_step1.wav",
                        "redrawn/bendy/Redrawn_step2.wav",
                        "redrawn/bendy/Redrawn_step3.wav",
                        "redrawn/bendy/Redrawn_step4.wav",
                        "redrawn/bendy/Redrawn_step5.wav"
                    },
                    soundLevel = 79
                }, ent)
            end
        end

        if event == "Kill_entity" then
            if SERVER then
                timer.Simple(0.6,function()
                    if !IsValid(ent) then return end
                    local jumpscare_entity = ent.jumpscare_entity
                    if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end
                    ent.jumpscare_entity = nil
                    jumpscare_entity:SetPos(ent.entitylastpos)
                    jumpscare_entity:SetAngles(ent.entitylastang)
                    if jumpscare_entity:IsPlayer() then
                        net.Start('gentoi_Redrawn_cam')
                        net.WriteEntity(puppet)
                        net.WriteBool(false)
                        net.Send(jumpscare_entity)
                        jumpscare_entity:Kill(ply)
                    else
                        jumpscare_entity:NextThink(CurTime())

                        jumpscare_entity:TakeDamage(1e9, ply)
                    end
                    ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
                    AdvancedPillSound({
                        stringe = "redrawn/bendy/Redrawn_idleloop.wav",
                        soundLevel = 67
                    }, ent)
                end)
            end
        end
        if SERVER then
            local DurationForEvent = 0
            local function lerpfunction(lerpdur, oldnum, newnumb)
                local progress = 1 - ((DurationForEvent - CurTime()) / lerpdur)
                local val = Lerp( math.Clamp(progress, 0, 1) , oldnum, newnumb)
                return val
            end
            if event == "scalefrom1to2_start" then
                DurationForEvent = CurTime() + 0.239990234375

                local puppet = ent:GetPuppet()
                local hookname = "transition1_" .. puppet:EntIndex()

                hook.Add("Think", hookname, function()
                    if CurTime() > DurationForEvent or !IsValid(puppet) then
                        hook.Remove("Think", hookname)
                        return
                    end

                    local valv = lerpfunction(0.239990234375, 1, 2.49209)
                    puppet:ManipulateBoneScale(puppet:LookupBone("UpperArmE.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.239990234375, 1, 3.07137)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmS.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.239990234375, 1, 2.59751)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmE.R"), Vector(valv,valv,valv))

                    --puppet:SetPoseParameter("Aim_StretchR", lerpfunction(0.239990234375, 0, 2))
                end)                
            end
            if event == "scalefrom2to3_start" then
                DurationForEvent = CurTime() + 0.07501220703125
                
                local puppet = ent:GetPuppet()
                local hookname = "transition2_" .. puppet:EntIndex()

                hook.Add("Think", hookname, function()
                    if CurTime() > DurationForEvent or !IsValid(puppet) then
                        hook.Remove("Think", hookname)
                        return
                    end

                    local valv = lerpfunction(0.07501220703125, 2.49209, 2.08219)
                    puppet:ManipulateBoneScale(puppet:LookupBone("UpperArmE.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.07501220703125, 3.07137, 2.50233)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmS.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.07501220703125, 2.59751, 3.8745)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmE.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.07501220703125, 1, 3.69828)
                    puppet:ManipulateBoneScale(puppet:LookupBone("Hand.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.07501220703125, 1, 3.69828)
                    puppet:ManipulateBoneScale(puppet:LookupBone("Index1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Index2.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Middle1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Middle2.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Pinky1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Pinky1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Thumb1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Thumb1.R"), Vector(valv,valv,valv))

                    local y = lerpfunction(0.07501220703125, 0, 12)
                    local z = lerpfunction(0.07501220703125, 0, -7)
                    puppet:ManipulateBonePosition(puppet:LookupBone("Index1.R"), Vector(0,y,z))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Index2.R"), Vector(0,y,z))

                    local y = lerpfunction(0.07501220703125, 0, 7)
                    puppet:ManipulateBonePosition(puppet:LookupBone("Middle1.R"), Vector(0,y,0))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Middle2.R"), Vector(0,y,0))

                    puppet:ManipulateBonePosition(puppet:LookupBone("Pinky1.R"), Vector(0,y,y))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Pinky2.R"), Vector(0,y,y))

                    --puppet:SetPoseParameter("Aim_StretchR", lerpfunction(0.07501220703125, 2, 10))
                end)
            end
            if event == "scalefrom3to4_start" then
                DurationForEvent = CurTime() + 0.20999145507812

                local puppet = ent:GetPuppet()
                local hookname = "transition3_" .. puppet:EntIndex()

                hook.Add("Think", hookname, function()
                    if CurTime() > DurationForEvent or !IsValid(puppet) then
                        hook.Remove("Think", hookname)
                        return
                    end

                    local valv = lerpfunction(0.20999145507812, 2.08219, 1)
                    puppet:ManipulateBoneScale(puppet:LookupBone("UpperArmE.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.20999145507812, 2.50233, 1)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmS.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.20999145507812, 3.8745, 1)
                    puppet:ManipulateBoneScale(puppet:LookupBone("LowerArmE.R"), Vector(valv,valv,valv))

                    local valv = lerpfunction(0.20999145507812, 3.69828, 1)
                    puppet:ManipulateBoneScale(puppet:LookupBone("Hand.R"), Vector(valv,valv,valv))
                    
                    local valv = lerpfunction(0.20999145507812, 3.69828, 1)
                    puppet:ManipulateBoneScale(puppet:LookupBone("Index1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Index2.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Middle1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Middle2.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Pinky1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Pinky1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Thumb1.R"), Vector(valv,valv,valv))
                    puppet:ManipulateBoneScale(puppet:LookupBone("Thumb1.R"), Vector(valv,valv,valv))

                    local y = lerpfunction(0.20999145507812, 12, 0)
                    local z = lerpfunction(0.20999145507812, -7, 0)
                    puppet:ManipulateBonePosition(puppet:LookupBone("Index1.R"), Vector(0,y,z))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Index2.R"), Vector(0,y,z))

                    local y = lerpfunction(0.20999145507812, 7, 0)
                    puppet:ManipulateBonePosition(puppet:LookupBone("Middle1.R"), Vector(0,y,0))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Middle2.R"), Vector(0,y,0))

                    puppet:ManipulateBonePosition(puppet:LookupBone("Pinky1.R"), Vector(0,y,y))
                    puppet:ManipulateBonePosition(puppet:LookupBone("Pinky2.R"), Vector(0,y,y))
                end)
            end

            if event == "scale_3-4_short" then
                DurationForEvent = CurTime() + 0.35

                local puppet = ent:GetPuppet()
                local hookname = "transition25_" .. puppet:EntIndex()

                hook.Add("Think", hookname, function()
                    if CurTime() > DurationForEvent or !IsValid(puppet) then
                        hook.Remove("Think", hookname)
                        return
                    end

                    --puppet:SetPoseParameter("Aim_StretchR", lerpfunction(0.35, 10, 0))
                end)
            end
        end
    end,

    noodles_redrawn_gentoi_initialize=function(initializetable,initializetable2,initializetable3)
        if SERVER then
            AdvancedPillSound({
                stringe = "redrawn/bendy/Redrawn_idleloop.wav",
                soundLevel = 59
            }, initializetable2["entity"])

            initializetable2["entity"].InkTable_portal = {}
            initializetable2["entity"].InkTable_cardboard = {}
            initializetable2["entity"]:SetNWBool("gentoi_redrawn", true)
        end
    end,
    noodles_redrawn_gentoi_OnRemove=function(initializetable,initializetable2,initializetable3)
        initializetable2["entity"]:StopSound("redrawn/bendy/Redrawn_idleloop.wav")
        if !IsValid(initializetable2["player"]) then return end
        initializetable2["player"]:SetMoveType(MOVETYPE_WALK)
    end,

    think_noodles_redrawn_gentoi_pill = function(ply, ent)

        if SERVER then
            if ent:GetNWInt("grasp_duration") > CurTime() then
                --grasp_durationgrasp_duration
                local puppet = ent:GetPuppet()
                local boneIndex = puppet:LookupBone("Hand.R")
                local boneMatrix = boneIndex and puppet:GetBoneMatrix(boneIndex)
                
                local pos2 = boneMatrix:GetTranslation()
                
                if ent.grabbedentity then
                    if IsValid(ent.grabbedentity) then
                        local cam = puppet:GetAttachment(puppet:LookupAttachment("camera"))
                        ent.grabbedentity:SetPos(cam.Pos)
                    else
                        ent.grabbedentity = nil
                    end
                else
                    local puppet = ent:GetPuppet()

                    local tranceamount = 660
                    local trace = ply:GetForward() * 660

                    local boneIndex = puppet:LookupBone("Hand.R")
                    local boneMatrix = boneIndex and puppet:GetBoneMatrix(boneIndex)
                    
                    local pos2 = boneMatrix:GetTranslation()

                    local distancebetween2 = pos2:Distance(ent:GetPos())

                    if distancebetween2 < tranceamount then
                        tranceamount = distancebetween2
                    end
                    
                    for _, ent2 in pairs(ents.FindInSphere(ply:GetPos() + Vector(0,0,20) + ply:GetForward() * tranceamount, 200)) do
                        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() > 0 then
                            if ent2 == ply then continue end
                            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end


                            local trace = util.TraceLine({start = pos2 + Vector(0,0,20) + ply:GetForward() * tranceamount, endpos = ent2:LocalToWorld(Vector(0,0,40)), filter = {ent, ply}, mask = MASK_VISIBLE})

                            if not trace.Hit then
                                ent.grabbedentity = ent2
                                break
                            end
                        end
                    end

                end
            end

            if ent.InkTable_portal then
                if #ent.InkTable_portal < 7 then
                    local tr = ply:GetEyeTrace()

                    if not tr.Hit then return end

                    local normal = tr.HitNormal

                    if math.abs(normal.z) < 0.5 then
                        local groundTrace = util.TraceLine({
                            start = tr.HitPos,
                            endpos = tr.HitPos - Vector(0, 0, 5000),
                            filter = ply
                        })

                        if groundTrace.Hit then
                            local backTrace = util.TraceLine({
                                start = groundTrace.HitPos + normal * 1,
                                endpos = groundTrace.HitPos - normal * 100, 
                                filter = ply,
                                mask = MASK_SOLID
                            })

                            if backTrace.Hit and math.abs(backTrace.HitNormal.z) < 0.5 then
                                ent:SetNWBool("EnableCreatePortal", true)
                            else
                                ent:SetNWBool("EnableCreatePortal", false)
                            end
                        else
                            ent:SetNWBool("EnableCreatePortal", false)
                        end
                    else
                        ent:SetNWBool("EnableCreatePortal", false)
                    end
                end
            end
            if not ent.liquidcooldown then
                ent.liquidcooldown = 0
            end
                    
            if ent.liquidcooldown < CurTime() then
                if ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "crawlwalk" then
                    ent.liquidcooldown = CurTime() + 0.5
                    
                    local puppet = ent:GetPuppet()
                    local boneIndex = puppet:LookupBone("LowerTorso")
                    local boneMatrix = boneIndex and puppet:GetBoneMatrix(boneIndex)
                    
                    local pos2 = boneMatrix:GetTranslation()
                    
                    local effectdata = EffectData()
                    effectdata:SetOrigin(pos2)
                    util.Effect("redrawn_black_liquid", effectdata)
                else
                end
            end
            

            if ent:GetNWInt("move_redrawn") > CurTime() then
                if ent:GetNWVector("exitportalvector_redrawn"):Distance(ply:GetPos()) > 120 then
                    ply:SetMoveType(MOVETYPE_WALK)
                else
                    ply:SetAngles(ent:GetNWAngle("Angle_redrawn"))
                    ply:SetPos(ply:GetPos()+ply:GetForward()*-1.2)
                    ply:SetMoveType(MOVETYPE_NONE)
                end
            else
                ply:SetMoveType(MOVETYPE_WALK)
            end
            if not ent:GetNWBool("EnterPortal_redrawn") then
                ent:GetPuppet():SetColor(Color(255,255,255,255))
            end
            if ent.jumpscare_entity then
                local entity = ent.jumpscare_entity
                if IsValid(entity) then

                    local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                    local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                    if entity:Health() < 0.1 and entity:IsPlayer() then
                        ent.jumpscare_entity = nil
                    else
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        local lengthofentitybody = ((maxs.z - mins.z)/2)*4

                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                        entity:SetPos(NewVector)
                        entity:SetAngles(newAngle)
                    end
                end
            end

            local speed = {
                ['walk'] = GetConVar("GentoiPills_redrawnbendy_walkspeed"):GetFloat(),
                ['run'] = GetConVar("GentoiPills_redrawnbendy_runspeed"):GetFloat(),
                ['ducked'] = GetConVar("GentoiPills_redrawnbendy_crouchspeed"):GetFloat(),
                ['jumppower'] = GetConVar("GentoiPills_redrawnbendy_jumppower"):GetFloat(),
            }

            if ply:Crouching() then
                speed['walk'] = speed['ducked']
            end

            if IsValid(ply) and IsValid(ent) then
                ply:SetWalkSpeed(speed.walk)
                ply:SetRunSpeed(speed.run)
                ply:SetCrouchedWalkSpeed(speed.ducked)
                ply:SetJumpPower(speed.jumppower)
            end
        end
    end,

    noodles_redrawn_gentoi_keybinds = function(ply,ent,button)
        if button == KEY_R then
            if SERVER then
                if ent:GetNWBool("Shiftlock") then
                    ent:SetNWBool("Shiftlock", false)
                else
                    ent:SetNWBool("Shiftlock", true)
                end
            end
        end
        if button == KEY_3 then
            if SERVER then
                if not GetConVar("GentoiPills_redrawnbendy_CanGrasp"):GetBool() then return end
                if ent:GetNWInt("redrawn_abilityprvention") > CurTime() then return end
                if ent:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") > CurTime() then return end
                if ent:GetNWBool("EnterPortal_redrawn") then return end
                if ent:GetNWInt("Ability3_cooldown") > CurTime() then return end
                
                AdvancedPillSound({
                    stringe = "redrawn/bendy/Redrawn_grasp.wav",
                    soundLevel = 79
                }, ent)
                local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("grasp2"))
                ent:SetNWInt("grasp_duration", dur+CurTime()-0.8)
                ent:SetNWInt("NoJumping_redrawn", dur+CurTime())
                ent:PillAnim("grasp2")
                ent.grabbedentity = nil

                ent:SetNWInt("redrawn_abilityprvention", dur + CurTime() + 0.6 )
                ent:SetNWInt("Ability3_cooldown", GetConVar("GentoiPills_redrawnbendy_GraspCooldown"):GetFloat() + dur + CurTime() )
                ply:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", dur+CurTime())
            end

        end
        if button == KEY_2 then
            if SERVER then
                if not GetConVar("GentoiPills_redrawnbendy_CanCardboard"):GetBool() then return end
                if ent:GetNWInt("redrawn_abilityprvention") > CurTime() then return end
                if ent:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") > CurTime() then return end
                if ent:GetNWBool("EnterPortal_redrawn") then return end
                if ent:GetNWInt("Ability2_cooldown") > CurTime() then return end

                if #ent.InkTable_cardboard >= GetConVar("GentoiPills_redrawnbendy_MaxCardboards"):GetFloat() then return end
                local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("deploycutout"))
                ply:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", dur+CurTime())
                ent:PillAnim('deploycutout')
                ent:SetNWInt("NoJumping_redrawn", dur+CurTime())
                

                ent:SetNWInt("redrawn_abilityprvention", dur+CurTime())
                ent:SetNWInt("Ability2_cooldown", GetConVar("GentoiPills_redrawnbendy_CardboardCooldown"):GetFloat() + dur +CurTime() )
                AdvancedPillSound({
                    stringe = "redrawn/bendy/Redrawn_cardboardplacement.wav",
                    soundLevel = 79
                }, ent)
            end
        end
        if button == KEY_1 then
            if SERVER then
                if not GetConVar("GentoiPills_redrawnbendy_CanDeployPuddles"):GetBool() then return end
                if ent:GetNWInt("redrawn_abilityprvention") > CurTime() then return end
                if ent:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") > CurTime() then return end
                if ent:GetNWInt("Ability1_cooldown") > CurTime() then return end
                if ent:GetNWBool("EnterPortal_redrawn") then return end
                if not IsValid(ply) then return end
                if not IsValid(ent) then return end

                local tr = ply:GetEyeTrace()
                if #ent.InkTable_portal >= GetConVar("GentoiPills_redrawnbendy_MaxPuddles"):GetFloat() then return end

                if not tr.Hit then return end

                local normal = tr.HitNormal

                if math.abs(normal.z) < 0.5 then
                    local groundTrace = util.TraceLine({
                        start = tr.HitPos,
                        endpos = tr.HitPos - Vector(0, 0, 5000),
                        filter = ply
                    })

                    if groundTrace.Hit then
                        local backTrace = util.TraceLine({
                            start = groundTrace.HitPos + normal * 1,
                            endpos = groundTrace.HitPos - normal * 100, 
                            filter = ply,
                            mask = MASK_SOLID
                        })

                        if backTrace.Hit and math.abs(backTrace.HitNormal.z) < 0.5 then
                            local dynamic = ents.Create("prop_dynamic")
                            if IsValid(dynamic) then
                                
                                dynamic:SetModel("models/gentoi/anologhorror/InkPuddle.mdl")
                                dynamic:SetPos(backTrace.HitPos + backTrace.HitNormal * -13)


                                AdvancedPillSound({
                                    stringe = "redrawn/bendy/Redrawn_inkportalsummon.wav",
                                    soundLevel = 79
                                }, ent)
                                
                                for i, v in ipairs(ent.InkTable_portal) do
                                    if v:GetPos():Distance(dynamic:GetPos()) < 300 then
                                        dynamic:Remove()
                                        return
                                    end
                                end

                                local ang = backTrace.HitNormal:Angle()
                                ang:RotateAroundAxis(ang:Up(), 180)
                                dynamic:SetAngles(ang)

                                dynamic:SetParent(nil)
                                dynamic:Spawn()
                                ent:DeleteOnRemove(dynamic)

                                dynamic:SetRenderMode(RENDERMODE_TRANSALPHA)
                                dynamic:SetColor(Color(255, 255, 255, 255))
                                dynamic:SetModelScale(0, 0)


                                local startTime = CurTime()
                                local duration = 0.5
                                local timerName = "InkPuddleGrow_" .. dynamic:EntIndex()

                                timer.Create(timerName, 0, 0, function()
                                    if !IsValid(dynamic) then
                                        timer.Remove(timerName)
                                        return
                                    end

                                    local elapsed = CurTime() - startTime
                                    local frac = math.Clamp(elapsed / duration, 0, 1)
                                    dynamic:SetModelScale(frac, 0)

                                    if frac >= 1 then
                                        timer.Remove(timerName)
                                    end
                                end)


                                local effectdata = EffectData()
                                effectdata:SetOrigin(backTrace.HitPos + backTrace.HitNormal*2)
                                util.Effect("redrawn_black_liquid_spawnportal", effectdata)


                                table.insert(ent.InkTable_portal, dynamic)
                                ent:SetNWInt("Ability1_cooldown", GetConVar("GentoiPills_redrawnbendy_DeployPuddlesCooldown"):GetFloat() +CurTime() )       

                                ent:SetNWInt("PortalCount", #ent.InkTable_portal)
                            end
                        end
                    end
                end
            end
        end
        if button == KEY_E then
            if ent:GetNWInt("redrawn_abilityprvention") > CurTime() then return end
            if ent:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") > CurTime() then return end
            if ent:GetNWBool("EnterPortal_redrawn") then return end
            if SERVER then
                if ent:GetNWBool("EnterPortal_redrawn") then return end
                for i,v in ipairs(ent.InkTable_portal) do
                    if v:GetPos():Distance(ent:GetPos()) < 160 then
                        local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("inkportalenter"))

                        timer.Simple(dur,function()
                            if !IsValid(ent) then return end
                            ply:SetNWInt("CurrentSpectatingCamera",i)

                            net.Start("redrawndomainpopup_ui")
                            net.WriteEntity(ent)
                            net.WriteTable(ent.InkTable_portal)
                            net.Send(ply)
                        end)

                        ply:SetNWInt("DisablePlayerMovement_gentoi_redrawn_stun", dur+CurTime())
                        ent:SetNWInt("FadingIn_redrawn_gen", dur+CurTime())
                        ent:PillAnim('inkportalenter')

                        local fadeStart = CurTime() + dur - 1
                        local fadeEnd = CurTime() + dur

                        local puppet = ent:GetPuppet()

                        hook.Add("Think", "InkPortalFade_"..puppet:EntIndex(), function()
                            if !IsValid(puppet) then 
                                hook.Remove("Think", "InkPortalFade_"..puppet:EntIndex())
                                return
                            end

                            if CurTime() >= fadeEnd then
                                puppet:SetRenderMode(RENDERMODE_TRANSALPHA)
                                puppet:SetColor(Color(255,255,255,0))
                                hook.Remove("Think", "InkPortalFade_"..puppet:EntIndex())
                                return
                            elseif CurTime() >= fadeStart then
                                local alpha = 255 * (1 - (CurTime() - fadeStart) / (fadeEnd - fadeStart))
                                puppet:SetRenderMode(RENDERMODE_TRANSALPHA)
                                puppet:SetColor(Color(255,255,255,math.Clamp(alpha,0,255)))
                            end
                        end)

                        local portalangle = v:GetAngles()
                        portalangle.y = portalangle.y
                        ent:SetNWAngle("pill_assignedangle", portalangle)

                        ply:SetPos(v:GetPos()+ v:GetForward()*-80)

                        ent:SetNWBool("EnterPortal_redrawn", true)
                        ply.pk_pill_ent.locked = true

                        AdvancedPillSound({
                            stringe = "redrawn/bendy/Redrawn_inkportalenter.wav",
                            soundLevel = 67
                        }, ent)
                        ent:StopSound("redrawn/bendy/Redrawn_idleloop.wav")
                        break
                    end
                end
            end
        end
    end,
    
    attack = {
        mode = 'trigger',
        func = function(ply, ent)
            if ent:GetNWInt("redrawn_abilityprvention") > CurTime() then return end
            if ent:GetNWInt("DisablePlayerMovement_gentoi_redrawn_stun") > CurTime() then return end
            if ent:GetNWBool("EnterPortal_redrawn") then return end
            local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("Bendy_Kill Animation 232"))
            racheljackietien_jumpscare(
                ply,
                ent,
                dur,
                function()

                    AdvancedPillSound({
                        stringe = "redrawn/bendy/Redrawn_killanim.wav",
                        soundLevel = 79
                    }, ent)

                    ent:PillAnim('kill')
                end
            )
        end
    },


    attack2 = {
        mode = "tick",
        func = function(ply, ent)
        end,
    },

    reload=function(ply,ent)
    end,
    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent)


    end
})
