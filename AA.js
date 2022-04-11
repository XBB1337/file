UI.AddSubTab(["Rage", "SUBTAB_MGR"], "Anti-Aim");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"]," >>-      Anti-Aim  ++      -<<", 0, 0);
UI.AddDropdown(["Rage", "Anti-Aim", "Anti-Aim"],"Presets", ["Custom", "Valve", "HvH", "Blank"],1);
UI.AddHotkey(["Rage", "Anti Aim", "General", "Key assignment"], "Walk AA","Walk AA");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Speed:", 0, 135);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"Advanced Jitter");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Jitter limit", -180, 180);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"Offset Break");
UI.AddDropdown(["Rage", "Anti-Aim", "Anti-Aim"],"Anti Bruteforce", ["No", "Hit the target", "After shooting"],1);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"Freestand On Hit");
UI.AddSliderFloat(["Rage", "Anti-Aim", "Anti-Aim"],"Freestand Duration", 0, 5);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"AA-Swing");
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"Swing astrict");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Sway Amount", 0, 60);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Sway Range", 0, 360);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Sway frequency", 1, 50);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"False jitter");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"False jitter Speed", 1, 100);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"False jitter Range", 1, 100);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"False jitter Step", 1, 10);
UI.AddCheckbox(["Rage", "Anti-Aim", "Anti-Aim"],"AntiAim-Switch");
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Switch Delay", 1, 1000);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Switch Yaw - A", -180, 180);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Switch Yaw - B", -180, 180);
UI.AddSliderInt(["Rage", "Anti-Aim", "Anti-Aim"],"Switch Yaw - C", -180, 180);

var timer = false;
var down = false;
var man_timer = false;
lll = false;
a = 0;
var czz = 0;
var slide = false;
var fakeoff = 1;
var slideYonsn = 0;
man_init = false;
yawYonsn = 0;
rgb_r = 0;
rgb_g = 100;
rgb_b = 255;
current_preset = 0;
var sw_timer = false;
var sw_cur = 1;
exploit_on = false;
var lastTime = 0;

var hittime = 0;
var FREESTAND = false;

function OnHurt()
{
if (Entity.GetEntityFromUserID(Event.GetInt("userid")) !== Entity.GetLocalPlayer()) return;
var hitbox = Event.GetInt('hitgroup');

if (hitbox == 3 || hitbox == 4 || hitbox == 5 || hitbox == 6 )
{
hittime = Global.Curtime();
}
}

