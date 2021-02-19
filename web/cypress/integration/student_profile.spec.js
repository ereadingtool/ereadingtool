// login as the student

// test the stuff
describe('Access student portal', () => {
  it('Logs in to the student portal', () => {
      cy.student_login('cypress@star.org', 'cypressstar')
  })
})

describe('Access profile from navbar', () => {
  it('Clicks the logo in navbar', () => {
    cy.student_login('cypress@star.org', 'cypressstar')
      .then(() => {
        cy.get('#logo')
          .click()
      })
    cy.url().should('include', '/profile/student')
  })
})

describe('Access profile from navbar', () => {
  it('Clicks the Profile link in the navbar', () => {
    cy.student_login('cypress@star.org', 'cypressstar')
      .then(() => {
        cy.get('#header')
          .contains('Profile')
          .click()

        cy.url().should('include', '/profile/student')
      })
  })
})

describe('Access texts from navbar', () => {
  it('Clicks the Texts link in navbar', () => {
    cy.student_login('cypress@star.org', 'cypressstar')
      .then(() => {
        cy.get('#header')
          .children('.content-menu')
          .find('a')
          .should('have.text', 'Texts')
          .click()
      })
    cy.url().should('include', '/text/search')
  })
})

// =========== Local Storage ===========

describe('Confirms role in local storage', () => {
  it("Checks local stoarge to make sure role is student", () => {
    cy.student_login('cypress@star.org', 'cypressstar')
      .then(() => {
        const store = cy.get(localStorage)
        
      })
  })
})

// describe('Confirms JWT in local storage', () => {
//   it("Checks local stoarge for JWT but doesn't verify it", () => {