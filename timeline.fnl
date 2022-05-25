(local lume (require :lib.lume))

(local create-tween (require :tween))

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

(fn wait-until-next-frame []
  (coroutine.yield))

(fn tween [duration subject target easing]
  (let [tw (create-tween duration subject target easing)]
    (while (= (tw:status) :running)
      (tw:update (coroutine.yield)))))

(fn parallel-tween [...]
  (var tweens
       (icollect [_ args (ipairs [...])]
         (create-tween (unpack args))))
  (while (> (length tweens) 0)
    (let [dt (coroutine.yield)]
      (each [_ tw (ipairs tweens)]
        (if (= (tw:status) :running)
            (tw:update dt)
            (set tweens (lume.filter tweens #(not= $1 tw))))))))

(fn all [timelines]
  (let [completed (accumulate [acc true _ t (ipairs timelines)]
                    (and acc (or (not t) t.done t.destroyed t.cancelled)))]
    (if completed
      true
      (do
        (coroutine.yield)
        (all timelines)))))

; (fn parallel [fns]
;   "Waits until all the timelines are done."
;   (while (accumulate [acc true _ t (ipairs fns)]
;            (and acc (t:update dt)))
;     (coroutine.yield)))

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
   : end
   : wait-until-next-frame 
   : poll-for-state
   : tween
   : parallel-tween
   : all}
   ;: parallel} 
  {:__call #(timeline $2)})
