# api code for the reviewboard extension, inspired/copied from reviewboard
# post-review code.

import cookielib
import getpass
import mimetools
import os
import urllib2
import simplejson
import mercurial.ui
from urlparse import urljoin, urlparse

class APIError(Exception):
    pass

class ReviewBoardError(Exception):
    def __init__(self, json=None):
        self.msg = None
        self.code = None
        self.tags = {}

        if isinstance(json, str) or isinstance(json, unicode):
            try:
                json = simplejson.loads(json)
            except:
                self.msg = "Unknown error - non-JSON response"
                return

        if json:
            if json.has_key('err'):
                self.msg = json['err']['msg']
                self.code = json['err']['code']
            for key, value in json.items():
                if isinstance(value,unicode) or isinstance(value,str) or \
                    key == 'fields':
                    self.tags[key] = value

    def __str__(self):
        if self.msg:
            return ("%s (%s)" % (self.msg, self.code)) + \
                ''.join([("\n%s: %s" % (k, v)) for k,v in self.tags.items()])
        else:
            return Exception.__str__(self)

class Repository:
    """
    Represents a ReviewBoard repository
    """
    def __init__(self, id, name, tool, path):
        self.id = id
        self.name = name
        self.tool = tool
        self.path = path

class ReviewBoardHTTPPasswordMgr(urllib2.HTTPPasswordMgr):
    """
    Adds HTTP authentication support for URLs.

    Python 2.4's password manager has a bug in http authentication when the
    target server uses a non-standard port.  This works around that bug on
    Python 2.4 installs. This also allows post-review to prompt for passwords
    in a consistent way.

    See: http://bugs.python.org/issue974757
    """
    def __init__(self, reviewboard_url):
        self.passwd  = {}
        self.rb_url  = reviewboard_url
        self.rb_user = None
        self.rb_pass = None

    def set_credentials(self, username, password):
        self.rb_user = username
        self.rb_pass = password

    def find_user_password(self, realm, uri):
        if uri.startswith(self.rb_url):
            if self.rb_user is None or self.rb_pass is None:
                print "==> HTTP Authentication Required"
                print 'Enter username and password for "%s" at %s' % \
                    (realm, urlparse(uri)[1])
                self.rb_user = mercurial.ui.ui().prompt('Username: ')
                self.rb_pass = getpass.getpass('Password: ')

            return self.rb_user, self.rb_pass
        else:
            # If this is an auth request for some other domain (since HTTP
            # handlers are global), fall back to standard password management.
            return urllib2.HTTPPasswordMgr.find_user_password(self, realm, uri)

class ApiRequest(urllib2.Request):
    """
    Allows HTTP methods other than GET and POST to be used
    """
    def __init__(self, method, *args, **kwargs):
        self._method = method
        urllib2.Request.__init__(self, *args, **kwargs)

    def get_method(self):
        return self._method

class HttpErrorHandler(urllib2.HTTPDefaultErrorHandler):
    """
    Error handler that doesn't throw an exception for any code below 400.
    This is necessary because RB returns 2xx codes other than 200 to indicate
    success.
    """
    def http_error_default(self, req, fp, code, msg, hdrs):
        if code >= 400:
            return urllib2.HTTPDefaultErrorHandler.http_error_default(self,
                req, fp, code, msg, hdrs)
        else:
            result = urllib2.HTTPError( req.get_full_url(), code, msg, hdrs, fp)
            result.status = code
            return result

