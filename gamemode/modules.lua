MC = {}
MC.categories = { "Stats", "Extra-damage", "Utilities" }

local function CreateTimerInHook(timerName, timerTick, timerDuration, method)
    timer.Create(timerName, timerTick, timerDuration, method)
end

MC.ApplyVulnerability = function(ply, modId, modLv)
    local mod = MC.modules[modId]
    local dur = mod.upgrades[modLv]
    local ent = ply:GetEyeTrace().Entity
    local result = false
    local id = CurTime()
    if (IsValid(ent) && ent:IsEnemy(ply) && mod != nil && modLv != nil) then
        if (SERVER) then
            if (!ent.vulnerable) then
                sound.Play("npc/roller/mine/rmine_blip1.wav", ply:GetPos())
                sound.Play("ambient/machines/spinup.wav", ent:GetPos())
                ent.vulnerable = true
                timer.Simple(dur, function()
                    sound.Play("npc/roller/mine/rmine_blip3.wav", ply:GetPos())
                    if (IsValid(ent)) then
                        ent.vulnerable = false
                    end
                end)
                result = true
            end
        end
        if (CLIENT) then
            local lerpTime3 = dur
            local lerpStart3 = CurTime()
            local lerpVal3 = lerpStartVal3
            local scale = 0.25 // 5
            local headFx = Material("fx/broken-heart.png")
            local bodyFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "TemporaryVulnerabilityRender" .. id, function()
                local curTime = CurTime()
                local elapsed = curTime - lerpStart3
                local percentage = elapsed / lerpTime3
                
                if (IsValid(ent)) then
                    ent.vulnerable = false
                    local max = ent:OBBMaxs()
                    local min = ent:OBBMins()
                    local dist = math.abs(min.z - max.z)

                    local top = ent:OBBCenter()
                    top.z = max.z

                    local center = ent:OBBCenter()
                    lerpVal3 = Lerp(percentage, 0, dist)
                    max.z = center.z
                    local size = 16//center:Distance(max) * 2
                    local circleSize = center:Distance(max) * 2
                    local color = hex(mod.color)
                    local ticks = math.Round(dur) + 2
                    local tick = ((percentage * ticks) % ticks) * math.pi
                    color.a = math.abs(math.sin(tick)) * 255
                    
                    cam.Start3D2D( ent:LocalToWorld(top) /*+ ent:GetUp() * lerpVal3 - ent:GetUp() * dist / 2*/, Angle(0, /*360 * percentage*/LocalPlayer():GetAngles().y - 90, 90), scale )
                        surface.SetDrawColor( color )
                        surface.SetMaterial( headFx )
                        surface.DrawTexturedRect( -size / scale, -size / scale, size * 2 / scale, size * 2 / scale )
                    cam.End3D2D()
                    
                    cam.Start3D2D( ent:LocalToWorld(center) + ent:GetUp() * lerpVal3 - ent:GetUp() * dist / 2, Angle(0, 360 * percentage, 0), scale )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( bodyFx )
                        surface.DrawTexturedRect( -circleSize / scale, -circleSize / scale, circleSize * 2 / scale, circleSize * 2 / scale )
                    cam.End3D2D()
                end
            end)

            timer.Simple(dur, function()
                if (IsValid(ent)) then ent.vulnerable = false end
                hook.Remove("PostDrawOpaqueRenderables", "TemporaryVulnerabilityRender" .. id)
            end)
        end
    end
    return result
end

MC.PerformShockwave = function(ply, modId, modLv)
    local mod = MC.modules[modId]
    local result = false
    if (mod != nil && modLv != nil) then
        local range = mod.upgrades[modLv] * 50
        local delay = mod.casttime
        local pushtime = delay * 0.65
        local stomptime = 0.15
        local toGround = util.QuickTrace(ply:GetPos() + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
        local startingPos = toGround.HitPos
        local id = CurTime()
        if (SERVER) then
            //ply:SetMoveType(MOVETYPE_FLY)
            sound.Play("ambient/machines/thumper_top.wav", ply:GetPos())
            local lerpTime1 = delay
            local lerpStart1 = CurTime()
            local lerpStartVal1 = ply:GetPos()
            local lerpEndVal1 = ply:GetPos() + ply:GetUp() * 100
            local lerpVal1 = lerpStartVal1
            hook.Add("Think", "PrepareForStomp" .. id, function()
                local curTime = CurTime()
                local elapsed = curTime - lerpStart1
                local percentage = elapsed / lerpTime1

                lerpVal1 = LerpVector(percentage, lerpStartVal1, lerpEndVal1)
                ply:SetPos(lerpVal1)
            end)
            timer.Simple(delay - stomptime, function()
                hook.Remove("Think", "PrepareForStomp" .. id)
                //ply:SetMoveType(MOVETYPE_WALK)
                local lerpTime11 = stomptime
                local lerpStart11 = CurTime()
                local lerpStartVal11 = ply:GetPos()
                local lerpEndVal11 = startingPos + ply:GetUp() * 10
                local lerpVal11 = lerpStartVal11
                hook.Add("Think", "StompDescend" .. id, function()
                    //ply:SetMoveType(MOVETYPE_FLY)
                    local curTime = CurTime()
                    local elapsed = curTime - lerpStart11
                    local percentage = elapsed / lerpTime11

                    lerpVal11 = LerpVector(percentage, lerpStartVal11, lerpEndVal11)
                    ply:SetPos(lerpVal11)
                end)
                ply:SetVelocity( ply:GetUp() * -200 )
                timer.Simple(stomptime, function()
                    hook.Remove("Think", "StompDescend" .. id)
                    ply:SetMoveType(MOVETYPE_WALK)
                    sound.Play("npc/dog/car_impact1.wav", ply:GetPos())
                end)
            end)

            local d = DamageInfo()
            d:SetDamage( 2 )
            d:SetAttacker( ply )
            d:SetDamageType( DMG_DIRECT )

            timer.Simple(delay, function()
                for k, v in pairs (ents.FindInSphere(ply:GetPos(), range)) do
                    local physObj = v:GetPhysicsObject()
                    if (v:IsEnemy(ply) && IsValid(v) && IsValid(physObj)) then
                        local entIndex = v:EntIndex()
                        d:SetInflictor( v )
                        v:TakeDamageInfo( d )

                        local playerPos = ply:GetPos() - ply:GetUp() * 10
                        local direction = (v:GetPos() - playerPos):GetNormalized()
                        local lerpTime2 = pushtime
                        local lerpStart2 = CurTime()
                        local lerpStartVal2 = v:GetPos()
                        local lerpEndVal2 = v:GetPos() + direction * 300
                        local lerpVal2 = lerpStartVal2

                        local npcSafePos = v:GetPos()

                        hook.Add("Think", "PushSpecificNPC" .. entIndex .. "," .. id, function()
                            local curTime = CurTime()
                            local elapsed = curTime - lerpStart2
                            local percentage = elapsed / lerpTime2

                            lerpVal2 = LerpVector(percentage, lerpStartVal2, lerpEndVal2)
                            if (IsValid(physObj)) then
                                if (!physObj:IsPenetrating()) then
                                    npcSafePos = v:GetPos()
                                    v:SetPos(lerpVal2)
                                else
                                    v:SetPos(npcSafePos)
                                end
                            end
                        end)
		                //if (v:IsNPC()) then v:AddEntityRelationship( ply, D_LI, 99 ) end
                        timer.Simple(0.5, function()
                            hook.Remove("Think", "PushSpecificNPC" .. entIndex .. "," .. id)
                        end)
                        //timer.Simple(1, function()
		                //if (v:IsNPC()) then v:AddEntityRelationship( ply, D_HT, 99 ) end
                        //end)
                    end
                end
            end)
        end
        if (CLIENT) then
            local lerpTime3 = delay
            local lerpStart3 = CurTime()
            local lerpStartVal3 = range
            local lerpEndVal3 = 0
            local lerpVal3 = lerpStartVal3
            local scale = 0.33
            local circleFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "TemporaryRangeRender", function()
                    local curTime = CurTime()
                    local elapsed = curTime - lerpStart3
                    local percentage = elapsed / lerpTime3

                    lerpVal3 = Lerp(percentage, lerpStartVal3, lerpEndVal3)
                    
                    cam.Start3D2D( ply:GetPos() + ply:GetUp() * 1, Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, lerpVal3 / scale, Color(255,55,55,255) )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( circleFx )
                        surface.DrawTexturedRect( -lerpVal3 / scale, -lerpVal3 / scale, lerpVal3 * 2 / scale, lerpVal3 * 2 / scale )
                    cam.End3D2D()
            end)

            timer.Simple(delay, function()
                hook.Remove("PostDrawOpaqueRenderables", "TemporaryRangeRender")

                local lerpTime = pushtime
                local lerpStart = CurTime()
                local lerpStartVal = 0 //600
                local lerpEndVal = range //0
                local lerpVal = lerpStartVal
                local scale = 0.33
                hook.Add("PostDrawOpaqueRenderables", "TemporaryRangeRender2", function()
                        local curTime = CurTime()
                        local elapsed = curTime - lerpStart
                        local percentage = elapsed / lerpTime

                        lerpVal = Lerp(percentage, lerpStartVal, lerpEndVal)
                        //local color = Color(50, 50, 50)//hex(mod.color)
                        //color.a = math.min(lerpVal, 255)
                        cam.Start3D2D( startingPos + ply:GetUp() * 1, Angle(0, 0, 0), scale )
                            //surface.SetDrawColor( color )
                            //surface.SetMaterial( Material("fx/groundbreaker.png") )
                            //surface.DrawTexturedRect( -range / scale, -range / scale, range * 2 / scale, range * 2 / scale )
                            surface.SetDrawColor( hex(mod.color) )
                            surface.SetMaterial( circleFx )
                            surface.DrawTexturedRect( -lerpVal / scale, -lerpVal / scale, lerpVal * 2 / scale, lerpVal * 2 / scale )
                        cam.End3D2D()
                end)
                timer.Simple(pushtime, function()
                    hook.Remove("PostDrawOpaqueRenderables", "TemporaryRangeRender2")
                end)
            end)
        end
        result = true
    end
    return result
end

