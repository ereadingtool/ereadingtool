describe('Read Demo Text correctly', () => {
  it('Finds the demo text and answer questions correctly', () => {
    cy.student_access_texts() 
      .then(() => {
        // Expecting default to Intermediate-Mid
        cy.get('#text_search_results')
          .contains('Demo Text')
          .click()
          // Expecting to have never started the text or to have previously completed the text, thus starting at the intro
          .then(() => {
            // wait for websocket response
            cy.wait(1000)
            cy.get('#text-intro')
              .parent()
              .get('#nav')
              .contains('Start')
              .click()
              .then(() => {
                cy.get('.answers')
                  .contains('notification')
                  .click()
                  .then(() => {
                    cy.get('.correct')
                      .should('exist')

                    cy.get('#nav')
                      .contains('Next')
                      .click()
                      .then(() => {
                        cy.get('.answers')
                          .contains('Click')
                          .click()
                          .then(() => {
                            cy.get('.correct')
                              .should('exist')
                              .then(() => {
                                cy.get('#nav')
                                  .contains('Next')
                                  .click()
                                  .wait(1000) // the following get is executing too fast somehow?
                                  .then(() => {
                                    cy.get('#nav')
                                      .contains('Previous')
                                      .parent()
                                      .contains('Read Again')
                                      .parent()
                                      .contains('Read Another Text')
                                  })
                              })
                          })
                      })
                  })
              })
          })
      })
  })
})

describe('Read Demo Text incorrectly', () => {
  it('Finds the demo text and answer a question incorrectly', () => {
    cy.student_access_texts() 
      .then(() => {
        // Expecting default to Intermediate-Mid
        cy.get('#text_search_results')
          .contains('Demo Text')
          .click()
          // Expecting to have never started the text or to have previously completed the text, thus starting at the intro
          .then(() => {
            // wait for websocket response
            cy.wait(1000)
            cy.get('#text-intro')
              .parent()
              .get('#nav')
              .contains('Start')
              .click()
              .then(() => {
                cy.get('.answers')
                  .contains('sad')
                  .click()
                  .then(() => {
                    cy.get('.incorrect')
                      .should('exist')

                    cy.get('#nav')
                      .contains('Next')
                      .click()
                      .then(() => {
                        cy.get('.answers')
                          .contains('Click')
                          .click()
                          .then(() => {
                            cy.get('.correct')
                              .should('exist')
                              .then(() => {
                                cy.get('#nav')
                                  .contains('Next')
                                  .click()
                                  .wait(1000) // the following get is executing too fast somehow?
                                  .then(() => {
                                    cy.get('#nav')
                                      .contains('Previous')
                                      .parent()
                                      .contains('Read Again')
                                      .parent()
                                      .contains('Read Another Text')
                                  })
                              })
                          })
                      })
                  })
              })
          })
      })
  })
})