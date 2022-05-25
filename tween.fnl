;; Transformed kikito/tween.lua to fennel via antifennel and made modifications
(local easing (require :easing))

(local tween {: easing 
              :_VERSION "tween 2.1.1"
              :_DESCRIPTION "tweening for lua"
              :_URL "https://github.com/kikito/tween.lua"
              :_LICENSE "    MIT LICENSE

    Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    \"Software\"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  "})

(fn copy-tables [destination keys-table values-table]
  (set-forcibly! values-table (or values-table keys-table))
  (local mt (getmetatable keys-table))
  (when (and mt (= (getmetatable destination) nil))
    (setmetatable destination mt))
  (each [k v (pairs keys-table)]
    (if (= (type v) :table)
        (tset destination k (copy-tables {} v (. values-table k)))
        (tset destination k (. values-table k))))
  destination)
(fn check-subject-and-target-recursively [subject target path]
  (set-forcibly! path (or path {}))
  (local (target-type new-path) nil)
  (each [k target-value (pairs target)]
    (set-forcibly! (target-type new-path)
                   (values (type target-value) (copy-tables {} path)))
    (table.insert new-path (tostring k))
    (if (= target-type :number)
        (assert (= (type (. subject k)) :number)
                (.. "Parameter '" (table.concat new-path "/")
                    "' is missing from subject or isn't a number"))
        (= target-type :table)
        (check-subject-and-target-recursively (. subject k) target-value
                                              new-path)
        (assert (= target-type :number)
                (.. "Parameter '" (table.concat new-path "/")
                    "' must be a number or table of numbers")))))
(fn check-new-params [duration subject target easing]
  (assert (and (= (type duration) :number) (> duration 0))
          (.. "duration must be a positive number. Was " (tostring duration)))
  (local tsubject (type subject))
  (assert (or (= tsubject :table) (= tsubject :userdata))
          (.. "subject must be a table or userdata. Was " (tostring subject)))
  (assert (= (type target) :table)
          (.. "target must be a table. Was " (tostring target)))
  (assert (= (type easing) :function)
          (.. "easing must be a function. Was " (tostring easing)))
  (check-subject-and-target-recursively subject target))
(fn get-easing-function [easing]
  (set-forcibly! easing (or easing :linear))
  (when (= (type easing) :string)
    (local name easing)
    (set-forcibly! easing (. tween.easing name))
    (when (not= (type easing) :function)
      (error (.. "The easing function name '" name "' is invalid"))))
  easing)
(fn perform-easing-on-subject [subject target initial clock duration easing]
  (let [(t b c d) nil]
    (each [k v (pairs target)]
      (if (= (type v) :table)
          (perform-easing-on-subject (. subject k) v (. initial k) clock
                                     duration easing)
          (do
            (set-forcibly! (t b c d)
                           (values clock (. initial k) (- v (. initial k))
                                   duration))
            (tset subject k (easing t b c d)))))))
(local Tween {})
(set Tween.__index Tween)

(fn Tween.set [self clock]
  (assert (= (type clock) :number) "clock must be a positive number or 0")
  (set self.initial (or self.initial (copy-tables {} self.target self.subject)))
  (set self.clock clock)
  (if (<= self.clock 0)
      (do
        (set self.clock 0)
        (copy-tables self.subject self.initial))
      (>= self.clock self.duration)
      (do
        (set self.clock self.duration)
        (copy-tables self.subject self.target))
      (perform-easing-on-subject self.subject self.target self.initial
                                 self.clock self.duration self.easing))
  (>= self.clock self.duration))

(fn Tween.status [self]
  (if (< self.clock self.duration)
      :running 
      :finished))

(fn Tween.reset [self]
  (self:set 0))

(fn Tween.update [self dt]
  (assert (= (type dt) :number) "dt must be a number")
  (self:set (+ self.clock dt)))

(fn new-tween [duration subject target easing]
  (set-forcibly! easing (get-easing-function easing))
  (check-new-params duration subject target easing)
  (setmetatable {: duration : subject : target : easing :clock 0} Tween))

new-tween
