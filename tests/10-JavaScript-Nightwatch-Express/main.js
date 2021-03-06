#!/usr/bin/env bash.origin.test via github.com/nightwatchjs/nightwatch
/*
module.config = {
    "browsers": [
        "firefox"
    ],
    "test_runner": "mocha"
}
*/

console.log(">>>TEST_IGNORE_LINE:^127\\.<<<");
console.log('>>>TEST_IGNORE_LINE:Connected to <<<');
console.log('>>>TEST_IGNORE_LINE:Using: <<<');

describe('Hello World', function() {

    const LIB = require("bash.origin.lib").forPackage(__dirname);
    
    LIB.js.BASH_ORIGIN_EXPRESS.runForTestHooks(before, after, {
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
