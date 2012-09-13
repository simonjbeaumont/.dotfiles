'''post changesets to a reviewboard server'''

import os, errno, re
import cStringIO
from distutils.version import LooseVersion
from mercurial import cmdutil, hg, ui, mdiff, patch, util, node
from mercurial.i18n import _

from reviewboard import make_rbclient, ReviewBoardError

def postreview(ui, repo, rev='.', **opts):
    '''post a changeset to a Review Board server

This command creates a new review request on a Review Board server, or updates
an existing review request, based on a changeset in the repository. If no
revision number is specified the parent revision of the working directory is
used.

By default, the diff uploaded to the server is based on the parent of the
revision to be reviewed. A different parent may be specified using the
--parent or --longdiff options. --parent r specifies the revision to use on the
left side while --longdiff looks at the upstream repository specified in .hg/hgrc
to find a common ancestor to use on the left side. --parent may need one of
the options below if the Review Board server can't see the parent.

If the parent revision is not available to the Review Board server (e.g. it
exists in your local repository but not in the one that Review Board has
access to) you must tell postreview how to determine the base revision
to use for a parent diff. The --outgoing, --outgoingrepo or --master options
may be used for this purpose. The --outgoing option is the simplest of these;
it assumes that the upstream repository specified in .hg/hgrc is the same as
the one known to Review Board. The other two options offer more control if
this is not the case. In these cases two diffs are uploaded to Review Board:
the first is the difference between Reviewboard's view of the repo and your
parent revision(left side), the second is the difference between your parent
revision and your review revision(right side). Only the second diff is
under review. If you wish to review all the changes local to your repo use
the --longdiff option above.

The --outgoing option recognizes the path entries 'reviewboard', 'default-push'
and 'default' in this order of precedence. 'reviewboard' may be used if the
repository accessible to Review Board is not the upstream repository.

The --git option causes postreview to generate diffs in Git extended format,
which includes information about file renames and copies. ReviewBoard 1.6 beta
2 or later is required in order to use this feature.

The reviewboard extension may be configured by adding a [reviewboard] section
to your .hgrc or mercurial.ini file, or to the .hg/hgrc file of an individual
repository. The following options are available::

  [reviewboard]

  # REQUIRED
  server = <server_url>             # The URL of your ReviewBoard server

  # OPTIONAL
  http_proxy = <proxy_url>          # HTTP proxy to use for the connection
  user = <rb_username>              # Username to use for ReviewBoard
                                    # connections
  password = <rb_password>          # Password to use for ReviewBoard
                                    # connections
  repoid = <repoid>                 # ReviewBoard repository ID (normally only
                                    # useful in a repository-specific hgrc)
  target_groups = <groups>          # Default groups for new review requests
                                    # (comma-separated list)
  target_people = <users>           # Default users for new review requests
                                    # (comma-separated list)
  explicit_publish_update = <bool>  # If True, updates posted using the -e
                                    # option will not be published immediately
                                    # unless the -p option is also used
  launch_webbrowser = <bool>        # If True, new or updated requests will
                                    # always be shown in a web browser after
                                    # posting.

'''

    server = opts.get('server')
    if not server:
        server = ui.config('reviewboard', 'server')

    if not server:
        raise util.Abort(
                _('please specify a reviewboard server in your .hgrc file') )

    '''We are going to fetch the setting string from hg prefs, there we can set
    our own proxy, or specify 'none' to pass an empty dictionary to urllib2
    which overides the default autodetection when we want to force no proxy'''
    http_proxy = ui.config('reviewboard', 'http_proxy' )
    if http_proxy:
        if http_proxy == 'none':
            proxy = {}
        else:
            proxy = { 'http':http_proxy }
    else:
        proxy=None

    def getdiff(ui, repo, r, parent, opts):
        '''return diff for the specified revision'''
        output = ""
        if opts.get('git') or ui.configbool('diff', 'git'):
            # Git diffs don't include the revision numbers with each file, so
            # we have to put them in the header instead.
            output += "# Node ID " + node.hex(r.node()) + "\n"
            output += "# Parent  " + node.hex(parent.node()) + "\n"
        diffopts = patch.diffopts(ui, opts)
        for chunk in patch.diff(repo, parent.node(), r.node(), opts=diffopts):
            output += chunk
        return output

    parent = opts.get('parent')
    if parent:
        parent = repo[parent]
    else:
        parent = repo[rev].parents()[0]

    outgoing = opts.get('outgoing')
    outgoingrepo = opts.get('outgoingrepo')
    master = opts.get('master')
    repo_id_opt = opts.get('repoid')
    longdiff = opts.get('longdiff')

    if not repo_id_opt:
        repo_id_opt = ui.config('reviewboard','repoid')

    if master:
        rparent = repo[master]
    elif outgoingrepo:
        rparent = remoteparent(ui, repo, rev, upstream=outgoingrepo)
    elif outgoing:
        rparent = remoteparent(ui, repo, rev)
    elif longdiff:
        parent = remoteparent(ui, repo, rev)
        rparent = None
    else:
        rparent = None

    ui.debug(_('Parent is %s\n' % parent))
    ui.debug(_('Remote parent is %s\n' % rparent))

    request_id = None

    if opts.get('existing'):
        request_id = opts.get('existing')

    fields = {}

    c = repo.changectx(rev)
    changesets_string = get_changesets_string(repo, parent, c)

    # Don't clobber the summary and description for an existing request
    # unless specifically asked for    
    if opts.get('update') or not request_id:
        fields['summary']       = toascii(c.description().splitlines()[0])
        fields['description']   = toascii(changesets_string)
        fields['branch']        = toascii(c.branch())

    if opts.get('summary'):
        fields['summary'] = toascii(opts.get('summary'))

    diff = getdiff(ui, repo, c, parent, opts)
    ui.debug('\n=== Diff from parent to rev ===\n')
    ui.debug(diff + '\n')

    if rparent and parent != rparent:
        parentdiff = getdiff(ui, repo, parent, rparent, opts)
        ui.debug('\n=== Diff from rparent to parent ===\n')
        ui.debug(parentdiff + '\n')
    else:
        parentdiff = ''

    for field in ('target_groups', 'target_people'):
        if opts.get(field):
            value = ','.join(opts.get(field))
        else:
            value = ui.config('reviewboard', field)
        if value:
            fields[field] = toascii(value)

    ui.status('\n%s\n' % changesets_string)
    ui.status('reviewboard:\t%s\n' % server)
    ui.status('\n')
    username = opts.get('username') or ui.config('reviewboard', 'user')
    if username:
        ui.status('username: %s\n' % username)
    password = opts.get('password') or ui.config('reviewboard', 'password')
    if password:
        ui.status('password: %s\n' % '**********')

    try:
        reviewboard = make_rbclient(server, username, password, proxy=proxy,
                                    apiver=opts.get('apiver'))
    except Exception, e:
        raise util.Abort(_(str(e)))

    if request_id:
        try:
            reviewboard.update_request(request_id, fields=fields, diff=diff,
                parentdiff=parentdiff, publish=opts.get('publish') or
                    not ui.configbool('reviewboard', 'explicit_publish_update'))
        except ReviewBoardError, msg:
            raise util.Abort(_(str(msg)))
    else:
        if repo_id_opt:
            repo_id = str(int(repo_id_opt))
        else:
            try:
                repositories = reviewboard.repositories()
            except ReviewBoardError, msg:
                raise util.Abort(_(str(msg)))

            if not repositories:
                raise util.Abort(_('no repositories configured at %s' % server))

            ui.status('Repositories:\n')
            repo_ids = set()
            for r in repositories:
                ui.status('[%s] %s\n' % (r.id, r.name) )
                repo_ids.add(str(r.id))
            if len(repositories) > 1:
                repo_id = ui.prompt('repository id:', 0)
                if not repo_id in repo_ids:
                    raise util.Abort(_('invalid repository ID: %s') % repo_id)
            else:
                repo_id = str(repositories[0].id)
                ui.status('repository id: %s\n' % repo_id)

        try:
            request_id = reviewboard.new_request(repo_id, fields, diff, parentdiff)
            if opts.get('publish'):
                reviewboard.publish(request_id)
        except ReviewBoardError, msg:
            raise util.Abort(_(str(msg)))

    request_url = '%s/%s/%s/' % (server, "r", request_id)

    if not request_url.startswith('http'):
        request_url = 'http://%s' % request_url

    msg = 'review request draft saved: %s\n'
    if opts.get('publish'):
        msg = 'review request published: %s\n'
    ui.status(msg % request_url)

    if opts.get('webbrowser') or \
        ui.configbool('reviewboard', 'launch_webbrowser'):
        launch_browser(ui, request_url)

