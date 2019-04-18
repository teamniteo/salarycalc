module Tests exposing
    ( testCommitmentBonus
    , testHumanizeCommitmentBonus
    , testHumanizeTenure
    , testLookupByName
    , testSalary
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import List.Extra as List
import SalaryCalculator exposing (City, Role, commitmentBonus, humanizeCommitmentBonus, humanizeTenure, lookupByName, salary)
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


testHumanizeCommitmentBonus : Test
testHumanizeCommitmentBonus =
    describe "Commitment Bonus is viewed as percentages"
        [ test "0" <|
            \_ ->
                humanizeCommitmentBonus 0
                    |> Expect.equal "0%"
        , test "0.011" <|
            \_ ->
                humanizeCommitmentBonus 0.011
                    |> Expect.equal "1%"
        , test "0.125" <|
            \_ ->
                humanizeCommitmentBonus 0.125
                    |> Expect.equal "13%"
        ]


testLookupByName : Test
testLookupByName =
    describe "Get item in list based on name"
        [ test "item exists" <|
            \_ ->
                lookupByName "foo" [ { name = "foo" }, { name = "bar" } ]
                    |> Expect.equal (Just { name = "foo" })
        , test "item does not exist" <|
            \_ ->
                lookupByName "bla" [ { name = "foo" }, { name = "bar" } ]
                    |> Expect.equal Nothing
        ]


testHumanizeTenure : Test
testHumanizeTenure =
    describe "Tenure has a properly pluralized 'years' suffix"
        [ test "0" <|
            \_ ->
                humanizeTenure 0
                    |> Expect.equal "Just started"
        , test "0.011" <|
            \_ ->
                humanizeTenure 1
                    |> Expect.equal "1 year"
        , test "0.125" <|
            \_ ->
                humanizeTenure 5
                    |> Expect.equal "5 years"
        ]
