describe('Homepage links', () => {
  it('Visits homepage then moves to linked pages', () => {
    cy.visit('https://localhost:1234')
    cy.get('.features-text')
      .contains('Learn more')
      .click()

    cy.url().should('include', '/about')

    cy.visit('https://localhost:1234')
    cy.get('.features-text')
      .contains('Sign up now')
      .click()
  })
})

describe('Aknowledgement links', () => {
  it('Visits the acknowledgements page and checks links exist', () => {
    cy.visit('https://localhost:1234/acknowledgments')
    cy.get('#acknowledgements-intro')
      .contains('Institute of International Education')
      .contains('a')

    cy.visit('https://localhost:1234/acknowledgments')
    cy.get('#acknowledgements-intro')
      .contains('The Language Flagship')
      .contains('a')
  })
})