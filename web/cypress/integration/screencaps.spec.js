// Note: Need to login with the form field because we want the webpage to 
// be visible for the screenshot tool.

// ======================== Public pages ========================

describe('Cleans up screenshot directories', () => {
  it('Deletes comparison/ and screenshots/', () => {
    cy.exec('rm cypress/screenshots/screencaps.spec.js/*', {failOnNonZeroExit: false})
    cy.exec('rm cypress-visual-screenshots/comparison/*', {failOnNonZeroExit: false})
    cy.exec('rm cypress-visual-screenshots/diff/*', {failOnNonZeroExit: false})
  })
})

describe('Snapshots of public pages on 13" MacBook', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

    it('Home page snapshot comparison', () => {
      cy.visit('http://localhost:1234')
      cy.viewport('macbook-13')
      cy.compareSnapshot('home-page-mb13', 0.1)
    })

    it('Student login page snapshot comparison', () => {
      cy.visit('http://localhost:1234/login/student')
      cy.compareSnapshot('student-login-mb13', 0.1)
    })

    it('Content creator login page snapshot comparison', () => {
      cy.visit('http://localhost:1234/login/content-creator')
      cy.compareSnapshot('content-creator-login-mb13', 0.1)
    })

    it('Student signup page snapshot comparison', () => {
      cy.visit('http://localhost:1234/signup/student')
      cy.viewport('macbook-13')
      cy.compareSnapshot('student-signup-mb13', 0.1)
    })

    it('Content creator signup page snapshot comparison', () => {
      cy.visit('http://localhost:1234/signup/content-creator')
      cy.compareSnapshot('content-creator-signup-mb13', 0.1)
    })
    it('Reset password snapshot comparison', () => {
      cy.visit('http://localhost:1234/user/forgot-password')
      cy.viewport('macbook-13')
      cy.compareSnapshot('reset-password-mb13', 0.1)
    })
    it('About page snapshot comparison', () => {
      cy.visit('http://localhost:1234/about')
      cy.compareSnapshot('about-page-mb13', 0.1)
    })

    it('Acknowledgements page snapshot comparison', () => {
      cy.visit('http://localhost:1234/acknowledgements')
      cy.compareSnapshot('acknowledgements-page-mb13', 0.1)
    })
  })
})

// ======================== Student Profile Page ========================
describe('Snapshots of student pages on MacBook 13"', () => {
  context('13" macbook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

    it('Logs in as the Cypress user', () => {
      cy.student_login()
        .then(() => {
          cy.wait(500)
          cy.compareSnapshot('student-profile-macbook13', 0.1)
        })
    })

    it('Logs in as the Cypress user, turns off hints', () => {
      cy.student_login()
        .then(() => {
          cy.wait(500)
          cy.turn_off_hints()
          cy.compareSnapshot('student-profile-no-hints-macbook13', 0.1)
        })
    })

    it('Logs in as the Cypress user, clicks performance report tab', () => {
      cy.student_login()
        .then(() => {
          cy.wait(500)
          cy.get('.performance-report-tab')
            .click()
          cy.compareSnapshot('student-profile-performance-report-tab-macbook13', 0.1)
        })
    })

    it('Logs in as the Cypress user, clicks the preferred difficulty drop down', () => {
      cy.student_login()
        .then(() => {
          cy.wait(500)
          cy.get('.difficulty-select')
            .select('Intermediate-Mid')
          cy.compareSnapshot('student-profile-difficulty-dropdown-macbook13', 0.1)
        })
    })
  })
})

describe('Snapshots of public pages on IPhone X', () => {
  context('IPhone X', () => {
    beforeEach(() => {
      cy.viewport('iphone-x')
    })

    it('Home page snapshot comparison', () => {
      cy.visit('http://localhost:1234')
      cy.compareSnapshot('home-page-iphoneX', 0.1)
    })

    it('Student login page snapshot comparison', () => {
      cy.visit('http://localhost:1234/login/student')
      cy.compareSnapshot('student-login-iphoneX', 0.1)
    })

    it('Content creator login page snapshot comparison', () => {
      cy.visit('http://localhost:1234/login/content-creator')
      cy.compareSnapshot('content-creator-login-iphoneX', 0.1)
    })

    it('Student signup page snapshot comparison', () => {
     cy.visit('http://localhost:1234/signup/student')
      cy.compareSnapshot('student-signup-iphoneX', 0.1)
    })

    it('Content creator signup page snapshot comparison', () => {
      cy.visit('http://localhost:1234/signup/content-creator')
      cy.compareSnapshot('content-creator-signup-iphoneX', 0.1)
    })

    it('Reset password snapshot comparison', () => {
      cy.visit('http://localhost:1234/user/forgot-password')
      cy.compareSnapshot('reset-password-iphoneX', 0.1)
    })

// // TODO: Doesn't want to work for some reason.
// //   it('About page snapshot comparison', () => {
// //     cy.visit('http://localhost:1234/about')
// //     cy.viewport('iphone-x')
// //     cy.compareSnapshot('about-page-iphoneX', 0.1)
// //   })

    it('Acknowledgements page snapshot comparison IPhone X viewport', () => {
      cy.visit('http://localhost:1234/acknowledgements')
      cy.compareSnapshot('acknowledgements-page-iphoneX', 0.1)
    })
  })
})

// TODO: Figure out why mobile testing isn't working as well here...
// describe('Snapshots of student pages on IPhone X', () => {
//   context('IPhone X', () => {
//     beforeEach(() => {
//       cy.viewport('iphone-x')
//     })
//     it('Logs in as the Cypress user', () => {
//       cy.student_login()
//         .then(() => {
//           cy.wait(1000)
//           cy.turn_off_hints()
//           cy.compareSnapshot('student-profile-iphonex', 0.1)
//         })
//     })
//   })
// })