MC.PerformStomp = function(ply, modId, modLv)
    local mod = MC.modules[modId]
    local result = false
    if (mod != nil && modLv != nil) then
        local range = mod.upgrades[modLv] * 50
        local delay = mod.casttime
        local pushtime = delay * 0.65
        local stomptime = 0.15
        local toGround = util.QuickTrace(ply:GetPos() + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
        local startingPos = toGround.HitPos
        local id = CurTime()
        if (SERVER) then
            //ply:SetMoveType(MOVETYPE_FLY)
            sound.Play("ambient/machines/thumper_top.wav", ply:GetPos())
            local lerpTime1 = delay
            local lerpStart1 = CurTime()
            local lerpStartVal1 = ply:GetPos()
            local lerpEndVal1 = ply:GetPos() + ply:GetUp() * 100
            local lerpVal1 = lerpStartVal1
            hook.Add("Think", "PrepareForStomp" .. id, function()
                local curTime = CurTime()
                local elapsed = curTime - lerpStart1
                local percentage = elapsed / lerpTime1

                lerpVal1 = LerpVector(percentage, lerpStartVal1, lerpEndVal1)
                ply:SetPos(lerpVal1)
            end)
            timer.Simple(delay - stomptime, function()
                hook.Remove("Think", "PrepareForStomp" .. id)
                //ply:SetMoveType(MOVETYPE_WALK)
                local lerpTime11 = stomptime
                local lerpStart11 = CurTime()
                local lerpStartVal11 = ply:GetPos()
                local lerpEndVal11 = startingPos + ply:GetUp() * 10
                local lerpVal11 = lerpStartVal11
                hook.Add("Think", "StompDescend" .. id, function()
                    //ply:SetMoveType(MOVETYPE_FLY)
                    local curTime = CurTime()
                    local elapsed = curTime - lerpStart11
                    local percentage = elapsed / lerpTime11

                    lerpVal11 = LerpVector(percentage, lerpStartVal11, lerpEndVal11)
                    ply:SetPos(lerpVal11)
                end)
                ply:SetVelocity( ply:GetUp() * -200 )
                timer.Simple(stomptime, function()
                    hook.Remove("Think", "StompDescend" .. id)
                    ply:SetMoveType(MOVETYPE_WALK)
                    sound.Play("npc/dog/car_impact1.wav", ply:GetPos())
                end)
            end)

            local d = DamageInfo()
            d:SetDamage( 2 )
            d:SetAttacker( ply )
            d:SetDamageType( DMG_DIRECT )

            timer.Simple(delay, function()
                for k, v in pairs (ents.FindInSphere(ply:GetPos(), range)) do
                    local physObj = v:GetPhysicsObject()
                    if (v:IsEnemy(ply) && IsValid(v) && IsValid(physObj)) then
                        local entIndex = v:EntIndex()
                        d:SetInflictor( v )
                        v:TakeDamageInfo( d )

                        local playerPos = ply:GetPos() - ply:GetUp() * 10
                        local direction = (v:GetPos() - playerPos):GetNormalized()
                        local lerpTime2 = pushtime
                        local lerpStart2 = CurTime()
                        local lerpStartVal2 = v:GetPos()
                        local lerpEndVal2 = v:GetPos() + direction * 300
                        local lerpVal2 = lerpStartVal2

                        local npcSafePos = v:GetPos()

                        hook.Add("Think", "PushSpecificNPC" .. entIndex .. "," .. id, function()
                            local curTime = CurTime()
                            local elapsed = curTime - lerpStart2
                            local percentage = elapsed / lerpTime2

                            lerpVal2 = LerpVector(percentage, lerpStartVal2, lerpEndVal2)
                            if (IsValid(physObj)) then
                                if (!physObj:IsPenetrating()) then
                                    npcSafePos = v:GetPos()
                                    v:SetPos(lerpVal2)
                                else
                                    v:SetPos(npcSafePos)
                                end
                            end
                        end)
		                v:AddEntityRelationship( ply, D_LI, 99 )
                        timer.Simple(0.5, function()
                            hook.Remove("Think", "PushSpecificNPC" .. entIndex .. "," .. id)
                        end)
                        timer.Simple(1, function()
		                v:AddEntityRelationship( ply, D_HT, 99 )
                        end)
                    end
                end
            end)
        end
        if (CLIENT) then
            local lerpTime3 = delay
            local lerpStart3 = CurTime()
            local lerpStartVal3 = range
            local lerpEndVal3 = 0
            local lerpVal3 = lerpStartVal3
            local scale = 1
            local circleFx = Material("fx/magic-swirl.png")
            local groundFx = Material("fx/groundbreaker.png")
            hook.Add("PostDrawOpaqueRenderables", "TemporaryRangeRender", function()
                    local curTime = CurTime()
                    local elapsed = curTime - lerpStart3
                    local percentage = elapsed / lerpTime3

                    lerpVal3 = Lerp(percentage, lerpStartVal3, lerpEndVal3)
                    
                    cam.Start3D2D( ply:GetPos() + ply:GetUp() * 1, Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, lerpVal3 / scale, Color(255,55,55,255) )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial(  )
                        surface.DrawTexturedRect( -lerpVal3 / scale, -lerpVal3 / scale, lerpVal3 * 2 / scale, lerpVal3 * 2 / scale )
                    cam.End3D2D()
            end)

            timer.Simple(delay, function()
                hook.Remove("PostDrawOpaqueRenderables", "TemporaryRangeRender")

                local lerpTime = pushtime
                local lerpStart = CurTime()
                local lerpStartVal = 600
                local lerpEndVal = 0
                local lerpVal = lerpStartVal
                scale = 1
                hook.Add("PostDrawOpaqueRenderables", "TemporaryRangeRender2", function()
                        local curTime = CurTime()
                        local elapsed = curTime - lerpStart
                        local percentage = elapsed / lerpTime

                        lerpVal = Lerp(percentage, lerpStartVal, lerpEndVal)
                        local color = Color(50, 50, 50)//hex(mod.color)
                        color.a = math.min(lerpVal, 255)
                        cam.Start3D2D( startingPos + ply:GetUp() * 1, Angle(0, 0, 0), scale )
                            //surface.DrawCircle( 0, 0, lerpVal / scale, Color(255,55,55,255) )
                            surface.SetDrawColor( color )
                            surface.SetMaterial( groundFx )
                            surface.DrawTexturedRect( -range / scale, -range / scale, range * 2 / scale, range * 2 / scale )
                        cam.End3D2D()
                end)
                timer.Simple(pushtime, function()
                    hook.Remove("PostDrawOpaqueRenderables", "TemporaryRangeRender2")
                end)
            end)
        end
        result = true
    end
    return result
end

MC.HealingBomb = function(ply, modId, modLv, pos)
    local mod = MC.modules[modId]
    local heal = mod.upgrades[modLv]

    local result = false
    local size = 300
    //local pos = ply:GetPos()
    local time = 5
    local hitDelay = 0.5
    local hits = time / hitDelay

    local pos = pos || ply:GetPos()
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    local id = CurTime()

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local npcHeal = ply:HealthFormula() * heal / hits
            local sounds = {"ambient/levels/labs/electric_explosion1.wav", "ambient/levels/labs/electric_explosion2.wav", "ambient/levels/labs/electric_explosion3.wav", "ambient/levels/labs/electric_explosion4.wav"}
            sound.Play(table.Random(sounds), pos)
            sound.Play("npc/vort/health_charge.wav", pos)
            timer.Create("HealingSmokeSV" .. id, hitDelay, hits, function()
                for k, v in pairs (player.GetAll()) do
                    if (IsValid(v) && v:GetPos():Distance(pos) <= size && !v:IsEnemy(ply)) then
                        v:GainHealth(v:HealthFormula() * heal / hits)
                    end
                end
                for k, v in pairs (ents.FindByClass("npc_*")) do
                    if (v:IsMinion(ply) && v:GetPos():Distance(pos) <= size) then
                        local heal = v:Health() + npcHeal
                        if (heal >= v:GetMaxHealth()) then heal = v:GetMaxHealth() end
                        local healed = heal - v:Health()
			            ShowWorldText(v:LocalToWorld(v:OBBCenter()), "+"..math.Round(healed * 10).." HP", "heal")
                        v:SetHealth(heal)
                        if (v.health) then v.health = heal end
                    end
                end
            end)
        end
        if (CLIENT) then
            local mineModel = ClientsideModel( "models/healthvial.mdl", RENDERGROUP_TRANSLUCENT ) //models/props_junk/propanecanister001a.mdl
            mineModel:SetPos(pos)
            local emitter = ParticleEmitter( pos )
            local color = hex(mod.color)
            local emerge = true
            timer.Create("HealingSmoke" .. id, hitDelay, hits, function()
                local fx = Material("fx/hospital-cross.png")
                for i = 0, 2 do
                    local part = emitter:Add( fx, pos )
                    if ( part ) then
                        part:SetDieTime( 2.5 )
                        part:SetPos( pos + Vector(math.random(-size, size), math.random(-size, size), 0) )
                        part:SetColor(color.r, color.g, color.b)

                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )

                        part:SetStartSize( 10 )
                        part:SetEndSize( 15 )

                        part:SetGravity( Vector( 0, 0, -50 ) )
                        part:SetVelocity( Vector(0, 0, 100) )
                    end
                end
            end)

            
            local emergePos = pos
            local buryPos = mineModel:GetPos() - Vector(0, 0, 20)
            hook.Add("Think", "TemporaryHealingModel" .. id, function()
                local minePos = mineModel:GetPos()
                if (emerge) then
                    minePos = LerpVector(0.01, minePos, emergePos)
                else
                    minePos = LerpVector(0.01, minePos, buryPos)
                end
                mineModel:SetPos(minePos)
            end)

            local scale = 0.33
            local circleFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "TemporaryHealingRange" .. id, function()                   
                    cam.Start3D2D( pos + Vector(0, 0, 10), Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, size / scale, color )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( circleFx )
                        surface.DrawTexturedRect( -size / scale, -size / scale, size * 2 / scale, size * 2 / scale )
                    cam.End3D2D()
            end)
            timer.Simple(time, function()
                hook.Remove("PostDrawOpaqueRenderables", "TemporaryHealingRange" .. id)
                emerge = false
            end)
            timer.Simple(time * 2, function()
                hook.Remove("Think", "TemporaryHealingModel" .. id)
                mineModel:Remove()
                emitter:Finish()
            end)

        end
        result = true
    end
    return result
end

