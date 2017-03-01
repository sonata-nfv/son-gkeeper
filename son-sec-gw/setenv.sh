#!/bin/bash
sleep 2
songtkapi=$(cat /etc/hosts | grep son-gtkapi | awk '{print $1}')
songui=$(cat /etc/hosts | grep son-gui | awk '{print $1}')

if [ -n "$songtkapi" ]
then
   sed "s#son-gtkapi#$songtkapi#" -i /etc/nginx/conf.d/*
fi

if [ -n "$songui" ]
then
   sed "s#son-gui#$songui#" -i /etc/nginx/conf.d/*
fi