def remoteparent(ui, repo, rev, upstream=None):
    if upstream:
        remotepath = ui.expandpath(upstream)
    else:
        remotepath = ui.expandpath(ui.expandpath('reviewboard', 'default-push'),
                                   'default')
    remoterepo = hg.repository(ui, remotepath)
    out = findoutgoing(repo, remoterepo)
    ancestors = repo.changelog.ancestors([repo.lookup(rev)])
    for o in out:
        orev = repo[o]
        a, b, c = repo.changelog.nodesbetween([orev.node()], [repo[rev].node()])
        if a:
            return orev.parents()[0]

def findoutgoing(repo, remoterepo):
    # The method for doing this has changed a few times...
    try:
        from mercurial import discovery
    except ImportError:
        # Must be earlier than 1.6
        return repo.findoutgoing(remoterepo)

    try:
        if LooseVersion(util.version()) >= LooseVersion('2.1'):
            outgoing = discovery.findcommonoutgoing(repo, remoterepo)
            return outgoing.missing
        common, outheads = discovery.findcommonoutgoing(repo, remoterepo)
        return repo.changelog.findmissing(common=common, heads=outheads)
    except AttributeError:
        # Must be earlier than 1.9
        return discovery.findoutgoing(repo, remoterepo)

def launch_browser(ui, request_url):
    # not all python installations have the webbrowser module
    from mercurial import demandimport
    demandimport.disable()
    try:
        import webbrowser
        webbrowser.open(request_url)
    except:
        ui.status('unable to launch browser - webbrowser module not available.')

    demandimport.enable()

