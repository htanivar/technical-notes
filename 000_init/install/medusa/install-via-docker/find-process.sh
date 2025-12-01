#!/usr/bin/env bash
ps -aux | grep 'npm' | awk '{print $2}' | xargs pwdx