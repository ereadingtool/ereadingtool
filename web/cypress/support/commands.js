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
    .type(email)
    // .type('USER')

  cy.get('#password-input')
    .type(pw)
    // .type('PWD')

  cy.get('.login_submit')
    .click()
})

Cypress.Commands.add('student_access_texts', (email, pw) => {
  cy.visit('http://localhost:1234/login/student')
  cy.get('#email-input')
    .type(email)
    // .type('USER')

  cy.get('#password-input')
    .type(pw)
    // .type('PWD')

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
