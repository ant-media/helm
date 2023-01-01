#!/bin/bash
helm uninstall antmedia 
rm *.tgz
helm dependency update
helm package $(pwd)/.
