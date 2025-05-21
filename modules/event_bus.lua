-- event_bus.lua -------------------------------------------------------------
-- Event Bus simples e desacoplado para projetos Defold
-- Version 2.0 — inclui "sender" automático (GO que publicou) + chaves fracas
--
-- [Visão geral]
-- Este módulo implementa um barramento de eventos (pub/sub) leve em Lua.
-- • Mantém listeners com chaves fracas: não vaza memória.
-- • Passa automaticamente o **GO que disparou** o evento como `sender`.
--   Assinatura final do callback: `fn(ctx, sender, ...)`.
-- • Continua 100 % Lua, sem dependência da API de mensagens nativa.
--
-- [Glossário de variáveis]
--   M         : API pública (subscribe, unsubscribe, publish).
--   listeners : listeners[event] = weak_table{ [ctx_or_fn] = fn }
--   event     : Nome/hash do evento (ex.: "GLOBAL_DAMAGE").
--   fn        : Callback para o evento.
--   ctx       : Contexto opcional (normalmente `self`).
--   sender    : GO ID de quem publicou (obtido via `go.get_id()`).
--   ...       : Payload adicional.
-- ---------------------------------------------------------------------------

local M = {}
local listeners = {}

-------------------------------------------------------------------------------
-- subscribe(event, fn, ctx)
-------------------------------------------------------------------------------
function M.subscribe(event, fn, ctx)
    if not listeners[event] then
        listeners[event] = setmetatable({}, { __mode = "k" })
    end
    listeners[event][ctx or fn] = fn
end

-------------------------------------------------------------------------------
-- unsubscribe(event, ctx)
-------------------------------------------------------------------------------
function M.unsubscribe(event, ctx)
    local list = listeners[event]
    if list then list[ctx] = nil end
end

-------------------------------------------------------------------------------
-- publish(event, ...)
-- Passa para cada callback: (ctx, sender, ...)
-------------------------------------------------------------------------------
function M.publish(event, ...)
    local list = listeners[event]
    if not list then return end

    local sender = go.get_id() -- quem chamou publish()

    for ctx, fn in pairs(list) do
        fn(ctx, sender, ...)
    end
end

return M
