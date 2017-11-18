#!/usr/bin/env bash.origin.test via github.com/nightwatchjs/nightwatch
/*
module.config = {
    "browsers": [
        "firefox"
    ],
    "test_runner": "mocha"
}
*/

describe('Hello World', function() {

    const LIB = require("bash.origin.workspace").forPackage(__dirname + '/../..').LIB;
    
    LIB.BASH_ORIGIN_EXPRESS.runForTestHooks(before, after, {
        "routes": {
            "/": "<body>Hello World!</body>"
        }
    });

    it('Test', function (client) {

        client
            .url('http://localhost:' + process.env.PORT + '/')
            .pause(500);

        client.waitForElementPresent('body', 3000);

//        client.expect.element('body').text.to.contain('Hello World!');
    });
});
