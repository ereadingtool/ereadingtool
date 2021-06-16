describe('Homepage links', () => {
  it('Visits homepage then moves to linked pages', () => {
    cy.visit('http://localhost:1234')
    cy.get('.features-text')
      .contains('Learn more')
      .click()

    cy.url().should('include', '/guide/getting-started')

    cy.visit('http://localhost:1234')
    cy.get('.features-text')
      .contains('Sign up now')
      .click()
  })
})

describe('About page link', () => {
  it('Visits the about page and checks links exist', () => {
    cy.visit('http://localhost:1234')
    cy.get('#header')
      .contains('About')
      .click()
    cy.url().should('include', '/about')
  })
})