class HttpClient:
    def __init__(self, url, proxy=None):
        if not url.endswith('/'):
            url = url + '/'
        self.url       = url
        if 'APPDATA' in os.environ:
            homepath = os.environ["APPDATA"]
        elif 'USERPROFILE' in os.environ:
            homepath = os.path.join(os.environ["USERPROFILE"], "Local Settings",
                                    "Application Data")
        elif 'HOME' in os.environ:
            homepath = os.environ["HOME"]
        else:
            homepath = ''
        self.cookie_file = os.path.join(homepath, ".post-review-cookies.txt")
        self._cj = cookielib.MozillaCookieJar(self.cookie_file)
        self._password_mgr = ReviewBoardHTTPPasswordMgr(self.url)
        self._opener = opener = urllib2.build_opener(
                        urllib2.ProxyHandler(proxy),
                        urllib2.UnknownHandler(),
                        urllib2.HTTPHandler(),
                        HttpErrorHandler(),
                        urllib2.HTTPErrorProcessor(),
                        urllib2.HTTPCookieProcessor(self._cj),
                        urllib2.HTTPBasicAuthHandler(self._password_mgr),
                        urllib2.HTTPDigestAuthHandler(self._password_mgr)
                        )
        urllib2.install_opener(self._opener)

    def set_credentials(self, username, password):
        self._password_mgr.set_credentials(username, password)

    def api_request(self, method, url, fields=None, files=None):
        """
        Performs an API call using an HTTP request at the specified path.
        """
        try:
            rsp = self._http_request(method, url, fields, files)
            if rsp:
                return self._process_json(rsp)
            else:
                return None
        except APIError, e:
            rsp, = e.args
            raise ReviewBoardError(rsp)

    def has_valid_cookie(self):
        """
        Load the user's cookie file and see if they have a valid
        'rbsessionid' cookie for the current Review Board server.  Returns
        true if so and false otherwise.
        """
        try:
            parsed_url = urlparse(self.url)
            host = parsed_url[1]
            path = parsed_url[2] or '/'

            # Cookie files don't store port numbers, unfortunately, so
            # get rid of the port number if it's present.
            host = host.split(":")[0]

            print("Looking for '%s %s' cookie in %s" % \
                  (host, path, self.cookie_file))
            self._cj.load(self.cookie_file, ignore_expires=True)

            try:
                cookie = self._cj._cookies[host][path]['rbsessionid']

                if not cookie.is_expired():
                    print("Loaded valid cookie -- no login required")
                    return True

                print("Cookie file loaded, but cookie has expired")
            except KeyError:
                print("Cookie file loaded, but no cookie for this server")
        except IOError, error:
            print("Couldn't load cookie file: %s" % error)

        return False

    def _http_request(self, method, path, fields, files):
        """
        Performs an HTTP request on the specified path.
        """
        if path.startswith('/'):
            path = path[1:]
        url = urljoin(self.url, path)
        body = None
        headers = {}
        if fields or files:
            content_type, body = self._encode_multipart_formdata(fields, files)
            headers = {
                'Content-Type': content_type,
                'Content-Length': str(len(body))
                }

        try:
            r = ApiRequest(method, str(url), body, headers)
            data = urllib2.urlopen(r).read()
            self._cj.save(self.cookie_file)
            return data
        except urllib2.URLError, e:
            if not hasattr(e, 'code'):
                raise
            if e.code >= 400:
                raise
            else:
                return ""
        except urllib2.HTTPError, e:
            raise ReviewBoardError(e.read())

    def _process_json(self, data):
        """
        Loads in a JSON file and returns the data if successful. On failure,
        APIError is raised.
        """
        rsp = simplejson.loads(data)

        if rsp['stat'] == 'fail':
            raise APIError, rsp

        return rsp

    def _encode_multipart_formdata(self, fields, files):
        """
        Encodes data for use in an HTTP POST.
        """
        BOUNDARY = mimetools.choose_boundary()
        content = ""

        fields = fields or {}
        files = files or {}

        for key in fields:
            content += "--" + BOUNDARY + "\r\n"
            content += "Content-Disposition: form-data; name=\"%s\"\r\n" % key
            content += "\r\n"
            content += str(fields[key]) + "\r\n"

        for key in files:
            filename = files[key]['filename']
            value = files[key]['content']
            content += "--" + BOUNDARY + "\r\n"
            content += "Content-Disposition: form-data; name=\"%s\"; " % key
            content += "filename=\"%s\"\r\n" % filename
            content += "\r\n"
            content += value + "\r\n"

        content += "--" + BOUNDARY + "--\r\n"
        content += "\r\n"

        content_type = "multipart/form-data; boundary=%s" % BOUNDARY

        return content_type, content

class ApiClient:
    def __init__(self, httpclient):
        self._httpclient = httpclient

    def _api_request(self, method, url, fields=None, files=None):
        return self._httpclient.api_request(method, url, fields, files)

class Api20Client(ApiClient):
    """
    Implements the 2.0 version of the API
    """

    def __init__(self, httpclient):
        ApiClient.__init__(self, httpclient)
        self._repositories = None
        self._requestcache = {}

    def login(self, username=None, password=None):
        self._httpclient.set_credentials(username, password)
        return

    def repositories(self):
        if not self._repositories:
            rsp = self._api_request('GET', '/api/repositories/?max-results=500')
            self._repositories = [Repository(r['id'], r['name'], r['tool'],
                                             r['path'])
                                  for r in rsp['repositories']]
        return self._repositories

    def new_request(self, repo_id, fields={}, diff='', parentdiff=''):
        req = self._create_request(repo_id)
        self._set_request_details(req, fields, diff, parentdiff)
        self._requestcache[req['id']] = req
        return req['id']

    def update_request(self, id, fields={}, diff='', parentdiff='', publish=True):
        req = self._get_request(id)
        self._set_request_details(req, fields, diff, parentdiff)
        if publish:
            self.publish(id)

    def publish(self, id):
        req = self._get_request(id)
        drafturl = req['links']['draft']['href']
        self._api_request('PUT', drafturl, {'public':'1'})

    def _create_request(self, repo_id):
        data = { 'repository': repo_id }
        result = self._api_request('POST', '/api/review-requests/', data)
        return result['review_request']

    def _get_request(self, id):
        if self._requestcache.has_key(id):
            return self._requestcache[id]
        else:
            result = self._api_request('GET', '/api/review-requests/%s/' % id)
            self._requestcache[id] = result['review_request']
            return result['review_request']

    def _set_request_details(self, req, fields, diff, parentdiff):
        if fields:
            drafturl = req['links']['draft']['href']
            self._api_request('PUT', drafturl, fields)
        if diff:
            diffurl = req['links']['diffs']['href']
            data = {'path': {'filename': 'diff', 'content': diff}}
            if parentdiff:
                data['parent_diff_path'] = \
                    {'filename': 'parent_diff', 'content': parentdiff}
            self._api_request('POST', diffurl, {}, data)

