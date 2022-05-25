(local Font {})
(set Font.__index Font)

(fn Font.get_text_width [self text]
  (self.font:getWidth text))

(fn Font.get_height [self]
  (self.font:getHeight))

(fn new-font [asset-path font-size]
  (local self (setmetatable {} Font))
  (set self.font (love.graphics.newFont asset-path font-size))
  (self.font:setFilter :nearest :nearest)
  (set self.h (self.font:getHeight))
  self)

{: new-font}
