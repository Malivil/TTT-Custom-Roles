if SERVER then
    local resource = resource

    ---------------
    -- Materials --
    ---------------

    -- Celebration
    resource.AddSingleFile("materials/vgui/confetti.png")

    -- Corpse Search
    resource.AddFile("materials/vgui/ttt/icon_killer.vmt")
    resource.AddFile("materials/vgui/ttt/icon_team.vmt")

    -- Items
    resource.AddFile("materials/vgui/ttt/icon_bombstation.vmt")
    resource.AddFile("materials/vgui/ttt/icon_brainwash.vmt")
    resource.AddFile("materials/vgui/ttt/icon_cure.vmt")
    resource.AddFile("materials/vgui/ttt/icon_death_radar.vmt")
    resource.AddFile("materials/vgui/ttt/icon_exor.vmt")
    resource.AddFile("materials/vgui/ttt/icon_fakecure.vmt")
    resource.AddFile("materials/vgui/ttt/icon_meddefib.vmt")
    resource.AddFile("materials/vgui/ttt/icon_regen.vmt")
    resource.AddFile("materials/vgui/ttt/icon_speed.vmt")
    resource.AddFile("materials/vgui/ttt/icon_stationbomb.vmt")
    resource.AddFile("materials/vgui/ttt/icon_track_radar.vmt")

    -- Radar
    resource.AddFile("materials/vgui/ttt/beacon_back.vmt")
    resource.AddFile("materials/vgui/ttt/beacon_det.vmt")
    resource.AddFile("materials/vgui/ttt/beacon_skull.vmt")

    -- Round Summary
    resource.AddSingleFile("materials/vgui/ttt/score_disconicon.png")
    resource.AddSingleFile("materials/vgui/ttt/score_skullicon.png")

    -- Shop
    resource.AddFile("materials/vgui/ttt/equip/armor.vmt")
    resource.AddSingleFile("materials/vgui/ttt/equip/briefcase.png")
    resource.AddSingleFile("materials/vgui/ttt/equip/coin.png")
    resource.AddSingleFile("materials/vgui/ttt/equip/package.png")
    resource.AddFile("materials/vgui/ttt/slot_cap.vmt")

    -- Target ID
    resource.AddFile("materials/vgui/ttt/sprite_roleback.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_roleback_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_rolefront.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_rolefront_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_targetdownback.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_targetdownback_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_targetdownfront.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_targetdownfront_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_targetupback.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_targetupback_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_targetupfront.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_targetupfront_noz.vmt")

    -- Target Icons
    resource.AddFile("materials/vgui/ttt/targeticons/down/sprite_target_douse.vmt")
    resource.AddSingleFile("materials/vgui/ttt/targeticons/down/sprite_target_douse_noz.vmt")
    resource.AddFile("materials/vgui/ttt/targeticons/down/sprite_target_kill.vmt")
    resource.AddSingleFile("materials/vgui/ttt/targeticons/down/sprite_target_kill_noz.vmt")
    resource.AddFile("materials/vgui/ttt/targeticons/up/sprite_target_lover.vmt")
    resource.AddSingleFile("materials/vgui/ttt/targeticons/up/sprite_target_lover_noz.vmt")
    resource.AddFile("materials/vgui/ttt/targeticons/up/sprite_target_shadow.vmt")
    resource.AddSingleFile("materials/vgui/ttt/targeticons/up/sprite_target_shadow_noz.vmt")

    -- "Nil" role
    resource.AddFile("materials/vgui/ttt/roles/nil/icon_nil.vmt")
    resource.AddSingleFile("materials/vgui/ttt/roles/nil/score_nil.png")
    resource.AddSingleFile("materials/vgui/ttt/roles/nil/tab_nil.png")
    resource.AddSingleFile("materials/vgui/ttt/roles/nil/sprite_nil.vmt")
    resource.AddSingleFile("materials/vgui/ttt/roles/nil/sprite_nil_noz.vmt")
    resource.AddSingleFile("materials/vgui/ttt/roles/nil/sprite_nil.vtf")

    -- Misc
    resource.AddFile("materials/thieves/footprint.vmt")
    resource.AddFile("materials/vgui/ttt/tele_mark.vmt")
    resource.AddSingleFile("materials/vgui/ttt/ulx_ttt.png")

    -- Tutorial
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_death_arrow.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_found_arrow.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_corpse_info.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut03_shop.png")

    ------------
    -- Sounds --
    ------------

    -- Celebration
    resource.AddSingleFile("sound/birthday.wav")

    -- Smoke grenade
    resource.AddSingleFile("sound/extinguish.wav")

    -- Hit Markers
    resource.AddSingleFile("sound/hitmarkers/mlghit.wav")
end