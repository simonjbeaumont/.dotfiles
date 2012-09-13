#! /usr/bin/python

import sys, re, os
from mercurial import hg, ui, commands, patch

def master_hook(ui, repo, **kwargs):

        changecontexts = [repo[i] for i in range(repo[kwargs['node']].rev(), len(repo))]
        tip = repo[len(repo)-1]
        parents = len(tip.parents())

        if parents <= 1:
                os.system('hg postreview -g -o -p')

        return False
