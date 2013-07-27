#!/bin/sh

# CGroups Configurations and Tools
CGMOUNT="${CGMOUNT:-/sys/fs/cgroup}"
CGPARSER="${CGPARSER:-cgconfigparser}"

# Check root permission
check_root() {
		# Make sure only root can run our script
		if [ "x`id -u`" != "x0" ]; then
				echo "This script must be run as root\n\n"
				exit 1
		fi
}

# Check mouting status of required controllers
check_controllers() {

		# The [cpuset,memory,cpu,cpuacct] controller must be mounted on the same hierarchy
		DIFFH=`awk '/^cpuset/{PH=$2}
						/^memory/{MH=$2}
						/^cpu/{CH=$2}
						/^cpuacct/{AH=$2}
						END{
							if(PH!=MH || PH!=CH || PH!=AH) print 1;
							else print 0;
						}' /proc/cgroups`
		if [ $DIFFH -ne 0 ]; then
				echo "[cpuset,memory,cpu,cpuacct] controllers on different hierachies"
		fi

}

# Build up the Shield my moving all tasks into HOST node
ShieldBuild() {
	echo "Moving all (user-space) tasks into HOST node..."
	local rotate='|/-\'

	printf "Configure HOST cpus [$(cat ${CGMOUNT}/host/cpuset.cpus)]: "
	read CPUS
	[ "x$CPUS" != "x" ] && echo $CPUS > ${CGMOUNT}/host/cpuset.cpus 

	printf "Configure SBox cpus [$(cat ${CGMOUNT}/sbox/cpuset.cpus)]: "
	read CPUS
	[ "x$CPUS" != "x" ] && echo $CPUS > ${CGMOUNT}/sbox/cpuset.cpus 

	printf "Moving tasks to HOST ";
	for P in `cat $CGMOUNT/tasks`; do
			# jumping kernel thread which should not be moved
			readlink /proc/$P/exe >/dev/null 2>&1 || continue

			rotate="${rotate#?}${rotate%???}"
			printf "[%5d]... %.1s\b\b\b\b\b\b\b\b\b\b\b\b" $P  $rotate;
			echo $P > ${CGMOUNT}/host/tasks
	done
	echo

}

# Release the HOST shiled by moving back tasks to ROOT node
ShieldRelease() {
	echo "Moving all (user-space) tasks back to ROOT node..."
	local rotate='|/-\'

	printf "Moving tasks to ROOT ";
	for P in `cat $CGMOUNT/host/tasks`; do

			rotate="${rotate#?}${rotate%???}"
			printf "[%5d]... %.1s\b\b\b\b\b\b\b\b\b\b\b\b" $P  $rotate;
			echo $P > $CGMOUNT/tasks
	done
}


# Setup CGroups if required
setup() {

	# Check if the CGroup hierarcy is already mounted
	if [ ! -f $CGMOUNT/tasks ]; then
		echo "Mounting CGroups on [$CGMOUNT]..."
		mkdir -p $CGMOUNT >/dev/null 2>&1

		mount -t cgroup -o cpuset,memory,cpu,cpuacct sbox \
				$CGMOUNT >/dev/null 2>&1
		if [ $? -ne 0 ]; then
				echo "Mounting hierarchies [cpuset,memory,cpu,cpuacct] FAILED"
				check_controllers
				exit 1
		fi
	fi

	# Getting the total platform available CPUs and MEMs
	PLAT_CPUS=`cat $CGMOUNT/cpuset.cpus`
	PLAT_MEMS=`cat $CGMOUNT/cpuset.mems`

	echo "Build HOST partition.."
	mkdir $CGMOUNT/host || exit 1
	echo $PLAT_CPUS > $CGMOUNT/host/cpuset.cpus
	echo $PLAT_MEMS > $CGMOUNT/host/cpuset.mems

	echo "Build SBox partition.."
	mkdir $CGMOUNT/sbox || exit 1
	echo $PLAT_CPUS > $CGMOUNT/sbox/cpuset.cpus
	echo $PLAT_MEMS > $CGMOUNT/sbox/cpuset.mems

	echo "Setup CGroups shiled..."
	ln -s $CGMOUNT
	ShieldBuild

}

start() {
	# Setup CGroups
	echo "System setup..."
	setup
}

stop() {
	# Cleaning-up CGroup reservations
	if [ -d $CGMOUNT ]; then
		echo "Releasing CGroups shiled..."
		ShieldRelease
		sleep 1
		echo "Releasing BBQ CGroups..."
		find  $CGMOUNT/host -type d -delete
		find  $CGMOUNT/sbox -type d -delete
		umount sbox
		rm cgroup
	fi

	# Clean-up lock and PID files
	rm -f $PIDFILE $LOCKFILE >/dev/null 2>&1

	exit 0
}

restart() {
	stop
	sleep 1
	start
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		restart
		;;
	status)
		# not implemented
		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
		;;
esac

# vim: set tabstop=4:
