#!/bin/bash
ngspice "$@" | grep -vE "^(Note|Warning):"
