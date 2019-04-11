import { Elm } from "./SalaryCalculator.elm"
import config from "../config.yml"

const program = Elm.SalaryCalculator

export function init(node, config = config) {
  program.init({
      flags: {
        url: location.href,
        config
      },
      node
  })
}

export const defaults = config
