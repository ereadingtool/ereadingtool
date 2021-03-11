describe('Home page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234')
    cy.viewport('macbook-13')
    cy.compareSnapshot('home-page-mb13')
  })
})

describe('Home page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234')
    cy.viewport('iphone-x')
    cy.compareSnapshot('home-page-iphoneX')
  })
})

 describe('Student login page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.viewport('macbook-13')
    cy.compareSnapshot('student-login-mb13')
  })
})  

 describe('Student login page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/login/student')
    cy.viewport('iphone-x')
    cy.compareSnapshot('student-login-iphoneX')
  })
})

describe('Content creator login page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/login/content-creator')
    cy.viewport('macbook-13')
    cy.compareSnapshot('content-creator-login-mb13')
  })
})

describe('Content creator login page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/login/content-creator')
    cy.viewport('iphone-x')
    cy.compareSnapshot('content-creator-login-iphoneX')
  })
})

describe('Student signup page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/signup/student')
    cy.viewport('macbook-13')
    cy.compareSnapshot('student-signup-mb13')
  })
})

describe('Student signup page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/signup/student')
    cy.viewport('iphone-x')
    cy.compareSnapshot('student-signup-iphoneX')
  })
})

describe('Content creator signup page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/signup/content-creator')
    cy.viewport('macbook-13')
    cy.compareSnapshot('content-creator-signup-mb13')
  })
})

describe('Content creator signup page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/signup/content-creator')
    cy.viewport('iphone-x')
    cy.compareSnapshot('content-creator-signup-iphoneX')
  })
})

describe('Reset password snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/user/forgot-password')
    cy.viewport('macbook-13')
    cy.compareSnapshot('reset-password-mb13')
  })
})

describe('Reset password snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/user/forgot-password')
    cy.viewport('iphone-x')
    cy.compareSnapshot('reset-password-iphoneX')
  })
})

describe('About page snapshot comparison', () => {
  it('Uses a MacBook 13 viewport', () => {
    cy.visit('http://localhost:1234/about')
    cy.viewport('macbook-13')
    cy.comparaSnapshot('about-page-iphoneX')
  })
})

describe('About page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/about')
    cy.viewport('iphone-x')
    cy.comparaSnapshot('about-page-iphoneX')
  })
})

describe('Acknowledgements page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/acknowledgements')
    cy.viewport('iphone-x')
    cy.comparaSnapshot('acknowledgements-page-iphoneX')
  })
})

describe('Acknowledgements page snapshot comparison', () => {
  it('Uses an IPhone X viewport', () => {
    cy.visit('http://localhost:1234/acknowledgements')
    cy.viewport('iphone-x')
    cy.comparaSnapshot('acknowledgements-page-iphoneX')
  })
})