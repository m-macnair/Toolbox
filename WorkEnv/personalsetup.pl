#!/usr/bin/perl
# for when i'm me and not someone else

`git config --global credential.helper cache`;
`git config --global credential.helper 'cache --timeout=36000'`;
`chmod 0700 /home/$ENV{USER}/.git-credential-cache`;

`git config --global core.editor "vi "`;
`git config --global user.email  mmacnair@cpan.org`;
`git config --global user.name "m"`;
