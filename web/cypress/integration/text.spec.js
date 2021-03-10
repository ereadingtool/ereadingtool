describe('Logs student in, navigates to texts', () => {
  it('Clicks the texts link in the navbar', () => {
    cy.student_access_texts()
  })
})

describe('Logs student in, checks hints, checks for banner', () => {
  it('Confirms hints are available then checks the banner on the text page', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
          .then(() => {
            cy.get('.content-menu')
              .contains('Texts')
              .click()
              .then(() => {
                cy.get('#text-search-welcome-message')
                  .should('exist')
              })
          })
      })  
  })
})

describe('Checks text page hint modals exist via next', () => {
  it('Navigates the first cycle of hints via the next link', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
          .then(() => {
            cy.get('.content-menu')
              .contains('Texts')
              .click()
              .then(() => {
                cy.get('#difficulty_filter_hint')
                  .contains('next')
                  .click()
                cy.get('#topic_filter_hint')
                  .contains('next')
                  .click()
                cy.get('#status_filter_hint')
                  .contains('next')
                  .click()
                cy.get('#difficulty_filter_hint')
              })
          })
      })
  })
})

describe('Checks text page hint modals exist via prev', () => {
  it('Navigates the first cycle of hints via the prev link', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
          .then(() => {
            cy.get('.content-menu')
              .contains('Texts')
              .click()
              .then(() => {
                cy.get('#difficulty_filter_hint')
                  .contains('prev')
                  .click()
                cy.get('#status_filter_hint')
                  .contains('prev')
                  .click()
                cy.get('#topic_filter_hint')
                  .contains('prev')
                  .click()
                cy.get('#difficulty_filter_hint')
              })
          })
      })
  })
})

