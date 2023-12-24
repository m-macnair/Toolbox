#!/bin/bash
#Catalyst and sugar
#deps that follow doesn't follow
sudo cpan -fi MooseX::ConfigFromFile MooseX::Types::Path::Tiny

sudo cpan  MooseX  Catalyst path_db.sqlite
