module Pages.CreatorGuide exposing (Model, Msg, Params, page)

import Html exposing (..)
import Html.Attributes exposing (class)
import Markdown
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)


page : Page Params Model Msg
page =
    Page.protectedInstructorApplication
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    Maybe SafeModel


type SafeModel
    = SafeModel
        { protectedInfo : String
        }


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel
        { protectedInfo = "For authenticated eyes only"
        }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        ReplaceMe ->
            ( SafeModel model, Cmd.none )


save : SafeModel -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> SafeModel -> ( SafeModel, Cmd Msg )
load shared safeModel =
    ( safeModel, Cmd.none )


subscriptions : SafeModel -> Sub Msg
subscriptions (SafeModel model) =
    Sub.none



-- VIEW


view : SafeModel -> Document Msg
view (SafeModel model) =
    { title = "ProtectedApplicationTemplate"
    , body =
        [ viewGuide ]
    }


viewGuide : Html Msg
viewGuide =
    div [ class "editor-guide" ]
        [ viewIntroduction
        , viewCreateText
        , viewEditText
        , viewGlossing
        ]


viewIntroduction : Html Msg
viewIntroduction =
    Markdown.toHtml [] """

# Content Creator Guide

This guide lays out a few guidelines for creating and editing texts. Following
these guidelines will ensure that texts work well for students reading in the text
reader. You might want to keep this guide open while creating or editing texts as 
a quick reference.
"""


viewCreateText : Html Msg
viewCreateText =
    Markdown.toHtml [] """
## Creating a text

To create a new text, select "Create" from the blue navigation bar at the top of 
the site. A text should include

- **Text Title.** The text title. The title appears in the text search menu when a student
  is looking for a text to read.
- **Text Introduction.** A brief introduction preparing the student for the reading. Students
  see this after they have selected a text, but before they start reading it.
- **Text Author.** The author who wrote the source text.
- **Text Difficulty.** The difficulty of the text. Please use the ??? guidelines when assigning
  a difficuly.
- **Text Source.** Link to the webpage where the source text originally appeared. (Optional.)
- **Text Conclusion.** A conclusion that follows the reading.
- **Text Tags.** Tags indicating topics discussed in a text.
- **Text Sections.** The sections of the reading. Each section appears as a separate page in the 
  text reader and has a set of questions, answers, and answer feedback associated with it.

You can add as many sections to the text as you like, and each section can have multiple questions
associated with it.

When you have finished filling out all of the sections for a text, select "Save Text" at the bottom
right of the text editor. Your text will be queued up with a translation service to perform a first
pass over the text. For example, a Russian text might be translated by Yandex.

**Important.** Do not start working in the translations tab of text editor until the translation 
service has processed the text.
"""


viewEditText : Html Msg
viewEditText =
    Markdown.toHtml [] """
## Editing a text

After a text has been created and processed by the translation service, you can edit parts of the text, 
add and assign translations, add grammatical information, and merge words together into meaningful
phrases. We call these last three "glossing" a word.

**Important.** The one thing that you cannot edit is the source text in an existing text section. Once 
translations are applied, the order of words in the text matters and edits to the source text are likely
to cause unexpected behavior. If a source text must be edited, delete the entire text section, add a new
text section with the updated source text, wait for the translation service to process the new text, and
go reassign any glossing in the translations tab.

The text title, introduction, author, difficulty, source, conclusion, and tags can all be edited.
"""


viewGlossing : Html Msg
viewGlossing =
    Markdown.toHtml [] """
## Glossing

You can assign translations, add grammatical information, and merge words in the translations tab. The 
source text from each text section appears as a paragraph.

### Add text word

If a word has not been procesed by the translation service, "Add as text word" will appear and no 
translations will be shown. Assuming the translation service made its first pass, it failed to process
the word and you can add it as a text word.

**Important.** When adding text words, start from beginning of the text and move forward through the words 
from left to right. If adding a text word does nothing, try refreshing the page to see if it in fact worked.

### Add a lemma or grammeme

You can add a lemma or grammatical information to a word.

"""
