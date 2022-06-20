(local lume (require :lib.lume))

(local create-tween (require :lutils.tween))

(local Timeline {})
(set Timeline.__index Timeline)

(fn Timeline.cancel [self]
  (set self.cancelled true))

(fn wait [duration]
  "Wait for the given duration."
  (var timer 0)
  (while (< timer duration)
    (let [dt (coroutine.yield)]
      (set timer (+ timer dt)))))

(fn tween [duration subject target easing]
  (let [tw (create-tween duration subject target easing)]
    (while (= (tw:status) :running)
      (tw:update (coroutine.yield)))))

(fn Timeline.update [self dt]
  "Returns a truthy value if the timeline is finished."
  (if (or self.cancelled (= (coroutine.status self.coro) :dead)) 
      (do (set self.done true)
          true)
      (let [(ok result) (coroutine.resume self.coro dt)]
        (if (not ok)
            (error result)
            result))))

(fn timeline [f]
  "Creates a timeline from the given function."
  (let [coro (coroutine.create f)]
    (setmetatable {: coro} Timeline)))

(setmetatable
  {: wait 
   : tween}
  {:__call #(timeline $2)})
