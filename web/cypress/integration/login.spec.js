describe('Visit STAR', () => {
    it('Visits the STAR app', () => {
        cy.visit('http://localhost:1234')
    })
})

describe('Login page', () => {
    it('Visits the STAR login page via homepage', () => {
        cy.get('.nav-item')
          .contains('Log in')
          .click()

        cy.url().should('include', '/login/student')
    })
})

// =========== Student Portal ===========

describe('Login page is student portal', () => {
  it("Visit STAR login page and confirm it's the student portal", () => {
    cy.visit('http://localhost:1234/login/student')
    cy.get('.login_role')
      .contains('Student Login')
    
    cy.get('.login_options')
      .children()
      .should('have.length', 3)
      
    cy.get('.login_options')
      .find('div')
      .contains('Sign Up')
      .parentsUntil('.login_options')
      .next('div')
      .contains('Reset Password')
      .parentsUntil('.login_options')
      .next('div')
      .contains('Login as a content editor')
  })
})

describe('Student login to signup', () => {
    it('Visits login portal then moves to signup page', () => {
        cy.get('.login_options')
          .find('a')
          .contains('Sign Up')
          .click()

        cy.url().should('include', '/signup/student')
    })
})

describe('Student login to reset password', () => {
  it('Visits login portal then moves to reset password page', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.get('.login_options')
      .find('a')
      .contains('Reset Password')
      .click()

    cy.url().should('include', '/user/forgot-password')
  })
})

describe('Student login switch to content editor', () => {
  it('Visits the content editor login page from the student portal', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.get('.login_options')
      .find('a')
      .contains('Login as a content editor')
      .click()

    cy.url().should('include', '/login/instructor')
  })
})

describe('Student login switch to about', () => {
  it('Visits the student login page then moves to the about page', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.get('#acknowledgements-and-about')
      .find('div')
      .contains('About This Website')
      .click()
  })
})

describe('Student login switch to acknowledgements', () => {
  it('Visits the student login page then moves to the acknowledgements page', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.get('#acknowledgements-and-about')
      .find('div')
      .contains('Acknowledgements')
      .click()
  })
})

// =========== Content Editor Portal ===========

describe('Login page is instructor portal', () => {
  it("Visit STAR login page and confirm it's the student portal", () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('.login_role')
      .contains('Content Editor Login')

    cy.get('.login_options')
      .children()
      .should('have.length', 3)
        
    cy.get('.login_options')
      .find('div')
      .contains('Sign Up')
      .parentsUntil('.login_options')
      .next('div')
      .contains('Reset Password')
      .parentsUntil('.login_options')
      .next('div')
      .contains('Login as a student')
  })
})

describe('Content Editor login to signup', () => {
  it('Visits login portal then moves to signup page', () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('.login_options')
      .find('a')
      .contains('Sign Up')
      .click()

    cy.url().should('include', '/signup/instructor')
  })
})

describe('Student login to reset password', () => {
  it('Visits login portal then moves to reset password page', () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('.login_options')
      .find('a')
      .contains('Reset Password')
      .click()

    cy.url().should('include', '/user/forgot-password')
  })
})

describe('Student login switch to content editor', () => {
  it('Visits the student login page from the content editor portal', () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('.login_options')
      .find('a')
      .contains('Login as a student')
      .click()

    cy.url().should('include', '/login/student')
  })
})

describe('Content Editor login switch to about', () => {
  it('Visits the student login page then moves to the about page', () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('#acknowledgements-and-about')
      .find('div')
      .contains('About This Website')
      .click()
  })
})

describe('Content Editor login switch to acknowledgements', () => {
  it('Visits the content editor login page then moves to the acknowledgements page', () => {
    cy.visit('http://localhost:1234/login/instructor')
    cy.get('#acknowledgements-and-about')
      .find('div')
      .contains('Acknowledgements')
      .click()
  })
})


// =========== Navbar ===========
describe('Confirms texts in to each navbar link', () => {
  it('Navigate to the homepage, visit each navbar link and confirm they work', () => {
    cy.visit('http://localhost:1234/')
    cy.get("#logo")
      .click()

    cy.get('.profile-menu')
      .children('.nav-item')
      .find('a')
      // .click({multiple: true}) // don't assert, but neat
      .first().should('have.text', 'Log in').parent()
      .next().should('have.text', 'Sign up')
      .next().should('have.text', 'Acknowledgements')
  })
})

// rather gross solution since each link has the same class
describe('Confirms each link is visited in the navbar', () => {
  it('Try each link ', () => {
    cy.get('.profile-menu')
      .children('.nav-item')
      .find('a')
      .first('a')
      .click()

    cy.visit('http://localhost:1234/')
    cy.get('.profile-menu')
      .children('.nav-item')
      .find('a')
      .first('a') // can't seem to skip
      .parent()
      .next()
      .click()

    cy.visit('http://localhost:1234/')
    cy.get('.profile-menu')
      .children('.nav-item')
      .find('a')
      .first('a') // can't seem to skip
      .parent()
      .next()
      .next()
      .click()
  })
})


describe('Logs in the student', () => {
  beforeEach(() => {
    cy.student_login(Cypress.env('USER'), Cypress.env('PWD'))
  })
  it('First navigate to the student login portal, then use command', () => {
    cy.get('.profile-title')
      .should('have.text', 'Student Profile')
  })
})