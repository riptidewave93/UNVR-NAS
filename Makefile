.DEFAULT_GOAL := build
CONTAINER_NAME = unvr-nas:builder

setup:
	sudo modprobe loop; \
	sudo modprobe binfmt_misc

build: setup
	@set -e;	\
	for file in `ls ./scripts/[0-99]*.sh`;	\
	do					\
		bash $${file};			\
	done					\

clean: mountclean
	sudo rm -rf $(CURDIR)/BuildEnv; \
	docker ps -a | awk '{ print $$1,$$2 }' | grep $(CONTAINER_NAME) | awk '{print $$1 }' | xargs -I {} docker rm {};

distclean: clean
	docker rmi $(CONTAINER_NAME) -f; \
	rm -rf $(CURDIR)/downloads $(CURDIR)/output

mountclean:
	sudo umount $(CURDIR)/BuildEnv/rootfs/boot; \
	sudo umount $(CURDIR)/BuildEnv/rootfs; \
	sudo losetup -D
