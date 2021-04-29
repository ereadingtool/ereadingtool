module Pages.CreatorGuide exposing (Model, Msg, Params, page)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (alt, class, src, title)
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
    = SafeModel ()


init : Shared.Model -> Url Params -> ( SafeModel, Cmd Msg )
init shared { params } =
    ( SafeModel ()
    , Cmd.none
    )



-- UPDATE


type Msg
    = Nop


update : Msg -> SafeModel -> ( SafeModel, Cmd Msg )
update msg (SafeModel model) =
    case msg of
        Nop ->
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
    { title = "Content Creator Guide"
    , body =
        [ viewGuide ]
    }


viewGuide : Html Msg
viewGuide =
    div [ class "creator-guide" ]
        [ viewIntroduction
        , viewCreateTextFirst
        , viewCreateTextFirstImage
        , viewCreateTextSecond
        , viewCreateTextSecondImage
        , viewEditTextFirst
        , viewEditTextFirstImage
        , viewEditTextSecond
        , viewEditTextSecondImage
        , viewEditTextThird
        , viewEditTextThirdImage
        , viewEditTextFourth
        , viewEditTextFourthImage
        , viewEditTextFifth
        , viewGlossing
        ]


viewIntroduction : Html Msg
viewIntroduction =
    Markdown.toHtml [] """

# Content Creator Guide

This guide describes the basic guidelines to follow when you are creating or editing a content block in STAR.
A content block includes: an authentic text, comprehension questions, feedback to the comprehension questions, 
brief pre-reading and post-reading comments, and vocabulary glossing. Following these guidelines will ensure 
that the whole content block works well for students when they read passages in the STAR application. You 
might want to keep this guide open while creating or editing content blocks as a quick reference.

Suggestion: Gather, create, and edit all of the elements of a context block except vocabulary glosses in a 
word processing document. When you have a text, and you’ve edited the pre- and post- reading comments, 
comprehension questions, feedback, then you can cut and paste the elements into the STAR content creation form.
"""


viewCreateTextFirst : Html Msg
viewCreateTextFirst =
    Markdown.toHtml [] """
## Creating a text

To create a new content block, select "Create" from the blue navigation bar at the top of the site. You will 
come to a page that has two tabs: “Text” and “Translations.” You will enter all the components of the content 
block (except vocabulary glossing) on the “Text” tab. Everything related to vocabulary glossing is handled on 
the “Translations” tab. 

- **Text Title.** Put the title of the reading in this text box.  The text title will appear in the text search 
  menu when a student is looking for a text to read. Text titles should be in English, and be informative enough 
  so that students can see if they want to read further, but not too revealing so that they don’t have to read 
  the text. For texts taken from news sources, use a variation on the original title of the article. For excerpts 
  from longer works, you will need to create a title appropriate to the excerpt.
- **Text Introduction.** This is the place for any pre-reading commentary you want the student to see before they 
  start to read the text. The brief (usually a single sentence) commentary in English should orient the reader to 
  the genre and original context of the passage. Students see this pre-reading message after they have selected a 
  text, but before they start reading it.
- **Text Author.** The author who wrote the source text, if noted in the article or selection. The author name 
  should be provided in Cyrillic Russian. Leave blank for texts (such as announcements) that do not have a 
  specific author.
- **Text Difficulty.** This will set the difficulty of the text and related questions. Please consult the
  [2012 ACTFL Proficiency Guidelines](https://www.actfl.org/sites/default/files/guidelines/ACTFLProficiencyGuidelines2012.pdf)
  when assigning a difficulty level. Remember to consider text type, its syntactic complexity, and question type(s)
  in setting the difficulty level. Difficulty level will be one of the main features that students will use in 
  finding texts to read.
- **Text Source.** Link to the webpage where the source text originally appeared or provide bibliographic details 
  about the original publication. This information is for internal purposes only, and students will not see it.
- **Text Conclusion.** This is the place to add any post-reading commentary about a text.  If the original text 
  had links to other websites, those links can be placed here in the post-reading commentary. If the content of 
  the text strongly suggests a topic that might be of further interest to a student, you can add a link to that 
  external Russian-language site for additional reading. Conclusions are optional, but they do add value in 
  motivating students to learn more about Russian culture. Concluding commentary can be written in English.
  """

viewCreateTextFirstImage : Html Msg
viewCreateTextFirstImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/1.png"
            , alt (viewAltText "1" altTexts)
            , title (viewAltText "1" altTexts)
            ] 
            [] 
        ]


