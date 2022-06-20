;; Transformed kikito/tween.lua to fennel via antifennel and made modifications

(local tween {:_VERSION "tween 2.1.1"
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

(local (pow sin cos pi sqrt abs asin)
       (values math.pow math.sin math.cos math.pi math.sqrt math.abs math.asin))
(fn linear [t b c d]
  (+ (/ (* c t) d) b))
(fn in-quad [t b c d]
  (+ (* c (pow (/ t d) 2)) b))
(fn out-quad [t b c d]
  (set-forcibly! t (/ t d))
  (+ (* (* (- c) t) (- t 2)) b))
(fn in-out-quad [t b c d]
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (/ c 2) (pow t 2)) b)]
      (lua "return ___antifnl_rtn_1___")))
  (+ (* (/ (- c) 2) (- (* (- t 1) (- t 3)) 1)) b))
(fn out-in-quad [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-quad (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-quad (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-cubic [t b c d]
  (+ (* c (pow (/ t d) 3)) b))
(fn out-cubic [t b c d]
  (+ (* c (+ (pow (- (/ t d) 1) 3) 1)) b))
(fn in-out-cubic [t b c d]
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (* (* (/ c 2) t) t) t) b)]
      (lua "return ___antifnl_rtn_1___")))
  (set-forcibly! t (- t 2))
  (+ (* (/ c 2) (+ (* (* t t) t) 2)) b))
(fn out-in-cubic [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-cubic (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-cubic (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-quart [t b c d]
  (+ (* c (pow (/ t d) 4)) b))
(fn out-quart [t b c d]
  (+ (* (- c) (- (pow (- (/ t d) 1) 4) 1)) b))
(fn in-out-quart [t b c d]
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (/ c 2) (pow t 4)) b)]
      (lua "return ___antifnl_rtn_1___")))
  (+ (* (/ (- c) 2) (- (pow (- t 2) 4) 2)) b))
(fn out-in-quart [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-quart (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-quart (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-quint [t b c d]
  (+ (* c (pow (/ t d) 5)) b))
(fn out-quint [t b c d]
  (+ (* c (+ (pow (- (/ t d) 1) 5) 1)) b))
(fn in-out-quint [t b c d]
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (/ c 2) (pow t 5)) b)]
      (lua "return ___antifnl_rtn_1___")))
  (+ (* (/ c 2) (+ (pow (- t 2) 5) 2)) b))
