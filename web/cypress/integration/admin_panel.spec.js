// describe("Tests login to the admin panel", () => {
//   it('Fills in the login form fields for the admin panel', () => {
//     cy.visit('http://localhost:8001/')
//     const username = Cypress.env('ADMIN_USER')
//     const password = Cypress.env('ADMIN_PWD')

//     if (typeof username !== 'string' || !username) {
//       throw new Error('Missing username value, set using CYPRESS_ADMIN_USER')
//     }
//     if (typeof password !== 'string' || !password) {
//       throw new Error('Missing username value, set using CYPRESS_ADMIN_PWD')
//     }
//     cy.get('#id_username')
//       // .type('admin@example.com', { log: false }) 
//       .type(username, { log: false }) 
  
//     cy.get('#id_password')
//       .type(password, { log: false })
  
//     cy.get('.submit-row')
//       .contains('Log in')
//       .click()
//   })
// })

// https://github.com/cypress-io/cypress-example-recipes/blob/master/examples/logging-in__csrf-tokens/cypress/integration/logging-in-csrf-tokens-spec.js
describe("Add Cypress user via admin panel", () => {
  before(() => {
    cy.request('http://localhost:8001/')
      .its('body')
      .then((body) => {
        const $html = Cypress.$(body)
        const csrf = $html.find('input[name=csrfmiddlewaretoken]').val()

        cy.admin_login(csrf)
    })
  })

  it('Confirms admin login works', () => {
    cy.get('h1')
      .contains('Site administration')
  })

  // Cannot add student for some reason
  // it('Access admin panel and adds user', () => {
  //   cy.visit('http://localhost:8001')
  //     .then(() => {
  //       cy.get('.model-student')
  //         .contains('Add')
  //         .click()
  //         .then(() => {
  //           cy.get('#id_user')
  //             .select('admin')
  //           cy.get('#id_research_consent')
  //             .select('')
  //         })
  //     })
  // })
})


// })
