function getObjectOfCookies() {
    return Object.fromEntries(document.cookie.split(';').map((el)=> el.split('=')))
}