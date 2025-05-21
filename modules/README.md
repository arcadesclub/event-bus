# Defold Event Bus

Event bus (pub/sub) 100 % Lua:
* `subscribe(event, fn, ctx)`
* `unsubscribe(event, ctx)`
* `publish(event, ...)` — send via *(ctx, sender, ...)*

## How To Use

```lua
-- publisher.script
local bus = require "defold_event_bus.src.event_bus"

function init(self)
    msg.post(".", "acquire_input_focus")
end

function on_input(self, action_id, action)
    if action_id == hash("touch") and action.released   -- click/touch
    or (action_id == hash("space") and action.released) -- keyboard
    then
        bus.publish("GAME.GLOBAL_DAMAGE", 10)
    end
end

```

```lua
-- main/listener.script
local bus = require "main.event_bus"

local function on_global_damage(self, sender, dmg)
    self.hp = self.hp - dmg
    local message_to_print = self.id .. " hit by " .. tostring(sender) .. ". HP: " .. tostring(self.hp)
    print(message_to_print)
    if self.hp <= 0 then go.delete(self.id) end
end

function init(self)
    self.id = go.get_id() -- necessary because go.get_id() inside the callback always reflects the context at the top of the stack, that is, whoever called publish(). This is inherent to Defold's single VM and cannot be "fixed" at runtime. Therefore, the cleanest practice is to store self.id and use the sender parameter to identify the emitter
    self.hp = 30
    bus.subscribe("GAME.GLOBAL_DAMAGE", on_global_damage, self)
end

function final(self)
    bus.unsubscribe("GAME.GLOBAL_DAMAGE", self)
end

```