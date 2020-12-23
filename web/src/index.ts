// @ts-expect-error
import { Elm } from './Main.elm';
import jwtDecode, { JwtPayload } from "jwt-decode";
import { Console } from 'console';

type User = { user: { id: number; token: string; role: string } };
type ShowHelp = { showHelp: boolean };
type Creds = { email: string; password: string; role: string };

const restApiUrl: string = process.env.RESTAPIURL;
const websocketBaseUrl: string = process.env.WEBSOCKETBASEURL;
const authStoreKey: string = 'user';
let sockets = {};

// INIT

let user: User = JSON.parse(localStorage.getItem(authStoreKey));
let showHelp: ShowHelp = JSON.parse(localStorage.getItem('showHelp'));

if (user) {
  const decodedToken = jwtDecode<JwtPayload>(user.user.token);
  const now = new Date().getTime() / 1000;

  // nullify user and remove token if token expired
  if (decodedToken.exp <= now) {
    localStorage.removeItem(authStoreKey);
    user = null;
  }
}

// initialize show help for new users
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
    loginEndpoint = '/api/student/login';
  } else if (creds.role === 'instructor') {
    loginEndpoint = '/api/instructor/login';
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
  const jsonResponse = await response.json()

  if (response.ok) {
    const user: User = {
      user: { id: jsonResponse.id, token: jsonResponse.token, role: creds.role }
    };
    localStorage.setItem(authStoreKey, JSON.stringify(user));
    app.ports.onAuthStoreChange.send(user);
  } else {
    const authErrorMessage = jsonResponse.all;
    const usernameMissingError = jsonResponse.username;
    const passwordMissingError = jsonResponse.password;

    if (usernameMissingError && passwordMissingError) {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: 'E-mail address and password fields are required.'
      });
    } else if (usernameMissingError) {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: 'E-mail address field is required.'
      });
    } else if (passwordMissingError) {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: 'Password field is required.'
      });
    } else if (authErrorMessage) {
      app.ports.onAuthResponse.send({
        result: 'error',
        message: authErrorMessage
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
  logout();
});

const logout = () => {
  app.ports.onAuthStoreChange.send(null);
  localStorage.removeItem(authStoreKey);
  window.scrollTo(0, 0);
  app.ports.onAuthResponse.send({
    result: 'success',
    message: 'Logging you out. Please login again to continue using the STAR site.'
  });
}

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
  if (wat.cmd == 'connect') {
    // implicit disconnect on new socket connection with the same name
    if (sockets[wat.name]) {
      sockets[wat.name].close();
    }

    let socket = new WebSocket(wat.address);
    socket.onmessage = function (event) {
      const data = JSON.parse(event.data);
      if (data.error && data.error == "Invalid JWT") {
        logout();
      } else if (data.error && data.error === "Missing text") {
        app.ports.onAuthResponse.send({
          result: 'error',
          message: 'This text no longer exists. Please select another text to read.'
        });
      } else {
        app.ports.receiveSocketMsg.send({
          name: wat.name,
          msg: 'data',
          data: event.data
        });
      }
    };
    sockets[wat.name] = socket;
  } else if (wat.cmd == 'send') {
    sockets[wat.name].send(JSON.stringify(wat.content));
  } else if (wat.cmd == 'close') {
    sockets[wat.name].close();
    delete sockets[wat.name];
  } else if (wat.cmd == 'closeAll') {
    Object.keys(sockets).forEach(name => {
      sockets[name].close();
      delete sockets[name];
    });
  }
};

app.ports.sendSocketCommand.subscribe(config => {
  sendSocketCommand(config);
});

// INPUTS

app.ports.clearInputText.subscribe(id => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(() => {
    const input = document.getElementById(id) as HTMLInputElement;

    if (input) {
      input.value = '';
    }
  });
});

app.ports.selectAllInputText.subscribe(id => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(() => {
    const input = document.getElementById(id) as HTMLInputElement;

    if (input) {
      input.focus();
      input.setSelectionRange(0, -1);
    }
  });
});

// SCROLL

app.ports.scrollTo.subscribe(id => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(() => {
    const elem = document.getElementById(id);

    if (elem) {
      elem.scrollIntoView(false);
    }
  });
});

// EDITOR

app.ports.ckEditor.subscribe(id => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(() => {
    if (window.CKEDITOR) {
      // implicit detach
      if (window.CKEDITOR.instances[id]) {
        window.CKEDITOR.instances[id].destroy();
      }

      window.CKEDITOR.inline(id).on('change', function (evt) {
        console.log(evt.editor.getData());
        app.ports.ckEditorUpdate.send([id, evt.editor.getData()]);
      });
    }
  });
});

// app.ports.addClassToCKEditor.subscribe(([ckeditorInstance, className]) => {
//   // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
//   window.requestAnimationFrame(() => {
//     if (CKEDITOR) {
//       const elem = document.getElementById(ckeditorInstance)
//         .nextSibling as HTMLElement;

//       if (elem) {
//         elem.classList.add(className);
//       }
//     }
//   });
// });

app.ports.ckEditorSetHtml.subscribe(([id, html]) => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(function (timestamp) {
    if (window.CKEDITOR) {
      window.CKEDITOR.instances[id].setData(html);
    }
  });
});

app.ports.confirm.subscribe(msg => {
  // wrap call in requestAnimationFrame to ensure that Elm has time to finish refreshing the view
  window.requestAnimationFrame(() => {
    const confirm = window.confirm(msg);
    app.ports.confirmation.send(confirm);
  });
});
