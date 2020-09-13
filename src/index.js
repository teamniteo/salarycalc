import { Elm } from "./Main.elm";
import config from "../config.yml";

const program = Elm.Main;

export function init(node, config = config) {
  program.init({
    flags: {
      location: location.href,
      config
    },
    node
  });
}

export const defaults = config;