MC.PullingMine = function(ply, modId, modLv, pos)
    local result = false

    local mod = MC.modules[modId]
    local size = mod.upgrades[modLv] * 50

    local time = 5
    local hitDelay = 0.4
    local hits = time / hitDelay
    local id = CurTime()

    local pos = pos || ply:GetEyeTrace().HitPos
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            sound.Play("npc/scanner/scanner_electric2.wav", ply:GetPos())
            sound.Play("npc/vort/health_charge.wav", pos)
            hook.Add("Think", "PullingFieldSV" .. id, function()
                for k, v in pairs (ents.GetAll()) do
                    local physObj = v:GetPhysicsObject()
                    if (IsValid(v) && IsValid(physObj) && v:GetPos():Distance(pos) <= size && v:IsEnemy(ply)) then
                        local dir = (pos - v:GetPos()):GetNormalized()
                        //physObj:AddVelocity(dir * 5000)
                        v:SetVelocity(dir * (pos:Distance(v:GetPos()) * 0.5) + v:GetUp() * 5)
                    end
                end
            end)
            timer.Simple(time, function()
                hook.Remove("Think", "PullingFieldSV" .. id);
            end)
        end
        if (CLIENT) then
            local mineModel = ClientsideModel( "models/props_combine/combine_mine01.mdl", RENDERGROUP_TRANSLUCENT )
            mineModel:SetPos(pos)
            local emitter = ParticleEmitter( pos )
            local color = hex(mod.color)
            local emerge = true
            local fx = Material("fx/pounce.png")
            timer.Create("PullingFieldParticles" .. id, hitDelay, hits, function()
                for i = 0, 1 do
                    local part = emitter:Add( fx, pos )
                    if ( part ) then
                        part:SetDieTime( 2.5 )
                        part:SetPos( pos + Vector(math.random(-size, size), math.random(-size, size), 100) )
                        part:SetColor(color.r, color.g, color.b)

                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )

                        part:SetStartSize( 10 )
                        part:SetEndSize( 15 )

                        part:SetGravity( Vector( 0, 0, -50 ) )
                        part:SetVelocity( Vector(0, 0, -25) )
                    end
                end
            end)

            
            local emergePos = pos
            local buryPos = mineModel:GetPos() - Vector(0, 0, 20)
            hook.Add("Think", "TemporaryMineModel" .. id, function()
                local minePos = mineModel:GetPos()
                if (emerge) then
                    minePos = LerpVector(0.01, minePos, emergePos)
                else
                    minePos = LerpVector(0.01, minePos, buryPos)
                end
                mineModel:SetPos(minePos)
            end)

            local scale = 0.33
            local circleFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "PullingFieldView" .. id, function()                   
                    cam.Start3D2D( pos + Vector(0, 0, 10), Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, size / scale, color )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( circleFx )
                        surface.DrawTexturedRect( -size / scale, -size / scale, size * 2 / scale, size * 2 / scale )
                    cam.End3D2D()
            end)
            timer.Simple(time, function()
                hook.Remove("PostDrawOpaqueRenderables", "PullingFieldView" .. id)
                emerge = false
            end)
            timer.Simple(time * 2, function()
                hook.Remove("Think", "TemporaryMineModel" .. id)
                mineModel:Remove()
                emitter:Finish()
            end)

        end
        result = true
    end
    return result
end

MC.ThrowHarpoon = function(ply, modId, modLv)
    local result = false

    local mod = MC.modules[modId]
    local dur = mod.upgrades[modLv]

    local id = CurTime()
    local sparks = 30

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local harpoon = ply:CreateGrenade("prop_physics", "models/props_junk/harpoon002a.mdl", true)
            harpoon:SetCollisionGroup(COLLISION_GROUP_WORLD)
            local trail = util.SpriteTrail(harpoon, 0, hex(mod.color), false, 10, 1, 4, 1/(15+1)*0.5, "trails/laser.vmt")
            hook.Add("Think", "HarpoonHitCheck" .. id, function()
                if (IsValid(harpoon)) then
                    physObj = harpoon:GetPhysicsObject()
                    for k, v in pairs (ents.FindInSphere(harpoon:GetPos(), 5)) do
                        if (IsValid(v) && v:IsEnemy(ply) && IsValid(physObj)) then
                            local dmginfo = DamageInfo()
                            dmginfo:SetDamage(1)
                            dmginfo:SetAttacker(ply)
                            dmginfo:SetInflictor(v)
                            v:TakeDamageInfo(dmginfo)

			                ply:ShowEffect(harpoon:GetPos(), hex(mod.color), sparks)

                            sound.Play("weapons/crossbow/bolt_skewer1.wav", v:GetPos())
                            harpoon:SetParent(v)

                            if (!v.weakened) then
                                sound.Play("ambient/machines/spinup.wav", v:GetPos())
                                v.weakened = true
                            end
                            timer.Simple(dur, function()
                                if (IsValid(v)) then
                                    v.weakened = false
                                    sound.Play("npc/roller/mine/rmine_blip3.wav", v:GetPos())
                                end
                                if (IsValid(harpoon)) then
                                    harpoon:Remove()
                                end
                            end)
                            hook.Remove("Think", "HarpoonHitCheck" .. id)
                        end
                    end
                end
            end)

            timer.Simple(2, function()
                if (IsValid(harpoon) && !harpoon:GetParent():IsEnemy(ply)) then
                    hook.Remove("Think", "HarpoonHitCheck" .. id)
                    harpoon:Remove()
                end
            end)
        end
        result = true
    end
    return result
end

MC.ThrowExplodingHarpoon = function(ply, modId, modLv)
    local result = false

    local mod = MC.modules[modId]
    local damage = mod.upgrades[modLv] - 1

    local dur = 5
    local tick = 0.33
    local hits = dur / tick
    local id = CurTime()
    local sparks = 20
    //local singleDamage = damage / hits

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local harpoon = ply:CreateGrenade("prop_physics", "models/props_junk/harpoon002a.mdl", true)
            harpoon:SetCollisionGroup(COLLISION_GROUP_WORLD)
            local trail = util.SpriteTrail(harpoon, 0, hex(mod.color), false, 10, 1, 4, 1/(15+1)*0.5, "trails/smoke.vmt")
            hook.Add("Think", "EHarpoonHitCheck" .. id, function()
                if (IsValid(harpoon)) then
                    physObj = harpoon:GetPhysicsObject()
                    for k, v in pairs (ents.FindInSphere(harpoon:GetPos(), 5)) do
                        if (IsValid(v) && v:IsEnemy(ply) && IsValid(physObj)) then
                            local dmginfo = DamageInfo()
                            dmginfo:SetDamage(1)
                            dmginfo:SetAttacker(ply)
                            dmginfo:SetInflictor(v)
                            v:TakeDamageInfo(dmginfo)

			                ply:ShowEffect(harpoon:GetPos(), hex(mod.color), sparks)

                            v:ApplyExplosion("ExplodeEntity" .. id .. "," .. v:EntIndex(), tick, hits, ply, damage)


                            timer.Simple(dur, function()
                                if (IsValid(v) && IsValid(harpoon)) then
                                    harpoon:Remove()
                                    timer.Remove("ExplodeEntity" .. id .. "," .. v:EntIndex())
                                end
                            end)

                            sound.Play("weapons/crossbow/bolt_skewer1.wav", v:GetPos())
                            harpoon:SetParent(v)
                            hook.Remove("Think", "EHarpoonHitCheck" .. id)
                        end
                    end
                end
            end)

            timer.Simple(2, function()
                if (IsValid(harpoon) && !harpoon:GetParent():IsEnemy(ply)) then
                    hook.Remove("Think", "EHarpoonHitCheck" .. id)
                    harpoon:Remove()
                end
            end)
        end
        result = true
    end
    return result
end

MC.ThrowPoisonHarpoon = function(ply, modId, modLv)
    local result = false

    local mod = MC.modules[modId]
    local damage = mod.upgrades[modLv] - 1

    local dur = 15
    local tick = 0.5
    local hits = dur / tick
    local id = CurTime()
    local sparks = 20
    local singleDamage = damage / hits

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local harpoon = ply:CreateGrenade("prop_physics", "models/props_junk/harpoon002a.mdl", true)
            harpoon:SetCollisionGroup(COLLISION_GROUP_WORLD)
            local trail = util.SpriteTrail(harpoon, 0, hex(mod.color), false, 10, 1, 4, 1/(15+1)*0.5, "trails/smoke.vmt")
            hook.Add("Think", "PHarpoonHitCheck" .. id, function()
                if (IsValid(harpoon)) then
                    physObj = harpoon:GetPhysicsObject()
                    for k, v in pairs (ents.FindInSphere(harpoon:GetPos(), 5)) do
                        if (IsValid(v) && v:IsEnemy(ply) && IsValid(physObj)) then
                            local dmginfo = DamageInfo()
                            dmginfo:SetDamage(1)
                            dmginfo:SetAttacker(ply)
                            dmginfo:SetInflictor(v)
                            v:TakeDamageInfo(dmginfo)

			                ply:ShowEffect(harpoon:GetPos(), hex(mod.color), sparks)

                            v:ApplyPoison("DrainHealth" .. id .. "," .. v:EntIndex(), tick, hits, ply, singleDamage)

                            timer.Simple(dur, function()
                                if (IsValid(v) && IsValid(harpoon)) then
                                    harpoon:Remove()
                                    timer.Remove("DrainHealth" .. id .. "," .. v:EntIndex())
                                end
                            end)

                            sound.Play("weapons/crossbow/bolt_skewer1.wav", v:GetPos())
                            harpoon:SetParent(v)
                            hook.Remove("Think", "PHarpoonHitCheck" .. id)
                        end
                    end
                end
            end)

            timer.Simple(2, function()
                if (IsValid(harpoon) && !harpoon:GetParent():IsEnemy(ply)) then
                    hook.Remove("Think", "PHarpoonHitCheck" .. id)
                    harpoon:Remove()
                end
            end)
        end
        result = true
    end
    return result
end

