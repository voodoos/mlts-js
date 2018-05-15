import Mlts from "./mlts-api.js";

function log(l, p, t) {
  console.log(l, p, t);
  let child = document.createElement("div");
  child.innerHTML = "Log (" + l + ") : [ " + p + "] : " + t;
  document.getElementById("console")
    .appendChild(child)
}
const mlts = new Mlts(log);

mlts.start.then(val => {
  log("info", "MltsProm", val);
});

mlts.transpile("3 + 4;;").then(val => {
  log("info", "MltsProm", JSON.stringify(val, null, 4));
}).catch(err => {
  log("error", "MltsProm", err);
});


