#!/usr/bin/perl
# for when i'm me and not someone else
`perl ./setup.pl`;
`git config --global credential.helper cache`;
`git config --global credential.helper 'cache --timeout=36000'`;
`touch /home/$ENV{USER}/.git-credential-cache`;
`chmod 0700 /home/$ENV{USER}/.git-credential-cache`;

`git config --global core.editor "vi "`;
`git config --global user.email  mmacnair@cpan.org`;
`git config --global user.name "m"`;
