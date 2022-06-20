(local {: rgba} (require :color))
(local {: vec} (require :vector))

(fn set-color [color?]
  (love.graphics.setColor
    (unpack (if color?
              (color?:serialize)
              [1 1 1 1]))))

(fn line [p1 p2 line-width? color?]
  (set-color color?)
  (love.graphics.setLineWidth (or line-width? 1))
  (love.graphics.setLineStyle "rough")
  (love.graphics.line p1.x p1.y p2.x p2.y))

(fn polyline [line-width? color? points]
  (set-color color?)
  (love.graphics.setLineWidth (or line-width? 1))
  (love.graphics.setLineStyle "rough")
  (local pts [])
  (each [_ p (ipairs points)]
    (table.insert pts p.x)
    (table.insert pts p.y))
  (love.graphics.line pts))

(fn dashed-line [p1 p2 dash-size gap-size line-width]
  (when line-width (love.graphics.setLineWidth line-width))
  (local (dx dy) (values (- p2.x p1.x) (- p2.y p1.y)))
  (local (an st) (values (math.atan2 dy dx) (+ dash-size gap-size)))
  (local len (math.sqrt (+ (* dx dx) (* dy dy))))
  (local nm (/ (- len dash-size) st))
  (love.graphics.push)
  (love.graphics.translate p1.x p1.y)
  (love.graphics.rotate an)
  (for [i 0 nm 1] (love.graphics.line (* i st) 0 (+ (* i st) dash-size) 0))
  (love.graphics.line (* nm st) 0 (+ (* nm st) dash-size) 0)
  (love.graphics.pop))  

(fn dashed-rectangle [position size dash-size gap-size line-width color?]
  (set-color color?)
  (dashed-line position (+ position (vec size.x 0)) dash-size gap-size line-width)
  (dashed-line position (+ position (vec 0 size.y)) dash-size gap-size line-width)
  (dashed-line (+ position (vec size.x 0)) (+ position (vec size.x size.y)) dash-size gap-size line-width)
  (dashed-line (+ position (vec 0 size.y)) (+ position (vec size.x size.y)) dash-size gap-size line-width))

(fn _print [text font position color? ?r ?scale]
  (set-color color?)
  (love.graphics.push)
  (let [s (or ?scale (vec 1 1))]
    (love.graphics.translate position.x position.y)
    (love.graphics.scale s.x s.y)
    (love.graphics.print text font.font 0 0 (or ?r 0))
    (love.graphics.pop)))

(fn print-centered [text font position color? r scale?]
  (set-color color?)
  (local lines [])
  ;; TODO: figure out why string.gmatch with [^\r\n]+ doesn't work
  (each [s _ (string.gmatch text "[^#]+")]
    (table.insert lines s))
  (let [scale (or scale? (vec 1 1))
        height (* scale.y (length lines) font.h)
        half-height (/ height 2)
        start-y (- position.y half-height)]
    (each [ix s (ipairs lines)]
      (let [y (+ start-y (* (- ix 1) font.h scale.y))
            sc (or scale? (vec 1 1))]
          (love.graphics.push)
          (love.graphics.translate position.x y)
          (love.graphics.scale sc.x sc.y)
          (love.graphics.print s font.font 0 0 0 1 1
                               (+ (/ (font:get_text_width s) 2)) 0)
          (love.graphics.pop)))))

(fn print-centered-dropshadow [text font position color? shadow-color? r scale? shadow-dist?]
  (print-centered text font (- position (or shadow-dist? (vec 1 -1))) (or shadow-color? (rgba 0 0 0 1)) r scale?)
  (print-centered text font position color? r scale?))

(fn stroke-rectangle [pos sz width? color? ?r ?angle]
  (set-color color?)
  (love.graphics.setLineWidth (or width? 1))
  (love.graphics.rectangle :line pos.x pos.y sz.x sz.y ?r ?angle))

(fn rectangle [pos sz color? ?r ?angle]
  (set-color color?)
  (love.graphics.rectangle :fill pos.x pos.y sz.x sz.y ?r ?angle))

(fn polygon [points color?]
  (set-color color?)
  (local pts [])
  (each [_ p (ipairs points)]
    (table.insert pts p.x)
    (table.insert pts p.y))
  (love.graphics.polygon :fill (unpack pts)))

(fn circle [pos r color?]
  (set-color color?)
  (love.graphics.circle :fill pos.x pos.y r))

(fn stroke-circle [pos r width? color?]
  (set-color color?)
  (love.graphics.setLineWidth (or width? 1))
  (love.graphics.circle :line pos.x pos.y r))

(fn image [img ?pos ?scale ?tint ?rotation]
  (set-color ?tint)
  (let [s (or ?scale (vec 1 1))]
    (love.graphics.draw img.img 
                        (- (or (?. ?pos :x) 0)
                           (* 0.5 s.x img.width))
                        (- (or (?. ?pos :y) 0)
                           (* 0.5 s.y img.height))
                        (or ?rotation 0) s.x s.y)))

(λ image-sz [img size ?pos ?tint]
  (set-color ?tint)
  (let [sx (/ size.x img.width)
        sy (/ size.y img.height)]
    (love.graphics.draw img.img 
                        (- (or (?. ?pos :x) 0) (* 0.5 size.x))
                        (- (or (?. ?pos :y) 0) (* 0.5 size.y))
                        0
                        sx
                        sy)))

(λ progress-bar [pos size v max color]
  (rectangle pos size (rgba 1 0 0 1))
  (let [s (/ v max)
        sx (* s size.x)]
    (rectangle pos (vec sx size.y) color))
  (stroke-rectangle pos size 1 (rgba 0 0 0 1)))

{: dashed-line
 : progress-bar
 : set-color
 : dashed-rectangle
 : rectangle 
 : stroke-rectangle 
 : image
 : line
 : circle
 : polygon
 : image-sz
 : stroke-circle
 : print-centered
 : print-centered-dropshadow
 :print _print
 : polyline}
