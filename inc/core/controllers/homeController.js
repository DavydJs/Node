const fs = require('fs')
const dir = __dirname.replace('controllers','')

exports.home = function(req, res) {
    console.log('Query:--', req.method,'-- Controller: --', req.url, '-- Date: --', new Date())
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    fs.createReadStream(`${dir}/views/home.html`).pipe(res)
}
