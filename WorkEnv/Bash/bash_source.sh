export TOOLBOXDIR="/home/m/git/Toolbox"
export PATH="$PATH:/home/m/git/Toolbox/WorkEnv/PathScripts"
# straight string dumped into bash_source.rc when setup.pl is run
# setup.pl provides the environment variables to make this work
source $TOOLBOXDIR/WorkEnv/Bash/aliases.sh
source $TOOLBOXDIR/WorkEnv/Bash/functions.sh
export PERL5LIB="$PERL5LIB:/home/m/git/Toolbox-lib/lib/:/home/m/git/Moo-GenericRole/lib/"
