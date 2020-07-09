import { Elm } from './Main.elm';

const baseUrl: string = 'http://localhost:9000/'
const authStoreKey: string = 'user';
const flags: string = localStorage.getItem(authStoreKey);

const app = Elm.Main.init({
  node: document.getElementById('main'),
  flags: flags
});

type Creds = { email: string, password: string }
type User = { user: { token: string } }

app.ports.login.subscribe(async (creds: Creds) => {
  const response = await fetch(baseUrl + 'login', {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    method: 'POST',
    body: JSON.stringify(creds)
  });
  const jsonResponse = await response.json(); // { token: "JWTToken"}
  console.log('login response', jsonResponse)

  const user: User = { user: { token: jsonResponse.token } }
  localStorage.setItem(authStoreKey, 
    JSON.stringify(user)
  );
  app.ports.onAuthStoreChange.send(JSON.stringify(user));
});

app.ports.logout.subscribe(async () => {
  const response = await fetch(baseUrl + 'logout', {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    method: 'POST',
    body: ""
  });
  const jsonResponse = await response.json(); // { message: "logged out"}
  console.log('logout response', jsonResponse)

  localStorage.removeItem(authStoreKey);
  app.ports.onAuthStoreChange.send(null);
});

window.addEventListener("storage", function(event) {
  if (event.storageArea === localStorage && event.key === authStoreKey) {
    app.ports.onAuthStoreChange.send(event.newValue);
  }
}, false);