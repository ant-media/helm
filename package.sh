#!/bin/bash
helm uninstall antmedia 
rm *.tgz
helm dependency update
helm package $(pwd)/.
helm repo index --url https://ant-media.github.io/helm/ --merge index.yaml .
