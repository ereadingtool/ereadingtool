module TextReader.Dictionary exposing (..)

import Dict exposing (Dict)

dictionary : Dict String String
dictionary =
 Dict.fromList [
   ("test",
     """
     A procedure for critical evaluation; a means of determining the presence, quality, or truth of something; a
     trial: a test of one's eyesight; subjecting a hypothesis to a test; a test of an athlete's endurance.
     """)
 ]