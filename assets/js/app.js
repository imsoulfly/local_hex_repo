// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import ClipboardJS from "../vendor/clipboard.min"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// import ClipboardJS from "clipboard";

function SideBar() {
  if (!sidebar) return;

  const toggle = sidebar.querySelector(".sidebar__toggle");
  const linkItems = sidebar.querySelector(".sidebar__link");
  const toggleOpen = () => sidebar.classList.toggle("sidebar__open");

  toggle.addEventListener("click", toggleOpen);
  window.addEventListener("click", e => {
    if (sidebar.contains(e.target)) {
      return;
    }

    if (sidebar.classList.contains("sidebar__open")) {
      toggleOpen();
    }
  });
};

function Collapsible() {
  if (!collapsible) return;

  const toggle = collapsible.querySelector(".collapsible__toggle");
  const toggleOpen = () => collapsible.classList.toggle("collapsible__open");

  toggle.addEventListener("click", toggleOpen);
};

const initialize = () => {
  const collapsible = document.getElementById("collapsible");
  const sidebar = document.getElementById("sidebar");

  new ClipboardJS(".cp-btn");
  new Collapsible(collapsible);
  new SideBar(sidebar);
};

window.addEventListener('DOMContentLoaded', (event) => {
  initialize();
});
