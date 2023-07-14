import { Elm } from "./Main.elm";
import config from "../config.yml";

Elm.Main.init({
  flags: {
    location: location.href,
    config
  },
  node: document.getElementById("app-container")
});
