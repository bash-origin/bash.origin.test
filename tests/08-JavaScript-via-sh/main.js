#!/usr/bin/env bash.origin.test via github.com/facebook/jest

console.log("Load code");

if (process.env.NODE_ENV === "test") {

    console.log("Test code");

    test('Test', function () {

        expect(true).toBe(true);
    });

} else {

    console.log("Runtime code");

}