viewCreateTextSecond : Html Msg
viewCreateTextSecond =
    Markdown.toHtml [] """
- **Text Tags.** Select all the content tags that are appropriate to the topics covered in the original reading. 
  You can select as many tags as are appropriate. Tags help students find texts that match their personal interests.
  Content creators who want to keep specific texts “in reserve” for testing or for research studies should select 
  the tag “Hidden.” This creates a Content block that does not show up in students’ search menus, although it can 
  be accessed by students if the instructor shares the specific URL with the students.
- **Text Sections.** In this and following text boxes you will place the original reading. Each text should be 
  broken into parts that are followed by comprehension questions related to that section. If a reading has only one 
  question, then it will have only one text section. Use the questions as ways to guide a struggling reader who 
  wants to check their understanding of the text at various points along the way.
- Before adding text to the textbox, prepare the original reading text by removing any links or text ornaments 
  (font size shifts, indenting, italics,  etc.). Paste the Russian text of the first text section into the text box 
  using Control-Shift-V (Command-Shift-V on a Mac) to remove formatting.
- Prepare the comprehension questions related to the first section of the text. Comprehension questions should be in 
  English. The app will handle multiple choice questions with two, three, or four answer options.  You should delete 
  unused answer options by highlighting the unused answer line, and clicking the delete button that appears on the right.
- Be sure to indicate which answer is the correct one by clicking the radio button to the left of the answer. The app 
  allows only one answer to be correct. You do not need to number or letter answer options. The app does this automatically, 
  as it automatically shuffles the possible answer options between readings.
- The textbox for feedback will appear when you enter possible answers.  You should provide as much detail as you can in 
  the feedback to both correct and incorrect answers. The feedback is the place where you as content creator can help the 
  student understand the original text, especially any syntactically complex features of the text. We recommend that the 
  feedback be written in English with quotations from the original text so that students can see how the words of the 
  original text come to create that meaning in English. This detailed feedback is where the student will learn to improve 
  the accuracy of their reading. Each text section and its related questions will appear to the student reader on a separate 
  page.
- To add a second or third question to the same text section, click the option “Add question.” If you make a mistake in 
  adding a question or answer options, or feedback, you may want to delete the whole question and related feedback. To delete 
  a question, put a check in the box next to the question and click the “Delete selected question.”
- Continue creating additional text sections with their questions and feedback, by clicking on the add text section. You can 
  add as many sections to the text as you like, and each section can have multiple questions associated with it.  You can 
  remove a single text section, or remove a whole text, by selecting those options. There are no options to restore a deleted 
  text section, question, or whole text. This is another reason why users are strongly encouraged to gather all parts of a 
  content block and edit them in a word processing program before adding a content block to the app.
- When you have finished filling out all of the sections for a text, select "Save Text" at the bottom right of the text editor. 
  You will not be able to save your work until you have provided information in all the required fields. We also recommend not 
  selecting “Save Text” until you’ve added all the components of the content block, not just the required ones.
- When you select “Save Text,” your content block is queued up with a service that does a first pass automatic glossing for 
  all the words in the text. This automatic glossing does not take place immediately, and on the tab “Translations” you will 
  see a notification (“`⏳ Text queued for translation service processing`"), until the processing is finished. When the service 
  has completed its first pass glossing and it is ready for review, you will see on the tab “Translations” the notification: 
  "`✔️ Translation service has processed this text`”. **IMPORTANT:** This first pass glossing needs to be reviewed and refined, 
  but you **must not** start that work, until the translation service has completely processed the text. The glossing service 
  runs once a day, and it may take several days for a very long text to be completely glossed.
"""


viewCreateTextSecondImage : Html Msg
viewCreateTextSecondImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/2.png"
            , alt (viewAltText "2" altTexts)
            , title (viewAltText "2" altTexts)
            ] 
            [] 
        ]

viewEditTextFirst : Html Msg
viewEditTextFirst =
    Markdown.toHtml [] """
## Editing a text

This app has limited editing capabilities.

### In editing mode 

### Tab labeled "Text"
You may edit the text title, introduction, author, difficulty, source, conclusion, tags, questions and feedback freely. All 
changes will be saved, when you select “Save text.” 

You should **NOT** edit the reading passages in the individual text sections textboxes, because the methods we use for 
completing the first pass automatic glossing rely on the words remaining in their exact order and spacing. Even a small change 
(as small as adding a space) is likely to break the automatic glosses and cause unpredictable behavior for the student user.
If you detect any defect in a reading passage, you **MUST** delete the entire text section, add a new text section with the 
corrected source text of the reading passage. The new corrected text section will be queued for first pass automatic glossing. 
Replacing the whole text section will avoid problems for the student user.
"""


viewEditTextFirstImage : Html Msg
viewEditTextFirstImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/3.png"
            , alt (viewAltText "3" altTexts)
            , title (viewAltText "3" altTexts)
            ] 
            [] 
        ]


