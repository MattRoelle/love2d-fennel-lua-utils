(local Spritesheet {})
(set Spritesheet.__index Spritesheet)

(λ Spritesheet.get-frame-index [self p]
  (+ p.x (* (- p.y 1) (+ self.width 1))))

(λ Spritesheet.get-frame-ix [self v]
  (let [vtype (type v)]
    (if (= :table vtype)
        (+ v.x (* self.width (- v.y 1)))
        (= :number vtype)
        v (error :unhandled-frame-type))))

(λ Spritesheet.draw [self frame-ix ?pos ?scale]
  (love.graphics.push)
  (love.graphics.translate (or (?. ?pos :x) 0) (or (?. ?pos :y) 0))
  (love.graphics.scale (or (?. ?scale :x) 1) (or (?. ?scale :y) 1))
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.draw self.img (. self.quads (self:get-frame-ix frame-ix)) 0 0 0 1 1)
  (love.graphics.pop))

(λ spritesheet [path cell-w cell-h ?filter1 ?filter2]
  (let [img (love.graphics.newImage path)
        sheet-w (math.floor (/ (img:getWidth) cell-w))
        sheet-h (math.floor (/ (img:getHeight) cell-w))
        image-w (img:getWidth)
        image-h (img:getHeight)
        quads []]
   (when ?filter1
     (img:setFilter ?filter1 ?filter2))
   (for [y 0 (- sheet-h 1)]
    (for [x 0 (- sheet-w 1)]
     (table.insert quads
                   (love.graphics.newQuad
                    (* cell-w x) (* cell-h y)
                    cell-w cell-h
                    image-w image-h))))
   (setmetatable 
     {: img
      : quads
      : path
      :cell-width cell-w 
      :cell-height cell-h
      :width sheet-w 
      :height sheet-h
      :frames (length quads)}
     Spritesheet)))

(local MultiImgSpritesheet {})
(set MultiImgSpritesheet.__index MultiImgSpritesheet)

(fn MultiImgSpritesheet.draw [self frame-ix ?pos ?scale]
  (love.graphics.push)
  (love.graphics.translate (or (?. ?pos :x) 0) (or (?. ?pos :y) 0))
  (love.graphics.scale (or (?. ?scale :x) 1) (or (?. ?scale :y) 1))
  (love.graphics.draw (. self.images frame-ix))
  (love.graphics.pop))

(λ to-frame-ix-string [i]
  (var s (tostring i))
  (while (< (length s) 4)
    (set s (.. "0" s)))
  s)

(fn multi-img-spritesheet [base-path start end]
  (local tbl (setmetatable {:images []}
                           MultiImgSpritesheet))
  (for [i start end]
    (let [img (love.graphics.newImage (.. base-path (to-frame-ix-string i) :.png))]
     (table.insert tbl.images img)))
  tbl)

{: spritesheet
 : multi-img-spritesheet}
