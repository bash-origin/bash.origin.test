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

    require('bash.origin.express').runForTestHooks(before, after, {
        "routes": {
            "/": "<body>Hello World!</body>"
        }
    });

    it('Test', function (client) {

        client
            .url('http://localhost:' + process.env.PORT + '/')
            .pause(500);

        client.expect.element('body').text.to.contain('Hello World!');
    });
});