function Freestanding()
{
if (!UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Freestand On Hit"]))
return;

FREESTAND = 0;

if ((hittime + UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim","Freestand Duration"]) > Global.Curtime()))
FREESTAND = 1;

UI.SetValue(["Rage", "Anti Aim", "Directions", "Auto direction" ],FREESTAND);
}

var jitter_cache = UI.GetValue(["Rage", "Anti Aim", "Directions", "Jitter offset"])
var yaw_cache = UI.GetValue(["Rage", "Anti Aim", "Directions", "Yaw offset"])

function Walk_AA()
{
    localplayer_index = Entity.GetLocalPlayer( );


        if(UI.GetValue(["Rage", "Anti Aim", "General", "Key assignment", "Walk AA"]))
        {
            UI.SetValue(["Rage", "Anti Aim", "Directions", "Yaw offset"], 4);
            UI.SetValue(["Rage", "Anti Aim", "Directions", "Jitter offset"], -4);
            AntiAim.SetOverride(1);
            AntiAim.SetFakeOffset(-2);
            AntiAim.SetRealOffset(-32);
		
              }
            
}

function onunload() {
    AntiAim.SetOverride(0)
}
Cheat.RegisterCallback("Unload", "onunload")

function getVal(valName) {return UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", valName]);}

function cMove() {
    //forward, side, up.
    if (!UI.GetValue(["Rage", "Anti Aim", "General", "Key assignment", "Walk AA"])) return;

    speed = getVal("Speed:");

    fSpeed = speed;
    bSpeed = speed;
    sSpeed = speed;


    dir = [0, 0, 0];

    if (Input.IsKeyPressed(0x57)) {
        //'W' AKA Forward
        dir[0] += fSpeed;
    }
    if (Input.IsKeyPressed(0x44)) {
        //'D' AKA Right
        dir[1] += sSpeed;
    }
    if (Input.IsKeyPressed(0x41)) {
        //'A' AKA Left
        dir[1] -= sSpeed;
    }
    if (Input.IsKeyPressed(0x53)) {
        //'S' AKA Back
        dir[0] -= bSpeed;
    }

    UserCMD.SetMovement(dir);
}


function GetScriptOption(name)
{
    var Value = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", name]);
    return Value;
}

function radian(degree)
{
    return degree * Math.PI / 180.0;
}

function ExtendVector(vector, angle, extension)
{
    var radianAngle = radian(angle);
    return [extension * Math.cos(radianAngle) + vector[0], extension * Math.sin(radianAngle) + vector[1], vector[2]];
}

function VectorAdd(a, b)
{
    return [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
}

function VectorSubtract(a, b)
{
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

function VectorMultiply(a, b)
{
    return [a[0] * b[0], a[1] * b[1], a[2] * b[2]];
}

function VectorLength(x, y, z)
{
    return Math.sqrt(x * x + y * y + z * z);
}

function VectorNormalize(vec)
{
    var length = VectorLength(vec[0], vec[1], vec[2]);
    return [vec[0] / length, vec[1] / length, vec[2] / length];
}

function VectorDot(a, b)
{
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function VectorDistance(a, b)
{
    return VectorLength(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
}

function ClosestPointOnRay(target, rayStart, rayEnd)
{
    var to = VectorSubtract(target, rayStart);
    var dir = VectorSubtract(rayEnd, rayStart);
    var length = VectorLength(dir[0], dir[1], dir[2]);
    dir = VectorNormalize(dir);

    var rangeAlong = VectorDot(dir, to);
    if (rangeAlong < 0.0)
    {
        return rayStart;
    }
    if (rangeAlong > length)
    {
        return rayEnd;
    }
    return VectorAdd(rayStart, VectorMultiply(dir, [rangeAlong, rangeAlong, rangeAlong]));
}

function Flip()
{
    UI.ToggleHotkey(["Rage", "Anti Aim", "General", "Key assignment", 'AA Direction inverter']);
}

var lastHitTime = 0.0;
var lastImpactTimes =
[
    0.0
];
var lastImpacts =
[
    [0.0, 0.0, 0.0]
];

function OnHurt()
{
    if (GetScriptOption("Anti Bruteforce") == 0) return;
    if (Entity.GetEntityFromUserID(Event.GetInt("userid")) !== Entity.GetLocalPlayer()) return;
    var hitbox = Event.GetInt('hitgroup');

    if (hitbox == 1 || hitbox == 6 || hitbox == 7)  //head, both toe
    {
        var curtime = Global.Curtime();
        if (Math.abs(lastHitTime - curtime) > 0.5)   //0.2s backtrack + 0.2 extand + 0.1 extra
        {
            lastHitTime = curtime;
            Flip();
        }
    }
}

function OnBulletImpact()
{
    if (GetScriptOption("Anti Bruteforce") !== 2) return;

    var curtime = Global.Curtime();
    if (Math.abs(lastHitTime - curtime) < 0.5) return;

    var entity = Entity.GetEntityFromUserID(Event.GetInt("userid"));
    var impact = [Event.GetFloat("x"), Event.GetFloat("y"), Event.GetFloat("z"), curtime];
    var source;
    if (Entity.IsValid(entity) && Entity.IsEnemy(entity))
    {
        if (!Entity.IsDormant(entity))
        {
            source = Entity.GetEyePosition(entity);
        }
        else if (Math.abs(lastImpactTimes[entity] - curtime) < 0.1)
        {
            source = lastImpacts[entity];
        }
        else
        {
            lastImpacts[entity] = impact;
            lastImpactTimes[entity] = curtime;
            return;
        }
        var local = Entity.GetLocalPlayer();
        var localEye = Entity.GetEyePosition(local);
        var localOrigin = Entity.GetProp(local, "CBaseEntity", "m_vecOrigin");
        var localBody = VectorMultiply(VectorAdd(localEye, localOrigin), [0.5, 0.5, 0.5]);

        var bodyVec = ClosestPointOnRay(localBody, source, impact);
        var bodyDist = VectorDistance(localBody, bodyVec);
        
        if (bodyDist < 128.0)       //he clearly shot at us!
        {
            var realAngle = Local.GetRealYaw();
            var fakeAngle = Local.GetFakeYaw();

            var headVec = ClosestPointOnRay(localEye, source, impact);
            var headDist = VectorDistance(localEye, headVec);
            var feetVec = ClosestPointOnRay(localOrigin, source, impact);
            var feetDist = VectorDistance(localOrigin, feetVec);

            var closestRayPoint;
            var realPos;
            var fakePos;

            if (bodyDist < headDist && bodyDist < feetDist)     //that's a pelvis
            {                                                   //pelvis direction = goalfeetyaw + 180       
                closestRayPoint = bodyVec;
                realPos = ExtendVector(bodyVec, realAngle + 180.0, 10.0);
                fakePos = ExtendVector(bodyVec, fakeAngle + 180.0, 10.0);
            }
            else if (feetDist < headDist)                       //ow my toe
            {                                                   //toe direction = goalfeetyaw -30 +- 90
                closestRayPoint = feetVec;
                var realPos1 = ExtendVector(bodyVec, realAngle - 30.0 + 90.0, 10.0);
                var realPos2 = ExtendVector(bodyVec, realAngle - 30.0 - 90.0, 10.0);
                var fakePos1 = ExtendVector(bodyVec, fakeAngle - 30.0 + 90.0, 10.0);
                var fakePos2 = ExtendVector(bodyVec, fakeAngle - 30.0 - 90.0, 10.0);
                if (VectorDistance(feetVec, realPos1) < VectorDistance(feetVec, realPos2))
                {
                    realPos = realPos1;
                }
                else
                {
                    realPos = realPos2;
                }
                if (VectorDistance(feetVec, fakePos1) < VectorDistance(feetVec, fakePos2))
                {
                    fakePos = fakePos1;
                }
                else
                {
                    fakePos = fakePos2;
                }
            }
            else                                                //ow my head i feel like i slept for 2 days
            {
                closestRayPoint = headVec;
                realPos = ExtendVector(bodyVec, realAngle, 10.0);
                fakePos = ExtendVector(bodyVec, fakeAngle, 10.0);
            }

            if (VectorDistance(closestRayPoint, fakePos) < VectorDistance(closestRayPoint, realPos))        //they shot at our fake. they will probably not gonna shoot it again.
            {
                lastHitTime = curtime;
                Flip();
            }
        }

        lastImpacts[entity] = impact;
        lastImpactTimes[entity] = curtime;
    }
}

Cheat.RegisterCallback("player_hurt", "OnHurt");
Cheat.RegisterCallback("bullet_impact", "OnBulletImpact");



function antiaimloop() {
    
    var $typeface = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Advanced Jitter"]);
    var $off = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Offset Break"]);
    var $sway = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "AA-Swing"]);
    var $switch = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "AntiAim-Switch"]);
    var $fake = getScriptVal("False jitter");
    if (getScriptVal( "Presets") !== current_preset){
        loadPreset(getScriptVal("Presets"));
        current_preset = getScriptVal( "Presets");
    }
    if (!$typeface) {
        UI.SetValue(["Rage", "Anti Aim", "Directions", "Jitter offset"], 0);
    }
    if ($typeface) {
        var $Range = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Jitter limit"]);
        var bg = $Range;
        var sg = ($Range *  -1);
        min = Math.ceil(sg);
        max = Math.floor(bg);
        AntiAim.SetOverride(1);
        var subVal = (Math.floor(Math.random(subVal) * (max - min)) + min);
        var rem = subVal / 2;
        UI.SetValue(["Rage", "Anti Aim", "Directions", "Yaw offset"], rem);
        UI.SetValue(["Rage", "Anti Aim", "Directions", "Jitter offset"], subVal);
    }
    if ($off) {
        var m2 = m2 + m1;
        var m1 = Math.floor(Math.random() * 100) - 50;
        var c1 = Math.floor( (Math.random() * 50)) - 25;
        var offsetVal = (m1 * -1);
        AntiAim.SetOverride(1);
        AntiAim.SetFakeOffset(m1);
        AntiAim.SetRealOffset(offsetVal);
    }
    {
        isInverted = UI.GetValue(["Rage", "Anti Aim", "General", "Key assignment", 'AA Direction inverter']);
        slideRange = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Sway Range"]);
        slideRate = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Sway frequency"]);
        limit = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Swing astrict"]);
        LimitYonsn = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Sway Amount"]);
        if (!limit) {
            if (slide) {
                if (slideYonsn > (slideRange / 2)) {
                    slide = false;
                } else {
                    slideYonsn += slideRate;
                }
            } else {
                if (slideYonsn < -(slideRange / 2)) {
                    slide = true;
                } else {
                    slideYonsn -= slideRate;
                }
            }
            slideRange += slideYonsn;
        } else if (limit) {
            if (slide) {
                if (slideYonsn > slideRange / 2) {
                    slide = false;
                } else {
                    slideYonsn += slideRate;
                }
            } else {
                if (slideYonsn < LimitYonsn / 2) {
                    slide = true;
                } else {
                    slideYonsn -= slideRate;
                }
            }
        }
        if ($sway && !isInverted) {
            AntiAim.SetOverride(1);
            AntiAim.SetFakeOffset(0);
            AntiAim.SetRealOffset(slideYonsn);
            AntiAim.SetLBYOffset(-slideYonsn);
        } else if ($sway && isInverted) {
            AntiAim.SetOverride(1);
            AntiAim.SetFakeOffset(0);
            AntiAim.SetRealOffset(-slideYonsn);
            AntiAim.SetLBYOffset(slideYonsn);
        }
    }
    if ($fake) {
        FJ_Step = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "False jitter Step"]);
        FJ_Range = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "False jitter Range"]);
        FJ_Speed = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "False jitter Speed"]);
        FJ_Extend = ((1e-9)/ (FJ_Speed * 0x4ee0d1d72fd4780000000000000));
        FJ_Retract = 1e-22 / (FJ_Speed * 0x7e3482f1e620c0000000000000);
        AntiAim.SetOverride(1);
        if ((a < FJ_Range) && !down) {
            if (!timer) {
                lasttime = Globals.Curtime();
                timer = true;
            }
            if (Globals.Curtime() >=( lasttime + FJ_Extend)) {
                a += FJ_Step;
                if (!areExploits()) {
                    AntiAim.SetFakeOffset(0);
                    if (!isInverted) {
                        AntiAim.SetLBYOffset(a);
                    } else if (isInverted) {
                        AntiAim.SetLBYOffset(-a);
                    }
                } else {
                    if (!isInverted) {
                        AntiAim.SetFakeOffset(a);
                        AntiAim.SetFakeOffset(-a);
                    } else if (isInverted) {
                        AntiAim.SetFakeOffset(-a);
                        AntiAim.SetFakeOffset(a);
                    }
                }
                timer = false;
            }
        } else if ( (a >= FJ_Range) || down) {
            down = true;
            if (a <= 0) {
                down = false;
            }
            if (!timer) {
                lasttime = Globals.Curtime();
                timer = true;
            }
            if (Globals.Curtime() >= (lasttime + FJ_Retract)) {
                a -= FJ_Step;
                if (!areExploits()) {
                    AntiAim.SetFakeOffset(0);
                    if (!isInverted) {
                        AntiAim.SetLBYOffset(a);
                    } else if (isInverted) {
                        AntiAim.SetLBYOffset(-a);
                    }
                } else {
                    if (!isInverted) {
                        AntiAim.SetFakeOffset(a);
                        AntiAim.SetFakeOffset(-a);
                    } else if (isInverted) {
                        AntiAim.SetFakeOffset(-a);
                        AntiAim.SetFakeOffset(a);
                    }
                }
                timer = false;
            }
        }
    }
    if ($switch) {
        switchC1 = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Switch Yaw - A"]);
        switchC2 = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Switch Yaw - B"]);
        switchC3 = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Switch Yaw - C"]);
        switchDelay = UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim", "Switch Delay"]);
        sw_delay = 0.001 * switchDelay;
        if (!sw_timer) {
            sw_lasttime = Globals.Curtime();
            sw_timer = true;
        }
        if (Globals.Curtime() >= sw_lasttime + sw_delay) {
            if (sw_cur == 1) {
                sw_val = switchC2;
                sw_cur += 1;
                sw_timer = false;
            } else if (sw_cur == 2) {
                sw_val = switchC3;
                sw_cur += 1;
                sw_timer = false;
            } else if (sw_cur == 3) {
                sw_val = switchC1;
                sw_cur = 1;
                sw_timer = false;
            }
            if (!isInverted) {
                UI.SetValue(["Rage", "Anti Aim", "Directions", "Yaw offset"], sw_val);
            } else if (isInverted) {    
                UI.SetValue(["Rage", "Anti Aim", "Directions", "Yaw offset"], -sw_val);
            }
        }
    }
    


}

