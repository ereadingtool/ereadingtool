describe('Use navbar items', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

  it('Logs in to the student portal', () => {
    cy.student_login()
  })

  it('Clicks the logo in navbar', () => {
    cy.student_login()
      .then(() => {
        cy.get('#logo')
          .click()
      })
    cy.url().should('include', '/profile/student')
  })

  it('Clicks the Profile link in the navbar', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Profile')
          .click()
      })
    cy.url().should('include', '/profile/student')
  })

  it('Clicks the Texts link in navbar', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Texts')
          .click()
      })
    cy.url().should('include', '/text/search')
  })

  it('Clicks the Guide link in the navbar', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
      })
    cy.url().should('include', '/my-words')
  })

  it('Clicks the My Words link in the navbar', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('My Words')
          .click()
      })
    cy.url().should('include', '/my-words')
  })
})
})

describe('Checks if username update functionality', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })
  it('Clicks the update button, changes text, cancels change', () => {
    cy.student_login()
      .then(() => {
        cy.get('.update_username')
          .click()
          .then(() => {
          cy.get('.username_input')
            .type('asdfasdf')
            .then(() => {
              cy.get('.username_submit')
                .contains('Cancel')
                .click()
            })
          })
      })
  })

  it('Checks username update length restriction', () => {
    cy.student_login()
      .then(() => {
        cy.get('.update_username')
          .click()
          .then(() => {
            cy.get('.username_input')
              .clear()
              .type('asdf')
            cy.get('.invalid_username')
          })
          // no tests for all possible special characters that could be in the username
      })
  })

  it('Checks username for special characters', () => {
    cy.student_login()
      .then(() => {
        cy.get('.update_username')
          .click()
        cy.get('.username_input')
          .clear()
          .type('asdfasdf@')
          .then(() => {
            cy.get('.valid_username')
          })
        cy.get('.username_input')
          .clear()
          .type('asdfasdf.')
          .then(() => {
            cy.get('.valid_username')
          })
        cy.get('.username_input')
          .clear()
          .type('asdfasdf+')
          .then(() => {
            cy.get('.valid_username')
          })
        cy.get('.username_input')
          .clear()
          .type('asdfasdf-')
          .then(() => {
            cy.get('.valid_username')
          })
        cy.get('.username_input')
          .clear()
          .type('asdfasdf_')
          .then(() => {
            cy.get('.valid_username')
          })
        cy.get('.username_input')
          .clear()
          .type('asdfasdf1')
          .then(() => {
            cy.get('.valid_username')
          })
      })
  })
})
})

describe('Confirms role in local storage', () => {

  it("Checks local storage to validate token's existance", () => {
    cy.student_login()
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

describe('Checks the student profile elements', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })
  it("Checks the show hints modal is up", () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
          .then(() => {
            cy.get('.hint_overlay')
          })
      })
  })

  it('Turns the Show Hints tutorial off', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
        cy.turn_off_hints()
        cy.get('.help_hints')
          .should('not.exist')
      })
  })

  it('Check for the hints banner', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
        cy.get('#profile-welcome-banner')
      })
  })

  it('Checks profile page hint modals exist via next', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
        cy.get('#help_hints')
          .contains('next')
          .click()
        cy.get('#username_hint')
          .contains('next')
          .click({force: true})
        cy.get('#my_performance_hint')
          .contains('next')
          .click()
        cy.get('#preferred_difficulty_hint')
          .contains('next')
          .click()
        cy.get('#help_hints')
      })
  })

  it('Checks profile page hint modals exist via prev', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
        cy.get('#help_hints')
          .contains('prev')
          .click()
        cy.get('#preferred_difficulty_hint')
          .contains('prev')
          .click()
        cy.get('#my_performance_hint')
          .contains('prev')
          .click()
        cy.get('#username_hint')
          .contains('prev')
          .click({force: true})
        cy.get('#help_hints')
      })
  })

  it('Closes the first hints modal', () => {
    cy.student_login()
      .then(() => {
        cy.turn_on_hints()
        cy.get('#help_hints')
          .find('.exit')
          .click()
        cy.get('.invisible')
          .should('exist')
      })
  })

  it('Clicks the consent to research button', () => {
    cy.student_login()
      .then(() => {
        cy.get('#research_consent')
          .find('.check-box')
          .click()
      })
  })
})
})


describe('Validate performance report table tabs', () => {
  it('Checks Completion tab', () => {
    cy.student_login()
      .then(() => {
        cy.get('.performance_report')
          .contains('Level')
        cy.get('.performance_report')
          .contains('Time Period')
        cy.get('.performance_report')
          .contains('Texts Started')
        cy.get('.performance_report')
          .contains('Texts Completed')
      })
  })

  it('Click First Time Comprehension tab', () => {
    cy.student_login()
      .then(() => {
        cy.get('.performance-report-tabs')
          .contains('First Time Comprehension')
          .click()
        
        cy.get('.performance_report')
          .contains('Level')
        cy.get('.performance_report')
          .contains('Answers Correct')
        cy.get('.performance_report')
          .contains('Percent Correct')
      })
  })
})


describe('Confirms the file download links are working correctly', () => {
  it('Downloads performance report', () => {
    cy.student_login()
      .then(() => {
        cy.wait(1000)
          .then(() => {
            let user = JSON.parse(localStorage.user)
            let file = '/profile/student/' + user.user.id + '/performance_report.pdf?token=' + user.user.token
            cy.get('.performance_download_link')
              .find('a')
              .should('have.attr', 'href')
              .and('include', file)
          })
      })
  })

  it("Checks My Words CSV to confirm file link exists", () => {
    cy.student_login()
      .then(() => {
        cy.wait(500)
          .then(() => {
            let user = JSON.parse(localStorage.user)
            let file = '/profile/student/' + user.user.id + '/words.csv?token=' + user.user.token
            cy.get('#words')
              .contains('CSV file')
              .should('have.attr', 'href')
              .and('include', file)
          })
      })
  })

  it("Checks my words PDF to confirm file link exists", () => {
    cy.student_login()
      .then(() => {
        cy.wait(500)
          .then(() => {
            let user = JSON.parse(localStorage.user)
            let file = '/profile/student/' + user.user.id + '/words.pdf?token=' + user.user.token
            cy.get('#words')
              .contains('PDF')
              .should('have.attr', 'href')
              .and('include', file)
          })
      })
  })
})


describe('Checks research link exists', () => {
  it('Finds the Research Consent section and checks the link', () => {
    cy.student_login()
      .then(() => {
        cy.get('#research_consent')
          .find('a')
          .should('have.attr', 'href')
          .and('include', 'https://sites.google.com/pdx.edu/star-russian/home')
      })
  })
})