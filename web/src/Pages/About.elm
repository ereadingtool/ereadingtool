module Pages.About exposing (Model, Msg, Params, page)

import Html exposing (..)
import Html.Attributes exposing (href, id)
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)


page : Page Params Model Msg
page =
    Page.static
        { view = view
        }


type alias Model =
    Url Params


type alias Msg =
    Never



-- VIEW


type alias Params =
    ()


view : Url Params -> Document Msg
view { params } =
    { title = "About"
    , body =
        [ div [ id "acknowledgements-body" ]
            [ div [ id "acknowledgements" ]
                [ div [ id "title" ] [ text "About" ]
                , p [ id "acknowledgements-intro" ]
                    [ text
                        """                        
                        This site is being developed at Portland State University by the Russian Flagship Center under the Collaborative
                        Technology Innovation Initiative with funding from the
                        """
                    , a [ href "https://www.iie.org/" ] [ text "Institute of International Education " ]
                    , text "(IIE) funded by "
                    , a [ href "https://www.thelanguageflagship.org/" ] [ text "The Language Flagship " ]
                    , text "for the period September 2017-April 2021."
                    ]
                , p []
                    [ text
                        """
                        The Project Director is William J. Comer (Portland State University, Russian Flagship),
                        the Project Manager is Hannah Verbruggen, and the Website Developers are Andrew Silvernail, Brian Ginsburg, and 
                        Jeffrey De La Mare. Texts and questions for the site were selected through the collective efforts of Dr. Anna Kudyma 
                        and Elena Skudskaia (UCLA, Russian Flagship), Dr. Anna Tumarkin (University of Wisconsin-Madison, Russian Flagship),
                        and Dr. Irina Walsh (Bryn Mawr College, Russian Flagship). Dr. Shannon Spasova did a review of the site and helped point
                        out many areas for improvement, and Floyd Palmer did the yeoman's work on vocabulary glossing and proofreading. Dr. Julio 
                        Rodríguez and Aitor Arronte Alvarez from the Language Flagship Technology Innovation Center at the University of Hawaii 
                        and Dr. Jonathan Perkins from the University of Kansas provided much useful technical assistance and advice in developing 
                        and realizing this project. Many thanks go to the students who used the site early on and made suggestions. Questions and
                        comments should be addressed to 
                        """
                    , a [ href "mailto:ereader@pdx.edu" ] [ text "ereader@pdx.edu." ]
                    ]
                , p []
                    [ text
                        """
                        The Language Flagship is a public/private partnership sponsored by the National Security Education Program
                        (NSEP) of the Department of Defense and administered by the Institute of International Education (IIE).
                        The contents of this website do not necessarily reflect the position or policy of the government or IIE and
                        no official Government or IIE endorsement should be inferred.
                        """
                    ]
                ]
            ]
        ]
    }
