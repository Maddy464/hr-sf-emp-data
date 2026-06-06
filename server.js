'use strict';
const cds = require('@sap/cds');

// Development convenience: ?sap-user=<username> switches the authenticated user
// without a Basic Auth popup (needed behind the BAS HTTPS proxy).
//
// How it works:
//   1. First request with ?sap-user=carol.white  →  sets Authorization header
//      AND writes a sap-mock-user cookie so subsequent requests (OData calls
//      from the UI5 app) also authenticate as carol.white without the param.
//   2. Requests without the param  →  reads the sap-mock-user cookie and
//      injects the Authorization header automatically.
//   3. In both cases the incoming session/CAP cookie is dropped so a stale
//      session (e.g. david.brown) cannot bleed through.
cds.on('bootstrap', (app) => {
  const COOKIE = 'sap-mock-user';

  const _injectAuth = (req, user) => {
    const pass = cds.env.requires?.auth?.users?.[user]?.password ?? user;
    req.headers.authorization =
      'Basic ' + Buffer.from(`${user}:${pass}`).toString('base64');
    delete req.headers.cookie;
  };

  const _readCookie = (req) => {
    const raw = req.headers.cookie ?? '';
    const m   = raw.match(new RegExp(`(?:^|;\\s*)${COOKIE}=([^;]+)`));
    return m ? decodeURIComponent(m[1]) : null;
  };

  app.use((req, res, next) => {
    const users    = cds.env.requires?.auth?.users;
    if (!users) return next();

    const paramUser = req.query?.['sap-user'];
    if (paramUser && users[paramUser]) {
      // Persist choice for this browser session
      res.cookie(COOKIE, paramUser, { httpOnly: true, sameSite: 'lax' });
      _injectAuth(req, paramUser);
      return next();
    }

    const cookieUser = _readCookie(req);
    if (cookieUser && users[cookieUser]) {
      _injectAuth(req, cookieUser);
    }

    next();
  });
});

module.exports = cds.server;
