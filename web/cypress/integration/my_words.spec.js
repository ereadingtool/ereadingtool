describe('Checks My Words', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

    it('Confirms the table exists with appropriate column names', () => {
      cy.student_login()
        .then(() => {
          cy.get('#header')
            .contains('My Words')
            .click()
            .then(() => {
              cy.get('#my-words-table')
                .contains('Phrase')
              cy.get('#my-words-table')
                .contains('Context')
              cy.get('#my-words-table')
                .contains('Dictionary Form')
              cy.get('#my-words-table')
                .contains('Translation')
            })
        })
    })
  })
})