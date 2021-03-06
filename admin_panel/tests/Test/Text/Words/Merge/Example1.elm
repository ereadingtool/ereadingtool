module Test.Text.Words.Merge.Example1 exposing (test_model, testMerge, new_text_words)

import Array exposing (Array)
import Dict exposing (Dict)

import OrderedDict exposing (OrderedDict)

import Expect exposing (Expectation)

import Text.Translations exposing (..)
import Text.Translations.Model exposing (Model)
import Text.Translations.TextWord as TextWord
import Text.Translations.Word.Instance exposing (WordInstance)
import Text.Translations.Word.Kind exposing (WordKind(..))


section_one_words =
    Dict.fromList
        [ ( "а", Array.fromList [ TextWord.new (TextWordId 10855) (SectionNumber 1) 0 "а" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32776, endpoint = "/api/text/word/10855/translation/32776/", correct_for_context = True, text = "and" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10855/", translations = "/api/text/word/10855/translation/" } ] )
        , ( "будет", Array.fromList [ TextWord.new (TextWordId 10862) (SectionNumber 1) 0 "будет" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "futr" ) ])) (Just [ { id = 32799, endpoint = "/api/text/word/10862/translation/32799/", correct_for_context = True, text = "be" }, { id = 32800, endpoint = "/api/text/word/10862/translation/32800/", correct_for_context = False, text = "exist" }, { id = 32801, endpoint = "/api/text/word/10862/translation/32801/", correct_for_context = False, text = "lead" }, { id = 32802, endpoint = "/api/text/word/10862/translation/32802/", correct_for_context = False, text = "fare" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10862/", translations = "/api/text/word/10862/translation/" } ] )
        , ( "был", Array.fromList [ TextWord.new (TextWordId 10831) (SectionNumber 1) 0 "был" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32698, endpoint = "/api/text/word/10831/translation/32698/", correct_for_context = True, text = "be" }, { id = 32699, endpoint = "/api/text/word/10831/translation/32699/", correct_for_context = False, text = "exist" }, { id = 32700, endpoint = "/api/text/word/10831/translation/32700/", correct_for_context = False, text = "lead" }, { id = 32701, endpoint = "/api/text/word/10831/translation/32701/", correct_for_context = False, text = "fare" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10831/", translations = "/api/text/word/10831/translation/" } ] )
        , ( "были", Array.fromList [ TextWord.new (TextWordId 10821) (SectionNumber 1) 0 "были" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32671, endpoint = "/api/text/word/10821/translation/32671/", correct_for_context = True, text = "be" }, { id = 32672, endpoint = "/api/text/word/10821/translation/32672/", correct_for_context = False, text = "exist" }, { id = 32673, endpoint = "/api/text/word/10821/translation/32673/", correct_for_context = False, text = "lead" }, { id = 32674, endpoint = "/api/text/word/10821/translation/32674/", correct_for_context = False, text = "fare" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10821/", translations = "/api/text/word/10821/translation/" } ] )
        , ( "в", Array.fromList [ TextWord.new (TextWordId 10829) (SectionNumber 1) 0 "в" (Just (Dict.fromList [ ( "pos", "PREP" ) ])) (Just [ { id = 32695, endpoint = "/api/text/word/10829/translation/32695/", correct_for_context = True, text = "V" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10829/", translations = "/api/text/word/10829/translation/" } ] )
        , ( "вот", Array.fromList [ TextWord.new (TextWordId 10827) (SectionNumber 1) 0 "вот" (Just (Dict.fromList [ ( "pos", "PRCL" ) ])) (Just [ { id = 32689, endpoint = "/api/text/word/10827/translation/32689/", correct_for_context = True, text = "here" }, { id = 32690, endpoint = "/api/text/word/10827/translation/32690/", correct_for_context = False, text = "lo" }, { id = 32691, endpoint = "/api/text/word/10827/translation/32691/", correct_for_context = False, text = "that" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10827/", translations = "/api/text/word/10827/translation/" }, TextWord.new (TextWordId 10828) (SectionNumber 1) 1 "вот" (Just (Dict.fromList [ ( "pos", "PRCL" ) ])) (Just [ { id = 32692, endpoint = "/api/text/word/10828/translation/32692/", correct_for_context = True, text = "here" }, { id = 32693, endpoint = "/api/text/word/10828/translation/32693/", correct_for_context = False, text = "lo" }, { id = 32694, endpoint = "/api/text/word/10828/translation/32694/", correct_for_context = False, text = "that" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10828/", translations = "/api/text/word/10828/translation/" } ] )
        , ( "вполне", Array.fromList [ TextWord.new (TextWordId 10822) (SectionNumber 1) 0 "вполне" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32675, endpoint = "/api/text/word/10822/translation/32675/", correct_for_context = True, text = "quite" }, { id = 32676, endpoint = "/api/text/word/10822/translation/32676/", correct_for_context = False, text = "completely" }, { id = 32677, endpoint = "/api/text/word/10822/translation/32677/", correct_for_context = False, text = "perfectly" }, { id = 32678, endpoint = "/api/text/word/10822/translation/32678/", correct_for_context = False, text = "very" }, { id = 32679, endpoint = "/api/text/word/10822/translation/32679/", correct_for_context = False, text = "easily" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10822/", translations = "/api/text/word/10822/translation/" } ] )
        , ( "группой", Array.fromList [ TextWord.new (TextWordId 10841) (SectionNumber 1) 0 "группой" (Just (Dict.fromList [ ( "form", "ablt" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32735, endpoint = "/api/text/word/10841/translation/32735/", correct_for_context = True, text = "group" }, { id = 32736, endpoint = "/api/text/word/10841/translation/32736/", correct_for_context = False, text = "team" }, { id = 32737, endpoint = "/api/text/word/10841/translation/32737/", correct_for_context = False, text = "party" }, { id = 32738, endpoint = "/api/text/word/10841/translation/32738/", correct_for_context = False, text = "panel" }, { id = 32739, endpoint = "/api/text/word/10841/translation/32739/", correct_for_context = False, text = "cluster" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10841/", translations = "/api/text/word/10841/translation/" } ] )
        , ( "желающих", Array.fromList [ TextWord.new (TextWordId 10858) (SectionNumber 1) 0 "желающих" (Just (Dict.fromList [ ( "form", "gent" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32783, endpoint = "/api/text/word/10858/translation/32783/", correct_for_context = True, text = "wishing" }, { id = 32784, endpoint = "/api/text/word/10858/translation/32784/", correct_for_context = False, text = "willing" }, { id = 32785, endpoint = "/api/text/word/10858/translation/32785/", correct_for_context = False, text = "wish" }, { id = 32786, endpoint = "/api/text/word/10858/translation/32786/", correct_for_context = False, text = "interested person" }, { id = 32787, endpoint = "/api/text/word/10858/translation/32787/", correct_for_context = False, text = "wanting" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10858/", translations = "/api/text/word/10858/translation/" } ] )
        , ( "и", Array.fromList [ TextWord.new (TextWordId 10825) (SectionNumber 1) 0 "И" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32687, endpoint = "/api/text/word/10825/translation/32687/", correct_for_context = True, text = "and" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10825/", translations = "/api/text/word/10825/translation/" }, TextWord.new (TextWordId 10826) (SectionNumber 1) 1 "И" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32688, endpoint = "/api/text/word/10826/translation/32688/", correct_for_context = True, text = "and" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10826/", translations = "/api/text/word/10826/translation/" }, TextWord.new (TextWordId 10842) (SectionNumber 1) 0 "и" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32740, endpoint = "/api/text/word/10842/translation/32740/", correct_for_context = True, text = "and" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10842/", translations = "/api/text/word/10842/translation/" }, TextWord.new (TextWordId 10843) (SectionNumber 1) 1 "и" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32741, endpoint = "/api/text/word/10843/translation/32741/", correct_for_context = True, text = "and" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10843/", translations = "/api/text/word/10843/translation/" } ] )
        , ( "идти", Array.fromList [ TextWord.new (TextWordId 10854) (SectionNumber 1) 0 "идти" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "pos", "INFN" ) ])) (Just [ { id = 32771, endpoint = "/api/text/word/10854/translation/32771/", correct_for_context = True, text = "go" }, { id = 32772, endpoint = "/api/text/word/10854/translation/32772/", correct_for_context = False, text = "walk" }, { id = 32773, endpoint = "/api/text/word/10854/translation/32773/", correct_for_context = False, text = "move" }, { id = 32774, endpoint = "/api/text/word/10854/translation/32774/", correct_for_context = False, text = "take" }, { id = 32775, endpoint = "/api/text/word/10854/translation/32775/", correct_for_context = False, text = "run" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10854/", translations = "/api/text/word/10854/translation/" } ] )
        , ( "интересно", Array.fromList [ TextWord.new (TextWordId 10867) (SectionNumber 1) 0 "интересно" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32816, endpoint = "/api/text/word/10867/translation/32816/", correct_for_context = True, text = "interestingly" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10867/", translations = "/api/text/word/10867/translation/" } ] )
        , ( "как-то", Array.fromList [ TextWord.new (TextWordId 10851) (SectionNumber 1) 0 "как-то" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32757, endpoint = "/api/text/word/10851/translation/32757/", correct_for_context = True, text = "somehow" }, { id = 32758, endpoint = "/api/text/word/10851/translation/32758/", correct_for_context = False, text = "as something" }, { id = 32759, endpoint = "/api/text/word/10851/translation/32759/", correct_for_context = False, text = "like something" }, { id = 32760, endpoint = "/api/text/word/10851/translation/32760/", correct_for_context = False, text = "in some way" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10851/", translations = "/api/text/word/10851/translation/" } ] )
        , ( "комсомольцами", Array.fromList [ TextWord.new (TextWordId 10824) (SectionNumber 1) 0 "комсомольцами" (Just (Dict.fromList [ ( "form", "ablt" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32685, endpoint = "/api/text/word/10824/translation/32685/", correct_for_context = True, text = "Komsomolets" }, { id = 32686, endpoint = "/api/text/word/10824/translation/32686/", correct_for_context = False, text = "young communist" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10824/", translations = "/api/text/word/10824/translation/" } ] )
        , ( "курсе", Array.fromList [ TextWord.new (TextWordId 10819) (SectionNumber 1) 0 "курсе" (Just (Dict.fromList [ ( "form", "loct" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32664, endpoint = "/api/text/word/10819/translation/32664/", correct_for_context = True, text = "course" }, { id = 32665, endpoint = "/api/text/word/10819/translation/32665/", correct_for_context = False, text = "rate" }, { id = 32666, endpoint = "/api/text/word/10819/translation/32666/", correct_for_context = False, text = "policy" }, { id = 32667, endpoint = "/api/text/word/10819/translation/32667/", correct_for_context = False, text = "class" }, { id = 32668, endpoint = "/api/text/word/10819/translation/32668/", correct_for_context = False, text = "path" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10819/", translations = "/api/text/word/10819/translation/" } ] )
        , ( "много", Array.fromList [ TextWord.new (TextWordId 10860) (SectionNumber 1) 0 "много" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32793, endpoint = "/api/text/word/10860/translation/32793/", correct_for_context = True, text = "many" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10860/", translations = "/api/text/word/10860/translation/" } ] )
        , ( "мужем", Array.fromList [ TextWord.new (TextWordId 10814) (SectionNumber 1) 0 "мужем" (Just (Dict.fromList [ ( "form", "ablt" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32643, endpoint = "/api/text/word/10814/translation/32643/", correct_for_context = True, text = "husband" }, { id = 32644, endpoint = "/api/text/word/10814/translation/32644/", correct_for_context = False, text = "man" }, { id = 32645, endpoint = "/api/text/word/10814/translation/32645/", correct_for_context = False, text = "lord" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10814/", translations = "/api/text/word/10814/translation/" } ] )
        , ( "мы", Array.fromList [ TextWord.new (TextWordId 10812) (SectionNumber 1) 0 "Мы" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NPRO" ) ])) (Just [ { id = 32642, endpoint = "/api/text/word/10812/translation/32642/", correct_for_context = True, text = "we" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10812/", translations = "/api/text/word/10812/translation/" }, TextWord.new (TextWordId 10849) (SectionNumber 1) 0 "мы" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NPRO" ) ])) (Just [ { id = 32755, endpoint = "/api/text/word/10849/translation/32755/", correct_for_context = True, text = "we" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10849/", translations = "/api/text/word/10849/translation/" }, TextWord.new (TextWordId 10850) (SectionNumber 1) 1 "мы" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NPRO" ) ])) (Just [ { id = 32756, endpoint = "/api/text/word/10850/translation/32756/", correct_for_context = True, text = "we" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10850/", translations = "/api/text/word/10850/translation/" } ] )
        , ( "на", Array.fromList [ TextWord.new (TextWordId 10816) (SectionNumber 1) 0 "на" (Just (Dict.fromList [ ( "pos", "PREP" ) ])) (Just [ { id = 32651, endpoint = "/api/text/word/10816/translation/32651/", correct_for_context = True, text = "upon" }, { id = 32652, endpoint = "/api/text/word/10816/translation/32652/", correct_for_context = False, text = "at" }, { id = 32653, endpoint = "/api/text/word/10816/translation/32653/", correct_for_context = False, text = "with" }, { id = 32654, endpoint = "/api/text/word/10816/translation/32654/", correct_for_context = False, text = "for" }, { id = 32655, endpoint = "/api/text/word/10816/translation/32655/", correct_for_context = False, text = "to" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10816/", translations = "/api/text/word/10816/translation/" }, TextWord.new (TextWordId 10817) (SectionNumber 1) 1 "на" (Just (Dict.fromList [ ( "pos", "PREP" ) ])) (Just [ { id = 32656, endpoint = "/api/text/word/10817/translation/32656/", correct_for_context = True, text = "upon" }, { id = 32657, endpoint = "/api/text/word/10817/translation/32657/", correct_for_context = False, text = "at" }, { id = 32658, endpoint = "/api/text/word/10817/translation/32658/", correct_for_context = False, text = "with" }, { id = 32659, endpoint = "/api/text/word/10817/translation/32659/", correct_for_context = False, text = "for" }, { id = 32660, endpoint = "/api/text/word/10817/translation/32660/", correct_for_context = False, text = "to" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10817/", translations = "/api/text/word/10817/translation/" } ] )
        , ( "не", Array.fromList [ TextWord.new (TextWordId 10852) (SectionNumber 1) 0 "не" (Just (Dict.fromList [ ( "pos", "PRCL" ) ])) (Just [ { id = 32761, endpoint = "/api/text/word/10852/translation/32761/", correct_for_context = True, text = "not" }, { id = 32762, endpoint = "/api/text/word/10852/translation/32762/", correct_for_context = False, text = "without" }, { id = 32763, endpoint = "/api/text/word/10852/translation/32763/", correct_for_context = False, text = "nor" }, { id = 32764, endpoint = "/api/text/word/10852/translation/32764/", correct_for_context = False, text = "never" }, { id = 32765, endpoint = "/api/text/word/10852/translation/32765/", correct_for_context = False, text = "nothing" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10852/", translations = "/api/text/word/10852/translation/" } ] )
        , ( "ночью", Array.fromList [ TextWord.new (TextWordId 10863) (SectionNumber 1) 0 "ночью" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32803, endpoint = "/api/text/word/10863/translation/32803/", correct_for_context = True, text = "during the night" }, { id = 32804, endpoint = "/api/text/word/10863/translation/32804/", correct_for_context = False, text = "overnight" }, { id = 32805, endpoint = "/api/text/word/10863/translation/32805/", correct_for_context = False, text = "nightly" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10863/", translations = "/api/text/word/10863/translation/" }, TextWord.new (TextWordId 10864) (SectionNumber 1) 1 "ночью" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32806, endpoint = "/api/text/word/10864/translation/32806/", correct_for_context = True, text = "during the night" }, { id = 32807, endpoint = "/api/text/word/10864/translation/32807/", correct_for_context = False, text = "overnight" }, { id = 32808, endpoint = "/api/text/word/10864/translation/32808/", correct_for_context = False, text = "nightly" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10864/", translations = "/api/text/word/10864/translation/" } ] )
        , ( "нужно", Array.fromList [ TextWord.new (TextWordId 10839) (SectionNumber 1) 0 "нужно" (Just (Dict.fromList [ ( "pos", "PRED" ), ( "tense", "pres" ) ])) Nothing (SingleWord Nothing) { text_word = "/api/text/word/10839/", translations = "/api/text/word/10839/translation/" } ] )
        , ( "о", Array.fromList [ TextWord.new (TextWordId 10833) (SectionNumber 1) 0 "о" (Just (Dict.fromList [ ( "pos", "PREP" ) ])) Nothing (SingleWord Nothing) { text_word = "/api/text/word/10833/", translations = "/api/text/word/10833/translation/" } ] )
        , ( "оба", Array.fromList [ TextWord.new (TextWordId 10820) (SectionNumber 1) 0 "оба" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NUMR" ) ])) (Just [ { id = 32669, endpoint = "/api/text/word/10820/translation/32669/", correct_for_context = True, text = "both" }, { id = 32670, endpoint = "/api/text/word/10820/translation/32670/", correct_for_context = False, text = "two" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10820/", translations = "/api/text/word/10820/translation/" } ] )
        , ( "объявили", Array.fromList [ TextWord.new (TextWordId 10857) (SectionNumber 1) 0 "объявили" (Just (Dict.fromList [ ( "aspect", "perf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32781, endpoint = "/api/text/word/10857/translation/32781/", correct_for_context = True, text = "announce" }, { id = 32782, endpoint = "/api/text/word/10857/translation/32782/", correct_for_context = False, text = "advertise" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10857/", translations = "/api/text/word/10857/translation/" } ] )
        , ( "одном", Array.fromList [ TextWord.new (TextWordId 10818) (SectionNumber 1) 0 "одном" (Just (Dict.fromList [ ( "form", "loct" ), ( "pos", "ADJF" ) ])) (Just [ { id = 32661, endpoint = "/api/text/word/10818/translation/32661/", correct_for_context = True, text = "one" }, { id = 32662, endpoint = "/api/text/word/10818/translation/32662/", correct_for_context = False, text = "a" }, { id = 32663, endpoint = "/api/text/word/10818/translation/32663/", correct_for_context = False, text = "alone" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10818/", translations = "/api/text/word/10818/translation/" } ] )
        , ( "организованно", Array.fromList [ TextWord.new (TextWordId 10844) (SectionNumber 1) 0 "организованно" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) Nothing (SingleWord Nothing) { text_word = "/api/text/word/10844/", translations = "/api/text/word/10844/translation/" } ] )
        , ( "пойти", Array.fromList [ TextWord.new (TextWordId 10845) (SectionNumber 1) 0 "пойти" (Just (Dict.fromList [ ( "aspect", "perf" ), ( "pos", "INFN" ) ])) (Just [ { id = 32742, endpoint = "/api/text/word/10845/translation/32742/", correct_for_context = True, text = "go" }, { id = 32743, endpoint = "/api/text/word/10845/translation/32743/", correct_for_context = False, text = "will" }, { id = 32744, endpoint = "/api/text/word/10845/translation/32744/", correct_for_context = False, text = "take" }, { id = 32745, endpoint = "/api/text/word/10845/translation/32745/", correct_for_context = False, text = "start" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10845/", translations = "/api/text/word/10845/translation/" }, TextWord.new (TextWordId 10846) (SectionNumber 1) 1 "пойти" (Just (Dict.fromList [ ( "aspect", "perf" ), ( "pos", "INFN" ) ])) (Just [ { id = 32746, endpoint = "/api/text/word/10846/translation/32746/", correct_for_context = True, text = "go" }, { id = 32747, endpoint = "/api/text/word/10846/translation/32747/", correct_for_context = False, text = "will" }, { id = 32748, endpoint = "/api/text/word/10846/translation/32748/", correct_for_context = False, text = "take" }, { id = 32749, endpoint = "/api/text/word/10846/translation/32749/", correct_for_context = False, text = "start" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10846/", translations = "/api/text/word/10846/translation/" } ] )
        , ( "потом", Array.fromList [ TextWord.new (TextWordId 10856) (SectionNumber 1) 0 "потом" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32777, endpoint = "/api/text/word/10856/translation/32777/", correct_for_context = True, text = "then" }, { id = 32778, endpoint = "/api/text/word/10856/translation/32778/", correct_for_context = False, text = "after" }, { id = 32779, endpoint = "/api/text/word/10856/translation/32779/", correct_for_context = False, text = "next" }, { id = 32780, endpoint = "/api/text/word/10856/translation/32780/", correct_for_context = False, text = "after that" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10856/", translations = "/api/text/word/10856/translation/" } ] )
        , ( "потому", Array.fromList [
            TextWord.new (TextWordId 10868) (SectionNumber 1) 0 "потому"
              (Just (Dict.fromList [ ( "pos", "ADVB" ) ]))
              (Just [
                { id = 32817, endpoint = "/api/text/word/10868/translation/32817/", correct_for_context = True
                , text = "therefore" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10868/"
                , translations = "/api/text/word/10868/translation/" }
           ] )
        , ( "похороны", Array.fromList [ TextWord.new (TextWordId 10847) (SectionNumber 1) 0 "похороны" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32750, endpoint = "/api/text/word/10847/translation/32750/", correct_for_context = True, text = "funeral" }, { id = 32751, endpoint = "/api/text/word/10847/translation/32751/", correct_for_context = False, text = "bury" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10847/", translations = "/api/text/word/10847/translation/" } ] )
        , ( "правильными", Array.fromList [ TextWord.new (TextWordId 10823) (SectionNumber 1) 0 "правильными" (Just (Dict.fromList [ ( "form", "ablt" ), ( "pos", "ADJF" ) ])) (Just [ { id = 32680, endpoint = "/api/text/word/10823/translation/32680/", correct_for_context = True, text = "right" }, { id = 32681, endpoint = "/api/text/word/10823/translation/32681/", correct_for_context = False, text = "correct" }, { id = 32682, endpoint = "/api/text/word/10823/translation/32682/", correct_for_context = False, text = "regular" }, { id = 32683, endpoint = "/api/text/word/10823/translation/32683/", correct_for_context = False, text = "valid" }, { id = 32684, endpoint = "/api/text/word/10823/translation/32684/", correct_for_context = False, text = "true" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10823/", translations = "/api/text/word/10823/translation/" } ] )
        , ( "прощание", Array.fromList [ TextWord.new (TextWordId 10861) (SectionNumber 1) 0 "прощание" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32794, endpoint = "/api/text/word/10861/translation/32794/", correct_for_context = True, text = "farewell" }, { id = 32795, endpoint = "/api/text/word/10861/translation/32795/", correct_for_context = False, text = "parting" }, { id = 32796, endpoint = "/api/text/word/10861/translation/32796/", correct_for_context = False, text = "valediction" }, { id = 32797, endpoint = "/api/text/word/10861/translation/32797/", correct_for_context = False, text = "leave" }, { id = 32798, endpoint = "/api/text/word/10861/translation/32798/", correct_for_context = False, text = "saying goodbye" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10861/", translations = "/api/text/word/10861/translation/" } ] )
        , ( "разговор", Array.fromList [ TextWord.new (TextWordId 10832) (SectionNumber 1) 0 "разговор" (Just (Dict.fromList [ ( "form", "nomn" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32702, endpoint = "/api/text/word/10832/translation/32702/", correct_for_context = True, text = "conversation" }, { id = 32703, endpoint = "/api/text/word/10832/translation/32703/", correct_for_context = False, text = "call" }, { id = 32704, endpoint = "/api/text/word/10832/translation/32704/", correct_for_context = False, text = "speaking" }, { id = 32705, endpoint = "/api/text/word/10832/translation/32705/", correct_for_context = False, text = "talking" }, { id = 32706, endpoint = "/api/text/word/10832/translation/32706/", correct_for_context = False, text = "speak" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10832/", translations = "/api/text/word/10832/translation/" } ] )
        , ( "решили", Array.fromList [ TextWord.new (TextWordId 10866) (SectionNumber 1) 0 "решили" (Just (Dict.fromList [ ( "aspect", "perf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32812, endpoint = "/api/text/word/10866/translation/32812/", correct_for_context = True, text = "solve" }, { id = 32813, endpoint = "/api/text/word/10866/translation/32813/", correct_for_context = False, text = "settle" }, { id = 32814, endpoint = "/api/text/word/10866/translation/32814/", correct_for_context = False, text = "determine" }, { id = 32815, endpoint = "/api/text/word/10866/translation/32815/", correct_for_context = False, text = "elect" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10866/", translations = "/api/text/word/10866/translation/" } ] )
        , ( "с", Array.fromList [ TextWord.new (TextWordId 10813) (SectionNumber 1) 0 "с" (Just (Dict.fromList [ ( "pos", "PREP" ) ])) Nothing (SingleWord Nothing) { text_word = "/api/text/word/10813/", translations = "/api/text/word/10813/translation/" } ] )
        , ( "собирались", Array.fromList [ TextWord.new (TextWordId 10853) (SectionNumber 1) 0 "собирались" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32766, endpoint = "/api/text/word/10853/translation/32766/", correct_for_context = True, text = "go" }, { id = 32767, endpoint = "/api/text/word/10853/translation/32767/", correct_for_context = False, text = "gonna" }, { id = 32768, endpoint = "/api/text/word/10853/translation/32768/", correct_for_context = False, text = "gather" }, { id = 32769, endpoint = "/api/text/word/10853/translation/32769/", correct_for_context = False, text = "meet" }, { id = 32770, endpoint = "/api/text/word/10853/translation/32770/", correct_for_context = False, text = "collect" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10853/", translations = "/api/text/word/10853/translation/" } ] )
        , ( "собраться", Array.fromList [ TextWord.new (TextWordId 10840) (SectionNumber 1) 0 "собраться" (Just (Dict.fromList [ ( "aspect", "perf" ), ( "pos", "INFN" ) ])) (Just [ { id = 32730, endpoint = "/api/text/word/10840/translation/32730/", correct_for_context = True, text = "gather" }, { id = 32731, endpoint = "/api/text/word/10840/translation/32731/", correct_for_context = False, text = "together" }, { id = 32732, endpoint = "/api/text/word/10840/translation/32732/", correct_for_context = False, text = "come together" }, { id = 32733, endpoint = "/api/text/word/10840/translation/32733/", correct_for_context = False, text = "get" }, { id = 32734, endpoint = "/api/text/word/10840/translation/32734/", correct_for_context = False, text = "convene" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10840/", translations = "/api/text/word/10840/translation/" } ] )
        , ( "так", Array.fromList [ TextWord.new (TextWordId 10859) (SectionNumber 1) 0 "так" (Just (Dict.fromList [ ( "pos", "CONJ" ) ])) (Just [ { id = 32788, endpoint = "/api/text/word/10859/translation/32788/", correct_for_context = True, text = "so" }, { id = 32789, endpoint = "/api/text/word/10859/translation/32789/", correct_for_context = False, text = "as" }, { id = 32790, endpoint = "/api/text/word/10859/translation/32790/", correct_for_context = False, text = "true" }, { id = 32791, endpoint = "/api/text/word/10859/translation/32791/", correct_for_context = False, text = "alike" }, { id = 32792, endpoint = "/api/text/word/10859/translation/32792/", correct_for_context = False, text = "in one way" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10859/", translations = "/api/text/word/10859/translation/" } ] )
        , ( "тогда", Array.fromList [ TextWord.new (TextWordId 10848) (SectionNumber 1) 0 "Тогда" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32752, endpoint = "/api/text/word/10848/translation/32752/", correct_for_context = True, text = "then" }, { id = 32753, endpoint = "/api/text/word/10848/translation/32753/", correct_for_context = False, text = "at that time" }, { id = 32754, endpoint = "/api/text/word/10848/translation/32754/", correct_for_context = False, text = "whereupon" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10848/", translations = "/api/text/word/10848/translation/" }, TextWord.new (TextWordId 10865) (SectionNumber 1) 0 "тогда" (Just (Dict.fromList [ ( "pos", "ADVB" ) ])) (Just [ { id = 32809, endpoint = "/api/text/word/10865/translation/32809/", correct_for_context = True, text = "then" }, { id = 32810, endpoint = "/api/text/word/10865/translation/32810/", correct_for_context = False, text = "at that time" }, { id = 32811, endpoint = "/api/text/word/10865/translation/32811/", correct_for_context = False, text = "whereupon" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10865/", translations = "/api/text/word/10865/translation/" } ] )
        , ( "том", Array.fromList [ TextWord.new (TextWordId 10834) (SectionNumber 1) 0 "том" (Just (Dict.fromList [ ( "form", "loct" ), ( "pos", "ADJF" ) ])) (Just [ { id = 32707, endpoint = "/api/text/word/10834/translation/32707/", correct_for_context = True, text = "the" }, { id = 32708, endpoint = "/api/text/word/10834/translation/32708/", correct_for_context = False, text = "it" }, { id = 32709, endpoint = "/api/text/word/10834/translation/32709/", correct_for_context = False, text = "one" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10834/", translations = "/api/text/word/10834/translation/" } ] )
        , ( "университете", Array.fromList [ TextWord.new (TextWordId 10830) (SectionNumber 1) 0 "университете" (Just (Dict.fromList [ ( "form", "loct" ), ( "pos", "NOUN" ) ])) (Just [ { id = 32696, endpoint = "/api/text/word/10830/translation/32696/", correct_for_context = True, text = "University" }, { id = 32697, endpoint = "/api/text/word/10830/translation/32697/", correct_for_context = False, text = "varsity" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10830/", translations = "/api/text/word/10830/translation/" } ] )
        , ( "учились", Array.fromList [ TextWord.new (TextWordId 10815) (SectionNumber 1) 0 "учились" (Just (Dict.fromList [ ( "aspect", "impf" ), ( "mood", "indc" ), ( "pos", "VERB" ), ( "tense", "past" ) ])) (Just [ { id = 32646, endpoint = "/api/text/word/10815/translation/32646/", correct_for_context = True, text = "learn" }, { id = 32647, endpoint = "/api/text/word/10815/translation/32647/", correct_for_context = False, text = "study" }, { id = 32648, endpoint = "/api/text/word/10815/translation/32648/", correct_for_context = False, text = "go" }, { id = 32649, endpoint = "/api/text/word/10815/translation/32649/", correct_for_context = False, text = "student" }, { id = 32650, endpoint = "/api/text/word/10815/translation/32650/", correct_for_context = False, text = "attend" } ]) (SingleWord Nothing) { text_word = "/api/text/word/10815/", translations = "/api/text/word/10815/translation/" } ] )
        , ( "что", Array.fromList [
            TextWord.new (TextWordId 10835) (SectionNumber 1) 0 "что"
              (Just (Dict.fromList [ ( "pos", "CONJ" ) ]))
              (Just [
                { id = 32710, endpoint = "/api/text/word/10835/translation/32710/", correct_for_context = True
                , text = "that" }
              , { id = 32711, endpoint = "/api/text/word/10835/translation/32711/", correct_for_context = False
                , text = "what" }
              , { id = 32712, endpoint = "/api/text/word/10835/translation/32712/", correct_for_context = False
                , text = "the" }, { id = 32713, endpoint = "/api/text/word/10835/translation/32713/"
                , correct_for_context = False, text = "than" }
              , { id = 32714, endpoint = "/api/text/word/10835/translation/32714/", correct_for_context = False
                , text = "it" } ]) (SingleWord Nothing)
                  { text_word = "/api/text/word/10835/", translations = "/api/text/word/10835/translation/" }
          , TextWord.new (TextWordId 10836) (SectionNumber 1) 1 "что"
               (Just (Dict.fromList [ ( "pos", "CONJ" ) ]))
               (Just [
                 { id = 32715, endpoint = "/api/text/word/10836/translation/32715/", correct_for_context = True
                 , text = "that" }
               , { id = 32716, endpoint = "/api/text/word/10836/translation/32716/", correct_for_context = False
                 , text = "what" }
               , { id = 32717, endpoint = "/api/text/word/10836/translation/32717/", correct_for_context = False
                 , text = "the" }
               , { id = 32718, endpoint = "/api/text/word/10836/translation/32718/", correct_for_context = False
                 , text = "than" }
               , { id = 32719, endpoint = "/api/text/word/10836/translation/32719/", correct_for_context = False
                 , text = "it" } ]) (SingleWord Nothing)
                   { text_word = "/api/text/word/10836/", translations = "/api/text/word/10836/translation/" }
          , TextWord.new (TextWordId 10837) (SectionNumber 1) 2 "что"
              (Just (Dict.fromList [ ( "pos", "CONJ" ) ]))
              (Just [
                { id = 32720, endpoint = "/api/text/word/10837/translation/32720/", correct_for_context = True
                , text = "that" }
              , { id = 32721, endpoint = "/api/text/word/10837/translation/32721/", correct_for_context = False
                , text = "what" }
              , { id = 32722, endpoint = "/api/text/word/10837/translation/32722/", correct_for_context = False
                , text = "the" }
              , { id = 32723, endpoint = "/api/text/word/10837/translation/32723/", correct_for_context = False
                , text = "than" }
              , { id = 32724, endpoint = "/api/text/word/10837/translation/32724/", correct_for_context = False
                , text = "it" } ]) (SingleWord Nothing)
              { text_word = "/api/text/word/10837/", translations = "/api/text/word/10837/translation/" }
          , TextWord.new (TextWordId 10838) (SectionNumber 1) 3 "что"
              (Just (Dict.fromList [ ( "pos", "CONJ" ) ]))
              (Just [
                { id = 32725, endpoint = "/api/text/word/10838/translation/32725/", correct_for_context = True
                , text = "that" }
              , { id = 32726, endpoint = "/api/text/word/10838/translation/32726/", correct_for_context = False
                , text = "what" }
              , { id = 32727, endpoint = "/api/text/word/10838/translation/32727/", correct_for_context = False
                , text = "the" }
              , { id = 32728, endpoint = "/api/text/word/10838/translation/32728/", correct_for_context = False
                , text = "than" }
              , { id = 32729, endpoint = "/api/text/word/10838/translation/32729/", correct_for_context = False
                , text = "it" } ]) (SingleWord Nothing)
                { text_word = "/api/text/word/10838/", translations = "/api/text/word/10838/translation/" } ] )
        ]

new_text_words =
    [ TextWord.new
        (TextWordId 10868) (SectionNumber 1) 0 "потому"
        (Just (Dict.fromList [ ( "pos", "ADVB" ) ]))
        (Just [
           { id = 32817, endpoint = "/api/text/word/10868/translation/32817/", correct_for_context = True
           , text = "therefore" }
         ])
        (SingleWord (Just { id = 15064, instance = 0, pos = 0, length = 2 }))
        { text_word = "/api/text/word/10868/", translations = "/api/text/word/10868/translation/" }
    , TextWord.new
        (TextWordId 10838) (SectionNumber 1) 3 "что"
        (Just (Dict.fromList [ ( "pos", "CONJ" ) ]))
        (Just [
          { id = 32725, endpoint = "/api/text/word/10838/translation/32725/", correct_for_context = True
          , text = "that" }
        , { id = 32726, endpoint = "/api/text/word/10838/translation/32726/", correct_for_context = False
          , text = "what" }
        , { id = 32727, endpoint = "/api/text/word/10838/translation/32727/", correct_for_context = False
          , text = "the" }
        , { id = 32728, endpoint = "/api/text/word/10838/translation/32728/", correct_for_context = False
          , text = "than" }
        , { id = 32729, endpoint = "/api/text/word/10838/translation/32729/", correct_for_context = False
          , text = "it" }
        ])
        (SingleWord (Just { id = 15064, instance = 3, pos = 1, length = 2 }))
        { text_word = "/api/text/word/10838/", translations = "/api/text/word/10838/translation/" }
    , TextWord.new
        (TextWordId 15064) (SectionNumber 1) 0 "потому что"
        (Just (Dict.fromList [])) Nothing CompoundWord
        { text_word = "/api/text/word/15064/", translations = "/api/text/word/15064/translation/" }
    ]

test_model =
    { words = Array.fromList [ Dict.empty, section_one_words ]
    , editing_words = Dict.fromList [ ( "потому", 0 ) ]
    , editing_grammeme = Nothing
    , editing_grammemes = Dict.fromList []
    , editing_word_instances = Dict.fromList [ ( "1_0_потому", True ) ]
    , edit_lock = False
    , text =
        { id = Just 82
        , title = "Recollections of Maria Pogrebova"
        , introduction = """<p>In this text, Maria Pogrebova gives an account of events that
               happened while she was engaged.</p>"""
        , author = ""
        , source = "https://newtimes.ru/articles/detail/150471/"
        , difficulty = "advanced_mid"
        , conclusion = Just """<p>You have completed this reading. To access more readings,
                please click on the Search Texts button in the menu bar.<br />
&nbsp;</p>"""
        , created_by = Just "vhannah@pdx.edu"
        , last_modified_by = Just "vhannah@pdx.edu"
        , tags = Just [ "History", "Human Interest", "Internal Affairs", "Society and Societal Trends" ]
        , created_dt = Nothing
        , modified_dt = Nothing
        , words = Dict.empty
        , write_locker = Nothing
        , sections = Array.fromList []
        }
    , text_id = 82
    , merging_words = OrderedDict.empty
    , new_translations = Dict.fromList []
    , flags =
        { add_as_text_word_endpoint_url = "/api/text/word/"
        , csrftoken = "axEBYhjuR5RqPExR1OTDA7D78qWfEzP0cW6TKCAx7Fk5e1UXqCqhBCgBMCULtiZO"
        , merge_textword_endpoint_url = "/api/text/word/compound/"
        , text_translation_match_endpoint = "/api/text/translations/match/"
        }
    , add_as_text_word_endpoint = AddTextWordEndpoint (URL "/api/text/word/")
    , merge_textword_endpoint = MergeTextWordEndpoint (URL "/api/text/word/compound/")
    , text_translation_match_endpoint = TextTranslationMatchEndpoint (URL "/api/text/translations/match/")
    }


testMerge : Model -> Int -> Phrase -> Instance -> List TextWord.TextWord -> Expectation
testMerge model section phrase instance text_words =
    let
      new_model = Text.Translations.Model.completeMerge model (SectionNumber 1) "потому что" 0 text_words
    in
      Expect.equalLists
        [Just (0, 0, 2), Just (3, 1, 2), Nothing]
        (List.map (Text.Translations.Model.isTextWordPartOfCompoundWord new_model) text_words)