MC.LaserBeam = function(ply, modId, modLv)
    local result = false

    local mod = MC.modules[modId]
    local totalDamage = mod.upgrades[modLv] - 1

    local dur = 4
    local range = 1800
    local tick = 0.065
    local hits = dur / tick
    local id = CurTime()
    local sparks = 8
    local pos = function()
        local wep = ply:GetViewModel()//ply:GetActiveWeapon()
        if (!IsValid(wep)) then wep = ply:GetActiveWeapon() end
        local startPos = ply:LocalToWorld(ply:OBBCenter()) + Vector(0, 0, 15)
        local muzzle = nil
        if (IsValid(wep)) then
            if (wep:LookupAttachment("muzzle") && wep:GetAttachment(wep:LookupAttachment("muzzle"))) then
                muzzle = wep:GetAttachment(wep:LookupAttachment("muzzle")).Pos + wep:GetAttachment(wep:LookupAttachment("muzzle")).Ang:Forward() * 0
            elseif (wep:LookupAttachment("muzzle_flash") && wep:GetAttachment(wep:LookupAttachment("muzzle_flash"))) then
                muzzle = wep:GetAttachment(wep:LookupAttachment("muzzle_flash")).Pos
            elseif (wep:LookupBone("ValveBiped.flash")) then
                muzzle = wep:LookupBone("ValveBiped.flash"):GetPos()
            elseif (wep:LookupBone("ValveBiped.weapon_bone")) then
                muzzle = wep:LookupBone("ValveBiped.weapon_bone"):GetPos()
            end
        end
        if (muzzle) then
            return muzzle
        end
        return startPos
    end
    local allEntities = ents.GetAll()
    local endPos = function(part, startPart)
        local p = ply:EyePos() * (startPart || 1) + ply:EyeAngles():Forward() * range * (part || 1)
        local trace = util.TraceLine({start = ply:EyePos(), endpos = p, filter = allEntities})
        if (trace.Hit) then p = trace.HitPos end
        return p
    end

    local burnTime = 4
    local burnDelay = 0.5
    local burnHits = burnTime / burnDelay

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            /*local oldSpeed = {walk = ply:GetWalkSpeed(), run = ply:GetRunSpeed(), jump = ply:GetJumpPower()}
            ply:SetWalkSpeed(oldSpeed.walk * 0.33)
            ply:SetRunSpeed(oldSpeed.run * 0.33)
            timer.Simple(dur, function()
                ply:SetWalkSpeed(oldSpeed.walk)
                ply:SetRunSpeed(oldSpeed.run)
            end)*/
            sound.Play("npc/vort/attack_shoot.wav", ply:GetPos())
            local filter = RecipientFilter()
            filter:AddAllPlayers()
            local sfx = CreateSound(ply, "npc/stalker/laser_burn.wav", filter)
            sfx:PlayEx(0.5, 255)
            timer.Simple(dur, function()
                sfx:Stop()
                sound.Play("weapons/airboat/airboat_gun_energy2.wav", ply:GetPos())
            end)

            timer.Create("LaserBeamHits" .. id, tick, hits, function()
                for k, v in pairs (ents.FindAlongRay(pos(), endPos())) do
                    if (IsValid(v) && v:IsEnemy(ply)) then
                        local dmginfo = DamageInfo()
                        local laserDmg = 0.1
                        if (v.burned) then laserDmg = 0 end
                        dmginfo:SetDamage(laserDmg)
                        dmginfo:SetAttacker(ply)
                        dmginfo:SetInflictor(v)
                        v:TakeDamageInfo(dmginfo)

                        v:ShowEffect(v:LocalToWorld(v:OBBCenter()) + VectorRand() * 10, hex(mod.color), sparks)
                        if (!v.burned) then
                            v.laserHit = (v.laserHit || 0) + 1
                            timer.Simple(dur, function()
                                if (IsValid(v)) then
                                    v.laserHit = (v.laserHit || 1) - 1
                                end
                            end)

                            if (v.laserHit && v.laserHit >= 4) then
                                v:ApplyFire("FireDamage" .. id .. v:EntIndex(), burnDelay, burnHits, ply, totalDamage / burnHits)
                            end
                        end
                    end
                end
            end)
        end
        if (CLIENT) then
            local lerpPos = {}
            local laserMat = Material( "trails/laser" )//Material( "cable/redlaser" )
            hook.Add("PostDrawOpaqueRenderables", "DrawLaserBeam" .. id, function()
                local parts = 20
                local dir = (endPos() - pos()):GetNormalized()
                local dist = (pos():Distance(endPos())) * 2
                local lastLerpedPos = endPos()
                for i = 1, parts do
                    if (i > 10) then break end
                    local start = pos() + dir * ((i - 1) / parts) * dist
                    local endpos = pos() + dir * (i / parts) * dist
                    lerpPos[i] = lerpPos[i] || {}
                    local sLerp = 0.125 * (1 - (i / parts))
                    local eLerp = 0.125 * (1 - ((i + 1) / parts))
                    lerpPos[i].s = Lerp(math.max(sLerp, 0.001), (lerpPos[i].s || start), start)
                    lerpPos[i].e = Lerp(math.max(eLerp, 0.001), (lerpPos[i].e || endpos), endpos)
                    
                    render.SetMaterial( laserMat )
                    render.DrawBeam( lerpPos[i].s, lerpPos[i].e, 20, 1, 1, Color( 255 * (i / parts), 255, 255, 255 ) )
                    lastLerpedPos = lerpPos[i].e
                end
            end)

            timer.Simple(dur, function()
                hook.Remove("PostDrawOpaqueRenderables", "DrawLaserBeam" .. id)
            end)
        end
        result = true
    end
    return result
end

MC.SnaringBomb = function(ply, modId, modLv, pos)
    local result = false

    local mod = MC.modules[modId]
    local time = mod.upgrades[modLv]

    local size = 300
    local hitDelay = 0.8
    local hits = time / hitDelay
    local id = CurTime()

    local pos = pos || ply:GetEyeTrace().HitPos
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local affectedNpcs = {}
            sound.Play("npc/scanner/scanner_electric2.wav", ply:GetPos())
            sound.Play("npc/vort/health_charge.wav", pos)
            hook.Add("Think", "SnaringFieldSV" .. id, function()
                for k, v in pairs (ents.GetAll()) do
                    local physObj = v:GetPhysicsObject()
                    if (IsValid(v) && IsValid(physObj) && v:GetPos():Distance(pos) <= size && v:IsEnemy(ply)) then
                        if (!v.snarePos) then
                            table.insert(affectedNpcs, v)
                            v.snarePos = v:GetPos()
			                v:ShowEffect(v:LocalToWorld(v:OBBCenter()), hex(mod.color), 3, "fx/thorns.png")
                            sound.Play("npc/barnacle/neck_snap1.wav", v:GetPos())
                        else
                            v:SetPos(v.snarePos)
                        end
                    end
                end
            end)
            timer.Simple(time, function()
                if (table.Count(affectedNpcs) >= 1) then
                    for k, v in pairs (affectedNpcs) do
                        v.snarePos = nil
                    end
                end
                hook.Remove("Think", "SnaringFieldSV" .. id);
            end)
        end
        if (CLIENT) then
            local mineModel = ClientsideModel( "models/mechanics/solid_steel/type_a_2_4.mdl", RENDERGROUP_TRANSLUCENT )
            mineModel:SetPos(pos)
            local emitter = ParticleEmitter( pos )
            local color = hex(mod.color)
            local emerge = true
            local fx = Material("fx/thorns.png")
            timer.Create("SnaringFieldParticles" .. id, hitDelay, hits, function()
                for i = 0, 1 do
                    local part = emitter:Add( fx, pos )
                    if ( part ) then
                        part:SetDieTime( 2.5 )
                        part:SetPos( pos + Vector(math.random(-size, size), math.random(-size, size), 100) )
                        part:SetColor(color.r, color.g, color.b)

                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )

                        part:SetStartSize( 20 )
                        part:SetEndSize( 25 )

                        part:SetGravity( Vector( 0, 0, -50 ) )
                        part:SetVelocity( Vector(0, 0, -25) )
                    end
                end
            end)

            
            local emergePos = pos
            local buryPos = mineModel:GetPos() - Vector(0, 0, 20)
            local angle = 0
            hook.Add("Think", "TemporaryMineModel2" .. id, function()
                local minePos = mineModel:GetPos()
                if (emerge) then
                    minePos = LerpVector(0.01, minePos, emergePos)
                else
                    minePos = LerpVector(0.01, minePos, buryPos)
                end
                mineModel:SetPos(minePos)
                angle = angle + 0.5
                mineModel:SetAngles(Angle(0, angle, 0))
            end)

            local scale = 0.33
            local circleFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "SnaringFieldView" .. id, function()                   
                    cam.Start3D2D( pos + Vector(0, 0, 10), Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, size / scale, color )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( circleFx )
                        surface.DrawTexturedRect( -size / scale, -size / scale, size * 2 / scale, size * 2 / scale )
                    cam.End3D2D()
            end)
            timer.Simple(time, function()
                hook.Remove("PostDrawOpaqueRenderables", "SnaringFieldView" .. id)
                emerge = false
            end)
            timer.Simple(time * 2, function()
                hook.Remove("Think", "TemporaryMineModel2" .. id)
                mineModel:Remove()
                emitter:Finish()
            end)

        end
        result = true
    end
    return result
end

MC.FlameExplosion = function(ply, modId, modLv, pos)
    local result = false

    local explosionDamage = 2
    local mod = MC.modules[modId]
    local totalDamage = mod.upgrades[modLv] - explosionDamage

    local size = 300
    //local pos = ply:GetPos()
    local time = 5
    local hitDelay = 0.25
    local hits = time / hitDelay
    local burnTime = 10
    local burnDelay = 0.5
    local burnHits = burnTime / burnDelay

    local pos = pos || ply:GetPos()
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    local id = CurTime()

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            local sounds = {"weapons/mortar/mortar_explode1.wav", "ambient/explosions/explode_5.wav", "ambient/explosions/explode_1.wav"}
            sound.Play(table.Random(sounds), pos)
            sound.Play("npc/scanner/cbot_discharge1.wav", pos)

            for k, v in pairs (ents.GetAll()) do
                if (IsValid(v) && v:GetPos():Distance(pos) <= size && v:IsEnemy(ply)) then
                    local dmginfo = DamageInfo()
                    dmginfo:SetDamage(explosionDamage)
                    dmginfo:SetAttacker(ply)
                    dmginfo:SetInflictor(v)
                    v:TakeDamageInfo(dmginfo)
                end
            end

            local effectdata = EffectData()
            effectdata:SetOrigin( pos )
            effectdata:SetRadius( size )
		    effectdata:SetScale( 3 )
            util.Effect( "Explosion", effectdata )

            timer.Create("BurningSmokeSV" .. id, hitDelay, hits, function()
                for k, v in pairs (ents.GetAll()) do
                    if (IsValid(v) && v:GetPos():Distance(pos) <= size && v:IsEnemy(ply) && !v.burned) then
                        v:ApplyFire("FireDamage" .. id .. v:EntIndex(), burnDelay, burnHits, ply, totalDamage / burnHits)
                    end
                end
            end)
        end
        if (CLIENT) then
            local mineModel = ClientsideModel( "models/items/grenadeammo.mdl", RENDERGROUP_TRANSLUCENT ) //models/props_junk/propanecanister001a.mdl
            mineModel:SetPos(pos)
            local emitter = ParticleEmitter( pos )
            local color = hex(mod.color)
            local emerge = true
            local fx = Material("fx/small-fire.png")
            timer.Create("BurningSmoke" .. id, hitDelay / 4, hits * 4, function()
                for i = 0, 2 do
                    local part = emitter:Add( fx, pos )
                    if ( part ) then
                        part:SetDieTime( 0.5 )
                        part:SetPos( pos + Vector(math.random(-size, size), math.random(-size, size), 0) )
                        part:SetColor(color.r * math.random(0.9, 1.5), color.g * math.random(1, 1.2), color.b * math.random(0.9, 1))

                        part:SetStartAlpha( 255 )
                        part:SetEndAlpha( 0 )

                        part:SetStartSize( 20 )
                        part:SetEndSize( 5 )

                        part:SetGravity( Vector( 0, 0, -50 ) )
                        part:SetVelocity( Vector(0, 0, 250) )
                    end
                end
            end)

            
            local emergePos = pos
            local buryPos = mineModel:GetPos() - Vector(0, 0, 20)
            hook.Add("Think", "TemporaryBombModel" .. id, function()
                local minePos = mineModel:GetPos()
                if (emerge) then
                    minePos = LerpVector(0.01, minePos, emergePos)
                else
                    minePos = LerpVector(0.01, minePos, buryPos)
                end
                mineModel:SetPos(minePos)
            end)

            local scale = 0.05
            local circleFx = Material("fx/magic-swirl.png")
            hook.Add("PostDrawOpaqueRenderables", "TemporaryFlameRange" .. id, function()                   
                    cam.Start3D2D( pos + Vector(0, 0, 10), Angle(0, 0, 0), scale )
                        //surface.DrawCircle( 0, 0, size / scale, color )
                        surface.SetDrawColor( hex(mod.color) )
                        surface.SetMaterial( circleFx )
                        surface.DrawTexturedRect( -size / scale, -size / scale, size * 2 / scale, size * 2 / scale )
                    cam.End3D2D()
            end)
            timer.Simple(time, function()
                hook.Remove("PostDrawOpaqueRenderables", "TemporaryFlameRange" .. id)
                emerge = false
            end)
            timer.Simple(time * 2, function()
                hook.Remove("Think", "TemporaryBombModel" .. id)
                mineModel:Remove()
                emitter:Finish()
            end)

        end
        result = true
    end
    return result
