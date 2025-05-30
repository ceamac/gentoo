# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LUA_COMPAT=( lua5-{1..4} )

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/SchedMD/slurm.git"
	INHERIT_GIT="git-r3"
	MY_P="${P}"
else
	if [[ ${PV} == *pre* || ${PV} == *rc* ]]; then
		MY_PV=$(ver_rs '-0.') # pre-releases or release-candidate
	else
		MY_PV=$(ver_rs 1-4 '-') # stable releases
	fi
	MY_P="${P}"
	INHERIT_GIT=""
	SRC_URI="https://download.schedmd.com/slurm/${MY_P}.tar.bz2"
	KEYWORDS="~amd64 ~arm64 ~riscv ~x86"
fi

inherit autotools bash-completion-r1 flag-o-matic lua-single pam \
		perl-module prefix toolchain-funcs systemd ${INHERIT_GIT} \
		tmpfiles

DESCRIPTION="A Highly Scalable Resource Manager"
HOMEPAGE="https://www.schedmd.com https://github.com/SchedMD/slurm"

LICENSE="GPL-2"
S="${WORKDIR}/${MY_P}"
SLOT="0"

IUSE="X debug hdf5 html ipmi json lua multiple-slurmd +munge mysql numa
		nvml ofed pam perl slurmdbd slurmrestd static-libs torque ucx yaml"

COMMON_DEPEND="
	!sys-cluster/torque
	!net-analyzer/slurm
	!net-analyzer/sinfo
	|| ( sys-cluster/pmix[-pmi] >=sys-cluster/openmpi-2.0.0 )
	mysql? (
		|| ( dev-db/mariadb-connector-c dev-db/mysql-connector-c )
		slurmdbd? ( || ( dev-db/mariadb:* dev-db/mysql:* ) )
		)
	slurmrestd? (
		net-libs/http-parser
	)
	munge? ( sys-auth/munge )
	pam? ( sys-libs/pam )
	lua? ( ${LUA_DEPS} )
	ipmi? ( sys-libs/freeipmi )
	json? ( dev-libs/json-c:= )
	hdf5? ( sci-libs/hdf5:= )
	numa? ( sys-process/numactl )
	nvml? ( dev-util/nvidia-cuda-toolkit x11-drivers/nvidia-drivers )
	ofed? ( sys-cluster/rdma-core )
	ucx? ( sys-cluster/ucx )
	yaml? ( dev-libs/libyaml )
	X? ( net-libs/libssh2 )
	>=sys-apps/hwloc-1.1.1-r1:=
	sys-libs/ncurses:0=
	app-arch/lz4:0=
	dev-libs/glib:2=
	sys-apps/dbus
	sys-libs/readline:0="

DEPEND="${COMMON_DEPEND}
	html? ( sys-apps/man2html )"

BDEPEND="acct-user/slurm
	acct-group/slurm"

RDEPEND="${COMMON_DEPEND}
	dev-libs/libcgroup"

REQUIRED_USE="lua? ( ${LUA_REQUIRED_USE} )
	torque? ( perl )
	slurmrestd? ( json ) "

LIBSLURM_PERL_S="${S}/contribs/perlapi/libslurm/perl"
LIBSLURMDB_PERL_S="${S}/contribs/perlapi/libslurmdb/perl"

RESTRICT="test"

pkg_setup() {
	append-ldflags -Wl,-z,lazy
	use lua && lua-single_pkg_setup
}

