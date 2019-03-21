import { Elm } from "./SalaryCalculator.elm"

const program = Elm.SalaryCalculator

export function init(node) {
  program.init({
      flags: location.href,
      node: node
  })
}
