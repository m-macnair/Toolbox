#!/bin/bash
echo -ne "\033]30;$1\007"
ssh $USER@$1.uk1.traveltek.net