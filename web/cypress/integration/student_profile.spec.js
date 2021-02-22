// // login as the student

const { assert } = require("console")

// // test the stuff
// describe('Access student portal', () => {
//   it('Logs in to the student portal', () => {
//     cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
//   })
// })

// describe('Access profile from navbar', () => {
//   it('Clicks the logo in navbar', () => {
//     cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
//       .then(() => {
//         cy.get('#logo')
//           .click()
//       })
//     cy.url().should('include', '/profile/student')
//   })
// })

// describe('Access profile from navbar', () => {
//   it('Clicks the Profile link in the navbar', () => {
//     cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
//       .then(() => {
//         cy.get('#header')
//           .contains('Profile')
//           .click()

//         cy.url().should('include', '/profile/student')
//       })
//   })
// })

// describe('Access texts from navbar', () => {
//   it('Clicks the Texts link in navbar', () => {
//     cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
//       .then(() => {
//         cy.get('#header')
//           .children('.content-menu')
//           .find('a')
//           .should('have.text', 'Texts')
//           .click()
//       })
//     cy.url().should('include', '/text/search')
//   })
// })

// =========== Local Storage ===========

describe('Confirms role in local storage', () => {
  it("Checks local storage to validate token's existance", () => {
    cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
      .wait(500)
      .then(() => {
        let ls = JSON.parse(localStorage.user)
        expect(ls).to.have.property('user')
        expect(ls.user).to.have.property('role')
        expect(ls.user.id).to.be.greaterThan(0)
        expect(ls.user.role).to.be.equal('student')
        expect(ls.user.token).to.exist
      })
  })
})

// =========== Hints ===========
// describe('Toggles the Show Hints button', () => {
//   it("Clicks the Show Hints button")
// })

// describe('Checks the show hints modal is up', () => {
//   it("Makes Show Hints button active, checks for the modal", () => {
//     cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
//   })
// })

// check for hint banner


// =========== Links ===========

// check all of the links

// check links in modal (traverse them)

// check link in banner

// =========== Files ===========

describe("Checks my words CSV to confirm file downloads", () => {
  it("Builds the link from localStorage and the environment variable, then attempts to readFile", () => {
    cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
      .wait(500)
      .then(() => {
        let ls = JSON.parse(localStorage.user) 
        let file = 'localhost:8000/profile/student/' + ls.user.id + '/mywords.csv?token=' + ls.user.token
        cy.readFile(file, {timeout: 10000})
      })
  })
})