class Api10Client(ApiClient):
    """
    Implements the 1.0 version of the API
    """

    def __init__(self, httpclient):
        ApiClient.__init__(self, httpclient)
        self._repositories = None
        self._requests = None

    def _api_post(self, url, fields=None, files=None):
        return self._api_request('POST', url, fields, files)

    def login(self, username=None, password=None):
        if not username and not password and self._httpclient.has_valid_cookie():
            return

        if not username:
            username = mercurial.ui.ui().prompt('Username: ')
        if not password:
            password = getpass.getpass('Password: ')

        self._api_post('/api/json/accounts/login/', {
            'username': username,
            'password': password,
        })

    def repositories(self):
        if not self._repositories:
            rsp = self._api_post('/api/json/repositories/')
            self._repositories = [Repository(r['id'], r['name'], r['tool'],
                                             r['path'])
                                  for r in rsp['repositories']]
        return self._repositories

    def requests(self):
        if not self._requests:
            rsp = self._api_post('/api/json/reviewrequests/all/')
            self._requests = rsp['review_requests']
        return self._requests

    def new_request(self, repo_id, fields={}, diff='', parentdiff=''):
        repository_path = None
        for r in self.repositories():
            if r.id == int(repo_id):
                repository_path = r.path
                break
        if not repository_path:
            raise ReviewBoardError, ("can't find repository with id: %s" % \
                                        repo_id)

        id = self._create_request(repository_path)

        self._set_request_details(id, fields, diff, parentdiff)

        return id

    def update_request(self, id, fields={}, diff='', parentdiff='', publish=True):
        request_id = None
        for r in self.requests():
            if r['id'] == int(id):
                request_id = int(id)
                break
        if not request_id:
            raise ReviewBoardError, ("can't find request with id: %s" % id)

        self._set_request_details(request_id, fields, diff, parentdiff)

        return request_id

    def publish(self, id):
        self._api_post('api/json/reviewrequests/%s/publish/' % id)

    def _create_request(self, repository_path):
        data = { 'repository_path': repository_path }
        rsp = self._api_post('/api/json/reviewrequests/new/', data)

        return rsp['review_request']['id']

    def _set_request_field(self, id, field, value):
        self._api_post('/api/json/reviewrequests/%s/draft/set/' %
                                id, { field: value })

    def _upload_diff(self, id, diff, parentdiff=""):
        data = {'path': {'filename': 'diff', 'content': diff}}
        if parentdiff:
            data['parent_diff_path'] = \
                {'filename': 'parent_diff', 'content': parentdiff}
        rsp = self._api_post('/api/json/reviewrequests/%s/diff/new/' % \
                                id, {}, data)

    def _set_fields(self, id, fields={}):
        for field in fields:
            self._set_request_field(id, field, fields[field])

    def _set_request_details(self, id, fields, diff, parentdiff):
        self._set_fields(id, fields)
        if diff:
            self._upload_diff(id, diff, parentdiff)
        if fields or diff:
            self._save_draft(id)

    def _save_draft(self, id):
        self._api_post("/api/json/reviewrequests/%s/draft/save/" % id )

def make_rbclient(url, username, password, proxy=None, apiver=''):
    httpclient = HttpClient(url, proxy)

    if not httpclient.has_valid_cookie():
        if not username:
            username = mercurial.ui.ui().prompt('Username: ')
        if not password:
            password = getpass.getpass('Password: ')
        httpclient.set_credentials(username, password)

    if not apiver:
        # Figure out whether the server supports API version 2.0
        try:
            httpclient.api_request('GET', '/api/')
            apiver = '2.0'
        except:
            apiver = '1.0'

    if apiver == '2.0':
        return Api20Client(httpclient)
    elif apiver == '1.0':
        cli = Api10Client(httpclient)
        cli.login(username, password)
        return cli
    else:
        raise Exception("Unknown API version: %s" % apiver)
