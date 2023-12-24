#!/bin/bash
#bare minimum to accomplish anything useful

(echo o conf prerequisites_policy follow;echo o conf commit)|cpan
sudo cpan CPAN
sudo cpan Log::Log4perl
sudo cpan Moo Config::Any::Merge Data::UUID File::Find::Rule CPAN::DistnameInfo



