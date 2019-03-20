module Tests exposing (commitmentBonus, defaultSalary)

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import SalaryCalculator exposing (ljubljana, salary, softwareEngineer, tenureDetail)
import Test exposing (..)


defaultSalary : Test
defaultSalary =
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


commitmentBonus : Test
commitmentBonus =
    describe "Commitment Bonus is calculated correctly"
        [ test "0 years" <|
            \_ ->
                tenureDetail 0
                    |> Expect.equal { name = "Just started", commitmentBonus = 0 }
        , test "1 year" <|
            \_ ->
                tenureDetail 1
                    |> Expect.equal { name = "1 year", commitmentBonus = 0.06931471805599453 }
        , test "2 year" <|
            \_ ->
                tenureDetail 2
                    |> Expect.equal { name = "2 years", commitmentBonus = 0.10986122886681096 }
        , test "5 year" <|
            \_ ->
                tenureDetail 5
                    |> Expect.equal { name = "5 years", commitmentBonus = 0.1791759469228055 }
        , test "10 year" <|
            \_ ->
                tenureDetail 10
                    |> Expect.equal { name = "10 years", commitmentBonus = 0.23978952727983707 }
        , test "15 year" <|
            \_ ->
                tenureDetail 15
                    |> Expect.equal { name = "15 years", commitmentBonus = 0.2772588722239781 }
        ]
