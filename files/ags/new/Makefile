.PHONY: build run update

build: 
	ags types || \
	(printf "\n\nSleeping for 2 seconds...\n" && \
	sleep 2 && \
	printf "\n\n\033[1;31mUPDATE FAILED - RUNNING FALLBACK\033[0m\n\n" && \
	printf "Sleeping for 2 seconds...\n" && \
	sleep 2 && \
	npx -y @ts-for-gir/cli list)

run: 
	ags run .

update:
	npx -y npm-check-updates -u
	npm install