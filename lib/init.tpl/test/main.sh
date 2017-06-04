#!/usr/bin/env bash.origin.script

echo "OK"



exit 0

##############################
# main.js for jest
##############################
#!/usr/bin/env bash.origin.test via github.com/facebook/jest

test('Test', function () {

    expect(true).toBe(true);
});


##############################
# main.js for nightwatch
##############################
#!/usr/bin/env bash.origin.test via github.com/nightwatchjs/nightwatch

module.exports = {
    'Demo test Google' : function (browser) {
        browser
            .url('http://www.google.com')
            .waitForElementVisible('body', 2000)
            .setValue('input[type=text]', 'nightwatch')
            .waitForElementVisible('button[name=btnG]', 2000)
            .click('button[name=btnG]')
            .pause(2000)
            .assert.containsText('#main', 'Night Watch')
            .end();
    }
};
