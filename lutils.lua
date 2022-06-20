package.preload["lutils.tween"] = package.preload["lutils.tween"] or function(...)
  local easing = require("lutils.easing")
  local tween = {easing = easing, _VERSION = "tween 2.1.1", _DESCRIPTION = "tweening for lua", _URL = "https://github.com/kikito/tween.lua", _LICENSE = "    MIT LICENSE\n\n    Copyright (c) 2014 Enrique Garc\195\173a Cota, Yuichi Tateno, Emmanuel Oga\n\n    Permission is hereby granted, free of charge, to any person obtaining a\n    copy of this software and associated documentation files (the\n    \"Software\"), to deal in the Software without restriction, including\n    without limitation the rights to use, copy, modify, merge, publish,\n    distribute, sublicense, and/or sell copies of the Software, and to\n    permit persons to whom the Software is furnished to do so, subject to\n    the following conditions:\n\n    The above copyright notice and this permission notice shall be included\n    in all copies or substantial portions of the Software.\n\n    THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS\n    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\n    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\n    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\n    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE\n    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n  "}
  local function copy_tables(destination, keys_table, values_table)
    values_table = (values_table or keys_table)
    local mt = getmetatable(keys_table)
    if (mt and (getmetatable(destination) == nil)) then
      setmetatable(destination, mt)
    else
    end
    for k, v in pairs(keys_table) do
      if (type(v) == "table") then
        destination[k] = copy_tables({}, v, values_table[k])
      else
        destination[k] = values_table[k]
      end
    end
    return destination
  end
  local function check_subject_and_target_recursively(subject, target, path)
    path = (path or {})
    local target_type, new_path = nil
    for k, target_value in pairs(target) do
      target_type, new_path = type(target_value), copy_tables({}, path)
      table.insert(new_path, tostring(k))
      if (target_type == "number") then
        assert((type(subject[k]) == "number"), ("Parameter '" .. table.concat(new_path, "/") .. "' is missing from subject or isn't a number"))
      elseif (target_type == "table") then
        check_subject_and_target_recursively(subject[k], target_value, new_path)
      else
        assert((target_type == "number"), ("Parameter '" .. table.concat(new_path, "/") .. "' must be a number or table of numbers"))
      end
    end
    return nil
  end
  local function check_new_params(duration, subject, target, easing0)
    assert(((type(duration) == "number") and (duration > 0)), ("duration must be a positive number. Was " .. tostring(duration)))
    local tsubject = type(subject)
    assert(((tsubject == "table") or (tsubject == "userdata")), ("subject must be a table or userdata. Was " .. tostring(subject)))
    assert((type(target) == "table"), ("target must be a table. Was " .. tostring(target)))
    assert((type(easing0) == "function"), ("easing must be a function. Was " .. tostring(easing0)))
    return check_subject_and_target_recursively(subject, target)
  end
  local function get_easing_function(easing0)
    easing0 = (easing0 or "linear")
    if (type(easing0) == "string") then
      local name = easing0
      easing0 = tween.easing[name]
      if (type(easing0) ~= "function") then
        error(("The easing function name '" .. name .. "' is invalid"))
      else
      end
    else
    end
    return easing0
  end
  local function perform_easing_on_subject(subject, target, initial, clock, duration, easing0)
    local t, b, c, d = nil
    for k, v in pairs(target) do
      if (type(v) == "table") then
        perform_easing_on_subject(subject[k], v, initial[k], clock, duration, easing0)
      else
        t, b, c, d = clock, initial[k], (v - initial[k]), duration
        subject[k] = easing0(t, b, c, d)
      end
    end
    return nil
  end
  local Tween = {}
  Tween.__index = Tween
  Tween.set = function(self, clock)
    assert((type(clock) == "number"), "clock must be a positive number or 0")
    self.initial = (self.initial or copy_tables({}, self.target, self.subject))
    self.clock = clock
    if (self.clock <= 0) then
      self.clock = 0
      copy_tables(self.subject, self.initial)
    elseif (self.clock >= self.duration) then
      self.clock = self.duration
      copy_tables(self.subject, self.target)
    else
      perform_easing_on_subject(self.subject, self.target, self.initial, self.clock, self.duration, self.easing)
    end
    return (self.clock >= self.duration)
  end
  Tween.status = function(self)
    if (self.clock < self.duration) then
      return "running"
    else
      return "finished"
    end
  end
  Tween.reset = function(self)
    return self:set(0)
  end
  Tween.update = function(self, dt)
    assert((type(dt) == "number"), "dt must be a number")
    return self:set((self.clock + dt))
  end
  local function new_tween(duration, subject, target, easing0)
    easing0 = get_easing_function(easing0)
    check_new_params(duration, subject, target, easing0)
    return setmetatable({duration = duration, subject = subject, target = target, easing = easing0, clock = 0}, Tween)
  end
  return new_tween
end
package.preload["lutils.timeline"] = package.preload["lutils.timeline"] or function(...)
  local lume = require("lib.lume")
  local create_tween = require("lutils.tween")
  local Timeline = {}
  Timeline.__index = Timeline
  Timeline.cancel = function(self)
    self.cancelled = true
    return nil
  end
  local function wait(duration)
    local timer = 0
    while (timer < duration) do
      local dt = coroutine.yield()
      timer = (timer + dt)
    end
    return nil
  end
  local function tween(duration, subject, target, easing)
    local tw = create_tween(duration, subject, target, easing)
    while (tw:status() == "running") do
      tw:update(coroutine.yield())
    end
    return nil
  end
  Timeline.update = function(self, dt)
    if (self.cancelled or (coroutine.status(self.coro) == "dead")) then
      self.done = true
      return true
    else
      local ok, result = coroutine.resume(self.coro, dt)
      if not ok then
        return error(result)
      else
        return result
      end
    end
  end
  local function timeline(f)
    local coro = coroutine.create(f)
    return setmetatable({coro = coro}, Timeline)
  end
  local function _155_(_241, _242)
    return timeline(_242)
  end
  return setmetatable({wait = wait, tween = tween}, {__call = _155_})
