module User exposing (..)


type UserID = UserID Int
type URI = URI String

type SignUpURI = SignUpURI URI
type LoginURI = LoginURI URI

type URL = URL String

type LoginPageURL = LoginPageURL URL

type ForgotPassURL = ForgotPassURL URL


forgotPassURL : ForgotPassURL -> URL
forgotPassURL (ForgotPassURL url) =
  url

loginPageURL : LoginPageURL -> URL
loginPageURL (LoginPageURL url) =
  url

urlToString : URL -> String
urlToString (URL url) =
  url
