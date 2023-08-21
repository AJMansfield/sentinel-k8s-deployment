#!/bin/bash

set -x

output_sbom="sbom.spdx"

all_images=($(kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" \
    | tr -s '[[:space:]]' '\n' \
    | sort --unique ))

image_args=()
for image in "${all_images[@]}"; do image_args+=(--image "$image"); done

bom generate --output "$output_sbom" --dirs . "${image_args[@]}"
