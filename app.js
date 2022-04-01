// Constants
let count = 0;
const logsDir = './public/logs/'

// Modules for project work
require('log-timestamp')
const request = require('request');
const express = require('express')
const fs = require('fs')

//Server code
fs.mkdir(logsDir, { recursive: true }, (err) => { if (err) console.error(err)});
const app = express()
const port = process.env.PORT || 3000
app.use(express.static(__dirname + "/public/"))
app.use(express.urlencoded({ extended: false }))
const routes = require('./inc/core/routers')


function empty() { console.log(count++) }
function sleep() {
    return new Promise(function (resolve, reject) {
        const options = {
            url: 'http://localhost:3001/test',
        };
        request.get(options, function (error, response, body) {
            console.log(body);
            resolve('Ok')
        });
    });
}


app.get("/", function (req, res) {
    sleep().then((res) => console.log('Result:', res, count++))
    console.log('Query:--', req.method, '-- Controller: --', req.url, '-- IP: --', req.ip)
    fs.appendFileSync('./public/logs/log.txt', `\n${count}`);
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    fs.createReadStream('./public/html/index.html').pipe(res)
    console.log('count', count++)
})

app.get("/log", function (req, res) {
    console.log('Query:--', req.method, '-- Controller: --', req.url, '-- Date: --', Date.now())
    res.setHeader("Content-Type", "text/plain; charset=utf-8")
    fs.createReadStream('./public/logs/log.txt').pipe(res)
})

app.get("/home", routes.homeRouter)

app.get("/test", function (req, res) {
    let n = 0
    while (n++ < 10e3) {
        empty()
    }
    res.end(`TEST_END ${new Date()}`)
})

app.get("/converter", routes.converterRouter)

app.listen(port, function () {
    console.log(`Server running on port:${port}`)
})

console.log(process.argv.at(1))