function onFire() {
    return;
}



function setYaw(yaw) {
    UI.SetValue(["Rage", "Anti Aim", "Directions", "Yaw offset", yaw]);
}

function rand_int(min, max) {
    return Math.floor(Math.random() * ( (max -  min) + 1) + min);
}

function onUnload() {
    AntiAim.SetOverride(0);
}

function getScriptVal(name) {
    return UI.GetValue(["Rage", "Anti-Aim", "Anti-Aim"],name);
}

function setScriptVal(key, value) {
    UI.SetValue(["Rage", "Anti-Aim", "Anti-Aim",  key], value);
}

function areExploits() {

    if (UI.GetValue(["Rage", "Exploits", "Keys", "Double tap"]) || UI.GetValue(["Rage", "Exploits", "Keys", "Hide shots"])) {
        if (!exploit_on) {
            OG_FJspeed = getScriptVal("False jitter Speed");
            OG_FJrange = getScriptVal( "False jitter Range");
            OG_FJstep = getScriptVal( "False jitter Step");
        }
        setScriptVal("False jitter Speed", 90);
        setScriptVal("False jitter Range", 11);
        setScriptVal("False jitter Step", 8);
        exploit_on = true;
        return true;
    } else {
        if (exploit_on) {
            setScriptVal("False jitter Speed", OG_FJspeed);
            setScriptVal( "False jitter Range", OG_FJrange);
            setScriptVal( "False jitter Step", OG_FJstep);
        }
        exploit_on = false;
        return false;
    }
}

