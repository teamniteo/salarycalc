module Tests exposing
    ( cityImpact
    , commitmentBonus
    , defaultSalary
    , tenureImpact
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import List.Extra as List
import SalaryCalculator exposing (City(..), Role(..), salary, tenureDetail)
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
                , role = SoftwareEngineer
                , city = Ljubljana
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


{-| Note: Cities are ordered from most to least expensive. This is significant for the cityImpact test below.
-}
cities =
    [ SanFrancisco
    , London
    , Amsterdam
    , Berlin
    , Barcelona
    , Lisbon
    , Ljubljana
    , Maribor
    , Bucharest
    , NoviSad
    , Davao
    , Delhi
    , Kharkiv
    ]


roles =
    [ PrincipalSoftwareEngineer
    , LeadSoftwareEngineer
    , SoftwareEngineer
    , JuniorSoftwareEngineer
    , JuniorProgrammer
    , SeniorProductMarketingManager
    , ProductMarketingManager
    , SeniorDigitalMarketingSpecialist
    , DigitalMarketingSpecialist
    , MarketingAssociate
    , PrincipalDesigner
    , LeadDesigner
    , SeniorDesigner
    , Designer
    , JuniorDesigner
    , SeniorOperationsManager
    , OperationsManager
    , TechnicalSupportSpecialist
    , CustomerSupportAssociate
    , CustomerSupportSpecialist
    ]


years =
    List.range 0 24


defaults =
    SalaryCalculator.init "https://niteo.co/salary-calculator"
        |> Tuple.first


tenureImpact : Test
tenureImpact =
    let
        tenureTest : Role -> City -> Int -> Test
        tenureTest role city tenure =
            let
                title =
                    String.join " "
                        [ (SalaryCalculator.roleDetail role).name
                        , "living in"
                        , (SalaryCalculator.cityDetail city).name
                        , "with tenure of"
                        , String.fromInt tenure
                        , "earns more than with tenure of"
                        , String.fromInt (tenure - 1)
                        ]
            in
            test title
                (\_ ->
                    Expect.greaterThan
                        (salary { defaults | role = role, tenure = tenure })
                        (salary { defaults | role = role, tenure = tenure + 1 })
                )
    in
    describe "Longer tenure always results in" <|
        List.lift3 tenureTest roles cities years


{-| Note: This suit depends on cities list above being ordered from most to least expenisve.
-}
cityImpact : Test
cityImpact =
    let
        personaSuit : ( Role, Int ) -> Test
        personaSuit ( role, tenure ) =
            let
                title =
                    [ (SalaryCalculator.roleDetail role).name
                    , "with a tenure of"
                    , String.fromInt tenure
                    , "years..."
                    ]
                        |> String.join " "
            in
            cities
                |> pairs
                |> List.map (citiesTest role tenure)
                |> describe title

        personas : List ( Role, Int )
        personas =
            List.lift2 Tuple.pair roles years

        citiesTest : Role -> Int -> ( City, City ) -> Test
        citiesTest role tenure ( a, b ) =
            let
                title =
                    [ "...living in"
                    , (SalaryCalculator.cityDetail a).name
                    , "earns at least as much as if she would live in"
                    , (SalaryCalculator.cityDetail b).name
                    ]
                        |> String.join " "
            in
            test title <|
                \() ->
                    Expect.atLeast
                        (salary
                            { defaults
                                | role = role
                                , tenure = tenure
                                , city = b
                            }
                        )
                        (salary
                            { defaults
                                | role = role
                                , tenure = tenure
                                , city = a
                            }
                        )
    in
    describe "Salaries are higher in more expensive cities" <|
        List.map personaSuit personas


{-| Helper that given a list of elements returns a list of tuples with two neighboring elements

    pairs [ SanFrancisco, London, Amsterdam, Berlin ]
    -- [( SanFrancisco, London ), ( London, Amsterdam ), ( Amsterdam, Berlin )]

Used for comparing salaries in different cities.

-}
pairs : List a -> List ( a, a )
pairs list =
    case list of
        [] ->
            []

        a :: [] ->
            []

        a :: b :: rest ->
            ( a, b ) :: pairs (b :: rest)
