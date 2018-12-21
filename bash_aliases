#should probably make this an env variable :D
Toolbox="/home/m/Code/Repo/Toolbox"
alias clean.pl="perl $Toolbox/clean.pl"
alias tidy.sh="sh $Toolbox/tidy.sh"
alias ctidy.sh="sh $Toolbox/ctidy.sh"
alias ttidy.sh="sh $Toolbox/ttidy.sh"
#for when inside a Module::Starter based module's /script directory. Eventually should look for ./lib further up too
alias hperl="perl -I../lib/ "
alias mstarter='module-starter --author="mmacnair" --email=mmacnair@cpan.org '
alias rprove="prove -l -r "