import { Elm } from "./SalaryCalculator.elm"

const node = document.getElementById("app-container")
const program = Elm.SalaryCalculator

program.init({
    flags: location.href,
    node: node
})