(fn out-in-quint [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-quint (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-quint (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-sine [t b c d]
  (+ (+ (* (- c) (cos (* (/ t d) (/ pi 2)))) c) b))
(fn out-sine [t b c d]
  (+ (* c (sin (* (/ t d) (/ pi 2)))) b))
(fn in-out-sine [t b c d]
  (+ (* (/ (- c) 2) (- (cos (/ (* pi t) d)) 1)) b))
(fn out-in-sine [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-sine (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-sine (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-expo [t b c d]
  (when (= t 0)
    (lua "return b"))
  (- (+ (* c (pow 2 (* 10 (- (/ t d) 1)))) b) (* c 0.001)))
(fn out-expo [t b c d]
  (when (= t d)
    (let [___antifnl_rtn_1___ (+ b c)]
      (lua "return ___antifnl_rtn_1___")))
  (+ (* (* c 1.001) (+ (- (pow 2 (/ (* (- 10) t) d))) 1)) b))
(fn in-out-expo [t b c d]
  (when (= t 0)
    (lua "return b"))
  (when (= t d)
    (let [___antifnl_rtn_1___ (+ b c)]
      (lua "return ___antifnl_rtn_1___")))
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (- (+ (* (/ c 2) (pow 2 (* 10 (- t 1)))) b)
                                 (* c 0.0005))]
      (lua "return ___antifnl_rtn_1___")))
  (+ (* (* (/ c 2) 1.0005) (+ (- (pow 2 (* (- 10) (- t 1)))) 2)) b))
(fn out-in-expo [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-expo (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-expo (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn in-circ [t b c d]
  (+ (* (- c) (- (sqrt (- 1 (pow (/ t d) 2))) 1)) b))
(fn out-circ [t b c d]
  (+ (* c (sqrt (- 1 (pow (- (/ t d) 1) 2)))) b))
(fn in-out-circ [t b c d]
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (/ (- c) 2) (- (sqrt (- 1 (* t t))) 1)) b)]
      (lua "return ___antifnl_rtn_1___")))
  (set-forcibly! t (- t 2))
  (+ (* (/ c 2) (+ (sqrt (- 1 (* t t))) 1)) b))
(fn out-in-circ [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-circ (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-circ (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))
(fn calculate-pAS [p a c d]
  (set-forcibly! (p a) (values (or p (* d 0.3)) (or a 0)))
  (when (< a (abs c))
    (let [___antifnl_rtn_1___ p
          ___antifnl_rtn_2___ c
          ___antifnl_rtn_3___ (/ p 4)]
      (lua "return ___antifnl_rtn_1___, ___antifnl_rtn_2___, ___antifnl_rtn_3___")))
  (values p a (* (/ p (* 2 pi)) (asin (/ c a)))))
(fn in-elastic [t b c d a p]
  (let [s nil]
    (when (= t 0)
      (lua "return b"))
    (set-forcibly! t (/ t d))
    (when (= t 1)
      (let [___antifnl_rtn_1___ (+ b c)]
        (lua "return ___antifnl_rtn_1___")))
    (set-forcibly! (p a s) (calculate-pAS p a c d))
    (set-forcibly! t (- t 1))
    (+ (- (* (* a (pow 2 (* 10 t))) (sin (/ (* (- (* t d) s) (* 2 pi)) p)))) b)))
(fn out-elastic [t b c d a p]
  (let [s nil]
    (when (= t 0)
      (lua "return b"))
    (set-forcibly! t (/ t d))
    (when (= t 1)
      (let [___antifnl_rtn_1___ (+ b c)]
        (lua "return ___antifnl_rtn_1___")))
    (set-forcibly! (p a s) (calculate-pAS p a c d))
    (+ (+ (* (* a (pow 2 (* (- 10) t))) (sin (/ (* (- (* t d) s) (* 2 pi)) p)))
          c) b)))
(fn in-out-elastic [t b c d a p]
  (let [s nil]
    (when (= t 0)
      (lua "return b"))
    (set-forcibly! t (* (/ t d) 2))
    (when (= t 2)
      (let [___antifnl_rtn_1___ (+ b c)]
        (lua "return ___antifnl_rtn_1___")))
    (set-forcibly! (p a s) (calculate-pAS p a c d))
    (set-forcibly! t (- t 1))
    (when (< t 0)
      (let [___antifnl_rtn_1___ (+ (* (- 0.5)
                                      (* (* a (pow 2 (* 10 t)))
                                         (sin (/ (* (- (* t d) s) (* 2 pi)) p))))
                                   b)]
        (lua "return ___antifnl_rtn_1___")))
    (+ (+ (* (* (* a (pow 2 (* (- 10) t)))
                (sin (/ (* (- (* t d) s) (* 2 pi)) p))) 0.5) c) b)))
(fn out-in-elastic [t b c d a p]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-elastic (* t 2) b (/ c 2) d a p)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-elastic (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d a p))
(fn in-back [t b c d s]
  (set-forcibly! s (or s 1.70158))
  (set-forcibly! t (/ t d))
  (+ (* (* (* c t) t) (- (* (+ s 1) t) s)) b))
(fn out-back [t b c d s]
  (set-forcibly! s (or s 1.70158))
  (set-forcibly! t (- (/ t d) 1))
  (+ (* c (+ (* (* t t) (+ (* (+ s 1) t) s)) 1)) b))
(fn in-out-back [t b c d s]
  (set-forcibly! s (* (or s 1.70158) 1.525))
  (set-forcibly! t (* (/ t d) 2))
  (when (< t 1)
    (let [___antifnl_rtn_1___ (+ (* (/ c 2) (* (* t t) (- (* (+ s 1) t) s))) b)]
      (lua "return ___antifnl_rtn_1___")))
  (set-forcibly! t (- t 2))
  (+ (* (/ c 2) (+ (* (* t t) (+ (* (+ s 1) t) s)) 2)) b))
(fn out-in-back [t b c d s]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-back (* t 2) b (/ c 2) d s)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-back (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d s))
(fn out-bounce [t b c d]
  (set-forcibly! t (/ t d))
  (when (< t (/ 1 2.75))
    (let [___antifnl_rtn_1___ (+ (* c (* (* 7.5625 t) t)) b)]
      (lua "return ___antifnl_rtn_1___")))
  (if (< t (/ 2 2.75))
      (do
        (set-forcibly! t (- t (/ 1.5 2.75)))
        (let [___antifnl_rtn_1___ (+ (* c (+ (* (* 7.5625 t) t) 0.75)) b)]
          (lua "return ___antifnl_rtn_1___"))) (< t (/ 2.5 2.75))
      (do
        (set-forcibly! t (- t (/ 2.25 2.75)))
        (let [___antifnl_rtn_1___ (+ (* c (+ (* (* 7.5625 t) t) 0.9375)) b)]
          (lua "return ___antifnl_rtn_1___"))))
  (set-forcibly! t (- t (/ 2.625 2.75)))
  (+ (* c (+ (* (* 7.5625 t) t) 0.984375)) b))
(fn in-bounce [t b c d]
  (+ (- c (out-bounce (- d t) 0 c d)) b))
(fn in-out-bounce [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtn_1___ (+ (* (in-bounce (* t 2) 0 c d) 0.5) b)]
      (lua "return ___antifnl_rtn_1___")))
  (+ (+ (* (out-bounce (- (* t 2) d) 0 c d) 0.5) (* c 0.5)) b))
(fn out-in-bounce [t b c d]
  (when (< t (/ d 2))
    (let [___antifnl_rtns_1___ [(out-bounce (* t 2) b (/ c 2) d)]]
      (lua "return (table.unpack or _G.unpack)(___antifnl_rtns_1___)")))
  (in-bounce (- (* t 2) d) (+ b (/ c 2)) (/ c 2) d))

{: linear
 :inQuad in-quad
 :outQuad out-quad
 :inOutQuad in-out-quad
 :outInQuad out-in-quad
 :inCubic in-cubic
 :outCubic out-cubic
 :inOutCubic in-out-cubic
 :outInCubic out-in-cubic
 :inQuart in-quart
 :outQuart out-quart
 :inOutQuart in-out-quart
 :outInQuart out-in-quart
 :inQuint in-quint
 :outQuint out-quint
 :inOutQuint in-out-quint
 :outInQuint out-in-quint
 :inSine in-sine
 :outSine out-sine
 :inOutSine in-out-sine
 :outInSine out-in-sine
 :inExpo in-expo
 :outExpo out-expo
 :inOutExpo in-out-expo
 :outInExpo out-in-expo
 :inCirc in-circ
 :outCirc out-circ
 :inOutCirc in-out-circ
 :outInCirc out-in-circ
 :inElastic in-elastic
 :outElastic out-elastic
 :inOutElastic in-out-elastic
 :outInElastic out-in-elastic
 :inBack in-back
 :outBack out-back
 :inOutBack in-out-back
 :outInBack out-in-back
 :inBounce in-bounce
 :outBounce out-bounce
 :inOutBounce in-out-bounce
 :outInBounce out-in-bounce}