viewEditTextSecond : Html Msg
viewEditTextSecond =
    Markdown.toHtml [] """
### Tab labeled "Translations"
You can and will need to refine vocabulary information that the automatic glossing has retrieved.

The automatic glossing retrieves: the dictionary head word form of a text word (i.e., the lemma), grammatical information about 
each text word (i.e, POS, case, tense), and the five most frequent English equivalents for the word.

You should check that the automatic parser has correctly identified the text word’s lemma and grammatical information. Corrections 
to the lemma and grammatical information can be made, by selecting the correct feature and adding the new information.  The automatic 
parser generally is good at distinguishing well-known homonyms (i.e., стали = became”  from стали = of steel); it works less well 
on proper nouns and adjectives, new words and neologisms.

Below the grammatical information, you will need to pick the best English equivalent for the context. You should designate the best 
equivalent for the context by adding a check mark to the right of that entry. Should none of the equivalents offered work for the 
context, you can add a suitable English equivalent of your own by writing it into the text box and clicking the + sign.
"""

viewEditTextSecondImage : Html Msg
viewEditTextSecondImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/4.png"
            , alt (viewAltText "4" altTexts)
            , title (viewAltText "4" altTexts)
            ] 
            [] 
        ]


viewEditTextThird : Html Msg
viewEditTextThird =
    Markdown.toHtml [] """
If the text words form part of a multi-word unit that should really be glossed together (i.e., потому что = because; в основном = basically), 
it is possible to “merge” text words into a unit so that only one gloss is displayed for the whole unit. To merge words, start with the 
first one appearing in the text, click to bring up the current glossing, select the next word(s) in the phrase that you want to merge. 
When all of the words have been selected, click merge on the final word’s glossing dialog box. After you click “merge,” the gloss will 
disappear and you can click the new merged version of the words and add the appropriate equivalent for the whole phrase.
"""


viewEditTextThirdImage : Html Msg
viewEditTextThirdImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/5.png"
            , alt (viewAltText "5" altTexts)
            , title (viewAltText "5" altTexts)
            ] 
            [] 
        ]


viewEditTextFourth : Html Msg
viewEditTextFourth =
    Markdown.toHtml [] """
### Add text word
The automatic first pass glossing may not be able to recognize all the words in the text. If a word has not been processed by the automatic 
service, you can add information about the unrecognized text word clicking on "Add as text word."  Important. When adding text words, start 
from the beginning of the text and move forward through the words from left to right, top to bottom. After adding a text word, you may need 
to try refreshing the page to make sure that the text word has been saved. 
"""

viewEditTextFourthImage =
    div [ class "guide-image-container"] 
        [ img 
            [ class "guide-image"
            , src "/public/img/tutorial/creator/6.png"
            , alt (viewAltText "6" altTexts)
            , title (viewAltText "6" altTexts)
            ] 
            [] 
        ]


viewEditTextFifth : Html Msg
viewEditTextFifth =
    Markdown.toHtml [] """
### Save for all
When a text word is selected, a "Save for all" option may be available. Selecting “Save for all” will apply the glossing details of the 
selected word to all other matching text word instances across the text. Note that “Save for all” does not support words that have been merged.

### Important considerations in glossing words
These glosses are available to students as they read a text, and they should give the basic dictionary information about a word. If the word 
forms part of a complicated metaphor or plays a key role in the syntax of the reading passage, do not try to convey that information in a 
vocabulary gloss. That kind of information is best made available to readers in the bilingual feedback to the comprehension questions. The 
vocabulary glossing is primarily designed to help readers retrieve the basic dictionary meanings. These basic meanings can be saved by students 
for vocabulary learning.

Students using the app can save text words that they have looked up to a “My words” list. When the student adds a text word to that list, they 
will get the lemmas, the immediate context (5 words left and five words right) and the English equivalent you have selected for the context. 
They can review their “My words list” (saved as a PDF), or export them (in CSV format) to use in flashcard programs, such as 
[Quizlet](https://quizlet.com/).
"""


viewGlossing : Html Msg
viewGlossing =
    Markdown.toHtml [] """
## Previewing a Content block as a student

Once you’ve added a complete content block, you can use the Texts link in the top menu bar to preview the text as a student reader will see and 
experience it. This preview mode will allow you to check that the text reads correctly, that the glosses are showing correctly, the correct 
answer is showing to each question, and that any pre-reading and post-reading comments is appropriate. Be sure to check any links you’ve added 
to the post-reading text. 

Once on the Text search page, find the newly added content block by filtering for difficulty level and content tags. Then click to the title to 
start the reading.  Make notes of corrections to be made, and then return to the Edit mode to make your changes. Note that any fixes to the 
original reading text sections will need to be made by completely replacing the text.
"""



-- ALT TEXTS


viewAltText : String -> Dict String String -> String
viewAltText id texts =
    case Dict.get id texts of
        Just text ->
            text

        Nothing ->
            ""


altTexts : Dict String String
altTexts =
    Dict.fromList
        [ ( "1", "" )
        , ( "2", "" )
        ]