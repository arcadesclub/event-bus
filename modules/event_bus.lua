-- event_bus.lua -------------------------------------------------------------
-- Event Bus simples e desacoplado para projetos Defold
-- Version 2.0 — inclui "sender" automático (GO que publicou) + chaves fracas + bus escopado
--
-- [Visão geral]
-- Este módulo implementa um barramento de eventos (pub/sub) leve em Lua.
-- • Fila por contexto (GUI‑safe)        → bus.process(ctx[, max])
-- • Mantém contexto escopado. Listeners separados por "área" (ex.: "LEVEL1", "UI").
-- • Mantém listeners com chaves fracas: não vaza memória.
-- • Passa automaticamente o **GO que disparou** o evento como `sender`.
-- • Assinatura final do callback: `fn(ctx, sender, ...)`.
-- • Continua 100 % Lua, sem dependência da API de mensagens nativa.
--
-- [Glossário de variáveis]
--   M         : API pública (subscribe, unsubscribe, publish).
--   listeners : listeners[event] = weak_table{ [ctx_or_fn] = fn }
--   event     : Nome/hash do evento (ex.: "GLOBAL_DAMAGE").
--   fn        : Callback para o evento.
--   ctx       : Contexto opcional (normalmente `self`).
--   sender    : GO ID de quem publicou (obtido via `go.get_id()`).
--   scoped    : Qualquer string. Se omitido → "_global".
--   ...       : Payload adicional.
-- ---------------------------------------------------------------------------

local M = {}

local DEFAULT_SCOPE = hash("_global")
local listeners = {}                -- listeners[event][scope] = weak {ctx→fn}
local queue     = setmetatable({}, { __mode = "k" }) -- fila por contexto

------------------------------------------------------------------
-- subscribe(event, fn, ctx [, scope])
------------------------------------------------------------------
function M.subscribe(event, fn, ctx, scope)
    scope = scope or DEFAULT_SCOPE

    if not listeners[event] then listeners[event] = {} end
    local scopes = listeners[event]

    if not scopes[scope] then
        scopes[scope] = setmetatable({}, { __mode = "k" })
    end
    scopes[scope][ctx or fn] = fn
end

------------------------------------------------------------------
-- unsubscribe(event, ctx [, scope])
------------------------------------------------------------------
function M.unsubscribe(event, ctx, scope)
    scope = scope or DEFAULT_SCOPE
    local scopes = listeners[event]
    if scopes and scopes[scope] then
        scopes[scope][ctx] = nil
    end
end

------------------------------------------------------------------
-- publish(event [, args, scope], ...)
-- Enfileira callbacks do scope escolhido; recebe (ctx, sender, ...)
------------------------------------------------------------------
function M.publish(event, args, scope)
    -- Ajuste de parâmetros: se scope omitido, empurra payload
    if args ~= nil and type(args) ~= "table" then
        error("[Event Bus]: Args must be a table or nil, got: " .. type(args), 2)
    end

    if scope == nil or scope == '' or scope == "" then
        scope = DEFAULT_SCOPE
    end

    if scope ~= nil and type(scope) ~= "userdata" then
        error("[Event Bus]: Scope must be a hash, got: " .. type(scope), 2)
    end

    local scopes = listeners[event]
    if not scopes then return end

    local list = scopes[scope]
    if not list then return end

    local sender = go.get_id()

    for ctx, fn in pairs(list) do
        local q = queue[ctx]
        if not q then
            q = {}
            queue[ctx] = q
        end
        q[#q + 1] = { fn = fn, sender = sender, args = args or {} }
    end
end

------------------------------------------------------------------
-- process(ctx [, max])
-- Executa até `max` eventos da fila desse contexto.
-- Se `max` for 0, não processa nada e retorna 0.
-- Se `max` for nil, processa todos os eventos pendentes.
-- Retorna o número de eventos processados.
------------------------------------------------------------------
function M.process(ctx, max)

    if max == 0 then
        return 0
    end

    local q = queue[ctx]
    if not q or #q == 0 then return 0 end

    local processed = 0
    local limit = max or #q

    while processed < limit and #q > 0 do
        local item = table.remove(q, 1)
        item.fn(ctx, item.sender, item.args)
        processed = processed + 1
    end

    if #q == 0 then
        queue[ctx] = nil
    end

    return processed
end

return M