end

MC.ThrowSpikes = function(ply, modId, modLv)
    local result = false

    local mod = MC.modules[modId]
    local dur = mod.upgrades[modLv]

    local amount = 8
    local hitDelay = 0.5
    local hits = dur / hitDelay
    local id = CurTime()
    local thrown = 0

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            sound.Play("weapons/slam/throw.wav", ply:GetPos())
            for thrown = 0,amount do
                //thrown = thrown + 1
		        local spike = ents.Create("prop_physics")//ply:CreateGrenade("prop_physics", "models/mechanics/wheels/wheel_spike_24.mdl", true)
                spike:SetModel("models/mechanics/wheels/wheel_spike_24.mdl")
                spike:SetMaterial("phoenix_storms/dome")

                local spacing = math.random(-10, 10)//(thrown - (amount * 0.5)) * 4
                spike:SetPos(ply:LocalToWorld(ply:OBBCenter()) + ply:GetRight() * spacing + ply:GetUp() * math.random(30, 35))
                spike:SetFriction(4)
                spike:SetCollisionGroup(COLLISION_GROUP_WORLD)
                spike:SetModelScale(0.65)
                spike:Spawn()

		        local spike2 = ents.Create("prop_physics")
                spike2:SetModel("models/mechanics/wheels/wheel_spike_24.mdl")
                spike2:SetMaterial("phoenix_storms/dome")
                spike2:SetPos(spike:GetPos())
                spike2:SetAngles(spike:GetAngles() + Angle(0, 0, 90))
                spike2:SetParent(spike)
                spike2:SetModelScale(0.65)
                spike2:SetCollisionGroup(COLLISION_GROUP_WORLD)

                spike:PhysWake()
                local phys = spike:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(Angle(ply:EyeAngles().p, ply:EyeAngles().y - spacing, 0):Forward() * math.random(400, 650))
                end

                timer.Simple(thrown * 0.05, function()
                timer.Create("HurtOnSpikes" .. id .. "," .. thrown, hitDelay, 0, function()
                    if (IsValid(spike)) then
                        for k, v in pairs (ents.FindInSphere(spike:GetPos(), 50)) do
                            if (IsValid(v) && v:IsEnemy(ply)) then
                                local dmginfo = DamageInfo()
                                dmginfo:SetDamage(1)
                                dmginfo:SetAttacker(ply)
                                dmginfo:SetInflictor(v)
                                v:TakeDamageInfo(dmginfo)

                                local fxPos = spike:LocalToWorld(spike:OBBCenter()) + Vector(0, 0, 20)
			                    ply:ShowEffect(fxPos, Color(255, 50, 50, 150), 1)
                            end
                        end
                    end
                end)
                end)
                timer.Simple(dur, function()
                    spike:Remove()
                    timer.Remove("HurtOnSpikes".. id .. "," .. thrown)
                end)
            end
        end
        result = true
    end
    return result
end

MC.ProtectionField = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local duration = mod.upgrades[modLv]
    local id = CurTime()

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply.shield = true
            timer.Simple(duration, function() ply.shield = false end)
        end
        if (CLIENT) then
            //models/props_combine/combine_barricade_short01a.mdl
            local angle = 0
            local amount = 3
            local height = -40
            for index = 0, amount do
                local shieldModel = ClientsideModel( "models/props_debris/metal_panelchunk01d.mdl", RENDERGROUP_TRANSLUCENT ) //models/props_junk/propanecanister001a.mdl
                shieldModel:SetPos(ply:GetPos() - Vector(0, 0, 140))
                shieldModel:SetColor( hex(mod.color) )
			    shieldModel:SetModelScale(0.65)
                hook.Add("Think", "TemporaryShieldMovement" .. id .. "," .. index, function()
                    angle = angle + 0.1
                    local angles = Angle(0, angle + index * 360 / amount, 0)
                    local followPos = ply:LocalToWorld(ply:OBBCenter()) + angles:Forward() * 50 + ply:GetUp() * height
                    local lerpPos = Lerp(0.05, shieldModel:GetPos(), followPos)
                    if (lerpPos:Distance(followPos) >= 200) then lerpPos = followPos end
                    shieldModel:SetAngles(angles)
                    shieldModel:SetPos(lerpPos)
                end)
                timer.Simple(duration, function()
                    height = -140
                end)
                timer.Simple(duration + 0.5, function()
                    hook.Remove("Think", "TemporaryShieldMovement" .. id .. "," .. index)
                    shieldModel:Remove()
                end)
            end
        end
        result = true
    end
    return result
end

//TODO: test eyeangles online
MC.ReflectiveField = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local duration = mod.upgrades[modLv]
    local id = CurTime()

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply.reflect = true
            timer.Simple(duration, function() ply.reflect = false end)
        end
        if (CLIENT) then
            //models/props_combine/combine_barricade_short01a.mdl
            local height = 55
            local shieldModel = ClientsideModel( "models/props_combine/combine_barricade_short01a.mdl", RENDERGROUP_TRANSLUCENT ) //models/props_junk/propanecanister001a.mdl
            shieldModel:SetPos(ply:GetPos() - Vector(0, 0, 140))
            shieldModel:SetColor( hex(mod.color) )
            shieldModel:SetModelScale(0.65)
            hook.Add("Think", "TemporaryShieldMovement" .. id, function()
                local angles = Angle(0, ply:EyeAngles().y, 0)
                local base = ply:GetPos()
                local followPos = base + angles:Forward() * 40 + Vector(0, 0, height)
                local lerpPos = Lerp(0.08, shieldModel:GetPos(), followPos)
                if (lerpPos:Distance(followPos) >= 200) then lerpPos = followPos end
                shieldModel:SetAngles(angles)
                shieldModel:SetPos(lerpPos)
            end)
            timer.Simple(duration, function()
                height = -140
            end)
            timer.Simple(duration + 0.5, function()
                hook.Remove("Think", "TemporaryShieldMovement" .. id)
                shieldModel:Remove()
            end)
        end
        result = true
    end
    return result
end

MC.AbsorbingField = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local duration = mod.upgrades[modLv]
    local id = CurTime()

    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply.absorb = true
            timer.Simple(duration, function() ply.absorb = false end)
        end
        if (CLIENT) then
            local height = 55
            local shieldModel = ClientsideModel( "models/props_combine/combine_barricade_short01a.mdl", RENDERGROUP_TRANSLUCENT ) //models/props_junk/propanecanister001a.mdl
            shieldModel:SetMaterial("phoenix_storms/dome")
            shieldModel:SetPos(ply:GetPos() - Vector(0, 0, 140))
            shieldModel:SetColor( hex(mod.color) )
            shieldModel:SetModelScale(0.65)
            hook.Add("Think", "TemporaryShieldMovement2" .. id, function()
                //local angles = Angle(0, ply:GetAngles().y, 0)
                local angles = Angle(0, ply:EyeAngles().y, 0)
                local base = ply:GetPos()
                local followPos = base + angles:Forward() * 40 + Vector(0, 0, height)
                local lerpPos = Lerp(0.08, shieldModel:GetPos(), followPos)
                if (lerpPos:Distance(followPos) >= 200) then lerpPos = followPos end
                shieldModel:SetAngles(angles)
                shieldModel:SetPos(lerpPos)
            end)
            timer.Simple(duration, function()
                height = -140
            end)
            timer.Simple(duration + 0.5, function()
                hook.Remove("Think", "TemporaryShieldMovement2" .. id)
                shieldModel:Remove()
            end)
        end
        result = true
    end
    return result
end

MC.LongJump = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local strength = mod.upgrades[modLv] * 0.5
    local dur = 1
    local tick = 0.5
    local hits = dur / tick
    local curTime = CurTime()
    local sparks = 20
    local canCheck = false
    if (mod != nil && modLv != nil && (!ply:Crouching() || !ply:OnGround()) && ply:GetMoveType() != MOVETYPE_LADDER) then
        if (SERVER) then
            ply:ShowEffect(ply:LocalToWorld(ply:OBBCenter()) + Vector(0, 0, 20), hex(mod.color), sparks)

            sound.Play("weapons/crossbow/bolt_fly4.wav", ply:GetPos())
            ply:SetMoveType(MOVETYPE_FLYGRAVITY)
            ply:SetVelocity(ply:EyeAngles():Forward() * 400 * strength)
            local physObj = ply:GetPhysicsObject()
            local startPos = ply:GetPos()
            local safePos = ply:GetPos()
            local safeCheck = 0

            local landFunc = function()
                ply:ShowEffect(ply:LocalToWorld(ply:OBBCenter()) + Vector(0, 0, 20), hex(mod.color), sparks / 2)
                ply:SetMoveType(MOVETYPE_WALK)
                sound.Play("weapons/crossbow/hit1.wav", ply:GetPos())
                sound.Play("npc/antlion/land1.wav", ply:GetPos())
                hook.Remove("Think", "PlayerGroundCheck" .. ply:EntIndex())
            end

            hook.Add("Think", "PlayerGroundCheck" .. ply:EntIndex(), function()
                if (!IsValid(ply)) then
                    return
                end

                local percent = math.Clamp((CurTime() - curTime) / dur, 0, 1)
                local lerpValue = Lerp(percent, 3 + strength, 0)
                
                if (IsValid(physObj)) then
                    if (!physObj:IsPenetrating()) then
                        if (safeCheck >= 3) then safePos = ply:GetPos() end
                        ply:SetPos(ply:GetPos() + ply:GetUp() * lerpValue)
                        safeCheck = safeCheck + 1
                    else
                        ply:SetPos(safePos)
                        safeCheck = 0
                        landFunc()
                    end
                end

                if (!ply:OnGround()) then canCheck = true end

                if (canCheck && ply:OnGround()) then
                    landFunc()
                end
            end)

            timer.Simple(1.5, function()
                if (IsValid(ply) && IsValid(physObj) && physObj:IsPenetrating()) then
                    ply:SetPos(startPos)
                end
            end)
        end
        result = true
    end
    return result
end

