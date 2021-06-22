describe('Checks student guide', () => {
  context('13" MacBook', () => {
    beforeEach(() => {
      cy.viewport('macbook-13')
    })

  let image_count = 0;

  it('Confirms each tab exists', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
          .then(() => {
            cy.get('.guide-tabs')
              .contains('Getting Started')
            cy.get('.guide-tabs')
              .contains('Reading Texts')
            cy.get('.guide-tabs')
              .contains('Settings')
            cy.get('.guide-tabs')
              .contains('Progress')
          })
      })
  })

  it('Checks the Getting Started page for images', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
          .then(() => {
            // MAGIC NUMBER HERE -------------------------------------------v
            cy.get('[class="guide-image-container"]').should('have.length', 6)
            cy.get('[class="guide-image-container"]').each(($el, index, $list) => {
              let img = $el[0].childNodes[0]
              expect(img.src).to.include(`/public/img/tutorial/student/${image_count + index + 1}.png`)
              expect(img).to.have.attr('alt')
              expect(img).to.have.attr('title')
            }).then(() => {
              image_count += 6;
            })
          })
      })
  })

  it('Checks the Reading Texts page for images', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
          .then(() => {
            cy.get('.guide-tabs')
              .contains('Reading Texts')
              .click()
              .then(() => {
                // MAGIC NUMBER HERE -------------------------------------------v
                cy.get('[class="guide-image-container"]').should('have.length', 6)
                cy.get('[class="guide-image-container"]').each(($el, index, $list) => {
                  let img = $el[0].childNodes[0]
                  expect(img.src).to.include(`/public/img/tutorial/student/${image_count + index + 1}.png`)
                  expect(img).to.have.attr('alt')
                  expect(img).to.have.attr('title')
                }).then(() => {
                  image_count += 6;
                })
              })
          })
      })
  })

  it('Checks the Settings page for images', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
          .then(() => {
            cy.get('.guide-tabs')
              .contains('Settings')
              .click()
              .then(() => {
                // MAGIC NUMBER HERE -------------------------------------------v
                cy.get('[class="guide-image-container"]').should('have.length', 1)
                cy.get('[class="guide-image-container"]').each(($el, index, $list) => {
                  let img = $el[0].childNodes[0]
                  expect(img.src).to.include(`/public/img/tutorial/student/${image_count + index + 1}.png`)
                  expect(img).to.have.attr('alt')
                  expect(img).to.have.attr('title')
                }).then(() => {
                  image_count += 1;
                })
              })
          })
      })
  })

  it('Checks the Progress page for images', () => {
    cy.student_login()
      .then(() => {
        cy.get('#header')
          .contains('Guide')
          .click()
          .then(() => {
            cy.get('.guide-tabs')
              .contains('Progress')
              .click()
              .then(() => {
                // MAGIC NUMBER HERE -------------------------------------------v
                cy.get('[class="guide-image-container"]').should('have.length', 1)
                cy.get('[class="guide-image-container"]').each(($el, index, $list) => {
                  let img = $el[0].childNodes[0]
                  expect(img.src).to.include(`/public/img/tutorial/student/${image_count + index + 1}.png`)
                  expect(img).to.have.attr('alt')
                  expect(img).to.have.attr('title')
                }).then(() => {
                  image_count += 1;
                })
              })
          })
      })
  })
  })
})