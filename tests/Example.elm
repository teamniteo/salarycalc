module Example exposing (suite)

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import SalaryCalculator exposing (ljubljana, salary, softwareEngineer)
import Test exposing (..)


suite : Test
suite =
    test "Salary for Software Engineer from Ljubljana with a 2 year tenure"
        (\_ ->
            salary
                { roleDropdown = Dropdown.initialState
                , cityDropdown = Dropdown.initialState
                , tenureDropdown = Dropdown.initialState
                , accordionState = Accordion.initialState
                , role = softwareEngineer
                , city = ljubljana
                , tenure = 2
                }
                |> Expect.equal 5017
        )
