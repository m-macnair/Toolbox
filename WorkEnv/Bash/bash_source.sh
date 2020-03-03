export TOOLBOXDIR="/mnt/sda3/home/m/git/Toolbox"
export PATH="$PATH:/mnt/sda3/home/m/git/Toolbox/WorkEnv//PathScripts"
export PERL5LIB="$PERL5LIB:/mnt/sda3/home/m/git/Toolbox/perl/lib/"
# straight string dumped into bash_source.rc when setup.pl is run
# setup.pl provides the environment variables to make this work
source $TOOLBOXDIR/WorkEnv/Bash/aliases.sh
source $TOOLBOXDIR/WorkEnv/Bash/functions.sh