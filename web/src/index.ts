// @ts-expect-error
import { Elm } from './Main.elm';

type User = { user: { token: string } } 
type Creds = { email: string, password: string }

const restApiUrl: string = process.env.RESTAPIURL;
const authStoreKey: string = 'user';

// INIT

const user: User = JSON.parse(localStorage.getItem(authStoreKey));

const app = Elm.Main.init({
  node: document.getElementById('main'),
  flags: { restApiUrl, ...user }
});


// LOGIN

app.ports.login.subscribe(async (creds: Creds) => {
  const response = await fetch(restApiUrl + '/token-auth/', {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    method: 'POST',
    body: JSON.stringify(creds)
  });
  const jsonResponse = await response.json(); // { token: "JWTToken"}

  if (response.ok) {
    const user: User = { user: { token: jsonResponse.token } }
    localStorage.setItem(authStoreKey, 
      JSON.stringify(user)
    );
    app.ports.onAuthStoreChange.send(user);
  } else {
    const errorMessage = jsonResponse?.errors?.__all__[0];
    if (errorMessage) {
      app.ports.onAuthResponse.send({
        result: "error",
        message: errorMessage
      });
    } else {
      app.ports.onAuthResponse.send({
        result: "error",
        message: "An internal error occured. Please contact the developers."
      });
    }
  }

});


// LOGOUT

app.ports.logout.subscribe(async () => {
  // const response = await fetch(restApiUrl + 'logout', {
  //   headers: {
  //     'Accept': 'application/json',
  //     'Content-Type': 'application/json'
  //   },
  //   method: 'POST',
  //   body: ""
  // });
  // const jsonResponse = await response.json(); // { message: "logged out"}
  // console.log('logout response', jsonResponse)

  localStorage.removeItem(authStoreKey);
  app.ports.onAuthStoreChange.send(null);
});


// Notify inactive tabs when user changes
window.addEventListener("storage", function(event) {
  if (event.storageArea === localStorage && event.key === authStoreKey) {
    const user: User = JSON.parse(event.newValue);
    app.ports.onAuthStoreChange.send(user);
  }
}, false);