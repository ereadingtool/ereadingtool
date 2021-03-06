// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
Cypress.Commands.add('student_login', (email, pw) => {
  cy.visit('http://localhost:1234/login/student')
  cy.get('#email-input')
    .type(Cypress.env('USER')) 

  cy.get('#password-input')
    .type(Cypress.env('PWD'))

  cy.get('.login_submit')
    .click()
})

Cypress.Commands.add('instructor_login', (email, pw) => {
  cy.visit('http://localhost:1234/login/content-creator')
  cy.get('#email-input')
    .type(Cypress.env('ADMIN_EMAIL'))

  cy.get('#password-input')
    .type(Cypress.env('ADMIN_PWD'))

  cy.get('.login_submit')
    .click()
})


Cypress.Commands.add('student_login_headless', (email, pw) => {
  cy.request({
    method: 'POST',
    url: 'http://localhost:8000/api/student/login',
    body: {
      username: Cypress.env('USER'),
      password: Cypress.env('PWD'),
      role: 'student' 
    }
  })
})

// Turn these into cy.request(..) for more performant code
Cypress.Commands.add('student_access_texts', () => {
  // restructure this
  cy.visit('http://localhost:1234/login/student')
  cy.get('#email-input')
    .type(Cypress.env('USER')) 

  cy.get('#password-input')
    .type(Cypress.env('PWD'))

  cy.get('.login_submit')
    .click()
    .then(() => {
      cy.turn_off_hints()
        .then(() => {
          cy.get('.content-menu')
            .contains('Texts')
            .click()
        })
    })
})

Cypress.Commands.add('admin_login', (csrf) => {
  const username = Cypress.env('ADMIN_USER')
  const password = Cypress.env('ADMIN_PWD')

  cy.visit('http://localhost:8001')
  cy.get('#id_username')
    .type(Cypress.env('ADMIN_USER'), { log: false }) 

  cy.get('#id_password')
    .type(Cypress.env('ADMIN_PWD'), { log: false })

  cy.get('.submit-row')
    .contains('Log in')
    .click() 
})

Cypress.Commands.add('admin_login_headless', (csrf) => {
  const username = Cypress.env('ADMIN_USER')
  const password = Cypress.env('ADMIN_PWD')

  cy.request({
      method: 'POST',
      url: 'http://localhost:8001/login/?next=/',
      failOnStatusCode: false,
      form: true,
      body: {
        username: username,
        password: password,
        csrfmiddlewaretoken: csrf,
        next: '/'
      }
    })
})

Cypress.Commands.add('content_editor_login', () => {
  // TODO
})

Cypress.Commands.add('turn_off_hints', () => {
  let help = JSON.parse(localStorage.showHelp)
  if (help.showHelp) {
    cy.get('#show-help')
      .find('.check-box')
      .click()
  }
})

Cypress.Commands.add('turn_on_hints', () => {
  let help = JSON.parse(localStorage.showHelp)
  if (!help.showHelp) {
    cy.get('#show-help')
      .find('.check-box')
      .click()
  }
})

Cypress.Commands.add('reset_demo_text', () => {
  cy.get('#text_search_results')
    .contains('Demo Text')
    .parents('.search_result')
    .find('.result_item_title')
    .first()
    .then(($v) => {
      // console.log($v[0].outerText)
      let rating = $v[0].outerText
      if (rating == -1) {
        // click the downvote
        cy.get('#text_search_results')
          .contains('Demo Text')
          .parents('.search_result')
          .find('.downvote')
          .click()
      } else if (rating == 1) {
        // click the upvote
        cy.get('#text_search_results')
          .contains('Demo Text')
          .parents('.search_result')
          .find('.upvote')
          .click()
      }
    })
})

// image diff tool
const compareSnapshotCommand = require('cypress-image-diff-js/dist/command')
compareSnapshotCommand()

// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })
