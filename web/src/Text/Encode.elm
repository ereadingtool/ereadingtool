module Text.Encode exposing (textEncoder)

import Json.Encode as Encode
import Text.Model
import Text.Section.Encode exposing (textSectionsEncoder)


textEncoder : Text.Model.Text -> Encode.Value
textEncoder text =
    let
        conclusion =
            case text.conclusion of
                Just concln ->
                    [ ( "conclusion", Encode.string concln ) ]

                Nothing ->
                    []
    in
    Encode.object <|
        [ ( "introduction", Encode.string text.introduction )
        , ( "title", Encode.string text.title )
        , ( "source", Encode.string text.source )
        , ( "author", Encode.string text.author )
        , ( "difficulty", Encode.string text.difficulty )
        , ( "text_sections", textSectionsEncoder text.sections )
        , ( "tags"
          , Encode.list Encode.string <|
                case text.tags of
                    Just tags ->
                        tags

                    Nothing ->
                        []
            --   , Encode.list
            --         (case text.tags of
            --             Just tags ->
            --                 List.map (\tag -> Encode.string tag) tags
            --             _ ->
            --                 []
            --         )
          )
        ]
            ++ conclusion
