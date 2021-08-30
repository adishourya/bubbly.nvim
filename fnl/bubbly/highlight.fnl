(module bubbly.highlight
  {autoload {clj lib.cljlib}})

(local {: inc
        : nil?
        : empty?} clj)

(defn- hex->dec [hex] (tonumber hex 16))

(defn hex->8bit [hex]
  "Converts a hexadecimal color to its nearest 8-bit color
  It's the same implementation that tmux and mpv use"
  (fn v2ci [v]
    (if
      (< v 48) 0
      (< v 115) 1
      (math.floor (/ (- v 35) 40))))
  (fn dist [[A B C] [a b c]]
    (+ (^ (- A a) 2) (^ (- B b) 2) (^ (- C c) 2)))
  (local i2cv [0 0x5F 0x87 0xAF 0xD7 0xFF])
  (let [[r g b] [(string.match hex "#(%w%w)(%w%w)(%w%w)")]
        [r g b] (icollect [_ v (ipairs [r g b])]
                  (hex->dec v))
        ir (v2ci r)
        ig (v2ci g)
        ib (v2ci b)
        color-index (+ (* 36 ir) (* 6 ig) ib)
        average (math.floor (/ (+ r g b) 3))
        gray-index (if (> average 238) 23
                     (math.floor (/ (- average 3) 10)))
        cr (. i2cv (inc ir))
        cg (. i2cv (inc ig))
        cb (. i2cv (inc ib))
        gv (+ 8 (* gray-index 10))
        color-error (dist [cr cg cb] [r g b])
        gray-error (dist [gv gv gv] [r g b])]
    (if (<= color-error gray-error) (+ 16 color-index)
      (+ 232 gray-index))))

(defn- ->bool [obj]
  (if obj true false))

(defn- hex-color? [hex-color]
  (->bool (string.match hex-color "#%w%w%w%w%w%w")))

(defn- extract-highlight-by-name [group-name]
  (let [(ok? value) (pcall vim.api.nvim_get_hl_by_name group-name true)]
    (when ok? value)))

(defn- extract-color [color]
  (match [(string.match color "(%w+)%s(%w+)")]
    [group-name key] (or (-?>>
                           (-?> (extract-highlight-by-name group-name)
                                (. key))
                           (string.format "#%06x"))
                         "NONE")
    _ color))

(defn highlight [group-name
                 {:fg guifg :bg guibg}
                 attr-list]
  (let [attr-list (if (or
                        (nil? attr-list)
                        (empty? attr-list)) "NONE"
                    (table.concat attr-list ","))
        guifg (extract-color guifg)
        guibg (extract-color guibg)
        ctermfg (if
                  (hex-color? guifg) (hex->8bit guifg)
                  guifg)
        ctermbg (if
                  (hex-color? guibg) (hex->8bit guibg)
                  guibg)]
    (string.format "highlight %s ctermfg=%s ctermbg=%s cterm=%s guifg=%s guibg=%s gui=%s"
                   group-name ctermfg ctermbg attr-list guifg guibg attr-list)))
