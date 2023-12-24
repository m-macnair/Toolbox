#!/bin/bash
#Catalyst and sugar
#deps that follow doesn't follow
sudo cpan -fi Catalyst::Model::Adaptor Catalyst::Plugin::Authentication Catalyst::Plugin::Session::Store::FastMmap Catalyst::Plugin::Session::State::Cookie Catalyst::Plugin::Session Catalyst::View::TT Catalyst::Controller::HTML::FormFu 
