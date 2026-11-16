-- Run from combat-recorder: lua tests/gcd_test.lua
local GCD = require("gcd")
local client, server = { value = 100 }, { value = 10 }
var = { VarClient = { COMBATV2_GLOBAL_COOLDOWN_START_CLIENT = client },
    VarPlayer = { COMBATV2_GLOBAL_COOLDOWN_START = server } }
GCD.Reset()
client.value, server.value = 200, 20
assert(GCD.Separator() == " -> ", "new GCD begins a rotation step")
assert(GCD.Separator() == " + ", "ability without a new GCD joins the current step")
server.value = 21
assert(GCD.Separator() == " + ", "later server update does not duplicate the client GCD")
client.value = 300
assert(GCD.Separator() == " -> ", "conditional action that starts a GCD begins a step")
assert(GCD.Separator() == " + ", "same action without a new GCD joins the step")
client.value = 0
assert(GCD.Separator() == " + ", "clearing a cooldown marker does not start a new step")
client.value = 400
GCD.Reset()
assert(GCD.Separator() == " + ", "reset discards earlier GCD changes")
var.VarClient = nil
GCD.Reset()
server.value = 30
assert(GCD.Separator() == " -> ", "server marker works when client marker is unavailable")
assert(GCD.Separator() == " + ")
var = nil
assert(GCD.Separator() == " -> ", "missing API markers retain the old separator")
print("GCD separators: new cooldowns, unchanged cooldowns, reset, and fallback passed")
