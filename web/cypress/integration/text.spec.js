describe('Checks student text search page', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

    it('Clicks the texts link in the navbar', () => {
      cy.student_access_texts()
    })

    it('Logs student in, checks hints, checks for banner', () => {
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

    it('Checks text page hint modals exist via next', () => {
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

    it('Checks text page hint modals exist via prev', () => {
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

    it('Tries each difficulty', () => {
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

    it("Checks existance of three read statuses, confirms they're mutually exclusive", () => {
      cy.student_access_texts()
        .then(() => {
          cy.get('.search_filter')
            .contains('Unread')
            .click()
            .then(() => {
              cy.get('.text_status')
                .contains('Read')
                .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                .then(() => {
                  cy.get('.search_filter')
                    .contains('In Progress')
                    .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                })
            })
        })
        .then(() => {
          cy.get('.search_filter')
            .get('.text_status')
            .contains('Read')
            .click()
            .then(() => {
              cy.get('.search_filter')
                .contains('Unread')
                .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                .then(() => {
                  cy.get('.search_filter')
                    .contains('In Progress')
                    .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                })
            })
        })
        .then(() => {
          cy.get('.search_filter')
            .contains('In Progress')
            .click()
            .then(() => {
              cy.get('.search_filter')
                .contains('Unread')
                .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                .then(() => {
                  cy.get('.text_status')
                    .contains('Read')
                    .should('not.have.css', 'background-color', 'rgb(0, 84, 166)')
                })
            })
        })
    })

    it('Confirms upvoting works', () => {
      cy.student_access_texts()
        .then(() => {
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '0')

          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.upvote')
            .click()
            .then(($upvote) => {
              // is it colored accordingly?
              cy.wrap($upvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward_enabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '1')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward_disabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .click()

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward.svg')
            })
        })
    })

    it('Confirms downvoting works', () => {
      cy.student_access_texts()
        .then(() => {
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '0')

          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.downvote')
            .click()
            .then(($downvote) => {
              // is it colored accordingly?
              cy.wrap($downvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward_enabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '-1')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward_disabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .click()

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward.svg')
            })
        })
    })

    it('Undoes an upvote', () => {
      cy.student_access_texts()
        .then(() => {
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '0')

          cy.wait(500)

          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.upvote')
            .click()
            .then(($upvote) => {
              // is it colored accordingly?
              cy.wrap($upvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward_enabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '1')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .click()

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward.svg')
            })
        })
    })

    it('Undoes a downvote', () => {
      cy.student_access_texts()
        .then(() => {

          // confirms text rating is 0
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '0')

          // downvotes the text
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.downvote')
            .click()
            .then(($downvote) => {

              // confirms downvote image
              cy.wrap($downvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward_enabled.svg')

              // confirms downvoted rating
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '-1')

              // clicks downvote again
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .click()

              // checks rating is now zero after undoing downvote
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '0')

              // confirm up arrow is normal (neither enabled or disabled)
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward.svg')

              // confirm down arrow is normal (neither enabled or disabled)
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward.svg')
            })
        })
    })

    it('Downvotes from an upvote', () => {
      cy.student_access_texts()
        .then(() => {

          // starts at 0
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '0')

          // upvotes to 1
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.upvote')
            .click()
            .then(($upvote) => {
              cy.wrap($upvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward_enabled.svg')

              // confirms rating is 1
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '1')

              // downvotes
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .click()

              // confirms downvote image
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.downvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward_enabled.svg')

              // confirms rating updated
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '-1')
            })
        })
    })

    it('Upvotes from a downvote', () => {
      cy.student_access_texts()
        .then(() => {
          // previous test set vote to -1
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '-1')

          // upvote the downvoted text
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.upvote')
            .click()
            .then(($upvote) => {

              // upvote should be active
              cy.wrap($upvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward_enabled.svg')

              // check the rating
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '1')

              // reset value in db to 0
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .click()

              // confirm up arrow is normal (neither enabled or disabled)
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_upward.svg')

              // confirm down arrow is normal (neither enabled or disabled)
              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.upvote')
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward.svg')
            })
        })
    })

    it('Confirms downvoting works', () => {
      cy.student_access_texts()
        .then(() => {
          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.result_item_title')
            .first()
            .should('have.text', '1')

          cy.get('#text_search_results')
            .contains('Demo Text')
            .parents('.search_result')
            .find('.upvote')
            .click()
            .then(($upvote) => {
              // is it colored accordingly?
              cy.wrap($upvote)
                .find('img')
                .should('have.attr', 'src', '/public/img/arrow_downward_enabled.svg')

              cy.get('#text_search_results')
                .contains('Demo Text')
                .parents('.search_result')
                .find('.result_item_title')
                .first()
                .should('have.text', '-1')
            })
        })
    })

    it('Checks that text difficulties exist', () => {
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
})
