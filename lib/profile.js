
const FS = require("fs");
const MINIMIST = require("minimist");
const TABLE = require("cli-table3");


const DEBUG = false;


const ARGS = MINIMIST(process.argv.slice(2));


const RAW_LOG_PATH = ARGS.log;
const RAW_LOG_PROFILER_PID_PATH = RAW_LOG_PATH + ".profiler.pid";
const RAW_LOG_PROFILE_TIMING_PATH = RAW_LOG_PATH + ".profile.timing.json";


if (ARGS._[0] === "profile") {
    if (DEBUG) console.log("Start profiling for:", RAW_LOG_PATH);
    FS.writeFileSync(RAW_LOG_PROFILER_PID_PATH, ("" + process.pid), "utf8");

    try {
        FS.unlinkSync(RAW_LOG_PROFILE_TIMING_PATH);
    } catch (err) {}

    var fd = FS.openSync(RAW_LOG_PATH, 'r');

    var timing = [];

    var lastTime = null;
    var newTime = null;
    var lastSize = 0;
    var newSize = null;
    // TODO: Make resolution (i.e. 10ms) configurable.
    var monitorInterval = setInterval(function () {
        newTime = Date.now();
        newSize = FS.statSync(RAW_LOG_PATH).size;
        if (
            newSize !== lastSize && 
            newTime !== lastTime
        ) {
            var buffer = new Buffer(newSize - lastSize);
            FS.readSync(fd, buffer, 0, newSize - lastSize, lastSize - 1);
            lastTime = newTime;
            lastSize = newSize;
            timing.push([
                newTime,
                newSize,
                buffer.toString().split("\n").pop()
            ]);
        }
    }, 10);

    function stop () {
        if (monitorInterval) {
            clearInterval(monitorInterval);
            monitorInterval = null;
        }
        FS.closeSync(fd);
        FS.writeFileSync(RAW_LOG_PROFILE_TIMING_PATH, JSON.stringify(timing, null, 4), "utf8");
        try {
            FS.unlinkSync(RAW_LOG_PROFILER_PID_PATH);
        } catch (err) {}
        process.exit(0);
    }

    // Reactive
    process.on('SIGINT', stop);
    // Sanity
    setInterval(function () {
        FS.exists(RAW_LOG_PROFILER_PID_PATH, function (exists) {
            if (exists) return;
            stop();
        });
    }, 1000);

} else
if (ARGS._[0] === "summary") {
    if (DEBUG) console.log("Summary for:", RAW_LOG_PATH);

    // Notify
    var pid = parseInt(FS.readFileSync(RAW_LOG_PROFILER_PID_PATH, "utf8"));
    try {
        FS.unlinkSync(RAW_LOG_PROFILER_PID_PATH);
    } catch (err) {}
    process.kill(pid, 'SIGINT');

    // Wait for a second for the timing file to be written
    // TODO: Wait for the timing file and act once it has no handles.
    setTimeout(function () {
        try {

            // Parse
            var rawResult = FS.readFileSync(RAW_LOG_PATH, "utf8");
            var lines = rawResult.split("\n");

            var headerSizeOffset = 0;

            // NOTE: We subtract the first few lines that set environment variables
            for (var i=0; i<lines.length; i++) {
                if (/^\+ \//.test(lines[i])) {
                    headerSizeOffset = lines.slice(0, i).join("\n").length + 1;
                    lines = lines.slice(i);
                    break;
                }
            }

            // NOTE: We subtract 2 more lines to remove the test runner instructions that turn debugging off again
            lines = lines.slice(0, lines.indexOf("##### END_TEST_RESULT #####") - 1);

            var timing = JSON.parse(FS.readFileSync(RAW_LOG_PROFILE_TIMING_PATH, "utf8"));

            var timingBySize = {};
            timing.forEach(function (slice, i) {
                timingBySize[slice[1]] = slice[0];
            });

            var sizes = Object.keys(timingBySize);

            var sections = [];
            var section = {
                length: 0,
                lines: []
            };
            var usedLength = headerSizeOffset;

            sizes.forEach(function (size, i) {
                var timing = timingBySize[size];

                while (true) {
                    var line = lines[0] || "";
                    if ((usedLength + line.length + 1) > size) {
                        break;
                    }
                    var line = lines.shift();
                    if (!line) break;
                    section.lines.push(line);
                    section.length += line.length + 1;
                    usedLength += line.length + 1;
                }
                section.size = size;
                section.usedLength = usedLength;
/*
                if (i === sizes.length - 1) {
                    if (lines.length) {
                        lines.forEach(function (line) {
                            section.lines.push(line);
                            section.length += line.length + 1;
                            usedLength += line.length + 1;
                        });
                        lines = [];
                    }
                }
*/
                if (i > 0) {
                    sections.push(section);
                }
                sections.push({
                    time: timing
                });
                section = {
                    length: 0,
                    lines: []
                };
            });

            // Drop the last line if it is empty. Needed to properly attribute timing to last section.
            if (sections.length > 4 && sections[sections.length-2].length === 0) {
                sections.splice(sections.length-3, 2);
            }

            var table = new TABLE({
                head: ['Duration (ms)', 'Code'],
                colWidths: [15, 150]
            });

            var section = null;
            for (var i=0; i<sections.length; i++) {
                section = sections[i];
                if (section.lines) {

                    var duration = (sections[i + 1].time - sections[i-1].time);

                    if (duration < 30 && !!!process.env.VERBOSE) {
                        // We ignore sections that took little time unless we are running in verbose mode.
                        continue;
                    }

                    table.push([
                        duration,
                        sections[i].lines.join("\n")
                    ]);
                }
            }

            process.stdout.write(table.toString() + "\n");

        } catch (err) {
            console.error(err.stack);
        }
    }, 1000);

} else {
    throw new Error("Unknown command: " + ARGS._);
}
