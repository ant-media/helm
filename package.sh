#!/bin/bash
rm $(pwd)/antmedia-$(cat VERSION).tgz
helm dependency update
helm package $(pwd)/.
helm repo index --url https://ant-media.github.io/helm/ --merge index.yaml .
cat $(pwd)/Chart.yaml |grep "version: [0-9].[0-9]" | cut -d " " -f 2 > $(pwd)/VERSION
