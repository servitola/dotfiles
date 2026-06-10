# Scanning Heuristics — High-Signal Grep Patterns per Stack

## Contents
- React / browser JavaScript-TypeScript (frontend)
- Node / Express (backend)
- Next.js (SSR / fullstack)
- Django / Python (backend)
- Dependency hygiene (all JS/TS stacks)

Use during step "systematic file review" of the audit. Identify the stack(s)
first (frontend + backend separately), then run only the relevant sections.

**A grep hit is a lead, not a finding.** Before reporting, always confirm:
1. Data origin — is the value actually attacker-influenced (URL, storage,
   API response, postMessage, DB rows editable by users)?
2. Sink type — HTML/DOM, SQL, subprocess, filesystem, redirect, outbound HTTP,
   code execution, template engine.
3. Protective controls already present — sanitizer, allowlist, CSRF token,
   CSP, parameterization, middleware. Defense-in-depth in place lowers severity.

Severity tags below are *ceilings* assuming the lead is confirmed
attacker-reachable; downgrade when context limits exploitability.

---

## React / browser JavaScript-TypeScript (frontend)

**Raw HTML / XSS escape hatches** — High:
```
dangerouslySetInnerHTML    __html:
rehype-raw    allowDangerousHtml    sanitize: false
```
Trace the HTML string origin (API/CMS/URL/localStorage). Sanitization must be
DOMPurify-class with allowlist config — regex/ad-hoc stripping does not count.

**DOM XSS sinks** (also outside React rendering) — High:
```
innerHTML    outerHTML    insertAdjacentHTML(    document.write(    document.writeln(
DOMParser    createContextualFragment
```
Safe alternative: `textContent` or normal JSX interpolation (escaped by default).

**String-to-code execution** — Critical:
```
eval(    new Function(    setTimeout("    setInterval("
.setAttribute("on    .onclick =    .onload =
```

**Untrusted URL / navigation sinks** — High:
```
href={    src={    window.location    location.href    location.assign    location.replace
window.open    navigate(    javascript:    data:text/html
```
Query params named `next`, `returnTo`, `redirect` flowing into navigation =
open redirect. Fix: allow only relative paths (`/^\/[^\s]*$/`) or a strict
origin allowlist; safe fallback on validation failure.

**Token/session storage risk** — High (violates "Never do" tier):
```
localStorage.setItem    sessionStorage.setItem    getItem(
```
…combined with keys/values containing `token`, `jwt`, `session`, `auth`,
`refresh`. XSS exfiltrates all Web Storage; tokens belong in httpOnly cookies
or short-lived in-memory storage.

**Cookie/CSRF coupling** — High:
```
credentials: 'include'    withCredentials: true
```
…on state-changing requests (POST/PUT/PATCH/DELETE) with no CSRF token header
(`X-CSRF-Token` or equivalent). If auth is header-based (Bearer), CSRF is not
a concern — don't report it.

**postMessage** — Medium-High:
```
postMessage(    addEventListener('message'
```
Flag `postMessage(data, '*')` and message handlers without a strict
`event.origin` allowlist check. Payload must be treated as untrusted data —
never eval'd or inserted as HTML.

**Secrets in the bundle** — Critical:
```
REACT_APP_    VITE_    NEXT_PUBLIC_    process.env.    import.meta.env.
apiKey    client_secret    private    password
```
Anything shipped to the browser is public. Build-time env vars are embedded
in the bundle. Also inspect `public/` for runtime config JSON and check
whether source maps are published.

**Third-party scripts / supply chain** — Medium:
```
<script src=    integrity=    document.createElement('script')
navigator.serviceWorker.register
```
Third-party `<script src>` without `integrity=` (SRI) and unpinned versions;
dynamic script insertion; tag manager snippets (GTM, Segment, Hotjar) with no
governance. Service workers: must be HTTPS-only; flag indiscriminate caching
of authenticated API responses.

---

## Node / Express (backend)

**Proxy trust** — Medium:
```
app.set('trust proxy', true)    req.ip    req.protocol    req.hostname
```
`trust proxy: true` with security logic reading `req.ip`/`req.protocol` lets
clients spoof `X-Forwarded-*`. Configure the exact hop count or proxy IPs.