function loadPreset(parms) {
    switch (parms) {
        case 0:
            return;
            break;
        case 1:
            p_isAdvancedJitter = 1;
            p_AdvancedRange = -5;
            p_isOffsetBreak = 0;
            p_isSway = 1;
            p_isSwayLimit = 1;
            p_LimitRange = 17;
            p_swayRange = 45;
            p_swaySpeed = 2;
            p_isFakeJitter = 1;
            p_FJspeed = 15;
            p_FJrange = 15;
            p_FJstep = 3;
            p_isSwitchAA = 1;
            p_yawVal1 = -3;
            p_yawVal2 = -2;
            p_yawVal3 = -1;
            break;
        case 2:
            p_isAdvancedJitter = 1;
            p_AdvancedRange = -14;
            p_isOffsetBreak = 1;
            p_isSway = 1;
            p_isSwayLimit = 0;
            p_LimitRange = 34;
            p_swayRange = 87;
            p_swaySpeed = 14;
            p_isFakeJitter = 1;
            p_FJspeed = 25;
            p_FJrange = 34;
            p_FJstep = 6;
            p_isSwitchAA = 1;
            p_yawVal1 = -1;
            p_yawVal2 = -5;
            p_yawVal3 = -2;
            break;
        case 3:
            p_isAdvancedJitter = 0;
            p_AdvancedRange = 0;
            p_isOffsetBreak = 0;
            p_isSway = 0;
            p_isSwayLimit = 0;
            p_LimitRange = 0;
            p_swayRange = 0;
            p_swaySpeed = 0;
            p_isFakeJitter = 0;
            p_FJspeed = 0;
            p_FJrange = 0;
            p_FJstep = 0;
            p_isSwitchAA = 0;
            p_yawVal1 = 0;
            p_yawVal2 = -10;
            p_yawVal3 = 0;
            break;
        default:
            return;
            break;
    }
    setScriptVal("Advanced Jitter", p_isAdvancedJitter);
    setScriptVal( "Range", p_AdvancedRange);
    setScriptVal("Offset Break", p_isOffsetBreak);
    setScriptVal( "AA-Swing", p_isSway);
    setScriptVal( "Swing astrict", p_isSwayLimit);
    setScriptVal("Sway Amount", p_LimitRange);
    setScriptVal( "Sway Range", p_swayRange);
    setScriptVal("Sway frequency", p_swaySpeed);
    setScriptVal("False jitter", p_isFakeJitter);
    setScriptVal("False jitter Speed", p_FJspeed);
    setScriptVal("False jitter Range", p_FJrange);
    setScriptVal("False jitter Step", p_FJstep);
    setScriptVal( "AntiAim-Switch", p_isSwitchAA);
    setScriptVal("Switch Yaw - A", p_yawVal1);
    setScriptVal("Switch Yaw - B", p_yawVal1);
    setScriptVal("Switch Yaw - C", p_yawVal1);
}

function main()
{
    //const font = Render.GetFont( "Tahomabd.ttf", 40, true )
    //Render.String(10, 720 / 2 + 358, 0, "", [0,255,255,255], font)
}
Cheat.RegisterCallback("Draw", "main")
Cheat.RegisterCallback("CreateMove", "antiaimloop");
Cheat.RegisterCallback("Unload", "onUnload");
Cheat.RegisterCallback("CreateMove", "Walk_AA");
Cheat.RegisterCallback("CreateMove", "cMove");
Cheat.RegisterCallback("player_hurt", "OnHurt");
Cheat.RegisterCallback("Draw", "Freestanding");

