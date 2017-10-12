module Main exposing (..)

import String exposing (toLower)
import Html exposing (..)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (onClick)
import NewStyle exposing (..)
import Set exposing (empty, member, insert)
import Data


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- model


type alias Model =
    { bio : String
    , projects : List Project
    , statuses : List String
    , technologies : List String
    , categories : List String
    , filterBy : String
    }


type alias Result =
    { bio : String
    , projects : List Project
    }


type alias Project =
    { id : Int
    , name : String
    , timeline : String
    , status : String
    , categories : List String
    , technologies : List String
    , link : String
    , src_link : String
    , description : String
    }


decodeResult : String -> Result
decodeResult json =
    case Json.Decode.decodeString modelDecoder json of
        Ok model ->
            model

        Err errorMessage ->
            { bio = "Error"
            , projects = []
            }


modelDecoder : Decoder Result
modelDecoder =
    Json.Decode.Pipeline.decode Result
        |> required "bio" string
        |> required "projects" (list projectDecoder)


projectDecoder : Decoder Project
projectDecoder =
    Json.Decode.Pipeline.decode Project
        |> required "id" int
        |> required "name" string
        |> required "timeline" string
        |> required "status" string
        |> required "categories" (list string)
        |> required "technologies" (list string)
        |> required "link" string
        |> required "src_link" string
        |> required "description" string


unique : List comparable -> List comparable
unique list =
    uniqueHelp identity Set.empty list


uniqueHelp : (a -> comparable) -> Set.Set comparable -> List a -> List a
uniqueHelp f existing remaining =
    case remaining of
        [] ->
            []

        first :: rest ->
            let
                computedFirst =
                    f first
            in
                if Set.member computedFirst existing then
                    uniqueHelp f existing rest
                else
                    first :: uniqueHelp f (Set.insert computedFirst existing) rest


initialModel : Model
initialModel =
    let
        result =
            decodeResult Data.json
    in
        { bio = result.bio
        , projects = result.projects
        , filterBy = ""
        , statuses = unique (List.concat (List.map (\p -> [ p.status ]) result.projects))
        , technologies = unique (List.concat (List.map (\p -> p.technologies) result.projects))
        , categories = unique (List.concat (List.map (\p -> p.categories) result.projects))
        }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = Clear
    | UpdateFilter String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Clear ->
            ( initialModel, Cmd.none )

        UpdateFilter newFilter ->
            ( filterProjects initialModel newFilter, Cmd.none )


filterProjects : Model -> String -> Model
filterProjects model newFilter =
    let
        newProjects =
            List.filter (\p -> (List.member newFilter (flattenTags p))) model.projects
    in
        { model
            | filterBy = newFilter
            , projects = newProjects
        }


flattenTags : Project -> List String
flattenTags project =
    let
        newProject =
            project
    in
        newProject.categories ++ newProject.technologies ++ [ newProject.status ]



-- VIEW


view : Model -> Html Msg
view model =
    Element.layout stylesheet <|
        column Main
            [ paddingLeft 17, paddingTop 3, width (px 900) ]
            [ header model.bio
            , content model
            ]


header bio =
    column Header
        [ paddingBottom 25 ]
        [ el Title [ moveLeft 2 ] (Element.text "Patrick Kolodgy")
        , navBar
        , el None [ paddingTop 12 ] (Element.text bio)
        ]


navBar =
    row Nav
        [ spacing 10, paddingTop 4 ]
        [ el None [] (Element.text "Brooklyn, NY")
        , el None [] (Element.text "pkolodgy at gmail")
        , newTab "http://github.com/pkolo" <| el Link [] (Element.text "github")
        , newTab "https://www.linkedin.com/in/pkolodgy/" <| el Link [] (Element.text "linkedin")
        ]


content model =
    row None
        [ spacing 20, paddingTop 2 ]
        [ sideBar model
        , projectList model.projects
        ]


sideBar model =
    column SideBar
        [ width (px 180), spacing 10 ]
        [ el SideBarTitle [] (Element.text "Filter projects by")
        , el Tag [ onClick Clear ] (Element.text "All")
        , filterWidget "Status" model.statuses
        , filterWidget "Technologies" model.technologies
        , filterWidget "Categories" model.categories
        , footer
        ]


footer =
    column None
        [ paddingTop 30 ]
        [ el None [] (Element.text "© Patrick Kolodgy, 2017")
        , row None
            []
            [ el None [] (Element.text "Written in Elm")
            , el None [] (Element.text " | ")
            , newTab "https://github.com/pkolo/pkolo.github.io" <| el Link [] (Element.text "src")
            ]
        ]


filterWidget title tagList =
    column None
        []
        (List.map (tagLink) tagList)


projectList projects =
    column None
        [ spacing 25 ]
        (List.map project projects)


project p =
    column None
        [ spacing 5 ]
        [ projectMeta p
        , paragraph ProjectDescription
            []
            [ (Element.text p.description) ]
        , projectTagList "Technologies" p.technologies
        , projectTagList "Categories" p.categories
        ]


projectMeta p =
    row None
        [ spacing 7 ]
        [ el ProjectTitle [ alignBottom ] (Element.text p.name)
        , el (statusStyle p.status) [ alignBottom ] (Element.text ("(" ++ (toLower p.status) ++ ")"))
        , newTab p.link <| el Link [ alignBottom ] (Element.text "link")
        , newTab p.src_link <| el Link [ alignBottom ] (Element.text "src")
        ]


projectTagList title tagList =
    row None
        [ spacing 10 ]
        ([ el None [] (Element.text (title ++ ":")) ]
            ++ (List.map (tagLink) tagList)
        )


tagLink : String -> Element NewStyle variation Msg
tagLink tag =
    el Tag [ onClick (UpdateFilter tag) ] (Element.text tag)


statusStyle status =
    case status of
        "Active" ->
            NewStyle.Active

        "Inactive" ->
            NewStyle.Inactive

        "In Progress" ->
            NewStyle.InProgress

        _ ->
            NewStyle.Inactive