end
package.preload["lutils.spritesheet"] = package.preload["lutils.spritesheet"] or function(...)
  local Spritesheet = {}
  Spritesheet.__index = Spritesheet
  Spritesheet["get-frame-index"] = function(self, p)
    _G.assert((nil ~= p), "Missing argument p on ./lutils/spritesheet.fnl:4")
    _G.assert((nil ~= self), "Missing argument self on ./lutils/spritesheet.fnl:4")
    return (p.x + ((p.y - 1) * (self.width + 1)))
  end
  Spritesheet["get-frame-ix"] = function(self, v)
    _G.assert((nil ~= v), "Missing argument v on ./lutils/spritesheet.fnl:7")
    _G.assert((nil ~= self), "Missing argument self on ./lutils/spritesheet.fnl:7")
    local vtype = type(v)
    if ("table" == vtype) then
      return (v.x + (self.width * (v.y - 1)))
    elseif ("number" == vtype) then
      return v
    else
      return error("unhandled-frame-type")
    end
  end
  Spritesheet.draw = function(self, frame_ix, _3fpos, _3fscale)
    _G.assert((nil ~= frame_ix), "Missing argument frame-ix on ./lutils/spritesheet.fnl:14")
    _G.assert((nil ~= self), "Missing argument self on ./lutils/spritesheet.fnl:14")
    love.graphics.push()
    local function _120_()
      local t_121_ = _3fpos
      if (nil ~= t_121_) then
        t_121_ = (t_121_).x
      else
      end
      return t_121_
    end
    local function _123_()
      local t_124_ = _3fpos
      if (nil ~= t_124_) then
        t_124_ = (t_124_).y
      else
      end
      return t_124_
    end
    love.graphics.translate((_120_() or 0), (_123_() or 0))
    local function _126_()
      local t_127_ = _3fscale
      if (nil ~= t_127_) then
        t_127_ = (t_127_).x
      else
      end
      return t_127_
    end
    local function _129_()
      local t_130_ = _3fscale
      if (nil ~= t_130_) then
        t_130_ = (t_130_).y
      else
      end
      return t_130_
    end
    love.graphics.scale((_126_() or 1), (_129_() or 1))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, self.quads[self["get-frame-ix"](self, frame_ix)], 0, 0, 0, 1, 1)
    return love.graphics.pop()
  end
  local function spritesheet(path, cell_w, cell_h, _3ffilter1, _3ffilter2)
    _G.assert((nil ~= cell_h), "Missing argument cell-h on ./lutils/spritesheet.fnl:22")
    _G.assert((nil ~= cell_w), "Missing argument cell-w on ./lutils/spritesheet.fnl:22")
    _G.assert((nil ~= path), "Missing argument path on ./lutils/spritesheet.fnl:22")
    local img = love.graphics.newImage(path)
    local sheet_w = math.floor((img:getWidth() / cell_w))
    local sheet_h = math.floor((img:getHeight() / cell_w))
    local image_w = img:getWidth()
    local image_h = img:getHeight()
    local quads = {}
    if _3ffilter1 then
      img:setFilter(_3ffilter1, _3ffilter2)
    else
    end
    for y = 0, (sheet_h - 1) do
      for x = 0, (sheet_w - 1) do
        table.insert(quads, love.graphics.newQuad((cell_w * x), (cell_h * y), cell_w, cell_h, image_w, image_h))
      end
    end
    return setmetatable({img = img, quads = quads, path = path, ["cell-width"] = cell_w, ["cell-height"] = cell_h, width = sheet_w, height = sheet_h, frames = #quads}, Spritesheet)
  end
  local MultiImgSpritesheet = {}
  MultiImgSpritesheet.__index = MultiImgSpritesheet
  MultiImgSpritesheet.draw = function(self, frame_ix, _3fpos, _3fscale)
    love.graphics.push()
    local function _133_()
      local t_134_ = _3fpos
      if (nil ~= t_134_) then
        t_134_ = (t_134_).x
      else
      end
      return t_134_
    end
    local function _136_()
      local t_137_ = _3fpos
      if (nil ~= t_137_) then
        t_137_ = (t_137_).y
      else
      end
      return t_137_
    end
    love.graphics.translate((_133_() or 0), (_136_() or 0))
    local function _139_()
      local t_140_ = _3fscale
      if (nil ~= t_140_) then
        t_140_ = (t_140_).x
      else
      end
      return t_140_
    end
    local function _142_()
      local t_143_ = _3fscale
      if (nil ~= t_143_) then
        t_143_ = (t_143_).y
      else
      end
      return t_143_
    end
    love.graphics.scale((_139_() or 1), (_142_() or 1))
    love.graphics.draw(self.images[frame_ix])
    return love.graphics.pop()
  end
  local function to_frame_ix_string(i)
    _G.assert((nil ~= i), "Missing argument i on ./lutils/spritesheet.fnl:59")
    local s = tostring(i)
    while (#s < 4) do
      s = ("0" .. s)
    end
    return s
  end
  local function multi_img_spritesheet(base_path, start, _end)
    local tbl = setmetatable({images = {}}, MultiImgSpritesheet)
    for i = start, _end do
      local img = love.graphics.newImage((base_path .. to_frame_ix_string(i) .. ".png"))
      table.insert(tbl.images, img)
    end
    return tbl
  end
  return {spritesheet = spritesheet, ["multi-img-spritesheet"] = multi_img_spritesheet}
end
package.preload["lutils.input"] = package.preload["lutils.input"] or function(...)
  local last_state = {}
  local state = {}
  local function copy_state()
    for k, v in pairs(state) do
      last_state[k] = v
    end
    return nil
  end
  local function update()
    copy_state()
    state.mouse = love.mouse.isDown(1)
    return nil
  end
  local function mouse_down_3f()
    return state.mouse
  end
  local function mouse_pressed_3f()
    return (not last_state.mouse and state.mouse)
  end
  local function mouse_released_3f()
    return (last_state.mouse and not state.mouse)
  end
  return {["mouse-pressed?"] = mouse_pressed_3f, ["mouse-released?"] = mouse_released_3f, ["mouse-down?"] = mouse_down_3f, update = update}
end
package.preload["lib.lume"] = package.preload["lib.lume"] or function(...)
  --
  -- lume
  --
  -- Copyright (c) 2018 rxi
  --
  -- Permission is hereby granted, free of charge, to any person obtaining a copy of
  -- this software and associated documentation files (the "Software"), to deal in
  -- the Software without restriction, including without limitation the rights to
  -- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  -- of the Software, and to permit persons to whom the Software is furnished to do
  -- so, subject to the following conditions:
  --
  -- The above copyright notice and this permission notice shall be included in all
  -- copies or substantial portions of the Software.
  --
  -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  -- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  -- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  -- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  -- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  -- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  -- SOFTWARE.
  --
  
  local lume = { _version = "2.3.0" }
  
  local pairs, ipairs = pairs, ipairs
  local type, assert, unpack = type, assert, unpack or table.unpack
  local tostring, tonumber = tostring, tonumber
  local math_floor = math.floor
  local math_ceil = math.ceil
  local math_atan2 = math.atan2 or math.atan
  local math_sqrt = math.sqrt
  local math_abs = math.abs
  
  local noop = function()
  end
  
  local identity = function(x)
    return x
  end
  
  local patternescape = function(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  end
  
  local absindex = function(len, i)
    return i < 0 and (len + i + 1) or i
  end
  
  local iscallable = function(x)
    if type(x) == "function" then return true end
    local mt = getmetatable(x)
    return mt and mt.__call ~= nil
  end
  
  local getiter = function(x)
    if lume.isarray(x) then
      return ipairs
    elseif type(x) == "table" then
      return pairs
    end
    error("expected table", 3)
  end
  
  local iteratee = function(x)
    if x == nil then return identity end
    if iscallable(x) then return x end
    if type(x) == "table" then
      return function(z)
        for k, v in pairs(x) do
          if z[k] ~= v then return false end
        end
        return true
      end
    end
    return function(z) return z[x] end
  end
  
  
  
  function lume.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
  end
  
  
  function lume.round(x, increment)
    if increment then return lume.round(x / increment) * increment end
    return x >= 0 and math_floor(x + .5) or math_ceil(x - .5)
  end
  
  
  function lume.sign(x)
    return x < 0 and -1 or 1
  end
  
  
  function lume.lerp(a, b, amount)
    return a + (b - a) * lume.clamp(amount, 0, 1)
  end
  
  
  function lume.smooth(a, b, amount)
    local t = lume.clamp(amount, 0, 1)
    local m = t * t * (3 - 2 * t)
    return a + (b - a) * m
  end
  
  
  function lume.pingpong(x)
    return 1 - math_abs(1 - x % 2)
  end
  
  
  function lume.distance(x1, y1, x2, y2, squared)
    local dx = x1 - x2
    local dy = y1 - y2
    local s = dx * dx + dy * dy
    return squared and s or math_sqrt(s)
  end
  
  
  function lume.angle(x1, y1, x2, y2)
    return math_atan2(y2 - y1, x2 - x1)
  end
  
  
  function lume.vector(angle, magnitude)
    return math.cos(angle) * magnitude, math.sin(angle) * magnitude
  end
  
  
  function lume.random(a, b)
    if not a then a, b = 0, 1 end
    if not b then b = 0 end
    return a + math.random() * (b - a)
  end
  
  
  function lume.randomchoice(t)
    return t[math.random(#t)]
  end
  
  
  function lume.weightedchoice(t)
    local sum = 0
    for _, v in pairs(t) do
      assert(v >= 0, "weight value less than zero")
      sum = sum + v
    end
    assert(sum ~= 0, "all weights are zero")
    local rnd = lume.random(sum)
    for k, v in pairs(t) do
      if rnd < v then return k end
      rnd = rnd - v
    end
  end
  
  
  function lume.isarray(x)
    return type(x) == "table" and x[1] ~= nil
  end
  
  
  function lume.push(t, ...)
    local n = select("#", ...)
    for i = 1, n do
      t[#t + 1] = select(i, ...)
    end
    return ...
  end
  
  
  function lume.remove(t, x)
    local iter = getiter(t)
    for i, v in iter(t) do
      if v == x then
        if lume.isarray(t) then
          table.remove(t, i)
          break
        else
          t[i] = nil
          break
        end
      end
    end
    return x
  end
  
  
  function lume.clear(t)
    local iter = getiter(t)
    for k in iter(t) do
      t[k] = nil
    end
    return t
  end
  
  
  function lume.extend(t, ...)
    for i = 1, select("#", ...) do
      local x = select(i, ...)
      if x then
        for k, v in pairs(x) do
          t[k] = v
        end
      end
    end
    return t
  end
  
  
  function lume.shuffle(t)
    local rtn = {}
    for i = 1, #t do
      local r = math.random(i)
      if r ~= i then
        rtn[i] = rtn[r]
      end
      rtn[r] = t[i]
    end
    return rtn
  end
  
  
  function lume.sort(t, comp)
    local rtn = lume.clone(t)
    if comp then
      if type(comp) == "string" then
        table.sort(rtn, function(a, b) return a[comp] < b[comp] end)
      else
        table.sort(rtn, comp)
      end
    else
      table.sort(rtn)
    end
    return rtn
  end
  
  
  function lume.array(...)
    local t = {}
    for x in ... do t[#t + 1] = x end
    return t
  end
  
  
  function lume.each(t, fn, ...)
    local iter = getiter(t)
    if type(fn) == "string" then
      for _, v in iter(t) do v[fn](v, ...) end
    else
      for _, v in iter(t) do fn(v, ...) end
    end
    return t
  end
  
  
  function lume.map(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    local rtn = {}
    for k, v in iter(t) do rtn[k] = fn(v) end
    return rtn
  end
  
  
  function lume.all(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for _, v in iter(t) do
      if not fn(v) then return false end
    end
    return true
  end
  
  
  function lume.any(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for _, v in iter(t) do
      if fn(v) then return true end
    end
    return false
  end
  
  
  function lume.reduce(t, fn, first)
    local acc = first
    local started = first and true or false
    local iter = getiter(t)
    for _, v in iter(t) do
      if started then
        acc = fn(acc, v)
      else
        acc = v
        started = true
      end
    end
    assert(started, "reduce of an empty table with no first value")
    return acc
  end
  
  
  function lume.unique(t)
    local rtn = {}
    for k in pairs(lume.invert(t)) do
      rtn[#rtn + 1] = k
    end
    return rtn
  end
  
  
  function lume.filter(t, fn, retainkeys)
     
    fn = iteratee(fn)
    local iter = getiter(t)
    local rtn = {}
    if retainkeys then
      for k, v in iter(t) do
        if fn(v) then rtn[k] = v end
      end
    else
      for _, v in iter(t) do
        if fn(v) then rtn[#rtn + 1] = v end
      end
    end
    return rtn
  end
  
  
  function lume.reject(t, fn, retainkeys)
    fn = iteratee(fn)
    local iter = getiter(t)
    local rtn = {}
    if retainkeys then
      for k, v in iter(t) do
        if not fn(v) then rtn[k] = v end
      end
    else
      for _, v in iter(t) do
        if not fn(v) then rtn[#rtn + 1] = v end
      end
    end
    return rtn
  end
  
  
  function lume.merge(...)
    local rtn = {}
    for i = 1, select("#", ...) do
      local t = select(i, ...)
      local iter = getiter(t)
      for k, v in iter(t) do
        rtn[k] = v
      end
    end
    return rtn
  end
  
  
  function lume.concat(...)
    local rtn = {}
    for i = 1, select("#", ...) do
      local t = select(i, ...)
      if t ~= nil then
        local iter = getiter(t)
        for _, v in iter(t) do
          rtn[#rtn + 1] = v
        end
      end
    end
    return rtn
  end
  
  
  function lume.find(t, value)
    local iter = getiter(t)
    for k, v in iter(t) do
      if v == value then return k end
    end
    return nil
  end
  
  
  function lume.match(t, fn)
    fn = iteratee(fn)
    local iter = getiter(t)
    for k, v in iter(t) do
      if fn(v) then return v, k end
    end
    return nil
  end
  
  
  function lume.count(t, fn)
    local count = 0
    local iter = getiter(t)
    if fn then
      fn = iteratee(fn)
      for _, v in iter(t) do
        if fn(v) then count = count + 1 end
      end
    else
      if lume.isarray(t) then
        return #t
      end
      for _ in iter(t) do count = count + 1 end
    end
    return count
  end
  
  
  function lume.slice(t, i, j)
    i = i and absindex(#t, i) or 1
    j = j and absindex(#t, j) or #t
    local rtn = {}
    for x = i < 1 and 1 or i, j > #t and #t or j do
      rtn[#rtn + 1] = t[x]
    end
    return rtn
  end
  
  
  function lume.first(t, n)
    if not n then return t[1] end
    return lume.slice(t, 1, n)
  end
  
  
  function lume.last(t, n)
    if not n then return t[#t] end
    return lume.slice(t, -n, -1)
  end
  
  
  function lume.invert(t)
    local rtn = {}
    for k, v in pairs(t) do rtn[v] = k end
    return rtn
  end
  
  
  function lume.pick(t, ...)
    local rtn = {}
    for i = 1, select("#", ...) do
      local k = select(i, ...)
      rtn[k] = t[k]
    end
    return rtn
  end
  
  
  function lume.keys(t)
    local rtn = {}
    local iter = getiter(t)
    for k in iter(t) do rtn[#rtn + 1] = k end
    return rtn
  end
  
  
  function lume.clone(t)
    local rtn = {}
    for k, v in pairs(t) do rtn[k] = v end
    return rtn
  end
  
  
  function lume.fn(fn, ...)
    assert(iscallable(fn), "expected a function as the first argument")
    local args = { ... }
    return function(...)
      local a = lume.concat(args, { ... })
      return fn(unpack(a))
    end
  end
  
  
  function lume.once(fn, ...)
    local f = lume.fn(fn, ...)
    local done = false
    return function(...)
      if done then return end
      done = true
      return f(...)
    end
  end
  
  
  local memoize_fnkey = {}
  local memoize_nil = {}
  
  function lume.memoize(fn)
    local cache = {}
    return function(...)
      local c = cache
      for i = 1, select("#", ...) do
        local a = select(i, ...) or memoize_nil
        c[a] = c[a] or {}
        c = c[a]
      end
      c[memoize_fnkey] = c[memoize_fnkey] or {fn(...)}
      return unpack(c[memoize_fnkey])
    end
  end
  
  
  function lume.combine(...)
    local n = select('#', ...)
    if n == 0 then return noop end
    if n == 1 then
      local fn = select(1, ...)
      if not fn then return noop end
      assert(iscallable(fn), "expected a function or nil")
      return fn
    end
    local funcs = {}
    for i = 1, n do
      local fn = select(i, ...)
      if fn ~= nil then
        assert(iscallable(fn), "expected a function or nil")
        funcs[#funcs + 1] = fn
      end
    end
    return function(...)
      for _, f in ipairs(funcs) do f(...) end
    end
  end
  
  
  function lume.call(fn, ...)
    if fn then
      return fn(...)
    end
  end
  
  
  function lume.time(fn, ...)
    local start = os.clock()
    local rtn = {fn(...)}
    return (os.clock() - start), unpack(rtn)
  end
  
  
  local lambda_cache = {}
  
  function lume.lambda(str)
    if not lambda_cache[str] then
      local args, body = str:match([[^([%w,_ ]-)%->(.-)$]])
      assert(args and body, "bad string lambda")
      local s = "return function(" .. args .. ")\nreturn " .. body .. "\nend"
      lambda_cache[str] = lume.dostring(s)
    end
    return lambda_cache[str]
  end
  
  
  local serialize
  
  local serialize_map = {
    [ "boolean" ] = tostring,
    [ "nil"     ] = tostring,
    [ "string"  ] = function(v) return string.format("%q", v) end,
    [ "number"  ] = function(v)
      if      v ~=  v     then return  "0/0"      --  nan
      elseif  v ==  1 / 0 then return  "1/0"      --  inf
      elseif  v == -1 / 0 then return "-1/0" end  -- -inf
      return tostring(v)
    end,
    [ "table"   ] = function(t, stk)
      stk = stk or {}
      if stk[t] then error("circular reference") end
      local rtn = {}
      stk[t] = true
      for k, v in pairs(t) do
        rtn[#rtn + 1] = "[" .. serialize(k, stk) .. "]=" .. serialize(v, stk)
      end
      stk[t] = nil
      return "{" .. table.concat(rtn, ",") .. "}"
    end
  }
  
  setmetatable(serialize_map, {
    __index = function(_, k) error("unsupported serialize type: " .. k) end
  })
  
  serialize = function(x, stk)
    return serialize_map[type(x)](x, stk)
  end
  
  function lume.serialize(x)
    return serialize(x)
  end
  
  
  function lume.deserialize(str)
    return lume.dostring("return " .. str)
  end
  
  
  function lume.split(str, sep)
    if not sep then
      return lume.array(str:gmatch("([%S]+)"))
    else
      assert(sep ~= "", "empty separator")
      local psep = patternescape(sep)
      return lume.array((str..sep):gmatch("(.-)("..psep..")"))
    end
  end
  
  
  function lume.trim(str, chars)
    if not chars then return str:match("^[%s]*(.-)[%s]*$") end
    chars = patternescape(chars)
    return str:match("^[" .. chars .. "]*(.-)[" .. chars .. "]*$")
  end
  
  
  function lume.wordwrap(str, limit)
    limit = limit or 72
    local check
    if type(limit) == "number" then
      check = function(s) return #s >= limit end
    else
      check = limit
    end
    local rtn = {}
    local line = ""
    for word, spaces in str:gmatch("(%S+)(%s*)") do
      local s = line .. word
      if check(s) then
        table.insert(rtn, line .. "\n")
        line = word
      else
        line = s
      end
      for c in spaces:gmatch(".") do
        if c == "\n" then
          table.insert(rtn, line .. "\n")
          line = ""
        else
          line = line .. c
        end
      end
    end
    table.insert(rtn, line)
    return table.concat(rtn)
  end
  
  
  function lume.format(str, vars)
    if not vars then return str end
    local f = function(x)
      return tostring(vars[x] or vars[tonumber(x)] or "{" .. x .. "}")
    end
    return (str:gsub("{(.-)}", f))
  end
  
  
  function lume.trace(...)
    local info = debug.getinfo(2, "Sl")
    local t = { info.short_src .. ":" .. info.currentline .. ":" }
    for i = 1, select("#", ...) do
      local x = select(i, ...)
      if type(x) == "number" then
        x = string.format("%g", lume.round(x, .01))
      end
      t[#t + 1] = tostring(x)
    end
    print(table.concat(t, " "))
  end
  
  
  function lume.dostring(str)
    return assert((loadstring or load)(str))()
  end
  
  
  function lume.uuid()
    local fn = function(x)
      local r = math.random(16) - 1
      r = (x == "x") and (r + 1) or (r % 4) + 9
      return ("0123456789abcdef"):sub(r, r)
    end
    return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
  end
  
  
  function lume.hotswap(modname)
    local oldglobal = lume.clone(_G)
    local updated = {}
    local function update(old, new)
      if updated[old] then return end
      updated[old] = true
      local oldmt, newmt = getmetatable(old), getmetatable(new)
      if oldmt and newmt then update(oldmt, newmt) end
      for k, v in pairs(new) do
        if type(v) == "table" then update(old[k], v) else old[k] = v end
      end
    end
    local err = nil
    local function onerror(e)
      for k in pairs(_G) do _G[k] = oldglobal[k] end
      err = lume.trim(e)
    end
    local ok, oldmod = pcall(require, modname)
    oldmod = ok and oldmod or nil
    xpcall(function()
      package.loaded[modname] = nil
      local newmod = require(modname)
      if type(oldmod) == "table" then update(oldmod, newmod) end
      for k, v in pairs(oldglobal) do
        if v ~= _G[k] and type(v) == "table" then
          update(v, _G[k])
          _G[k] = v
        end
      end
    end, onerror)
    package.loaded[modname] = oldmod
    if err then return nil, err end
    return oldmod
  end
  
  
  local ripairs_iter = function(t, i)
    i = i - 1
    local v = t[i]
    if v ~= nil then 
      return i, v
    end
  end
  
  function lume.ripairs(t)
    return ripairs_iter, t, (#t + 1)
  end
  
  
  function lume.color(str, mul)
    mul = mul or 1
    local r, g, b, a
    r, g, b = str:match("#(%x%x)(%x%x)(%x%x)")
    if r then
      r = tonumber(r, 16) / 0xff
      g = tonumber(g, 16) / 0xff
      b = tonumber(b, 16) / 0xff
      a = 1
    elseif str:match("rgba?%s*%([%d%s%.,]+%)") then
      local f = str:gmatch("[%d.]+")
      r = (f() or 0) / 0xff
      g = (f() or 0) / 0xff
      b = (f() or 0) / 0xff
      a = f() or 1
    else
      error(("bad color string '%s'"):format(str))
    end
    return r * mul, g * mul, b * mul, a * mul
  end
  
  
  local chain_mt = {}
  chain_mt.__index = lume.map(lume.filter(lume, iscallable, true),
    function(fn)
      return function(self, ...)
        self._value = fn(self._value, ...)
        return self
      end
    end)
  chain_mt.__index.result = function(x) return x._value end
  
  function lume.chain(value)
    return setmetatable({ _value = value }, chain_mt)
  end
  
  setmetatable(lume,  {
    __call = function(_, ...)
      return lume.chain(...)
    end
  })
  
  
  return lume
end
package.preload["lutils.imgui"] = package.preload["lutils.imgui"] or function(...)
  local lume = require("lib.lume")
  local _local_81_ = require("lutils.vector")
  local vec = _local_81_["vec"]
  local polar_vec2 = _local_81_["polar-vec2"]
  local aabb = require("lutils.aabb")
  local layout_stack = {}
  local function peek_layout_stack()
    return layout_stack[1]
  end
  local function push_layout_stack(item)
    _G.assert((nil ~= item), "Missing argument item on ./lutils/imgui.fnl:8")
    return table.insert(layout_stack, 1, item)
  end
  local function pop_layout_stack()
    return table.remove(layout_stack, 1)
  end
  local function get_layout_rect(context)
    _G.assert((nil ~= context), "Missing argument context on ./lutils/imgui.fnl:11")
    return aabb(context.position, context.size)
  end
  local function expand_props(_3ftbl)
    return lume.merge({display = "absolute", direction = "left", padding = vec(0, 0), flex = 1, ["flex-direction"] = "row"}, (_3ftbl or {}))
  end
  local function clean_children(_3fchildren)
    if (not _3fchildren or (_3fchildren == "nil")) then
      return {}
    else
      return _3fchildren
    end
  end
  local function render_display_absolute(render_f, props, _3fchildren)
    _G.assert((nil ~= props), "Missing argument props on ./lutils/imgui.fnl:26")
    _G.assert((nil ~= render_f), "Missing argument render-f on ./lutils/imgui.fnl:26")
    local context = peek_layout_stack()
    for _, itm in ipairs(clean_children(_3fchildren)) do
      if itm then
        local _let_83_ = itm
        local cf = _let_83_[1]
        local _3fcp = _let_83_[2]
        local _3fcc = _let_83_[3]
        local function _84_()
          local _86_
          do
            local t_85_ = _3fcp
            if (nil ~= t_85_) then
              t_85_ = (t_85_).position
            else
            end
            _86_ = t_85_
          end
          if _86_ then
            if ("string" == type(_3fcp.position)) then
              return get_layout_rect(context)[_3fcp.position]
            else
              return _3fcp.position
            end
          else
            return nil
          end
        end
        push_layout_stack({size = context.size, position = (context.position + (_84_() or vec(0, 0)))})
        render_f(cf, _3fcp, _3fcc)
        pop_layout_stack()
      else
      end
    end
    return nil
  end
  local function render_display_flex(render_f, props, _3fchildren)
    _G.assert((nil ~= props), "Missing argument props on ./lutils/imgui.fnl:43")
    _G.assert((nil ~= render_f), "Missing argument render-f on ./lutils/imgui.fnl:43")
    local root_context = peek_layout_stack()
    local nchildren = #(_3fchildren or {})
    local width = (root_context.size.x / nchildren)
    local height = (root_context.size.y / nchildren)
    local offset
    do
      local _91_ = props["flex-direction"]
      if (_91_ == "row") then
        offset = vec(( - width), 0)
      elseif (_91_ == "column") then
        offset = vec(0, ( - height))
      else
        offset = nil
      end
    end
    local position = (root_context.position + offset)
    local function _93_()
      if (not _3fchildren or ("table" ~= type(_3fchildren))) then
        return {}
      else
        return _3fchildren
      end
    end
    for _, itm in ipairs(_93_()) do
      if itm then
        local _let_94_ = itm
        local cf = _let_94_[1]
        local _3fcp = _let_94_[2]
        local _3fcc = _let_94_[3]
        local context = peek_layout_stack()
        local rect = get_layout_rect(context)
        local function _96_()
          local _95_ = props["flex-direction"]
          if (_95_ == "row") then
            return vec(width, 0)
          elseif (_95_ == "column") then
            return vec(0, height)
          elseif true then
            local _0 = _95_
            return error("Invalid flex-direction")
          else
            return nil
          end
        end
        position = (position + _96_())
        local _99_
        do
          local _98_ = props["flex-direction"]
          if (_98_ == "row") then
            _99_ = vec(width, context.size.y)
          elseif (_98_ == "column") then
            _99_ = vec(context.size.x, height)
          elseif true then
            local _0 = _98_
            _99_ = error("Invalid flex-direction")
          else
            _99_ = nil
          end
        end
        push_layout_stack({size = _99_, position = position})
        render_f(cf, _3fcp, _3fcc)
      else
      end
    end
    return nil
  end
  local function render_display_stack(render_f, props, _3fchildren)
    _G.assert((nil ~= props), "Missing argument props on ./lutils/imgui.fnl:73")
    _G.assert((nil ~= render_f), "Missing argument render-f on ./lutils/imgui.fnl:73")
    local root_context = peek_layout_stack()
    local offset
    do
      local _105_ = props["content-start"]
      if (_105_ == "top-right") then
        offset = (root_context.size * vec(1, 0))
      elseif true then
        local _ = _105_
        offset = vec(0, 0)
      else
        offset = nil
      end
    end
    for _, itm in ipairs((_3fchildren or {})) do
      if itm then
        local _let_107_ = itm
        local cf = _let_107_[1]
        local _3fcp = _let_107_[2]
        local _3fcc = _let_107_[3]
        local context = peek_layout_stack()
        local rect = get_layout_rect(context)
        local _let_108_ = render_f(cf, _3fcp, _3fcc)
        local child_size = _let_108_["size"]
        local function _110_()
          local _109_ = props.direction
          if (_109_ == "left") then
            return vec(( - child_size.x), 0)
          elseif (_109_ == "right") then
            return vec(child_size.x, 0)
          elseif (_109_ == "up") then
            return vec(0, ( - child_size.y))
          elseif (_109_ == "down") then
            return vec(0, child_size.y)
          else
            return nil
          end
        end
        push_layout_stack({size = context.size, position = (context.position + _110_())})
      else
      end
    end
    return nil
  end
  local function render_layout_node(f, _3fprops, _3fchildren)
    _G.assert((nil ~= f), "Missing argument f on ./lutils/imgui.fnl:94")
    local props = expand_props(_3fprops)
    local context = peek_layout_stack()
    local new_context = {position = (context.position + props.padding), size = ((props.size or context.size) - (props.padding * 2))}
    f(new_context, props)
    push_layout_stack(new_context)
    do
      local draw_f
      do
        local _113_ = props
        if ((_G.type(_113_) == "table") and ((_113_).display == "absolute")) then
          draw_f = render_display_absolute
        elseif ((_G.type(_113_) == "table") and ((_113_).display == "stack")) then
          draw_f = render_display_stack
        elseif ((_G.type(_113_) == "table") and ((_113_).display == "flex")) then
          draw_f = render_display_flex
        else
          draw_f = nil
        end
      end
      draw_f(render_layout_node, props, _3fchildren)
      for i = 1, #(_3fchildren or {}) do
        pop_layout_stack()
      end
    end
    return pop_layout_stack()
  end
  local function layout(f, _3fprops, _3fchildren)
    _G.assert((nil ~= f), "Missing argument f on ./lutils/imgui.fnl:112")
    if not peek_layout_stack() then
      local px, py = love.graphics.transformPoint(0, 0)
      local function _115_()
        local t_116_ = _3fprops
        if (nil ~= t_116_) then
          t_116_ = (t_116_).size
        else
        end
        return t_116_
      end
      push_layout_stack({position = vec(px, py), size = (_115_() or vec(love.graphics.getWidth(love.graphics.getHeight())))})
    else
    end
    return render_layout_node(f, _3fprops, _3fchildren)
  end
  return {layout = layout, ["get-layout-rect"] = get_layout_rect, ["peek-layout-stack"] = peek_layout_stack, ["push-layout-stack"] = push_layout_stack, ["pop-layout-stack"] = pop_layout_stack}
end
package.preload["lutils.graphics"] = package.preload["lutils.graphics"] or function(...)
  local _local_65_ = require("lutils.color")
  local rgba = _local_65_["rgba"]
  local _local_66_ = require("lutils.vector")
  local vec = _local_66_["vec"]
  local function set_color(color_3f)
    local function _67_()
      if color_3f then
        return color_3f:serialize()
      else
        return {1, 1, 1, 1}
      end
    end
    return love.graphics.setColor(unpack(_67_()))
  end
  local function line(p1, p2, line_width_3f, color_3f)
    set_color(color_3f)
    love.graphics.setLineWidth((line_width_3f or 1))
    love.graphics.setLineStyle("rough")
    return love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  end
  local function polyline(line_width_3f, color_3f, points)
    set_color(color_3f)
    love.graphics.setLineWidth((line_width_3f or 1))
    love.graphics.setLineStyle("rough")
    local pts = {}
    for _, p in ipairs(points) do
      table.insert(pts, p.x)
      table.insert(pts, p.y)
    end
    return love.graphics.line(pts)
  end
  local function dashed_line(p1, p2, dash_size, gap_size, line_width)
    if line_width then
      love.graphics.setLineWidth(line_width)
    else
    end
    local dx, dy = (p2.x - p1.x), (p2.y - p1.y)
    local an, st = math.atan2(dy, dx), (dash_size + gap_size)
    local len = math.sqrt(((dx * dx) + (dy * dy)))
    local nm = ((len - dash_size) / st)
    love.graphics.push()
    love.graphics.translate(p1.x, p1.y)
    love.graphics.rotate(an)
    for i = 0, nm, 1 do
      love.graphics.line((i * st), 0, ((i * st) + dash_size), 0)
    end
    love.graphics.line((nm * st), 0, ((nm * st) + dash_size), 0)
    return love.graphics.pop()
  end
  local function dashed_rectangle(position, size, dash_size, gap_size, line_width, color_3f)
    set_color(color_3f)
    dashed_line(position, (position + vec(size.x, 0)), dash_size, gap_size, line_width)
    dashed_line(position, (position + vec(0, size.y)), dash_size, gap_size, line_width)
    dashed_line((position + vec(size.x, 0)), (position + vec(size.x, size.y)), dash_size, gap_size, line_width)
    return dashed_line((position + vec(0, size.y)), (position + vec(size.x, size.y)), dash_size, gap_size, line_width)
  end
  local function _print(text, font, position, color_3f, _3fr, _3fscale)
    set_color(color_3f)
    love.graphics.push()
    local s = (_3fscale or vec(1, 1))
    love.graphics.translate(position.x, position.y)
    love.graphics.scale(s.x, s.y)
    love.graphics.print(text, font.font, 0, 0, (_3fr or 0))
    return love.graphics.pop()
  end
  local function print_centered(text, font, position, color_3f, r, scale_3f)
    set_color(color_3f)
    local lines = {}
    for s, _ in string.gmatch(text, "[^#]+") do
      table.insert(lines, s)
    end
    local scale = (scale_3f or vec(1, 1))
    local height = (scale.y * #lines * font.h)
    local half_height = (height / 2)
    local start_y = (position.y - half_height)
    for ix, s in ipairs(lines) do
      local y = (start_y + ((ix - 1) * font.h * scale.y))
      local sc = (scale_3f or vec(1, 1))
      love.graphics.push()
      love.graphics.translate(position.x, y)
      love.graphics.scale(sc.x, sc.y)
      love.graphics.print(s, font.font, 0, 0, 0, 1, 1, (font:get_text_width(s) / 2), 0)
      love.graphics.pop()
    end
    return nil
  end
  local function print_centered_dropshadow(text, font, position, color_3f, shadow_color_3f, r, scale_3f, shadow_dist_3f)
    print_centered(text, font, (position - (shadow_dist_3f or vec(1, -1))), (shadow_color_3f or rgba(0, 0, 0, 1)), r, scale_3f)
    return print_centered(text, font, position, color_3f, r, scale_3f)
  end
  local function stroke_rectangle(pos, sz, width_3f, color_3f, _3fr, _3fangle)
    set_color(color_3f)
    love.graphics.setLineWidth((width_3f or 1))
    return love.graphics.rectangle("line", pos.x, pos.y, sz.x, sz.y, _3fr, _3fangle)
  end
  local function rectangle(pos, sz, color_3f, _3fr, _3fangle)
    set_color(color_3f)
    return love.graphics.rectangle("fill", pos.x, pos.y, sz.x, sz.y, _3fr, _3fangle)
  end
  local function polygon(points, color_3f)
    set_color(color_3f)
    local pts = {}
    for _, p in ipairs(points) do
      table.insert(pts, p.x)
      table.insert(pts, p.y)
    end
    return love.graphics.polygon("fill", unpack(pts))
  end
  local function circle(pos, r, color_3f)
    set_color(color_3f)
    return love.graphics.circle("fill", pos.x, pos.y, r)
  end
  local function stroke_circle(pos, r, width_3f, color_3f)
    set_color(color_3f)
    love.graphics.setLineWidth((width_3f or 1))
    return love.graphics.circle("line", pos.x, pos.y, r)
  end
  local function image(img, _3fpos, _3fscale, _3ftint, _3frotation)
    set_color(_3ftint)
    local s = (_3fscale or vec(1, 1))
    local function _69_()
      local t_70_ = _3fpos
      if (nil ~= t_70_) then
        t_70_ = (t_70_).x
      else
      end
      return t_70_
    end
    local function _72_()
      local t_73_ = _3fpos
      if (nil ~= t_73_) then
        t_73_ = (t_73_).y
      else
      end
      return t_73_
    end
    return love.graphics.draw(img.img, ((_69_() or 0) - (0.5 * s.x * img.width)), ((_72_() or 0) - (0.5 * s.y * img.height)), (_3frotation or 0), s.x, s.y)
  end
  local function image_sz(img, size, _3fpos, _3ftint)
    _G.assert((nil ~= size), "Missing argument size on ./lutils/graphics.fnl:115")
    _G.assert((nil ~= img), "Missing argument img on ./lutils/graphics.fnl:115")
    set_color(_3ftint)
    local sx = (size.x / img.width)
    local sy = (size.y / img.height)
    local function _75_()
      local t_76_ = _3fpos
      if (nil ~= t_76_) then
        t_76_ = (t_76_).x
      else
      end
      return t_76_
    end
    local function _78_()
      local t_79_ = _3fpos
      if (nil ~= t_79_) then
        t_79_ = (t_79_).y
      else
      end
      return t_79_
    end
    return love.graphics.draw(img.img, ((_75_() or 0) - (0.5 * size.x)), ((_78_() or 0) - (0.5 * size.y)), 0, sx, sy)
  end
  local function progress_bar(pos, size, v, max, color)
    _G.assert((nil ~= color), "Missing argument color on ./lutils/graphics.fnl:126")
    _G.assert((nil ~= max), "Missing argument max on ./lutils/graphics.fnl:126")
    _G.assert((nil ~= v), "Missing argument v on ./lutils/graphics.fnl:126")
    _G.assert((nil ~= size), "Missing argument size on ./lutils/graphics.fnl:126")
    _G.assert((nil ~= pos), "Missing argument pos on ./lutils/graphics.fnl:126")
    rectangle(pos, size, rgba(1, 0, 0, 1))
    do
      local s = (v / max)
      local sx = (s * size.x)
      rectangle(pos, vec(sx, size.y), color)
    end
    return stroke_rectangle(pos, size, 1, rgba(0, 0, 0, 1))
  end
  return {["dashed-line"] = dashed_line, ["progress-bar"] = progress_bar, ["set-color"] = set_color, ["dashed-rectangle"] = dashed_rectangle, rectangle = rectangle, ["stroke-rectangle"] = stroke_rectangle, image = image, line = line, circle = circle, polygon = polygon, ["image-sz"] = image_sz, ["stroke-circle"] = stroke_circle, ["print-centered"] = print_centered, ["print-centered-dropshadow"] = print_centered_dropshadow, print = _print, polyline = polyline}
end
package.preload["lutils.font"] = package.preload["lutils.font"] or function(...)
  local Font = {}
  Font.__index = Font
  Font.get_text_width = function(self, text)
    return (self.font):getWidth(text)
  end
  Font.get_height = function(self)
    return (self.font):getHeight()
  end
  local function new_font(asset_path, font_size)
    local self = setmetatable({}, Font)
    self.font = love.graphics.newFont(asset_path, font_size)
    do end (self.font):setFilter("nearest", "nearest")
    self.h = (self.font):getHeight()
    return self
  end
  return {["new-font"] = new_font}
end
package.preload["lutils.easing"] = package.preload["lutils.easing"] or function(...)
  local tween = {_VERSION = "tween 2.1.1", _DESCRIPTION = "tweening for lua", _URL = "https://github.com/kikito/tween.lua", _LICENSE = "    MIT LICENSE\n\n    Copyright (c) 2014 Enrique Garc\195\173a Cota, Yuichi Tateno, Emmanuel Oga\n\n    Permission is hereby granted, free of charge, to any person obtaining a\n    copy of this software and associated documentation files (the\n    \"Software\"), to deal in the Software without restriction, including\n    without limitation the rights to use, copy, modify, merge, publish,\n    distribute, sublicense, and/or sell copies of the Software, and to\n    permit persons to whom the Software is furnished to do so, subject to\n    the following conditions:\n\n    The above copyright notice and this permission notice shall be included\n    in all copies or substantial portions of the Software.\n\n    THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS\n    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\n    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\n    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\n    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE\n    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n  "}
  local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin
  local function linear(t, b, c, d)
    return (((c * t) / d) + b)
  end
  local function in_quad(t, b, c, d)
    return ((c * pow((t / d), 2)) + b)
  end
  local function out_quad(t, b, c, d)
    t = (t / d)
    return (((( - c) * t) * (t - 2)) + b)
  end
  local function in_out_quad(t, b, c, d)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((c / 2) * pow(t, 2)) + b)
      return ___antifnl_rtn_1___
    else
    end
    return (((( - c) / 2) * (((t - 1) * (t - 3)) - 1)) + b)
  end
  local function out_in_quad(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_quad((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_quad(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_cubic(t, b, c, d)
    return ((c * pow((t / d), 3)) + b)
  end
  local function out_cubic(t, b, c, d)
    return ((c * (pow(((t / d) - 1), 3) + 1)) + b)
  end
  local function in_out_cubic(t, b, c, d)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((((c / 2) * t) * t) * t) + b)
      return ___antifnl_rtn_1___
    else
    end
    t = (t - 2)
    return (((c / 2) * (((t * t) * t) + 2)) + b)
  end
  local function out_in_cubic(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_cubic((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_cubic(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_quart(t, b, c, d)
    return ((c * pow((t / d), 4)) + b)
  end
  local function out_quart(t, b, c, d)
    return ((( - c) * (pow(((t / d) - 1), 4) - 1)) + b)
  end
  local function in_out_quart(t, b, c, d)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((c / 2) * pow(t, 4)) + b)
      return ___antifnl_rtn_1___
    else
    end
    return (((( - c) / 2) * (pow((t - 2), 4) - 2)) + b)
  end
  local function out_in_quart(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_quart((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_quart(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_quint(t, b, c, d)
    return ((c * pow((t / d), 5)) + b)
  end
  local function out_quint(t, b, c, d)
    return ((c * (pow(((t / d) - 1), 5) + 1)) + b)
  end
  local function in_out_quint(t, b, c, d)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((c / 2) * pow(t, 5)) + b)
      return ___antifnl_rtn_1___
    else
    end
    return (((c / 2) * (pow((t - 2), 5) + 2)) + b)
  end
  local function out_in_quint(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_quint((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_quint(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_sine(t, b, c, d)
    return (((( - c) * cos(((t / d) * (pi / 2)))) + c) + b)
  end
  local function out_sine(t, b, c, d)
    return ((c * sin(((t / d) * (pi / 2)))) + b)
  end
  local function in_out_sine(t, b, c, d)
    return (((( - c) / 2) * (cos(((pi * t) / d)) - 1)) + b)
  end
  local function out_in_sine(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_sine((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_sine(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_expo(t, b, c, d)
    if (t == 0) then
      return b
    else
    end
    return (((c * pow(2, (10 * ((t / d) - 1)))) + b) - (c * 0.001))
  end
  local function out_expo(t, b, c, d)
    if (t == d) then
      local ___antifnl_rtn_1___ = (b + c)
      return ___antifnl_rtn_1___
    else
    end
    return (((c * 1.001) * (( - pow(2, ((( - 10) * t) / d))) + 1)) + b)
  end
  local function in_out_expo(t, b, c, d)
    if (t == 0) then
      return b
    else
    end
    if (t == d) then
      local ___antifnl_rtn_1___ = (b + c)
      return ___antifnl_rtn_1___
    else
    end
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = ((((c / 2) * pow(2, (10 * (t - 1)))) + b) - (c * 0.0005))
      return ___antifnl_rtn_1___
    else
    end
    return ((((c / 2) * 1.0005) * (( - pow(2, (( - 10) * (t - 1)))) + 2)) + b)
  end
  local function out_in_expo(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_expo((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_expo(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function in_circ(t, b, c, d)
    return ((( - c) * (sqrt((1 - pow((t / d), 2))) - 1)) + b)
  end
  local function out_circ(t, b, c, d)
    return ((c * sqrt((1 - pow(((t / d) - 1), 2)))) + b)
  end
  local function in_out_circ(t, b, c, d)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((( - c) / 2) * (sqrt((1 - (t * t))) - 1)) + b)
      return ___antifnl_rtn_1___
    else
    end
    t = (t - 2)
    return (((c / 2) * (sqrt((1 - (t * t))) + 1)) + b)
  end
  local function out_in_circ(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_circ((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_circ(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  local function calculate_pAS(p, a, c, d)
    p, a = (p or (d * 0.3)), (a or 0)
    if (a < abs(c)) then
      local ___antifnl_rtn_1___ = p
      local ___antifnl_rtn_2___ = c
      local ___antifnl_rtn_3___ = (p / 4)
      return ___antifnl_rtn_1___, ___antifnl_rtn_2___, ___antifnl_rtn_3___
    else
    end
    return p, a, ((p / (2 * pi)) * asin((c / a)))
  end
  local function in_elastic(t, b, c, d, a, p)
    local s = nil
    if (t == 0) then
      return b
    else
    end
    t = (t / d)
    if (t == 1) then
      local ___antifnl_rtn_1___ = (b + c)
      return ___antifnl_rtn_1___
    else
    end
    p, a, s = calculate_pAS(p, a, c, d)
    t = (t - 1)
    return (( - ((a * pow(2, (10 * t))) * sin(((((t * d) - s) * (2 * pi)) / p)))) + b)
  end
  local function out_elastic(t, b, c, d, a, p)
    local s = nil
    if (t == 0) then
      return b
    else
    end
    t = (t / d)
    if (t == 1) then
      local ___antifnl_rtn_1___ = (b + c)
      return ___antifnl_rtn_1___
    else
    end
    p, a, s = calculate_pAS(p, a, c, d)
    return ((((a * pow(2, (( - 10) * t))) * sin(((((t * d) - s) * (2 * pi)) / p))) + c) + b)
  end
  local function in_out_elastic(t, b, c, d, a, p)
    local s = nil
    if (t == 0) then
      return b
    else
    end
    t = ((t / d) * 2)
    if (t == 2) then
      local ___antifnl_rtn_1___ = (b + c)
      return ___antifnl_rtn_1___
    else
    end
    p, a, s = calculate_pAS(p, a, c, d)
    t = (t - 1)
    if (t < 0) then
      local ___antifnl_rtn_1___ = ((( - 0.5) * ((a * pow(2, (10 * t))) * sin(((((t * d) - s) * (2 * pi)) / p)))) + b)
      return ___antifnl_rtn_1___
    else
    end
    return (((((a * pow(2, (( - 10) * t))) * sin(((((t * d) - s) * (2 * pi)) / p))) * 0.5) + c) + b)
  end
  local function out_in_elastic(t, b, c, d, a, p)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_elastic((t * 2), b, (c / 2), d, a, p)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_elastic(((t * 2) - d), (b + (c / 2)), (c / 2), d, a, p)
  end
  local function in_back(t, b, c, d, s)
    s = (s or 1.70158)
    t = (t / d)
    return ((((c * t) * t) * (((s + 1) * t) - s)) + b)
  end
  local function out_back(t, b, c, d, s)
    s = (s or 1.70158)
    t = ((t / d) - 1)
    return ((c * (((t * t) * (((s + 1) * t) + s)) + 1)) + b)
  end
  local function in_out_back(t, b, c, d, s)
    s = ((s or 1.70158) * 1.525)
    t = ((t / d) * 2)
    if (t < 1) then
      local ___antifnl_rtn_1___ = (((c / 2) * ((t * t) * (((s + 1) * t) - s))) + b)
      return ___antifnl_rtn_1___
    else
    end
    t = (t - 2)
    return (((c / 2) * (((t * t) * (((s + 1) * t) + s)) + 2)) + b)
  end
  local function out_in_back(t, b, c, d, s)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_back((t * 2), b, (c / 2), d, s)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_back(((t * 2) - d), (b + (c / 2)), (c / 2), d, s)
  end
  local function out_bounce(t, b, c, d)
    t = (t / d)
    if (t < (1 / 2.75)) then
      local ___antifnl_rtn_1___ = ((c * ((7.5625 * t) * t)) + b)
      return ___antifnl_rtn_1___
    else
    end
    if (t < (2 / 2.75)) then
      t = (t - (1.5 / 2.75))
      local ___antifnl_rtn_1___ = ((c * (((7.5625 * t) * t) + 0.75)) + b)
      return ___antifnl_rtn_1___
    elseif (t < (2.5 / 2.75)) then
      t = (t - (2.25 / 2.75))
      local ___antifnl_rtn_1___ = ((c * (((7.5625 * t) * t) + 0.9375)) + b)
      return ___antifnl_rtn_1___
    else
    end
    t = (t - (2.625 / 2.75))
    return ((c * (((7.5625 * t) * t) + 0.984375)) + b)
  end
  local function in_bounce(t, b, c, d)
    return ((c - out_bounce((d - t), 0, c, d)) + b)
  end
  local function in_out_bounce(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtn_1___ = ((in_bounce((t * 2), 0, c, d) * 0.5) + b)
      return ___antifnl_rtn_1___
    else
    end
    return (((out_bounce(((t * 2) - d), 0, c, d) * 0.5) + (c * 0.5)) + b)
  end
  local function out_in_bounce(t, b, c, d)
    if (t < (d / 2)) then
      local ___antifnl_rtns_1___ = {out_bounce((t * 2), b, (c / 2), d)}
      return (table.unpack or _G.unpack)(___antifnl_rtns_1___)
    else
    end
    return in_bounce(((t * 2) - d), (b + (c / 2)), (c / 2), d)
  end
  return {linear = linear, inQuad = in_quad, outQuad = out_quad, inOutQuad = in_out_quad, outInQuad = out_in_quad, inCubic = in_cubic, outCubic = out_cubic, inOutCubic = in_out_cubic, outInCubic = out_in_cubic, inQuart = in_quart, outQuart = out_quart, inOutQuart = in_out_quart, outInQuart = out_in_quart, inQuint = in_quint, outQuint = out_quint, inOutQuint = in_out_quint, outInQuint = out_in_quint, inSine = in_sine, outSine = out_sine, inOutSine = in_out_sine, outInSine = out_in_sine, inExpo = in_expo, outExpo = out_expo, inOutExpo = in_out_expo, outInExpo = out_in_expo, inCirc = in_circ, outCirc = out_circ, inOutCirc = in_out_circ, outInCirc = out_in_circ, inElastic = in_elastic, outElastic = out_elastic, inOutElastic = in_out_elastic, outInElastic = out_in_elastic, inBack = in_back, outBack = out_back, inOutBack = in_out_back, outInBack = out_in_back, inBounce = in_bounce, outBounce = out_bounce, inOutBounce = in_out_bounce, outInBounce = out_in_bounce}
end
package.preload["lutils.color"] = package.preload["lutils.color"] or function(...)
  local Color = {}
  Color.__index = Color
  Color.lighten = function()
    return nil
  end
  local function rgba(r_3f, g_3f, b_3f, a_3f)
    _G.assert((nil ~= a_3f), "Missing argument a? on ./lutils/color.fnl:26")
    _G.assert((nil ~= b_3f), "Missing argument b? on ./lutils/color.fnl:26")
    _G.assert((nil ~= g_3f), "Missing argument g? on ./lutils/color.fnl:26")
    _G.assert((nil ~= r_3f), "Missing argument r? on ./lutils/color.fnl:26")
    local _25_
    if (type(r_3f) == "number") then
      _25_ = {r = r_3f, g = g_3f, b = b_3f, a = a_3f}
    else
      local _27_
      do
        local t_26_ = r_3f
        if (nil ~= t_26_) then
          t_26_ = (t_26_).r
        else
        end
        _27_ = t_26_
      end
      if _27_ then
        _25_ = {r = r_3f.r, g = r_3f.g, b = r_3f.b, a = r_3f.a}
      else
        local _30_
        do
          local t_29_ = r_3f
          if (nil ~= t_29_) then
            t_29_ = (t_29_)[1]
          else
          end
          _30_ = t_29_
        end
        if _30_ then
          _25_ = {r = (r_3f)[1], g = (r_3f)[2], b = (r_3f)[3], a = (r_3f)[4]}
        else
          _25_ = error("Invalid color arguments")
        end
      end
    end
    return setmetatable(_25_, Color)
  end
  local function parse_hexadecimal_number(str)
    _G.assert((nil ~= str), "Missing argument str on ./lutils/color.fnl:38")
    return tonumber(str, 16)
  end
  local function hexcolor(str)
    _G.assert((nil ~= str), "Missing argument str on ./lutils/color.fnl:39")
    local r = parse_hexadecimal_number(string.sub(str, 1, 2))
    local g = parse_hexadecimal_number(string.sub(str, 3, 4))
    local b = parse_hexadecimal_number(string.sub(str, 5, 6))
    local a = parse_hexadecimal_number(string.sub(str, 7, 8))
    return rgba((r / 255), (g / 255), (b / 255), (a / 255))
  end
  Color["set-alpha"] = function(self, a)
    _G.assert((nil ~= a), "Missing argument a on ./lutils/color.fnl:46")
    _G.assert((nil ~= self), "Missing argument self on ./lutils/color.fnl:46")
    return rgba(self.r, self.g, self.b, a)
  end
  Color.clone = function(self)
    _G.assert((nil ~= self), "Missing argument self on ./lutils/color.fnl:49")
    return rgba(self.r, self.g, self.b, self.a)
  end
  Color.serialize = function(self)
    _G.assert((nil ~= self), "Missing argument self on ./lutils/color.fnl:52")
    return {self.r, self.g, self.b, self.a}
  end
  Color.__tostring = function(self)
    _G.assert((nil ~= self), "Missing argument self on ./lutils/color.fnl:55")
    return string.format("(%d, %d, %d, %d)", self.r, self.g, self.b, self.a)
  end
  return {rgba = rgba, white = rgba(1, 1, 1, 1), black = rgba(0, 0, 0, 1), hexcolor = hexcolor}
end
package.preload["lutils.animation"] = package.preload["lutils.animation"] or function(...)
  local SpritesheetAnimation = {}
  SpritesheetAnimation.__index = SpritesheetAnimation
  SpritesheetAnimation.update = function(self, dt)
    self.timer = (self.timer + dt)
    if (self.timer > self.delay) then
      self.ix = (self.ix + 1)
      self.timer = 0
    else
    end
    if (self.ix > self.options["end"]) then
      if self.options["on-complete"] then
        self.options["on-complete"](self)
      else
      end
      if self.options.loop then
        self.ix = self.options.start
        return nil
      else
        self.done = true
        return nil
      end
    else
      return nil
    end
  end
  SpritesheetAnimation.reset = function(self)
    _G.assert((nil ~= self), "Missing argument self on ./lutils/animation.fnl:15")
    self.ix = self.options.start
    self.timer = 0
    self.done = false
    return nil
  end
  SpritesheetAnimation.draw = function(self, _3fpos, _3fscale)
    if (not self.done or self.options.stay) then
      love.graphics.setColor(unpack(self.options.color))
      local _16_
      if self.done then
        _16_ = self.options["end"]
      else
        _16_ = self.ix
      end
      return (self.spritesheet):draw(_16_, _3fpos, _3fscale)
    else
      return nil
    end
  end
  local function spritesheet_animation(spritesheet, _3foptions)
    local options = lume.merge({loop = false, start = 1, ["end"] = 2, color = {1, 1, 1, 1}, ["on-complete"] = nil, fps = 8}, (_3foptions or {}))
    local delay = (1 / options.fps)
    return setmetatable({timer = 0, ix = options.start, delay = delay, options = options, spritesheet = spritesheet, drawable = true}, SpritesheetAnimation)
  end
  local function make_animation_set(defs)
    local tbl_12_auto = {}
    for k, _19_ in pairs(defs) do
      local _each_20_ = _19_
      local spritesheet = _each_20_[1]
      local start = _each_20_[2]
      local _end = _each_20_[3]
      local options_3f = _each_20_[4]
      local _21_, _22_ = nil, nil
      do
        local options = lume.merge({loop = true, fps = 8}, (options_3f or {}))
        _21_, _22_ = k, spritesheet_animation(spritesheet, {start = start, ["end"] = _end, loop = options.loop, fps = options.fps, color = {1, 1, 1, 1}})
      end
      if ((nil ~= _21_) and (nil ~= _22_)) then
        local k_13_auto = _21_
        local v_14_auto = _22_
        tbl_12_auto[k_13_auto] = v_14_auto
      else
      end
    end
    return tbl_12_auto
  end
  local function animation_set(defs)
    local function _24_(...)
      return make_animation_set(defs, ...)
    end
    return _24_
  end
  return {["spritesheet-animation"] = spritesheet_animation, ["animation-set"] = animation_set}
end
package.preload["lutils.vector"] = package.preload["lutils.vector"] or function(...)
  local Vector2D = {}
  Vector2D.__index = Vector2D
  local Vector3D = {}
  local function _2_()
    return error("TODO: Implement Vector3D")
  end
  Vector3D.__index = _2_
  local Vector4D = {}
  local function _3_()
    return error("TODO: Implement Vector4D")
  end
  Vector4D.__index = _3_
  local function vec(x, y, z_3f, w_3f)
    assert(x, "Must pass at least x and y")
    assert(y, "Must pass at least x and y")
    local function _4_()
      if w_3f then
        return Vector4D
      elseif z_3f then
        return Vector3D
      else
        return Vector2D
      end
    end
    return setmetatable({x = x, y = y, z = z_3f, w = w_3f}, _4_())
  end
  local function polar_vec2(theta, magnitude)
    return vec((math.cos(theta) * magnitude), (math.sin(theta) * magnitude))
  end
  Vector2D.__unm = function(v)
    return vec(( - v.x), ( - v.y))
  end
  Vector2D.__add = function(a, b)
    return vec((a.x + b.x), (a.y + b.y))
  end
  Vector2D.__sub = function(a, b)
    return vec((a.x - b.x), (a.y - b.y))
  end
  Vector2D.__mul = function(a, b)
    if (type(a) == "number") then
      return vec((a * b.x), (a * b.y))
    elseif (type(b) == "number") then
      return vec((a.x * b), (a.y * b))
    else
      return vec((a.x * b.x), (a.y * b.y))
    end
  end
  Vector2D.__div = function(a, b)
    return vec((a.x / b), (a.y / b))
  end
  Vector2D.__eq = function(a, b)
    return ((a.x == b.x) and (a.y == b.y))
  end
  Vector2D.__tostring = function(self)
    return ("(" .. self.x .. ", " .. self.y .. ")")
  end
  Vector2D.floor = function(self)
    return vec(math.floor(self.x), math.floor(self.y))
  end
  Vector2D.clamp = function(self, min, max)
    return vec(math.min(math.max(self.x, min.x), max.x), math.min(math.max(self.y, min.y), max.y))
  end
  Vector2D["clamp!"] = function(self, min, max)
    self.x, self.y = math.min(math.max(self.x, min.x), max.x), math.min(math.max(self.y, min.y), max.y)
    return nil
  end
  Vector2D["distance-to"] = function(a, b)
    return math.sqrt((((a.x - b.x) ^ 2) + ((a.y - b.y) ^ 2)))
  end
  Vector2D["angle-from"] = function(a, b)
    return math.atan2((a.y - b.y), (a.x - b.x))
  end
  Vector2D["angle-to"] = function(a, b)
    return math.atan2((b.y - a.y), (b.x - a.x))
  end
  Vector2D.angle = function(self)
    return math.atan2(self.y, self.x)
  end
  Vector2D["set-angle"] = function(self, angle)
    local len = self:length()
    return vec((math.cos(angle) * len), (math.sin(angle) * len))
  end
  Vector2D["set-angle!"] = function(self, angle)
    local len = self:length()
    self.x, self.y = (math.cos(angle) * len), (math.sin(angle) * len)
    return nil
  end
  Vector2D.rotate = function(self, theta)
    local s = math.sin(theta)
    local c = math.cos(theta)
    return vec(((c * self.x) + (s * self.y)), (( - (s * self.x)) + (c * self.y)))
  end
  Vector2D["rotate!"] = function(self, theta)
    local s = math.sin(theta)
    local c = math.cos(theta)
    return vec(((c * self.x) + (s * self.y)), (( - (s * self.x)) + (c * self.y)))
  end
  Vector2D.unpack = function(self)
    return self.x, self.y
  end
  Vector2D.clone = function(self)
    return vec(self.x, self.y)
  end
  Vector2D.length = function(self)
    return math.sqrt(((self.x ^ 2) + (self.y ^ 2)))
  end
  Vector2D["set-length"] = function(self, len)
    local theta = self:angle()
    return vec((math.cos(theta) * len), (math.sin(theta) * len))
  end
  Vector2D["clamp-length"] = function(self, min, max)
    local l = self:length()
    if (l < min) then
      return self["set-length"](self, min)
    elseif (l > max) then
      return self["set-length"](self, max)
    else
      return self
    end
  end
  Vector2D["clamp-length!"] = function(self, min, max)
    local l = self:length()
    if (l < min) then
      self["set-length!"](self, min)
    elseif (l > max) then
      self["set-length!"](self, max)
    else
    end
    return self
  end
  Vector2D["set-length!"] = function(self, len)
    local theta = self:angle()
    self.x, self.y = (math.cos(theta) * len), (math.sin(theta) * len)
    return nil
  end
  Vector2D.lengthsq = function(self)
    return ((self.x ^ 2) + (self.y ^ 2))
  end
  Vector2D.normalize = function(self)
    local mag = self:length()
    if (mag == 0) then
      return self
    else
      return vec((self.x / mag), (self.y / mag))
    end
  end
  Vector2D["normalize!"] = function(self)
    local mag = self:length()
    if (mag == 0) then
      self.x, self.y = (self.x / mag), (self.y / mag)
      return nil
    else
      return nil
    end
  end
  Vector2D.dot = function(self, v)
    return ((self.x * v.x) + (self.y * v.y))
  end
  Vector2D.limit = function(self, max)
    local magsq = self:lengthsq()
    local theta = self:angle()
    if (magsq > (max ^ 2)) then
      return polar_vec2(theta, max)
    else
      return self
    end
  end
  Vector2D["limit!"] = function(self, max)
    local magsq = self:lengthsq()
    local theta = self:angle()
    if (magsq > (max ^ 2)) then
      self.x, self.y = (math.cos(theta) * max), (math.sin(theta) * max)
      return nil
    else
      return self
    end
  end
  Vector2D.lerp = function(a, b, t)
    return vec(((a.x * (1 - t)) + (b.x * t)), ((a.y * (1 - t)) + (b.y * t)))
  end
  Vector2D["lerp!"] = function(a, b, t)
    a.x, a.y = ((a.x * (1 - t)) + (b.x * t)), ((a.y * (1 - t)) + (b.y * t))
    return nil
  end
  Vector2D.midpoint = function(a, b)
    return ((a + b) / 2)
  end
  return {vec = vec, Vector2D = Vector2D, ["polar-vec2"] = polar_vec2}
end
package.preload["lutils.aabb"] = package.preload["lutils.aabb"] or function(...)
  local _local_1_ = require("lutils.vector")
  local vec = _local_1_["vec"]
  local AABB = {}
  AABB.__index = AABB
  local function aabb(position, size)
    local r = setmetatable({position = position, size = size}, AABB)
    r["init!"](r)
    return r
  end
  AABB.__tostring = function(self)
    return ("AABB [(" .. self.position.x .. ", " .. self.position.y .. ")" .. " " .. "(" .. self.size.x .. ", " .. self.size.y .. ")]")
  end
  AABB["init!"] = function(self)
    return self["calculate-bounds!"](self)
  end
  AABB["calculate-bounds!"] = function(self)
    self.left = self.position.x
    self.top = self.position.y
    self.right = (self.position.x + self.size.x)
    self.bottom = (self.position.y + self.size.y)
    self.center = (self.position + (self.size / 2))
    self["top-left"] = self.position
    self["top-right"] = (self.position + vec(self.size.x, 0))
    self["bottom-left"] = (self.position + vec(0, self.size.y))
    self["bottom-right"] = (self.position + self.size)
    self["left-center"] = vec((self.center.x - (self.size.x / 2)), self.center.y)
    self["right-center"] = vec((self.center.x + (self.size.x / 2)), self.center.y)
    self["top-center"] = vec(self.center.x, (self.center.y - (self.size.y / 2)))
    self["bottom-center"] = vec(self.center.x, (self.center.y + (self.size.y / 2)))
    return nil
  end
  AABB["set-position!"] = function(self, position)
    self.position = position
    return self["calculate-bounds!"](self)
  end
  AABB["set-size!"] = function(self, size)
    self.size = size
    return self["calculate-bounds!"](self)
  end
  AABB["set-left!"] = function(self, left)
    do
      local width_delta = (self.left - left)
      self.position.x = left
      self.size.x = (self.size.x + width_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-right!"] = function(self, right)
    do
      local width_delta = (right - self.right)
      self.size.x = (self.size.x + width_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-top!"] = function(self, top)
    do
      local height_delta = (self.top - top)
      self.position.y = top
      self.size.y = (self.size.y + height_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-bottom!"] = function(self, bottom)
    do
      local height_delta = (bottom - self.bottom)
      self.size.y = (self.size.y + height_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["contains-point?"] = function(self, p)
    return not ((p.x < self.left) or (p.x > self.right) or (p.y < self.top) or (p.y > self.bottom))
  end
  AABB["intersects?"] = function(self, other)
    return not ((self.right < other.left) or (other.right < self.left) or (self.bottom < other.top) or (other.bottom < self.top))
  end
  return aabb
end
return {aabb = require("lutils.aabb"), animation = require("lutils.animation"), color = require("lutils.color"), easing = require("lutils.easing"), font = require("lutils.font"), graphics = require("lutils.graphics"), imgui = require("lutils.imgui"), input = require("lutils.input"), spritesheet = require("lutils.spritesheet"), timeline = require("lutils.timeline"), tween = require("lutils.tween"), vector = require("lutils.vector")}
