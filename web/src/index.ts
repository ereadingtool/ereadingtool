// @ts-expect-error
import { Elm } from './Main.elm';

type User = { user: { id: number; token: string; role: string } };
type ShowHelp = { showHelp: boolean };
type Creds = { email: string; password: string; role: string };

const restApiUrl: string = process.env.RESTAPIURL;
const websocketBaseUrl: string = process.env.WEBSOCKETBASEURL;
const authStoreKey: string = 'user';
let mySockets = {};

// INIT

const user: User = JSON.parse(localStorage.getItem(authStoreKey));
let showHelp: ShowHelp = JSON.parse(localStorage.getItem('showHelp'));

if (showHelp === null) {
  showHelp = { showHelp: true };
  localStorage.setItem('showHelp', JSON.stringify(showHelp));
}

const app = Elm.Main.init({
  node: document.getElementById('main'),
  flags: { restApiUrl, websocketBaseUrl, ...showHelp, ...user }
});

// HELP

app.ports.toggleShowHelp.subscribe(showHelp => {
  localStorage.setItem('showHelp', JSON.stringify(showHelp));
});

// LOGIN

app.ports.login.subscribe(async (creds: Creds) => {
  let loginEndpoint: string;
  if (creds.role === 'student') {
    loginEndpoint = '/api/student/login/';
  } else if (creds.role === 'instructor') {
    loginEndpoint = '/api/instructor/login/';
  } else {
    app.ports.onAuthResponse.send({
      result: 'error',
      message: 'An internal error occured. Please contact the developers.'
    });
  }

  const response = await fetch(restApiUrl + loginEndpoint, {
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json'
    },
    method: 'POST',
    body: JSON.stringify(creds)
  });
  const jsonResponse = await response.json(); // { token: "JWTToken"}

  if (response.ok) {
    const user: User = {
      user: { id: jsonResponse.id, token: jsonResponse.token, role: creds.role }
    };
    localStorage.setItem(authStoreKey, JSON.stringify(user));
    app.ports.onAuthStoreChange.send(user);
  } else {
    const errorMessage = jsonResponse.all;
    if (errorMessage) {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: errorMessage
      });
    } else {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: 'An internal error occured. Please contact the developers.'
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
window.addEventListener(
  'storage',
  function (event) {
    if (event.storageArea === localStorage && event.key === authStoreKey) {
      const user: User = JSON.parse(event.newValue);
      app.ports.onAuthStoreChange.send(user);
    }
  },
  false
);

// WEBSOCKETS

const sendSocketCommand = wat => {
  console.log('ssc: ' + JSON.stringify(wat, null, 4));
  if (wat.cmd == 'connect') {
    // console.log("connecting!");
    // let socket = new WebSocket(wat.address, wat.protocol);
    let socket = new WebSocket(wat.address);
    socket.onmessage = function (event) {
      // console.log( "onmessage: " +  JSON.stringify(event.data, null, 4));
      app.ports.receiveSocketMsg.send({
        name: wat.name,
        msg: 'data',
        data: event.data
      });
    };
    mySockets[wat.name] = socket;
  } else if (wat.cmd == 'send') {
    console.log('sending to socket: ' + wat.name);
    mySockets[wat.name].send(wat.content);
  } else if (wat.cmd == 'close') {
    console.log('closing socket: ' + wat.name);
    mySockets[wat.name].close();
    delete mySockets[wat.name];
  }
};

app.ports.sendSocketCommand.subscribe(config => {
  console.log(config);
  sendSocketCommand(config);
});
