#should probably make this an env variable :D
Toolbox="/home/m/Code/Repo/Toolbox"
alias clean.pl="perl $Toolbox/clean.pl"
alias tidy.sh="sh $Toolbox/tidy.sh"
alias ctidy.sh="sh $Toolbox/ctidy.sh"
alias ttidy.sh="sh $Toolbox/ttidy.sh"
#for when inside a Module::Starter based module's /script directory. Eventually should look for ./lib further up too
alias hperl="perl -I../lib/ "
alias perll="perl -I./lib/ "
alias mstarter='module-starter --author="mmacnair" --email=mmacnair@cpan.org --license=bsd '
alias prover="clear && prove -l -r t"
alias gitaddperl="find ./ -type f -name \"*.p[ml]\" -exec git add {} \;"
alias gitaddtest="find ./ -type f -name \"*.t\" -exec git add {} \;"
alias gitignoresymlink="find . -type l | sed -e s'/^\.\///g' >> .gitignore"
alias rmtestdb='find ./ -type f -name "*test_file.sqlite" -exec rm {} \;'