#!/usr/bin/env bash.origin.test via github.com/nightwatchjs/nightwatch
/*
module.config = {
    "browsers": [
        "firefox"
    ],
    "test_runner": {
        "type": "mocha",
        "options": {
            "ui": "bdd",
            "reporter": "list"
        }
    }    
}
*/

const HTTP = require('http');

describe('Hello World', function() {

    var server = null;

    before(function(client, done) {

        server = HTTP.createServer(function (req, res) {
            res.statusCode = 200;
            res.setHeader('Content-Type', 'text/html');
            res.end('<body>Hello World!</body>');
        });

        server.listen(parseInt(process.env.PORT), '127.0.0.1', () => {

            console.log('Server running at http://localhost:' + process.env.PORT);
            done();
        });
    });

    after(function(client, done) {
        client.end(function() {
            server.close(done);
        });
    });

    it('Test', function (client) {

        client
            .url('http://localhost:' + process.env.PORT + '/')
            .pause(500);

        client.waitForElementPresent('body', 3000);

        client.expect.element('body').text.to.contain('Hello World!');
    });
});
