module Tests exposing
    (  testCommitmentBonus
       --, cityImpact
       --, tenureImpact

    , testSalary
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import List.Extra as List
import SalaryCalculator exposing (City, Role, commitmentBonus, salary)
import Test exposing (..)


testSalary : Test
testSalary =
    test "Salary for Software Engineer from Ljubljana with a 2 year tenure"
        (\_ ->
            salary { name = "FooRole", baseSalary = 4919 } { name = "FooCity", locationFactor = 0.91 } 2
                |> Expect.equal 5017
        )


testCommitmentBonus : Test
testCommitmentBonus =
    describe "Commitment Bonus is calculated correctly"
        [ test "0 years" <|
            \_ ->
                commitmentBonus 0
                    |> Expect.equal 0
        , test "1 year" <|
            \_ ->
                commitmentBonus 1
                    |> String.fromFloat
                    |> Expect.equal "0.06931471805599453"
        , test "2 year" <|
            \_ ->
                commitmentBonus 2
                    |> String.fromFloat
                    |> Expect.equal "0.10986122886681096"
        , test "5 year" <|
            \_ ->
                commitmentBonus 5
                    |> String.fromFloat
                    |> Expect.equal "0.1791759469228055"
        , test "10 year" <|
            \_ ->
                commitmentBonus 10
                    |> String.fromFloat
                    |> Expect.equal "0.23978952727983707"
        , test "15 year" <|
            \_ ->
                commitmentBonus 15
                    |> String.fromFloat
                    |> Expect.equal "0.2772588722239781"
        ]