**Headers / fingerprinting** — Medium:
```
helmet(    x-powered-by
```
Missing `helmet()`; missing `app.disable('x-powered-by')`.

**Sessions / cookies** — High:
```
express-session    cookie-session    secret:
```
Flag: hard-coded `secret:`, missing `store` (MemoryStore in production),
missing `cookie: { secure, httpOnly, sameSite }`, `cookie-session` carrying
large objects or secrets client-side.

**Body parsing limits (DoS)** — Medium:
```
express.json()    express.urlencoded()
```
…without `limit` / `parameterLimit` — unbounded body parsing.

**Open redirect** — Medium:
```
res.redirect(req.query    res.redirect(req.body
```

**Injection** — Critical:
```
child_process.exec    execSync    shell: true
```
SQL template literals into DB calls (`` query(`SELECT ... ${ `` ). Command
execution with request-derived strings.

**File handling** — High:
```
res.sendFile(    res.download(    express.static('uploads'
path.join(    fs.readFile(
```
…where the path originates from the request → path traversal. Uploads served
as static content → stored XSS / active content.

**SSRF** — High:
```
fetch(    axios(    got(
```
…with user-provided URLs from server-side code. Check for allowlists.

**Runtime hazards** — High:
```
--inspect    insecureHTTPParser
```
…in production start scripts.

---

## Next.js (SSR / fullstack)

**Production misconfig** — High:
```
next dev    NODE_ENV=development
```
…in production start commands / Dockerfiles.

**Secrets exposure** — Critical:
```
NEXT_PUBLIC_
```
…on sensitive variables; `process.env` referenced inside `"use client"`
modules; `.env` committed.

**Auth coverage** — High:
- `app/**/route.ts` or `pages/api/**` handlers with no auth check.
- `"use server"` actions performing DB writes with no authorization.
- `middleware.ts` matchers that exclude sensitive routes.

**Caching / data leak** — High:
```
dynamic = 'force-static'    use cache    cacheLife    unstable_cache
```
…around user-specific or authenticated data — one user's data cached and
served to others.

**Server-side sinks** — High:
```
redirect(searchParams    NextResponse.redirect(    fetch(userProvidedUrl
fs.readFile    path.join
```
…with request input in Route Handlers / Server Actions (open redirect, SSRF,
path traversal). Uploads written under `public/` = served as live content.

**Webhooks / limits** — Medium:
- API routes with `bodyParser: false` and no raw-body signature verification.
- `serverActions.bodySizeLimit` raised or `serverActions.allowedOrigins`
  broadened without justification.

---

## Django / Python (backend)

**Deployment / dev server** — Critical in production:
```
manage.py runserver    runserver 0.0.0.0    --insecure
DEBUG = True
```
`DEBUG = True` in production leaks settings, stack traces, and environment.
`runserver` is not a production server.

**Host validation** — High:
```
ALLOWED_HOSTS = ['*']
ALLOWED_HOSTS = []
```
Wildcard enables Host-header attacks (cache poisoning, password-reset
poisoning).

**SECRET_KEY hygiene and rotation** — Critical if leaked:
```
SECRET_KEY =    SECRET_KEY_FALLBACKS
```
Audit checks:
- `SECRET_KEY` hard-coded in settings committed to VCS → Critical.
- Rotation: the safe path is `SECRET_KEY_FALLBACKS` — new key in `SECRET_KEY`,
  old key(s) temporarily in `SECRET_KEY_FALLBACKS` so signed data (sessions,
  password-reset tokens) survives rotation. Flag both: rotation done *without*
  fallbacks (mass session invalidation hides whether old key is still trusted
  somewhere) and stale keys left in `SECRET_KEY_FALLBACKS` indefinitely
  (extends the attack window of a compromised key) → Medium.

**HTTPS and proxy trust** — High:
```
SECURE_SSL_REDIRECT    SECURE_HSTS_SECONDS    SECURE_PROXY_SSL_HEADER
```
`SECURE_PROXY_SSL_HEADER` tradeoff (common in Docker/K8s behind a TLS-terminating
proxy):
- *Missing* behind a proxy → `request.is_secure()` is wrong, secure-cookie and
  CSRF logic break, redirect loops with `SECURE_SSL_REDIRECT`.
- *Set* when the proxy does NOT strip client-supplied `X-Forwarded-Proto` →
  clients spoof "https" and bypass HTTPS-only logic → High.
Verify the proxy config strips/overwrites the header before accepting the
setting as safe. If not visible in the repo, report as "verify at the edge".

**Cookies / sessions** — Medium:
```
SESSION_COOKIE_SECURE    SESSION_COOKIE_HTTPONLY    SESSION_COOKIE_SAMESITE
CSRF_COOKIE_SECURE    CSRF_COOKIE_SAMESITE
```
Missing/False in production settings. (Careful: `secure` cookies on non-TLS
dev/test deployments break the app — only flag for production configs.)

**CSRF bypasses** — High:
```
csrf_exempt    CsrfViewMiddleware    {% csrf_token %}
```
Audit rule: every `@csrf_exempt` is a finding by default ("Ask first" tier —
was this approved?). The only routinely acceptable use is a webhook endpoint,
and then an **alternative control must be present**: request signature
verification (HMAC over the raw body, e.g. Stripe/GitHub-style), not just an
obscure URL or IP filter. `@csrf_exempt` on a general-purpose authenticated
view with no compensating control → High. Also flag removed
`CsrfViewMiddleware` and POST forms missing `{% csrf_token %}`.

**XSS** — High:
```
|safe    autoescape off    safeseq    mark_safe(    SafeString    format_html(
```
`mark_safe()` / `|safe` on values containing request data, user content, or
DB rows editable by users. `format_html` with pre-built HTML strings as args.
Direct `HttpResponse(user_value)` returning HTML.

**SQL injection** — Critical:
```
.raw(    .extra(    RawSQL(    cursor.execute(
```
…with f-strings, `%`-format, `.format()`, or `+` concatenation building the
SQL. Parameters must go through `params=` / placeholder args. Also flag quoted
placeholders (`'%s'`) — quoting placeholders defeats parameterization.

**Runtime template rendering (server-side template injection)** — High-Critical:
```
django.template.Template(    Engine.from_string(    .render(Context(
```
…with non-constant template strings. Treat "template source influenced by
untrusted input" as its own injection class — even Django's constrained engine
leaks context data and bypasses escaping; in engines like Jinja2
(`from_string`) it is full RCE. Same class applies to any stack: user-supplied
Handlebars/EJS/Razor template strings compiled at runtime. Fix: non-executing
formatting (`string.Template`, explicit placeholders) or heavy isolation.

**Insecure deserialization** — Critical:
```
pickle.loads(    pickle.load(    PickleSerializer    yaml.load(
```
`pickle` on any attacker-influenced bytes (cache values, queue messages,
cookies, uploaded files) = code execution. `SESSION_SERIALIZER =
...PickleSerializer` turns a leaked `SECRET_KEY` into RCE. `yaml.load` without
`SafeLoader`.

**Uploads / media** — Medium:
```
request.FILES    MEDIA_ROOT    MEDIA_URL
```
Media served inline (stored XSS via HTML/SVG), `MEDIA_ROOT == STATIC_ROOT`,
no extension/content-type allowlist.

**Open redirect** — Medium:
```
redirect(request.GET    url_has_allowed_host_and_scheme
```
`redirect(request.GET.get("next"))` without
`url_has_allowed_host_and_scheme()` validation.

**Headers** — Medium:
```
SecurityMiddleware    X_FRAME_OPTIONS    SECURE_CONTENT_TYPE_NOSNIFF
```
Missing `SecurityMiddleware`, missing clickjacking protection, no CSP.

---

## Dependency hygiene (all JS/TS stacks)

Audit checks — Medium unless a known-exploitable CVE is reachable:
- **Lockfile present and enforced**: `package-lock.json` / `yarn.lock` /
  `pnpm-lock.yaml` committed. CI must install with `npm ci` (or
  `yarn install --frozen-lockfile` / `pnpm install --frozen-lockfile`) —
  bare `npm install` in CI silently drifts from the lockfile and produces
  non-reproducible, tamperable builds.
  ```
  grep CI configs for: npm install    npm ci    frozen-lockfile
  ```
- **Install scripts**: suspicious `postinstall` hooks in dependencies; consider
  `--ignore-scripts` where feasible.
- **Audit step**: `npm audit` (or equivalent) wired into the release flow —
  triage per the decision tree in SKILL.md.
