#!/usr/bin/env bash
set -euo pipefail

EXPORT_DIR="${1:-exported-html}"

if [ ! -d "$EXPORT_DIR" ]; then
	printf 'Error: %s not found\n' "$EXPORT_DIR" >&2
	exit 1
fi

# Write payloads to temp files
css_tmp=$(mktemp)
htmljs_tmp=$(mktemp)
cleanup() { rm -f "$css_tmp" "$htmljs_tmp"; }
trap cleanup EXIT

cat > "$css_tmp" << 'CSSEOF'
/* POSTPROCESS:CRT */
.crt-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  pointer-events: none;
  z-index: 9998;
  display: none;
}
.crt-overlay.active { display: block; }
.crt-overlay .crt-scanlines {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background:
    repeating-linear-gradient(
      0deg,
      rgba(0, 0, 0, 0) 0px,
      rgba(0, 0, 0, 0.18) 2px,
      rgba(0, 0, 0, 0) 4px
    ),
    repeating-linear-gradient(
      90deg,
      rgba(255, 0, 50, 0.06) 0px,
      rgba(0, 255, 50, 0.06) 2px,
      rgba(50, 80, 255, 0.06) 4px
    );
  background-size: 100% 6px, 6px 100%;
}
.crt-overlay .crt-vignette {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: radial-gradient(ellipse at center, transparent 65%, rgba(0, 0, 0, 0.45) 100%);
}
.crt-active #ansi-output {
  text-shadow:
    -1px 0 1px rgba(255, 0, 80, 0.35),
    1px 0 1px rgba(0, 255, 180, 0.35),
    0 0 5px rgba(0, 255, 100, 0.2),
    0 0 12px rgba(180, 0, 255, 0.1),
    0 0 25px rgba(0, 255, 100, 0.05);
}
@keyframes crt-flicker {
  0% { opacity: 0.96; }
  5% { opacity: 1; }
  10% { opacity: 0.97; }
  40% { opacity: 1; }
  45% { opacity: 0.94; }
  50% { opacity: 1; }
  80% { opacity: 0.98; }
  85% { opacity: 0.95; }
  100% { opacity: 0.98; }
}
.crt-active #ansi-output {
  animation: crt-flicker .5s infinite;
}
#options-bar a.home-link {
  color: #0a0;
  text-decoration: none;
}
#options-bar a.home-link:hover {
  color: #0f0;
  text-decoration: underline;
}
/* POSTPROCESS:END */
CSSEOF

cat > "$htmljs_tmp" << 'HTMLJSEOF'
<!-- POSTPROCESS:CRT -->
<div class="crt-overlay" id="crt-overlay"><div class="crt-scanlines"></div><div class="crt-vignette"></div></div>
<script>
(function() {
  function fixInternalLinks() {
    var links = document.querySelectorAll('#ansi-output a');
    for (var i = 0; i < links.length; i++) {
      var href = links[i].getAttribute('href');
      if (href && !/^(https?:|mailto:)/i.test(href)) {
        links[i].removeAttribute('target');
        links[i].removeAttribute('rel');
      }
    }
  }

  function addOptionsBarItems() {
    var bar = document.getElementById('options-bar');
    if (!bar) return;

    var homeLink = document.createElement('a');
    homeLink.href = './index.html';
    homeLink.textContent = 'Home';
    homeLink.className = 'home-link';
    bar.insertBefore(homeLink, bar.firstChild);

    var crtLabel = document.createElement('label');
    crtLabel.innerHTML = '<input id="crt-toggle" type="checkbox"> CRT';
    bar.appendChild(crtLabel);
  }

  function setupCRT() {
    var toggle = document.getElementById('crt-toggle');
    var overlay = document.getElementById('crt-overlay');
    if (!toggle || !overlay) return;

    var enabled = false;
    try { enabled = localStorage.getItem('crt-enabled') === 'true'; } catch(e) {}

    function applyCRT(on) {
      if (on) {
        overlay.classList.add('active');
        document.body.classList.add('crt-active');
      } else {
        overlay.classList.remove('active');
        document.body.classList.remove('crt-active');
      }
      toggle.checked = on;
    }

    applyCRT(enabled);
    toggle.addEventListener('change', function() {
      var on = toggle.checked;
      try { localStorage.setItem('crt-enabled', on ? 'true' : 'false'); } catch(e) {}
      applyCRT(on);
    });
  }

  fixInternalLinks();
  addOptionsBarItems();
  setupCRT();

  var target = document.getElementById('ansi-output');
  if (target) {
    new MutationObserver(function() { fixInternalLinks(); })
      .observe(target, { childList: true });
  }
})();
</script>
<!-- POSTPROCESS:END -->
HTMLJSEOF

# 1. Inject CSS into style.css (if it exists and not already done)
css_file="$EXPORT_DIR/style.css"
if [ -f "$css_file" ] && ! grep -q 'POSTPROCESS:CRT' "$css_file"; then
	printf 'Post-processing: %s\n' "$css_file"
	cat "$css_tmp" >> "$css_file"
fi

# 2. Inject HTML+JS into each HTML file (before </body>)
for html_file in "$EXPORT_DIR"/*.html; do
	[ -f "$html_file" ] || continue

	if grep -q 'POSTPROCESS:CRT' "$html_file"; then
		printf 'Skipping (already processed): %s\n' "$html_file"
		continue
	fi

	printf 'Post-processing: %s\n' "$html_file"

	tmp_file=$(mktemp)

	# Handle both formats: inline <style> or external style.css
	awk -v css_file="$css_tmp" -v htmljs_file="$htmljs_tmp" '
		/<\/style>/ {
			while ((getline line < css_file) > 0) print line
			close(css_file)
		}
		/<\/body>/ {
			while ((getline line < htmljs_file) > 0) print line
			close(htmljs_file)
		}
		{ print }
	' "$html_file" > "$tmp_file" && mv "$tmp_file" "$html_file"
done
