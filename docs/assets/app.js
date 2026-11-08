(function () {
    "use strict";

    // ---------- Language ----------
    var root = document.documentElement;
    function store(key, value) {
        try {
            if (value === undefined) return localStorage.getItem(key);
            localStorage.setItem(key, value);
        } catch (e) { return null; }
    }
    function setLang(lang) {
        root.classList.remove("lang-vi", "lang-en");
        root.classList.add("lang-" + lang);
        root.lang = lang;
        document.title = lang === "vi"
            ? "SlimeUI · Thư viện UI cho script Roblox"
            : "SlimeUI · UI library for Roblox scripts";
        document.querySelectorAll(".lang-switch button").forEach(function (b) {
            b.classList.toggle("on", b.dataset.lang === lang);
            b.setAttribute("aria-pressed", b.dataset.lang === lang ? "true" : "false");
        });
        store("slimeui-lang", lang);
    }
    var params = new URLSearchParams(location.search);
    var initial = params.get("lang") || store("slimeui-lang") ||
        ((navigator.language || "").toLowerCase().indexOf("vi") === 0 ? "vi" : "en");
    setLang(initial === "vi" ? "vi" : "en");
    document.querySelectorAll(".lang-switch button").forEach(function (b) {
        b.addEventListener("click", function () { setLang(b.dataset.lang); });
    });

    // ---------- Mobile nav ----------
    var menuBtn = document.querySelector(".menu-btn");
    if (menuBtn) {
        menuBtn.addEventListener("click", function () { document.body.classList.toggle("nav-open"); });
    }
    document.querySelectorAll(".sidenav a").forEach(function (a) {
        a.addEventListener("click", function () { document.body.classList.remove("nav-open"); });
    });

    // ---------- Lua syntax highlight ----------
    var KEYWORDS = "local|function|end|if|then|else|elseif|for|in|do|while|repeat|until|return|and|or|not|nil|true|false|break";
    var GLOBALS = "SlimeUI|Window|Enum|Color3|Vector2|UDim2|game|workspace|task|math|string|table|print|loadstring|readfile|ipairs|pairs";
    var TOKEN = new RegExp(
        "(--\\[\\[[\\s\\S]*?\\]\\]|--[^\\n]*)" +            // 1 comment
        "|(\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*')" + // 2 string
        "|\\b(" + KEYWORDS + ")\\b" +                         // 3 keyword
        "|\\b(\\d+(?:\\.\\d+)?)\\b" +                         // 4 number
        "|\\b(" + GLOBALS + ")\\b" +                          // 5 global
        "|([A-Za-z_]\\w*)(?=\\s*[({\"])",                     // 6 call
        "g");
    function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
    function highlight(code) {
        var out = "", last = 0, m;
        TOKEN.lastIndex = 0;
        while ((m = TOKEN.exec(code))) {
            out += esc(code.slice(last, m.index));
            var cls = m[1] ? "c" : m[2] ? "s" : m[3] ? "k" : m[4] ? "n" : m[5] ? "g" : "f";
            out += '<span class="t-' + cls + '">' + esc(m[0]) + "</span>";
            last = TOKEN.lastIndex;
        }
        return out + esc(code.slice(last));
    }
    document.querySelectorAll("pre > code.lua").forEach(function (el) {
        el.innerHTML = highlight(el.textContent);
    });

    // ---------- Copy buttons ----------
    document.querySelectorAll("pre").forEach(function (pre) {
        var btn = document.createElement("button");
        btn.className = "copy";
        btn.type = "button";
        btn.innerHTML = '<span class="vi">Sao chép</span><span class="en">Copy</span>';
        btn.addEventListener("click", function () {
            var text = pre.querySelector("code").textContent;
            var done = function () {
                btn.classList.add("done");
                btn.innerHTML = '<span class="vi">Đã chép</span><span class="en">Copied</span>';
                setTimeout(function () {
                    btn.classList.remove("done");
                    btn.innerHTML = '<span class="vi">Sao chép</span><span class="en">Copy</span>';
                }, 1600);
            };
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(done, function () {});
            } else {
                var ta = document.createElement("textarea");
                ta.value = text; document.body.appendChild(ta); ta.select();
                try { document.execCommand("copy"); done(); } catch (e) {}
                ta.remove();
            }
        });
        pre.appendChild(btn);
    });

    // ---------- Theme gallery ----------
    var THEMES = [
        { name: "Glass", window: "14, 16, 24", alpha: 0.4, tint: "255, 255, 255", accent: "#0a84ff", text: "#ffffff", sub: "#ced2de", vi: "Kính trong suốt", en: "Clear glass" },
        { name: "Slime", window: "6, 30, 16", alpha: 0.6, tint: "160, 255, 175", accent: "#58dc48", text: "#f0fff3", sub: "#a8e4b6", vi: "Bong bóng + giọt slime", en: "Bubbles + slime drips", slime: true },
        { name: "Dark", window: "28, 28, 32", alpha: 0.95, tint: "255, 255, 255", accent: "#0a84ff", text: "#f5f5f7", sub: "#98989f", vi: "Tối, gần như đặc", en: "Solid dark" },
        { name: "Light", window: "242, 242, 246", alpha: 0.95, tint: "0, 0, 0", accent: "#007aff", text: "#1d1d1f", sub: "#6e6e73", vi: "Nền sáng", en: "Bright theme" },
        { name: "Midnight", window: "0, 0, 0", alpha: 0.92, tint: "255, 255, 255", accent: "#64d2ff", text: "#ebebf0", sub: "#82828c", vi: "Đen tuyền cho OLED", en: "Pure black for OLED" },
        { name: "Ocean", window: "6, 22, 40", alpha: 0.55, tint: "165, 215, 255", accent: "#38bdf8", text: "#f0f8ff", sub: "#a5c8e8", vi: "Kính xanh biển", en: "Blue glass" },
        { name: "Sakura", window: "40, 14, 28", alpha: 0.55, tint: "255, 195, 220", accent: "#ff69a0", text: "#fff4f8", sub: "#f0b9d0", vi: "Kính hồng anh đào", en: "Cherry blossom pink" },
        { name: "Amethyst", window: "22, 14, 42", alpha: 0.55, tint: "212, 192, 255", accent: "#a778ff", text: "#f8f4ff", sub: "#c4b6ec", vi: "Kính tím thạch anh", en: "Purple glass" },
        { name: "Sunset", window: "40, 20, 10", alpha: 0.55, tint: "255, 212, 172", accent: "#ff8c32", text: "#fff8f0", sub: "#f0caa6", vi: "Kính cam hoàng hôn", en: "Warm orange glass" }
    ];
    var mock = document.getElementById("mock");
    function applyTheme(t) {
        if (!mock) return;
        mock.style.setProperty("--mk-window", t.window);
        mock.style.setProperty("--mk-alpha", t.alpha);
        mock.style.setProperty("--mk-tint", t.tint);
        mock.style.setProperty("--mk-accent", t.accent);
        mock.style.setProperty("--mk-text", t.text);
        mock.style.setProperty("--mk-sub", t.sub);
        mock.classList.toggle("slime", !!t.slime);
        document.querySelectorAll(".theme").forEach(function (b) {
            b.classList.toggle("on", b.dataset.theme === t.name);
        });
        var label = document.getElementById("theme-code");
        if (label) label.textContent = t.name;
    }
    var gallery = document.getElementById("theme-gallery");
    if (gallery) {
        THEMES.forEach(function (t) {
            var b = document.createElement("button");
            b.type = "button";
            b.className = "theme";
            b.dataset.theme = t.name;
            b.innerHTML =
                '<div class="sw" style="background: linear-gradient(135deg, rgba(' + t.window + ', 1), rgba(' + t.tint + ', .35))">' +
                '<i style="background:' + t.accent + '"></i></div>' + t.name +
                '<small><span class="vi">' + t.vi + '</span><span class="en">' + t.en + "</span></small>";
            b.addEventListener("click", function () {
                applyTheme(t);
                if (mock) mock.scrollIntoView({ behavior: "smooth", block: "center" });
            });
            gallery.appendChild(b);
        });
    }
    var heroThemes = document.querySelectorAll("[data-hero-theme]");
    heroThemes.forEach(function (b) {
        b.addEventListener("click", function () {
            var t = THEMES.filter(function (x) { return x.name === b.dataset.heroTheme; })[0];
            if (t) applyTheme(t);
        });
    });
    applyTheme(THEMES[1]);

    // bubbles + drips for the Slime preview
    var bubbles = document.querySelector(".mk-bubbles");
    if (bubbles) {
        for (var i = 0; i < 10; i++) {
            var s = document.createElement("span");
            var size = 6 + Math.round(Math.random() * 12);
            s.style.width = s.style.height = size + "px";
            s.style.left = Math.round(Math.random() * 95) + "%";
            s.style.animationDuration = (5 + Math.random() * 6).toFixed(1) + "s";
            s.style.animationDelay = (-Math.random() * 8).toFixed(1) + "s";
            bubbles.appendChild(s);
        }
        [62, 74, 88, 95].forEach(function (x, idx) {
            var d = document.createElement("div");
            d.className = "mk-drip";
            d.style.left = x + "%";
            d.style.animationDuration = (1.4 + idx * 0.35) + "s";
            bubbles.appendChild(d);
        });
    }

    // ---------- Active section in the sidebar ----------
    var links = Array.prototype.slice.call(document.querySelectorAll(".sidenav a[href^='#']"));
    var targets = links.map(function (a) { return document.querySelector(a.getAttribute("href")); }).filter(Boolean);
    if ("IntersectionObserver" in window && targets.length) {
        var observer = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
                if (entry.isIntersecting) {
                    links.forEach(function (a) {
                        a.classList.toggle("active", a.getAttribute("href") === "#" + entry.target.id);
                    });
                }
            });
        }, { rootMargin: "-20% 0px -70% 0px" });
        targets.forEach(function (t) { observer.observe(t); });
    }
})();
