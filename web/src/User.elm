module User exposing (..)


type UserID
    = UserID Int


type URI
    = URI String


type RedirectURI
    = RedirectURI URI


type SignUpURL
    = SignUpURL URL


type LoginURI
    = LoginURI URI


type URL
    = URL String


type LoginPageURL
    = LoginPageURL URL


type ForgotPassURL
    = ForgotPassURL URL


type AcknowledgePageURL
    = AcknowledgePageURL URL


type AboutPageURL
    = AboutPageURL URL


acknowledgePageURL : AcknowledgePageURL -> URL
acknowledgePageURL (AcknowledgePageURL url) =
    url


aboutPageURL : AboutPageURL -> URL
aboutPageURL (AboutPageURL url) =
    url


redirectURI : RedirectURI -> URI
redirectURI (RedirectURI uri) =
    uri


signupURL : SignUpURL -> URL
signupURL (SignUpURL url) =
    url


forgotPassURL : ForgotPassURL -> URL
forgotPassURL (ForgotPassURL url) =
    url


loginURI : LoginURI -> URI
loginURI (LoginURI uri) =
    uri


loginPageURL : LoginPageURL -> URL
loginPageURL (LoginPageURL url) =
    url


uriToString : URI -> String
uriToString (URI uri) =
    uri


urlToString : URL -> String
urlToString (URL url) =
    url