MC.Dash = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local dur = mod.upgrades[modLv]
    local tick = 0.5
    local hits = dur / tick
    local curTime = CurTime()
    local sparks = 20
    local canCheck = false
    if (mod != nil && modLv != nil && (!ply:Crouching() || !ply:OnGround()) && ply:GetMoveType() != MOVETYPE_LADDER) then
        if (SERVER) then
            ply:ShowEffect(ply:LocalToWorld(ply:OBBCenter()) + Vector(0, 0, 20), hex(mod.color), sparks)

            sound.Play("weapons/slam/throw.wav", ply:GetPos())
            local physObj = ply:GetPhysicsObject()
            local safePos = ply:GetPos()
            local safeCheck = 0
            ply.immortal = true

            local dir = ply:GetVelocity():GetNormalized() + ply:GetUp() * 0.15

            local endDash = function()
                if (IsValid(ply)) then
                    ply.immortal = false
                    sound.Play("ambient/machines/thumper_hit.wav", ply:GetPos())
                    hook.Remove("Think", "PlayerDash" .. ply:EntIndex())
                end
            end

            hook.Add("Think", "PlayerDash" .. ply:EntIndex(), function()
                if (!IsValid(ply)) then
                    return
                end

                local percent = math.Clamp((CurTime() - curTime) / dur, 0, 1)
                local lerpValue = Lerp(percent, 12, 5)
                
                if (IsValid(physObj)) then
                    if (!physObj:IsPenetrating()) then
                        if (safeCheck >= 2) then safePos = ply:GetPos() end
                        ply:SetPos(ply:GetPos() + dir * lerpValue)
                        safeCheck = safeCheck + 1
                    else
                        ply:SetPos(safePos)
                        safeCheck = 0
                        endDash()
                    end
                end
            end)

            timer.Simple(dur, endDash)
        end
        result = true
    end
    return result
end