def toascii(s):
    for i in xrange(len(s)):
        if ord(s[i]) >= 128:
            s = s[:i] + '?' + s[i+1:]

    return s

def get_changesets_string(repo, parentctx, ctx):
    """Build a summary from all changesets included in this review."""
    contexts = []
    for node in repo.changelog.nodesbetween([parentctx.node()],[ctx.node()])[0]:
        currctx = repo[node]
        if node == parentctx.node():
            continue
            
        contexts.append(currctx)

    if len(contexts) == 0:
        contexts.append(ctx)

    contexts.reverse()

    changesets_string = '* * *\n\n'.join(
                ['Changeset %s:%s\n---------------------------\n%s\n' %
                (ctx.rev(), ctx, ctx.description())
                for ctx in contexts])

    return changesets_string

cmdtable = {
    "postreview":
        (postreview,
        [
        ('o', 'outgoing', False,
         _('use upstream repository to determine the parent diff base')),
        ('O', 'outgoingrepo', '',
         _('use specified repository to determine the parent diff base')),
        ('i', 'repoid', '',
         _('specify repository id on reviewboard server')),
        ('m', 'master', '',
         _('use specified revision as the parent diff base')),
        ('', 'server', '', _('ReviewBoard server URL')),
        ('g', 'git', False,
         _('use git extended diff format (enables rename/copy support)')),
        ('e', 'existing', '', _('existing request ID to update')),
        ('u', 'update', False, _('update the fields of an existing request')),
        ('p', 'publish', None, _('publish request immediately')),
        ('', 'parent', '', _('parent revision for the uploaded diff')),
        ('l','longdiff', False,
         _('review all changes since last upstream sync')),
        ('s', 'summary', '', _('summary for the review request')),
        ('U', 'target_people', [], _('comma separated list of people needed to review the code')),
        ('G', 'target_groups', [], _('comma separated list of groups needed to review the code')),
        ('w', 'webbrowser', False, _('launch browser to show review')),
        ('', 'username', '', _('username for the ReviewBoard site')),
        ('', 'password', '', _('password for the ReviewBoard site')),
        ('', 'apiver', '', _('ReviewBoard API version (e.g. 1.0, 2.0)')),
        ],
        _('hg postreview [OPTION]... [REVISION]')),
}
