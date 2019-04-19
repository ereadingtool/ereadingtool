module User exposing (..)


type UserID = UserID Int
type URI = URI String
type RedirectURI = RedirectURI URI

type SignUpURI = SignUpURI URI
type LoginURI = LoginURI URI

type URL = URL String

type LoginPageURL = LoginPageURL URL

type ForgotPassURL = ForgotPassURL URL


redirectURI : RedirectURI -> URI
redirectURI (RedirectURI uri) = uri

signupURI : SignUpURI -> URI
signupURI (SignUpURI uri) = uri

forgotPassURL : ForgotPassURL -> URL
forgotPassURL (ForgotPassURL url) =
  url

loginURI : LoginURI -> URI
loginURI (LoginURI uri) = uri

loginPageURL : LoginPageURL -> URL
loginPageURL (LoginPageURL url) =
  url

uriToString : URI -> String
uriToString (URI uri) =
  uri

urlToString : URL -> String
urlToString (URL url) =
  url