src_unpack() {
	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	tc-ld-force-bfd
	default

	# pids should go to /var/run/slurm
	sed \
		-e 's:/tmp:/var/tmp:g' \
		-e "s:/var/run/slurmctld.pid:${EPREFIX}/run/slurm/slurmctld.pid:g" \
		-e "s:/var/run/slurmd.pid:${EPREFIX}/run/slurm/slurmd.pid:g" \
		-e "s:StateSaveLocation=.*:StateSaveLocation=${EPREFIX}/var/spool/slurm:g" \
		-e "s:SlurmdSpoolDir=.*:SlurmdSpoolDir=${EPREFIX}/var/spool/slurm/slurmd:g" \
		-i "${S}/etc/slurm.conf.example" \
		|| die "Can't sed for /var/run/slurmctld.pid"
	sed \
		-e "s:/var/run/slurmdbd.pid:${EPREFIX}/run/slurm/slurmdbd.pid:g" \
		-i "${S}/etc/slurmdbd.conf.example" \
		|| die "Can't sed for /var/run/slurmdbd.pid"
	# gentooify systemd services
	sed \
		-e 's:sysconfig/.*:conf.d/slurm:g' \
		-e 's:var/run/:run/slurm/:g' \
		-e '/^EnvironmentFile=.*/d' \
		-i "${S}/etc"/*.service.in \
		|| die "Can't sed systemd services for sysconfig or var/run/"

	sed -e '/AM_PATH_GTK_2_0/d' -i configure.ac || die

	hprefixify auxdir/{ax_check_zlib,x_ac_{lz4,ofed,munge}}.m4
	eautoreconf
}

src_configure() {
	local myconf=(
		CPPFLAGS="-I/opt/cuda/include"
		--sysconfdir="${EPREFIX}/etc/${PN}"
		--with-hwloc="${EPREFIX}/usr"
		--htmldir="${EPREFIX}/usr/share/doc/${PF}"
		$(use_enable debug)
		$(use_with lua)
		$(use_enable pam)
		$(use_enable X x11)
		$(use_with munge)
		$(use_with json)
		$(use_with hdf5)
		$(use_with nvml)
		$(use_with ofed)
		$(use_with ucx)
		$(use_with yaml)
		$(use_enable static-libs static)
		$(use_enable slurmrestd)
		$(use_enable multiple-slurmd)
	)
	use pam && myconf+=( --with-pam_dir=$(getpam_mod_dir) )
	use mysql || myconf+=( --without-mysql_config )
	econf "${myconf[@]}"

	if use perl ; then
		# small hack to make it compile
		mkdir -p "${S}/src/api/.libs" || die
		mkdir -p "${S}/src/db_api/.libs" || die
		touch "${S}/src/api/.libs/libslurm.so" || die
		touch "${S}/src/db_api/.libs/libslurmdb.so" || die
		cd "${LIBSLURM_PERL_S}" || die
		S="${LIBSLURM_PERL_S}" SRC_PREP="no" perl-module_src_configure
		cd "${LIBSLURMDB_PERL_S}" || die
		S="${LIBSLURMDB_PERL_S}" SRC_PREP="no" perl-module_src_configure
		cd "${S}" || die
		rm -rf "${S}/src/api/.libs" "${S}/src/db_api/.libs" || die
	fi
}

src_compile() {
	default
	use pam && emake -C contribs/pam
	if use perl ; then
		cd "${LIBSLURM_PERL_S}" || die
		S="${LIBSLURM_PERL_S}" perl-module_src_compile
		cd "${LIBSLURMDB_PERL_S}" || die
		S="${LIBSLURMDB_PERL_S}" perl-module_src_compile
		cd "${S}" || die
	fi
	use torque && emake -C contribs/torque
}

src_install() {
	default
	use pam && emake DESTDIR="${D}" -C contribs/pam install
	if use perl; then
		cd "${LIBSLURM_PERL_S}" || die
		S="${LIBSLURM_PERL_S}" perl-module_src_install
		cd "${LIBSLURMDB_PERL_S}" || die
		S="${LIBSLURMDB_PERL_S}" perl-module_src_install
		cd "${S}" || die
	fi
	if use torque; then
		emake DESTDIR="${D}" -C contribs/torque
		rm -f "${D}"/usr/bin/mpiexec || die
	fi
	use static-libs || find "${ED}" -name '*.la' -exec rm {} +
	# install sample configs
	keepdir /etc/slurm
	insinto /etc/slurm
	doins \
		etc/prolog.example \
		etc/cgroup.conf.example \
		etc/slurm.conf.example \
		etc/slurmdbd.conf.example
	exeinto /etc/slurm
	keepdir /etc/slurm/layouts.d
	# install init.d files
	newinitd "$(prefixify_ro "${FILESDIR}/slurmd.initd")" slurmd
	newinitd "$(prefixify_ro "${FILESDIR}/slurmctld.initd")" slurmctld
	newinitd "$(prefixify_ro "${FILESDIR}/slurmdbd.initd")" slurmdbd
	# install conf.d files
	newconfd "${FILESDIR}/slurm.confd" slurm
	# install logrotate file
	insinto /etc/logrotate.d
	newins "${FILESDIR}/logrotate" slurm
	# install bashcomp
	newbashcomp contribs/slurm_completion_help/slurm_completion.sh scontrol
	bashcomp_alias scontrol \
		sreport sacctmgr squeue scancel sshare sbcast sinfo \
		sprio sacct salloc sbatch srun sattach sdiag sstat \
		scrontab slurmrestd strigger
	# install systemd files
	newtmpfiles "${FILESDIR}/slurm.tmpfiles" slurm.conf
	systemd_dounit etc/slurmd.service etc/slurmctld.service etc/slurmdbd.service

	paths=(
		/var/${PN}/checkpoint
		/var/${PN}
		/var/spool/${PN}/slurmd
		/var/spool/${PN}
		/var/log/${PN}
	)
	local folder_path
	for folder_path in ${paths[@]}; do
		keepdir ${folder_path}
		fowners ${PN}:${PN} ${folder_path}
	done
}

pkg_preinst() {
	if use munge; then
		sed -i 's,\(SLURM_USE_MUNGE=\).*,\11,' "${D}"/etc/conf.d/slurm || die
	fi
}

pkg_postinst() {
	tmpfiles_process slurm.conf

	elog "Please visit the file '/usr/share/doc/${P}/html/configurator.html"
	elog "through a (javascript enabled) browser to create a configureation file."
	elog "Copy that file to /etc/slurm/slurm.conf on all nodes (including the headnode) of your cluster."
	echo
	elog "For cgroup support, please see https://www.schedmd.com/slurmdocs/cgroup.conf.html"
	elog "Your kernel must be compiled with the wanted cgroup feature:"
	elog "    For the proctrack plugin:"
	elog "        freezer"
	elog "    For the task plugin:"
	elog "        cpuset, memory, devices"
	elog "    For the accounting plugin:"
	elog "        cpuacct, memory, blkio"
	elog "Then, set these options in /etc/slurm/slurm.conf:"
	elog "    ProctrackType=proctrack/cgroup"
	elog "    TaskPlugin=task/cgroup"
	einfo
	ewarn "Paths were created for slurm. Please use these paths in /etc/slurm/slurm.conf:"
	for folder_path in ${paths[@]}; do
		ewarn "    ${folder_path}"
	done
}
