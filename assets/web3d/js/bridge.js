// ============================================================================
// Bridge between the 3D engine (JS) and the Flutter shell.
//
//  • Engine -> Flutter : Bridge.emit(event, data)
//       Uses flutter_inappwebview's callHandler('onGameEvent', {...}) when
//       running inside the app; falls back to console + a CustomEvent so the
//       same build is fully testable in a plain desktop browser.
//
//  • Flutter -> Engine : window.RahinoEngine.cmd(name, data)
//       Flutter calls this via evaluateJavascript(). The engine registers a
//       single dispatcher with Bridge.onCommand(fn).
// ============================================================================

let commandHandler = null;
const pending = [];

export const Bridge = {
  emit(event, data = {}) {
    const payload = { event, data, t: Date.now() };
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onGameEvent', payload);
      } else {
        // Desktop-browser fallback for testing without Flutter.
        window.dispatchEvent(new CustomEvent('rahino-event', { detail: payload }));
        if (event !== 'position') console.log('[engine→flutter]', event, data);
      }
    } catch (e) {
      console.warn('Bridge emit failed', e);
    }
  },

  onCommand(fn) {
    commandHandler = fn;
    // Flush any commands that arrived before the engine was ready.
    while (pending.length) fn(pending.shift());
  },
};

// Global entry point Flutter calls into.
window.RahinoEngine = {
  cmd(name, data = {}) {
    const c = { name, data: typeof data === 'string' ? safeParse(data) : data };
    if (commandHandler) commandHandler(c);
    else pending.push(c);
  },
};

function safeParse(s) {
  try { return JSON.parse(s); } catch { return {}; }
}