describe('Checks that text difficulties exist', () => {
  it('Tries each tag', () => {
    cy.student_access_texts()
      .then(() => {
        cy.turn_off_hints()
          .then(() => {
            cy.get('.text_tags')
              .contains('Biography')
              .click()
              .then(() => {
                cy.get('.text_tags')
                  .contains('Biography')
                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                  .then(() => {
                    cy.get('.text_tags')
                      .contains('Culture')
                      .click()
                      .then(() => {
                        cy.get('.text_tags')
                          .contains('Culture')
                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                          .then(() => {
                            cy.get('.text_tags')
                              .contains('Economics/Business')
                              .click()
                              .then(() => {
                                cy.get('.text_tags')
                                  .contains('Economics/Business')
                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                  .then(() => {
                                    cy.get('.text_tags')
                                      .contains('Film')
                                      .click()
                                      .then(() => {
                                        cy.get('.text_tags')
                                          .contains('Film')
                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                          .then(() => {
                                            cy.get('.text_tags')
                                              .contains('History')
                                              .click()
                                              .then(() => {
                                                cy.get('.text_tags')
                                                  .contains('History')
                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                  .then(() => {
                                                    cy.get('.text_tags')
                                                      .contains('Human Interest')
                                                      .click()
                                                      .then(() => {
                                                        cy.get('.text_tags')
                                                          .contains('Human Interest')
                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                          .then(() => {
                                                            cy.get('.text_tags')
                                                              .contains('Internal Affairs')
                                                              .click()
                                                              .then(() => {
                                                                cy.get('.text_tags')
                                                                  .contains('Internal Affairs')
                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                  .then(() => {
                                                                    cy.get('.text_tags')
                                                                      .contains('International Relations')
                                                                      .click()
                                                                      .then(() => {
                                                                        cy.get('.text_tags')
                                                                          .contains('International Relations')
                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                          .then(() => {
                                                                            cy.get('.text_tags')
                                                                              .contains('Kazakhstan')
                                                                              .click()
                                                                              .then(() => {
                                                                                cy.get('.text_tags')
                                                                                  .contains('Kazakhstan')
                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                  .then(() => {
                                                                                    cy.get('.text_tags')
                                                                                      .contains('Literary Arts')
                                                                                      .click()
                                                                                      .then(() => {
                                                                                        cy.get('.text_tags')
                                                                                          .contains('Literary Arts')
                                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                          .then(() => {
                                                                                            cy.get('.text_tags')
                                                                                              .contains('Medicine/Health Care')
                                                                                              .click()
                                                                                              .then(() => {
                                                                                                cy.get('.text_tags')
                                                                                                  .contains('Medicine/Health Care')
                                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                  .then(() => {
                                                                                                    cy.get('.text_tags')
                                                                                                      .contains('Music')
                                                                                                      .click()
                                                                                                      .then(() => {
                                                                                                        cy.get('.text_tags')
                                                                                                          .contains('Music')
                                                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                          .then(() => {
                                                                                                            cy.get('.text_tags')
                                                                                                              .contains('News Briefs')
                                                                                                              .click()
                                                                                                              .then(() => {
                                                                                                                cy.get('.text_tags')
                                                                                                                  .contains('News Briefs')
                                                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                  .then(() => {
                                                                                                                    cy.get('.text_tags')
                                                                                                                      .contains('Other')
                                                                                                                      .click()
                                                                                                                      .then(() => {
                                                                                                                        cy.get('.text_tags')
                                                                                                                          .contains('Other')
                                                                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                          .then(() => {
                                                                                                                            cy.get('.text_tags')
                                                                                                                              .contains('Public Policy')
                                                                                                                              .click()
                                                                                                                              .then(() => {
                                                                                                                                cy.get('.text_tags')
                                                                                                                                  .contains('Public Policy')
                                                                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                                  .then(() => {
                                                                                                                                    cy.get('.text_tags')
                                                                                                                                      .contains('Science/Technology')
                                                                                                                                      .click()
                                                                                                                                      .then(() => {
                                                                                                                                        cy.get('.text_tags')
                                                                                                                                          .contains('Science/Technology')
                                                                                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                                          .then(() => {
                                                                                                                                            cy.get('.text_tags')
                                                                                                                                              .contains('Society and Societal Trends')
                                                                                                                                              .click()
                                                                                                                                              .then(() => {
                                                                                                                                                cy.get('.text_tags')
                                                                                                                                                  .contains('Society and Societal Trends')
                                                                                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                                                  .then(() => {
                                                                                                                                                    cy.get('.text_tags')
                                                                                                                                                      .contains('Sports')
                                                                                                                                                      .click()
                                                                                                                                                      .then(() => {
                                                                                                                                                        cy.get('.text_tags')
                                                                                                                                                          .contains('Sports')
                                                                                                                                                          .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                                                          .then(() => {
                                                                                                                                                            cy.get('.text_tags')
                                                                                                                                                              .contains('Visual Arts')
                                                                                                                                                              .click()
                                                                                                                                                              .then(() => {
                                                                                                                                                                cy.get('.text_tags')
                                                                                                                                                                  .contains('Visual Arts')
                                                                                                                                                                  .should('have.css', 'background-color', 'rgb(0, 84, 166)')
                                                                                                                                                                  .then(() => {
                                                                                                                                                                    cy.get('.text_tags')
                                                                                                                                                                      .contains('Hidden')
                                                                                                                                                                      .should('not.exist')
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
  })
})

// TODO: Fails, need exclusive Read Status
// describe('Tries each read status', () => {
//   it("Checks existance of three read statuses, confirms they're mutually exclusive", () => {
//     cy.student_access_texts()
//       .then(() => {
//         cy.get('.search_filter')
//           .contains('Unread')
//           .click()
//           .then(() => {
//             cy.get('.search_filter')
//               .contains('Read')
//               .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               .then(() => {
//                 cy.get('.search_filter')
//                   .contains('In Progress')
//                   .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               })
//           })
//       })
//       .then(() => {
//         cy.get('.search_filter')
//           .contains('Read')
//           .click()
//           .then(() => {
//             cy.get('.search_filter')
//               .contains('Unread')
//               .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               .then(() => {
//                 cy.get('.search_filter')
//                   .contains('In Progress')
//                   .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               })
//           })
//       })
//       .then(() => {
//         cy.get('.search_filter')
//           .contains('In Progress')
//           .click()
//           .then(() => {
//             cy.get('.search_filter')
//               .contains('Unread')
//               .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               .then(() => {
//                 cy.get('.search_filter')
//                   .contains('Read')
//                   .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
//               })
//           })
//       })
//   })
// })

describe('Tries each difficulty', () => {
  it('Selects each difficulty and expects mutual exclusivity', () => {
    cy.student_access_texts()
      .then(() => {
        cy.get('.search_filter')
          .contains('Intermediate-Mid')
          .click()
          .then(() => {
            cy.get('.search_filter')
              .contains('Intermediate-High')
              .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
          })
          .then(() => {
            cy.get('.search_filter')
              .contains('Advanced-Low')
              .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
          })
          .then(() => {
            cy.get('.search_filter')
              .contains('Advanced-Mid')
              .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
          })
          .then(() => {
            cy.get('.search_filter')
              .contains('Intermediate-High')
              .click()
              .then(() => {
                cy.get('.search_filter')
                  .contains('Intermediate-High')
                  .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
              })
          })
      })
  })
})
