describe('Use navbar items', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })
  })
  it('Logs in to the student portal', () => {
    cy.instructor_login()
  })

  it('Clicks the logo in navbar', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#logo')
          .click()
      })
    cy.url().should('include', '/profile/content-creator')
  })

  it('Clicks the Texts link in navbar', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#header')
          .children('.content-menu')
          .find('a')
          .contains('Text')
          .click()
      })
    cy.url().should('include', '/text/search')
  })

  it('Clicks the Edit link in navbar', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#header')
          .children('.content-menu')
          .find('a')
          .contains('Edit')
          .click()
      })
    cy.url().should('include', '/text/creator-search')
  })

  it('Clicks the Create link in navbar', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#header')
          .children('.content-menu')
          .find('a')
          .contains('Create')
          .click()
      })
    cy.url().should('include', '/text/create')
  })

  it('Clicks the Guide link in navbar', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#header')
          .children('.content-menu')
          .find('a')
          .contains('Guide')
          .click()
      })
    cy.url().should('include', '/creator-guide')
  })
})


describe('Check profile items', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })
  })

  it('Confirms profile item Username exists when admin is True', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('.profile_item')
          .contains('Username')
      })
  })

  it('Confirms profile item Invitations exists when admin is True', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('.invites')
          .contains('Invitations')
      })
  })

  it('Confirms profile item Texts exists when admin is True', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('.instructor-profile-texts')
          .contains('Texts')
      })
  })

  it('Confirms admin instructor can invite other instructors', () => {
    cy.instructor_login()
      .then(() => {
        cy.get('#create_invite')
          .find('#input')
          .type('admin2@example.com')
          .then(() => {
            cy.get('#submit')
              .click()
              .then(() => {
                cy.get('.invite')
                  .contains('Email:')
                  .parent()
                  .contains(/[a-zA-Z0-9]+[@][a-zA-Z0-9]+[.][a-zA-Z0-9]+/)
                  .parent()
                  .contains('Invite Code:')
                  .parent()
                  .contains('Expiration:')
                  .parent()
                  .contains(/[a-zA-Z]+ [0-3]?[0-9][,] [0-1]?[0-9][:][0-5]?[0-9][:][0-5]?[0-9] [A|P][M] [0-9]*/)
              })
          })
      })
  })
})