MC.JetpackThrust = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local sparks = 20
    local pos = ply:GetPos()
    if (mod != nil && modLv != nil && ply:GetMoveType() != MOVETYPE_LADDER) then
        if (SERVER) then
            ply:ShowEffect(ply:GetPos(), hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            ply:SetMoveType(MOVETYPE_FLYGRAVITY)
            ply:SetVelocity(ply:GetUp() * 45000 * pwr)
            timer.Simple(0.025, function()
                ply:SetMoveType(MOVETYPE_WALK)
            end)

            local effectdata = EffectData()
            effectdata:SetOrigin( pos )
            util.Effect( "MuzzleFlash", effectdata )
        end
        result = true
    end
    return result
end

MC.DeployTurret = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local health = 120
    local sparks = 50
    
    local pos = ply:GetPos() + ply:GetForward() * 60
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply:ShowEffect(pos, hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            local turret = ents.Create("npc_turret_floor")
			turret:SetPos(pos)
			turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
            turret:Spawn()
            turret.health = health
            turret:SetHealth(health)
            turret:SetMaxHealth(health)
            turret.minion = true
            turret.owner = ply
            turret.damage = pwr
            turret.level = modLv
			turret:Fire("StartPatrolling")
			turret:Fire("SetReadinessHigh")
			turret:SetNPCState(NPC_STATE_COMBAT)
			turret:Activate()
            /*local physObj = turret:GetPhysicsObject()
            if (IsValid(physObj)) then
                physObj:SetMass(physObj:GetMass() * 3)
            end*/
            turret:SetMoveType(MOVETYPE_NONE)

            for _, v in pairs (NPCs) do
                turret:AddRelationship(v.npc .. " D_HT 99")
            end

            local entIndex = turret:EntIndex()

            hook.Add("Think", "TurretThink" .. entIndex, function()
                if (IsValid(turret)) then
                    if (turret.health) then turret:SetHealth(turret.health) end
                    if (turret:Health() <= 0) then
                        local effectdata = EffectData()
                        effectdata:SetOrigin( turret:GetPos() )
                        effectdata:SetRadius( 50 )
                        effectdata:SetScale( 1 )
                        util.Effect( "Explosion", effectdata )
                        turret:Remove()
                    end
                else
                    hook.Remove("Think", "TurretThink" .. entIndex)
                end
            end)
            
            timer.Create("TurretPlayerCheck" .. entIndex, 1, 0, function()
                if (!IsValid(turret) || !IsValid(ply)) then
                    timer.Destroy("TurretPlayerCheck" .. entIndex)
                else
                    for _, v in pairs (player.GetAll()) do
                        if (pvpmode >= 1 && v != ply) then
                            turret:AddEntityRelationship(v, D_HT, 99)
                        else
                            turret:AddEntityRelationship(v, D_LI, 99)
                        end
                    end
                    for _, v in pairs (ents.FindByClass("npc_*")) do
                        if (v.minion) then
                            turret:AddEntityRelationship(v, D_LI, 99)
                        else
                            turret:AddEntityRelationship(v, D_HT, 99)
                        end
                    end
                end
            end)
        end
        result = true
    end
    return result
end

MC.DeployRollermine = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local health = 70
    local sparks = 50
    
    local pos = ply:GetPos() + ply:GetForward() * 60
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply:ShowEffect(pos, hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            local turret = ents.Create("npc_rollermine")
			turret:SetPos(pos)
			turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
            turret:Spawn()
            turret.health = health
            turret:SetHealth(health)
            turret:SetMaxHealth(health)
            turret.minion = true
            turret.owner = ply
            turret.damage = pwr
            turret.level = modLv
			turret:Fire("StartPatrolling")
			turret:Fire("SetReadinessHigh")
			turret:SetNPCState(NPC_STATE_COMBAT)
			turret:Activate()
            /*local physObj = turret:GetPhysicsObject()
            if (IsValid(physObj)) then
                physObj:SetMass(physObj:GetMass() * 3)
            end*/
            //turret:SetMoveType(MOVETYPE_NONE)

            for _, v in pairs (NPCs) do
                turret:AddRelationship(v.npc .. " D_HT 99")
            end

            local entIndex = turret:EntIndex()

            hook.Add("Think", "RollermineThink" .. entIndex, function()
                if (IsValid(turret)) then
                    if (turret.health) then turret:SetHealth(turret.health) end
                    if (turret:Health() <= 0) then
                        local effectdata = EffectData()
                        effectdata:SetOrigin( turret:GetPos() )
                        effectdata:SetRadius( 50 )
                        effectdata:SetScale( 1 )
                        util.Effect( "Explosion", effectdata )
                        turret:Remove()
                    end
                else
                    hook.Remove("Think", "RollermineThink" .. entIndex)
                end
            end)
            
            timer.Create("RollerminePlayerCheck" .. entIndex, 1, 0, function()
                if (!IsValid(turret) || !IsValid(ply)) then
                    timer.Destroy("RollerminePlayerCheck" .. entIndex)
                else
                    for _, v in pairs (player.GetAll()) do
                        if (pvpmode >= 1 && v != ply) then
                            turret:AddEntityRelationship(v, D_HT, 99)
                        else
                            turret:AddEntityRelationship(v, D_LI, 99)
                        end
                    end
                    for _, v in pairs (ents.FindByClass("npc_*")) do
                        if (v.minion) then
                            turret:AddEntityRelationship(v, D_LI, 99)
                        else
                            turret:AddEntityRelationship(v, D_HT, 99)
                        end
                    end
                end
            end)
        end
        result = true
    end
    return result
end

MC.DeployRebel = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local health = 200
    local weapon = "ai_weapon_smg1"
    local sparks = 50
    
    local pos = ply:GetPos() + ply:GetForward() * 60
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply:ShowEffect(pos, hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            local turret = ents.Create("npc_citizen")
			turret:SetPos(pos)
			turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
			turret:SetKeyValue("additionalequipment", weapon)
            turret:Spawn()
            //turret.health = health
            turret:SetHealth(health)
            turret:SetMaxHealth(health)
            turret.minion = true
            turret.owner = ply
            turret.damage = pwr
            turret.level = modLv
			turret:Give(weapon)
			turret:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_GOOD)
			turret:Fire("StartPatrolling")
			turret:Fire("SetReadinessHigh")
			turret:SetNPCState(NPC_STATE_COMBAT)
			turret:Activate()
            
            for _, v in pairs (NPCs) do
                turret:AddRelationship(v.npc .. " D_HT 99")
            end

            local entIndex = turret:EntIndex()
            timer.Create("CitizenPlayerCheck" .. entIndex, 1, 0, function()
                if (!IsValid(turret) || !IsValid(ply)) then
                    timer.Destroy("CitizenPlayerCheck" .. entIndex)
                else
                    for _, v in pairs (player.GetAll()) do
                        if (pvpmode >= 1 && v != ply) then
                            turret:AddEntityRelationship(v, D_HT, 99)
                        else
                            turret:AddEntityRelationship(v, D_LI, 99)
                        end
                    end
                    for _, v in pairs (ents.FindByClass("npc_*")) do
                        if (v.minion) then
                            turret:AddEntityRelationship(v, D_LI, 99)
                        else
                            turret:AddEntityRelationship(v, D_HT, 99)
                        end
                    end
                end
            end)
        end
        result = true
    end
    return result
end

MC.DeployManhack = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local health = 50
    local sparks = 50
    
    local pos = ply:GetPos() + ply:GetForward() * 60
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply:ShowEffect(pos, hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            local turret = ents.Create("npc_manhack")
			turret:SetPos(pos)
			turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
            turret:Spawn()
            //turret.health = health
            turret:SetHealth(health)
            turret:SetMaxHealth(health)
            turret.minion = true
            turret.owner = ply
            turret.damage = pwr
            turret.level = modLv
			turret:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_GOOD)
			turret:Fire("StartPatrolling")
			turret:Fire("SetReadinessHigh")
			turret:SetNPCState(NPC_STATE_COMBAT)
			turret:Activate()
            
            for _, v in pairs (NPCs) do
                turret:AddRelationship(v.npc .. " D_HT 99")
            end

            local entIndex = turret:EntIndex()
            timer.Create("ManhackPlayerCheck" .. entIndex, 1, 0, function()
                if (!IsValid(turret) || !IsValid(ply)) then
                    timer.Destroy("ManhackPlayerCheck" .. entIndex)
                else
                    for _, v in pairs (player.GetAll()) do
                        if (pvpmode >= 1 && v != ply) then
                            turret:AddEntityRelationship(v, D_HT, 99)
                        else
                            turret:AddEntityRelationship(v, D_LI, 99)
                        end
                    end
                    for _, v in pairs (ents.FindByClass("npc_*")) do
                        if (v.minion) then
                            turret:AddEntityRelationship(v, D_LI, 99)
                        else
                            turret:AddEntityRelationship(v, D_HT, 99)
                        end
                    end
                end
            end)
        end
        result = true
    end
    return result
end

MC.DeployVortigaunt = function(ply, modId, modLv)
    local result = false
    local mod = MC.modules[modId]
    local pwr = mod.upgrades[modLv]
    local id = CurTime()
    local health = 140
    local sparks = 50
    
    local pos = ply:GetPos() + ply:GetForward() * 60
    local toGround = util.QuickTrace(pos + ply:GetUp() * 10, ply:GetUp() * -1000, ply)
    pos = toGround.HitPos
    if (mod != nil && modLv != nil) then
        if (SERVER) then
            ply:ShowEffect(pos, hex(mod.color), sparks)

            sound.Play("weapons/grenade_launcher1.wav", pos)
            local turret = ents.Create("npc_vortigaunt")
			turret:SetPos(pos)
			turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
            turret:Spawn()
            //turret.health = health
            turret:SetHealth(health)
            turret:SetMaxHealth(health)
            turret.minion = true
            turret.owner = ply
            turret.damage = pwr
            turret.level = modLv
			turret:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_GOOD)
			turret:Fire("StartPatrolling")
			turret:Fire("SetReadinessHigh")
			turret:SetNPCState(NPC_STATE_COMBAT)
			turret:Activate()
            
            for _, v in pairs (NPCs) do
                turret:AddRelationship(v.npc .. " D_HT 99")
            end

            local entIndex = turret:EntIndex()
            timer.Create("VortigauntPlayerCheck" .. entIndex, 1, 0, function()
                if (!IsValid(turret) || !IsValid(ply)) then
                    timer.Destroy("VortigauntPlayerCheck" .. entIndex)
                else
                    for _, v in pairs (player.GetAll()) do
                        if (pvpmode >= 1 && v != ply) then
                            turret:AddEntityRelationship(v, D_HT, 99)
                        else
                            turret:AddEntityRelationship(v, D_LI, 99)
                        end
                    end
                    for _, v in pairs (ents.FindByClass("npc_*")) do
                        if (v.minion) then
                            turret:AddEntityRelationship(v, D_LI, 99)
                        else
                            turret:AddEntityRelationship(v, D_HT, 99)
                        end
                    end
                end
            end)
        end
        result = true
    end
    return result
end

MC.modulesByName = {
    increasedAux = 1,
    increasedHp = 2,
    increasedRangedDmg = 3,
    increasedMeleeDmg = 4,
    increasedClipSize = 5,
    explodingEnemies = 6,
    criticalHits = 7,
    lifeSteal = 8
}

MC.modules = {
    {
        name = "Increased AUX",
        category = "Core enhancements",
        description = "Increases your <b>total AUX</b> energy and its <b>regeneration</b> capabilities.",
        type = "Passive",
        upgrade = "AUX",
        upgrades = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100},
        parseUpgrade = function(value) return (value) .. "" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "battery-plus",
        color = "#F4F1BB",
        grenade = false,
        execute = nil
    },
    {
        name = "Increased Health",
        category = "Core enhancements",
        description = "Increases your <b>total Health</b> and the total amount of <b>Health healed</b> from any healing module.",
        type = "Passive",
        upgrade = "Health",
        upgrades = {15, 30, 45, 60, 75, 90, 105, 130, 145, 160},
        parseUpgrade = function(value) return (value) .. "" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "health-increase",
        color = "#ED6A5A",
        grenade = false,
        execute = nil
    },
    {
        name = "Increased Bullet Dmg",
        category = "Core enhancements",
        description = "Increases <b>damage</b> dealt with <b>bullets-based weapons</b>.",
        type = "Passive",
        upgrade = "Damage",
        upgrades = {0.035, 0.07, 0.105, 0.14, 0.175, 0.21, 0.245, 0.28, 0.315, 0.35},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "supersonic-bullet",
        color = "#F5BB00",
        grenade = false,
        execute = nil
    },
    {
        name = "Increased Melee Dmg",
        category = "Core enhancements",
        description = "Increases <b>damage</b> dealt with <b>melee weapons</b>.",
        type = "Passive",
        upgrade = "Damage",
        upgrades = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "crowbar",
        color = "#DB663D",
        grenade = false,
        execute = nil
    },
    {
        name = "Increased Clip Size",
        category = "Core enhancements",
        description = "Increases <b>clip size</b> of all <b>ranged weapons</b>.",
        type = "Passive",
        upgrade = "Damage",
        upgrades = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "bullets",
        color = "#C6C4C4",
        grenade = false,
        execute = nil
    },
    {
        name = "Exploding enemies",
        category = "Extra-damage",
        description = "Enemies have a <b>chance<b> of <b>exploding</b> upon death, dealing <b>85 AOE damage</b>. \n<i>Chance is based on module's level.",
        type = "Passive",
        upgrade = "Chance",
        upgrades = {0.08, 0.12, 0.16, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.5},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 2,
        icon = "bright-explosion",
        color = "#DDB77F",
        grenade = false,
        execute = nil
    },
    {
        name = "Critical hits",
        category = "Extra-damage",
        description = "Bullets have a <b>chance</b> of hitting <b>critical</b> spots on the enemy, dealing <b>bonus damage</b>. \n<i>Chance is based on module's level",
        type = "Passive",
        upgrade = "Chance",
        upgrades = {0.02, 0.04, 0.06, 0.09, 0.12, 0.15, 0.20, 0.25, 0.3, 0.35},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 1,
        icon = "targeting",
        color = "#F67A2F",
        grenade = false,
        execute = nil
    },
    {
        name = "Melee Lifesteal",
        category = "Utilities",
        description = "Melee attacks <b>heal</b> you a percentage of the <b>damage dealt</b>. \n<i>Chance is based on module's level",
        type = "Passive",
        upgrade = "Lifesteal",
        upgrades = {0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.12, 0.14, 0.16},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 0,
        cooldown = 0,
        casttime = 0,
        cost = 4,
        icon = "fangs",
        color = "#990D32",
        grenade = false,
        execute = nil
    },
    {
        name = "Shockwave",
        category = "Utilities",
        description = "Perform a powerful shockwave and <b>stuns</b> and <b>pushes away</b> all nearby enemies. \n<i>Area is based on module's level.",
        type = "Active - Area",
        upgrade = "Area",
        upgrades = {5.6, 6, 6.4, 6.8, 7.2, 7.6, 8, 8.4, 8.8, 9.2},
        parseUpgrade = function(value) return (value) .. "m" end,
        drain = 30,
        cooldown = 5,
        casttime = 0.5,
        cost = 1,
        icon = "quake-stomp",
        color = "#DDAD92",
        grenade = false,
        execute = MC.PerformShockwave
    },
    {
        name = "Fire Bomb",
        category = "Extra-damage",
        description = "Throw a Flaming Bomb which explodes creating an area of flames that <b>lasts 5 seconds</b> and inflicts <b>burn status</b> to all nearby enemies, dealing damage over <b>10 seconds</b>. \n<i>Total damage is based on module's level.</i>",
        type = "Active - AOE",
        upgrade = "Damage",
        upgrades = {25, 28, 31, 34, 37, 40, 44, 48, 52, 56},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 15,
        casttime = 0,
        cost = 5,
        icon = "molotov",
        color = "#E4572E",
        grenade = "models/items/grenadeammo.mdl",
        execute = MC.FlameExplosion
    },
    {
        name = "Laser Beam",
        category = "Extra-damage",
        description = "Shoot a <b>Laser Beam</b> that lasts <b>4 seconds</b>, inflicting <b>burn status</b> to all enemies in its way for <b>8 seconds</b>. \n<i>Total damage is based on module's level.</i>",
        type = "Active - AOE",
        upgrade = "Damage",
        upgrades = {20, 22, 24, 26, 29, 32, 35, 38, 41, 45},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 40,
        cooldown = 13,
        casttime = 0,
        cost = 3,
        icon = "ion-cannon-blast",
        color = "#DEC0C0",
        grenade = false,
        execute = MC.LaserBeam
    },
    {
        name = "Vulnerability",
        category = "Extra-damage",
        description = "Render the selected target <b>vulnerable</b>, taking <b>25% more damage</b> for a short span of time. \n<i>Duration is based on module's level.",
        type = "Active - Target",
        upgrade = "Duration",
        upgrades = {1, 1.2, 1.4, 1.6, 1.8, 2.1, 2.4, 2.7, 3, 3.5},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 40,
        cooldown = 10,
        casttime = 0,
        cost = 2,
        icon = "broken-heart",
        color = "#E80005",//"#97443A",
        grenade = false,
        execute = MC.ApplyVulnerability
    },
    {
        name = "Healing Bomb",
        category = "Utilities",
        description = "Throw a healing capsule to the ground. Upon impact, creates a large area which <b>refills a certain amount of Health</b> to all nearby allies within <b>5 seconds</b>. \n<i>Health healed is based on module's level.",
        type = "Active - AOE",
        upgrade = "Duration",
        upgrades = {0.25, 0.28, 0.31, 0.34, 0.38, 0.42, 0.46, 0.5, 0.55, 0.6},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 90,
        cooldown = 20,
        casttime = 0,
        cost = 3,
        icon = "health-capsule",
        color = "#99BEC8",
        grenade = "models/healthvial.mdl",
        execute = MC.HealingBomb
    },
    {
        name = "Snare Bomb",
        category = "Utilities",
        description = "Throw a slowing bomb to the ground. Upon impact, creates a large area which <b>snares</b> all nearby enemies. \n<i>Duration is based on module's level.",
        type = "Active - AOE (W.I.P.)",
        upgrade = "Duration",
        upgrades = {3, 3.4, 3.8, 4.2, 4.6, 5, 5.5, 6, 6.5, 7},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 40,
        cooldown = 15,
        casttime = 0,
        cost = 3,
        icon = "wolf-trap",
        color = "#566B34",
        grenade = "models/maxofs2d/hover_basic.mdl",
        execute = MC.SnaringBomb
    },
    {
        name = "Pulling Mine",
        category = "Utilities",
        description = "Throw a pulling mine to the ground. Upon activation, creates a large area which <b>pulls all nearby enemies</b> for <b>5 seconds</b>. \n<i>Area of effect is based on module's level.",
        type = "Active - AOE",
        upgrade = "Area",
        upgrades = {6, 6.2, 6.4, 6.6, 6.9, 7.2, 7.5, 8, 8.5, 9},
        parseUpgrade = function(value) return (value) .. "m" end,
        drain = 40,
        cooldown = 15,
        casttime = 0,
        cost = 3,
        icon = "land-mine",
        color = "#47120F",
        grenade = "models/props_combine/combine_mine01.mdl",
        execute = MC.PullingMine
    },
    {
        name = "Spikes",
        category = "Extra-damage",
        description = "Throw 8 spikes on the ground, dealing <b>10 damage</b> to all nearby enemies. \n<i>Spikes' duration is based on module's level.",
        type = "Active - AOE",
        upgrade = "Duration",
        upgrades = {10, 11, 12, 13, 14, 15, 16.5, 18, 19.5, 21},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 30,
        cooldown = 12,
        casttime = 0,
        cost = 2,
        icon = "caltrops",
        color = "#484242",
        grenade = false,
        execute = MC.ThrowSpikes
    },
    {
        name = "Poison Harpoon",
        category = "Extra-damage",
        description = "Throw a poisoned harpoon which <b>inflicts poison</b> on hit, dealing damage over <b>15 seconds</b>. \nPoison inflicted <b>spreads</b> across enemies. \n<i>Total damage is based on module's level.</i>",
        type = "Active - Target",
        upgrade = "Damage",
        upgrades = {25, 28, 31, 34, 37, 40, 45, 50, 55, 60},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 18,
        casttime = 0,
        cost = 5,
        icon = "chemical-arrow",
        color = "#9BC53D",
        grenade = false,
        execute = MC.ThrowPoisonHarpoon
    },
    {
        name = "Exploding Harpoon",
        category = "Extra-damage",
        description = "Throw an exploding harpoon which <b>explodes</b> after <b>5 seconds</b> dealing <b>AOE damage</b>. <i>\nDamage is based on module's level.</i>",
        type = "Active - Target",
        upgrade = "Damage",
        upgrades = {20, 23, 26, 29, 32, 34, 38, 42, 46, 50},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 16,
        casttime = 0,
        cost = 3,
        icon = "fast-arrow",
        color = "#621708",
        grenade = false,
        execute = MC.ThrowExplodingHarpoon
    },
    {
        name = "Weakening Harpoon",
        category = "Utilities",
        description = "Throw a weakening harpoon which <b>decreases</b> the <b>damage output</b> by <b>50%</b> of the victim for a few seconds. <i>\nDuration is based on module's level.</i>",
        type = "Active - Target",
        upgrade = "Duration",
        upgrades = {10, 11, 12, 13, 14, 16, 18, 20, 22, 25},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 40,
        cooldown = 20,
        casttime = 0,
        cost = 4,
        icon = "broadhead-arrow",
        color = "#C5EFCB",
        grenade = false,
        execute = MC.ThrowHarpoon
    },
    {
        name = "Protective field",
        category = "Defense",
        description = "Activate a protective field around yourself that <b>reduces damage taken</b> to <b>50%</b> for a couple of seconds. \n<i>Duration is based on module's level.",
        type = "Active - Self",
        upgrade = "Duration",
        upgrades = {10, 11, 12, 13, 14, 15.2, 16.4, 17.6, 18.8, 20},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 40,
        cooldown = 35,
        casttime = 0,
        cost = 3,
        icon = "bell-shield",
        color = "#A4C9AF",
        grenade = false,
        execute = MC.ProtectionField
    },
    {
        name = "Reflective shield",
        category = "Defense",
        description = "Activate a reflective shield in front yourself that <b>reflects 100%</b> of <b>the damage taken</b> for a short amount of time. \n<i>Duration is based on module's level.",
        type = "Active - Self",
        upgrade = "Duration",
        upgrades = {1.2, 1.4, 1.6, 1.8, 2, 2.2, 2.4, 2.6, 2.8, 3},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 30,
        cooldown = 8,
        casttime = 0,
        cost = 1,
        icon = "shield-reflect",
        color = "#77949D",
        grenade = false,
        execute = MC.ReflectiveField
    },
    {
        name = "Absorbing shield",
        category = "Defense",
        description = "Activate an abosrbing shield in front yourself that <b>turns 100%</b> of <b>the damage taken</b> into <b>health</b> for a short amount of time. \n<i>Duration is based on module's level.",
        type = "Active - Self",
        upgrade = "Duration",
        upgrades = {1.2, 1.4, 1.6, 1.8, 2, 2.2, 2.4, 2.6, 2.8, 3},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 35,
        cooldown = 8,
        casttime = 0,
        cost = 2,
        icon = "rosa-shield",
        color = "#77949D",
        grenade = false,
        execute = MC.AbsorbingField
    },
    {
        name = "Long Jump",
        category = "Mobility",
        description = "<b>Propel yourself</b> forward skipping a decent amount of ground. \n<i>Jump length is based on module's level.",
        type = "Active - Self",
        upgrade = "Length",
        upgrades = {3, 3.2, 3.4, 3.6, 3.8, 4, 4.3, 4.5, 4.7, 5},
        parseUpgrade = function(value) return (value) .. "m" end,
        drain = 20,
        cooldown = 5,
        casttime = 0,
        cost = 2,
        icon = "arrow-dunk",
        color = "#F06543",
        grenade = false,
        execute = MC.LongJump
    },
    {
        name = "Dash",
        category = "Mobility",
        description = "<b>Dash</b> in a direction to <b>avoid all damage</b> for the whole dash duration. \n<i>Duration is based on module's level.",
        type = "Active - Self",
        upgrade = "Duration",
        upgrades = {0.5, 0.55, 0.6, 0.65, 0.7, 0.76, 0.82, 0.88, 0.94, 1},
        parseUpgrade = function(value) return (value) .. "s" end,
        drain = 40,
        cooldown = 5,
        casttime = 0,
        cost = 2,
        icon = "sprint",
        color = "#F7FFDD",
        grenade = false,
        execute = MC.Dash
    },
    {
        name = "Jetpack Thrust",
        category = "Mobility",
        description = "<b>Thrust</b> upwards in a short burst. \n<i>Thrust Power is based on module's level.",
        type = "Active - Self",
        upgrade = "Power",
        upgrades = {0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1},
        parseUpgrade = function(value) return (value * 100) .. "%" end,
        drain = 20,
        cooldown = 0.5,
        casttime = 0,
        cost = 1,
        icon = "jet-pack",
        color = "#5A2F00",
        grenade = false,
        execute = MC.JetpackThrust
    },
    {
        name = "Turret",
        category = "Minion",
        description = "Deploy a friendly <b>static turret</b> which <b>shoots</b> any enemy it sees. \n<i>Damage is based on module's level.",
        type = "Active - Deployable",
        upgrade = "Damage",
        upgrades = {1.5, 1.7, 1.9, 2.1, 2.4, 2.7, 3, 3.4, 3.8, 4.2},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 60,
        casttime = 0,
        cost = 2,
        icon = "sentry-gun",
        color = "#C6C4C4",
        grenade = false,
        execute = MC.DeployTurret
    },
    {
        name = "Rollermine",
        category = "Minion",
        description = "Deploy a friendly <b>rollermine</b> which <b>bashes</b> any enemy it sees, dealing damage. \n<i>Damage is based on module's level.",
        type = "Active - Deployable",
        upgrade = "Damage",
        upgrades = {4, 4.3, 4.6, 4.9, 5.2, 5.5, 6, 6.5, 7, 7.5},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 60,
        casttime = 0,
        cost = 3,
        icon = "morph-ball",
        color = "#A1CFD2",
        grenade = false,
        execute = MC.DeployRollermine
    },
    {
        name = "Rebel",
        category = "Minion",
        description = "Deploy a friendly <b>citizen</b> which <b>shoots</b> any enemy it sees. \n<i>Damage is based on module's level.",
        type = "Active - Deployable",
        upgrade = "Damage",
        upgrades = {1, 1.2, 1.4, 1.6, 1.8, 2, 2.3, 2.6, 2.9, 3.2},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 60,
        casttime = 0,
        cost = 3,
        icon = "static-guard",
        color = "#A8FCD1",
        grenade = false,
        execute = MC.DeployRebel
    },
    {
        name = "Manhack",
        category = "Minion",
        description = "Deploy a friendly <b>manhack</b> which <b>slashes</b> any enemy it sees. \n<i>Damage is based on module's level.",
        type = "Active - Deployable",
        upgrade = "Damage",
        upgrades = {2, 2.2, 2.4, 2.6, 2.8, 3, 3.3, 3.6, 3.9, 4.2},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 60,
        casttime = 0,
        cost = 3,
        icon = "evil-bat",
        color = "#A4B3A8",
        grenade = false,
        execute = MC.DeployManhack
    },
    {
        name = "Vortigaunt",
        category = "Minion",
        description = "Deploy a friendly <b>vortigaunt</b> which <b>beams</b> any enemy it sees. \n<i>Damage is based on module's level.",
        type = "Active - Deployable",
        upgrade = "Damage",
        upgrades = {4, 4.3, 4.6, 4.9, 5.2, 5.5, 6, 6.5, 7, 7.5},
        parseUpgrade = function(value) return (value * 10) .. "" end,
        drain = 50,
        cooldown = 60,
        casttime = 0,
        cost = 3,
        icon = "sinusoidal-beam",
        color = "#7FB486",
        grenade = false,
        execute = MC.DeployVortigaunt
    }
}

function MC.LoadAllData()
    for k, v in pairs (player.GetAll()) do
        MC.LoadData(v)
    end
end

function MC.LoadData(v, profile)
    v.profile = profile || tonumber(v:GetPData("profile", 1))
    v.profileName = v:GetPData(v.profile .. "_name", "New Profile")
    v.level = tonumber(v:GetPData(v.profile .. "_level", 1))
    v.points = tonumber(v:GetPData(v.profile .. "_points", 2))
    v.exp = tonumber(v:GetPData(v.profile .. "_exp", 0))
    v:SetHealth(tonumber(v:GetPData(v.profile .. "_health", v:HealthFormula())))
    v.useModule = tonumber(v:GetPData(v.profile .. "_usemodule", -1))
    v.modules = MC.DeserializeModulesData(v:GetPData(v.profile .. "_modules", ""))
    v:SetMaxHealth(v:HealthFormula())
    v:SetPData("profile", v.profile)
end

function MC.SaveAllData()
    for k, v in pairs (player.GetAll()) do
        MC.SaveData(v)
    end
end

function MC.SaveData(v)
    v:SetPData("profile", v.profile)
    v:SetPData(v.profile .. "_name", v.profileName)
    v:SetPData(v.profile .. "_level", v.level)
    v:SetPData(v.profile .. "_points", v.points)
    v:SetPData(v.profile .. "_exp", v.exp)
    v:SetPData(v.profile .. "_health", v:Health())
    v:SetPData(v.profile .. "_usemodule", v.useModule)
    v:SetPData(v.profile .. "_modules", MC.SerializeModulesData(v.modules))
end

function MC.RenameProfile(v, id, name)
    v:SetPData(id .. "_name", name)
end

function MC.SerializeModulesData(data)
    local result = ""
    if (data != nil) then
        for k, v in ipairs (MC.modules) do
            result = result .. data[k]
            if (k < table.Count(MC.modules)) then
                result = result .. ";"
            end
        end
    end
    return result
end

function MC.DeserializeModulesData(data)
    local result = {}
    local split = string.Split(data, ";")
    
    if (data != "" && table.Count(split) == table.Count(MC.modules)) then
        for k, v in ipairs (split) do
            result[k] = tonumber(v)
        end
    else
        //print("-------------\n-------------\nNO VALID DATA FOUND\n-------------\n-------------")
        for k, v in ipairs (MC.modules) do
            result[k] = 0
        end
    end
    return result
end

function MC.ResetData(v, pId)
    local profile = pId || v.profile
    v:SetPData(profile .. "_name", "New Profile")
    v:SetPData(profile .. "_level", 1)
    v:SetPData(profile .. "_points", 2)
    v:SetPData(profile .. "_exp", 0)
    v:SetPData(profile .. "_health", 100)
    v:SetPData(profile .. "_usemodule", -1)
    v:SetPData(profile .. "_modules", MC.DeserializeModulesData(""))
    if (profile == v.profile) then
        MC.LoadData(v)
    end
end

concommand.Add("ResetData", function(v)
    ResetData(v)
end)