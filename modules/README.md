# Defold Event Bus

Event bus (pub/sub) 100 % Lua:
* `subscribe(event, fn, ctx [, scope])`
* `unsubscribe(event, ctx [, scope])`
* `publish(event, args, scope)` 

## How To Use

Um consumidor deve se inscrever para o evento e o canal. O produtor deve publicar um evento no canal.

- `ctx`: contexto que se deseja enviar para a função de callback informada no subscribe (isso é necessário, pois self não estará disponível ao processar o evento, pois fará parte de outra pilha de execução)
- `args`: deve ser nil ou table

```lua
-- publisher.script
local bus = require "modules.event_bus"

function init(self)
    msg.post(".", "acquire_input_focus")
end

function on_input(self, action_id, action)
    if action_id == hash("attack_enemy_1") and action.released then
        bus.publish("GLOBAL_DAMAGE", { damage = 10 }, hash("enemy_1"))
    elseif action_id == hash("attack_enemy_2") and action.released then
        bus.publish("GLOBAL_DAMAGE", { damage = 10 }, hash("enemy_2"))
    end
end

```

```lua
-- main/listener.script
local bus = require "main.event_bus"

local function on_global_damage(self, sender, args)
    -- msg.url() is the URL of the GO that sent the message.
    -- This allows for better context handling in the event bus.
    local sender_id = sender.path
    self.hp = self.hp - args.damage
    local message_to_print = go.get_id() .. " hit by " .. sender_id .. ". HP: " .. self.hp
    print(message_to_print)
    if self.hp <= 0 then go.delete() end
end

function init(self)
    msg.post(".", "acquire_input_focus")
    bus.subscribe("GLOBAL_DAMAGE", on_global_damage, self, hash("enemy_2"))
end

function update(self, dt)
    --[[
    A quantidade de eventos que deseja processar é opcional, mas:
        - <= 0: não processar nada;
        - nil: processar tudo;
    Após o evento ser processado, ele é removido da fila
    ]]
    bus.process(self, 1)
end

function final(self)
    bus.unsubscribe("GLOBAL_DAMAGE", self, hash("enemy_2"))
end

```