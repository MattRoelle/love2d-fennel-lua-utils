(local SpritesheetAnimation {})
(set SpritesheetAnimation.__index SpritesheetAnimation)

(fn SpritesheetAnimation.update [self dt]
  (set self.timer (+ self.timer dt))
  (when (> self.timer self.delay)
    (set self.ix (+ self.ix 1))
    (set self.timer 0))
  (when (> self.ix self.options.end)
    (when self.options.on-complete (self.options.on-complete self))
    (if self.options.loop
      (set self.ix self.options.start)
      (set self.done true))))

(λ SpritesheetAnimation.reset [self]
  (set self.ix self.options.start)
  (set self.timer 0)
  (set self.done false))

(fn SpritesheetAnimation.draw [self ?pos ?scale]
  (when (or  (not self.done) self.options.stay)
    (love.graphics.setColor (unpack self.options.color))
    (self.spritesheet:draw (if self.done self.options.end self.ix) ?pos ?scale)))

(fn spritesheet-animation [spritesheet ?options]
  (let [options (lume.merge {:loop false
                             :start 1
                             :end 2
                             :color [1 1 1 1]
                             :on-complete nil
                             :fps 8} (or ?options {}))
        delay (/ 1 options.fps)]
    (setmetatable 
       {:timer 0 
        :ix options.start
        : delay
        : options
        : spritesheet
        :drawable true}
      SpritesheetAnimation)))

(fn make-animation-set [defs]
  (collect [k [spritesheet start end options?] (pairs defs)]
    (let [options (lume.merge {:loop true :fps 8} (or options? {}))]
      (values k (spritesheet-animation spritesheet
                  {: start 
                   : end
                   :loop options.loop
                   :fps options.fps
                   :color [1 1 1 1]})))))

(fn animation-set [defs]
  (partial make-animation-set defs))

{: spritesheet-animation
 : animation-set} 
